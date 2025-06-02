import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './DepositPage.dart';
import './WithdrawPage.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  late Box _userWalletBox;
  bool _isLoading = true;
  String _username = '';
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _initializeWalletData();
  }

  Future<void> _initializeWalletData() async {
    // Hindari error jika widget sudah di-dispose
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'Guest';
    _userWalletBox = await Hive.openBox('wallet_$_username');
    setState(() {
      _isLoading = false;
    });
  }

  // --- HAPUS FUNGSI _calculateTotalValue() DARI STATE ---

  String _formatCurrency(double value) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    );
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ValueListenableBuilder sekarang membungkus semua widget yang bergantung pada data wallet
    return ValueListenableBuilder(
      valueListenable: _userWalletBox.listenable(),
      builder: (context, Box box, _) {
        double totalAssetValue = 0;
        for (var key in box.keys) {
          final asset = box.get(key);
          if (asset != null &&
              asset['amount'] is num &&
              asset['price_in_idr'] is num) {
            totalAssetValue +=
                (asset['amount'] as num).toDouble() *
                (asset['price_in_idr'] as num).toDouble();
          }
        }

        // UI utama sekarang di-build di dalam builder ini
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Kirim data yang sudah dihitung sebagai parameter
                _buildHeader(totalAssetValue),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons
                          .account_balance_wallet_outlined, // Anda bisa ganti icon ini
                      color: Colors.grey[800],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Your Portfolio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Kirim box langsung ke list
                _buildCoinList(box),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double totalAssetValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Asset Value',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isBalanceVisible ? _formatCurrency(totalAssetValue) : '********',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            IconButton(
              icon: Icon(
                _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                // setState hanya untuk UI toggle, ini benar
                setState(() {
                  _isBalanceVisible = !_isBalanceVisible;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildActionButtons() {
    // Tidak ada perubahan di sini
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // ---- PERUBAHAN DI SINI ----
                  // Kirim box yang sedang aktif ke DepositPage
                  builder: (context) => DepositPage(walletBox: _userWalletBox),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Deposit',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WithdrawPage(walletBox: _userWalletBox),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Withdraw',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoinList(Box box) {
    if (box.isEmpty) {
      return const Expanded(child: Center(child: Text('No assets found.')));
    }

    return Expanded(
      child: ListView.builder(
        itemCount: box.length,
        itemBuilder: (context, index) {
          final asset = box.get(box.keyAt(index));
          if (asset == null) return const SizedBox.shrink();
          return _buildCoinTile(asset);
        },
      ),
    );
  }

  Widget _buildCoinTile(dynamic asset) {
    // Formatter untuk jumlah koin (misal: 1,000.12345 BTC)
    final amountFormatter = NumberFormat('#,##0.########', 'en_US');

    // 1. Definisikan formatter untuk mata uang Rupiah
    final valueFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    );

    // Ambil dan konversi nilai dengan aman
    final double amount = (asset['amount'] as num?)?.toDouble() ?? 0.0;
    final double price = (asset['price_in_idr'] as num?)?.toDouble() ?? 0.0;
    final double totalValuePerCoin = amount * price;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 20,
            child: Image.network(
              asset['image_url'] ?? '',
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, color: Colors.red);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset['name'] ??
                      'No Name', // Tambahkan fallback jika nama null
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                // 2. Gunakan variabel 'amount' yang sudah aman, bukan asset['amount'] lagi
                '${amountFormatter.format(amount)} ${asset['short_name'] ?? ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(
                // Sekarang `valueFormatter` sudah bisa digunakan
                valueFormatter.format(totalValuePerCoin),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
