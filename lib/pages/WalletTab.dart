import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'MarketTab.dart';
import '../services/api/coin_gecko_api.dart';
import '../model/coinGecko.dart';
import './DepositPage.dart';
import './WithdrawPage.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

List<CoinGeckoMarketModel> _marketCoins = [];

class WalletSummary {
  final double staticValue;
  final double marketValue;
  final double returnValue;
  final double returnPercentage;

  WalletSummary({
    required this.staticValue,
    required this.marketValue,
    required this.returnValue,
    required this.returnPercentage,
  });

  // Factory method untuk menghitung summary
  factory WalletSummary.calculate(
      double staticValue, double currentMarketValue) {
    final returnValue = currentMarketValue - staticValue;
    final returnPercentage =
        staticValue != 0 ? (returnValue / staticValue) * 100 : 0.0;

    return WalletSummary(
      staticValue: staticValue,
      marketValue: currentMarketValue,
      returnValue: returnValue,
      returnPercentage: returnPercentage,
    );
  }
}

class _WalletTabState extends State<WalletTab> {
  final CoinGeckoApi _apiServiceGecko = CoinGeckoApi();
  late Box _userWalletBox;
  bool _isLoading = true;
  String _username = '';
  bool _isBalanceVisible = true;
  WalletSummary? _walletSummary; // Tambah state untuk wallet summary

  @override
  void initState() {
    super.initState();
    _initializeWalletData();
    _fetchMarketData();
  }

  Future<void> _fetchMarketData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Ambil data dari CoinGecko, default vs_currency='idr', per_page=100
      final fetchedCoins = await _apiServiceGecko.getMarkets(
        vsCurrency: 'idr',
        perPage: 100,
      );
      if (!mounted) return;
      setState(() {
        _marketCoins = fetchedCoins;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeWalletData() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'Guest';
    _userWalletBox = await Hive.openBox('wallet_$_username');
    setState(() {
      _isLoading = false;
    });
  }

  void _updateWalletSummary(double totalAssetValue) {
    // Ambil static value dari total deposit
    double staticValue = 0;
    for (var key in _userWalletBox.keys) {
      final asset = _userWalletBox.get(key);
      if (asset != null && asset['amount'] is num) {
        staticValue += (asset['amount'] as num).toDouble() *
            (asset['initial_price'] ?? asset['price_in_idr'] as num).toDouble();
      }
    }

    setState(() {
      _walletSummary = WalletSummary.calculate(staticValue, totalAssetValue);
    });
  }

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

    return ValueListenableBuilder(
      valueListenable: _userWalletBox.listenable(),
      builder: (context, Box box, _) {
        double totalAssetValue = 0;
        double staticValue = 0;

        for (var key in box.keys) {
          final asset = box.get(key);
          if (asset != null &&
              asset['amount'] is num &&
              asset['price_in_idr'] is num) {
            final double amount = (asset['amount'] as num).toDouble();
            final double currentPrice =
                (asset['price_in_idr'] as num).toDouble();
            final double initialPrice =
                (asset['initial_price'] ?? currentPrice).toDouble();

            totalAssetValue += amount * currentPrice;
            staticValue += amount * initialPrice;
          }
        }

        final walletSummary =
            WalletSummary.calculate(staticValue, totalAssetValue);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildHeader(totalAssetValue, walletSummary),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
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
                _buildCoinList(box),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double totalAssetValue, WalletSummary summary) {
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
                setState(() {
                  _isBalanceVisible = !_isBalanceVisible;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Return Value (1D): ',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            Text(
              _isBalanceVisible ? _formatCurrency(summary.returnValue) : '****',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: summary.returnValue >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: summary.returnPercentage >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isBalanceVisible
                    ? '${summary.returnPercentage >= 0 ? '+' : ''}${summary.returnPercentage.toStringAsFixed(2)}%'
                    : '****',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      summary.returnPercentage >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
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
                  builder: (context) => DepositPage(walletBox: _userWalletBox),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 112, 190, 145),
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
                color: Color.fromARGB(255, 112, 190, 145),
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
    final amountFormatter = NumberFormat('#,##0.########', 'en_US');

    final valueFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    );

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
                '${amountFormatter.format(amount)} ${asset['short_name'] ?? ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(
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
