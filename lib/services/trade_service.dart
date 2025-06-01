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

  TradeMode currentTradeMode = TradeMode.buy;
  List<CoinGeckoMarketModel> tradableCoins = [];
  String selectedCryptoId = '';
  String selectedCryptoSymbol = '';
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

    try {
      tradableCoins = await _apiServiceGecko.fetchCoinMarkets(
        vsCurrency: 'idr',
        perPage: 50, // Ambil 50 koin teratas misalnya, sesuaikan jumlahnya
      );
      if (tradableCoins.isNotEmpty) {
        // Atur koin pilihan awal ke koin pertama dari daftar
        _setSelectedCoin(tradableCoins.first);
        await fetchCryptoMarketDataAndUpdatePrice(
          selectedCryptoId,
          calledByPairChange: false,
        ); // Harga untuk koin default
      } else {
        // Handle jika tidak ada koin yang bisa diambil
        print("TradeService: Tidak ada koin yang bisa diambil dari API.");
        // Anda mungkin ingin mengatur selectedCryptoId/Symbol ke placeholder atau handle error
      }
    } catch (e) {
      print("TradeService: Gagal mengambil daftar koin tradable: $e");
      // Handle error, mungkin tampilkan pesan di UI melalui state error
    }

    _loadInitialBalancesFromHive();

    await fetchCryptoMarketDataAndUpdatePrice(
      selectedCryptoId,
      calledByPairChange: true,
    );
    _startListeningToBalances();
    isLoadingBalances = false;
    notifyListeners();
  }

  void _setSelectedCoin(CoinGeckoMarketModel coin) {
    selectedCryptoId = coin.id;
    selectedCryptoSymbol = coin.symbol.toUpperCase();
    _selectedCryptoMarketData = coin;
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

  void setTradeMode(TradeMode mode) {
    currentTradeMode = mode;
    amountInputString.value = "";
    totalInputString.value = "";
    notifyListeners(); // Beri tahu UI bahwa mode dan mungkin field telah berubah
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
        _selectedCryptoMarketData = coinDataList.first;
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
    final selectedCoinData = tradableCoins.firstWhere(
      (c) => c.id == newCryptoId,
      orElse:
          () =>
              tradableCoins.isNotEmpty
                  ? tradableCoins.first
                  : throw Exception(
                    "Tidak ada koin tradable",
                  ), // Handle jika error
    );

    _setSelectedCoin(selectedCoinData);

    amountInputString.value = "";
    totalInputString.value = "";

    notifyListeners();

    currentMarketPrice.value = _selectedCryptoMarketData?.currentPrice ?? 0.0;
    if (priceInputString.value.isEmpty ||
        priceInputString.value == "Error" ||
        priceInputString.value == "0" ||
        true /*selalu update saat ganti koin*/ ) {
      priceInputString.value = _priceFormatter
          .format(currentMarketPrice.value)
          .replaceAll('Rp ', '')
          .replaceAll('.', '');
    }

    _listenToSelectedCryptoBalance();
  }

  void calculateTotalFromAmount(String amountStr) {
    amountInputString.value = amountStr;
    final double price =
        currentMarketPrice.value; // <--- Gunakan harga pasar aktual
    final double amount =
        double.tryParse(amountStr.replaceAll(',', '.')) ?? 0.0;
    final double total = price * amount;
    totalInputString.value = _priceFormatter
        .format(total)
        .replaceAll('Rp ', '')
        .replaceAll('.', '');
  }

  void calculateAmountFromTotal(String totalStr) {
    totalInputString.value = totalStr;
    final double price = currentMarketPrice.value;
    final double total = double.tryParse(totalStr.replaceAll('.', '')) ?? 0.0;
    if (price > 0) {
      final double amount = total / price;
      amountInputString.value = _cryptoAmountFormatter
          .format(amount)
          .replaceAll(',', '');
    } else {
      amountInputString.value = "";
    }
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
        cryptoAssetMap['amount'] = currentCryptoAmount - amount;
        idrAssetMap['amount'] = currentIdrAmount + calculatedTotal;
      }

      await _userWalletBox.put('IDR', idrAssetMap);

      if ((cryptoAssetMap['amount'] as num).toDouble() < 0.1 &&
          currentTradeMode == TradeMode.sell) {
        await _userWalletBox.delete(cryptoKey);
        print(
          "TradeService: Menghapus $cryptoKey dari wallet karena saldo habis setelah SELL.",
        );
      } else {
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
