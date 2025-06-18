import 'package:apk_tb_care/Main/Petugas/medication_validation.dart';
import 'package:apk_tb_care/data/medication_record.dart';
import 'package:apk_tb_care/data/patient.dart';
import 'package:apk_tb_care/data/patient_treatment.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Models

class AdherenceData {
  final DateTime date;
  final double adherenceRate;

  AdherenceData(this.date, this.adherenceRate);
}

// Main Page
class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  late List<Patient> _patients = [];
  late List<PatientTreatment> _treatments = [];
  late List<MedicationRecord> _medicationRecords = [];
  late List<AdherenceData> _adherenceData = [];
  final TextEditingController _searchController = TextEditingController();
  int _coordinatorId = 1;
  int _selectedFilter = 0; // 0=All, 1=Active, 2=Completed, 3=Failed

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _getUserId();
    setState(() {
      _patients = _generateDummyPatients();
      _treatments = _generateDummyTreatments();
      _medicationRecords = _generateDummyMedicationRecords();
      _adherenceData = _generateAdherenceData();
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
        verifiedBy: 'Dr. Budi',
        notes: null,
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

  List<AdherenceData> _generateAdherenceData() {
    return [
      AdherenceData(DateTime.now().subtract(Duration(days: 30)), 85),
      AdherenceData(DateTime.now().subtract(Duration(days: 25)), 90),
      AdherenceData(DateTime.now().subtract(Duration(days: 20)), 78),
      AdherenceData(DateTime.now().subtract(Duration(days: 15)), 92),
      AdherenceData(DateTime.now().subtract(Duration(days: 10)), 88),
      AdherenceData(DateTime.now().subtract(Duration(days: 5)), 95),
      AdherenceData(DateTime.now().subtract(Duration(days: 1)), 100),
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

  List<MedicationRecord> _generateMedicationHistory(int treatmentId) {
    return [
      MedicationRecord(
        id: 1,
        patientTreatmentId: 1,

        photoUrl: 'https://example.com/medication1.jpg',
        takenAt: DateTime.now().subtract(Duration(days: 1)),
        status: 'verified',
      ),
      MedicationRecord(
        id: 2,
        patientTreatmentId: 2,

        photoUrl: 'https://example.com/medication2.jpg',
        takenAt: DateTime.now().subtract(Duration(days: 2)),
        status: 'verified',
      ),
      MedicationRecord(
        id: 3,
        patientTreatmentId: 3,

        photoUrl: null,
        takenAt: DateTime.now().subtract(Duration(days: 3)),
        status: 'pending',
        notes: 'Lupa upload foto',
      ),
    ];
  }

  Future<void> _getUserId() async {
    final session = await SharedPreferences.getInstance();
    final userId = session.getInt('userId');
    setState(() {
      _coordinatorId = userId ?? 1;
    });
  }

  // Data generation methods (to be replaced with API calls)

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Pasien'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daftar Pasien'),
              Tab(text: 'Pengobatan'),
              Tab(text: 'Validasi Obat'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddPatientDialog,
              tooltip: 'Tambah Pasien Baru',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Patient List
            _buildPatientListTab(),
            // Tab 2: Treatment Management
            _buildTreatmentTab(),

            MedicationValidationPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientListTab() {
    final filteredPatients =
        _patients.where((patient) {
          final query = _searchController.text.toLowerCase();
          return patient.name.toLowerCase().contains(query) ||
              patient.nik.toLowerCase().contains(query) ||
              patient.code!.toLowerCase().contains(query);
        }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari pasien...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                      : null,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              itemCount: filteredPatients.length,
              itemBuilder: (context, index) {
                return _buildPatientCard(filteredPatients[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(Patient patient) {
    final treatment = _treatments.firstWhere(
      (t) => t.patientId == patient.id,
      orElse:
          () => PatientTreatment(
            id: 0,
            patientId: 0,
            patientName: patient.name,
            treatmentTypeId: 0,
            treatmentType: 'Belum ada pengobatan',
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () => _showPatientDetail(patient),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person), radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('NIK: ${patient.nik} | Kode: ${patient.code}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 16,
                          color: _getStatusColor(treatment.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTreatmentStatusText(treatment.status),
                          style: TextStyle(
                            color: _getStatusColor(treatment.status),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentTab() {
    final filteredTreatments =
        _treatments.where((treatment) {
          if (_selectedFilter == 0) return true;
          return treatment.status == _selectedFilter;
        }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: [
                    DropdownMenuItem(value: 0, child: Text('Semua Status')),
                    DropdownMenuItem(value: 1, child: Text('Berjalan')),
                    DropdownMenuItem(value: 2, child: Text('Selesai')),
                    DropdownMenuItem(value: 3, child: Text('Gagal')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.filter_alt),
                onPressed: () {
                  // Add more filter options if needed
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredTreatments.length,
            itemBuilder: (context, index) {
              return _buildTreatmentCard(filteredTreatments[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentCard(PatientTreatment treatment) {
    final patient = _patients.firstWhere(
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

    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => _showTreatmentDetail(treatment, patient),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      treatment.patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      _getTreatmentStatusText(treatment.status),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _getStatusColor(treatment.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Regimen: ${treatment.treatmentType}'),
              Text(
                'Periode: ${DateFormat('dd MMM yyyy').format(treatment.startDate)} - ${DateFormat('dd MMM yyyy').format(treatment.endDate)}',
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: treatment.progressPercentage,
                backgroundColor: Colors.grey[200],
                color: _getStatusColor(treatment.status),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hari ${treatment.currentDay} dari ${treatment.totalDays} (${treatment.remainingDays} hari tersisa)',
                  ),
                  Text('${treatment.adherenceRate.toStringAsFixed(1)}%'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _showMedicationHistory(treatment),
                    child: const Text('Riwayat Obat'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _updateTreatmentStatus(treatment),
                    child: const Text('Update Status'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog and Detail Methods
  void _showAddPatientDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final nikController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final heightController = TextEditingController();
    final weightController = TextEditingController();
    String? bloodType;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Pasien Baru'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap*',
                    ),
                    validator:
                        (value) => value!.isEmpty ? 'Harap isi nama' : null,
                  ),
                  TextFormField(
                    controller: nikController,
                    decoration: const InputDecoration(
                      labelText: 'NIK*',
                      hintText: '16 digit NIK',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Harap isi NIK';
                      if (value.length != 16) return 'NIK harus 16 digit';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Alamat*'),
                    maxLines: 2,
                    validator:
                        (value) => value!.isEmpty ? 'Harap isi alamat' : null,
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'No. Telepon*',
                    ),
                    keyboardType: TextInputType.phone,
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Harap isi nomor telepon' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: heightController,
                          decoration: const InputDecoration(
                            labelText: 'Tinggi Badan (cm)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: weightController,
                          decoration: const InputDecoration(
                            labelText: 'Berat Badan (kg)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Golongan Darah',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'A+', child: Text('A+')),
                      DropdownMenuItem(value: 'A-', child: Text('A-')),
                      DropdownMenuItem(value: 'B+', child: Text('B+')),
                      DropdownMenuItem(value: 'B-', child: Text('B-')),
                      DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                      DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                      DropdownMenuItem(value: 'O+', child: Text('O+')),
                      DropdownMenuItem(value: 'O-', child: Text('O-')),
                    ],
                    onChanged: (value) => bloodType = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newPatient = Patient(
                    id: _patients.length + 1,
                    name: nameController.text,
                    nik: nikController.text,
                    code:
                        'P${(_patients.length + 1).toString().padLeft(3, '0')}',
                    address: addressController.text,
                    phone: phoneController.text,
                    subdistrictId: 1, // Default value
                    puskesmasId: _coordinatorId,
                    height: int.tryParse(heightController.text),
                    weight: int.tryParse(weightController.text),
                    bloodType: bloodType,
                    diagnosisDate: DateTime.now(),
                  );

                  setState(() {
                    _patients.add(newPatient);
                    // Add default treatment
                    _treatments.add(
                      PatientTreatment(
                        id: _treatments.length + 1,
                        patientId: newPatient.id,
                        patientName: newPatient.name,
                        treatmentTypeId: 1,
                        treatmentType: 'Regimen TB Kategori 1',
                        diagnosisDate: DateTime.now(),
                        startDate: DateTime.now(),
                        endDate: DateTime.now().add(const Duration(days: 180)),
                        medicationTime: const TimeOfDay(hour: 8, minute: 0),
                        status: 1,
                        currentDay: 1,
                        totalDays: 180,
                        adherenceRate: 100.0,
                      ),
                    );
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pasien berhasil ditambahkan'),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showPatientDetail(Patient patient) {
    final treatment = _treatments.firstWhere(
      (t) => t.patientId == patient.id,
      orElse:
          () => PatientTreatment(
            id: 0,
            patientId: 0,
            patientName: patient.name,
            treatmentTypeId: 0,
            treatmentType: 'Belum ada pengobatan',
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detail Pasien: ${patient.name}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('NIK', patient.nik),
                _buildDetailRow('Kode Pasien', patient.code),
                _buildDetailRow('Alamat', patient.address),
                _buildDetailRow('No. Telepon', patient.phone),
                if (patient.height != null)
                  _buildDetailRow('Tinggi Badan', '${patient.height} cm'),
                if (patient.weight != null)
                  _buildDetailRow('Berat Badan', '${patient.weight} kg'),
                if (patient.bloodType != null)
                  _buildDetailRow('Golongan Darah', patient.bloodType!),
                const SizedBox(height: 16),
                const Text(
                  'Status Kesehatan:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildDetailRow(
                  'Tanggal Diagnosis',
                  DateFormat('dd MMM yyyy').format(patient.diagnosisDate),
                ),
                _buildDetailRow(
                  'Status Pengobatan',
                  _getTreatmentStatusText(treatment.status),
                ),
                _buildDetailRow(
                  'Tingkat Kepatuhan',
                  '${treatment.adherenceRate.toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _editPatientDetails(patient),
                  child: const Text('Edit Data Pasien'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showTreatmentDetail(PatientTreatment treatment, Patient patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Pengobatan',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Nama Pasien', patient.name),
              _buildDetailRow('Regimen', treatment.treatmentType),
              _buildDetailRow(
                'Tanggal Diagnosis',
                DateFormat('dd MMM yyyy').format(treatment.diagnosisDate),
              ),
              _buildDetailRow(
                'Periode Pengobatan',
                '${DateFormat('dd MMM yyyy').format(treatment.startDate)} - ${DateFormat('dd MMM yyyy').format(treatment.endDate)}',
              ),
              _buildDetailRow(
                'Waktu Minum Obat',
                treatment.medicationTime.format(context),
              ),
              _buildDetailRow(
                'Progress',
                '${treatment.currentDay} dari ${treatment.totalDays} hari (${treatment.progressPercentage.toStringAsFixed(1)}%)',
              ),
              LinearProgressIndicator(
                value: treatment.progressPercentage,
                backgroundColor: Colors.grey[200],
                color: _getStatusColor(treatment.status),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Status',
                _getTreatmentStatusText(treatment.status),
              ),
              _buildDetailRow(
                'Tingkat Kepatuhan',
                '${treatment.adherenceRate.toStringAsFixed(1)}%',
              ),
              if (treatment.prescription != null)
                _buildDetailRow('Resep', treatment.prescription!),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showMedicationHistory(treatment),
                  child: const Text('Lihat Riwayat Minum Obat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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

  void _editPatientDetails(Patient patient) {
    final formKey = GlobalKey<FormState>();
    final addressController = TextEditingController(text: patient.address);
    final phoneController = TextEditingController(text: patient.phone);
    final heightController = TextEditingController(
      text: patient.height != null ? patient.height.toString() : '',
    );
    final weightController = TextEditingController(
      text: patient.weight != null ? patient.weight.toString() : '',
    );
    String? bloodType =
        [
              'A+',
              'A-',
              'B+',
              'B-',
              'AB+',
              'AB-',
              'O+',
              'O-',
            ].contains(patient.bloodType)
            ? patient.bloodType
            : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Data: ${patient.name}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Alamat*'),
                    validator:
                        (value) => value!.isEmpty ? 'Harap isi alamat' : null,
                    maxLines: 2,
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'No. Telepon*',
                    ),
                    keyboardType: TextInputType.phone,
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Harap isi nomor telepon' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: heightController,
                          decoration: const InputDecoration(
                            labelText: 'Tinggi Badan (cm)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: weightController,
                          decoration: const InputDecoration(
                            labelText: 'Berat Badan (kg)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: bloodType,
                    decoration: const InputDecoration(
                      labelText: 'Golongan Darah',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'A+', child: Text('A+')),
                      DropdownMenuItem(value: 'A-', child: Text('A-')),
                      DropdownMenuItem(value: 'B+', child: Text('B+')),
                      DropdownMenuItem(value: 'B-', child: Text('B-')),
                      DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                      DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                      DropdownMenuItem(value: 'O+', child: Text('O+')),
                      DropdownMenuItem(value: 'O-', child: Text('O-')),
                    ],
                    onChanged: (value) => bloodType = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    patient.address = addressController.text;
                    patient.phone = phoneController.text;
                    patient.height = int.tryParse(heightController.text);
                    patient.weight = int.tryParse(weightController.text);
                    patient.bloodType = bloodType;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data berhasil diperbarui')),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context); // Close detail dialog too
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showMedicationHistory(PatientTreatment treatment) {
    final history =
        _medicationRecords
            .where((record) => record.patientTreatmentId == treatment.id)
            .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Minum Obat - ${treatment.patientName}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    history.isEmpty
                        ? const Center(
                          child: Text('Belum ada riwayat minum obat'),
                        )
                        : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final record = history[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading:
                                    record.photoUrl != null
                                        ? CachedNetworkImage(
                                          imageUrl: record.photoUrl!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) =>
                                                  const CircularProgressIndicator(),
                                          errorWidget:
                                              (context, url, error) =>
                                                  const Icon(Icons.error),
                                        )
                                        : const Icon(
                                          Icons.medical_services,
                                          size: 40,
                                        ),
                                title: Text(
                                  DateFormat(
                                    'EEEE, d MMMM yyyy',
                                  ).format(record.takenAt),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'HH:mm',
                                      ).format(record.takenAt),
                                    ),
                                    Text(
                                      record.status == 'verified'
                                          ? 'Terverifikasi'
                                          : record.status == 'pending'
                                          ? 'Menunggu verifikasi'
                                          : 'Ditolak',
                                      style: TextStyle(
                                        color:
                                            record.status == 'verified'
                                                ? Colors.green
                                                : record.status == 'pending'
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ),
                                    if (record.notes != null)
                                      Text(
                                        'Catatan: ${record.notes}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                                trailing:
                                    record.status == 'pending'
                                        ? IconButton(
                                          icon: const Icon(Icons.check),
                                          onPressed:
                                              () => _verifyMedication(record),
                                          tooltip: 'Verifikasi',
                                        )
                                        : null,
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _verifyMedication(MedicationRecord record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verifikasi Minum Obat'),
          content: const Text(
            'Apakah Anda yakin ingin memverifikasi bukti minum obat ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  record.status = 'verified';
                  record.verifiedBy = 'Petugas'; // Replace with actual user
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bukti minum obat telah diverifikasi'),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Verifikasi'),
            ),
          ],
        );
      },
    );
  }

  void _updateTreatmentStatus(PatientTreatment treatment) {
    int? newStatus = treatment.status;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Status Pengobatan'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<int>(
                    title: const Text('Berjalan'),
                    value: 1,
                    groupValue: newStatus,
                    onChanged: (value) => setState(() => newStatus = value),
                  ),
                  RadioListTile<int>(
                    title: const Text('Selesai'),
                    value: 2,
                    groupValue: newStatus,
                    onChanged: (value) => setState(() => newStatus = value),
                  ),
                  RadioListTile<int>(
                    title: const Text('Gagal'),
                    value: 3,
                    groupValue: newStatus,
                    onChanged: (value) => setState(() => newStatus = value),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newStatus != null && newStatus != treatment.status) {
                  setState(() {
                    treatment.status = newStatus!;
                    // Update adherence rate if treatment is completed or failed
                    if (newStatus == 2) {
                      treatment.adherenceRate = 100.0;
                    } else if (newStatus == 3) {
                      treatment.adherenceRate = 0.0;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status pengobatan diperbarui'),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Helper Methods
  Color _getStatusColor(int status) {
    switch (status) {
      case 1: // Active
        return Colors.blue;
      case 2: // Completed
        return Colors.green;
      case 3: // Failed
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTreatmentStatusText(int status) {
    switch (status) {
      case 1:
        return 'Berjalan';
      case 2:
        return 'Selesai';
      case 3:
        return 'Gagal';
      default:
        return 'Belum dimulai';
    }
  }
}
