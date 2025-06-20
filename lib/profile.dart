import 'package:apk_tb_care/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Simulate API call to GET /api/profile
    await Future.delayed(const Duration(seconds: 1));

    // Mock data based on your database structure
    setState(() {
      _userData = {
        'id': 1,
        'name': 'Budi Santoso',
        'email': 'budi@example.com',
        'username': 'budisantoso',
        'address': 'Jl. Merdeka No. 10, Jakarta',
        'gender': 'Laki-laki',
        'date_of_birth': '1990-05-15',
        'telephone': '081234567890',
        'profile': 'https://example.com/profiles/budi.jpg',
        'user_type_id': 2, // 2 for patient, 1 for staff
        'created_at': '2023-01-10T08:30:00Z',
      };
      _isLoading = false;
    });
  }

  String _getUserType() {
    return _userData['user_type_id'] == 1 ? 'Petugas Kesehatan' : 'Pasien';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Keluar'),
            content: const Text('Yakin ingin keluar dari aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // Clear session
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to login (replace with your actual navigation)
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileEditPage(userData: _userData),
                  ),
                ).then((_) => _loadUserData()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        _userData['profile'] != null
                            ? CachedNetworkImageProvider(_userData['profile'])
                            : null,
                    child:
                        _userData['profile'] == null
                            ? Text(
                              _userData['name'][0].toUpperCase(),
                              style: const TextStyle(fontSize: 28),
                            )
                            : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData['name'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getUserType(),
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Pribadi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow('Username', _userData['username']),
                    _buildInfoRow('Email', _userData['email']),
                    _buildInfoRow('Telepon', _userData['telephone']),
                    _buildInfoRow(
                      'Tanggal Lahir',
                      DateFormat(
                        'dd MMMM yyyy',
                      ).format(DateTime.parse(_userData['date_of_birth'])),
                    ),
                    _buildInfoRow('Jenis Kelamin', _userData['gender']),
                    _buildInfoRow('Alamat', _userData['address']),
                    _buildInfoRow(
                      'Bergabung Pada',
                      DateFormat(
                        'dd MMMM yyyy',
                      ).format(DateTime.parse(_userData['created_at'])),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_userData['user_type_id'] == 2) // Patient features
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.medical_services),
                    title: const Text('Riwayat Pengobatan'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to treatment history
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.medication),
                    title: const Text('Pengingat Minum Obat'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to medication reminders
                    },
                  ),
                ],
              ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
