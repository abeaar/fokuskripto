import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../model/coinGecko.dart';
import '../../services/api/coin_gecko_api.dart';
import 'notification_service.dart';

class MarketProvider extends ChangeNotifier {
  final CoinGeckoApi _api = CoinGeckoApi();

  Timer? _refreshTimer;

  bool _isLoading = false;
  String? _error;
  List<CoinGeckoMarketModel> _allCoins = [];
  DateTime? _lastUpdated;
  String _sortField = 'market_cap_rank';
  bool _isAscending = true;
  static const int _refreshIntervalSeconds = 120;
  static const int _forceRefreshIntervalMinutes = 5;

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
      fetchData(silent: true, forceRefresh: true);
    } else {
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
      final coins = await _api.getMarkets(
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
      await NotificationService().showMarketUpdateNotification();
    }
  }

  CoinGeckoMarketModel? getCoinById(String id) {
    try {
      return _allCoins.firstWhere((coin) => coin.id == id);
    } catch (e) {
      return null;
    }
  }

  void sortBy(String field) {
    if (_sortField == field) {
      _isAscending = !_isAscending;
    } else {
      _sortField = field;
      _isAscending = true;
    }
    _allCoins = _applySorting(_allCoins);
    notifyListeners();
  }

  List<CoinGeckoMarketModel> _applySorting(List<CoinGeckoMarketModel> coins) {
    return [...coins]..sort((a, b) {
        int compareResult;
        switch (_sortField) {
          case 'name':
            compareResult = a.name.compareTo(b.name);
            break;
          case 'price_change_24h':
            compareResult = (a.priceChangePercentage24h ?? 0.0)
                .compareTo(b.priceChangePercentage24h ?? 0.0);
            break;
          case 'current_price':
            compareResult = a.currentPrice.compareTo(b.currentPrice);
            break;
          case 'total_volume':
            compareResult =
                (a.totalVolume ?? 0.0).compareTo(b.totalVolume ?? 0.0);
            break;
          default:
            compareResult =
                (a.marketCapRank ?? 0).compareTo(b.marketCapRank ?? 0);
        }
        return _isAscending ? compareResult : -compareResult;
      });
  }

  String get currentSortField => _sortField;
  bool get isAscendingSort => _isAscending;

  Future<CoinGeckoMarketModel?> refreshCoinById(String id) async {
    try {
      final coins = await _api.getMarkets(
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

  void shuffleCoins() {
    _allCoins.shuffle();
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
