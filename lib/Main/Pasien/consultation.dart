import 'package:apk_tb_care/data/public_chat.dart';
import 'package:flutter/material.dart';

class ConsultationPage extends StatefulWidget {
  const ConsultationPage({super.key});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<PublicChatMessage> _messages = [
    PublicChatMessage(
      text: "Selamat pagi semua! Ada yang bisa saya bantu?",
      senderName: "Dr. Andi",
      senderRole: "Petugas",
      time: "08:00",
      isOfficer: true,
    ),
    PublicChatMessage(
      text: "Saya mau tanya tentang efek samping obat",
      senderName: "Budi",
      senderRole: "Pasien",
      time: "08:05",
      isOfficer: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Konsultasi Publik'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => _showParticipants(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info forum
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue[50],
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Forum ini dibimbing oleh petugas kesehatan. Mohon menjaga etika berkomunikasi.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),

          // Message input
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessage(PublicChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            message.isOfficer
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
        children: [
          // Sender info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment:
                  message.isOfficer
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
              children: [
                if (message.isOfficer) ...[
                  const Icon(Icons.verified_user, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                ],
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        message.isOfficer ? Colors.blue[800] : Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        message.isOfficer ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    message.senderRole,
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          message.isOfficer
                              ? Colors.blue[800]
                              : Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: message.isOfficer ? Colors.blue[50] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    message.isOfficer ? Colors.blue[100]! : Colors.grey[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.text),
                const SizedBox(height: 4),
                Text(
                  message.time,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Tulis pesan...",
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
                if (_messageController.text.trim().isNotEmpty) {
                  _sendMessage(_messageController.text);
                  _messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    setState(() {
      _messages.add(
        PublicChatMessage(
          text: text,
          senderName: "Anda", // Ganti dengan nama user sebenarnya
          senderRole: "Pasien",
          time:
              "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          isOfficer: false,
        ),
      );
    });
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Anggota Forum',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildParticipantTile("Dr. Andi", "Petugas", true),
              _buildParticipantTile("Budi", "Pasien", false),
              _buildParticipantTile("Citra", "Pasien", false),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantTile(String name, String role, bool isOfficer) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isOfficer ? Colors.blue[100] : Colors.grey[200],
        child: Icon(
          isOfficer ? Icons.verified_user : Icons.person,
          color: isOfficer ? Colors.blue : Colors.grey,
        ),
      ),
      title: Text(name),
      subtitle: Text(role),
      trailing: Text(
        isOfficer ? "Online" : "Aktif 5m lalu",
        style: TextStyle(
          color: isOfficer ? Colors.green : Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }
}
