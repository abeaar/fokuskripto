// lib/widgets/trade_input_group.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Jika Anda memutuskan untuk pass formatter

class TradeInputGroup extends StatelessWidget {
  final String priceDisplay; // Teks harga yang sudah diformat
  final TextEditingController amountController;
  final TextEditingController totalController;
  final String selectedCryptoSymbol;
  final bool isLoadingPrice;
  // Anda bisa juga pass NumberFormat jika ingin format di dalam widget ini,
  // tapi untuk sekarang kita asumsikan controller sudah diisi dengan string angka bersih.

  const TradeInputGroup({
    super.key,
    required this.priceDisplay,
    required this.amountController,
    required this.totalController,
    required this.selectedCryptoSymbol,
    required this.isLoadingPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InputDecorator(
          // Agar tetap ada border dan label seperti field
          decoration: InputDecoration(
            labelText: "Harga per $selectedCryptoSymbol (IDR)",
            border: const OutlineInputBorder(),
            // Hilangkan prefixText jika priceDisplay sudah termasuk "Rp "
            // prefixText: "Rp ",
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                // Expanded agar teks harga bisa panjang
                child: Text(
                  priceDisplay, // Tampilkan string harga dari parameter
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500 /* Sesuaikan style */,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLoadingPrice)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(2.0), // Kurangi padding agar pas
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Icon(
                  // Ikon statis, atau bisa juga tombol refresh jika diinginkan di sini
                  Icons.sell_outlined, // Contoh ikon, bisa juga kosong
                  color: Colors.grey[400],
                  size: 20,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: "Jumlah ($selectedCryptoSymbol)",
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
