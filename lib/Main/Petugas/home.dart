import 'package:apk_tb_care/Main/Petugas/consultation.dart';
import 'package:apk_tb_care/Main/Petugas/education.dart';
import 'package:apk_tb_care/Main/Petugas/patient.dart';
import 'package:apk_tb_care/profile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:apk_tb_care/values/colors.dart';

class StaffHomePage extends StatefulWidget {
  final String name;

  const StaffHomePage({super.key, required this.name});

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> _staffHomeData;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _staffHomeData = _fetchStaffHomeData();
    _pages = [
      _buildStaffHomePage(),
      PatientPage(),
      StaffEducationPage(),
      StaffConsultationPage(),
      ProfilePage(),
    ];
  }

  Future<Map<String, dynamic>> _fetchStaffHomeData() async {
    // Simulate API calls
    await Future.delayed(Duration(seconds: 1));

    return {
      'patient_count': 24,
      'new_patients': 3,
      'adherence_rate': 82.5,
      'recent_patients': [
        {
          'id': 1,
          'name': 'Budi Santoso',
          'treatment_day': 45,
          'total_days': 180,
          'last_medication': DateTime.now().subtract(Duration(hours: 12)),
          'adherence': 92,
          'status': 'Aktif',
          'photo': 'https://example.com/patient1.jpg',
        },
        {
          'id': 2,
          'name': 'Ani Wijaya',
          'treatment_day': 120,
          'total_days': 180,
          'last_medication': DateTime.now().subtract(Duration(days: 2)),
          'adherence': 78,
          'status': 'Aktif',
          'photo': 'https://example.com/patient2.jpg',
        },
        {
          'id': 3,
          'name': 'Citra Dewi',
          'treatment_day': 15,
          'total_days': 180,
          'last_medication': DateTime.now().subtract(Duration(hours: 6)),
          'adherence': 100,
          'status': 'Aktif',
          'photo': 'https://example.com/patient3.jpg',
        },
      ],
      'critical_patients': [
        {
          'id': 4,
          'name': 'Dodi Pratama',
          'reason': 'Tidak minum obat 3 hari berturut-turut',
          'status': 'Perlu tindakan',
        },
      ],
      'stats': {
        'active_treatments': 18,
        'completed_treatments': 6,
        'missed_medications': 5,
      },
    };
  }

  Widget _buildStaffHomePage() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _staffHomeData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat data'));
        }

        final data = snapshot.data!;
        final adherenceRate = data['adherence_rate'];
        final stats = data['stats'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              _buildStaffGreetingSection(),
              const SizedBox(height: 24),

              // Quick Stats Cards
              _buildQuickStats(data),
              const SizedBox(height: 16),

              // Adherence Rate Card
              _buildAdherenceCard(adherenceRate),
              const SizedBox(height: 24),

              // Critical Patients
              // if (data['critical_patients'].length > 0)
              //   _buildCriticalPatients(data['critical_patients']),
              // if (data['critical_patients'].length > 0)
              //   const SizedBox(height: 24),

              // Recent Patients
              _buildRecentPatientsSection(data['recent_patients']),
              const SizedBox(height: 16),

              // Full Stats
              _buildFullStats(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selamat datang, ${widget.name}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Anda menangani ${_staffHomeData.then((data) => data['patient_count'])} pasien TB',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: data['patient_count'].toString(),
            label: 'Total Pasien',
            icon: Icons.group,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: data['new_patients'].toString(),
            label: 'Pasien Baru',
            icon: Icons.person_add,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceCard(double rate) {
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
                Icon(Icons.medication, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Tingkat Kepatuhan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: rate / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[200],
                      color:
                          rate > 80
                              ? Colors.green
                              : rate > 60
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$rate%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        rate > 80
                            ? 'Baik'
                            : rate > 60
                            ? 'Cukup'
                            : 'Kurang',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Rata-rata kepatuhan minum obat pasien',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalPatients(List<dynamic> patients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pasien Perlu Perhatian',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          color: Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children:
                  patients
                      .map(
                        (patient) => ListTile(
                          leading: Icon(Icons.warning, color: Colors.red),
                          title: Text(patient['name']),
                          subtitle: Text(patient['reason']),
                          trailing: Chip(
                            label: Text(patient['status']),
                            backgroundColor: Colors.red[100],
                            labelStyle: TextStyle(color: Colors.red[800]),
                          ),
                          onTap: () {
                            // Navigate to patient detail
                          },
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPatientsSection(List<dynamic> patients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pasien Terkini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1; // Navigate to patient list
                });
              },
              child: Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children:
              patients.map((patient) => _buildPatientCard(patient)).toList(),
        ),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final progress = patient['treatment_day'] / patient['total_days'];
    final lastMedication = DateFormat(
      'dd/MM HH:mm',
    ).format(patient['last_medication']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        onTap: () {
          // Navigate to patient detail
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(patient['photo']),
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: AppColors.primary,
                      minHeight: 4,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Hari ${patient['treatment_day']}/${patient['total_days']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Chip(
                          label: Text('${patient['adherence']}%'),
                          backgroundColor:
                              patient['adherence'] > 80
                                  ? Colors.green[100]
                                  : patient['adherence'] > 60
                                  ? Colors.orange[100]
                                  : Colors.red[100],
                          labelStyle: TextStyle(
                            color:
                                patient['adherence'] > 80
                                    ? Colors.green[800]
                                    : patient['adherence'] > 60
                                    ? Colors.orange[800]
                                    : Colors.red[800],
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    'Terakhir',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    lastMedication,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullStats(Map<String, dynamic> stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik Pengobatan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStatCard(
                  value: stats['active_treatments'].toString(),
                  label: 'Aktif',
                  color: Colors.blue,
                ),
                _buildMiniStatCard(
                  value: stats['completed_treatments'].toString(),
                  label: 'Selesai',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'TB Care - Petugas',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Badge(smallSize: 8, child: Icon(Icons.notifications_none)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Belum ada notifikasi baru')),
              );
            },
          ),
        ],
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
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Pasien',
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
