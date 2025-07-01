import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:apk_tb_care/Main/Pasien/history.dart';
import 'package:apk_tb_care/Main/Pasien/treatment_history.dart';
import 'package:apk_tb_care/Section/screening.dart';
import 'package:apk_tb_care/connection.dart';
import 'package:apk_tb_care/data/medication_record.dart';
import 'package:apk_tb_care/data/patient_treatment.dart';
import 'package:apk_tb_care/values/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class TreatmentPage extends StatefulWidget {
  final int patientId;

  const TreatmentPage({super.key, required this.patientId});

  @override
  State<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  late Future<Map<String, dynamic>> _patientFuture;
  late Map<String, dynamic> _patientData;
  bool _notifIsActive = false;
  List<dynamic> _treatments = [];
  Map<String, dynamic>? _currentTreatment;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initNotifications();
    _patientFuture = _fetchPatientData();
    _getSharedPreferences();
  }

  void _getSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifIsActive = prefs.getBool('notifIsActive') ?? false;
    });
    log(prefs.getInt('hour').toString());
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> _initNotifications() async {
    // Initialize notification channels
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create medication reminder channel
    const AndroidNotificationChannel medicationChannel =
        AndroidNotificationChannel(
          'reminder_channel',
          'Pengingat Harian',
          description: 'Channel untuk pengingat harian seperti minum obat',
          importance: Importance.high,
        );

    // Create visit reminder channel
    const AndroidNotificationChannel visitChannel = AndroidNotificationChannel(
      'visit_channel',
      'Pengingat Kunjungan',
      description: 'Channel untuk pengingat kunjungan pengobatan',
      importance: Importance.high,
    );

    final androidPlatform =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlatform?.createNotificationChannel(medicationChannel);
    await androidPlatform?.createNotificationChannel(visitChannel);
  }

  Future<void> _setNotificationStatus(bool status, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();

    // Request notification permission if not granted
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (await Permission.notification.isGranted) {
      setState(() {
        _notifIsActive = status;
        prefs.setBool('notifIsActive', status);
        if (_notifIsActive) {
          _setNotificationTZ(hour, minute);
        } else {
          flutterLocalNotificationsPlugin.cancel(
            0,
          ); // Cancel medication reminders
        }
      });
    }
  }

  Future<void> _setNotificationTZ(int hour, int minute) async {
    // Check and request exact alarm permission first
    if (await _checkExactAlarmPermission()) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Reminder Pengobatan',
        'Saatnya minum obat! Jangan lupa ya!',
        _nextInstanceOf(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Pengingat Harian',
            channelDescription:
                'Channel untuk pengingat harian seperti minum obat',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode:
            AndroidScheduleMode.inexactAllowWhileIdle, // Changed to inexact
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<bool> _checkExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isGranted) {
      return true;
    }

    // Request permission if not granted
    final status = await Permission.scheduleExactAlarm.request();
    if (status.isGranted) {
      return true;
    }

    // If permission denied, show explanation and open settings
    if (await Permission.scheduleExactAlarm.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'This app needs exact alarm permission to show timely medication reminders. '
                'Please enable it in app settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
      );
    }
    return false;
  }

  Future<void> _scheduleVisitNotifications(List<dynamic> visits) async {
    // Batalkan semua notifikasi kunjungan sebelumnya (ID dimulai dari 100)
    await flutterLocalNotificationsPlugin.cancel(100);

    for (final visit in visits) {
      final visitDate = DateTime.parse(visit['visit_date']);
      final visitTime = visit['visit_time'].split(':');
      final hour = int.parse(visitTime[0]);
      final minute = int.parse(visitTime[1]);

      final scheduledDate = tz.TZDateTime(
        tz.local,
        visitDate.year,
        visitDate.month,
        visitDate.day,
        hour,
        minute,
      );

      // Jadwalkan 1 jam sebelum kunjungan
      final reminderDate = scheduledDate.subtract(const Duration(hours: 1));

      if (reminderDate.isAfter(tz.TZDateTime.now(tz.local))) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          100 + visits.indexOf(visit), // ID unik untuk setiap kunjungan
          'Kunjungan Pengobatan',
          'Anda memiliki jadwal kunjungan pengobatan dalam 1 jam',
          reminderDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'visit_channel',
              'Pengingat Kunjungan',
              channelDescription:
                  'Channel untuk pengingat kunjungan pengobatan',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
      }
    }
  }

  // Update _fetchPatientData to schedule visit notifications
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
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _patientData = data['data'];
          _treatments = data['data']['treatments'] ?? [];
          if (_treatments.isNotEmpty) {
            _currentTreatment = _treatments.first;
            // Schedule visit notifications if visits exist
            if (_currentTreatment?['visits'] != null) {
              _scheduleVisitNotifications(_currentTreatment!['visits']);
            }
          }
        });
        return data['data'];
      } else {
        throw Exception('Failed to load patient data');
      }
    } catch (e) {
      log('Error fetching patient data: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengobatan Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (builder) =>
                            MedicationHistoryPage(patientId: widget.patientId),
                  ),
                ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _patientFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || _currentTreatment == null) {
            return const Center(child: Text('Tidak ada data pengobatan'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                _buildStatusCard(_currentTreatment!),
                const SizedBox(height: 24),

                // Regimen Details
                _buildRegimenDetails(_currentTreatment!),
                const SizedBox(height: 24),

                // Medication Reminder
                if (_currentTreatment!['medication_time'] != null)
                  _buildMedicationReminder(_currentTreatment!),
                const SizedBox(height: 24),

                // Drug
                if (_currentTreatment!['prescription'] != null &&
                    _currentTreatment!['prescription'].isNotEmpty)
                  _buildDrugList(_currentTreatment!['prescription']),
                const SizedBox(height: 24),

                // Screening Section
                _buildScreeningSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreeningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Skrining TB",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          "Lakukan pengecekan rutin terhadap gejala TB Anda. ",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        _buildScreeningButton("Skrining TB", Icons.paste),
      ],
    );
  }

  Widget _buildScreeningButton(String title, IconData icon) {
    return OutlinedButton.icon(
      label: Text(title),
      onPressed: () => _navigateToScreening(title),
      icon: Icon(icon, color: Colors.blue),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        fixedSize: Size(double.maxFinite, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDrugCard(String drug) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drug,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> treatmentData) {
    // Hitung progress jika data tersedia
    final currentDay = _calculateCurrentDay(
      treatmentData['start_date'],
      treatmentData['end_date'],
    );
    final totalDays = _calculateTotalDays(
      treatmentData['start_date'],
      treatmentData['end_date'],
    );
    final progress = currentDay / totalDays;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.medical_services, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Status Pengobatan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (builder) => TreatmentHistoryPage(
                                patientId: widget.patientId,
                              ),
                        ),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Pengobatan TB",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
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
                      '${treatmentData['start_date'] ?? 'Tanggal mulai'} - ${treatmentData['end_date'] ?? 'Tanggal selesai'}',
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
                    color: _getStatusColor(
                      treatmentData['treatment_status'],
                      true,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(
                        treatmentData['treatment_status'],
                        false,
                      ),
                    ),
                  ),
                  child: Text(
                    treatmentData['treatment_status'] ??
                        'Status tidak tersedia',
                    style: TextStyle(
                      color: _getStatusTextColor(
                        treatmentData['treatment_status'],
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateCurrentDay(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 0;

    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final today = DateTime.now();

      if (today.isBefore(start)) return 0;
      if (today.isAfter(end)) return end.difference(start).inDays;

      return today.difference(start).inDays;
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

  Color _getStatusColor(String? status, bool isBackground) {
    switch (status) {
      case 'Berjalan':
        return isBackground ? Colors.green[50]! : Colors.green;
      case 'Selesai':
        return isBackground ? Colors.blue[50]! : Colors.blue;
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
      default:
        return Colors.grey[800]!;
    }
  }

  Widget _buildRegimenDetails(Map<String, dynamic> treatment) {
    final duration = _calculateDuration(
      DateTime.parse(treatment['start_date']),
      DateTime.parse(treatment['end_date']),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detail Regimen",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          "Tanggal Mulai",
          _formatDate(DateTime.parse(treatment['start_date'])),
        ),
        _buildDetailRow(
          "Tanggal Selesai",
          _formatDate(DateTime.parse(treatment['end_date'])),
        ),
        _buildDetailRow("Durasi", duration),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMedicationReminder(Map<String, dynamic> treatment) {
    // Default medication time if not provided
    final medicationTime = TimeOfDay(hour: 8, minute: 0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.orange),
                const SizedBox(width: 12),
                const Text(
                  "Pengingat Obat",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: _notifIsActive,
                  onChanged:
                      (value) => _toggleReminder(
                        value,
                        medicationTime.hour,
                        medicationTime.minute,
                      ),
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Minum obat berikutnya:",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              _getNextMedicationTime(medicationTime),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showUploadDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.medical_services, color: Colors.white),
                label: const Text(
                  "SUDAH MINUM OBAT",
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

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Minum Obat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Apakah Anda sudah minum obat hari ini?'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Nanti'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showUploadOptions();
                      },
                      child: const Text('Konfirmasi'),
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

  Widget _buildDrugList(List<dynamic> prescription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daftar Obat",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...prescription.map((drug) => _buildDrugCard(drug)).toList(),
      ],
    );
  }

  String _calculateDuration(DateTime startDate, DateTime endDate) {
    final months =
        (endDate.year - startDate.year) * 12 +
        (endDate.month - startDate.month);
    return '$months Bulan';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy').format(date);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getNextMedicationTime(TimeOfDay medicationTime) {
    return 'Setiap hari, ${medicationTime.hour}:${medicationTime.minute.toString().padLeft(2, '0')} WIB';
  }

  void _toggleReminder(bool value, int hour, int minute) async {
    try {
      setState(() {
        _setNotificationStatus(value, hour, minute);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pengingat ${value ? 'diaktifkan' : 'dinonaktifkan'}"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal mengubah pengingat")));
    }
  }

  void _showUploadOptions() {
    final ImagePicker _picker = ImagePicker();

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
                    final XFile? photo = await _picker.pickImage(
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
                    final XFile? image = await _picker.pickImage(
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

  Future<void> _uploadImage(File imageFile, String patientTreatmentId) async {
    final url = Uri.parse('${Connection.BASE_URL}/treatments/proof');

    final request = http.MultipartRequest('POST', url);

    // Tambahkan token kalau pakai auth
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    request.headers['Authorization'] = 'Bearer $token';

    // Tambahkan form field dan file
    request.fields['patient_treatment_id'] = patientTreatmentId;
    request.files.add(
      await http.MultipartFile.fromPath('photo', imageFile.path),
    );

    try {
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
    await _uploadImage(imageFile, _currentTreatment!['id'].toString());
  }

  void _navigateToScreening(String type) {
    switch (type) {
      case "Skrining Visual":
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const ScreeningPage()));
        break;
      default:
    }
  }
}
