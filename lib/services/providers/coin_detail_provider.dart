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

  CoinDetailProvider({required this.coinId}) {
    print('CoinDetailProvider created for $coinId');
    fetchAll(force: true);
  }

  Future<void> fetchAll({bool force = false}) async {
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
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
