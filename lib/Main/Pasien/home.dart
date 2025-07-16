import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:apk_tb_care/Main/Pasien/consultation.dart';
import 'package:apk_tb_care/Main/Pasien/education.dart';
import 'package:apk_tb_care/connection.dart';
import 'package:apk_tb_care/profile.dart';
import 'package:apk_tb_care/Main/Pasien/treatment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apk_tb_care/values/colors.dart';

class HomePage extends StatefulWidget {
  final String name;
  final int userId;
  final int? patientId;

  const HomePage({
    super.key,
    required this.name,
    required this.userId,
    this.patientId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> _patientDataFuture;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _patientDataFuture = _fetchPatientData();
    _pages = [
      _buildHomePage(),
      TreatmentPage(patientId: widget.patientId ?? 0),
      const EducationPage(),
      const ConsultationPage(),
      const ProfilePage(),
    ];
  }

  Future<Map<String, dynamic>> _fetchPatientData() async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('${Connection.BASE_URL}/patients/${widget.patientId}/show'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to load patient data');
      }
    } catch (e) {
      log('Error fetching patient data: $e');
      return {};
    }
  }

  Widget _buildHomePage() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _patientDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
        }

        final patientData = snapshot.data!;
        final treatments = patientData['treatments'] as List<dynamic>? ?? [];
        final currentTreatment = treatments.isNotEmpty ? treatments[0] : null;
        final visits = currentTreatment?['visits'] as List<dynamic>? ?? [];

        // Add default health tips if not available
        final healthTips = [
          {
            'title': 'Minum Air yang Cukup',
            'description':
                'Pastikan minum 8 gelas air per hari untuk membantu pengobatan',
            'icon': Icons.local_drink,
          },
          {
            'title': 'Istirahat yang Cukup',
            'description': 'Tidur 7-8 jam per hari untuk pemulihan optimal',
            'icon': Icons.bedtime,
          },
          {
            'title': 'Makan Bergizi',
            'description': 'Konsumsi makanan tinggi protein dan vitamin',
            'icon': Icons.restaurant,
          },
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              _buildGreetingSection(),
              const SizedBox(height: 24),

              // Treatment Status Card (only show if treatment exists)
              if (currentTreatment != null) ...[
                _buildTreatmentCard(currentTreatment),
                const SizedBox(height: 24),
              ],

              // Upcoming Visits (only show if visits exist)
              if (visits.isNotEmpty) ...[
                _buildUpcomingEvents(visits),
                const SizedBox(height: 24),
              ],

              // Health Tips Section
              _buildHealthTips(healthTips),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hai, ${widget.name} 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selamat datang di aplikasi TB Care. Yuk jaga kesehatanmu!',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTreatmentCard(Map<String, dynamic> treatment) {
    final currentDay = _calculateCurrentDay(
      treatment['start_date'],
      treatment['end_date'],
    );
    final totalDays = _calculateTotalDays(
      treatment['start_date'],
      treatment['end_date'],
    );
    final progress = totalDays > 0 ? currentDay / totalDays : 0.0;
    final medicationTime =
        treatment['medication_time']?.substring(0, 5) ?? '--:--';
    final prescription = (treatment['prescription'] as List<dynamic>? ?? [])
        .join(', ');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Status Pengobatan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getTreatmentType(treatment['treatment_type_id']),
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            if (prescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Obat: $prescription',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hari ke-$currentDay dari $totalDays',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '${treatment['start_date'] ?? 'Tanggal mulai'} - ${treatment['end_date'] ?? 'Tanggal selesai'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(treatment['treatment_status'], true),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(
                        treatment['treatment_status'],
                        false,
                      ),
                    ),
                  ),
                  child: Text(
                    treatment['treatment_status'] ?? 'Status tidak tersedia',
                    style: TextStyle(
                      color: _getStatusTextColor(treatment['treatment_status']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengingat Minum Obat',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Setiap hari, $medicationTime WIB',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showUploadDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.medical_services,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text(
                  'SUDAH MINUM OBAT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(List<dynamic> visits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jadwal Mendatang',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children:
              visits.map((visit) {
                final date =
                    visit['visit_date'] != null
                        ? DateFormat(
                          'dd MMM yyyy',
                        ).format(DateTime.parse(visit['visit_date']))
                        : 'Tanggal tidak tersedia';
                final time = visit['visit_time']?.substring(0, 5) ?? '--:--';
                final status = visit['visit_status'] ?? 'Status tidak tersedia';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event, color: AppColors.primary),
                    ),
                    title: const Text(
                      'Kunjungan Pengobatan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('$date • $time • $status'),
                    trailing: const Icon(Icons.chevron_right),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.grey[50],
                    onTap: () => _showEventDetails(visit),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildHealthTips(List<Map<String, dynamic>> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tips Kesehatan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tip = tips[index];
              return SizedBox(
                width: 200,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(tip['icon'], color: AppColors.primary, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          tip['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tip['description'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper methods
  int _calculateCurrentDay(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 0;

    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final today = DateTime.now();

      if (today.isBefore(start)) return 0;
      if (today.isAfter(end)) return end.difference(start).inDays;

      return today.difference(start).inDays + 1; // +1 to include current day
    } catch (e) {
      return 0;
    }
  }

  int _calculateTotalDays(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 1;

    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return end.difference(start).inDays;
    } catch (e) {
      return 1;
    }
  }

  String _getTreatmentType(int? typeId) {
    switch (typeId) {
      case 1:
        return 'Pengobatan TB Aktif';
      case 2:
        return 'Pengobatan TB Laten';
      case 3:
        return 'Pengobatan TB MDR';
      default:
        return 'Jenis Pengobatan Tidak Diketahui';
    }
  }

  Color _getStatusColor(String? status, bool isBackground) {
    switch (status) {
      case 'Berjalan':
        return isBackground ? Colors.green[50]! : Colors.green;
      case 'Selesai':
        return isBackground ? Colors.blue[50]! : Colors.blue;
      case 'Terjadwal':
        return isBackground ? Colors.orange[50]! : Colors.orange;
      default:
        return isBackground ? Colors.grey[200]! : Colors.grey;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case 'Berjalan':
        return Colors.green[800]!;
      case 'Selesai':
        return Colors.blue[800]!;
      case 'Terjadwal':
        return Colors.orange[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  void _showEventDetails(Map<String, dynamic> visit) {
    final date =
        visit['visit_date'] != null
            ? DateFormat(
              'EEEE, dd MMMM yyyy',
              'id_ID',
            ).format(DateTime.parse(visit['visit_date']))
            : 'Tanggal tidak tersedia';
    final time = visit['visit_time']?.substring(0, 5) ?? '--:--';
    final status = visit['visit_status'] ?? 'Status tidak tersedia';
    final notes = visit['notes'] ?? 'Tidak ada catatan';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detail Kunjungan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal: $date'),
                Text('Waktu: $time'),
                Text('Status: $status'),
                Text('Catatan: $notes'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Minum Obat'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Apakah Anda sudah minum obat hari ini?')],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nanti'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showUploadOptions();
                },
                child: const Text('Konfirmasi'),
              ),
            ],
          ),
    );
  }

  void _showUploadOptions() {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Unggah Bukti Minum Obat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text('Ambil Foto'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? photo = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (photo != null) {
                      _handleSelectedImage(File(photo.path));
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      _handleSelectedImage(File(image.path));
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Konfirmasi obat berhasil dicatat'),
                      ),
                    );
                  },
                  child: const Text('Tanpa Foto'),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _uploadImage(File imageFile) async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Connection.BASE_URL}/treatments/proof'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath('photo', imageFile.path),
      );

      final response = await request.send();
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto berhasil diunggah')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload gagal: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi error: $e')));
    }
  }

  void _handleSelectedImage(File imageFile) async {
    await _uploadImage(imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'TB Care',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.healing_outlined),
            selectedIcon: Icon(Icons.healing),
            label: 'Pengobatan',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Edukasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Konsultasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
