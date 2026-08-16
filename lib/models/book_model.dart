class BookModel {
  final String id;
  final String title;
  final String author;
  final double price;
  final double originalPrice;
  final String condition; // 'New', 'Good', 'Midlevel'
  final String phone;
  final String userId;
  final String sellerName;
  final String imageUrl;
  final String description;
  final double rating;
  final int reviewCount;
  final DateTime? createdAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    this.originalPrice = 0.0,
    required this.condition,
    required this.phone,
    required this.userId,
    required this.sellerName,
    this.imageUrl = '',
    this.description = '',
    this.rating = 4.5,
    this.reviewCount = 12,
    this.createdAt,
  });

  factory BookModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? dt;
    final raw = map['createdAt'];
    if (raw is DateTime) {
      dt = raw;
    } else if (raw is String) {
      dt = DateTime.tryParse(raw);
    }

    return BookModel(
      id: id,
      title: map['title']?.toString() ?? '',
      author: map['author']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble() ?? 0,
      condition: map['condition']?.toString() ?? 'Good',
      phone: map['phone']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      sellerName: map['sellerName']?.toString() ?? 'Student',
      imageUrl: map['imageUrl']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 10,
      createdAt: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'price': price,
      'originalPrice': originalPrice,
      'condition': condition,
      'phone': phone,
      'userId': userId,
      'sellerName': sellerName,
      'imageUrl': imageUrl,
      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
