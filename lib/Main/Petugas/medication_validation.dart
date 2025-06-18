import 'package:apk_tb_care/Main/Pasien/treatment.dart';
import 'package:apk_tb_care/Main/Petugas/patient.dart';
import 'package:apk_tb_care/data/medication_record.dart';
import 'package:apk_tb_care/data/patient.dart';
import 'package:apk_tb_care/data/patient_treatment.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicationValidationPage extends StatefulWidget {
  const MedicationValidationPage({super.key});

  @override
  State<MedicationValidationPage> createState() =>
      _MedicationValidationPageState();
}

class _MedicationValidationPageState extends State<MedicationValidationPage> {
  List<MedicationRecord> _pendingRecords = [];
  List<MedicationRecord> _verifiedRecords = [];
  List<MedicationRecord> _rejectedRecords = [];
  late List<Patient> _patients = [];
  late List<PatientTreatment> _treatments = [];

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMedicationRecords();
    _patients = _generateDummyPatients();
    _treatments = _generateDummyTreatments();
  }

  List<PatientTreatment> _generateDummyTreatments() {
    final now = DateTime.now();
    return [
      PatientTreatment(
        id: 1,
        patientId: 1,
        treatmentTypeId: 3,
        diagnosisDate: DateTime(2024, 3, 1),
        medicationTime: TimeOfDay(hour: 8, minute: 0),
        patientName: 'Budi Santoso',
        treatmentType: 'Regimen TB Kategori 1',
        startDate: DateTime(2023, 6, 1),
        endDate: DateTime(2023, 12, 1),
        status: 1, // Active
        currentDay: (now.difference(DateTime(2023, 6, 1)).inDays),
        totalDays: 180,
        adherenceRate: 92.5,
      ),
      PatientTreatment(
        id: 2,
        patientId: 2,
        patientName: 'Ani Wijaya',
        treatmentTypeId: 3,
        diagnosisDate: DateTime(2024, 3, 1),
        medicationTime: TimeOfDay(hour: 8, minute: 0),
        treatmentType: 'Regimen TB Kategori 1',
        startDate: DateTime(2023, 5, 15),
        endDate: DateTime(2023, 11, 15),
        status: 1, // Active
        currentDay: (now.difference(DateTime(2023, 5, 15)).inDays),
        totalDays: 180,
        adherenceRate: 85.0,
      ),
      PatientTreatment(
        id: 3,
        patientId: 3,
        patientName: 'Citra Dewi',
        treatmentTypeId: 3,
        diagnosisDate: DateTime(2024, 3, 1),
        medicationTime: TimeOfDay(hour: 8, minute: 0),
        treatmentType: 'Regimen TB Kategori 2',
        startDate: DateTime(2023, 7, 1),
        endDate: DateTime(2024, 1, 1),
        status: 1, // Active
        currentDay: (now.difference(DateTime(2023, 7, 1)).inDays),
        totalDays: 180,
        adherenceRate: 78.3,
      ),
      PatientTreatment(
        id: 4,
        patientId: 4,
        treatmentTypeId: 2,
        diagnosisDate: DateTime(2024, 3, 1),
        medicationTime: TimeOfDay(hour: 8, minute: 0),
        patientName: 'Dodi Pratama',
        treatmentType: 'Regimen TB Kategori 1',
        startDate: DateTime(2023, 4, 1),
        endDate: DateTime(2023, 10, 1),
        status: 3, // Failed
        currentDay: (now.difference(DateTime(2023, 4, 1)).inDays),
        totalDays: 180,
        adherenceRate: 45.2,
      ),
      PatientTreatment(
        id: 5,
        patientId: 5,
        treatmentTypeId: 1,
        patientName: 'Eka Sari',
        treatmentType: 'Regimen TB Kategori 1',
        startDate: DateTime(2023, 3, 1),
        endDate: DateTime(2023, 9, 1),
        status: 2, // Completed
        currentDay: (now.difference(DateTime(2023, 3, 1)).inDays),
        diagnosisDate: DateTime(2023, 3, 1),
        medicationTime: TimeOfDay(hour: 8, minute: 0),
        totalDays: 180,
        adherenceRate: 95.8,
      ),
    ];
  }

  List<Patient> _generateDummyPatients() {
    return [
      Patient(
        id: 1,
        name: 'Budi Santoso',
        nik: '3273010101010001',
        code: 'PSN001',
        address: 'Jl. Merdeka No. 10, Jakarta',
        phone: '081234567890',
        subdistrictId: 101,
        puskesmasId: 1,
        height: 170,
        weight: 65,
        bloodType: 'A',
        diagnosisDate: DateTime(2023, 1, 15),
      ),
      Patient(
        id: 2,
        name: 'Ani Wijaya',
        nik: '3273010202020002',
        code: 'PSN002',
        address: 'Jl. Sudirman No. 20, Jakarta',
        phone: '081234567891',
        subdistrictId: 102,
        puskesmasId: 1,
        height: 160,
        weight: 55,
        bloodType: 'B',
        diagnosisDate: DateTime(2023, 2, 10),
      ),
      Patient(
        id: 3,
        name: 'Citra Dewi',
        nik: '3273010303030003',
        code: 'PSN003',
        address: 'Jl. Thamrin No. 30, Jakarta',
        phone: '081234567892',
        subdistrictId: 103,
        puskesmasId: 1,
        height: 155,
        weight: 50,
        bloodType: 'O',
        diagnosisDate: DateTime(2023, 3, 5),
      ),
      Patient(
        id: 4,
        name: 'Dodi Pratama',
        nik: '3273010404040004',
        code: 'PSN004',
        address: 'Jl. Gatot Subroto No. 40, Jakarta',
        phone: '081234567893',
        subdistrictId: 104,
        puskesmasId: 1,
        height: 175,
        weight: 70,
        bloodType: 'AB',
        diagnosisDate: DateTime(2023, 4, 20),
      ),
      Patient(
        id: 5,
        name: 'Eka Sari',
        nik: '3273010505050005',
        code: 'PSN005',
        address: 'Jl. Hayam Wuruk No. 50, Jakarta',
        phone: '081234567894',
        subdistrictId: 105,
        puskesmasId: 1,
        height: 165,
        weight: 60,
        bloodType: 'A',
        diagnosisDate: DateTime(2023, 5, 15),
      ),
    ];
  }

  Future<void> _loadMedicationRecords() async {
    // Replace with actual API call
    final allRecords = _generateDummyMedicationRecords();

    setState(() {
      _pendingRecords = allRecords.where((r) => r.status == 'pending').toList();
      _verifiedRecords =
          allRecords.where((r) => r.status == 'verified').toList();
      _rejectedRecords =
          allRecords.where((r) => r.status == 'rejected').toList();
    });
  }

  List<MedicationRecord> _generateDummyMedicationRecords() {
    return [
      MedicationRecord(
        id: 1,
        patientTreatmentId: 1,
        photoUrl: 'https://example.com/medication1.jpg',
        takenAt: DateTime.now().subtract(Duration(days: 1)),
        status: 'verified',
        verifiedBy: 'Dr. Andi',
      ),
      MedicationRecord(
        id: 2,
        patientTreatmentId: 3,
        photoUrl: 'https://example.com/medication2.jpg',
        takenAt: DateTime.now().subtract(Duration(days: 2)),
        status: 'verified',
        verifiedBy: 'Dr. Budi',
      ),
      MedicationRecord(
        id: 3,
        patientTreatmentId: 1,
        photoUrl: null,
        takenAt: DateTime.now().subtract(Duration(days: 3)),
        status: 'pending',
      ),
      MedicationRecord(
        id: 4,
        patientTreatmentId: 1,
        photoUrl: 'https://example.com/medication4.jpg',
        takenAt: DateTime.now().subtract(Duration(days: 4)),
        status: 'rejected',
        notes: 'Foto tidak jelas',
        verifiedBy: 'Dr. Citra',
      ),
      MedicationRecord(
        id: 5,
        patientTreatmentId: 2,
        photoUrl: 'https://example.com/medication5.jpg',
        takenAt: DateTime.now().subtract(Duration(days: 5)),
        status: 'verified',
        verifiedBy: 'Dr. Andi',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Validasi Minum Obat'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Menunggu', icon: Icon(Icons.access_time)),
              Tab(text: 'Terverifikasi', icon: Icon(Icons.check_circle)),
              Tab(text: 'Ditolak', icon: Icon(Icons.cancel)),
            ],
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: _showFilterDialog,
              tooltip: 'Filter',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMedicationRecords,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildValidationList(_pendingRecords, true),
            _buildValidationList(_verifiedRecords, false),
            _buildValidationList(_rejectedRecords, false),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationList(List<MedicationRecord> records, bool isPending) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.check : Icons.medical_services,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isPending
                  ? 'Tidak ada bukti minum obat yang menunggu validasi'
                  : 'Tidak ada data yang ditampilkan',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedicationRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: records.length,
        itemBuilder: (context, index) {
          return _buildValidationCard(records[index], isPending);
        },
      ),
    );
  }

  Widget _buildValidationCard(MedicationRecord record, bool isPending) {
    final patient = _findPatientByTreatmentId(record.patientTreatmentId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _showValidationDetail(record, patient),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo Preview
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    record.photoUrl != null
                        ? CachedNetworkImage(
                          imageUrl: record.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.error),
                        )
                        : const Center(
                          child: Icon(Icons.photo_camera, size: 32),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient?.name ?? 'Pasien Tidak Dikenal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'EEEE, dd MMMM yyyy - HH:mm',
                      ).format(record.takenAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (record.verifiedBy != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Divalidasi oleh: ${record.verifiedBy}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (record.notes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Catatan: ${record.notes}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              record.status == 'rejected' ? Colors.red : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isPending) ...[
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _verifyMedication(record),
                      tooltip: 'Verifikasi',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectMedication(record),
                      tooltip: 'Tolak',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showValidationDetail(MedicationRecord record, Patient? patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Validasi',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Photo Section
              Expanded(
                child: Center(
                  child:
                      record.photoUrl != null
                          ? InteractiveViewer(
                            child: CachedNetworkImage(
                              imageUrl: record.photoUrl!,
                              fit: BoxFit.contain,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.error),
                            ),
                          )
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.warning,
                                size: 48,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada foto bukti',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                ),
              ),

              // Detail Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Nama Pasien', patient?.name ?? '-'),
                    _buildDetailRow(
                      'Waktu Pengambilan',
                      DateFormat(
                        'EEEE, dd MMMM yyyy - HH:mm',
                      ).format(record.takenAt),
                    ),
                    _buildDetailRow(
                      'Status',
                      record.status == 'verified'
                          ? 'Terverifikasi'
                          : record.status == 'pending'
                          ? 'Menunggu Validasi'
                          : 'Ditolak',
                      valueColor:
                          record.status == 'verified'
                              ? Colors.green
                              : record.status == 'pending'
                              ? Colors.orange
                              : Colors.red,
                    ),
                    if (record.verifiedBy != null)
                      _buildDetailRow('Divalidasi oleh', record.verifiedBy!),
                    if (record.notes != null)
                      _buildDetailRow('Catatan', record.notes!),
                  ],
                ),
              ),

              // Action Buttons
              if (record.status == 'pending') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () => _rejectMedication(record),
                        child: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _verifyMedication(record),
                        child: const Text('Verifikasi'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
  }

  Future<void> _verifyMedication(MedicationRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Verifikasi Bukti Minum Obat'),
            content: const Text(
              'Apakah Anda yakin ingin memverifikasi bukti minum obat ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Verifikasi'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        record.status = 'verified';
        record.verifiedBy = 'Petugas Kesehatan'; // Replace with actual user
        record.notes = null;
        _pendingRecords.remove(record);
        _verifiedRecords.insert(0, record);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti minum obat telah diverifikasi'),
          backgroundColor: Colors.green,
        ),
      );

      if (ModalRoute.of(context)?.isCurrent != true) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _rejectMedication(MedicationRecord record) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Alasan Penolakan'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Masukkan alasan penolakan...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context, controller.text);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      // Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        record.status = 'rejected';
        record.verifiedBy = 'Petugas Kesehatan'; // Replace with actual user
        record.notes = reason;
        _pendingRecords.remove(record);
        _rejectedRecords.insert(0, record);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti minum obat telah ditolak'),
          backgroundColor: Colors.red,
        ),
      );

      if (ModalRoute.of(context)?.isCurrent != true) {
        Navigator.pop(context);
      }
    }
  }

  void _showFilterDialog() {
    DateTime? startDate;
    DateTime? endDate;
    String? patientName;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Validasi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nama Pasien',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => patientName = value,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Tanggal Mulai'),
                      subtitle: Text(
                        startDate != null
                            ? DateFormat('dd MMM yyyy').format(startDate!)
                            : 'Pilih tanggal',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => startDate = date);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Tanggal Akhir'),
                      subtitle: Text(
                        endDate != null
                            ? DateFormat('dd MMM yyyy').format(endDate!)
                            : 'Pilih tanggal',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => endDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Apply filter logic here
                    Navigator.pop(context);
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper methods
  Patient? _findPatientByTreatmentId(int treatmentId) {
    final treatment = _treatments.firstWhere(
      (t) => t.id == treatmentId,
      orElse:
          () => PatientTreatment(
            id: 0,
            patientId: 0,
            patientName: 'Pasien Tidak Dikenal',
            treatmentTypeId: 0,
            treatmentType: '',
            diagnosisDate: DateTime.now(),
            startDate: DateTime.now(),
            endDate: DateTime.now(),
            medicationTime: TimeOfDay.now(),
            status: 0,
            currentDay: 0,
            totalDays: 0,
            adherenceRate: 0,
          ),
    );

    return _patients.firstWhere(
      (p) => p.id == treatment.patientId,
      orElse:
          () => Patient(
            id: 0,
            name: treatment.patientName,
            nik: '',
            code: '',
            address: '',
            phone: '',
            subdistrictId: 0,
            puskesmasId: 0,
            diagnosisDate: DateTime.now(),
          ),
    );
  }
}
