class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String category; // 'Important', 'Academic', 'Exams', 'Events'
  final String dateStr;
  final String attachmentName;
  final String attachmentUrl;
  final String userId;
  final String authorName;
  final DateTime? createdAt;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'Important',
    this.dateStr = 'May 20, 2024',
    this.attachmentName = 'Routine.pdf',
    this.attachmentUrl = '',
    required this.userId,
    required this.authorName,
    this.createdAt,
  });

  factory NoticeModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? dt;
    final raw = map['createdAt'];
    if (raw is DateTime) {
      dt = raw;
    } else if (raw is String) {
      dt = DateTime.tryParse(raw);
    }

    return NoticeModel(
      id: id,
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Important',
      dateStr: map['dateStr']?.toString() ?? 'Today',
      attachmentName: map['attachmentName']?.toString() ?? '',
      attachmentUrl: map['attachmentUrl']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? 'Admin',
      createdAt: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'dateStr': dateStr,
      'attachmentName': attachmentName,
      'attachmentUrl': attachmentUrl,
      'userId': userId,
      'authorName': authorName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
