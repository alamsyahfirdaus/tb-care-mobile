import 'dart:convert';
import 'package:apk_tb_care/connection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MedicationHistoryPage extends StatefulWidget {
  final int patientId;

  const MedicationHistoryPage({Key? key, required this.patientId})
    : super(key: key);

  @override
  _MedicationHistoryPageState createState() => _MedicationHistoryPageState();
}

class _MedicationHistoryPageState extends State<MedicationHistoryPage> {
  late Future<List<dynamic>> _recordsFuture;
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _recordsFuture = _fetchRecordData();
  }

  Future<List<dynamic>> _fetchRecordData() async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse(
          '${Connection.BASE_URL}/treatments/${widget.patientId}/history',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataJson = jsonDecode(response.body);
        return dataJson['data'] ?? [];
      } else {
        throw Exception('Failed to load medication history');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memuat riwayat obat")),
      );
      return [];
    }
  }

  List<dynamic> _filterRecords(List<dynamic> records) {
    return records.where((record) {
      if (_currentFilter == 'all') return true;
      if (_currentFilter == 'verified') return record['is_verified'] == 1;
      if (_currentFilter == 'pending') return record['is_verified'] == 0;
      if (_currentFilter == 'late') return record['late'] == 1;
      return true;
    }).toList();
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
      body: FutureBuilder<List<dynamic>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada riwayat minum obat'));
          }

          final filteredRecords = _filterRecords(snapshot.data!);
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredRecords.length,
            itemBuilder: (context, index) {
              return _buildRecordCard(filteredRecords[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final isVerified = record['is_verified'] == 1;
    final isLate = record['late'] == 1;
    final submittedAt = DateTime.parse(record['submitted_at']);
    final photoUrl = record['photo_url'];
    final notes = record['notes'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isVerified ? Colors.green[50] : Colors.orange[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.pending,
                  size: 16,
                  color: isVerified ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  isVerified ? 'Terverifikasi' : 'Menunggu Verifikasi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isVerified ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
                const Spacer(),
                if (isLate)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Terlambat',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
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
                      photoUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: photoUrl,
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
                      // Submission Info
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'EEEE, d MMMM yyyy - HH:mm',
                            ).format(submittedAt),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record['submitted_relative'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      // Notes (if any)
                      if (notes != null && notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Catatan: $notes',
                          style: const TextStyle(fontSize: 12),
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
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentFilter = 'all';
                  });
                },
              ),
              ListTile(
                title: const Text('Terverifikasi'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentFilter = 'verified';
                  });
                },
              ),
              ListTile(
                title: const Text('Menunggu Verifikasi'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentFilter = 'pending';
                  });
                },
              ),
              ListTile(
                title: const Text('Terlambat'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentFilter = 'late';
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
