import 'package:flutter/material.dart';

class ProfileInfoCard extends StatelessWidget {
  final String title;
  final List<Widget>
      infoRows; // List dari _buildProfileInfoRow yang sudah dibuat

  const ProfileInfoCard({
    super.key,
    required this.title,
    required this.infoRows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 59, 160, 63),
              ),
        ),
        const Divider(thickness: 1.5),
        ...infoRows, // Spread operator untuk memasukkan semua widget row
      ],
    );
  }
}
