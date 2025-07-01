import 'dart:convert';
import 'dart:io';
import 'package:apk_tb_care/connection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ConsultationPage extends StatefulWidget {
  final bool isStaff;

  const ConsultationPage({super.key, this.isStaff = false});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> recipients = [];
  List<dynamic> _consultations = [];
  bool _isLoading = true;
  File? _attachment;
  String? _attachmentName;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId().then((_) {
      _loadConsultations();
      if (widget.isStaff) {
        loadRecipients();
      }
    });
  }

  Future<void> _getCurrentUserId() async {
    final session = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = session.getString('user_id');
    });
  }

  Future<void> loadRecipients() async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('${Connection.BASE_URL}/consultations/recipients'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> dataJson = jsonDecode(response.body);
        setState(() {
          recipients =
              (dataJson['data'] as List).map<Map<String, dynamic>>((item) {
                return {
                  'id': item['id'],
                  'name': item['name'],
                  'email': item['email'],
                  'role': item['role'],
                };
              }).toList();
        });
      } else {
        throw Exception(
          'Failed to load recipients status code ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _loadConsultations() async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      final url =
          widget.isStaff
              ? '${Connection.BASE_URL}/consultations/staff'
              : '${Connection.BASE_URL}/consultations';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _consultations = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load consultations");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal memuat konsultasi")));
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _attachment = File(result.files.single.path!);
        _attachmentName = result.files.single.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Forum Konsultasi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Konsultasi'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConsultations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info forum
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isStaff
                        ? 'Anda dapat menghapus konsultasi atau balasan yang tidak pantas'
                        : 'Forum ini dibimbing oleh petugas kesehatan. Mohon menjaga etika berkomunikasi.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Consultation list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _consultations.length,
              itemBuilder: (context, index) {
                return _buildConsultationCard(_consultations[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          widget.isStaff
              ? null
              : FloatingActionButton(
                onPressed: () => _showNewConsultationDialog(),
                child: const Icon(Icons.add),
              ),
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> consultation) {
    final hasReplies = (consultation['replies'] as List?)?.isNotEmpty ?? false;
    final isAnswered = consultation['is_answered'] == 1;
    final createdAt = _formatDateTime(consultation['created_at']);
    final isPublic = consultation['recipient_id'] == null;
    final isOwnedByCurrentUser =
        consultation['sender_id'].toString() == _currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showConsultationDetail(consultation),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      consultation['title'] ?? 'Tanpa judul',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!isPublic)
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Colors.orange,
                    ),
                  if (isAnswered)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(consultation['message'] ?? ''),

              if (consultation['attachment'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () => _viewAttachment(consultation['attachment']),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          consultation['attachment'].split('/').last,
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Oleh: ${consultation['sender_name'] ?? 'Anonim'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    createdAt,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              if (hasReplies) ...[
                const SizedBox(height: 8),
                Text(
                  '${consultation['replies'].length} balasan',
                  style: TextStyle(color: Colors.blue[600], fontSize: 12),
                ),
              ],
              if (widget.isStaff || isOwnedByCurrentUser)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed:
                        () => _confirmDeleteConsultation(consultation['id']),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConsultationDetail(Map<String, dynamic> consultation) {
    final isOwnedByCurrentUser =
        consultation['sender_id'].toString() == _currentUserId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      consultation['title'] ?? 'Detail Konsultasi',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (consultation['recipient_name'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Kepada: ${consultation['recipient_name']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Original message
                      _buildCommentBubble(
                        message: consultation['message'] ?? '',
                        sender: consultation['sender_name'] ?? 'Anonim',
                        time: _formatDateTime(consultation['created_at']),
                        attachment: consultation['attachment'],
                        canDelete: widget.isStaff || isOwnedByCurrentUser,
                        onDelete:
                            () =>
                                _confirmDeleteConsultation(consultation['id']),
                      ),

                      // Replies
                      ...(consultation['replies'] as List?)?.map((reply) {
                            final isReplyOwnedByCurrentUser =
                                reply['sender_id'].toString() == _currentUserId;
                            return _buildCommentBubble(
                              message: reply['message'] ?? '',
                              sender: reply['sender_name'] ?? 'Pengguna',
                              time: _formatDateTime(reply['created_at']),
                              attachment: reply['attachment'],
                              canDelete:
                                  widget.isStaff || isReplyOwnedByCurrentUser,
                              onDelete:
                                  () => _confirmDeleteReply(
                                    consultation['id'],
                                    reply['id'],
                                  ),
                            );
                          }) ??
                          [],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (widget.isStaff ||
                  consultation['recipient_id'] == null ||
                  consultation['recipient_id'].toString() == _currentUserId)
                _buildReplyInput(consultation['id']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentBubble({
    required String message,
    required String sender,
    required String time,
    String? attachment,
    bool canDelete = false,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sender,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (canDelete) ...[
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16),
                        onPressed: onDelete,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      if (attachment != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _viewAttachment(attachment),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                attachment.split('/').last,
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
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

  Widget _buildReplyInput(int consultationId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          if (_attachment != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _attachmentName ?? 'Lampiran',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.blue[600], fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _attachment = null;
                        _attachmentName = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _pickFile,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: "Tulis balasan...",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty ||
                        _attachment != null) {
                      _sendReply(consultationId, _messageController.text);
                      _messageController.clear();
                      setState(() {
                        _attachment = null;
                        _attachmentName = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNewConsultationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    File? newAttachment;
    String? newAttachmentName;
    bool isPublic = true;
    String? selectedRecipientId;
    String? selectedRecipientName;

    Future<void> pickFile() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        newAttachment = File(result.files.single.path!);
        newAttachmentName = result.files.single.name;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Buat Konsultasi Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Judul
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul',
                        hintText: 'Masukkan judul konsultasi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Pesan
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Pesan',
                        hintText: 'Tulis pertanyaan atau keluhan Anda',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    /// Opsi Publik/Privat
                    Row(
                      children: [
                        Checkbox(
                          value: isPublic,
                          onChanged: (value) {
                            setState(() {
                              isPublic = value ?? true;
                              if (isPublic) {
                                selectedRecipientId = null;
                                selectedRecipientName = null;
                              }
                            });
                          },
                        ),
                        const Text('Publik'),
                      ],
                    ),

                    /// Dropdown Petugas Kesehatan
                    if (!isPublic) ...[
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Petugas Kesehatan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: selectedRecipientId,
                        items:
                            recipients.map((recipient) {
                              return DropdownMenuItem<String>(
                                value: recipient['id'].toString(),
                                child: Text(recipient['name']),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRecipientId = value;
                            selectedRecipientName =
                                recipients.firstWhere(
                                  (r) => r['id'].toString() == value,
                                )['name'];
                          });
                        },
                        hint: const Text('Pilih Petugas'),
                        validator: (value) {
                          if (!isPublic && (value == null || value.isEmpty)) {
                            return 'Harap pilih petugas';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(),

                    /// Lampiran
                    if (newAttachment != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                newAttachmentName ?? 'Lampiran',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                setState(() {
                                  newAttachment = null;
                                  newAttachmentName = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Lampirkan File'),
                        onPressed: pickFile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        (messageController.text.isNotEmpty ||
                            newAttachment != null)) {
                      await _createNewConsultation(
                        titleController.text,
                        messageController.text,
                        isPublic ? null : selectedRecipientId,
                        newAttachment,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendReply(int consultationId, String message) async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Connection.BASE_URL}/consultations/reply'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['consultation_id'] = consultationId.toString();
      request.fields['message'] = message;

      if (_attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'attachment',
            _attachment!.path,
            contentType: MediaType('application', 'octet-stream'),
          ),
        );
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Balasan terkirim')));
        _loadConsultations();
      } else {
        throw Exception('Failed to send reply ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim balasan: $e')));
    }
  }

  Future<void> _createNewConsultation(
    String title,
    String message,
    String? recipientId,
    File? attachment,
  ) async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Connection.BASE_URL}/consultations/store'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = title;
      request.fields['message'] = message;
      if (recipientId != null) {
        request.fields['recipient_id'] = recipientId;
      }

      if (attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'attachment',
            attachment.path,
            contentType: MediaType('application', 'octet-stream'),
          ),
        );
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Konsultasi baru dibuat')));
        _loadConsultations();
      } else {
        throw Exception('Failed to create consultation');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat konsultasi: $e')));
    }
  }

  Future<void> _deleteConsultation(int consultationId) async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      final response = await http.delete(
        Uri.parse('${Connection.BASE_URL}/consultations/$consultationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konsultasi berhasil dihapus')),
        );
        _loadConsultations();
      } else {
        throw Exception('Failed to delete consultation');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus konsultasi: $e')));
    }
  }

  Future<void> _deleteReply(int consultationId, int replyId) async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      final response = await http.delete(
        Uri.parse(
          '${Connection.BASE_URL}/consultations/$consultationId/replies/$replyId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balasan berhasil dihapus')),
        );
        _loadConsultations();
      } else {
        throw Exception('Failed to delete reply');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus balasan: $e')));
    }
  }

  void _confirmDeleteConsultation(int consultationId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Konsultasi'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus konsultasi ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteConsultation(consultationId);
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteReply(int consultationId, int replyId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Balasan'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus balasan ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteReply(consultationId, replyId);
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _viewAttachment(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File tidak tersedia')));
      return;
    }

    final fileName = url.split('/').last;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(fileName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getFileIcon(fileName),
              const SizedBox(height: 16),
              Text('Lampiran: $fileName', textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _downloadFile(url);
              },
              child: const Text('Unduh'),
            ),
          ],
        );
      },
    );
  }

  Widget _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const iconSize = 48.0;

    if (['pdf'].contains(ext)) {
      return const Icon(
        Icons.picture_as_pdf,
        size: iconSize,
        color: Colors.red,
      );
    } else if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
      return const Icon(Icons.image, size: iconSize, color: Colors.blue);
    } else if (['doc', 'docx'].contains(ext)) {
      return const Icon(Icons.description, size: iconSize, color: Colors.blue);
    } else if (['xls', 'xlsx'].contains(ext)) {
      return const Icon(Icons.table_chart, size: iconSize, color: Colors.green);
    } else {
      return const Icon(Icons.insert_drive_file, size: iconSize);
    }
  }

  Future<void> _downloadFile(String url) async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }

        if (await Permission.manageExternalStorage.isDenied) {
          await Permission.manageExternalStorage.request();
        }

        if (!await Permission.manageExternalStorage.isGranted) {
          throw Exception('Storage permission required');
        }
      }

      final dir =
          Platform.isAndroid
              ? await getExternalStorageDirectory()
              : await getApplicationDocumentsDirectory();

      final fileName = url.split('/').last;
      final savePath = '${dir!.path}/$fileName';

      await Dio().download(url, savePath);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File downloaded to $savePath')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.toString()}')),
      );
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final format = DateFormat('yyyy-MM-dd HH:mm');
      final dt = format.parse(dateTime);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return dateTime;
    }
  }
}
