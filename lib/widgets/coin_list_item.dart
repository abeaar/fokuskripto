import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/coin.dart'; // Pastikan path ini benar

class CoinListItem extends StatelessWidget {
  final Coin coin;
  final NumberFormat priceFormatter;

  const CoinListItem({
    super.key,
    required this.coin,
    required this.priceFormatter,
  });

  @override
  Widget build(BuildContext context) {
    // Menggunakan Column untuk bisa menambahkan Divider di bawah item
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // InkWell memberikan feedback visual (efek riak) saat item di-tap
        InkWell(
          onTap: () {
            // Tempat untuk menambahkan aksi saat item di-tap
            // Contoh: Navigasi ke halaman detail koin
            print('Tapped on ${coin.name}');
          },
          child: Padding(
            // Padding horizontal untuk memberi jarak dari tepi layar
            // Padding vertikal untuk memberi ruang napas di atas dan bawah konten
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                // --- IKON KOIN ---
                Image.network(
                  coin.imageUrl,
                  width: 36,
                  height: 36,
                  errorBuilder: (context, error, stackTrace) {
                    // Tampilan fallback jika gambar gagal dimuat
                    return const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.error, color: Colors.white, size: 18),
                    );
                  },
                ),
                const SizedBox(width: 12),

                // --- NAMA & SIMBOL KOIN ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600, // Sedikit tebal untuk nama
                          ),
                    ),
                    Text(
                      coin.shortName.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600], // Warna lebih redup untuk simbol
                          ),
                    ),
                  ],
                ),
                
                // Spacer akan mengisi ruang kosong dan mendorong widget berikutnya ke kanan
                const Spacer(),

                // --- HARGA KOIN ---
                Text(
                  priceFormatter.format(coin.currentPrice),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500, // Berat font medium
                      ),
                ),
              ],
            ),
          ),
        ),
        // Garis pemisah tipis antar item
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(height: 1, thickness: 0.5),
        ),
      ],
    );
  }
}