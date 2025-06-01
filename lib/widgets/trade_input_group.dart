// lib/widgets/trade_input_group.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Jika Anda memutuskan untuk pass formatter

class TradeInputGroup extends StatelessWidget {
  final TextEditingController priceController;
  final TextEditingController amountController;
  final TextEditingController totalController;
  final String selectedCryptoSymbol;
  final bool isLoadingPrice;
  // Anda bisa juga pass NumberFormat jika ingin format di dalam widget ini,
  // tapi untuk sekarang kita asumsikan controller sudah diisi dengan string angka bersih.

  const TradeInputGroup({
    super.key,
    required this.priceController,
    required this.amountController,
    required this.totalController,
    required this.selectedCryptoSymbol,
    required this.isLoadingPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: "Harga per $selectedCryptoSymbol (IDR)",
            prefixText: "Rp ",
            border: const OutlineInputBorder(),
            suffixIcon:
                isLoadingPrice
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(
                          12.0,
                        ), // Agar indicator lebih di tengah
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : null,
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
