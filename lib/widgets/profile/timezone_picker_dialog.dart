import 'package:flutter/material.dart';

class TimezonePickerDialog extends StatefulWidget {
  final String selectedTimeZone;
  final ValueChanged<String> onSelected;
  final VoidCallback onSaved;

  const TimezonePickerDialog({
    super.key,
    required this.selectedTimeZone,
    required this.onSelected,
    required this.onSaved,
  });

  @override
  State<TimezonePickerDialog> createState() => _TimezonePickerDialogState();
}

class _TimezonePickerDialogState extends State<TimezonePickerDialog> {
  late String selectedZone;
  final List<String> timeZones = ['WIB', 'WITA', 'WIT', 'London'];

  @override
  void initState() {
    super.initState();
    selectedZone = widget.selectedTimeZone;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Zona Waktu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: timeZones.map((zone) {
          return RadioListTile<String>(
            title: Text(zone),
            value: zone,
            groupValue: selectedZone,
            onChanged: (value) {
              setState(() {
                selectedZone = value!;
              });
              widget.onSelected(selectedZone);
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
