class PublicChatMessage {
  final String text;
  final String senderName;
  final String senderRole;
  final String time;
  final bool isOfficer;

  PublicChatMessage({
    required this.text,
    required this.senderName,
    required this.senderRole,
    required this.time,
    required this.isOfficer,
  });
}
