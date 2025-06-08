import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/providers/coin_detail_provider.dart';

class CoinChartWidget extends StatelessWidget {
  const CoinChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chartSpots =
        context.select<CoinDetailProvider, List<FlSpot>>((p) => p.chartSpots);
    if (chartSpots.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Data grafik tidak tersedia.")),
      );
    }
    double minY =
        chartSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    double maxY =
        chartSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    double minX = chartSpots.first.x;
    double maxX = chartSpots.last.x;
    minY = minY * 0.99;
    maxY = maxY * 1.01;
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, right: 16.0),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey, width: 1),
            ),
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: chartSpots,
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      Theme.of(context).colorScheme.primary.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
