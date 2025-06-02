import 'package:flutter/material.dart';

class KesanPesanSection extends StatelessWidget {
  final String kesanPesan;
  final VoidCallback onEditKesanPesan;

  const KesanPesanSection({
    super.key,
    required this.kesanPesan,
    required this.onEditKesanPesan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Kesan dan Pesan Kuliah",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const Divider(thickness: 1.5),
        InkWell(
          onTap: onEditKesanPesan,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    kesanPesan.isNotEmpty && kesanPesan != "Belum ada kesan dan pesan." 
                        ? kesanPesan 
                        : "Belum ada kesan dan pesan. Ketuk untuk menambah.",
                    style: TextStyle(
                        fontSize: 15,
                        color: kesanPesan.isNotEmpty && kesanPesan != "Belum ada kesan dan pesan."
                            ? Colors.black87
                            : Colors.grey[600]),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}