class HostelModel {
  final String id;
  final String name;
  final String type; // 'Boys', 'Girls', 'Family'
  final String location;
  final double rent;
  final String facilities;
  final List<String> facilitiesList;
  final String phone;
  final String userId;
  final String ownerName;
  final String gender;
  final String imageUrl;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final String distance;
  final String description;
  final DateTime? createdAt;

  HostelModel({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.rent,
    required this.facilities,
    this.facilitiesList = const ['Wifi', 'A/C', 'Study', 'Laundry', 'Parking'],
    required this.phone,
    required this.userId,
    required this.ownerName,
    required this.gender,
    this.imageUrl = '',
    this.images = const [],
    this.rating = 3.7,
    this.reviewCount = 64,
    this.distance = 'Jahar Town - 0.8 km from bubt',
    this.description = 'Clean, secure hostel with backup power, daily mess and a quiet study lounge. 5-min walk to the main bus stop.',
    this.createdAt,
  });

  factory HostelModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? dt;
    final raw = map['createdAt'];
    if (raw is DateTime) {
      dt = raw;
    } else if (raw is String) {
      dt = DateTime.tryParse(raw);
    }

    List<String> parsedFacs = map['facilitiesList'] is List
        ? List<String>.from(map['facilitiesList'].map((e) => e.toString()))
        : [];
    if (parsedFacs.isEmpty && (map['facilities']?.toString() ?? '').isNotEmpty) {
      parsedFacs = map['facilities'].toString().split(',').map((e) => e.trim()).toList();
    }

    List<String> imgs = map['images'] is List
        ? List<String>.from(map['images'].map((e) => e.toString()))
        : [];

    return HostelModel(
      id: id,
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? 'Boys',
      location: map['location']?.toString() ?? '',
      rent: (map['rent'] as num?)?.toDouble() ?? 0,
      facilities: map['facilities']?.toString() ?? '',
      facilitiesList: parsedFacs.isEmpty ? ['Wifi', 'A/C', 'Study', 'Laundry', 'Parking'] : parsedFacs,
      phone: map['phone']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      ownerName: map['ownerName']?.toString() ?? 'Owner',
      gender: map['gender']?.toString() ?? 'Boys',
      imageUrl: map['imageUrl']?.toString() ?? '',
      images: imgs,
      rating: (map['rating'] as num?)?.toDouble() ?? 3.7,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 64,
      distance: map['distance']?.toString() ?? 'Near BUBT',
      description: map['description']?.toString() ?? 'Clean, secure hostel with backup power and study environment.',
      createdAt: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'location': location,
      'rent': rent,
      'facilities': facilities,
      'facilitiesList': facilitiesList,
      'phone': phone,
      'userId': userId,
      'ownerName': ownerName,
      'gender': gender,
      'imageUrl': imageUrl,
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'distance': distance,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
