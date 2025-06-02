import 'package:flutter/material.dart';

class TradeInputGroup extends StatelessWidget {
  final String priceDisplay; // Teks harga yang sudah diformat
  final TextEditingController amountController;
  final TextEditingController totalController;
  final String selectedCryptoSymbol;
  final bool isLoadingPrice;


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
          decoration: InputDecoration(
            labelText: "Harga per $selectedCryptoSymbol (IDR)",
            border: const OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
