class ChatModel {
  final String id;
  final String message;
  final String senderId;
  final String senderName;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime dt = DateTime.now();
    final raw = map['createdAt'];
    if (raw is DateTime) {
      dt = raw;
    } else if (raw is String) {
      dt = DateTime.tryParse(raw) ?? DateTime.now();
    } else if (raw is num) {
      dt = DateTime.fromMillisecondsSinceEpoch((raw * 1000).round());
    }
    return ChatModel(
      id: id,
      message: map['message']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? 'Student',
      createdAt: dt,
    );
  }
}
