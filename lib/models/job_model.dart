class JobModel {
  final String id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final String type; // 'Full Time', 'Part Time', 'Internship'
  final String workplaceType; // 'On-site', 'Remote', 'Hybrid'
  final String description;
  final List<String> requirements;
  final List<String> benefits;
  final int applicantCount;
  final String contactEmail;
  final String phone;
  final String userId;
  final String posterName;
  final String imageUrl;
  final DateTime? createdAt;

  JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    this.type = 'Full Time',
    this.workplaceType = 'On-site',
    required this.description,
    this.requirements = const [
      'Proven experience as a UI/UX Designer',
      'Strong portfolio of design projects',
      'Proficiency in Figma, Adobe XD, or Sketch',
      'Good understanding of user-centered design',
    ],
    this.benefits = const [
      'Health Insurance',
      'Flexible Hours',
      'Career Growth',
      'Remote Options',
    ],
    this.applicantCount = 23,
    required this.contactEmail,
    this.phone = '',
    required this.userId,
    required this.posterName,
    this.createdAt,
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? dt;
    final raw = map['createdAt'];
    if (raw is DateTime) {
      dt = raw;
    } else if (raw is String) {
      dt = DateTime.tryParse(raw);
    }

    List<String> reqs = map['requirements'] is List
        ? List<String>.from(map['requirements'].map((e) => e.toString()))
        : [];
    List<String> benfs = map['benefits'] is List
        ? List<String>.from(map['benefits'].map((e) => e.toString()))
        : [];

    return JobModel(
      id: id,
      title: map['title']?.toString() ?? '',
      company: map['company']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      salary: map['salary']?.toString() ?? '',
      type: map['type']?.toString() ?? 'Full Time',
      workplaceType: map['workplaceType']?.toString() ?? 'On-site',
      description: map['description']?.toString() ?? '',
      requirements: reqs.isEmpty
          ? [
              'Proven experience in relevant field',
              'Strong problem solving skills',
              'Good communication and teamwork',
            ]
          : reqs,
      benefits: benfs.isEmpty
          ? ['Health Insurance', 'Flexible Hours', 'Career Growth', 'Remote Options']
          : benfs,
      applicantCount: (map['applicantCount'] as num?)?.toInt() ?? 12,
      contactEmail: map['contactEmail']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      posterName: map['posterName']?.toString() ?? 'Recruiter',
      imageUrl: map['imageUrl']?.toString() ?? '',
      createdAt: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'salary': salary,
      'imageUrl': imageUrl,
      'type': type,
      'workplaceType': workplaceType,
      'description': description,
      'requirements': requirements,
      'benefits': benefits,
      'applicantCount': applicantCount,
      'contactEmail': contactEmail,
      'phone': phone,
      'userId': userId,
      'posterName': posterName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
