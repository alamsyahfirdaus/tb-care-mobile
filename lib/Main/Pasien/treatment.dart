import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:apk_tb_care/Section/screening.dart';
import 'package:apk_tb_care/data/medication_record.dart';
import 'package:apk_tb_care/data/patient_treatment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class TreatmentPage extends StatefulWidget {
  final int patientId;

  const TreatmentPage({super.key, required this.patientId});

  @override
  State<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  late Future<PatientTreatment> _treatmentFuture;
  bool _notifIsActive = false;
  final ApiService _apiService = ApiService();

  void _getSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifIsActive = prefs.getBool('notifIsActive') ?? false;
    });
    log(prefs.getInt('hour').toString());
  }

  Future<void> _setNotificationTZ(int hour, int minute) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Reminder Pengobatan',
      'Saatnya minum obat! jangan lupa ya!',
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
      androidScheduleMode: AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.time,
    );
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

  void _setNotificationStatus(bool status, int hour, int minute) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    setState(() {
      _notifIsActive = status;
      prefs.setBool('notifIsActive', status);
      if (_notifIsActive) {
        _setNotificationTZ(hour, minute);
      } else {
        FlutterLocalNotificationsPlugin().cancelAll();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _treatmentFuture = _apiService.getPatientTreatment(widget.patientId);
    _getSharedPreferences();
    tz.initializeTimeZones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengobatan Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showMedicationHistory(),
          ),
        ],
      ),
      body: FutureBuilder<PatientTreatment>(
        future: _treatmentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Tidak ada data pengobatan'));
          }

          final treatment = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                _buildStatusCard(treatment),
                const SizedBox(height: 24),

                // Regimen Details
                _buildRegimenDetails(treatment),
                const SizedBox(height: 24),

                // Medication Reminder
                _buildMedicationReminder(treatment),
                const SizedBox(height: 24),

                // Drug List
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
      onPressed: () => _navigateToScreening(title),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        fixedSize: Size(double.maxFinite, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, color: Colors.blue),
      label: Text(title),
    );
  }

  Widget _buildDrugCard(Drug drug) {
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
                    drug.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text("Dosis: ${drug.dose} • Waktu: ${drug.time}"),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showDrugInfo(drug),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrugInfo(Drug drug) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(drug.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dosis: ${drug.dose}"),
                Text("Waktu: ${drug.time}"),
                const SizedBox(height: 16),
                const Text(
                  "Efek Samping:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text("- Mual ringan\n- Pusing\n- Perubahan warna urine"),
                const SizedBox(height: 16),
                const Text(
                  "Kontraindikasi:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text("- Riwayat alergi\n- Gangguan hati"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup"),
              ),
            ],
          ),
    );
  }

  Widget _buildStatusCard(PatientTreatment treatment) {
    final progress = _calculateProgress(treatment.startDate, treatment.endDate);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  treatment.treatmentType,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                Text(
                  "Progress: ${(progress * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        treatment.status == 1
                            ? Colors.green[50]
                            : Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: treatment.status == 1 ? Colors.green : Colors.blue,
                    ),
                  ),
                  child: Text(
                    treatment.status == 1 ? "Aktif" : "Selesai",
                    style: TextStyle(
                      color:
                          treatment.status == 1
                              ? Colors.green[800]
                              : Colors.blue[800],
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

  Widget _buildRegimenDetails(PatientTreatment treatment) {
    final duration = _calculateDuration(treatment.startDate, treatment.endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detail Regimen",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildDetailRow("Tanggal Mulai", _formatDate(treatment.startDate)),
        _buildDetailRow("Tanggal Selesai", _formatDate(treatment.endDate)),
        _buildDetailRow("Durasi", duration),
        _buildDetailRow("Waktu Minum", _formatTime(treatment.medicationTime)),
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

  Widget _buildMedicationReminder(PatientTreatment treatment) {
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
                        treatment.medicationTime.hour,
                        treatment.medicationTime.minute,
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
              _getNextMedicationTime(treatment.medicationTime),
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
                onPressed: () => _confirmMedication(treatment.id),
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

  Widget _buildDrugList(String prescription) {
    final drugs = _parsePrescription(prescription);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daftar Obat",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...drugs.map((drug) => _buildDrugCard(drug)).toList(),
      ],
    );
  }

  // Helper methods
  double _calculateProgress(DateTime startDate, DateTime endDate) {
    final totalDays = endDate.difference(startDate).inDays;
    final passedDays = DateTime.now().difference(startDate).inDays;
    return (passedDays / totalDays).clamp(0.0, 1.0);
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
    final now = DateTime.now();
    final nextTime = DateTime(
      now.year,
      now.month,
      now.day,
      medicationTime.hour,
      medicationTime.minute,
    );

    if (nextTime.isAfter(now)) {
      return 'Hari ini, ${_formatTime(medicationTime)}';
    } else {
      return 'Besok, ${_formatTime(medicationTime)}';
    }
  }

  List<Drug> _parsePrescription(String prescription) {
    // Parse the prescription text into Drug objects
    // This is a simplified parser - adjust based on your actual prescription format
    try {
      final json = jsonDecode(prescription);
      return (json as List).map((item) => Drug.fromJson(item)).toList();
    } catch (e) {
      // Fallback if prescription is not in JSON format
      return [
        Drug(name: "Rifampicin", dose: "600mg", time: "Pagi"),
        Drug(name: "Isoniazid", dose: "300mg", time: "Pagi"),
        Drug(name: "Pyrazinamide", dose: "1500mg", time: "Pagi"),
        Drug(name: "Ethambutol", dose: "1200mg", time: "Pagi"),
      ];
    }
  }

  // API interaction methods
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

  void _confirmMedication(int treatmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Konfirmasi Minum Obat"),
            content: const Text("Apakah Anda sudah minum semua obat hari ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Nanti"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Konfirmasi"),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _showUploadOptions(treatmentId);
    }
  }

  void _showUploadOptions(int treatmentId) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Unggah Bukti Minum Obat",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text("Ambil Foto"),
                  onTap: () => _takePhoto(treatmentId),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text("Pilih dari Galeri"),
                  onTap: () => _pickPhoto(treatmentId),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _submitWithoutPhoto(treatmentId),
                  child: const Text("Tanpa Foto"),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _takePhoto(int treatmentId) async {
    Navigator.pop(context);
    // Implement camera functionality
    // Then call:
    // await _apiService.submitMedication(treatmentId, imageFile, DateTime.now());
  }

  Future<void> _pickPhoto(int treatmentId) async {
    Navigator.pop(context);
    // Implement gallery picker
    // Then call:
    // await _apiService.submitMedication(treatmentId, imageFile, DateTime.now());
  }

  Future<void> _submitWithoutPhoto(int treatmentId) async {
    Navigator.pop(context);
    try {
      await _apiService.submitMedication(treatmentId, null, DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konfirmasi obat berhasil dicatat")),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mencatat konsumsi obat")),
      );
    }
  }

  void _showMedicationHistory() async {
    final history = await _apiService.getMedicationHistory(widget.patientId);
    // Show history in a dialog or new page
  }

  void _showTreatmentHistory() {
    // Implement treatment history
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

class TreatmentType {
  final int id;
  final String name;
  final int duration;
  final String durationUnit;
  final String description;

  TreatmentType({
    required this.id,
    required this.name,
    required this.duration,
    required this.durationUnit,
    required this.description,
  });
}

class Drug {
  final String name;
  final String dose;
  final String time;

  Drug({required this.name, required this.dose, required this.time});

  factory Drug.fromJson(Map<String, dynamic> json) {
    return Drug(name: json['name'], dose: json['dose'], time: json['time']);
  }
}

// Mock API Service
class ApiService {
  Future<PatientTreatment> getPatientTreatment(int patientId) async {
    // Mock API call
    await Future.delayed(const Duration(seconds: 1));
    return PatientTreatment(
      id: 1,
      patientId: patientId,
      patientName: "John Doe",
      treatmentType: "Pengobatan TB",
      treatmentTypeId: 1,
      currentDay: 30,
      totalDays: 180,
      adherenceRate: 0.85,
      diagnosisDate: DateTime(2024, 6, 1),
      startDate: DateTime(2024, 6, 15),
      endDate: DateTime(2026, 12, 15),
      medicationTime: const TimeOfDay(hour: 8, minute: 0),
      prescription: jsonEncode([
        {"name": "Rifampicin", "dose": "600mg", "time": "Pagi"},
        {"name": "Isoniazid", "dose": "300mg", "time": "Pagi"},
        {"name": "Pyrazinamide", "dose": "1500mg", "time": "Pagi"},
        {"name": "Ethambutol", "dose": "1200mg", "time": "Pagi"},
      ]),
      status: 1,
    );
  }

  Future<bool> getReminderStatus(int patientId) async {
    return true;
  }

  Future<void> submitMedication(
    int treatmentId,
    File? image,
    DateTime takenAt,
  ) async {
    // Implement actual API call to POST /api/medication/submit
  }

  Future<List<MedicationRecord>> getMedicationHistory(int patientId) async {
    return [];
  }
}
