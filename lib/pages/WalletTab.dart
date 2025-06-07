import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'MarketTab.dart';
import '../services/api/coin_gecko_api.dart';
import '../model/coinGecko.dart';
import './DepositPage.dart';
import './WithdrawPage.dart';
import '../widgets/wallet/wallet_header.dart';
import '../widgets/wallet/wallet_action_buttons.dart';
import '../widgets/wallet/wallet_coin_list.dart';

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

  Future<void> _updateWalletSummary(double totalAssetValue) async {
    // Ambil static value dari total deposit
    double staticValue = 0;
    double marketValue = 0;
    for (var key in _userWalletBox.keys) {
      final asset = _userWalletBox.get(key);
      if (asset != null && asset['amount'] is num) {
        final double amount = (asset['amount'] as num).toDouble();
        final double initialPrice =
            (asset['initial_price'] ?? asset['price_in_idr'] as num).toDouble();
        staticValue += amount * initialPrice;

        final String? assetId = asset['id'];
        final CoinGeckoMarketModel? marketCoin = _marketCoins
            .where((coin) => coin.id == assetId)
            .cast<CoinGeckoMarketModel?>()
            .firstOrNull;
        final double? marketPrice = marketCoin?.currentPrice;
        marketValue +=
            amount * (marketPrice ?? (asset['price_in_idr'] as num).toDouble());
      }
    }

    setState(() {
      _walletSummary = WalletSummary.calculate(staticValue, marketValue);
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
        _updateWalletSummary(0);

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

        final walletSummary = _walletSummary ??
            WalletSummary(
                staticValue: 0,
                marketValue: 0,
                returnValue: 0,
                returnPercentage: 0);
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                WalletHeader(
                  totalAssetValue: walletSummary.marketValue,
                  summary: walletSummary,
                  staticValue: walletSummary.staticValue,
                  isBalanceVisible: _isBalanceVisible,
                  onToggleBalance: () {
                    setState(() {
                      _isBalanceVisible = !_isBalanceVisible;
                    });
                  },
                ),
                const SizedBox(height: 24),
                WalletActionButtons(
                  onDeposit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DepositPage(walletBox: _userWalletBox),
                      ),
                    );
                  },
                  onWithdraw: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WithdrawPage(walletBox: _userWalletBox),
                      ),
                    );
                  },
                ),
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
                WalletCoinList(box: box, marketCoins: _marketCoins),
              ],
            ),
          ),
        );
      },
    );
  }
}
