import 'package:flutter/material.dart';

class JornadaDropdownWidget extends StatelessWidget {
  final List<String> jornadas;
  final String selectedJornada;
  final ValueChanged<String> onJornadaChanged;

  const JornadaDropdownWidget({
    super.key,
    required this.jornadas,
    required this.selectedJornada,
    required this.onJornadaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButton<String>(
        value: selectedJornada,
        isExpanded: true,
        items:
            jornadas
                .map(
                  (jornada) => DropdownMenuItem(
                    value: jornada,
                    child: Text('Jornada $jornada'),
                  ),
                )
                .toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            onJornadaChanged(newValue);
          }
        },
      ),
    );
  }
}
