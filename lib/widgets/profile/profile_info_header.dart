import 'dart:io';
import 'package:flutter/material.dart';

class ProfileHeaderSection extends StatelessWidget {
  final String? profileImagePath;
  final String usernameDisplay; // Atau bisa juga nama lengkap
  final VoidCallback onPickImage; // Callback untuk memilih gambar
  final String currentTime;

  const ProfileHeaderSection({
    super.key,
    required this.profileImagePath,
    required this.usernameDisplay, // Atau bisa tampilkan _fullName
    required this.onPickImage,
    required this.currentTime,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          InkWell(
            onTap: onPickImage,
            child: CircleAvatar(
              radius: 110, // Sesuaikan
              backgroundColor: Colors.grey[200],
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 100,
                    key: ValueKey<String?>(
                      profileImagePath ?? DateTime.now().toString(),
                    ),
                    backgroundColor: Colors.grey[300],
                    backgroundImage: profileImagePath != null &&
                            File(profileImagePath!).existsSync()
                        ? FileImage(File(profileImagePath!)) as ImageProvider
                        : const AssetImage(
                            "assets/images/placeholder_profile.png",
                          ), // Sediakan placeholder
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            // Verified Badge
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 4),
                Text(
                  "Verified",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentTime,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
