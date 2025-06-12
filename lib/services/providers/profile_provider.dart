import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProfileProvider extends ChangeNotifier {
  String currentLoggedInUsername = "";
  String usernameDisplay = "Pengguna";
  String fullName = "Belum diatur";
  String email = "Belum diatur";
  String phoneNumber = "Belum diatur";
  String kesanPesan = "Belum ada kesan dan pesan.";
  String? profileImagePath;
  String locationMessage = "Sedang mencari lokasi...";
  bool isFetchingLocation = false;
  bool isLoading = true;
  final ImagePicker picker = ImagePicker();
  String selectedTimeZone = 'WIB';
  String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
  String selectedCurrency = 'IDR';
  double currencyRate = 1.0;
  double walletBalanceIdr = 0.0;

  Map<String, double> currencyRates = {
    'IDR': 1.0,
    'USD': 0.000062,
    'EUR': 0.000057,
    'GBP': 0.000049,
  };
  Map<String, String> currencySymbols = {
    'IDR': 'Rp',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
  };

  ProfileProvider() {
    loadAllProfileData();
    getCurrentLocationAndUpdateUI();
    loadWalletBalance();
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      currentTime = getConvertedTime();
      notifyListeners();
    });
  }

  String getConvertedTime() {
    final nowUtc = DateTime.now().toUtc();
    int offset;
    switch (selectedTimeZone) {
      case 'WIB':
        offset = 7;
        break;
      case 'WITA':
        offset = 8;
        break;
      case 'WIT':
        offset = 9;
        break;
      case 'London':
        offset = 0;
        break;
      default:
        offset = 7;
    }
    final converted = nowUtc.add(Duration(hours: offset));
    return DateFormat('HH:mm:ss').format(converted);
  }

  Future<void> getCurrentLocationAndUpdateUI() async {
    isFetchingLocation = true;
    locationMessage = "Sedang mencari lokasi...";
    notifyListeners();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      locationMessage = 'Layanan lokasi tidak aktif.';
      isFetchingLocation = false;
      notifyListeners();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        locationMessage = 'Izin lokasi ditolak.';
        isFetchingLocation = false;
        notifyListeners();
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      locationMessage =
          'Izin lokasi ditolak permanen, buka pengaturan aplikasi.';
      isFetchingLocation = false;
      notifyListeners();
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
          locationMessage = address;
        } else {
          locationMessage = "Alamat tidak ditemukan.";
        }
      } catch (e) {
        locationMessage =
            "Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)} (Gagal geocode)";
      }
    } catch (e) {
      locationMessage = "Gagal mendapatkan lokasi: ${e.toString()}";
    } finally {
      isFetchingLocation = false;
      notifyListeners();
    }
  }

  Future<void> loadAllProfileData() async {
    isLoading = false;
    notifyListeners();
    await loadProfileDataFromPrefs();
    await getCurrentLocationAndUpdateUI();
    await loadWalletBalance();
  }

  Future<void> loadProfileDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    currentLoggedInUsername = prefs.getString('username') ?? "";
    if (currentLoggedInUsername.isNotEmpty) {
      usernameDisplay = currentLoggedInUsername;
      fullName = prefs.getString('${currentLoggedInUsername}_full_name') ??
          "Belum diatur";
      email =
          prefs.getString('${currentLoggedInUsername}_email') ?? "Belum diatur";
      phoneNumber =
          prefs.getString('${currentLoggedInUsername}_phone_number') ??
              "Belum diatur";
      kesanPesan = prefs.getString('${currentLoggedInUsername}_kesan_pesan') ??
          "Belum ada kesan dan pesan.";
      String? activeSlot =
          prefs.getString('${currentLoggedInUsername}_profile_pic_active_slot');
      if (activeSlot == 'a') {
        profileImagePath =
            prefs.getString('${currentLoggedInUsername}_profile_pic_path_a');
      } else if (activeSlot == 'b') {
        profileImagePath =
            prefs.getString('${currentLoggedInUsername}_profile_pic_path_b');
      } else {
        profileImagePath = null;
      }
    } else {
      usernameDisplay = "Pengguna (Error)";
      profileImagePath = null;
      fullName = "Belum diatur";
      email = "Belum diatur";
      phoneNumber = "Belum diatur";
      kesanPesan = "Belum ada kesan dan pesan.";
    }
    notifyListeners();
  }

  Future<void> pickAndSaveImage(BuildContext context) async {
    final XFile? pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(
                    context,
                    await picker.pickImage(source: ImageSource.gallery),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () async {
                  Navigator.pop(
                    context,
                    await picker.pickImage(source: ImageSource.camera),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
    if (pickedFile != null && currentLoggedInUsername.isNotEmpty) {
      final File imageFileFromPicker = File(pickedFile.path);
      final Directory appDir = await getApplicationDocumentsDirectory();
      final prefs = await SharedPreferences.getInstance();
      String? currentActiveSlot =
          prefs.getString('${currentLoggedInUsername}_profile_pic_active_slot');
      String newSlotKeySuffix;
      String oldSlotKeySuffix;
      String newSlotIdentifier;
      if (currentActiveSlot == 'a') {
        newSlotKeySuffix = 'profile_pic_path_b';
        oldSlotKeySuffix = 'profile_pic_path_a';
        newSlotIdentifier = 'b';
      } else {
        newSlotKeySuffix = 'profile_pic_path_a';
        oldSlotKeySuffix = 'profile_pic_path_b';
        newSlotIdentifier = 'a';
      }
      final String fileName =
          'profile_pic_${currentLoggedInUsername}_$newSlotIdentifier${path.extension(pickedFile.path)}';
      final String newImageAbsPath = path.join(appDir.path, fileName);
      final File newImageFileToSave = File(newImageAbsPath);
      try {
        if (await newImageFileToSave.exists()) {
          await newImageFileToSave.delete();
        }
        await imageFileFromPicker.copy(newImageAbsPath);
        await prefs.setString(
            '${currentLoggedInUsername}_$newSlotKeySuffix', newImageAbsPath);
        await prefs.setString(
            '${currentLoggedInUsername}_profile_pic_active_slot',
            newSlotIdentifier);
        String? oldImagePath =
            prefs.getString('${currentLoggedInUsername}_$oldSlotKeySuffix');
        if (oldImagePath != null &&
            oldImagePath.isNotEmpty &&
            oldImagePath != newImageAbsPath) {
          final File oldImageFile = File(oldImagePath);
          if (await oldImageFile.exists()) {
            await oldImageFile.delete();
            await prefs.remove('${currentLoggedInUsername}_$oldSlotKeySuffix');
          }
        }
        profileImagePath = newImageAbsPath;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan foto profil.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> loadWalletBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    if (username.isEmpty) {
      walletBalanceIdr = 0;
      notifyListeners();
      return;
    }
    final box = await Hive.openBox('wallet_$username');
    final idrAsset = box.get('IDR', defaultValue: {'amount': 0});
    walletBalanceIdr = (idrAsset['amount'] as num?)?.toDouble() ?? 0.0;
    notifyListeners();
  }

  void setTimeZone(String zone) {
    selectedTimeZone = zone;
    currentTime = getConvertedTime();
    notifyListeners();
  }

  void setCurrency(String currency) {
    selectedCurrency = currency;
    currencyRate = currencyRates[selectedCurrency]!;
    notifyListeners();
  }

  void setFullName(String name) {
    fullName = name.isNotEmpty ? name : "Belum diatur";
    notifyListeners();
  }

  void setEmail(String mail) {
    email = mail.isNotEmpty ? mail : "Belum diatur";
    notifyListeners();
  }

  void setPhoneNumber(String phone) {
    phoneNumber = phone.isNotEmpty ? phone : "Belum diatur";
    notifyListeners();
  }

  void setKesanPesan(String pesan) {
    kesanPesan = pesan.isNotEmpty ? pesan : "Belum ada kesan dan pesan.";
    notifyListeners();
  }
}
