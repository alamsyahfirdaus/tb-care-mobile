import 'dart:convert';
import 'dart:developer';

import 'package:apk_tb_care/Main/Pasien/materi_detail.dart';
import 'package:apk_tb_care/connection.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('${Connection.BASE_URL}/education'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataJson = jsonDecode(response.body);
        log("Data fetched: ${dataJson['data']}");

        final List<dynamic> data = dataJson['data'];
        setState(() {
          _materials = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load materials");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat materi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Materi Edukasi TB"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.article), text: "Image"),
            Tab(icon: Icon(Icons.video_library), text: "Video"),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildMaterialList(
                    _materials
                        .where((m) => m['material_type'] == "image")
                        .toList(),
                  ),
                  _buildMaterialList(
                    _materials
                        .where((m) => m['material_type'] == "video")
                        .toList(),
                  ),
                ],
              ),
    );
  }

  Widget _buildMaterialList(List<dynamic> materials) {
    if (materials.isEmpty) {
      return Center(
        child: Text(
          "Tidak ada materi tersedia",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        final materialType = material['material_type'] ?? 'unknown';
        final thumbnailUrl =
            materialType == 'image'
                ? material['image_url']
                : materialType == 'video'
                ? _getYoutubeThumbnail(material['video_url'])
                : null;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          elevation: 2,
          child: InkWell(
            onTap: () => _handleMaterialTap(material),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail image
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  child: Container(
                    height: 150,
                    color: Colors.grey[200],
                    child:
                        thumbnailUrl != null
                            ? CachedNetworkImage(
                              imageUrl: thumbnailUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) => Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                            )
                            : Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material['title_material'] ?? 'Judul tidak tersedia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (material['description'] != null &&
                          material['description'].isNotEmpty)
                        Text(
                          material['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _getMaterialTypeIcon(materialType),
                            size: 16,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _getMaterialTypeText(materialType),
                            style: TextStyle(fontSize: 12),
                          ),
                          Spacer(),
                          Text(
                            material['created_at'] != null
                                ? DateFormat(
                                  'dd MMM yyyy',
                                ).format(DateTime.parse(material['created_at']))
                                : 'Tanggal tidak tersedia',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper functions
  String? _getYoutubeThumbnail(String? videoUrl) {
    if (videoUrl == null) return null;
    try {
      final videoId = videoUrl.split('v=')[1].split('&')[0];
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    } catch (e) {
      return null;
    }
  }

  IconData _getMaterialTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.video_library;
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getMaterialTypeText(String type) {
    switch (type) {
      case 'video':
        return 'Video';
      case 'image':
        return 'Gambar';
      default:
        return 'File';
    }
  }

  void _handleMaterialTap(Map<String, dynamic> material) async {
    if (material['material_type'] == "url") {
      if (await canLaunch(material['material_url'])) {
        await launch(material['material_url']);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Tidak dapat membuka link")));
      }
    } else {
      // Handle file materials (PDFs)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MateriDetailPage(materialId: material['id']),
        ),
      );
    }
  }
}
