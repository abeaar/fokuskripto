import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/coinGecko.dart';
import 'api/coin_gecko_api.dart';
import 'api/api_exception.dart';

class MarketDataService extends ChangeNotifier {
  final CoinGeckoApi _api = CoinGeckoApi();
  Timer? _refreshTimer;

  bool _isLoading = false;
  String? _error;
  List<CoinGeckoMarketModel> _allCoins = [];
  DateTime? _lastUpdated;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CoinGeckoMarketModel> get allCoins => _allCoins;
  List<CoinGeckoMarketModel> get topCoins => _allCoins.take(3).toList();
  List<CoinGeckoMarketModel> get trendingCoins =>
      _allCoins.skip(3).take(5).toList();
  DateTime? get lastUpdated => _lastUpdated;

  MarketDataService() {
    // Initial fetch
    fetchData();

    // Set up auto refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchData(silent: true);
    });
  }

  Future<void> fetchData({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final coins = await _api.getMarkets(
        vsCurrency: 'idr',
        perPage: 100, // Get more coins at once
        page: 1,
      );

      _allCoins = coins;
      _lastUpdated = DateTime.now();
      _error = null;
    } on ApiException catch (e) {
      _error = 'Gagal memuat data: ${e.message}';
    } catch (e) {
      _error = 'Terjadi kesalahan tidak terduga: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  CoinGeckoMarketModel? getCoinById(String id) {
    try {
      return _allCoins.firstWhere((coin) => coin.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
