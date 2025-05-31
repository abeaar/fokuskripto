import 'package:flutter/material.dart';
import 'package:fokuskripto/pages/Profile_Page,.dart';
import 'DashboardTab.dart'; // <- IMPORT BARU
import 'MarketTab.dart'; // <- IMPORT BARU

class ConverterTab extends StatelessWidget {
  const ConverterTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Ini adalah Tab Konverter', style: TextStyle(fontSize: 20)),
    );
  }
}

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Ini adalah Tab wallet', style: TextStyle(fontSize: 20)),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Gunakan DashboardTab yang baru diimpor
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(),
    MarketTab(),
    ConverterTab(),
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
      title = 'Konverter';
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
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_outlined),
            label: 'Trade',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet_outlined),
            label: 'Wallet',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: const Color.fromARGB(255, 122, 118, 118),
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
