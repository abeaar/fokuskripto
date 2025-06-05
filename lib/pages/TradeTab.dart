import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/providers/market_provider.dart';
import '../services/providers/trade_provider.dart';
import '../services/providers/wallet_provider.dart';
import '../widgets/trade/percentage_buttons.dart';
import '../widgets/trade/trade_balance_info.dart';
import '../widgets/trade/trade_coin_dropdown.dart';
import '../widgets/trade/trade_execute_button.dart';
import '../widgets/trade/trade_input_form.dart';
import '../widgets/trade/trade_mode_buttons.dart';
import '../widgets/trade/trade_price_info.dart';

class TradeTab extends StatefulWidget {
  const TradeTab({super.key});

  @override
  State<TradeTab> createState() => _TradeTabState();
}

class _TradeTabState extends State<TradeTab> {
  static final NumberFormat _priceFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _cryptoAmountFormatter = NumberFormat(
    "#,##0.########",
    "en_US",
  );

  static final TextEditingController _amountController =
      TextEditingController();
  static final TextEditingController _totalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Force refresh when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refreshData() async {
    final walletProvider = context.read<WalletProvider>();
    await walletProvider.refresh();
    walletProvider.debugPrintState();
  }

  Widget _buildTradeContent(
    BuildContext context,
    TradeProvider tradeProvider,
    MarketProvider marketProvider,
    WalletProvider walletProvider,
  ) {
    if (marketProvider.isLoading && marketProvider.allCoins.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (marketProvider.error != null && marketProvider.allCoins.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                marketProvider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => marketProvider.fetchData(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TradeCoinDropdown(
                marketProvider: marketProvider,
                tradeProvider: tradeProvider,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          tradeProvider.setTradeMode(TradeMode.buy),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            tradeProvider.currentMode == TradeMode.buy
                                ? Colors.green
                                : Colors.grey,
                      ),
                      child: const Text('Beli'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          tradeProvider.setTradeMode(TradeMode.sell),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            tradeProvider.currentMode == TradeMode.sell
                                ? Colors.red
                                : Colors.grey,
                      ),
                      child: const Text('Jual'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Price Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harga Saat Ini:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _priceFormatter.format(tradeProvider.currentPrice),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Balance Info
              ValueListenableBuilder(
                valueListenable: Hive.box(
                        'wallet_${context.read<WalletProvider>().username}')
                    .listenable(),
                builder: (context, Box box, _) {
                  final idrAsset =
                      box.get('IDR', defaultValue: {'amount': 0.0});
                  final idrBalance =
                      (idrAsset['amount'] as num?)?.toDouble() ?? 0.0;
                  final tradeProvider = context.read<TradeProvider>();
                  final cryptoAsset = box.get(tradeProvider.selectedCoinSymbol,
                      defaultValue: {'amount': 0.0});
                  final cryptoBalance =
                      (cryptoAsset['amount'] as num?)?.toDouble() ?? 0.0;

                  // Update Total IDR controller automatically in buy mode
                  if (tradeProvider.currentMode == TradeMode.buy) {
                    final formatted = idrBalance.round().toString();
                    if (_totalController.text != formatted &&
                        !_totalController.selection.isValid) {
                      _totalController.text = formatted;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Tersedia:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tradeProvider.currentMode == TradeMode.buy
                                  ? _priceFormatter.format(idrBalance)
                                  : '${_cryptoAmountFormatter.format(cryptoBalance)} ${tradeProvider.selectedCoinSymbol}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Percentage Buttons
                      PercentageButtons(
                        onPercentageSelected: (percentage) {
                          // Ambil saldo langsung dari Hive
                          final idrAsset =
                              box.get('IDR', defaultValue: {'amount': 0.0});
                          final idrBalance =
                              (idrAsset['amount'] as num?)?.toDouble() ?? 0.0;
                          final tradeProvider = context.read<TradeProvider>();
                          final cryptoAsset = box.get(
                              tradeProvider.selectedCoinSymbol,
                              defaultValue: {'amount': 0.0});
                          final cryptoBalance =
                              (cryptoAsset['amount'] as num?)?.toDouble() ??
                                  0.0;

                          double calculatedAmount = 0;
                          double calculatedTotal = 0;

                          if (tradeProvider.currentMode == TradeMode.buy) {
                            final idrToSpend = idrBalance * percentage;
                            calculatedAmount =
                                idrToSpend / tradeProvider.currentPrice;
                            calculatedTotal = idrToSpend;
                          } else {
                            final cryptoToSell = cryptoBalance * percentage;
                            calculatedAmount = cryptoToSell;
                            calculatedTotal =
                                cryptoToSell * tradeProvider.currentPrice;
                          }

                          _amountController.text =
                              _cryptoAmountFormatter.format(calculatedAmount);
                          _totalController.text =
                              calculatedTotal.round().toString();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Amount Input
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText:
                              'Jumlah ${tradeProvider.selectedCoinSymbol}',
                          suffixText: tradeProvider.selectedCoinSymbol,
                        ),
                        onChanged: (value) {
                          final amount =
                              double.tryParse(value.replaceAll(',', '.')) ?? 0;
                          _totalController.text =
                              (amount * tradeProvider.currentPrice)
                                  .round()
                                  .toString();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Total IDR Input
                      TextFormField(
                        controller: _totalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total IDR',
                          prefixText: 'Rp ',
                        ),
                        onChanged: (value) {
                          final total = double.tryParse(value) ?? 0;
                          if (tradeProvider.currentPrice > 0) {
                            _amountController.text = _cryptoAmountFormatter
                                .format(total / tradeProvider.currentPrice);
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final amount = double.tryParse(
                                  _amountController.text.replaceAll(',', '.'),
                                ) ??
                                0;
                            await tradeProvider.executeTrade(amount);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaksi berhasil!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              tradeProvider.currentMode == TradeMode.buy
                                  ? Colors.green
                                  : Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          tradeProvider.currentMode == TradeMode.buy
                              ? 'BELI'
                              : 'JUAL',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<TradeProvider, MarketProvider, WalletProvider>(
      builder: (context, tradeProvider, marketProvider, walletProvider, _) =>
          _buildTradeContent(
              context, tradeProvider, marketProvider, walletProvider),
    );
  }
}
