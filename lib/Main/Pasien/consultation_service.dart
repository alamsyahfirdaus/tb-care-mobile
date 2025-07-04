import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:apk_tb_care/connection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

class ConsultationService {
  final DatabaseReference _consultationsRef;
  final DatabaseReference _repliesRef;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  DatabaseReference get consultationsRef => _consultationsRef;
  DatabaseReference get repliesRef => _repliesRef;

  List<Map<String, dynamic>> recipients = [];
  StreamSubscription<DatabaseEvent>? _consultationSubscription;
  StreamSubscription<DatabaseEvent>? _repliesSubscription;

  static const String _databaseUrl =
      'https://apk-tb-care-default-rtdb.asia-southeast1.firebasedatabase.app';

  ConsultationService()
    : _consultationsRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _databaseUrl,
      ).ref('consultations'),
      _repliesRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _databaseUrl,
      ).ref('replies'),
      _notificationsPlugin = FlutterLocalNotificationsPlugin() {
    _initializeNotifications();
  }

  void setupRealtimeListeners({
    Function(List<dynamic>)? onConsultationsUpdated,
    Function(Map<String, dynamic>)? onConsultationUpdated,
    Function(List<dynamic>)? onRepliesUpdated,
  }) {
    _consultationSubscription?.cancel();
    _repliesSubscription?.cancel();

    // Setup consultations listener
    _consultationSubscription = _consultationsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final consultations =
            data.entries.map((entry) {
              final consultation = entry.value as Map<dynamic, dynamic>;
              return {
                'id': consultation['id'],
                'title': consultation['title'],
                'message': consultation['message'],
                'is_answered': consultation['is_answered'] ?? 0,
                'attachment': consultation['attachment'],
                'created_at': consultation['created_at'],
                'user_id': consultation['user_id'],
                'sender_name': consultation['sender_name'],
                'recipient_id': consultation['recipient_id'],
                'recipient_name': consultation['recipient_name'],
                'replies': consultation['replies'] ?? [],
              };
            }).toList();

        onConsultationsUpdated?.call(consultations);
      } else {
        onConsultationsUpdated?.call([]);
      }
    });

    // Setup replies listener
    _repliesSubscription = _repliesRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final allReplies = <dynamic>[];
        data.forEach((consultationId, replies) {
          if (replies is Map) {
            replies.forEach((replyId, reply) {
              allReplies.add({
                'id': reply['id'] ?? replyId,
                'consultation_id': consultationId,
                'message': reply['message'],
                'attachment': reply['attachment'],
                'created_at': reply['created_at'],
                'user_id': reply['user_id'],
                'sender_name': reply['sender_name'],
                'is_read': reply['is_read'] ?? 0,
              });
            });
          }
        });
        onRepliesUpdated?.call(allReplies);
      }
    });
  }

  void dispose() {
    _consultationSubscription?.cancel();
    _repliesSubscription?.cancel();
  }

  Future<List<dynamic>> loadInitialConsultations() async {
    try {
      final session = await SharedPreferences.getInstance();
      final token = session.getString('token') ?? '';

      // Load from API
      final response = await http.get(
        Uri.parse('${Connection.BASE_URL}/consultations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final consultations = data['data'] ?? [];

        // Normalize data structure
        final normalizedConsultations =
            consultations.map((consultation) {
              return {
                'id': consultation['id'],
                'title': consultation['title'] ?? '',
                'message': consultation['message'] ?? '',
                'is_answered': consultation['is_answered'] ?? 0,
                'attachment': consultation['attachment'],
                'created_at': consultation['created_at'] ?? '',
                'user_id': consultation['user_id'],
                'sender_name': consultation['sender_name'] ?? 'Unknown',
                'recipient_id': consultation['recipient_id'],
                'recipient_name': consultation['recipient_name'],
                'replies': consultation['replies'] ?? [],
              };
            }).toList();

        await _syncConsultationsToFirebase(normalizedConsultations);
        return normalizedConsultations;
      }
      throw Exception('Failed to load consultations: ${response.statusCode}');
    } catch (e) {
      // Fallback to Firebase cache if API fails
      log("Error loading from API: $e");

      final snapshot = await _consultationsRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.values.toList();
      }
      return [];
    }
  }

  Future<void> _syncConsultationsToFirebase(List<dynamic> consultations) async {
    try {
      await _consultationsRef.set({}); // Clear existing data

      for (var consultation in consultations) {
        await _consultationsRef
            .child(consultation['id'].toString())
            .set(consultation);
      }
    } catch (e) {
      log("Error syncing to Firebase: $e");
      rethrow;
    }
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
        final Map<String, dynamic> data = jsonDecode(response.body);
        recipients =
            (data['data'] as List)
                .map(
                  (item) => {
                    'id': item['id'],
                    'name': item['name'],
                    'email': item['email'],
                    'role': item['role'],
                  },
                )
                .toList();
      } else {
        throw Exception('Failed to load recipients');
      }
    } catch (e) {
      throw Exception('Error loading recipients: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> createConsultation({
    required String title,
    required String message,
    required String senderId,
    required String senderName,
    String? recipientId,
    File? attachment,
    String? attachmentName,
  }) async {
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
            filename: attachmentName,
            contentType: MediaType('application', 'octet-stream'),
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 201) {
        final consultationData = {
          'id': responseData['data']['id'],
          'title': title,
          'message': message,
          'sender_id': senderId,
          'sender_name': senderName,
          'recipient_id': recipientId,
          'recipient_name':
              recipientId != null
                  ? recipients.firstWhere(
                    (r) => r['id'].toString() == recipientId,
                  )['name']
                  : null,
          'attachment':
              attachment != null
                  ? '${Connection.BASE_URL}/storage/${responseData['data']['attachment']}'
                  : null,
          'created_at': DateTime.now().toIso8601String(),
          'is_answered': false,
          'replies': [],
        };

        await _consultationsRef
            .child(responseData['data']['id'].toString())
            .set(consultationData);

        if (recipientId != null) {
          await _showNotification(
            'Konsultasi Baru',
            'Anda mendapat konsultasi baru dari $senderName',
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating consultation: $e');
      rethrow;
    }
  }

  // Add these methods to your ConsultationService class

  void setupConsultationListener(
    String consultationId,
    Function(Map<String, dynamic>) onConsultationUpdated,
  ) {
    _consultationsRef.child(consultationId).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        onConsultationUpdated(Map<String, dynamic>.from(data));
      }
    });
  }

  void setupReplyListener(
    String consultationId,
    Function(List<dynamic>) onRepliesUpdated,
  ) {
    _repliesRef.child(consultationId).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final replies = data.values.map((item) => item).toList();
        onRepliesUpdated(replies);
      } else {
        onRepliesUpdated([]);
      }
    });
  }

  Future<Map<String, dynamic>> loadConsultation(String consultationId) async {
    try {
      final snapshot = await _consultationsRef.child(consultationId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(
          snapshot.value as Map<dynamic, dynamic>,
        );
      }
      throw Exception('Consultation not found');
    } catch (e) {
      // Fallback to API if Firebase fails
      final session = await SharedPreferences.getInstance();
      final token = session.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${Connection.BASE_URL}/consultations/$consultationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['data'];
      }
      throw Exception('Failed to load consultation: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> loadReplies(String consultationId) async {
    try {
      final snapshot = await _repliesRef.child(consultationId).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.values.map((reply) => reply).toList();
      }
      return [];
    } catch (e) {
      // Fallback to API if Firebase fails
      final session = await SharedPreferences.getInstance();
      final token = session.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(
          '${Connection.BASE_URL}/consultations/$consultationId/replies',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      throw Exception('Failed to load replies: ${response.statusCode}');
    }
  }

  Future<void> sendReply(
    String consultationId,
    String message,
    File? attachment,
    String? attachmentName,
  ) async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';
    final userId = session.getString('user_id');
    final userName = session.getString('user_name') ?? 'Pengguna';

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Connection.BASE_URL}/consultations/reply'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['consultation_id'] = consultationId;
      request.fields['message'] = message;

      if (attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'attachment',
            attachment.path,
            filename: attachmentName,
            contentType: MediaType('application', 'octet-stream'),
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 201) {
        final newReply = {
          'id': responseData['data']['id'],
          'consultation_id': consultationId,
          'message': message,
          'sender_id': userId,
          'sender_name': userName,
          'attachment':
              attachment != null
                  ? '${Connection.BASE_URL}/storage/${responseData['data']['attachment']}'
                  : null,
          'created_at': DateTime.now().toIso8601String(),
          'is_read': false,
        };

        await _repliesRef
            .child(consultationId)
            .child(responseData['data']['id'].toString())
            .set(newReply);
      }
    } catch (e) {
      debugPrint('Error sending reply: $e');
      rethrow;
    }
  }

  Future<void> deleteConsultation(String id) async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      await http.delete(
        Uri.parse('${Connection.BASE_URL}/consultations/$id/delete'),
        headers: {'Authorization': 'Bearer $token'},
      );

      await _consultationsRef.child(id).remove();
      await _repliesRef.child(id).remove();
    } catch (e) {
      debugPrint('Error deleting consultation: $e');
      rethrow;
    }
  }

  Future<void> deleteReply(String consultationId, String replyId) async {
    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    try {
      await http.delete(
        Uri.parse('${Connection.BASE_URL}/consultations/$replyId/reply'),
        headers: {'Authorization': 'Bearer $token'},
      );

      await _repliesRef.child(consultationId).child(replyId).remove();
    } catch (e) {
      debugPrint('Error deleting reply: $e');
      rethrow;
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'consultation_channel',
          'Konsultasi',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  Future<void> viewAttachment(BuildContext context, String url) async {
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
                await _downloadFile(url, context);
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

  Future<void> _downloadFile(String url, BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }

        if (await Permission.manageExternalStorage.isDenied) {
          await Permission.manageExternalStorage.request();
        }

        if (!await Permission.manageExternalStorage.isGranted) {
          throw Exception('Izin penyimpanan diperlukan');
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
      ).showSnackBar(SnackBar(content: Text('File diunduh ke $savePath')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh: ${e.toString()}')),
      );
    }
  }

  String formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      try {
        final format = DateFormat('yyyy-MM-dd HH:mm:ss');
        final dt = format.parse(dateTime);
        return DateFormat('dd MMM yyyy, HH:mm').format(dt);
      } catch (_) {
        final format = DateFormat('yyyy-MM-dd HH:mm');
        final dt = format.parse(dateTime);
        return DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (e) {
      return dateTime;
    }
  }
}
