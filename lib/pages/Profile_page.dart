import 'dart:io'; // Untuk File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
const String spProfilePicPathBKeySuffix = 'profile_pic_path_b';
const String spActiveProfilePicSlotKeySuffix = 'profile_pic_active_slot';

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
    _loadProfileData();
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

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

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
      _phoneNumber =
          prefs.getString(
            '${_currentLoggedInUsername}_$spPhoneNumberKeySuffix',
          ) ??
          "Belum diatur";
      _kesanPesan =
          prefs.getString(
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
    }
    setState(() {
      _isLoading = false;
    });
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Column(
              children: [
                InkWell(
                  onTap: _pickAndSaveImage,
                  child: CircleAvatar(
                    radius: 100,
                    backgroundColor: Colors.grey[300],
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 95,
                          key: ValueKey<String?>(_profileImagePath),
                          backgroundImage:
                              _profileImagePath != null &&
                                      File(_profileImagePath!).existsSync()
                                  ? FileImage(File(_profileImagePath!))
                                  : null,
                          child:
                              _profileImagePath == null ||
                                      !File(_profileImagePath!).existsSync()
                                  ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white70,
                                  )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Profile Info",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 20),
          _buildProfileInfoRow(
            "Full name",
            _fullName,
            onAction: () {
              _showEditDialog(
                fieldKeySuffix: spFullNameKeySuffix,
                dialogTitle: "Nama Lengkap",
                initialValue: _fullName == "Haven't sign" ? "" : _fullName,
                onSave: (newValue) {
                  setState(() {
                    _fullName = newValue.isNotEmpty ? newValue : "Haven't sign";
                  });
                },
              );
            },
          ),
          _buildProfileInfoRow("Username", _usernameDisplay),
          const SizedBox(height: 24),
          Text(
            "Personal Information",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 20),
          _buildProfileInfoRow(
            "Email Address",
            _email,
            onAction: () {
              _showEditDialog(
                fieldKeySuffix: spEmailKeySuffix,
                dialogTitle: "Email Address",
                initialValue: _email == "Haven't sign" ? "" : _email,
                onSave: (newValue) {
                  setState(() {
                    _email = newValue.isNotEmpty ? newValue : "Haven't sign";
                  });
                },
              );
            },
          ),
          _buildProfileInfoRow(
            "Phone Number",
            _phoneNumber,
            onAction: () {
              _showEditDialog(
                fieldKeySuffix: spPhoneNumberKeySuffix,
                dialogTitle: "phone number",
                initialValue:
                    _phoneNumber == "Haven't sign" ? "" : _phoneNumber,
                onSave: (newValue) {
                  setState(() {
                    _phoneNumber =
                        newValue.isNotEmpty ? newValue : "Haven't sign";
                  });
                },
              );
            },
          ),
          _buildProfileInfoRow(
            "Lokasi Saat Ini", 
            _isFetchingLocation
                ? "Memuat lokasi..."
                : _locationMessage, // Value yang ditampilkan
            onAction:
                _getCurrentLocationAndUpdateUI, // Aksi saat tombol ditekan
            actionIcon: Icons.refresh, // Ikon refresh
          ),
          const SizedBox(height: 24),
          Text(
            "Kesan dan Pesan",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(/* ... */),
            child: Text(
              _kesanPesan.isNotEmpty
                  ? _kesanPesan
                  : "Belum ada kesan dan pesan.",
              style: TextStyle(
                fontSize: 15,
                color:
                    _kesanPesan.isNotEmpty ? Colors.black87 : Colors.grey[600],
              ),
              maxLines: null,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                "Edit Kesan & Pesan",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              onPressed: () {
                _showEditDialog(
                  fieldKeySuffix: spKesanPesanKeySuffix,
                  dialogTitle: "kesan dan pesan",
                  initialValue:
                      _kesanPesan == "Haven't sign" ? "" : _kesanPesan,
                  onSave: (newValue) {
                    setState(() {
                      _kesanPesan =
                          newValue.isNotEmpty ? newValue : "Haven't sign";
                    });
                  },
                );
              },
            ),
          ),
          const Divider(height: 20),
          Align(/* ... Tombol Edit Kesan Pesan ... */),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              onPressed: _handleLogout,
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}