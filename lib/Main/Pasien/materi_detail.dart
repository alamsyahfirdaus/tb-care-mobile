import 'dart:convert';
import 'package:apk_tb_care/connection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MateriDetailPage extends StatefulWidget {
  final int materialId;

  const MateriDetailPage({super.key, required this.materialId});

  @override
  State<MateriDetailPage> createState() => _MateriDetailPageState();
}

class _MateriDetailPageState extends State<MateriDetailPage> {
  late Map<String, dynamic> material = {};
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _fetchMaterialDetail();
  }

  Future<void> _fetchMaterialDetail() async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('${Connection.BASE_URL}/education/${widget.materialId}/show'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataJson = jsonDecode(response.body);
        setState(() {
          material = dataJson['data'] ?? {};
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load material details");
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load material details")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isError || material.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Detail Materi")),
        body: const Center(child: Text("Gagal memuat detail materi")),
      );
    }

    final materialType = material['material_type'] ?? 'unknown';
    final thumbnailUrl =
        materialType == 'image'
            ? material['image_url']
            : materialType == 'video'
            ? _getYoutubeThumbnail(material['video_url'])
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(material['title_material'] ?? 'Detail Materi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareMaterial(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 50),
                      ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              material['title_material'] ?? 'Judul tidak tersedia',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Diunggah pada: ${_formatCreatedAt(material['created_at'])}",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (material['description'] != null &&
                material['description'].isNotEmpty)
              Text(
                material['description'],
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 24),
            if (materialType == 'video' && material['video_url'] != null)
              ElevatedButton.icon(
                onPressed: () => _openVideo(material['video_url']),
                icon: const Icon(Icons.play_arrow),
                label: const Text("Tonton Video"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            if (materialType == 'image' && material['image_url'] != null)
              ElevatedButton.icon(
                onPressed: () => _viewFullImage(material['image_url']),
                icon: const Icon(Icons.fullscreen),
                label: const Text("Lihat Gambar Penuh"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCreatedAt(String? createdAt) {
    if (createdAt == null) return 'Tanggal tidak tersedia';
    try {
      final dateTime = DateTime.parse(createdAt);
      return DateFormat('dd MMMM yyyy').format(dateTime);
    } catch (e) {
      return 'Tanggal tidak valid';
    }
  }

  String? _getYoutubeThumbnail(String? videoUrl) {
    if (videoUrl == null) return null;
    try {
      final videoId = videoUrl.split('v=')[1].split('&')[0];
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    } catch (e) {
      return null;
    }
  }

  void _shareMaterial(BuildContext context) {
    // Implement share functionality
    final shareText =
        '${material['title_material']}\n\n${material['description']}';
    // Use share plugin like share_plus
  }

  void _openVideo(String videoUrl) async {
    final Uri url = Uri.parse(videoUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal membuka video')));
    }
  }

  void _viewFullImage(String imageUrl) {
    // Implement full screen image viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(),
              body: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  errorWidget:
                      (context, url, error) =>
                          const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
      ),
    );
  }
}
