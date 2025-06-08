import 'package:flutter/material.dart';
import '../../model/coinGecko_detail.dart';
import '../api/coin_gecko_api.dart';
import 'package:fl_chart/fl_chart.dart';

class CoinDetailProvider extends ChangeNotifier {
  final String coinId;
  final CoinGeckoApi _apiService = CoinGeckoApi();

  CoinGeckoDetailModel? coinDetail;
  List<FlSpot> chartSpots = [];
  bool isLoading = false;
  String? error;
  DateTime? _lastUpdated;
  static const int _refreshIntervalSeconds = 60; // interval cache, bisa diubah

  CoinDetailProvider({required this.coinId}) {
    print('CoinDetailProvider created for $coinId');
    fetchAll(force: false);
  }

  Future<void> fetchAll({bool force = false}) async {
    if (!force && _lastUpdated != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastUpdated!);
      if (timeSinceLastUpdate.inSeconds < _refreshIntervalSeconds) {
        print(
          'Data masih fresh, tidak fetch ulang',
        );
        return;
      }
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      coinDetail = await _apiService.getCoinDetail(coinId, forceRefresh: force);
      final chartRawData = await _apiService.getMarketChart(
        coinId: coinId,
        vsCurrency: 'idr',
        days: 1,
        forceRefresh: force,
      );
      chartSpots = chartRawData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value[1]);
      }).toList();
      chartSpots.sort((a, b) => a.x.compareTo(b.x));
      _lastUpdated = DateTime.now();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
