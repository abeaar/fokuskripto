import 'package:flutter/material.dart';

class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final Widget? valueWidget;

  const ProfileInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.onAction,
    this.actionIcon = Icons.edit_outlined,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 2),
                valueWidget ??
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              ],
            ),
          ),
          if (onAction != null)
            IconButton(
              icon: Icon(
                actionIcon,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: onAction,
              iconSize: 20,
            )
          else if (label == "Username" && valueWidget == null)
            IconButton(
              icon: Icon(
                Icons.copy_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {},
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
