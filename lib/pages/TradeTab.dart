import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Walaupun tidak ada listener, async operations tetap butuh ini
import 'package:dropdown_search/dropdown_search.dart'; // Untuk dropdown pencarian

import '../model/coinGecko.dart'; // Sesuaikan path jika perlu
import '../services/api_gecko.dart'; // Sesuaikan path jika perlu
import '../widgets/percentage_buttons.dart'; // Sesuaikan path jika perlu

const String spUsernameKey = 'username'; // Dari LoginPage Anda

enum TradeMode { buy, sell }

class TradeTab extends StatefulWidget {
  const TradeTab({super.key});

  @override
  State<TradeTab> createState() => _TradeTabState();
}

class _TradeTabState extends State<TradeTab> {
  final ApiServiceGecko _apiServiceGecko = ApiServiceGecko();
  late Box _userWalletBox;
  String _username = '';

  TradeMode _currentTradeMode = TradeMode.buy;
  List<CoinGeckoMarketModel> _tradableCoins = [];
  String _selectedCryptoId = '';
  String _selectedCryptoSymbol = '';
  CoinGeckoMarketModel? _selectedCryptoMarketData;

  double _currentMarketPrice = 0.0;
  String _priceDisplayString = "Rp 0"; // Untuk menampilkan harga yang diformat

  double _idrBalance = 0.0;
  double _cryptoBalance = 0.0;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();

  bool _isLoadingInitialData = true;
  bool _isLoadingPrice = false;
  String? _error;

  final NumberFormat _priceFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final NumberFormat _cryptoAmountFormatter = NumberFormat(
    "#,##0.########",
    "en_US",
  );

  @override
  void initState() {
    super.initState();
    _initializeTradeData();
    // Listener untuk _amountController dan _totalController sudah DIHAPUS
  }

  @override
  void dispose() {
    _amountController.dispose();
    _totalController.dispose();
    // Tidak ada lagi listener yang perlu di-remove di sini
    super.dispose();
  }

  Future<void> _initializeTradeData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingInitialData = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString(spUsernameKey) ?? 'Guest';
      _userWalletBox = await Hive.openBox('wallet_$_username');
      _tradableCoins = await _apiServiceGecko.fetchCoinMarkets(
        vsCurrency: 'idr',
        perPage: 50,
      );
      if (!mounted) return;

      if (_tradableCoins.isNotEmpty) {
        _setSelectedCoin(_tradableCoins.first);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitialData = false; // Pastikan loading awal berhenti
        });
        print(
          "TradeTab: _initializeTradeData selesai, _isLoadingInitialData = $_isLoadingInitialData",
        );
      }
    }
  }

  void _setSelectedCoin(CoinGeckoMarketModel coin) {
    if (!mounted) return;
    setState(() {
      _selectedCryptoId = coin.id;
      _selectedCryptoSymbol = coin.symbol.toUpperCase();
      _selectedCryptoMarketData = coin;
      _amountController.clear();
      _totalController.clear();
    });
    _fetchPriceAndBalancesForSelectedCoin();
  }

  Future<void> _fetchPriceAndBalancesForSelectedCoin() async {
    if (!mounted) return;

    if (_selectedCryptoId.isEmpty) {
      print("TradeTab: Tidak ada koin dipilih, refresh harga diabaikan.");
      if (_isLoadingPrice) {
        setState(() {
          _isLoadingPrice = false;
        });
      }
      return;
    }

    setState(() {
      _isLoadingPrice = true;
    });

    try {
      print(
        "TradeTab: Refreshing price for coin ID: $_selectedCryptoId",
      ); // DEBUG
      final List<CoinGeckoMarketModel> specificCoinDataList =
          await _apiServiceGecko.fetchCoinMarkets(
            ids: _selectedCryptoId,
            vsCurrency: 'idr',
          );
      if (!mounted) return;
      if (specificCoinDataList.isNotEmpty) {
        _selectedCryptoMarketData = specificCoinDataList.first;
        _currentMarketPrice = _selectedCryptoMarketData!.currentPrice;
        setState(() {
          _priceDisplayString = _priceFormatter.format(_currentMarketPrice);
          print("TradeTab: Harga baru diterima: $_priceDisplayString"); // DEBUG
        });
      } else {
        setState(() {
          _priceDisplayString = "Rp 0"; // Atau "Data tidak ditemukan"
          _currentMarketPrice = 0.0;
          print(
            "TradeTab: Data koin tidak ditemukan untuk ID: $_selectedCryptoId",
          ); // DEBUG
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _priceDisplayString = "Error Harga";
        _currentMarketPrice = 0.0;
        print("TradeTab: Error fetching specific coin price: $e"); // DEBUG
      });
    }

    _loadBalances(); // Muat saldo juga (ini akan memanggil setState sendiri)

    if (!mounted) return;
    setState(() {
      _isLoadingPrice = false;
    });
  }

  void _loadBalances() {
    if (!_userWalletBox.isOpen || !mounted) return;
    final idrAsset = _userWalletBox.get('IDR', defaultValue: {'amount': 0});
    final idrAmount = (idrAsset['amount'] as num?)?.toDouble() ?? 0.0;
    final cryptoAsset = _userWalletBox.get(
      _selectedCryptoSymbol.toUpperCase(),
      defaultValue: {'amount': 0.0},
    );
    final cryptoAmount = (cryptoAsset['amount'] as num?)?.toDouble() ?? 0.0;
    setState(() {
      _idrBalance = idrAmount;
      _cryptoBalance = cryptoAmount;
    });
    print(
      "TradeTab: Saldo dimuat: IDR=$_idrBalance, $_selectedCryptoSymbol=$_cryptoBalance",
    );
  }

  void _applyPercentage(double percentage) {
    final double price = _currentMarketPrice;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harga pasar belum tersedia untuk kalkulasi."),
        ),
      );
      return;
    }
    double calculatedAmount = 0;
    double calculatedTotal = 0;
    if (_currentTradeMode == TradeMode.buy) {
      final double idrToSpend = _idrBalance * percentage;
      calculatedAmount = idrToSpend / price;
      calculatedTotal = idrToSpend;
    } else {
      // Sell Mode
      final double cryptoToSell = _cryptoBalance * percentage;
      calculatedAmount = cryptoToSell;
      calculatedTotal = cryptoToSell * price;
    }
    setState(() {
      _amountController.text = calculatedAmount.toStringAsFixed(8);
      _totalController.text = calculatedTotal.round().toString();
    });
  }

  Future<void> _executeTrade() async {
    final double price = _currentMarketPrice;
    final double amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final int totalIdrForTransaction =
        (price * amount).round(); // Total IDR dibulatkan

    if (amount <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah dan harga harus valid.")),
      );
      return;
    }

    // Validasi Saldo
    if (_currentTradeMode == TradeMode.buy) {
      if (_idrBalance < totalIdrForTransaction) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Saldo IDR tidak mencukupi. Dibutuhkan: ${_priceFormatter.format(totalIdrForTransaction)}",
            ),
          ),
        );
        return;
      }
    } else {
      // Sell
      if (_cryptoBalance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Saldo $_selectedCryptoSymbol tidak mencukupi."),
          ),
        );
        return;
      }
    }

    // Proses ke Hive
    try {
      Map<String, dynamic> idrAssetMap = Map<String, dynamic>.from(
        _userWalletBox.get(
          'IDR',
          defaultValue: {
            'amount': 0,
            'name': 'Rupiah',
            'short_name': 'IDR',
            'image_url': 'URL_IDR_VALID',
            'price_in_idr': 1.0,
          },
        ),
      );
      int currentIdrInt = (idrAssetMap['amount'] as num?)?.toInt() ?? 0;

      String cryptoKey = _selectedCryptoSymbol.toUpperCase();
      Map<String, dynamic> cryptoAssetMap = Map<String, dynamic>.from(
        _userWalletBox.get(
          cryptoKey,
          defaultValue: {
            'amount': 0.0,
            'name': _selectedCryptoMarketData?.name ?? _selectedCryptoSymbol,
            'short_name': _selectedCryptoSymbol.toUpperCase(),
            'image_url': _selectedCryptoMarketData?.image ?? '',
            'price_in_idr': price,
          },
        ),
      );
      double currentCryptoAmount =
          (cryptoAssetMap['amount'] as num?)?.toDouble() ?? 0.0;

      if (_currentTradeMode == TradeMode.buy) {
        idrAssetMap['amount'] = currentIdrInt - totalIdrForTransaction;
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
        cryptoAssetMap['amount'] = double.parse(
          (currentCryptoAmount + amount).toStringAsFixed(8),
        );
        cryptoAssetMap['price_in_idr'] = newAveragePrice;
        cryptoAssetMap['name'] =
            _selectedCryptoMarketData?.name ?? cryptoAssetMap['name'];
        cryptoAssetMap['image_url'] =
            _selectedCryptoMarketData?.image ?? cryptoAssetMap['image_url'];
        cryptoAssetMap['short_name'] = _selectedCryptoSymbol.toUpperCase();
      } else {
        // Sell
        cryptoAssetMap['amount'] = double.parse(
          (currentCryptoAmount - amount).toStringAsFixed(8),
        );
        idrAssetMap['amount'] = currentIdrInt + totalIdrForTransaction;
      }

      await _userWalletBox.put('IDR', idrAssetMap);
      if ((cryptoAssetMap['amount'] as double) < 0.00000001 &&
          _currentTradeMode == TradeMode.sell) {
        await _userWalletBox.delete(cryptoKey);
      } else {
        await _userWalletBox.put(cryptoKey, cryptoAssetMap);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Trade ${_currentTradeMode == TradeMode.buy ? 'BUY' : 'SELL'} $_selectedCryptoSymbol berhasil!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _amountController.clear();
        _totalController.clear();
      });
      _loadBalances();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal melakukan trade: $e"),
          backgroundColor: Colors.red,
        ),
      );
      print("Error executing trade: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitialData) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchPriceAndBalancesForSelectedCoin,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownSearch<CoinGeckoMarketModel>(
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      labelText: "Cari Koin",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  itemBuilder:
                      (context, coin, isSelected) => ListTile(
                        title: Text(
                          "${coin.name} (${coin.symbol.toUpperCase()})",
                        ),
                      ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                ),
                items: _tradableCoins,
                itemAsString:
                    (CoinGeckoMarketModel coin) =>
                        "${coin.name} (${coin.symbol.toUpperCase()})",
                selectedItem:
                    _tradableCoins.isNotEmpty && _selectedCryptoId.isNotEmpty
                        ? _tradableCoins.firstWhere(
                          (c) => c.id == _selectedCryptoId,
                          orElse: () => _tradableCoins.first,
                        )
                        : null,
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Pilih Koin (vs IDR)",
                    border: OutlineInputBorder(),
                  ),
                ),
                onChanged:
                    (_tradableCoins.isEmpty)
                        ? null
                        : (CoinGeckoMarketModel? selectedCoin) {
                          if (selectedCoin != null) {
                            _setSelectedCoin(selectedCoin);
                          }
                        },
                enabled: _tradableCoins.isNotEmpty,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          () => setState(() {
                            // Ini sudah benar
                            _currentTradeMode = TradeMode.buy;
                            _amountController.clear();
                            _totalController.clear();
                          }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentTradeMode == TradeMode.buy
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300],
                        foregroundColor:
                            _currentTradeMode == TradeMode.buy
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.black54,
                      ),
                      child: const Text("BUY"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          () => setState(() {
                            _currentTradeMode = TradeMode.sell;
                            _amountController.clear();
                            _totalController.clear();
                          }),
                      // --- AKHIR PERBAIKAN ---
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentTradeMode == TradeMode.sell
                                ? Colors.red[600]
                                : Colors.grey[300],
                        foregroundColor:
                            _currentTradeMode == TradeMode.sell
                                ? Colors.white
                                : Colors.black54,
                      ),
                      child: const Text("SELL"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: "Harga per $_selectedCryptoSymbol (IDR)",
                  border: const OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _priceDisplayString,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Jumlah ($_selectedCryptoSymbol)",
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    double price = _currentMarketPrice;
                    double amount =
                        double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                    if (price > 0) {
                      double total = price * amount;
                      setState(() {
                        _totalController.text = total.round().toString();
                      });
                    }
                  } else {
                    setState(() {
                      _totalController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              PercentageButtons(onPercentageSelected: _applyPercentage),
              const SizedBox(height: 12),
              TextFormField(
                controller: _totalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Total (IDR)",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    double price = _currentMarketPrice;
                    double total =
                        double.tryParse(value.replaceAll('.', '')) ?? 0.0;
                    if (price > 0) {
                      double amount = total / price;
                      setState(() {
                        _amountController.text = amount.toStringAsFixed(8);
                      });
                    }
                  } else {
                    setState(() {
                      _amountController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                _currentTradeMode == TradeMode.buy
                    ? "Saldo IDR: ${_priceFormatter.format(_idrBalance)}"
                    : "Saldo $_selectedCryptoSymbol: ${_cryptoAmountFormatter.format(_cryptoBalance)} $_selectedCryptoSymbol",
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _executeTrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _currentTradeMode == TradeMode.buy
                            ? Colors.green[600]
                            : Colors.red[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentTradeMode == TradeMode.buy
                        ? "Buy $_selectedCryptoSymbol"
                        : "Sell $_selectedCryptoSymbol",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
