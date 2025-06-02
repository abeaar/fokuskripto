import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String spUsernameKey =
    'username'; // SUDAH KONSISTEN dengan LoginPage Anda
const String spIsLoginKey =
    'isLogin'; // Kunci untuk status login dari LoginPage Anda

const String spFullNameKeySuffix = 'full_name';
const String spEmailKeySuffix = 'email';
const String spPhoneNumberKeySuffix = 'phone_number';
const String spKesanPesanKeySuffix = 'kesan_pesan';
const String spProfilePicPathKeySuffix = 'profile_pic_path';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _currentLoggedInUsername =
      ""; // Untuk menyimpan username yang sedang login
  String _usernameDisplay =
      "Pengguna"; // Untuk tampilan (bisa sama dengan _currentLoggedInUsername)
  String _fullName = "Belum diatur";
  String _email = "Belum diatur";
  String _phoneNumber = "Belum diatur";
  String _kesanPesan = "Belum ada kesan dan pesan.";
  String? _profileImagePath;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    _currentLoggedInUsername =
        prefs.getString(spUsernameKey) ??
        ""; // Ambil username yang sedang login

    if (_currentLoggedInUsername.isNotEmpty) {
      _usernameDisplay =
          _currentLoggedInUsername; // Tampilkan username yang login
      // Muat data spesifik pengguna menggunakan username sebagai prefix
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
      _profileImagePath = prefs.getString(
        '${_currentLoggedInUsername}_$spProfilePicPathKeySuffix',
      );
    } else {
      _usernameDisplay = "Pengguna (Error)";
    }

    setState(() {
      _isLoading = false;
    });
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
    VoidCallback? onEdit,
    IconData? actionIcon = Icons.edit_outlined,
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
          if (onEdit != null)
            IconButton(
              icon: Icon(
                actionIcon,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: onEdit,
              iconSize: 20,
            )
          else if (label == "Username") //
            IconButton(
              icon: Icon(
                Icons.copy_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                /* Logika copy username */
              },
              iconSize: 20,
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
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  child:
                      _profileImagePath != null && _profileImagePath!.isNotEmpty
                          // ? ClipOval(child: Image.file(File(_profileImagePath!), fit: BoxFit.cover, width: 100, height: 100))
                          ? const Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.grey,
                          ) // Placeholder jika path ada tapi belum siap tampilkan
                          : const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          ),
                ),
                const SizedBox(height: 8),
                Container(/* ... Verified Badge ... */),
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
            onEdit: () {
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
            onEdit: () {
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
            onEdit: () {
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
