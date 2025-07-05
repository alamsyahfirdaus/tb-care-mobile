import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'consultation_service.dart';

class ConsultationDetailPage extends StatefulWidget {
  final String consultationId;
  final ConsultationService service;
  final bool isStaff;
  final String currentUserId;
  final String? currentUserName;

  const ConsultationDetailPage({
    super.key,
    required this.consultationId,
    required this.service,
    required this.isStaff,
    required this.currentUserId,
    this.currentUserName,
  });

  @override
  State<ConsultationDetailPage> createState() => _ConsultationDetailPageState();
}

class _ConsultationDetailPageState extends State<ConsultationDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _replies = [];
  Map<String, dynamic>? _consultation;
  File? _attachment;
  String? _attachmentName;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupRealtimeListeners();

    log(_replies.toString());
  }

  Future<void> _loadInitialData() async {
    try {
      log("Loading consultation: ${widget.consultationId}");

      final consultation = await widget.service.loadConsultation(
        widget.consultationId,
      );
      final replies = await widget.service.loadReplies(widget.consultationId);

      if (mounted) {
        setState(() {
          _consultation = _convertToMapStringDynamic(consultation);
          _replies = _sortReplies(
            replies.map(_convertToMapStringDynamic).toList(),
          );
        });
        _scrollToBottom();
      }
    } catch (e, stack) {
      log("Error loading data", error: e, stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: ${e.toString()}')),
        );
        await _loadDirectFromFirebase();
      }
    }
  }

  List<dynamic> _sortReplies(List<dynamic> replies) {
    return replies..sort((a, b) {
      final dateA = DateTime.parse(a['created_at'] ?? '1970-01-01');
      final dateB = DateTime.parse(b['created_at'] ?? '1970-01-01');
      return dateA.compareTo(dateB); // Urutan dari yang terlama ke terbaru
    });
  }

  Map<String, dynamic> _convertToMapStringDynamic(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map<dynamic, dynamic>) {
      return data.map(
        (key, value) => MapEntry(
          key.toString(),
          value is Map ? _convertToMapStringDynamic(value) : value,
        ),
      );
    }
    return {};
  }

  Future<void> _loadDirectFromFirebase() async {
    try {
      final consultationSnapshot =
          await widget.service.consultationsRef
              .child(widget.consultationId)
              .get();

      final repliesSnapshot =
          await widget.service.repliesRef.child(widget.consultationId).get();

      if (mounted) {
        setState(() {
          _consultation = _convertToMapStringDynamic(
            consultationSnapshot.value,
          );

          if (repliesSnapshot.exists) {
            final repliesData = repliesSnapshot.value as Map<dynamic, dynamic>?;
            _replies =
                repliesData?.values.map(_convertToMapStringDynamic).toList() ??
                [];
          }
        });
      }
    } catch (e) {
      log("Direct Firebase load failed: $e");
    }
  }

  void _setupRealtimeListeners() {
    widget.service.consultationsRef.child(widget.consultationId).onValue.listen(
      (event) {
        if (mounted) {
          setState(() {
            _consultation = _convertToMapStringDynamic(event.snapshot.value);
          });
        }
      },
    );

    widget.service.repliesRef.child(widget.consultationId).onValue.listen((
      event,
    ) {
      if (mounted) {
        final data = event.snapshot.value;
        if (data != null) {
          setState(() {
            _replies = _sortReplies(
              (data as Map<dynamic, dynamic>).values
                  .map(_convertToMapStringDynamic)
                  .toList(),
            );
            _scrollToBottom();
          });
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_consultation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_consultation!['title'] ?? 'Detail Konsultasi'),
        actions: [
          if (widget.isStaff ||
              _consultation!['user_id'] == widget.currentUserId)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(_consultation!, true),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageTile(_consultation!, isConsultation: true),
                  const SizedBox(height: 16),
                  ..._replies.map((reply) => _buildMessageTile(reply)),
                  if (_isSending) _buildSendingIndicator(),
                ],
              ),
            ),
          ),
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildMessageTile(
    Map<String, dynamic> message, {
    bool isConsultation = false,
  }) {
    final isOwned = message['user_id'] == widget.currentUserId;
    final alignment =
        isOwned ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = isOwned ? Colors.blue[50] : Colors.grey[50];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (!isConsultation && !isOwned)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message['sender_name'] ?? 'Anonim',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isConsultation)
                  Text(
                    message['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                if (isConsultation) const SizedBox(height: 8),
                Text(message['message'] ?? ''),
                if (message['attachment'] != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap:
                        () => widget.service.viewAttachment(
                          context,
                          message['attachment'],
                        ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_file, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          message['attachment'].split('/').last,
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.service.formatDateTime(message['created_at']),
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ),
          if (!isConsultation && (widget.isStaff || isOwned))
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, size: 16),
                onPressed: () => _confirmDelete(message, false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSendingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Mengirim...',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        color: Colors.white,
      ),
      child: Column(
        children: [
          if (_attachment != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _attachmentName ?? 'Lampiran',
                      overflow: TextOverflow.ellipsis,
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isSending ? null : _sendReply,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachment = File(result.files.single.path!);
          _attachmentName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file: ${e.toString()}')),
      );
    }
  }

  Future<void> _sendReply() async {
    if (_messageController.text.trim().isEmpty && _attachment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan atau lampiran diperlukan')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await widget.service.sendReply(
        widget.consultationId,
        _messageController.text,
        _attachment,
        _attachmentName,
      );

      _messageController.clear();
      setState(() {
        _attachment = null;
        _attachmentName = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim balasan: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _confirmDelete(Map<String, dynamic> message, bool isConsultation) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isConsultation ? 'Hapus Konsultasi' : 'Hapus Balasan'),
            content: Text(
              isConsultation
                  ? 'Apakah Anda yakin ingin menghapus konsultasi ini?'
                  : 'Apakah Anda yakin ingin menghapus balasan ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    if (isConsultation) {
                      await widget.service.deleteConsultation(message['id']);
                      if (mounted) Navigator.pop(context);
                    } else {
                      await widget.service.deleteReply(
                        widget.consultationId,
                        message['id'],
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menghapus: ${e.toString()}'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
