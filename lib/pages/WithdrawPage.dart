import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fokuskripto/services/notification_service.dart';

class WithdrawPage extends StatefulWidget {
  final Box walletBox;
  const WithdrawPage({super.key, required this.walletBox});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _currentIdrBalanceForMax = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentIdrBalance();
  }

  void _loadCurrentIdrBalance() {
    final idrAsset = widget.walletBox.get(
      'IDR',
      defaultValue: {'amount': 0},
    ); // Ambil sebagai int jika sudah dibulatkan di Hive
    _currentIdrBalanceForMax = (idrAsset['amount'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _handleWithdraw() async {
    if (_formKey.currentState?.validate() ?? false) {
      final double withdrawAmount = double.parse(_amountController.text);
      final Map idrAsset = widget.walletBox.get('IDR');
      final currentAmount = (idrAsset['amount'] as num).toDouble();

      // Validasi tambahan: Cek apakah saldo mencukupi
      if (withdrawAmount > currentAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saldo tidak mencukupi untuk melakukan penarikan.'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Hentikan proses jika saldo kurang
      }
      idrAsset['amount'] = currentAmount - withdrawAmount;
      widget.walletBox.put('IDR', idrAsset);
      await NotificationService().showWithdrawalSuccessNotification(
        withdrawAmount,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Penarikan sebesar IDR $withdrawAmount berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map idrAssetDisplay = widget.walletBox.get(
      'IDR',
      defaultValue: {'amount': 0},
    );
    final double currentBalanceDisplay =
        (idrAssetDisplay['amount'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Tarik Saldo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Saldo Anda saat ini: IDR ${NumberFormat('#,##0', 'id_ID').format(currentBalanceDisplay)}',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Penarikan (IDR)',
                  border: const OutlineInputBorder(),
                  prefixText: 'IDR ',
                  // --- TAMBAHKAN TOMBOL MAX DI SINI ---
                  suffixIcon: TextButton(
                    child: Text(
                      'MAX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onPressed: () {
                      final latestIdrAsset = widget.walletBox.get(
                        'IDR',
                        defaultValue: {'amount': 0},
                      );
                      final double preciseMaxAmount =
                          (latestIdrAsset['amount'] as num?)?.toDouble() ?? 0.0;

                      _amountController.text = preciseMaxAmount.toStringAsFixed(
                        0,
                      ); // Mengisi dengan angka bulat

                      _amountController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _amountController.text.length),
                      );
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah tidak boleh kosong';
                  }
                  final valNum = double.tryParse(value.replaceAll(',', '.'));
                  if (valNum == null) {
                    return 'Format angka tidak valid';
                  }
                  if (valNum <= 0) {
                    return 'Jumlah harus lebih dari 0';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleWithdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Konfirmasi Penarikan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
