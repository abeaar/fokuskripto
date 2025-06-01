import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WithdrawPage extends StatefulWidget {
  // Terima box dari halaman sebelumnya
  final Box walletBox;

  const WithdrawPage({super.key, required this.walletBox});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _handleWithdraw() {
    if (_formKey.currentState?.validate() ?? false) {
      final double withdrawAmount = double.parse(_amountController.text);
      final Map idrAsset = widget.walletBox.get('IDR');
      final currentAmount = (idrAsset['amount'] as num).toDouble();

      // Validasi tambahan: Cek apakah saldo mencukupi
      if (withdrawAmount > currentAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saldo tidak mencukupi untuk melakukan penarikan. $currentAmount',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return; // Hentikan proses jika saldo kurang
      }

      // Hitung saldo baru
      idrAsset['amount'] = currentAmount - withdrawAmount;

      // Simpan kembali data yang sudah diperbarui
      widget.walletBox.put('IDR', idrAsset);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Penarikan sebesar IDR $withdrawAmount berhasil! sisa uang sebesar $currentAmount',
          ),
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
    // Ambil saldo saat ini untuk ditampilkan
    final Map idrAsset = widget.walletBox.get(
      'IDR',
      defaultValue: {'amount': 0.0},
    );
    final currentBalance = (idrAsset['amount'] as num).toDouble();

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
                'Saldo Anda saat ini: IDR ${currentBalance.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Penarikan (IDR)',
                  border: OutlineInputBorder(),
                  prefixText: 'IDR ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Format angka tidak valid';
                  }
                  if (double.parse(value) <= 0) {
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
