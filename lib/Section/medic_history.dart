import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MedicationHistoryPage extends StatefulWidget {
  final int patientId;

  const MedicationHistoryPage({Key? key, required this.patientId})
    : super(key: key);

  @override
  _MedicationHistoryPageState createState() => _MedicationHistoryPageState();
}

class _MedicationHistoryPageState extends State<MedicationHistoryPage> {
  late Future<List<MedicationRecord>> _recordsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _recordsFuture = _apiService.getMedicationHistory(widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Minum Obat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<MedicationRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada riwayat minum obat'));
          }

          final records = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _buildRecordCard(records[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(MedicationRecord record) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(record.takenAt),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Photo and Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      record.photoUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: record.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.broken_image),
                            ),
                          )
                          : const Center(
                            child: Icon(Icons.medical_services, size: 40),
                          ),
                ),

                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm').format(record.takenAt),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              record.status == 'verified'
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record.status == 'verified'
                              ? 'Terverifikasi'
                              : 'Menunggu Verifikasi',
                          style: TextStyle(
                            color:
                                record.status == 'verified'
                                    ? Colors.green[800]
                                    : Colors.orange[800],
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Notes (if any)
                      if (record.notes != null && record.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Catatan: ${record.notes}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Riwayat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Semua'),
                onTap: () => _applyFilter('all'),
              ),
              ListTile(
                title: const Text('Terverifikasi'),
                onTap: () => _applyFilter('verified'),
              ),
              ListTile(
                title: const Text('Menunggu Verifikasi'),
                onTap: () => _applyFilter('pending'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilter(String filter) {
    Navigator.pop(context);
    setState(() {
      _recordsFuture = _apiService.getMedicationHistory(
        widget.patientId,
        filter: filter,
      );
    });
  }
}

// Models matching your database structure
class MedicationRecord {
  final int id;
  final int patientTreatmentId;
  final String? photoUrl;
  final DateTime takenAt;
  final String status; // 'verified' or 'pending'
  final String? notes;

  MedicationRecord({
    required this.id,
    required this.patientTreatmentId,
    this.photoUrl,
    required this.takenAt,
    required this.status,
    this.notes,
  });
}

// Mock API Service
class ApiService {
  Future<List<MedicationRecord>> getMedicationHistory(
    int patientId, {
    String filter = 'all',
  }) async {
    // Simulate API call to GET /api/medication/history
    await Future.delayed(const Duration(seconds: 1));

    final mockData = [
      MedicationRecord(
        id: 1,
        patientTreatmentId: 1,
        photoUrl: 'https://example.com/medication/1.jpg',
        takenAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'verified',
        notes: 'Minum obat tepat waktu',
      ),
      MedicationRecord(
        id: 2,
        patientTreatmentId: 1,
        photoUrl: 'https://example.com/medication/2.jpg',
        takenAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'verified',
      ),
      MedicationRecord(
        id: 3,
        patientTreatmentId: 1,
        photoUrl: null,
        takenAt: DateTime.now().subtract(const Duration(days: 3)),
        status: 'pending',
        notes: 'Lupa upload foto',
      ),
    ];

    return mockData.where((record) {
      if (filter == 'all') return true;
      if (filter == 'verified') return record.status == 'verified';
      if (filter == 'pending') return record.status == 'pending';
      return true;
    }).toList();
  }
}
