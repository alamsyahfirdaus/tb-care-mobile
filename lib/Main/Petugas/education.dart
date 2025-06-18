import 'dart:io';

import 'package:apk_tb_care/data/educational_material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffEducationPage extends StatefulWidget {
  const StaffEducationPage({super.key});

  @override
  State<StaffEducationPage> createState() => _StaffEducationPageState();
}

class _StaffEducationPageState extends State<StaffEducationPage> {
  List<EducationalMaterial> _materials = [];
  List<EducationalMaterial> _publishedMaterials = [];
  List<EducationalMaterial> _draftMaterials = [];
  bool _isLoading = true;
  int _currentTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    // Simulate API call to GET /api/education (for staff)
    await Future.delayed(const Duration(seconds: 1));

    // Mock data matching your database structure
    setState(() {
      _materials = [
        EducationalMaterial(
          id: 1,
          title: "Panduan Lengkap TB",
          description:
              "Materi komprehensif tentang pencegahan dan pengobatan TB",
          thumbnail: "https://example.com/tb_guide.jpg",
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
          thumbnail: "https://example.com/tb_video_thumb.jpg",
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
          description: "Sumber informasi terpercaya tentang TB (Draft)",
          thumbnail: "https://example.com/tb_website.jpg",
          materialFile: "",
          materialUrl: "https://tbindonesia.org",
          materialType: "url",
          isPublish: 0,
          userId: 1,
          createdAt: DateTime(2023, 4, 15),
          updatedAt: DateTime(2023, 4, 20),
        ),
        EducationalMaterial(
          id: 4,
          title: "Buku Saku TB",
          description: "Panduan praktis untuk pasien TB (Draft)",
          thumbnail: "https://example.com/tb_handbook.jpg",
          materialFile: "tb_handbook.pdf",
          materialUrl: "",
          materialType: "file",
          isPublish: 0,
          userId: 3,
          createdAt: DateTime(2023, 3, 5),
          updatedAt: DateTime(2023, 3, 10),
        ),
      ];

      _publishedMaterials = _materials.where((m) => m.isPublish == 1).toList();
      _draftMaterials = _materials.where((m) => m.isPublish == 0).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // <- Jumlah tab: "Publik" & "Draft"
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Kelola Materi Edukasi"),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddMaterialDialog,
              tooltip: "Tambah Materi Baru",
            ),
          ],
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            tabs: const [
              Tab(text: "Publik", icon: Icon(Icons.public)),
              Tab(text: "Draft", icon: Icon(Icons.edit)),
            ],
          ),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari materi...',
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
                      child: TabBarView(
                        children: [
                          _buildMaterialList(_publishedMaterials),
                          _buildMaterialList(_draftMaterials),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildMaterialList(List<EducationalMaterial> materials) {
    final filteredMaterials =
        materials.where((material) {
          final query = _searchController.text.toLowerCase();
          return material.title.toLowerCase().contains(query) ||
              material.description.toLowerCase().contains(query);
        }).toList();

    if (filteredMaterials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentTabIndex == 0 ? Icons.public_off : Icons.drafts,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _currentTabIndex == 0
                  ? "Tidak ada materi yang dipublikasikan"
                  : "Tidak ada materi draft",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMaterials,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredMaterials.length,
        itemBuilder: (context, index) {
          final material = filteredMaterials[index];
          return _buildMaterialCard(material);
        },
      ),
    );
  }

  Widget _buildMaterialCard(EducationalMaterial material) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _showMaterialDetail(material),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Container(
                height: 150,
                color: Colors.grey[200],
                child:
                    material.thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: material.thumbnail,
                          fit: BoxFit.cover,
                          errorListener:
                              (value) => const Icon(
                                Icons.broken_image,
                                size: 100,
                                color: Colors.grey,
                              ),
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) =>
                                  const Icon(Icons.broken_image),
                        )
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          material.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          material.isPublish == 1 ? "PUBLIK" : "DRAFT",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor:
                            material.isPublish == 1
                                ? Colors.green
                                : Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (material.description.isNotEmpty)
                    Text(
                      material.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        material.materialType == "file"
                            ? Icons.picture_as_pdf
                            : Icons.public,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        material.materialType == "file" ? "PDF" : "LINK",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM yyyy').format(material.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.end,
              buttonPadding: EdgeInsets.zero,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditMaterialDialog(material),
                  tooltip: "Edit",
                ),
                IconButton(
                  icon: Icon(
                    material.isPublish == 1
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () => _togglePublishStatus(material),
                  tooltip:
                      material.isPublish == 1 ? "Sembunyikan" : "Publikasikan",
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _confirmDeleteMaterial(material),
                  tooltip: "Hapus",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMaterialDetail(EducationalMaterial material) {
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
                    "Detail Materi",
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
                child: SingleChildScrollView(
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
                            errorWidget: (context, url, error) {
                              return const Icon(
                                Icons.broken_image,
                                size: 100,
                                color: Colors.grey,
                              );
                            },
                            errorListener:
                                (value) => const Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        material.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              material.isPublish == 1 ? "PUBLIK" : "DRAFT",
                            ),
                            backgroundColor:
                                material.isPublish == 1
                                    ? Colors.green
                                    : Colors.blue,
                          ),
                          const Spacer(),
                          Text(
                            "Diunggah: ${DateFormat('dd MMM yyyy').format(material.createdAt)}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (material.description.isNotEmpty)
                        Text(
                          material.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        "Jenis: ${material.materialType == "file" ? "File" : "URL"}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        material.materialType == "file"
                            ? material.materialFile
                            : material.materialUrl,
                      ),
                      const SizedBox(height: 24),
                      if (material.materialType == "url")
                        ElevatedButton.icon(
                          onPressed: () => _launchUrl(material.materialUrl),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text("Buka Link"),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showEditMaterialDialog(material),
                      child: const Text("Edit"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _togglePublishStatus(material),
                      child: Text(
                        material.isPublish == 1
                            ? "Sembunyikan"
                            : "Publikasikan",
                      ),
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

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tidak dapat membuka link")));
    }
  }

  void _showAddMaterialDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    String? materialType = "file";
    String? thumbnailPath;
    String? filePath;
    int isPublish = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Tambah Materi Edukasi Baru"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Judul Materi*",
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? "Harap isi judul materi"
                                    : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Deskripsi",
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: materialType,
                        decoration: const InputDecoration(
                          labelText: "Jenis Materi*",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "file",
                            child: Text("File (PDF/Dokumen)"),
                          ),
                          DropdownMenuItem(
                            value: "url",
                            child: Text("URL (Link Website/Video)"),
                          ),
                        ],
                        onChanged:
                            (value) => setState(() => materialType = value),
                      ),
                      const SizedBox(height: 16),
                      if (materialType == "file")
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final result = await FilePicker.platform
                                    .pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['pdf', 'doc', 'docx'],
                                    );
                                if (result != null) {
                                  setState(() {
                                    filePath = result.files.single.path!;
                                  });
                                }
                              },
                              child: const Text("Pilih File"),
                            ),
                            if (filePath != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  filePath!.split('/').last,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      if (materialType == "url")
                        TextFormField(
                          controller: urlController,
                          decoration: const InputDecoration(
                            labelText: "URL*",
                            hintText: "https://example.com",
                          ),
                          keyboardType: TextInputType.url,
                          validator:
                              (value) =>
                                  materialType == "url" && value!.isEmpty
                                      ? "Harap masukkan URL"
                                      : null,
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final pickedFile = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            setState(() {
                              thumbnailPath = pickedFile.path;
                            });
                          }
                        },
                        child: const Text("Unggah Thumbnail"),
                      ),
                      if (thumbnailPath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Image.file(
                            File(thumbnailPath!),
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text("Publikasikan Sekarang"),
                        value: isPublish == 1,
                        onChanged:
                            (value) =>
                                setState(() => isPublish = value ? 1 : 0),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (materialType == "file" && filePath == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Harap pilih file terlebih dahulu"),
                          ),
                        );
                        return;
                      }

                      // Simulate API call to POST /api/education
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      // Mock upload process
                      await Future.delayed(const Duration(seconds: 2));

                      final newMaterial = EducationalMaterial(
                        id: _materials.length + 1,
                        title: titleController.text,
                        description: descriptionController.text,
                        thumbnail: thumbnailPath ?? "",
                        materialFile: filePath ?? "",
                        materialUrl: urlController.text,
                        materialType: materialType!,
                        isPublish: isPublish,
                        userId: 1, // Replace with actual user ID
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      setState(() {
                        _materials.insert(0, newMaterial);
                        if (isPublish == 1) {
                          _publishedMaterials.insert(0, newMaterial);
                        } else {
                          _draftMaterials.insert(0, newMaterial);
                        }
                        _isLoading = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Materi berhasil ditambahkan"),
                        ),
                      );
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMaterialDialog(EducationalMaterial material) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: material.title);
    final descriptionController = TextEditingController(
      text: material.description,
    );
    final urlController = TextEditingController(text: material.materialUrl);
    String? materialType = material.materialType;
    String? thumbnailPath;
    String? filePath;
    int isPublish = material.isPublish;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Materi Edukasi"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Judul Materi*",
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? "Harap isi judul materi"
                                    : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Deskripsi",
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: materialType,
                        decoration: const InputDecoration(
                          labelText: "Jenis Materi*",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "file",
                            child: Text("File (PDF/Dokumen)"),
                          ),
                          DropdownMenuItem(
                            value: "url",
                            child: Text("URL (Link Website/Video)"),
                          ),
                        ],
                        onChanged:
                            (value) => setState(() => materialType = value),
                      ),
                      const SizedBox(height: 16),
                      if (materialType == "file")
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final result = await FilePicker.platform
                                    .pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['pdf', 'doc', 'docx'],
                                    );
                                if (result != null) {
                                  setState(() {
                                    filePath = result.files.single.path!;
                                  });
                                }
                              },
                              child: const Text("Pilih File Baru"),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                filePath?.split('/').last ??
                                    material.materialFile,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (materialType == "url")
                        TextFormField(
                          controller: urlController,
                          decoration: const InputDecoration(
                            labelText: "URL*",
                            hintText: "https://example.com",
                          ),
                          keyboardType: TextInputType.url,
                          validator:
                              (value) =>
                                  materialType == "url" && value!.isEmpty
                                      ? "Harap masukkan URL"
                                      : null,
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final pickedFile = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            setState(() {
                              thumbnailPath = pickedFile.path;
                            });
                          }
                        },
                        child: const Text("Unggah Thumbnail Baru"),
                      ),
                      if (thumbnailPath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Image.file(
                            File(thumbnailPath!),
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                          ),
                        )
                      else if (material.thumbnail.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: CachedNetworkImage(
                            imageUrl: material.thumbnail,
                            height: 100,
                            fit: BoxFit.cover,
                            errorListener:
                                (value) => const Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text("Publikasikan"),
                        value: isPublish == 1,
                        onChanged:
                            (value) =>
                                setState(() => isPublish = value ? 1 : 0),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (materialType == "file" &&
                          filePath == null &&
                          material.materialFile.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Harap pilih file terlebih dahulu"),
                          ),
                        );
                        return;
                      }

                      // Simulate API call to PUT /api/education/{id}
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      // Mock update process
                      await Future.delayed(const Duration(seconds: 2));

                      final updatedMaterial = EducationalMaterial(
                        id: material.id,
                        title: titleController.text,
                        description: descriptionController.text,
                        thumbnail: thumbnailPath ?? material.thumbnail,
                        materialFile: filePath ?? material.materialFile,
                        materialUrl: urlController.text,
                        materialType: materialType!,
                        isPublish: isPublish,
                        userId: material.userId,
                        createdAt: material.createdAt,
                        updatedAt: DateTime.now(),
                      );

                      setState(() {
                        final index = _materials.indexWhere(
                          (m) => m.id == material.id,
                        );
                        if (index != -1) {
                          _materials[index] = updatedMaterial;
                        }

                        // Update published/draft lists
                        _publishedMaterials =
                            _materials.where((m) => m.isPublish == 1).toList();
                        _draftMaterials =
                            _materials.where((m) => m.isPublish == 0).toList();
                        _isLoading = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Materi berhasil diperbarui"),
                        ),
                      );
                    }
                  },
                  child: const Text("Simpan Perubahan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _togglePublishStatus(EducationalMaterial material) async {
    final newStatus = material.isPublish == 1 ? 0 : 1;

    // Simulate API call to update status
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    final updatedMaterial = EducationalMaterial(
      id: material.id,
      title: material.title,
      description: material.description,
      thumbnail: material.thumbnail,
      materialFile: material.materialFile,
      materialUrl: material.materialUrl,
      materialType: material.materialType,
      isPublish: newStatus,
      userId: material.userId,
      createdAt: material.createdAt,
      updatedAt: DateTime.now(),
    );

    setState(() {
      final index = _materials.indexWhere((m) => m.id == material.id);
      if (index != -1) {
        _materials[index] = updatedMaterial;
      }

      _publishedMaterials = _materials.where((m) => m.isPublish == 1).toList();
      _draftMaterials = _materials.where((m) => m.isPublish == 0).toList();
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 1
              ? "Materi telah dipublikasikan"
              : "Materi disimpan sebagai draft",
        ),
        backgroundColor: newStatus == 1 ? Colors.green : Colors.blue,
      ),
    );

    if (ModalRoute.of(context)?.isCurrent != true) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDeleteMaterial(EducationalMaterial material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Hapus Materi?"),
            content: Text(
              "Anda yakin ingin menghapus materi '${material.title}'?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Hapus"),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // Simulate API call to DELETE /api/education/{id}
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _materials.removeWhere((m) => m.id == material.id);
        _publishedMaterials.removeWhere((m) => m.id == material.id);
        _draftMaterials.removeWhere((m) => m.id == material.id);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Materi berhasil dihapus"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
