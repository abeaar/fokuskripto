import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

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
  // Jika ApiServiceGecko di-provide di atas MaterialApp atau HomePage:
  // late ApiServiceGecko _apiService;
  // Jika tidak, buat instance baru:

  final List<double> _dummyChartPrices = [
    16250,
    16260,
    16275,
    16290,
    16285,
    16270,
    16280,
    16295,
    16300,
    16290,
    16310,
    16305,
  ];

  final ApiServiceGecko _apiService = ApiServiceGecko();

  CoinGeckoDetailModel? _coinDetail;
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
    // Jika menggunakan Provider:
    // _apiService = Provider.of<ApiServiceGecko>(context, listen: false);
    _fetchDetail(force: false); // Ambil dari cache dulu jika ada
  }

  Future<void> _fetchDetail({bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      print(
        "CoinDetailPage: Fetching detail for ${widget.coinId}, force: $force",
      );
      _coinDetail = await _apiService.fetchCoinDetail(
        widget.coinId,
        forceRefreshUiTrigger: force,
      );
      if (_coinDetail == null && mounted) {
        _error = "Data koin tidak ditemukan.";
      }
    } catch (e) {
      if (mounted) _error = e.toString();
      print("CoinDetailPage: Error fetching coin detail: $_error");
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleBuyButtonPressed() {
    // TODO: Implementasi navigasi ke TradeTab dengan info koin ini untuk BUY
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
    // TODO: Implementasi navigasi ke TradeTab dengan info koin ini untuk SELL
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
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
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
    // Untuk MVP, kita tampilkan sebagai teks biasa. Hati-hati jika ada tag HTML.
    // Untuk parsing HTML yang lebih baik, gunakan paket seperti flutter_html_to_widget atau flutter_widget_from_html_core.
    String plainTextDescription =
        descriptionHtml
            .replaceAll(RegExp(r'<[^>]*>'), ' ') // Hapus tag HTML sederhana
            .replaceAll(RegExp(r'\s+'), ' ') // Ganti spasi ganda dengan tunggal
            .trim();

    // Ambil beberapa kalimat pertama atau batasi panjangnya untuk MVP
    int maxLength = 300; // Batas karakter
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
    // Ubah _dummyChartPrices menjadi List<FlSpot>
    List<FlSpot> chartSpots = [];
    for (int i = 0; i < _dummyChartPrices.length; i++) {
      chartSpots.add(FlSpot(i.toDouble(), _dummyChartPrices[i]));
    }

    // Tentukan nilai min dan max Y untuk sumbu vertikal
    double minY =
        _dummyChartPrices.reduce((a, b) => a < b ? a : b) -
        20; // Beri sedikit ruang di bawah
    double maxY =
        _dummyChartPrices.reduce((a, b) => a > b ? a : b) +
        20; // Beri sedikit ruang di atas

    return SizedBox(
      height: 200, // Atur tinggi grafik sesuai keinginan Anda
      child: Padding(
        padding: const EdgeInsets.only(
          top: 16.0,
          bottom: 8.0,
          right: 16.0,
        ), // Tambahkan padding
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false), // Sembunyikan garis grid
            titlesData: const FlTitlesData(
              show: false,
            ), // Sembunyikan label sumbu (X dan Y)
            borderData: FlBorderData(
              show: true, // Tampilkan border
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            minX: 0, // Sumbu X mulai dari 0
            maxX:
                chartSpots.isNotEmpty
                    ? chartSpots.length.toDouble() - 1
                    : 1, // Sumbu X berakhir di index terakhir
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: chartSpots, // Data titik grafik
                isCurved: true, // Membuat garis melengkung
                gradient: LinearGradient(
                  // Memberi warna gradasi pada garis
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ],
                ),
                barWidth: 3, // Ketebalan garis
                isStrokeCapRound: true,
                dotData: const FlDotData(
                  show: false,
                ), // Sembunyikan titik pada data
                belowBarData: BarAreaData(
                  // Area di bawah garis
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
            // Tambahkan konfigurasi untuk sentuhan/tooltip jika diinginkan nanti
            // lineTouchData: LineTouchData(
            //   touchTooltipData: LineTouchTooltipData(
            //     tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            //   ),
            // ),
          ),
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
        backgroundColor: theme.colorScheme.inversePrimary,
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
                        onPressed: () => _fetchDetail(force: true),
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
                      onPressed: () => _fetchDetail(force: true),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: () => _fetchDetail(force: true),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      _priceFormatter.format(_coinDetail!.currentPriceIdr),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_coinDetail!.priceChangePercentage24h != null)
                      Text(
                        "${_coinDetail!.priceChangePercentage24h! >= 0 ? '+' : ''}${_percentageFormatter.format(_coinDetail!.priceChangePercentage24h)}%",
                        style: TextStyle(
                          color:
                              (_coinDetail!.priceChangePercentage24h! >= 0)
                                  ? Colors.green[700]
                                  : Colors.red[700],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 16), // Jarak sebelum grafik
                    // --- MEMANGGIL FUNGSI GRAFIK DI SINI ---
                    _buildChart(context),

                    // --- AKHIR PEMANGGILAN GRAFIK ---
                    const SizedBox(height: 24), // Jarak setelah grafik
                    // Market Stats Section
                    Text(
                      "Statistik Pasar (24 Jam)",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context, // Jika _buildInfoRow Anda masih memerlukan context
                      "Tertinggi",
                      _coinDetail!.high24hIdr != null
                          ? _priceFormatter.format(_coinDetail!.high24hIdr!)
                          : "-",
                    ),
                    _buildInfoRow(
                      context,
                      "Terendah",
                      _coinDetail!.low24hIdr != null
                          ? _priceFormatter.format(_coinDetail!.low24hIdr!)
                          : "-",
                    ),
                    _buildInfoRow(
                      context,
                      "Volume (IDR)",
                      _coinDetail!.totalVolumeIdr != null
                          ? "Rp ${_volumeFormatter.format(_coinDetail!.totalVolumeIdr!)}"
                          : "-",
                    ),
                    _buildInfoRow(
                      context,
                      "Volume (${_coinDetail!.symbol.toUpperCase()})",
                      _coinDetail!.totalVolumeBtc != null
                          ? "${_coinVolumeFormatter.format(_coinDetail!.totalVolumeBtc!)} ${_coinDetail!.symbol.toUpperCase()}"
                          : "-",
                    ),

                    _buildDescription(
                      context, // Jika _buildDescription Anda masih memerlukan context
                      _coinDetail!.descriptionEn,
                    ),

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
