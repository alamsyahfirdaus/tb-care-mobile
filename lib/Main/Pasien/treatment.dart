import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:apk_tb_care/Main/Pasien/history.dart';
import 'package:apk_tb_care/Main/Pasien/treatment_history.dart';
import 'package:apk_tb_care/Section/screening.dart';
import 'package:apk_tb_care/connection.dart';
import 'package:apk_tb_care/values/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

// Notification callback for alarm manager
@pragma('vm:entry-point')
void notificationCallback() {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  flutterLocalNotificationsPlugin.show(
    0,
    'Reminder Pengobatan',
    'Saatnya minum obat! Jangan lupa ya!',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel',
        'Pengingat Harian',
        channelDescription: 'Channel untuk pengingat harian seperti minum obat',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    ),
  );
}

@pragma('vm:entry-point')
void visitNotificationCallback() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize with a notification click handler
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse: (response) {},
  );

  try {
    await flutterLocalNotificationsPlugin.show(
      101,
      'Kunjungan Pengobatan',
      'Anda memiliki jadwal kunjungan dalam 1 jam',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'visit_channel',
          'Pengingat Kunjungan',
          channelDescription: 'Channel untuk pengingat kunjungan pengobatan',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          sound: RawResourceAndroidNotificationSound('notification'),
          color: Colors.blue,
          ledColor: Colors.blue,
          ledOnMs: 1000,
          ledOffMs: 500,
        ),
      ),
    );
    debugPrint('Visit notification shown successfully');
  } catch (e) {
    debugPrint('Error showing visit notification: $e');
  }
}

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
    _checkPermissions();
    _initNotifications();
    _patientFuture = _fetchPatientData();
    _getSharedPreferences();
    _scheduleTestNotification();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }

    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> _scheduleTestNotification() async {
    try {
      // Schedule test notification in 1 minute
      await AndroidAlarmManager.oneShot(
        const Duration(minutes: 1),
        999,
        notificationCallback,
        exact: true,
        wakeup: true,
      );

      log('Test notification scheduled in 1 minute');

      // Show immediate test notification
      await flutterLocalNotificationsPlugin.show(
        998,
        'TEST LANGSUNG',
        'Jika ini muncul, sistem notifikasi berfungsi',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
          ),
        ),
      );
    } catch (e) {
      log('Error scheduling test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _getSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifIsActive = prefs.getBool('notifIsActive') ?? false;
    });
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
    );

    // Create channels with proper configuration
    const AndroidNotificationChannel medicationChannel =
        AndroidNotificationChannel(
          'reminder_channel',
          'Pengingat Harian',
          description: 'Channel untuk pengingat harian seperti minum obat',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          sound: RawResourceAndroidNotificationSound('notification'),
        );

    const AndroidNotificationChannel visitChannel = AndroidNotificationChannel(
      'visit_channel',
      'Pengingat Kunjungan',
      description: 'Channel untuk pengingat kunjungan pengobatan',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    final androidPlatform =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlatform?.createNotificationChannel(medicationChannel);
    await androidPlatform?.createNotificationChannel(visitChannel);

    // Verify channels were created
    final channels = await androidPlatform?.getNotificationChannels();
    debugPrint('Created channels: $channels');
  }

  Future<void> _setNotificationStatus(bool status, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();

    // Request necessary permissions
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    setState(() {
      _notifIsActive = status;
      prefs.setBool('notifIsActive', status);
    });

    if (status) {
      await _scheduleDailyReminder(hour, minute);
    } else {
      await AndroidAlarmManager.cancel(0);
    }
  }

  Future<void> _scheduleDailyReminder(int hour, int minute) async {
    // Cancel any existing alarm
    await AndroidAlarmManager.cancel(0);

    // Get current time
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    // If the time has already passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Calculate initial delay
    final initialDelay = scheduledTime.difference(now);

    // Schedule the daily repeating alarm
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      0,
      notificationCallback,
      startAt: scheduledTime,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    log('Daily reminder scheduled at $hour:$minute');
  }

  Future<void> _scheduleVisitNotifications(List<dynamic> visits) async {
    try {
      // Cancel previous alarms
      for (int i = 100; i < 200; i++) {
        await AndroidAlarmManager.cancel(i);
      }

      debugPrint('Scheduling ${visits.length} visit notifications');

      for (final visit in visits) {
        try {
          final visitDate = DateTime.parse(visit['visit_date']);
          final timeParts = visit['visit_time'].split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          // Convert to local time
          final scheduledTime =
              DateTime(
                visitDate.year,
                visitDate.month,
                visitDate.day,
                hour,
                minute,
              ).toLocal();

          // Schedule 1 hour before
          final reminderTime = scheduledTime.subtract(const Duration(hours: 1));

          if (reminderTime.isAfter(DateTime.now())) {
            final alarmId = 100 + visits.indexOf(visit);

            debugPrint('''
Scheduling visit:
- ID: ${visit['id']}
- Original: $scheduledTime (${scheduledTime.timeZoneName})
- Reminder: $reminderTime (${reminderTime.timeZoneName})
''');

            await AndroidAlarmManager.oneShotAt(
              reminderTime,
              alarmId,
              visitNotificationCallback,
              exact: true,
              wakeup: true,
              rescheduleOnReboot: true,
            );
          }
        } catch (e) {
          debugPrint('Error scheduling visit ${visit['id']}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in visit scheduling: $e');
    }
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
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _patientData = data['data'];
          _treatments = data['data']['treatments'] ?? [];
          if (_treatments.isNotEmpty) {
            _currentTreatment = _treatments.first;
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

  // ... (keep all your existing build methods and helper functions unchanged)
  // The rest of your code (build methods, helper functions, etc.) remains the same
  // Just replace the notification scheduling parts with the alarm manager implementation

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
                _buildStatusCard(_currentTreatment!),
                const SizedBox(height: 24),
                _buildRegimenDetails(_currentTreatment!),
                const SizedBox(height: 24),
                if (_currentTreatment!['medication_time'] != null)
                  _buildMedicationReminder(_currentTreatment!),
                const SizedBox(height: 24),
                if (_currentTreatment!['prescription'] != null &&
                    _currentTreatment!['prescription'].isNotEmpty)
                  _buildDrugList(_currentTreatment!['prescription']),
                const SizedBox(height: 24),
                _buildScreeningSection(),
                // Add this to your build method
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        // Test immediate visit notification
                        await flutterLocalNotificationsPlugin.show(
                          101,
                          'TEST Kunjungan',
                          'Ini tes notifikasi kunjungan langsung',
                          const NotificationDetails(
                            android: AndroidNotificationDetails(
                              'visit_channel',
                              'Pengingat Kunjungan',
                              importance: Importance.high,
                              playSound: true,
                            ),
                          ),
                        );
                      },
                      child: const Text('Test Visit Notif Langsung'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Test scheduled visit notification in 1 minute
                        final testTime = DateTime.now().add(
                          const Duration(minutes: 1),
                        );
                        await AndroidAlarmManager.oneShotAt(
                          testTime,
                          102,
                          visitNotificationCallback,
                          exact: true,
                        );
                        debugPrint(
                          'Scheduled test visit notification for $testTime',
                        );
                      },
                      child: const Text('Test Visit Notif 1 Menit Lagi'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ... (keep all your existing helper widget methods)
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
                                patientName: _patientData['name'] ?? 'Pasien',
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
      await _setNotificationStatus(value, hour, minute);
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

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    request.headers['Authorization'] = 'Bearer $token';

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
