class FeedPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorHandle;
  final String? authorPhotoUrl;
  final String caption;
  final String? imageUrl;
  final DateTime? createdAt;
  final List<String> likedBy;
  final List<String> savedBy;
  final int commentCount;
  final String type;

  FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorHandle,
    this.authorPhotoUrl,
    required this.caption,
    this.imageUrl,
    this.createdAt,
    this.likedBy = const [],
    this.savedBy = const [],
    this.commentCount = 0,
    this.type = 'general',
  });

  factory FeedPost.fromMap(Map<String, dynamic> data, String id) {
    DateTime? dt;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is DateTime) {
        dt = data['createdAt'] as DateTime;
      } else {
        dt = DateTime.tryParse(data['createdAt'].toString());
      }
    }
    return FeedPost(
      id: id,
      authorId: data['authorId']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? 'Student',
      authorHandle: data['authorHandle']?.toString() ?? '@student',
      authorPhotoUrl: data['authorPhotoUrl']?.toString(),
      caption: data['caption']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString(),
      createdAt: dt,
      likedBy: _stringList(data['likedBy']),
      savedBy: _stringList(data['savedBy']),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      type: data['type']?.toString() ?? 'general',
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }
}
