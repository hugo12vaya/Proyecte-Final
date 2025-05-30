import 'package:flutter/material.dart';

class ToggleButtonsWidget extends StatelessWidget {
  final bool isGeneralSelected;
  final ValueChanged<bool> onToggle;

  const ToggleButtonsWidget({
    super.key,
    required this.isGeneralSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.blueGrey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isGeneralSelected
                          ? Colors.blueGrey.shade900
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  'General',
                  style: TextStyle(
                    color: isGeneralSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      !isGeneralSelected
                          ? Colors.blueGrey.shade900
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Jornada',
                  style: TextStyle(
                    color: !isGeneralSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
