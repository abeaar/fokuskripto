import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../services/trade_service.dart'; // Import TradeService
import '../widgets/trade_input_group.dart';
import '../widgets/percentage_buttons.dart';

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
  final _priceController = TextEditingController();
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

      _priceController.text = _tradeService.priceInputString.value;
      _amountController.text = _tradeService.amountInputString.value;
      _totalController.text = _tradeService.totalInputString.value;

      _tradeService.priceInputString.addListener(_updatePriceController);
      _tradeService.amountInputString.addListener(_updateAmountController);
      _tradeService.totalInputString.addListener(_updateTotalController);

      // Listener untuk input pengguna ke controller UI, memanggil metode di service
      _priceController.addListener(() {
        if (_priceController.text != _tradeService.priceInputString.value) {
          // Hindari loop jika update dari service
          _tradeService.calculatePriceFromTotalAndAmount(_priceController.text);
        }
      });
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

  void _updatePriceController() {
    if (_priceController.text != _tradeService.priceInputString.value) {
      _priceController.text = _tradeService.priceInputString.value;
    }
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
    _tradeService.priceInputString.removeListener(_updatePriceController);
    _tradeService.amountInputString.removeListener(_updateAmountController);
    _tradeService.totalInputString.removeListener(_updateTotalController);

    _priceController.dispose();
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
    final tradeService = Provider.of<TradeService>(
      context,
    ); // listen: true by default

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
            DropdownButtonFormField<String>(
              value: tradeService.selectedCryptoId,
              decoration: const InputDecoration(
                labelText: "Pilih Koin untuk Trading (vs IDR)",
              ),
              items:
                  tradeService.availableCryptos.map((
                    Map<String, String> crypto,
                  ) {
                    return DropdownMenuItem<String>(
                      value: crypto['id']!,
                      child: Text(crypto['symbol']!),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  tradeService.selectCrypto(newValue);
                }
              },
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

            TradeInputGroup(
              priceController: _priceController, // Controller tetap dikelola UI
              amountController: _amountController,
              totalController: _totalController,
              selectedCryptoSymbol: tradeService.selectedCryptoSymbol,
              isLoadingPrice: tradeService.isLoadingPrice,
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
