import 'package:flutter/material.dart';
import 'package:fokuskripto/pages/Profile_Page.dart';
import 'DashboardTab.dart';
import 'MarketTab.dart';
import 'WalletTab.dart';
import 'TradeTab.dart'; // Pastikan TradeTab sudah diimpor

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(),
    MarketTab(),
    TradeTab(),
    WalletTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Profil Saya'), // Judul untuk halaman profil
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                leading: IconButton(
                  // Tambahkan tombol back secara eksplisit jika perlu
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: const ProfilePage(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tambahkan AppBar di sini jika ingin judul berbeda untuk setiap tab
    String title = 'Crypto App';
    if (_selectedIndex == 0) {
      title = 'Dashboard';
    } else if (_selectedIndex == 1) {
      title = 'Market';
    } else if (_selectedIndex == 2) {
      title = 'Trade';
    } else if (_selectedIndex == 3) {
      title = 'Wallet';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.person_2_outlined), // Ikon profil
            tooltip: 'Profil Pengguna',
            onPressed: () {
              _navigateToProfile(context); // Panggil fungsi navigasi
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex, // Index dari widget yang ingin ditampilkan
        children: _widgetOptions, // List semua widget tab Anda
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
            ), // Anda bisa ganti dengan Icons.home_filled jika mau
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.analytics_outlined,
            ), // atau Icons.store_mall_directory_outlined
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_outlined), // atau Icons.swap_horiz
            label: 'Trade',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.wallet_outlined,
            ), // atau Icons.account_balance_wallet_outlined
            label: 'Wallet',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: const Color.fromARGB(255, 122, 118, 118),
        showUnselectedLabels:
            true, // Pastikan ini true agar label selalu tampil
        type:
            BottomNavigationBarType
                .fixed, // Baik untuk 3-4 item agar perilaku konsisten
        onTap: _onItemTapped,
      ),
    );
  }
}
