// lib/widgets/percentage_buttons.dart
import 'package:flutter/material.dart';

class PercentageButtons extends StatelessWidget {
  final Function(double) onPercentageSelected;

  const PercentageButtons({super.key, required this.onPercentageSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          [25, 50, 75, 100].map((percent) {
            return ElevatedButton(
              onPressed: () => onPercentageSelected(percent / 100.0),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(
                  fontSize: 13,
                ), // Sedikit penyesuaian ukuran font
              ),
              child: Text("$percent%"),
            );
          }).toList(),
    );
  }
}
