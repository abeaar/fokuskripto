import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditDialog extends StatefulWidget {
  final String fieldKeySuffix;
  final String dialogTitle;
  final String initialValue;
  final Function(String) onSave;
  final String currentLoggedInUsername;

  const ProfileEditDialog({
    super.key,
    required this.fieldKeySuffix,
    required this.dialogTitle,
    required this.initialValue,
    required this.onSave,
    required this.currentLoggedInUsername,
  });

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = controller.text.trim();
    if (widget.currentLoggedInUsername.isNotEmpty) {
      await prefs.setString(
        '${widget.currentLoggedInUsername}_${widget.fieldKeySuffix}',
        newValue,
      );
      widget.onSave(newValue);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Masukkan ${widget.dialogTitle}",
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Batal'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Simpan'),
          onPressed: _save,
        ),
      ],
    );
  }
}
