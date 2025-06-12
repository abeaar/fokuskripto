import 'package:flutter/material.dart';

class CurrencyPickerDialog extends StatefulWidget {
  final String selectedCurrency;
  final ValueChanged<String> onSelected;
  final VoidCallback onSaved;

  const CurrencyPickerDialog({
    super.key,
    required this.selectedCurrency,
    required this.onSelected,
    required this.onSaved,
  });

  @override
  State<CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<CurrencyPickerDialog> {
  late String selected;
  final List<String> currencies = ['IDR', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    selected = widget.selectedCurrency;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Mata Uang'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: currencies.map((cur) {
          return RadioListTile<String>(
            title: Text(cur),
            value: cur,
            groupValue: selected,
            onChanged: (value) {
              setState(() {
                selected = value!;
              });
              widget.onSelected(selected);
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          child: const Text('Batal'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Simpan'),
          onPressed: () {
            widget.onSaved();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
