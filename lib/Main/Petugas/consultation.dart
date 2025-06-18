import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffConsultationPage extends StatefulWidget {
  const StaffConsultationPage({super.key});

  @override
  State<StaffConsultationPage> createState() => _StaffConsultationState();
}

class _StaffConsultationState extends State<StaffConsultationPage> {
  final List<PublicMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  String? _attachmentPath;
  bool _isStaffMode = true; // Mode petugas (bisa hapus/pin pesan)

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  void _loadInitialMessages() {
    // Contoh data dummy (bisa diganti dengan API)
    _messages.addAll([
      PublicMessage(
        id: 1,
        senderName: "Dr. Andi",
        senderRole: "Petugas",
        message:
            "Selamat datang di forum konsultasi TB! Silakan ajukan pertanyaan.",
        isPinned: true,
        isVerified: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      PublicMessage(
        id: 2,
        senderName: "Budi",
        senderRole: "Pasien",
        message: "Apakah obat TB bisa menyebabkan pusing?",
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      PublicMessage(
        id: 3,
        senderName: "Dr. Citra",
        senderRole: "Petugas",
        message:
            "Ya, itu efek samping yang umum. Minum banyak air dan istirahat.",
        isVerified: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forum Konsultasi TB"),
        actions: [
          IconButton(
            icon: Icon(_isStaffMode ? Icons.verified_user : Icons.person),
            onPressed: () => setState(() => _isStaffMode = !_isStaffMode),
            tooltip: _isStaffMode ? "Mode Petugas" : "Mode Pasien",
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned message (hanya ditampilkan jika ada)
          if (_messages.any((m) => m.isPinned)) _buildPinnedMessage(),

          // Daftar pesan
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input pesan + lampiran (khusus petugas)
          if (_isStaffMode) _buildStaffInputArea(),
        ],
      ),
    );
  }

  Widget _buildPinnedMessage() {
    final pinnedMsg = _messages.firstWhere((m) => m.isPinned);
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.amber[50],
      child: Row(
        children: [
          const Icon(Icons.push_pin, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PESAN PINNED: ${pinnedMsg.message}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "- ${pinnedMsg.senderName} (${DateFormat('HH:mm').format(pinnedMsg.timestamp)})",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (_isStaffMode)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => _unpinMessage(pinnedMsg.id),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(PublicMessage msg) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            msg.senderRole == "Petugas"
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
        children: [
          // Header (nama + role)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment:
                  msg.senderRole == "Petugas"
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
              children: [
                if (msg.senderRole == "Petugas")
                  const Icon(Icons.verified, size: 14, color: Colors.blue),
                Text(
                  msg.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        msg.senderRole == "Petugas"
                            ? Colors.blue
                            : Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 4),
                Chip(
                  label: Text(msg.senderRole),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  backgroundColor:
                      msg.senderRole == "Petugas"
                          ? Colors.blue[50]
                          : Colors.grey[200],
                ),
              ],
            ),
          ),

          // Bubble pesan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                msg.senderRole == "Petugas"
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
            children: [
              if (_isStaffMode && msg.senderRole != "Petugas")
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () => _deleteMessage(msg.id),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        msg.senderRole == "Petugas"
                            ? Colors.blue[50]
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.message),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(msg.timestamp),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isStaffMode && msg.senderRole == "Petugas")
                PopupMenuButton(
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'pin',
                          child: Text("Pin Pesan"),
                        ),
                        const PopupMenuItem(
                          value: 'verify',
                          child: Text("Tandai Verified"),
                        ),
                      ],
                  onSelected: (value) {
                    if (value == 'pin') _togglePinMessage(msg.id);
                    if (value == 'verify') _toggleVerifyMessage(msg.id);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          if (_attachmentPath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _attachmentPath!.split('/').last,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _attachmentPath = null),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _pickAttachment,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: "Tulis pesan...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );
    if (result != null) {
      setState(() => _attachmentPath = result.files.single.path);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty && _attachmentPath == null)
      return;

    setState(() {
      _messages.add(
        PublicMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          senderName: "Anda", // Ganti dengan nama petugas
          senderRole: "Petugas",
          message: _messageController.text,
          timestamp: DateTime.now(),
          isVerified: true, // Default verified untuk petugas
        ),
      );
      _messageController.clear();
      _attachmentPath = null;
    });
  }

  // ===== FUNGSI KHUSUS PETUGAS =====
  void _deleteMessage(int messageId) {
    setState(() => _messages.removeWhere((m) => m.id == messageId));
  }

  void _togglePinMessage(int messageId) {
    setState(() {
      // Unpin semua pesan lain (hanya 1 pinned message)
      for (var msg in _messages) {
        msg.isPinned = (msg.id == messageId) ? !msg.isPinned : false;
      }
    });
  }

  void _toggleVerifyMessage(int messageId) {
    setState(() {
      final msg = _messages.firstWhere((m) => m.id == messageId);
      msg.isVerified = !msg.isVerified;
    });
  }

  void _unpinMessage(int messageId) {
    setState(() {
      final msg = _messages.firstWhere((m) => m.id == messageId);
      msg.isPinned = false;
    });
  }
}

class PublicMessage {
  final int id;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime timestamp;
  bool isPinned;
  bool isVerified;

  PublicMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.isPinned = false,
    this.isVerified = false,
  });
}
