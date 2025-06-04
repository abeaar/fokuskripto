import 'dart:io'; // Untuk File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../widgets/profile_info_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/kesan_pesan_section.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

const String spUsernameKey = 'username';
const String spIsLoginKey = 'isLogin';
const String spFullNameKeySuffix = 'full_name';
const String spEmailKeySuffix = 'email';
const String spPhoneNumberKeySuffix = 'phone_number';
const String spKesanPesanKeySuffix = 'kesan_pesan';
const String spProfilePicPathAKeySuffix = 'profile_pic_path_a';
const String spActiveProfilePicSlotKeySuffix = 'profile_pic_active_slot';
const String spProfilePicPathBKeySuffix = 'profile_pic_path_b';

class _ProfilePageState extends State<ProfilePage> {
  String _currentLoggedInUsername = "";
  String _usernameDisplay = "Pengguna";
  String _fullName = "Belum diatur";
  String _email = "Belum diatur";
  String _phoneNumber = "Belum diatur";
  String _kesanPesan = "Belum ada kesan dan pesan.";
  String? _profileImagePath;
  String _locationMessage = "Sedang mencari lokasi...";
  bool _isFetchingLocation = false;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker(); //
  @override
  void initState() {
    super.initState();
    _loadAllProfileData();
    _getCurrentLocationAndUpdateUI();
  }

  Future<void> _getCurrentLocationAndUpdateUI() async {
    if (!mounted) return;
    setState(() {
      _isFetchingLocation = true;
      _locationMessage = "Sedang mencari lokasi...";
    });

    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        _locationMessage = 'Layanan lokasi tidak aktif.';
        _isFetchingLocation = false;
      });
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _locationMessage = 'Izin lokasi ditolak.';
          _isFetchingLocation = false;
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        _locationMessage =
            'Izin lokasi ditolak permanen, buka pengaturan aplikasi.';
        _isFetchingLocation = false;
      });
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Akurasi bisa disesuaikan
      );
      if (!mounted) return;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
          setState(() {
            _locationMessage = address;
          });
        } else {
          _locationMessage = "Alamat tidak ditemukan.";
        }
      } catch (e) {
        print("Error geocoding: $e");
        _locationMessage =
            "Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)} (Gagal geocode)";
      }
    } catch (e) {
      print("Error mendapatkan lokasi: $e");
      if (!mounted) return;
      _locationMessage = "Gagal mendapatkan lokasi: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _loadAllProfileData() async {
    setState(() {
      _isLoading = false;
    });
    await _loadProfileDataFromPrefs();
    await _getCurrentLocationAndUpdateUI();
  }

  Future<void> _loadProfileDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLoggedInUsername = prefs.getString(spUsernameKey) ?? "";

    if (_currentLoggedInUsername.isNotEmpty) {
      _usernameDisplay = _currentLoggedInUsername;
      _fullName =
          prefs.getString('${_currentLoggedInUsername}_$spFullNameKeySuffix') ??
              "Belum diatur";
      _email =
          prefs.getString('${_currentLoggedInUsername}_$spEmailKeySuffix') ??
              "Belum diatur";
      _phoneNumber = prefs.getString(
            '${_currentLoggedInUsername}_$spPhoneNumberKeySuffix',
          ) ??
          "Belum diatur";
      _kesanPesan = prefs.getString(
            '${_currentLoggedInUsername}_$spKesanPesanKeySuffix',
          ) ??
          "Belum ada kesan dan pesan.";

      String? activeSlot = prefs.getString(
        '${_currentLoggedInUsername}_$spActiveProfilePicSlotKeySuffix',
      );
      if (activeSlot == 'a') {
        _profileImagePath = prefs.getString(
          '${_currentLoggedInUsername}_$spProfilePicPathAKeySuffix',
        );
      } else if (activeSlot == 'b') {
        _profileImagePath = prefs.getString(
          '${_currentLoggedInUsername}_$spProfilePicPathBKeySuffix',
        );
      } else {
        _profileImagePath = null;
      }
    } else {
      _usernameDisplay = "Pengguna (Error)";
      _profileImagePath = null;
      // Set semua field ke default jika tidak ada user
      _fullName = "Belum diatur";
      _email = "Belum diatur";
      _phoneNumber = "Belum diatur";
      _kesanPesan = "Belum ada kesan dan pesan.";
    }
    // setState akan dipanggil oleh _loadAllProfileData
  }

  Future<void> _pickAndSaveImage() async {
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
                    await _picker.pickImage(source: ImageSource.gallery),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () async {
                  Navigator.pop(
                    context,
                    await _picker.pickImage(source: ImageSource.camera),
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (pickedFile != null && _currentLoggedInUsername.isNotEmpty) {
      final File imageFileFromPicker = File(pickedFile.path);
      final Directory appDir = await getApplicationDocumentsDirectory();
      final prefs = await SharedPreferences.getInstance();

      String? currentActiveSlot = prefs.getString(
        '${_currentLoggedInUsername}_$spActiveProfilePicSlotKeySuffix',
      );
      String newSlotKeySuffix;
      String oldSlotKeySuffix;
      String newSlotIdentifier; // 'a' atau 'b'

      if (currentActiveSlot == 'a') {
        newSlotKeySuffix = spProfilePicPathBKeySuffix; // Simpan ke B
        oldSlotKeySuffix = spProfilePicPathAKeySuffix;
        newSlotIdentifier = 'b';
      } else {
        newSlotKeySuffix = spProfilePicPathAKeySuffix; // Simpan ke A
        oldSlotKeySuffix = spProfilePicPathBKeySuffix;
        newSlotIdentifier = 'a';
      }

      final String fileName =
          'profile_pic_${_currentLoggedInUsername}_$newSlotIdentifier${path.extension(pickedFile.path)}';
      final String newImageAbsPath = path.join(appDir.path, fileName);
      final File newImageFileToSave = File(newImageAbsPath);

      try {
        if (await newImageFileToSave.exists()) {
          await newImageFileToSave.delete();
        }
        await imageFileFromPicker.copy(newImageAbsPath);
        print(
          "Gambar profil baru disimpan ke: $newImageAbsPath (Slot $newSlotIdentifier)",
        );
        await prefs.setString(
          '${_currentLoggedInUsername}_$newSlotKeySuffix',
          newImageAbsPath,
        );
        await prefs.setString(
          '${_currentLoggedInUsername}_$spActiveProfilePicSlotKeySuffix',
          newSlotIdentifier,
        );
        String? oldImagePath = prefs.getString(
          '${_currentLoggedInUsername}_$oldSlotKeySuffix',
        );
        if (oldImagePath != null &&
            oldImagePath.isNotEmpty &&
            oldImagePath != newImageAbsPath) {
          final File oldImageFile = File(oldImagePath);
          if (await oldImageFile.exists()) {
            await oldImageFile.delete();
            print(
              "Gambar profil lama di slot ${oldSlotKeySuffix == spProfilePicPathAKeySuffix ? 'A' : 'B'} dihapus: $oldImagePath",
            );
            await prefs.remove('${_currentLoggedInUsername}_$oldSlotKeySuffix');
          }
        }

        if (!mounted) return;
        setState(() {
          _profileImagePath = newImageAbsPath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print("Error menyimpan/menyalin/menghapus gambar: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan foto profil.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(spIsLoginKey, false);
    await prefs.remove(
      spUsernameKey,
    ); // Menghapus siapa pengguna yang sedang aktif

    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/login_page', (Route<dynamic> route) => false);
    }
  }

  Future<void> _showEditDialog({
    required String fieldKeySuffix,
    required String dialogTitle,
    required String initialValue,
    required Function(String) onSave,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initialValue,
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Masukkan $dialogTitle",
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
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final newValue = controller.text.trim();
                if (_currentLoggedInUsername.isNotEmpty) {
                  await prefs.setString(
                    '${_currentLoggedInUsername}_$fieldKeySuffix',
                    newValue,
                  );
                  onSave(newValue);
                }
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileInfoRow(
    String label,
    String value, {
    VoidCallback? onAction, // Menggunakan onAction
    IconData? actionIcon = Icons.edit_outlined,
    Widget? valueWidget,
  }) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ProfileHeaderSection(
                    profileImagePath: _profileImagePath,
                    usernameDisplay: _usernameDisplay, // atau _fullName
                    onPickImage: _pickAndSaveImage,
                  ),
                  const SizedBox(height: 30),
                  ProfileInfoCard(
                    title: "Informasi Akun",
                    infoRows: [
                      _buildProfileInfoRow(
                        "Nama Lengkap",
                        _fullName,
                        onAction: () => _showEditDialog(
                          fieldKeySuffix: spFullNameKeySuffix,
                          dialogTitle: "Nama Lengkap",
                          initialValue:
                              _fullName == "Belum diatur" ? "" : _fullName,
                          onSave: (val) => setState(
                            () => _fullName =
                                val.isNotEmpty ? val : "Belum diatur",
                          ),
                        ),
                        actionIcon: Icons.edit_outlined,
                      ),
                      _buildProfileInfoRow(
                        "Username",
                        _usernameDisplay,
                      ), // Tanpa aksi edit
                    ],
                  ),
                  const SizedBox(height: 20),
                  ProfileInfoCard(
                    title: "Informasi Pribadi",
                    infoRows: [
                      _buildProfileInfoRow(
                        "Email",
                        _email,
                        onAction: () => _showEditDialog(
                          fieldKeySuffix: spEmailKeySuffix,
                          dialogTitle: "Email",
                          initialValue: _email == "Belum diatur" ? "" : _email,
                          onSave: (val) => setState(
                            () =>
                                _email = val.isNotEmpty ? val : "Belum diatur",
                          ),
                        ),
                        actionIcon: Icons.edit_outlined,
                      ),
                      _buildProfileInfoRow(
                        "Nomor Telepon",
                        _phoneNumber,
                        onAction: () => _showEditDialog(
                          fieldKeySuffix: spPhoneNumberKeySuffix,
                          dialogTitle: "Nomor Telepon",
                          initialValue: _phoneNumber == "Belum diatur"
                              ? ""
                              : _phoneNumber,
                          onSave: (val) => setState(
                            () => _phoneNumber =
                                val.isNotEmpty ? val : "Belum diatur",
                          ),
                        ),
                        actionIcon: Icons.edit_outlined,
                      ),
                      _buildProfileInfoRow(
                        "Lokasi Saat Ini",
                        _isFetchingLocation
                            ? "Memuat lokasi..."
                            : _locationMessage,
                        onAction: _getCurrentLocationAndUpdateUI,
                        actionIcon: Icons.refresh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  KesanPesanSection(
                    kesanPesan: _kesanPesan,
                    onEditKesanPesan: () {
                      _showEditDialog(
                        fieldKeySuffix: spKesanPesanKeySuffix,
                        dialogTitle: "Kesan dan Pesan",
                        initialValue:
                            _kesanPesan == "Belum ada kesan dan pesan."
                                ? ""
                                : _kesanPesan,
                        onSave: (newValue) => setState(
                          () => _kesanPesan = newValue.isNotEmpty
                              ? newValue
                              : "Belum ada kesan dan pesan.",
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      onPressed: _handleLogout,
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
