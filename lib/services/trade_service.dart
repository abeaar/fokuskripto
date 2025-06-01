import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../model/coinGecko.dart';
import 'api_gecko.dart';

const String spUsernameKey = 'username';

enum TradeMode { buy, sell }

class TradeService with ChangeNotifier {
  final ApiServiceGecko _apiServiceGecko = ApiServiceGecko();
  late Box _userWalletBox;
  String _username = '';

  // State yang akan dikelola oleh service ini
  TradeMode currentTradeMode = TradeMode.buy;
  String selectedCryptoId = 'bitcoin'; // Default
  String selectedCryptoSymbol = 'BTC'; // Default
  CoinGeckoMarketModel? _selectedCryptoMarketData;

  ValueNotifier<double> currentMarketPrice = ValueNotifier(0.0);
  ValueNotifier<double> idrBalance = ValueNotifier(0.0);
  ValueNotifier<double> cryptoBalance = ValueNotifier(0.0);

  ValueNotifier<String> priceInputString = ValueNotifier("");
  ValueNotifier<String> amountInputString = ValueNotifier("");
  ValueNotifier<String> totalInputString = ValueNotifier("");

  bool isLoadingPrice = false;
  bool isLoadingBalances = true;

  final NumberFormat _priceFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final NumberFormat _cryptoAmountFormatter = NumberFormat(
    "#,##0.########",
    "en_US",
  );

  NumberFormat get priceFormatter => _priceFormatter;
  NumberFormat get cryptoAmountFormatter => _cryptoAmountFormatter;

  // Daftar koin yang bisa di-trade (bisa juga diambil dari API atau konfigurasi)
  List<Map<String, String>> availableCryptos = [
    {
      'id': 'bitcoin',
      'symbol': 'BTC',
      'name': 'Bitcoin',
    }, // Tambahkan 'name' jika belum ada
    {'id': 'ethereum', 'symbol': 'ETH', 'name': 'Ethereum'},
    {'id': 'binancecoin', 'symbol': 'BNB', 'name': 'BNB'},
    {'id': 'ripple', 'symbol': 'XRP', 'name': 'XRP'},
    {'id': 'cardano', 'symbol': 'ADA', 'name': 'Cardano'},
  ];

  StreamSubscription? _idrBalanceSubscription;
  StreamSubscription? _cryptoBalanceSubscription;

  TradeService();

  Future<void> initialize() async {
    isLoadingBalances = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString(spUsernameKey) ?? 'Guest';
    if (_username == 'Guest' || _username.isEmpty) {
      isLoadingBalances = false;
      notifyListeners();
      return;
    }
    _userWalletBox = await Hive.openBox('wallet_$_username');

    _loadInitialBalancesFromHive();

    await fetchCryptoMarketDataAndUpdatePrice(
      selectedCryptoId,
      calledByPairChange: true,
    );
    _startListeningToBalances();
    isLoadingBalances = false;
    notifyListeners();
  }

  void _loadInitialBalancesFromHive() {
    if (!_userWalletBox.isOpen) {
      print(
        "Warning: _userWalletBox belum terbuka saat _loadInitialBalancesFromHive dipanggil.",
      );
      return;
    }
    final idrAsset = _userWalletBox.get('IDR', defaultValue: {'amount': 0.0});
    idrBalance.value = (idrAsset['amount'] as num?)?.toDouble() ?? 0.0;
    String cryptoKey = selectedCryptoSymbol.toUpperCase();
    final cryptoAssetData = _userWalletBox.get(
      cryptoKey,
      defaultValue: {'amount': 0.0},
    );
    cryptoBalance.value =
        (cryptoAssetData['amount'] as num?)?.toDouble() ?? 0.0;
    print(
      "Initial balances loaded: IDR=${idrBalance.value}, $selectedCryptoSymbol=${cryptoBalance.value}",
    );
  }

  void _startListeningToBalances() {
    _idrBalanceSubscription?.cancel();
    _idrBalanceSubscription = _userWalletBox.watch(key: 'IDR').listen((event) {
      if (!event.deleted && event.value != null) {
        final idrAsset =
            event.value as Map<dynamic, dynamic>; // Sesuaikan cast jika perlu
        idrBalance.value = (idrAsset['amount'] as num?)?.toDouble() ?? 0.0;
      } else if (event.deleted) {
        idrBalance.value = 0.0;
      }
    });
    _listenToSelectedCryptoBalance();
  }

  void _listenToSelectedCryptoBalance() {
    _cryptoBalanceSubscription?.cancel();
    String cryptoKey = selectedCryptoSymbol.toUpperCase();

    final cryptoAssetData = _userWalletBox.get(
      cryptoKey,
      defaultValue: {'amount': 0.0},
    );
    cryptoBalance.value =
        (cryptoAssetData['amount'] as num?)?.toDouble() ?? 0.0;
    print(
      "Current $selectedCryptoSymbol balance set/refreshed to: ${cryptoBalance.value}",
    );
    _cryptoBalanceSubscription = _userWalletBox.watch(key: cryptoKey).listen((
      event,
    ) {
      print("$selectedCryptoSymbol balance event: ${event.value}");
      if (!event.deleted && event.value != null) {
        final cryptoAsset = event.value as Map<dynamic, dynamic>;
        cryptoBalance.value =
            (cryptoAsset['amount'] as num?)?.toDouble() ?? 0.0;
      } else if (event.deleted) {
        cryptoBalance.value = 0.0;
      }
    });
    // }
  }

  @override
  void dispose() {
    _idrBalanceSubscription?.cancel();
    _cryptoBalanceSubscription?.cancel();
    currentMarketPrice.dispose();
    idrBalance.dispose();
    cryptoBalance.dispose();
    priceInputString.dispose();
    amountInputString.dispose();
    totalInputString.dispose();
    super.dispose();
  }

  Future<void> fetchCryptoMarketDataAndUpdatePrice(
    String cryptoId, {
    bool calledByPairChange = false,
  }) async {
    isLoadingPrice = true;
    notifyListeners();
    try {
      final List<CoinGeckoMarketModel> coinDataList = await _apiServiceGecko
          .fetchCoinMarkets(ids: cryptoId, vsCurrency: 'idr');
      if (coinDataList.isNotEmpty) {
        _selectedCryptoMarketData =
            coinDataList.first; // Simpan market data lengkap
        currentMarketPrice.value = _selectedCryptoMarketData!.currentPrice;
        if (calledByPairChange ||
            priceInputString.value.isEmpty ||
            priceInputString.value == "Error" ||
            priceInputString.value == "0") {
          priceInputString.value = _priceFormatter
              .format(currentMarketPrice.value)
              .replaceAll('Rp ', '')
              .replaceAll('.', '');
        }
      } else {
        _selectedCryptoMarketData = null;
        currentMarketPrice.value = 0.0;
        priceInputString.value = "0";
      }
    } catch (e) {
      _selectedCryptoMarketData = null;
      currentMarketPrice.value = 0.0;
      priceInputString.value = "Error";
      print("Error fetching price in TradeService: $e");
    }
    isLoadingPrice = false;
    notifyListeners();
  }

  void selectCrypto(String newCryptoId) {
    final selected = availableCryptos.firstWhere(
      (c) => c['id'] == newCryptoId,
      orElse: () => availableCryptos.first,
    );
    selectedCryptoId = newCryptoId;
    selectedCryptoSymbol = selected['symbol']!;

    amountInputString.value = "";
    totalInputString.value = "";

    notifyListeners();
    fetchCryptoMarketDataAndUpdatePrice(
      selectedCryptoId,
      calledByPairChange: true,
    );
    _listenToSelectedCryptoBalance();
  }

  void setTradeMode(TradeMode mode) {
    currentTradeMode = mode;
    // Mungkin perlu membersihkan field atau logika lain saat mode berubah
    amountInputString.value = "";
    totalInputString.value = "";
    notifyListeners();
  }

  void calculateTotalFromAmount(String amountStr) {
    amountInputString.value = amountStr; // Update nilai stringnya dulu
    final double price =
        double.tryParse(priceInputString.value.replaceAll('.', '')) ?? 0.0;
    final double amount =
        double.tryParse(amountStr.replaceAll(',', '.')) ?? 0.0;
    final double total = price * amount;
    totalInputString.value = _priceFormatter
        .format(total)
        .replaceAll('Rp ', '')
        .replaceAll('.', '');
    notifyListeners(); // Meskipun totalInputString adalah ValueNotifier, ini untuk jaga-jaga jika ada listener lain
  }

  void calculateAmountFromTotal(String totalStr) {
    totalInputString.value = totalStr;
    final double price =
        double.tryParse(priceInputString.value.replaceAll('.', '')) ?? 0.0;
    final double total = double.tryParse(totalStr.replaceAll('.', '')) ?? 0.0;

    if (price > 0) {
      final double amount = total / price;
      amountInputString.value = _cryptoAmountFormatter
          .format(amount)
          .replaceAll(',', ''); // Hapus koma dari formatter jika ada
    } else {
      amountInputString.value = "";
    }
    notifyListeners();
  }

  void calculatePriceFromTotalAndAmount(String priceStr) {
    priceInputString.value = priceStr;
    calculateTotalFromAmount(amountInputString.value);
  }

  void applyPercentage(double percentage) {
    double price =
        double.tryParse(priceInputString.value.replaceAll('.', '')) ??
        currentMarketPrice.value;
    if (price <= 0 && currentMarketPrice.value > 0)
      price = currentMarketPrice.value;
    if (price <= 0) return; // Tidak bisa kalkulasi

    if (currentTradeMode == TradeMode.buy) {
      final double availableToSpend = idrBalance.value * percentage;
      final double amountToBuy = availableToSpend / price;
      amountInputString.value = _cryptoAmountFormatter
          .format(amountToBuy)
          .replaceAll(',', '');
      totalInputString.value = _priceFormatter
          .format(availableToSpend)
          .replaceAll('Rp ', '')
          .replaceAll('.', '');
    } else {
      // Sell Mode
      final double amountToSell = cryptoBalance.value * percentage;
      final double totalReceived = amountToSell * price;
      amountInputString.value = _cryptoAmountFormatter
          .format(amountToSell)
          .replaceAll(',', '');
      totalInputString.value = _priceFormatter
          .format(totalReceived)
          .replaceAll('Rp ', '')
          .replaceAll('.', '');
    }
    notifyListeners();
  }

  Future<String?> executeTrade() async {
    // 1. Ambil dan Validasi Input Pengguna dari ValueNotifier
    final double price =
        double.tryParse(
          priceInputString.value.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0.0;
    final double amount =
        double.tryParse(amountInputString.value.replaceAll(',', '.')) ?? 0.0;

    final double calculatedTotal = price * amount;

    if (amount <= 0 || price <= 0) {
      return "Masukkan jumlah dan harga yang valid (lebih besar dari nol).";
    }

    // 2. Validasi Saldo Terkini (ValueNotifier sudah diupdate oleh listener Hive)
    if (currentTradeMode == TradeMode.buy) {
      if (idrBalance.value < calculatedTotal) {
        return "Saldo IDR tidak mencukupi. Dibutuhkan: ${_priceFormatter.format(calculatedTotal)}, Tersedia: ${_priceFormatter.format(idrBalance.value)}";
      }
    } else {
      // TradeMode.sell
      if (cryptoBalance.value < amount) {
        return "Saldo $selectedCryptoSymbol tidak mencukupi. Dibutuhkan: ${_cryptoAmountFormatter.format(amount)}, Tersedia: ${_cryptoAmountFormatter.format(cryptoBalance.value)}";
      }
    }

    // 3. Proses Transaksi di Hive
    try {
      Map<String, dynamic> idrAssetMap = Map<String, dynamic>.from(
        _userWalletBox.get(
          'IDR',
          defaultValue: {
            'name': 'Rupiah',
            'short_name': 'IDR',
            'image_url': 'URL_GAMBAR_IDR_ANDA_YANG_VALID', // PASTIKAN INI VALID
            'amount': 0.0,
            'price_in_idr': 1.0,
          },
        ),
      );
      double currentIdrAmount =
          (idrAssetMap['amount'] as num?)?.toDouble() ?? 0.0;

      String cryptoKey = selectedCryptoSymbol.toUpperCase();
      Map<String, dynamic> cryptoAssetMap = Map<String, dynamic>.from(
        _userWalletBox.get(
          cryptoKey,
          defaultValue: {
            'amount': 0.0,
            'name': _selectedCryptoMarketData?.name ?? selectedCryptoSymbol,
            'short_name': selectedCryptoSymbol.toUpperCase(),
            'image_url': _selectedCryptoMarketData?.image ?? '',
            'price_in_idr': price, // Harga awal jika ini koin baru
          },
        ),
      );
      double currentCryptoAmount =
          (cryptoAssetMap['amount'] as num?)?.toDouble() ?? 0.0;

      if (currentTradeMode == TradeMode.buy) {
        idrAssetMap['amount'] = currentIdrAmount - calculatedTotal;

        double newAveragePrice;
        if (currentCryptoAmount > 0 &&
            (cryptoAssetMap['price_in_idr'] as num? ?? 0) > 0) {
          newAveragePrice =
              ((currentCryptoAmount *
                      (cryptoAssetMap['price_in_idr'] as num).toDouble()) +
                  (amount * price)) /
              (currentCryptoAmount + amount);
        } else {
          newAveragePrice = price;
        }
        cryptoAssetMap['amount'] = currentCryptoAmount + amount;
        cryptoAssetMap['price_in_idr'] = newAveragePrice;
        cryptoAssetMap['name'] =
            _selectedCryptoMarketData?.name ?? cryptoAssetMap['name'];
        cryptoAssetMap['image_url'] =
            _selectedCryptoMarketData?.image ?? cryptoAssetMap['image_url'];
        cryptoAssetMap['short_name'] = selectedCryptoSymbol.toUpperCase();
      } else {
        // TradeMode.sell
        cryptoAssetMap['amount'] = currentCryptoAmount - amount;
        idrAssetMap['amount'] = currentIdrAmount + calculatedTotal;
      }

      // Simpan perubahan kembali ke Hive
      await _userWalletBox.put('IDR', idrAssetMap);

      // --- PERBAIKAN LOGIKA PENYIMPANAN cryptoAssetMap ---
      if ((cryptoAssetMap['amount'] as num).toDouble() < 0.00000001 &&
          currentTradeMode == TradeMode.sell) {
        // Jika menjual dan saldo menjadi sangat kecil/nol
        await _userWalletBox.delete(cryptoKey);
        print(
          "TradeService: Menghapus $cryptoKey dari wallet karena saldo habis setelah SELL.",
        );
      } else {
        // Untuk BUY, atau SELL yang saldonya tidak habis, atau jika Anda tidak ingin menghapus saat saldo 0
        await _userWalletBox.put(cryptoKey, cryptoAssetMap);
        print(
          "TradeService: Mengupdate $cryptoKey di wallet dengan saldo ${(cryptoAssetMap['amount'] as num).toDouble()}.",
        );
      }
    } catch (e) {
      print("Error saat eksekusi trade di Hive: $e");
      return "Gagal menyimpan transaksi ke wallet.";
    }

    amountInputString.value = "";
    totalInputString.value = "";

    notifyListeners(); 

    return null; // Menandakan sukses
  }
}
