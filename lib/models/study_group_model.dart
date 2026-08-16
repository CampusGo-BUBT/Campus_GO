class StudyGroupModel {
  final String id;
  final String name;
  final String subject;
  final String description;
  final String location;
  final String time;
  final int maxMembers;
  final List<String> members;
  final String creatorId;
  final String creatorName;

  StudyGroupModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.description,
    required this.location,
    required this.time,
    required this.maxMembers,
    required this.members,
    required this.creatorId,
    required this.creatorName,
  });

  factory StudyGroupModel.fromMap(Map<String, dynamic> data, String id) {
    return StudyGroupModel(
      id: id,
      name: data['name']?.toString() ?? '',
      subject: data['subject']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      time: data['time']?.toString() ?? '',
      maxMembers: (data['maxMembers'] as num?)?.toInt() ?? 5,
      members: data['members'] is List
          ? data['members'].map((e) => e.toString()).toList()
          : const [],
      creatorId: data['creatorId']?.toString() ?? '',
      creatorName: data['creatorName']?.toString() ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subject': subject,
      'description': description,
      'location': location,
      'time': time,
      'maxMembers': maxMembers,
      'members': members,
      'creatorId': creatorId,
      'creatorName': creatorName,
    };
  }
}
