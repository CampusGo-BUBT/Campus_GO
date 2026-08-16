class TutorModel {
  final String id;
  final String jobId;
  final String title;
  final String tutoringType;
  final String location;
  final String subLocation;
  final String medium;
  final String studentClass;
  final String preferredTutor;
  final String subject;
  final String daysPerWeek;
  final String salary;
  final double hourlyRate;
  final String requirements;
  final String phone;
  final String userId;
  final String posterName;
  final DateTime? postedAt;
  final List<String> applicants;

  TutorModel({
    required this.id,
    required this.jobId,
    required this.title,
    required this.tutoringType,
    required this.location,
    required this.subLocation,
    required this.medium,
    required this.studentClass,
    required this.preferredTutor,
    required this.subject,
    required this.daysPerWeek,
    required this.salary,
    required this.hourlyRate,
    required this.requirements,
    required this.phone,
    required this.userId,
    required this.posterName,
    this.postedAt,
    this.applicants = const [],
  });

  factory TutorModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? dt;
    final raw = map['postedAt'] ?? map['createdAt'];
    if (raw is DateTime) {
      dt = raw;
    } else if (raw is String) {
      dt = DateTime.tryParse(raw);
    }

    return TutorModel(
      id: id,
      jobId: map['jobId']?.toString() ?? '544${id.substring(0, id.length.clamp(0, 3))}1',
      title: map['title']?.toString() ?? 'Tutor Needed For ${map['subject'] ?? 'Students'}',
      tutoringType: map['tutoringType']?.toString() ?? 'Home Tutoring',
      location: map['location']?.toString() ?? 'Mirpur-2, Dhaka',
      subLocation: map['subLocation']?.toString() ?? 'Near Campus Area',
      medium: map['medium']?.toString() ?? 'English Version',
      studentClass: map['studentClass']?.toString() ?? 'Class 6',
      preferredTutor: map['preferredTutor']?.toString() ?? 'Any',
      subject: map['subject']?.toString() ?? 'ALL',
      daysPerWeek: map['daysPerWeek']?.toString() ?? '4 Days/Week',
      salary: map['salary']?.toString() ??
          (map['hourlyRate'] != null
              ? '\u09F3${(map['hourlyRate'] as num).toInt()}/Month'
              : '6,000 Tk/Month'),
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 6000,
      requirements: map['requirements']?.toString() ??
          'Looking for an experienced and punctual tutor who has great knowledge of ${map['subject'] ?? 'the subject'}. Daily 2 hours lesson requested.',
      phone: map['phone']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      posterName: map['posterName']?.toString() ?? map['name']?.toString() ?? 'Student_name',
      postedAt: dt,
      applicants: map['applicants'] is List
          ? map['applicants'].map((e) => e.toString()).toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'title': title,
      'tutoringType': tutoringType,
      'location': location,
      'subLocation': subLocation,
      'medium': medium,
      'studentClass': studentClass,
      'preferredTutor': preferredTutor,
      'subject': subject,
      'daysPerWeek': daysPerWeek,
      'salary': salary,
      'hourlyRate': hourlyRate,
      'requirements': requirements,
      'phone': phone,
      'userId': userId,
      'posterName': posterName,
      'postedAt': postedAt?.toIso8601String(),
      'applicants': applicants,
    };
  }
}
