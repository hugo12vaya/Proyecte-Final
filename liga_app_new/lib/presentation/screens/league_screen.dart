import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'partidos_screen.dart';
import 'estadisticas_screen.dart';
import 'clasificacion_screen.dart';
import 'rankings_screen.dart';
import 'forma_screen.dart';
import 'multas_screen.dart';
import 'videos_screen.dart';
import 'inicio_screen.dart';

class LeagueScreen extends StatefulWidget {
  final Map<String, String> league;

  const LeagueScreen({Key? key, required this.league}) : super(key: key);

  @override
  _LeagueScreenState createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  int _selectedIndex = 0;
  bool _canViewStats = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // Método que verifica los permisos del usuario actual en Firebase
  Future<void> _checkPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Usuario no autenticado');
      return;
    }

    try {
      // Llamada a Firebase Firestore para obtener la colección de ligas
      final leaguesSnapshot =
          await FirebaseFirestore.instance.collection('leagues').get();

      for (var league in leaguesSnapshot.docs) {
        final data = league.data();

        final isAdmin = data['admin'] == user.uid;
        final members = data['members'] as List<dynamic>? ?? [];

        final isDelegate = members.any(
          (member) =>
              member is Map<String, dynamic> &&
              member['uid'] == user.uid &&
              member['role'] == 'Delegado/Entrenador',
        );

        if (isAdmin || isDelegate) {
          print('Liga encontrada: ${data['name']}');
          setState(() {
            _canViewStats = true;
          });
          return;
        }
      }

      print('No se encontró una liga para el usuario actual');
    } catch (e) {
      print('Error al verificar permisos: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.league['name'] ?? 'Liga',
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
            if (_canViewStats)
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.bar_chart, color: Colors.blueGrey.shade900),
                ),
                title: Text(
                  'Ingresar Estadísticas',
                  style: TextStyle(color: Colors.blueGrey.shade900),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EstadisticasScreen(),
                    ),
                  );
                },
              ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: Colors.blueGrey.shade900),
              ),
              title: Text(
                'Forma',
                style: TextStyle(color: Colors.blueGrey.shade900),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FormaScreen()),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.euro, color: Colors.blueGrey.shade900),
              ),
              title: Text(
                'Multas',
                style: TextStyle(color: Colors.blueGrey.shade900),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MultasScreen()),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.video_library,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              title: Text(
                'Videos',
                style: TextStyle(color: Colors.blueGrey.shade900),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VideosScreen()),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.exit_to_app, color: Colors.blueGrey.shade900),
              ),
              title: Text(
                'Abandonar Liga',
                style: TextStyle(color: Colors.blueGrey.shade900),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('Confirmar'),
                        content: Text(
                          '¿Estás seguro de que deseas abandonar la liga?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Abandonar'),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // Llamada a Firebase Firestore para actualizar la lista de miembros de la liga
                      await FirebaseFirestore.instance
                          .collection('leagues')
                          .doc(widget.league['id'])
                          .update({
                            'members': FieldValue.arrayRemove([user.uid]),
                          });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Has abandonado la liga.')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al abandonar la liga: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      body:
          _selectedIndex == 0
              ? InicioScreen()
              : _selectedIndex == 1
              ? PartidosScreen()
              : _selectedIndex == 2
              ? ClasificacionScreen()
              : _selectedIndex == 3
              ? RankingsScreen()
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueGrey.shade50, Colors.blueGrey.shade100],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Contenido de la liga',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Partidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Clasificación',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.military_tech),
            label: 'Rankings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueGrey.shade900,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
