// lib/widgets/percentage_buttons.dart
import 'package:flutter/material.dart';

class PercentageButtons extends StatefulWidget {
  final Function(double) onPercentageSelected;

  const PercentageButtons({super.key, required this.onPercentageSelected});

  @override
  State<PercentageButtons> createState() => _PercentageButtonsState();
}

class _PercentageButtonsState extends State<PercentageButtons> {
  // 1. Variabel untuk menyimpan persentase yang dipilih
  int? _selectedPercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [25, 50, 75, 100].map((percent) {
        // 2. Cek apakah tombol ini adalah tombol yang sedang dipilih
        final bool isSelected = _selectedPercent == percent;

        return Expanded(
          child: Padding(
            // Menambahkan sedikit jarak antar tombol
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton(
              onPressed: () {
                // 3. Panggil setState untuk memperbarui UI dan menyimpan pilihan
                setState(() {
                  _selectedPercent = percent;
                });
                // Tetap panggil fungsi callback ke parent widget
                widget.onPercentageSelected(percent / 100.0);
              },
              style: ElevatedButton.styleFrom(
                // 4. Atur warna berdasarkan kondisi `isSelected`
                backgroundColor: isSelected ? Colors.amber : Colors.grey[200],
                foregroundColor: isSelected ? Colors.black : Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                // Menghilangkan bayangan agar terlihat lebih rapi saat aktif
                elevation: isSelected ? 0 : 2, 
              ),
              child: Text("$percent%"),
            ),
          ),
        );
      }).toList(),
    );
  }
}