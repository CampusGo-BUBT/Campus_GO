class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastSenderId;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastSenderId,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime dt = DateTime.now();
    final raw = map['lastMessageTime'] ?? map['createdAt'];
    if (raw is DateTime) {
      dt = raw;
    } else if (raw is String) {
      dt = DateTime.tryParse(raw) ?? DateTime.now();
    } else if (raw is num) {
      dt = DateTime.fromMillisecondsSinceEpoch((raw * 1000).round());
    }
    return ConversationModel(
      id: id,
      participants: (map['participants'] is List)
          ? List<String>.from(map['participants'].map((e) => e.toString()))
          : const [],
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageTime: dt,
      lastSenderId: map['lastSenderId']?.toString() ?? '',
    );
  }

  String otherUserId(String myUid) {
    return participants.firstWhere((id) => id != myUid, orElse: () => '');
  }
}
