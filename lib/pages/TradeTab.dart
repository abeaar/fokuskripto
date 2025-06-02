import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/trade_service.dart';
import '../widgets/trade_input_group.dart';
import '../widgets/percentage_buttons.dart';
import '../model/coinGecko.dart';
import 'package:dropdown_search/dropdown_search.dart';

class TradeTabProvider extends StatelessWidget {
  const TradeTabProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => TradeService()..initialize(), // Buat dan inisialisasi service
      child: const TradeTab(),
    );
  }
}

class TradeTab extends StatefulWidget {
  const TradeTab({super.key});

  @override
  State<TradeTab> createState() => _TradeTabState();
}

class _TradeTabState extends State<TradeTab> {
  final _amountController = TextEditingController();
  final _totalController = TextEditingController();

  late TradeService _tradeService; // Akan di-init di didChangeDependencies

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tradeService = Provider.of<TradeService>(
        context,
        listen: false,
      ); // Ambil instance awal

      _amountController.text = _tradeService.amountInputString.value;
      _totalController.text = _tradeService.totalInputString.value;

      _tradeService.amountInputString.addListener(_updateAmountController);
      _tradeService.totalInputString.addListener(_updateTotalController);

      // Listener untuk input pengguna ke controller UI, memanggil metode di service

      _amountController.addListener(() {
        if (_amountController.text != _tradeService.amountInputString.value) {
          _tradeService.calculateTotalFromAmount(_amountController.text);
        }
      });
      _totalController.addListener(() {
        if (_totalController.text != _tradeService.totalInputString.value) {
          _tradeService.calculateAmountFromTotal(_totalController.text);
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _tradeService = Provider.of<TradeService>(context, listen: false);
  }

  void _updateAmountController() {
    if (_amountController.text != _tradeService.amountInputString.value) {
      _amountController.text = _tradeService.amountInputString.value;
    }
  }

  void _updateTotalController() {
    if (_totalController.text != _tradeService.totalInputString.value) {
      _totalController.text = _tradeService.totalInputString.value;
    }
  }

  @override
  void dispose() {
    // Hapus listener dari service
    _tradeService.amountInputString.removeListener(_updateAmountController);
    _tradeService.totalInputString.removeListener(_updateTotalController);

    _amountController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _executeTradeUI() async {
    final tradeService = Provider.of<TradeService>(context, listen: false);
    String? errorMessage = await tradeService.executeTrade();
    if (mounted) {
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${tradeService.currentTradeMode == TradeMode.buy ? 'Pembelian' : 'Penjualan'} ${tradeService.selectedCryptoSymbol} berhasil!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tradeService = Provider.of<TradeService>(context);

    if (tradeService.isLoadingBalances) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownSearch<CoinGeckoMarketModel>(
              popupProps: PopupProps.menu(
                // Bisa juga .dialog atau .modalBottomSheet
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    labelText: "Cari Koin",
                    hintText: "Ketik nama atau simbol koin...",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                itemBuilder: (context, coin, isSelected) {
                  return ListTile(
                    title: Text("${coin.name} (${coin.symbol.toUpperCase()})"),
                  );
                },
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
              ),
              items: tradeService.tradableCoins,
              itemAsString:
                  (CoinGeckoMarketModel coin) =>
                      "${coin.name} (${coin.symbol.toUpperCase()})",
              selectedItem:
                  tradeService.tradableCoins.isNotEmpty &&
                          tradeService.selectedCryptoId.isNotEmpty
                      ? tradeService.tradableCoins.firstWhere(
                        (coin) => coin.id == tradeService.selectedCryptoId,
                        orElse:
                            () =>
                                tradeService
                                    .tradableCoins
                                    .first, // Fallback jika tidak ketemu, atau null
                      )
                      : null, // Atau koin default pertama jika tradableCoins tidak kosong
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Pilih Koin untuk Trading (vs IDR)",
                ),
              ),
              onChanged: (CoinGeckoMarketModel? selectedCoin) {
                if (selectedCoin != null) {
                  tradeService.selectCrypto(selectedCoin.id);
                }
              },
              enabled:
                  tradeService.tradableCoins.isNotEmpty &&
                  !tradeService.isLoadingBalances,
              dropdownButtonProps: DropdownButtonProps(
                tooltip:
                    tradeService.tradableCoins.isEmpty &&
                            tradeService.isLoadingBalances
                        ? "Memuat koin..."
                        : (tradeService.tradableCoins.isEmpty
                            ? "Tidak ada koin"
                            : "Pilih Koin"),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => tradeService.setTradeMode(TradeMode.buy),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          tradeService.currentTradeMode == TradeMode.buy
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                      foregroundColor:
                          tradeService.currentTradeMode == TradeMode.buy
                              ? Theme.of(context).colorScheme.onPrimary
                              : Colors.black54,
                    ),
                    child: const Text("BUY"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => tradeService.setTradeMode(TradeMode.sell),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          tradeService.currentTradeMode == TradeMode.sell
                              ? Colors.red[600]
                              : Colors.grey[300],
                      foregroundColor:
                          tradeService.currentTradeMode == TradeMode.sell
                              ? Colors.white
                              : Colors.black54,
                    ),
                    child: const Text("SELL"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ValueListenableBuilder<String>(
              valueListenable:
                  tradeService
                      .priceInputString, // Mendengarkan ValueNotifier dari service
              builder: (context, currentFormattedPrice, child) {
                // 'currentFormattedPrice' adalah nilai terbaru dari tradeService.priceInputString
                return TradeInputGroup(
                  priceDisplay:
                      currentFormattedPrice, // Mengirim string harga yang sudah siap tampil
                  amountController: _amountController,
                  totalController: _totalController,
                  selectedCryptoSymbol: tradeService.selectedCryptoSymbol,
                  isLoadingPrice: tradeService.isLoadingPrice,
                );
              },
            ),
            const SizedBox(height: 12),
            PercentageButtons(
              onPercentageSelected: (percentage) {
                tradeService.applyPercentage(percentage);
              },
            ),
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
            ),

            ValueListenableBuilder<double>(
              valueListenable:
                  tradeService.currentTradeMode == TradeMode.buy
                      ? tradeService.idrBalance
                      : tradeService.cryptoBalance,
              builder: (context, balance, _) {
                return Text(
                  tradeService.currentTradeMode == TradeMode.buy
                      ? "Saldo IDR: ${tradeService.priceFormatter.format(balance)}" // Akses formatter via service
                      : "Saldo ${tradeService.selectedCryptoSymbol}: ${tradeService.cryptoAmountFormatter.format(balance)} ${tradeService.selectedCryptoSymbol}",
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                );
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _executeTradeUI, // Panggil method UI untuk eksekusi
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      tradeService.currentTradeMode == TradeMode.buy
                          ? Colors.green[600]
                          : Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  tradeService.currentTradeMode == TradeMode.buy
                      ? "Buy ${tradeService.selectedCryptoSymbol}"
                      : "Sell ${tradeService.selectedCryptoSymbol}",
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
    );
  }
}
