import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MultasScreen extends StatefulWidget {
  @override
  _MultasScreenState createState() => _MultasScreenState();
}

class _MultasScreenState extends State<MultasScreen> {
  final List<Map<String, String>> _cachedUsers = [];
  final List<String> _motivosMultas = [
    'No llevar el peto',
    'Protestar al árbitro',
    'No saber una jugada',
    'Llegar tarde a la quedada antes del partido',
    'Error garrafal en el partido',
    'No ir con la misma ropa que el equipo',
    'Olvidar alguna prenda de ropa para jugar',
    'Tarjeta amarilla innecesaria',
    'Ir borracho al partido',
    'Tarjeta roja innecesaria',
    'No hacer el ejercicio junto al equipo',
    'No llevar el color de camiseta indicado por el entrenador',
    'Interrumpir al entrenador',
    'Llegar tarde',
    'Faltar al entrenamiento sin justificación',
    'Faltar al partido sin justificación',
    'Usar lenguaje inapropiado durante el partido',
    'Faltar al respeto a un compañero',
    'No respetar las decisiones del capitán o entrenador',
    'Abandonar el partido sin permiso',
    'Usar el móvil durante el entrenamiento',
    'Usar el móvil durante el partido',
    'No especificada',
  ];

  Future<List<Map<String, String>>> _fetchLeagueMembers() async {
    if (_cachedUsers.isNotEmpty) {
      return _cachedUsers;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // Llamada a Firebase Firestore para obtener las ligas del usuario
      final leaguesSnapshot =
          await FirebaseFirestore.instance.collection('leagues').get();

      for (var league in leaguesSnapshot.docs) {
        final data = league.data();
        if (data['admin'] == user.uid ||
            (data['members'] ?? []).any(
              (member) => member['uid'] == user.uid,
            )) {
          final adminUid = data['admin'];
          final members = data['members'] ?? [];

          List<Map<String, String>> users = [];

          // Llamada a Firebase Firestore para obtener los datos del administrador
          final adminDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(adminUid)
                  .get();
          if (adminDoc.exists) {
            users.add({
              'uid': adminUid,
              'username': adminDoc.data()?['username'] ?? 'Sin nombre',
            });
          }

          // Llamada a Firebase Firestore para obtener los datos de los miembros
          for (var member in members) {
            final memberDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(member['uid'])
                    .get();
            if (memberDoc.exists) {
              users.add({
                'uid': member['uid'],
                'username': memberDoc.data()?['username'] ?? 'Sin nombre',
              });
            }
          }

          _cachedUsers.addAll(users);
          return users;
        }
      }
    } catch (e) {
      print('Error fetching league members: $e');
    }

    return [];
  }

  Future<String> _getUserNameById(String uid) async {
    try {
      // Llamada a Firebase Firestore para obtener el nombre de usuario por ID
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['username'] ?? 'Sin nombre';
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
    return 'Usuario desconocido';
  }

  Future<List<Map<String, dynamic>>> _fetchMultas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // Llamada a Firebase Firestore para obtener las ligas del usuario
      final leaguesSnapshot =
          await FirebaseFirestore.instance.collection('leagues').get();

      for (var league in leaguesSnapshot.docs) {
        final data = league.data();
        if (data['admin'] == user.uid ||
            (data['members'] ?? []).any(
              (member) => member['uid'] == user.uid,
            )) {
          final multas = data['multas'] ?? [];
          final List<Map<String, dynamic>> multasWithNames = [];

          // Llamada a Firebase Firestore para obtener los nombres de los usuarios asociados a las multas
          for (var multa in multas) {
            final userId = multa['usuario'];
            final userName = await _getUserNameById(userId);
            multasWithNames.add({...multa, 'usuario': userName});
          }

          return multasWithNames;
        }
      }
    } catch (e) {
      print('Error fetching multas: $e');
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Multas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade900,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.blueGrey.shade100,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchMultas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  'Error al cargar las multas',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              );
            }

            final multas = snapshot.data!;

            // Calcula los totales dinámicamente
            final totalAcumulado = multas.fold<double>(
              0.0,
              (sum, multa) => sum + (multa['cantidad'] ?? 0.0),
            );
            final totalPagado = multas.fold<double>(
              0.0,
              (sum, multa) =>
                  sum +
                  ((multa['pagado'] == true ? multa['cantidad'] : 0.0) ?? 0.0),
            );

            return Column(
              children: [
                // Card actualizado con los valores dinámicos
                Card(
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.2),
                  child: Container(
                    height: 180, // Puedes ajustar esta altura si es necesario
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueGrey.shade900,
                          Colors.blueGrey.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween, // Ajusta el espacio
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 40,
                              ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Acumulado',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      '${totalAcumulado.toStringAsFixed(2)}€',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: Colors.white.withOpacity(0.5),
                            thickness: 1,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent.shade400,
                                size: 40,
                              ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Pagado',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      '${totalPagado.toStringAsFixed(2)}€',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.greenAccent.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Resto del contenido
                Expanded(
                  child: ListView.builder(
                    itemCount: multas.length,
                    itemBuilder: (context, index) {
                      final multa = multas[index];
                      return GestureDetector(
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Opciones de la multa'),
                                content: Text(
                                  'Selecciona una acción para esta multa.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        final user =
                                            FirebaseAuth.instance.currentUser;
                                        if (user == null) return;

                                        final leaguesSnapshot =
                                            await FirebaseFirestore.instance
                                                .collection('leagues')
                                                .get();

                                        for (var league
                                            in leaguesSnapshot.docs) {
                                          final data = league.data();
                                          if (data['admin'] == user.uid ||
                                              (data['members'] ?? []).any(
                                                (member) =>
                                                    member['uid'] == user.uid,
                                              )) {
                                            final leagueId = league.id;

                                            // Encuentra la multa exacta en la base de datos
                                            final multas =
                                                List<Map<String, dynamic>>.from(
                                                  data['multas'] ?? [],
                                                );
                                            final multaToRemove = multas
                                                .firstWhere(
                                                  (m) => m['id'] == multa['id'],
                                                  orElse: () => {},
                                                );

                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('leagues')
                                                  .doc(leagueId)
                                                  .update({
                                                    'multas':
                                                        FieldValue.arrayRemove([
                                                          multaToRemove,
                                                        ]),
                                                  });

                                              // Actualiza la lista de multas en la pantalla
                                              setState(() {
                                                snapshot.data!.remove(multa);
                                              });

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Multa eliminada correctamente',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'No se encontró la multa para eliminar.',
                                                  ),
                                                ),
                                              );
                                            }
                                            break;
                                          }
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error al eliminar la multa: $e',
                                            ),
                                          ),
                                        );
                                      }

                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Eliminar multa'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        final user =
                                            FirebaseAuth.instance.currentUser;
                                        if (user == null) return;

                                        final leaguesSnapshot =
                                            await FirebaseFirestore.instance
                                                .collection('leagues')
                                                .get();

                                        for (var league
                                            in leaguesSnapshot.docs) {
                                          final data = league.data();
                                          if (data['admin'] == user.uid ||
                                              (data['members'] ?? []).any(
                                                (member) =>
                                                    member['uid'] == user.uid,
                                              )) {
                                            final leagueId = league.id;

                                            // Buscar la multa por ID y actualizar su estado
                                            final multas =
                                                List<Map<String, dynamic>>.from(
                                                  data['multas'] ?? [],
                                                );
                                            final multaIndex = multas
                                                .indexWhere(
                                                  (m) => m['id'] == multa['id'],
                                                );
                                            if (multaIndex != -1) {
                                              // Cambiar el estado de "pagado"
                                              multas[multaIndex]['pagado'] =
                                                  !(multas[multaIndex]['pagado'] ??
                                                      false);

                                              // Actualizar la base de datos
                                              await FirebaseFirestore.instance
                                                  .collection('leagues')
                                                  .doc(leagueId)
                                                  .update({'multas': multas});

                                              // Actualizar el estado local
                                              setState(() {
                                                snapshot.data![index]['pagado'] =
                                                    multas[multaIndex]['pagado'];
                                              });

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    multas[multaIndex]['pagado'] ==
                                                            true
                                                        ? 'Multa marcada como pagada'
                                                        : 'Multa marcada como no pagada',
                                                  ),
                                                ),
                                              );
                                            }
                                            break;
                                          }
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error al actualizar la multa: $e',
                                            ),
                                          ),
                                        );
                                      }

                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      multa['pagado'] == true
                                          ? 'Marcar como no pagada'
                                          : 'Marcar como pagada',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: Text('Cancelar'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: Colors.black.withOpacity(0.1),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blueGrey.shade200,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Información principal
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Nombre del usuario
                                      Text(
                                        multa['usuario'] ??
                                            'Usuario desconocido',
                                        style: TextStyle(
                                          color: Colors.blueGrey.shade900,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 4),
                                      // Motivo de la multa
                                      Text(
                                        multa['motivo'] ??
                                            'Motivo no especificado',
                                        style: TextStyle(
                                          color: Colors.blueGrey.shade600,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      SizedBox(height: 4),
                                      // Fecha de la multa
                                      Text(
                                        multa['fecha'] != null
                                            ? DateTime.parse(
                                              multa['fecha'],
                                            ).toLocal().toString().split(' ')[0]
                                            : 'Sin fecha',
                                        style: TextStyle(
                                          color: Colors.blueGrey.shade400,
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                // Cantidad y estado de pago
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${multa['cantidad']?.toStringAsFixed(2) ?? '0.00'}€',
                                      style: TextStyle(
                                        color: Colors.blueGrey.shade900,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Icon(
                                      Icons
                                          .compare_arrows, // Ícono de transacción
                                      color:
                                          multa['pagado'] == true
                                              ? Colors
                                                  .green // Verde si está pagado
                                              : Colors
                                                  .red, // Rojo si no está pagado
                                      size: 40, // Tamaño aumentado
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return FutureBuilder<List<Map<String, String>>>(
                future: _fetchLeagueMembers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return AlertDialog(
                      title: Text('Error'),
                      content: Text('No se pudieron cargar los usuarios.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cerrar'),
                        ),
                      ],
                    );
                  }

                  final users = snapshot.data!;
                  String? selectedUser;
                  String? selectedMotivo;
                  String multaCantidad = '';
                  final TextEditingController cantidadController =
                      TextEditingController(text: multaCantidad);

                  bool isPaid = false;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueGrey.shade900,
                                Colors.blueGrey.shade700,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Título del diálogo
                                Text(
                                  'Multa',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Separador: Miembro
                                Divider(
                                  color: Colors.blueGrey.shade300,
                                  thickness: 1,
                                ),
                                SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedUser,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedUser = value;
                                    });
                                  },
                                  items:
                                      users.map((user) {
                                        return DropdownMenuItem<String>(
                                          value: user['uid'],
                                          child: Text(
                                            user['username']!,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  decoration: InputDecoration(
                                    hintText: 'Seleccionar usuario',
                                    hintStyle: TextStyle(
                                      color: Colors.blueGrey.shade400,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.blueGrey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.blueGrey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.blueGrey.shade700,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),

                                Divider(
                                  color: Colors.blueGrey.shade300,
                                  thickness: 1,
                                ),
                                SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 2.8,
                                    child: Wrap(
                                      spacing: 16.0,
                                      runSpacing: 8.0,
                                      children:
                                          _motivosMultas.map((motivo) {
                                            return ChoiceChip(
                                              label: Text(
                                                motivo,
                                                style: TextStyle(
                                                  color:
                                                      selectedMotivo == motivo
                                                          ? Colors.black
                                                          : Colors.black,
                                                ),
                                              ),
                                              selected:
                                                  selectedMotivo == motivo,
                                              onSelected: (isSelected) {
                                                setState(() {
                                                  selectedMotivo =
                                                      isSelected
                                                          ? motivo
                                                          : null;
                                                });
                                              },
                                              backgroundColor: Colors.white,
                                              selectedColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Divider(
                                  color: Colors.blueGrey.shade300,
                                  thickness: 1,
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  keyboardType: TextInputType.none,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: 'Cantidad (€)',
                                    hintStyle: TextStyle(
                                      color: Colors.blueGrey.shade400,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.blueGrey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.blueGrey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.blueGrey.shade700,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  controller: cantidadController,
                                ),
                                SizedBox(height: 16),
                                Wrap(
                                  spacing: 4.0,
                                  runSpacing: 8.0,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ...List.generate(5, (index) {
                                      return SizedBox(
                                        width: 45,
                                        height: 40,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 2,
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              multaCantidad +=
                                                  (index + 1).toString();
                                              cantidadController.text =
                                                  multaCantidad;
                                            });
                                          },
                                          child: Center(
                                            child: Text(
                                              (index + 1).toString(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    SizedBox(
                                      width: 45,
                                      height: 40,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          elevation: 2,
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (multaCantidad.isNotEmpty) {
                                              multaCantidad = multaCantidad
                                                  .substring(
                                                    0,
                                                    multaCantidad.length - 1,
                                                  );
                                              cantidadController.text =
                                                  multaCantidad;
                                            }
                                          });
                                        },
                                        child: Icon(
                                          Icons.backspace,
                                          color: Colors.black,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    ...List.generate(5, (index) {
                                      final number =
                                          index + 6 == 10 ? 0 : index + 6;
                                      return SizedBox(
                                        width: 45,
                                        height: 40,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 2,
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              multaCantidad +=
                                                  number.toString();
                                              cantidadController.text =
                                                  multaCantidad;
                                            });
                                          },
                                          child: Center(
                                            child: Text(
                                              number.toString(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    SizedBox(
                                      width: 45,
                                      height: 40,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          elevation: 2,
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (!multaCantidad.contains('.')) {
                                              multaCantidad += '.';
                                              cantidadController.text =
                                                  multaCantidad;
                                            }
                                          });
                                        },
                                        child: Center(
                                          child: Text(
                                            '.',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Divider(
                                  color: Colors.blueGrey.shade300,
                                  thickness: 1,
                                ),
                                SizedBox(height: 8),
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.blueGrey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              isPaid = false;
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  !isPaid
                                                      ? Colors.blueGrey.shade900
                                                      : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'No Pagado',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    !isPaid
                                                        ? Colors.white
                                                        : Colors
                                                            .blueGrey
                                                            .shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 5,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              isPaid = true;
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  isPaid
                                                      ? Colors.blueGrey.shade900
                                                      : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Pagado',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    isPaid
                                                        ? Colors.white
                                                        : Colors
                                                            .blueGrey
                                                            .shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),

                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      icon: Icon(
                                        Icons.cancel,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'Cancelar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueGrey.shade800,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size(0, 0),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        if (selectedUser != null &&
                                            selectedMotivo != null &&
                                            multaCantidad.isNotEmpty) {
                                          try {
                                            final user =
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser;
                                            if (user == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Usuario no autenticado',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

                                            // Llamada a Firebase Firestore para obtener las ligas del usuario
                                            final leaguesSnapshot =
                                                await FirebaseFirestore.instance
                                                    .collection('leagues')
                                                    .get();
                                            for (var league
                                                in leaguesSnapshot.docs) {
                                              final data = league.data();
                                              if (data['admin'] == user.uid ||
                                                  (data['members'] ?? []).any(
                                                    (member) =>
                                                        member['uid'] ==
                                                        user.uid,
                                                  )) {
                                                final leagueId = league.id;
                                                final multa = {
                                                  'usuario': selectedUser,
                                                  'motivo': selectedMotivo,
                                                  'cantidad': double.parse(
                                                    multaCantidad,
                                                  ),
                                                  'pagado': isPaid,
                                                  'fecha':
                                                      DateTime.now()
                                                          .toIso8601String(),
                                                };

                                                // Llamada a Firebase Firestore para registrar una nueva multa
                                                await FirebaseFirestore.instance
                                                    .collection('leagues')
                                                    .doc(leagueId)
                                                    .update({
                                                      'multas':
                                                          FieldValue.arrayUnion(
                                                            [multa],
                                                          ),
                                                    });

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Multa registrada correctamente',
                                                    ),
                                                  ),
                                                );

                                                Navigator.of(context).pop();
                                                return;
                                              }
                                            }

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'No se encontró una liga para el usuario',
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error al registrar la multa: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Por favor, completa todos los campos.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'Multar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueGrey.shade800,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size(0, 0),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
      ),
    );
  }
}
