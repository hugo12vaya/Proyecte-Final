import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'league_screen.dart';

// Pantalla principal després d'iniciar sessió
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Llista de lligues de l'usuari
  final List<Map<String, String>> _leagues = [];
  // Referència a Firestore i Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserLeagues(); // Carrega les lligues de l'usuari al començar
  }

  // Obté les lligues on l'usuari és admin o membre
  Future<void> _fetchUserLeagues() async {
    final user = _auth.currentUser; // Usuari autenticat
    if (user == null) {
      // Mostra missatge si no hi ha usuari
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Usuario no autenticado')));
      return;
    }

    try {
      // Obté totes les lligues de Firestore
      final querySnapshot = await _firestore.collection('leagues').get();
      // Filtra les lligues on l'usuari és admin o membre
      final userLeagues = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['admin'] == user.uid ||
            (data['members'] != null &&
                (data['members'] as List).any(
                  (member) =>
                      member is Map<String, dynamic> &&
                      member['uid'] == user.uid,
                ));
      });

      // Actualitza la llista de lligues a l'estat
      setState(() {
        _leagues.clear();
        _leagues.addAll(
          userLeagues
              .map((doc) {
                final data = doc.data();
                return {
                  'name': (data['name'] ?? '') as String,
                  'description': (data['description'] ?? '') as String,
                };
              })
              .cast<Map<String, String>>()
              .toList(),
        );
      });
    } catch (e) {
      // Mostra error si falla la càrrega
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar las ligas: $e')));
    }
  }

  // Mostra el diàleg per crear una nova lliga
  void _showCreateLeagueDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Crear Liga',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                // Camp per al nom de la lliga
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Nombre de la Liga',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Camp per a la descripció de la lliga
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Descripción (opcional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Botons per cancel·lar o crear la lliga
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isNotEmpty) {
                          final user = _auth.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Usuario no autenticado')),
                            );
                            return;
                          }

                          final league = {
                            'name': nameController.text,
                            'description': descriptionController.text,
                            'admin': user.uid,
                            'createdAt': FieldValue.serverTimestamp(),
                          };

                          try {
                            // Desa la lliga a Firestore
                            await _firestore.collection('leagues').add(league);
                            setState(() {
                              _leagues.add({
                                'name': nameController.text,
                                'description': descriptionController.text,
                              });
                            });
                            Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al guardar la liga: $e'),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'El nombre de la liga es obligatorio',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Crear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Mostra el diàleg per unir-se a una lliga existent
  void _showJoinLeagueDialog() {
    final TextEditingController leagueIdController = TextEditingController();
    String selectedRole = 'Jugador';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Unirse a Liga',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                // Camp per introduir l'ID de la lliga
                TextField(
                  controller: leagueIdController,
                  decoration: InputDecoration(
                    hintText: 'ID de la Liga',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Selector de rol dins la lliga
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items:
                      ['Portero', 'Jugador', 'Delegado/Entrenador']
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Botons per cancel·lar o unir-se a la lliga
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (leagueIdController.text.isNotEmpty) {
                          final user = _auth.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Usuario no autenticado')),
                            );
                            return;
                          }

                          try {
                            // Busca la lliga per ID
                            final leagueDoc =
                                await _firestore
                                    .collection('leagues')
                                    .doc(leagueIdController.text)
                                    .get();

                            if (!leagueDoc.exists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Liga no encontrada')),
                              );
                              return;
                            }

                            // Afegeix l'usuari com a membre de la lliga
                            await _firestore
                                .collection('leagues')
                                .doc(leagueIdController.text)
                                .update({
                                  'members': FieldValue.arrayUnion([
                                    {'uid': user.uid, 'role': selectedRole},
                                  ]),
                                });

                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Te has unido a la liga')),
                            );
                            _fetchUserLeagues();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al unirse a la liga: $e'),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('El ID de la liga es obligatorio'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Unirse'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Construcció de la interfície principal
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Inner League',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey.shade900,
        elevation: 4,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
      ),
      // Menú lateral (drawer)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                'Menú',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.blueGrey.shade900),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.blueGrey.shade900),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade50, Colors.blueGrey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),

          child: Column(
            children: [
              // Mostra les lligues de l'usuari o un missatge si no n'hi ha
              Expanded(
                flex: 6,
                child:
                    _leagues.isEmpty
                        ? Center(
                          child: Text(
                            'No hay ligas disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                        : PageView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _leagues.length,
                          itemBuilder: (context, index) {
                            final league = _leagues[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: _buildCard(
                                title: league['name']!.toUpperCase(),
                                subtitle: league['description'] ?? '',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              LeagueScreen(league: league),
                                    ),
                                  );
                                },
                                isLarge: true,
                              ),
                            );
                          },
                        ),
              ),
              SizedBox(height: 16),
              // Botó per crear una nova lliga
              _buildHorizontalCard(
                title: 'Crear Liga',
                subtitle: 'Crea una nova lliga',
                icon: Icons.add_circle,
                onTap: _showCreateLeagueDialog,
                isSmall: true,
              ),
              SizedBox(height: 16),
              // Botó per unir-se a una lliga existent
              _buildHorizontalCard(
                title: 'Unirse a Liga',
                subtitle: 'Únete a una lliga existent',
                icon: Icons.group_add,
                onTap: _showJoinLeagueDialog,
                isSmall: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget per mostrar una targeta de lliga gran
  Widget _buildCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      shadowColor: Colors.blueAccent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment:
                isLarge ? MainAxisAlignment.center : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isLarge ? 32 : 28,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'RobotoCondensed',
                  color: Colors.blueGrey.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                subtitle.toUpperCase(),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget per mostrar una targeta horitzontal (crear o unir-se a lliga)
  Widget _buildHorizontalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isSmall = false,
  }) {
    // Retorna una Card amb estil horitzontal i un botó d'acció
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ), // Cantonades arrodonides
      elevation: 6, // Ombra de la targeta
      shadowColor: Colors.blueAccent, // Color de l'ombra
      child: InkWell(
        onTap: onTap, // Acció quan es toca la targeta
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            isSmall ? 12.0 : 16.0,
          ), // Mida del padding segons si és petita
          child: Row(
            children: [
              // Icona principal de la targeta (crear o unir-se)
              Icon(
                icon,
                size:
                    isSmall
                        ? 36
                        : 40, // Mida de la icona segons mida de la targeta
                color: Colors.blueGrey.shade900,
              ),
              SizedBox(width: 16), // Espai entre la icona i el text
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Text alineat a l'esquerra
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Títol de la targeta (ex: "Crear Liga")
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmall ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade900,
                      ),
                    ),
                    SizedBox(height: 5), // Espai entre títol i subtítol
                    // Subtítol de la targeta (ex: "Crea una nova lliga")
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
