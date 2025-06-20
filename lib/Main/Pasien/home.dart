import 'package:apk_tb_care/Main/Pasien/consultation.dart';
import 'package:apk_tb_care/Main/Pasien/education.dart';
import 'package:apk_tb_care/profile.dart';
import 'package:apk_tb_care/Main/Pasien/treatment.dart';
import 'package:flutter/material.dart';
import 'package:apk_tb_care/values/colors.dart';

class HomePage extends StatefulWidget {
  final String name;

  const HomePage({super.key, required this.name});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> _homeData;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _homeData = _fetchHomeData();
    _pages = [
      _buildHomePage(),
      const TreatmentPage(patientId: 1),
      const EducationPage(),
      const ConsultationPage(),
      const ProfilePage(),
    ];
  }

  Future<Map<String, dynamic>> _fetchHomeData() async {
    // Simulate API calls
    await Future.delayed(Duration(seconds: 1));

    return {
      'treatment_status': 'Aktif',
      'treatment_day': 15,
      'total_days': 180,
      'next_medication': '08:00',
      'last_medication': DateTime.now().subtract(Duration(days: 1)),
      'health_tips': [
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
      ],
      'upcoming_events': [
        {
          'title': 'Kontrol ke Dokter',
          'date': '25 Juni 2023',
          'time': '10:00 WIB',
        },
        {
          'title': 'Tes Laboratorium',
          'date': '30 Juni 2023',
          'time': '08:30 WIB',
        },
      ],
      'motivational_quote': {
        'text':
            'Kesembuhan dimulai dari tekad yang kuat dan disiplin dalam pengobatan',
        'author': 'dr. Andi Pratama',
      },
    };
  }

  Widget _buildHomePage() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _homeData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat data'));
        }

        final data = snapshot.data!;
        final progress = data['treatment_day'] / data['total_days'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              _buildGreetingSection(),
              const SizedBox(height: 24),

              // Treatment Status Card
              _buildTreatmentCard(data, progress),
              SizedBox(height: 24),

              // Health Tips Section
              _buildHealthTips(data),
              SizedBox(height: 24),

              // Motivational Quote
              _buildMotivationalQuote(data),
              SizedBox(height: 24),
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

  Widget _buildTreatmentCard(Map<String, dynamic> data, double progress) {
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
                SizedBox(width: 8),
                Text(
                  'Status Pengobatan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hari ke-${data['treatment_day']} dari ${data['total_days']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        data['treatment_status'] == 'Aktif'
                            ? Colors.green[50]
                            : Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          data['treatment_status'] == 'Aktif'
                              ? Colors.green
                              : Colors.blue,
                    ),
                  ),
                  child: Text(
                    data['treatment_status'],
                    style: TextStyle(
                      color:
                          data['treatment_status'] == 'Aktif'
                              ? Colors.green[800]
                              : Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengingat Minum Obat',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Besok, ${data['next_medication']} WIB',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showUploadDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.medical_services,
                  size: 20,
                  color: Colors.white,
                ),
                label: Text(
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

  Widget _buildHealthTips(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tips Kesehatan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data['health_tips'].length,
            separatorBuilder: (context, index) => SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tip = data['health_tips'][index];
              return Container(
                width: 200,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(tip['icon'], color: AppColors.primary, size: 32),
                        SizedBox(height: 12),
                        Text(
                          tip['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          tip['description'],
                          style: TextStyle(fontSize: 14),
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

  Widget _buildMotivationalQuote(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Kata Motivasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '"${data['motivational_quote']['text']}"',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '- ${data['motivational_quote']['author']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Minum Obat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Apakah Anda sudah minum obat hari ini?'),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Nanti'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showUploadOptions();
                      },
                      child: Text('Konfirmasi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Unggah Bukti Minum Obat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text('Ambil Foto'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement camera
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement gallery
                  },
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Konfirmasi obat berhasil dicatat'),
                      ),
                    );
                  },
                  child: Text('Tanpa Foto'),
                ),
              ],
            ),
          ),
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
          'TB Care',
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
