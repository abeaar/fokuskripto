// lib/deposit_page.dart

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DepositPage extends StatefulWidget {
  // Terima box dari halaman sebelumnya
  final Box walletBox;

  const DepositPage({super.key, required this.walletBox});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _handleDeposit() async {
    // Validasi form
    if (_formKey.currentState?.validate() ?? false) {
      // Ambil nilai dari input dan konversi ke double
      final double depositAmount = double.parse(_amountController.text);

      // Ambil data 'IDR' yang ada dari Hive
      final Map idrAsset = widget.walletBox.get(
        'IDR',
        defaultValue: {
          'name': 'Rupiah',
          'short_name': 'IDR',
          'image_url':
              'https://cdn-icons-png.flaticon.com/512/13893/13893854.png',
          'amount': 0.0, // Default jika belum ada
          'price_in_idr': 1,
        },
      );

      // Hitung saldo baru
      final currentAmount = (idrAsset['amount'] as num).toDouble();
      idrAsset['amount'] = currentAmount + depositAmount;

      // Simpan kembali data yang sudah diperbarui ke Hive
      widget.walletBox.put('IDR', idrAsset);

      // Catat ke history
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? 'Guest';
      final historyBox = await Hive.openBox('transaction_history_$username');
      await historyBox.add({
        'type': 'deposit',
        'asset': 'IDR',
        'amount': depositAmount,
        'price': 1,
        'date': DateTime.now().toIso8601String(),
        'note': '',
      });

      await NotificationService().showDepositSuccessNotification(
        depositAmount,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deposit sebesar IDR ${NumberFormat('#,##0', 'id_ID').format(depositAmount)} berhasil! Sisa saldo: IDR ${NumberFormat('#,##0', 'id_ID').format(currentAmount + depositAmount)}',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Deposit',
          style: TextStyle(color: Color.fromARGB(255, 112, 190, 145)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Deposit (IDR)',
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
                onPressed: _handleDeposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 112, 190, 145),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Konfirmasi Deposit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
