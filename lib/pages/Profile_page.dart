// Untuk File
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/providers/trade_provider.dart';
import '../services/providers/wallet_provider.dart';
import '../services/providers/profile_provider.dart';

import '../widgets/profile/profile_info_header.dart';
import '../widgets/profile/profile_info_card.dart';
import '../widgets/profile/kesan_pesan_section.dart';
import '../widgets/profile/profile_info_row.dart';
import '../widgets/profile/profile_edit_dialog.dart';
import '../widgets/profile/timezone_picker_dialog.dart';
import '../widgets/profile/currency_picker_dialog.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Color.fromARGB(255, 59, 160, 63),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time,
                color: Color.fromARGB(255, 59, 160, 63)),
            tooltip: 'Pengaturan Waktu',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  String selectedZone = profile.selectedTimeZone;
                  return TimezonePickerDialog(
                    selectedTimeZone: profile.selectedTimeZone,
                    onSelected: (zone) {
                      selectedZone = zone;
                    },
                    onSaved: () {
                      profile.setTimeZone(selectedZone);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Zona waktu diubah ke ${profile.selectedTimeZone}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.currency_exchange,
                color: Color.fromARGB(255, 59, 160, 63)),
            tooltip: 'Pengaturan Mata Uang',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  String selected = profile.selectedCurrency;
                  return CurrencyPickerDialog(
                    selectedCurrency: profile.selectedCurrency,
                    onSelected: (cur) {
                      selected = cur;
                    },
                    onSaved: () {
                      profile.setCurrency(selected);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Mata uang diubah ke ${profile.selectedCurrency}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: profile.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ProfileHeaderSection(
                    profileImagePath: profile.profileImagePath,
                    usernameDisplay: profile.usernameDisplay,
                    onPickImage: () => profile.pickAndSaveImage(context),
                    currentTime: profile.currentTime,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'My Wallet:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  Text(
                    '${profile.currencySymbols[profile.selectedCurrency]} ' +
                        (profile.walletBalanceIdr * profile.currencyRate)
                            .toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ProfileInfoCard(
                    title: "Informasi Akun",
                    infoRows: [
                      ProfileInfoRow(
                        label: "Nama Lengkap",
                        value: profile.fullName,
                        onAction: () => showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => ProfileEditDialog(
                            fieldKeySuffix: 'full_name',
                            dialogTitle: "Nama Lengkap",
                            initialValue: profile.fullName == "Belum diatur"
                                ? ""
                                : profile.fullName,
                            onSave: (val) => profile.setFullName(val),
                            currentLoggedInUsername:
                                profile.currentLoggedInUsername,
                          ),
                        ),
                        actionIcon: Icons.edit_outlined,
                      ),
                      ProfileInfoRow(
                        label: "Username",
                        value: profile.usernameDisplay,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ProfileInfoCard(
                    title: "Informasi Pribadi",
                    infoRows: [
                      ProfileInfoRow(
                        label: "Email",
                        value: profile.email,
                        onAction: () => showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => ProfileEditDialog(
                            fieldKeySuffix: 'email',
                            dialogTitle: "Email",
                            initialValue: profile.email == "Belum diatur"
                                ? ""
                                : profile.email,
                            onSave: (val) => profile.setEmail(val),
                            currentLoggedInUsername:
                                profile.currentLoggedInUsername,
                          ),
                        ),
                        actionIcon: Icons.edit_outlined,
                      ),
                      ProfileInfoRow(
                        label: "Nomor Telepon",
                        value: profile.phoneNumber,
                        onAction: () => showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => ProfileEditDialog(
                            fieldKeySuffix: 'phone_number',
                            dialogTitle: "Nomor Telepon",
                            initialValue: profile.phoneNumber == "Belum diatur"
                                ? ""
                                : profile.phoneNumber,
                            onSave: (val) => profile.setPhoneNumber(val),
                            currentLoggedInUsername:
                                profile.currentLoggedInUsername,
                          ),
                        ),
                        actionIcon: Icons.edit_outlined,
                      ),
                      ProfileInfoRow(
                        label: "Lokasi Saat Ini",
                        value: profile.isFetchingLocation
                            ? "Memuat lokasi..."
                            : profile.locationMessage,
                        onAction: profile.getCurrentLocationAndUpdateUI,
                        actionIcon: Icons.refresh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  KesanPesanSection(
                    kesanPesan: profile.kesanPesan,
                    onEditKesanPesan: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => ProfileEditDialog(
                          fieldKeySuffix: 'kesan_pesan',
                          dialogTitle: "Kesan dan Pesan",
                          initialValue:
                              profile.kesanPesan == "Belum ada kesan dan pesan."
                                  ? ""
                                  : profile.kesanPesan,
                          onSave: (newValue) => profile.setKesanPesan(newValue),
                          currentLoggedInUsername:
                              profile.currentLoggedInUsername,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('isLogin', false);
                        await prefs.remove('username');
                        Provider.of<WalletProvider>(context, listen: false)
                            .resetWallet();
                        Provider.of<TradeProvider>(context, listen: false)
                            .dispose();
                        appKeyNotifier.value = Key(DateTime.now().toString());
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login_page', (Route<dynamic> route) => false);
                        }
                        Provider.of<ProfileProvider>(context, listen: false)
                            .loadAllProfileData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
