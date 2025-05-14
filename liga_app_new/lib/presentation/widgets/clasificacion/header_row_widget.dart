import 'package:flutter/material.dart';

class HeaderRow extends StatelessWidget {
  final bool isGeneral;

  const HeaderRow({super.key, required this.isGeneral});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade800,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildHeaderCell('#', flex: 1),
            _buildHeaderCell('Jugador', flex: 3),
            if (isGeneral) ...[
              _buildHeaderCell('PJ', flex: 1),
              _buildHeaderCell('PG', flex: 1),
              _buildHeaderCell('PE', flex: 1),
              _buildHeaderCell('PP', flex: 1),
            ] else ...[
              _buildHeaderCell('G', flex: 1),
              _buildHeaderCell('A', flex: 1),
              _buildHeaderCell('GF', flex: 1),
              _buildHeaderCell('GC', flex: 1),
            ],
            _buildHeaderCell('PTS', flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
