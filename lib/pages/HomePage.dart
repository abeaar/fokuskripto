import 'package:flutter/material.dart';

// Hapus placeholder DashboardTab, ConverterTab, ProfileTab yang lama jika ada di file ini.
// Import file tab yang sebenarnya
import 'DashboardTab.dart'; // <- IMPORT BARU

// --- Halaman Placeholder untuk Tab Lain (jika belum dibuat file terpisah) ---
class ConverterTab extends StatelessWidget {
  // Biarkan ini atau buat file terpisah nanti
  const ConverterTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Ini adalah Tab Konverter', style: TextStyle(fontSize: 20)),
    );
  }
}

class ProfileTab extends StatelessWidget {
  // Biarkan ini atau buat file terpisah nanti
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Ini adalah Tab Profil', style: TextStyle(fontSize: 20)),
    );
  }
}
// --- Akhir Halaman Placeholder ---

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Gunakan DashboardTab yang baru diimpor
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(), // <- GUNAKAN DashboardTab YANG BARU
    ConverterTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tambahkan AppBar di sini jika ingin judul berbeda untuk setiap tab
    String title = 'Crypto App';
    if (_selectedIndex == 0) {
      title = 'Dashboard';
    } else if (_selectedIndex == 1) {
      title = 'Konverter';
    } else if (_selectedIndex == 2) {
      title = 'Profil';
    }

    return Scaffold(
      appBar: AppBar(
        // AppBar ditambahkan di sini
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        // ... (sisa kode BottomNavigationBar tetap sama)
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Konverter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
