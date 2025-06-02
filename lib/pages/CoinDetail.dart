import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/base_network.dart';

// Sesuaikan path import model dan service Anda
import '../model/coinGecko_detail.dart';
import '../services/api_gecko.dart';
// import '../services/trade_service.dart'; // Tidak kita gunakan dulu untuk navigasi
// import 'home_page.dart'; // Tidak kita gunakan dulu untuk navigasi

class CoinDetailPage extends StatefulWidget {
  final String coinId;
  final String? coinName; // Untuk judul AppBar awal
  final String? coinSymbol; // Untuk referensi

  const CoinDetailPage({
    super.key,
    required this.coinId,
    this.coinName,
    this.coinSymbol,
  });

  @override
  State<CoinDetailPage> createState() => _CoinDetailPageState();
}

class _CoinDetailPageState extends State<CoinDetailPage> {
  final ApiServiceGecko _apiService = ApiServiceGecko();

  CoinGeckoDetailModel? _coinDetail;
  List<FlSpot> _chartSpots = [];
  bool _isLoading = true;
  String? _error;

  // Formatters
  final NumberFormat _priceFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final NumberFormat _percentageFormatter = NumberFormat(
    "##0.0#",
    "en_US",
  ); // Untuk % tanpa simbol %
  final NumberFormat _volumeFormatter = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 2,
  ); // Tanpa Rp untuk Volume IDR
  final NumberFormat _coinVolumeFormatter = NumberFormat.compactSimpleCurrency(
    locale: 'en_US',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _fetchPageData(force: false);
  }

  Future<void> _fetchPageData({bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _chartSpots = []; // Bersihkan chart data saat memulai fetch
    });
    try {
      print(
        "CoinDetailPage: Fetching ALL data for ${widget.coinId}, force: $force",
      );

      // Fetch Detail Data
      _coinDetail = await _apiService.fetchCoinDetail(
        widget.coinId,
        forceRefreshUiTrigger: force, // Meneruskan 'force' ke service detail
      );

      // Fetch Chart Data (untuk 1 hari terakhir)
      final chartRawData = await _apiService.fetchCoinMarketChart(
        coinId: widget.coinId,
        vsCurrency: 'idr', // Pastikan mata uang sesuai
        days:
            1, // Periode waktu yang Anda inginkan (1 = 24 jam, 7 = 7 hari, dst.)
        forceRefresh: force, // Meneruskan 'force' ke service chart
      );

      if (chartRawData.isNotEmpty) {
        // Konversi data historis [timestamp, harga] menjadi FlSpot [index, harga]
        // Kita gunakan index sebagai nilai X untuk FlSpot agar urutan benar pada grafik
        _chartSpots =
            chartRawData.asMap().entries.map((entry) {
              // entry.key adalah index (0, 1, 2, ...)
              // entry.value adalah List<double> yaitu [timestamp, price]
              return FlSpot(
                entry.key.toDouble(),
                entry.value[1],
              ); // Gunakan index sebagai X, harga sebagai Y
            }).toList();

        // Penting: Sort by X value untuk memastikan urutan titik yang benar pada grafik
        _chartSpots.sort((a, b) => a.x.compareTo(b.x));
      }

      if (_coinDetail == null && mounted) {
        _error = "Data koin tidak ditemukan.";
      }
    } catch (e) {
      if (mounted) {
        // Tangkap NetworkException secara spesifik atau error umum lainnya
        if (e is NetworkException) {
          _error = e.message;
        } else {
          _error = 'Terjadi kesalahan: ${e.toString()}';
        }
      }
      print("CoinDetailPage: Error fetching page data: $_error");
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleBuyButtonPressed() {
    print("Tombol BUY ditekan untuk: ${widget.coinSymbol ?? widget.coinId}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Fitur BUY untuk ${widget.coinSymbol ?? widget.coinId} segera hadir!",
        ),
      ),
    );
  }

  void _handleSellButtonPressed() {
    print("Tombol SELL ditekan untuk: ${widget.coinSymbol ?? widget.coinId}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Fitur SELL untuk ${widget.coinSymbol ?? widget.coinId} segera hadir!",
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String? value) {
    final ThemeData theme = Theme.of(context);
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color.fromARGB(255, 65, 65, 65),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context, String? descriptionHtml) {
    if (descriptionHtml == null || descriptionHtml.isEmpty) {
      return const SizedBox.shrink();
    }
    String plainTextDescription =
        descriptionHtml
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

    int maxLength = 300;
    if (plainTextDescription.length > maxLength) {
      plainTextDescription =
          "${plainTextDescription.substring(0, maxLength)}...";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Deskripsi",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Divider(),
        const SizedBox(height: 4),
        Text(
          plainTextDescription.isNotEmpty
              ? plainTextDescription
              : "Tidak ada deskripsi.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    if (_chartSpots.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Data grafik tidak tersedia.")),
      );
    }

    // Tentukan nilai min dan max Y dari data chart asli
    double minY = _chartSpots
        .map((spot) => spot.y)
        .reduce((a, b) => a < b ? a : b);
    double maxY = _chartSpots
        .map((spot) => spot.y)
        .reduce((a, b) => a > b ? a : b);
    double minX = _chartSpots.first.x;
    double maxX = _chartSpots.last.x;
    minY = minY * 0.99; // Mengurangi 1% dari nilai minimum
    maxY = maxY * 1.01; // Menambah 1% dari nilai maksimum
    print("Chart: MinY: $minY, MaxY: $maxY, MinX: $minX, MaxX: $maxX");

    return SizedBox(
      height: 200, // Atur tinggi grafik sesuai keinginan Anda
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, right: 16.0),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            minX:
                _chartSpots
                    .first
                    .x, // Sumbu X mulai dari titik pertama data asli
            maxX:
                _chartSpots
                    .last
                    .x, // Sumbu X berakhir di titik terakhir data asli
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: _chartSpots, // Gunakan data chart asli di sini
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Judul AppBar dinamis berdasarkan data yang ada
    String appBarTitle = _coinDetail?.name ?? widget.coinName ?? widget.coinId;
    if (_coinDetail?.symbol != null) {
      appBarTitle =
          "${_coinDetail!.name} (${_coinDetail!.symbol.toUpperCase()})";
    } else if (widget.coinSymbol != null) {
      appBarTitle =
          "${widget.coinName ?? widget.coinId} (${widget.coinSymbol!.toUpperCase()})";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.white,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          fontFamily: 'Roboto',
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Gagal memuat detail: $_error",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Coba Lagi"),
                        // Panggil dengan force: false agar memeriksa cache saat 'Coba Lagi'
                        onPressed: () => _fetchPageData(force: false),
                      ),
                    ],
                  ),
                ),
              )
              : _coinDetail == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Data detail koin tidak ditemukan."),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Coba Lagi"),
                      // Panggil dengan force: false agar memeriksa cache saat 'Coba Lagi'
                      onPressed: () => _fetchPageData(force: false),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                // PENTING: Mengubah force: true menjadi force: false di sini
                // Agar pull-to-refresh juga memeriksa cache terlebih dahulu.
                onRefresh: () => _fetchPageData(force: false),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                              ),
                              const SizedBox(height: 0),
                              Text(
                                _priceFormatter
                                    .format(_coinDetail!.currentPriceIdr)
                                    .replaceAll('Rp ', ''),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 33,
                                ),
                              ),
                              if (_coinDetail!.priceChangePercentage24h != null)
                                Text(
                                  "${_coinDetail!.priceChangePercentage24h! >= 0 ? '+' : ''}${_percentageFormatter.format(_coinDetail!.priceChangePercentage24h)}%",
                                  style: TextStyle(
                                    color:
                                        (_coinDetail!
                                                    .priceChangePercentage24h! >=
                                                0)
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                    fontSize: 23, // Ukuran
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ), // Jarak antara kolom kiri dan kanan
                        Expanded(
                          flex: 2, // Beri ruang yang cukup untuk statistik
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2), // Jarak kecil
                              _buildInfoRow(
                                context,
                                "High",
                                _coinDetail!.high24hIdr != null
                                    ? _priceFormatter
                                        .format(_coinDetail!.high24hIdr!)
                                        .replaceAll('Rp ', '')
                                    : "-",
                              ),
                              _buildInfoRow(
                                context,
                                "Low",
                                _coinDetail!.low24hIdr != null
                                    ? _priceFormatter
                                        .format(_coinDetail!.low24hIdr!)
                                        .replaceAll('Rp ', '')
                                    : "-",
                              ),
                              _buildInfoRow(
                                context,
                                "Vol (IDR)",
                                _coinDetail!.totalVolumeIdr != null
                                    ? " ${_volumeFormatter.format(_coinDetail!.totalVolumeIdr!)}"
                                    : "-",
                              ),
                              _buildInfoRow(
                                context,
                                "Vol (${_coinDetail!.symbol.toUpperCase()})",
                                _coinDetail!.totalVolumeBtc != null
                                    ? "${_coinVolumeFormatter.format(_coinDetail!.totalVolumeBtc!)} ${_coinDetail!.symbol.toUpperCase()}"
                                    : "-",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16), // Jarak sebelum grafik
                    _buildChart(context), // Memanggil fungsi grafik Anda
                    const SizedBox(height: 24),

                    _buildDescription(context, _coinDetail!.descriptionEn),

                    if (_coinDetail!.homepageUrl != null &&
                        _coinDetail!.homepageUrl!.isNotEmpty) ...[
                      // ... (Link Website Anda) ...
                    ],

                    const SizedBox(height: 40),
                    // Tombol Buy & Sell
                    Row(
                      // ... (Tombol Buy/Sell Anda) ...
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
