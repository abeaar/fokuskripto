import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Box _historyBox;
  bool _isLoading = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _initBox();
  }

  Future<void> _initBox() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'Guest';
    _historyBox = await Hive.openBox('transaction_history_$_username');
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History',
            style: TextStyle(color: Color.fromARGB(255, 59, 160, 63))),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: ValueListenableBuilder(
        valueListenable: _historyBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No transaction history.'));
          }
          final keys = box.keys.toList()
            ..sort((a, b) {
              final aDate =
                  DateTime.tryParse(box.get(a)['date'] ?? '') ?? DateTime(2000);
              final bDate =
                  DateTime.tryParse(box.get(b)['date'] ?? '') ?? DateTime(2000);
              return bDate.compareTo(aDate);
            });
          // Group by date (yyyy-MM-dd)
          Map<String, List<dynamic>> grouped = {};
          for (var k in keys) {
            final tx = box.get(k);
            final date = DateTime.tryParse(tx['date'] ?? '') ?? DateTime(2000);
            final dateKey = DateFormat('dd MMM yyyy').format(date);
            grouped.putIfAbsent(dateKey, () => []).add(tx);
          }
          return ListView(
            children: grouped.entries.expand((entry) {
              return [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Text(entry.key,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15)),
                ),
                ...entry.value.map((tx) => _buildTxTile(tx)).toList(),
              ];
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildTxTile(dynamic tx) {
    final type = tx['type'] ?? '';
    final asset = tx['asset'] ?? '';
    final amount = tx['amount'] ?? 0;
    final price = tx['price'] ?? 0;
    final date = tx['date'] ?? '';
    final dt = date.isNotEmpty ? DateTime.tryParse(date) : null;
    final timeStr = dt != null ? DateFormat('HH:mm').format(dt) : '';
    final amountStr = NumberFormat('#,##0.########').format(amount);
    final priceStr =
        NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0)
            .format(price);
    final totalStr =
        NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0)
            .format(price * (amount is num ? amount : 0));
    String typeLabel = '';
    IconData iconData = Icons.swap_horiz;
    Color iconColor = Colors.grey;
    switch (type) {
      case 'deposit':
        typeLabel = 'Deposit';
        iconData = Icons.attach_money;
        iconColor = Colors.green;
        break;
      case 'withdraw':
        typeLabel = 'Withdraw';
        iconData = Icons.money_off;
        iconColor = Colors.red;
        break;
      case 'buy':
        typeLabel = 'Buy';
        iconData = Icons.arrow_downward_rounded;
        iconColor = Colors.green;
        break;
      case 'sell':
        typeLabel = 'Sell';
        iconData = Icons.arrow_upward_rounded;
        iconColor = Colors.red;
        break;
      default:
        typeLabel = type;
        iconData = Icons.swap_horiz;
        iconColor = Colors.grey;
    }
    return Column(
      children: [
        const Divider(height: 5, thickness: 0.7, indent: 12, endIndent: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 2),
                child: Icon(iconData, color: iconColor, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$typeLabel $asset',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                      '${typeLabel == 'Buy' || typeLabel == 'Sell' ? '$typeLabel at $timeStr' : '$typeLabel at $timeStr'}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 109, 109, 109))),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$amountStr $asset',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  if (type == 'buy' || type == 'sell') ...[
                    Text('${totalStr} IDR',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 109, 109, 109))),
                    Text('$priceStr IDR',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 109, 109, 109))),
                  ]
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
