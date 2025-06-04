import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../model/coinGecko.dart';
import '../api/market_service.dart';

class MarketProvider extends ChangeNotifier {
  final MarketService _marketService = MarketService();
  Timer? _refreshTimer;

  bool _isLoading = false;
  String? _error;
  List<CoinGeckoMarketModel> _allCoins = [];
  DateTime? _lastUpdated;
  static const int _refreshIntervalSeconds = 60;
  static const int _forceRefreshIntervalMinutes = 1;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CoinGeckoMarketModel> get allCoins => _allCoins;
  List<CoinGeckoMarketModel> get topCoins => _allCoins.take(3).toList();
  List<CoinGeckoMarketModel> get trendingCoins =>
      _allCoins.skip(3).take(5).toList();
  DateTime? get lastUpdated => _lastUpdated;

  MarketProvider() {
    fetchData();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: _refreshIntervalSeconds), (_) {
      _checkAndFetchData();
    });
  }

  void _checkAndFetchData() {
    if (_lastUpdated == null) {
      fetchData(silent: true);
      return;
    }

    final timeSinceLastUpdate = DateTime.now().difference(_lastUpdated!);
    if (timeSinceLastUpdate.inMinutes >= _forceRefreshIntervalMinutes) {
      // Hanya force refresh jika data lebih lama dari interval cache
      fetchData(silent: true, forceRefresh: true);
    } else {
      // Gunakan cache jika data masih fresh
      fetchData(silent: true, forceRefresh: false);
    }
  }

  Future<void> fetchData(
      {bool silent = false, bool forceRefresh = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final coins = await _marketService.fetchCoinMarkets(
        vsCurrency: 'idr',
        perPage: 100,
        page: 1,
        forceRefresh: forceRefresh,
      );

      _allCoins = coins;
      _lastUpdated = DateTime.now();
      _error = null;
    } catch (e) {
      _error = 'Terjadi kesalahan: ${e.toString()}';
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

  Future<CoinGeckoMarketModel?> refreshCoinById(String id) async {
    try {
      final coins = await _marketService.fetchCoinMarkets(
        vsCurrency: 'idr',
        ids: id,
        forceRefresh: true,
      );

      if (coins.isNotEmpty) {
        final index = _allCoins.indexWhere((coin) => coin.id == id);
        if (index != -1) {
          _allCoins[index] = coins.first;
          notifyListeners();
        }
        return coins.first;
      }
    } catch (e) {
      print('Error refreshing coin $id: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
