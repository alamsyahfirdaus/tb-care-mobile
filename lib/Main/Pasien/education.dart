import 'package:apk_tb_care/data/educational_material.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EducationalMaterial> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    // Simulate API call to GET /api/education
    await Future.delayed(Duration(seconds: 1));

    // Mock data matching your database structure
    setState(() {
      _materials = [
        EducationalMaterial(
          id: 1,
          title: "Panduan Lengkap TB",
          description:
              "Materi komprehensif tentang pencegahan dan pengobatan TB",
          thumbnail: "assets/tb_guide.jpg",
          materialFile: "tb_guide.pdf",
          materialUrl: "",
          materialType: "file",
          isPublish: 1,
          userId: 1,
          createdAt: DateTime(2023, 5, 10),
          updatedAt: DateTime(2023, 5, 15),
        ),
        EducationalMaterial(
          id: 2,
          title: "Video Edukasi TB",
          description: "Video animasi tentang penularan TB",
          thumbnail: "assets/tb_video_thumb.jpg",
          materialFile: "",
          materialUrl: "https://youtube.com/watch?v=tb_education",
          materialType: "url",
          isPublish: 1,
          userId: 2,
          createdAt: DateTime(2023, 6, 1),
          updatedAt: DateTime(2023, 6, 1),
        ),
        EducationalMaterial(
          id: 3,
          title: "Website Resmi TB Indonesia",
          description: "Sumber informasi terpercaya tentang TB",
          thumbnail: "assets/tb_website.jpg",
          materialFile: "",
          materialUrl: "https://tbindonesia.org",
          materialType: "url",
          isPublish: 1,
          userId: 1,
          createdAt: DateTime(2023, 4, 15),
          updatedAt: DateTime(2023, 4, 20),
        ),
        EducationalMaterial(
          id: 4,
          title: "Buku Saku TB",
          description: "Panduan praktis untuk pasien TB",
          thumbnail: "assets/tb_handbook.jpg",
          materialFile: "tb_handbook.pdf",
          materialUrl: "",
          materialType: "file",
          isPublish: 1,
          userId: 3,
          createdAt: DateTime(2023, 3, 5),
          updatedAt: DateTime(2023, 3, 10),
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Materi Edukasi TB"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.article), text: "Artikel"),
            Tab(icon: Icon(Icons.video_library), text: "Video"),
            Tab(icon: Icon(Icons.public), text: "Website"),
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
                    _materials.where((m) => m.materialType == "file").toList(),
                  ),
                  _buildMaterialList(
                    _materials
                        .where((m) => m.materialUrl.contains("youtube"))
                        .toList(),
                  ),
                  _buildMaterialList(
                    _materials
                        .where(
                          (m) =>
                              m.materialType == "url" &&
                              !m.materialUrl.contains("youtube"),
                        )
                        .toList(),
                  ),
                ],
              ),
    );
  }

  Widget _buildMaterialList(List<EducationalMaterial> materials) {
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
                        material.thumbnail.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: material.thumbnail,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      Icon(Icons.broken_image),
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
                        material.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (material.description.isNotEmpty)
                        Text(
                          material.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            material.materialType == "file"
                                ? Icons.picture_as_pdf
                                : Icons.public,
                            size: 16,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            material.materialType == "file" ? "PDF" : "Website",
                            style: TextStyle(fontSize: 12),
                          ),
                          Spacer(),
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(material.createdAt),
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

  void _handleMaterialTap(EducationalMaterial material) async {
    if (material.materialType == "url") {
      if (await canLaunch(material.materialUrl)) {
        await launch(material.materialUrl);
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
          builder: (context) => MaterialDetailPage(material: material),
        ),
      );
    }
  }
}

class MaterialDetailPage extends StatelessWidget {
  final EducationalMaterial material;

  const MaterialDetailPage({Key? key, required this.material})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(material.title),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareMaterial(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (material.thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: material.thumbnail,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 16),
            Text(
              material.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Diunggah pada: ${DateFormat('dd MMMM yyyy').format(material.createdAt)}",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            if (material.description.isNotEmpty)
              Text(material.description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 24),
            if (material.materialType == "file")
              ElevatedButton.icon(
                onPressed: () => _downloadFile(material.materialFile),
                icon: Icon(Icons.download),
                label: Text("Download PDF"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _shareMaterial(BuildContext context) {
    // Implement share functionality
  }

  void _downloadFile(String fileUrl) {
    // Implement file download
  }
}
