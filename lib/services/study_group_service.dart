import '../models/study_group_model.dart';
import 'api_client.dart';

class StudyGroupService {
  static final _api = ApiClient.instance;

  Stream<List<StudyGroupModel>> getGroups() => pollStream(() => _fetch(''));

  Future<void> createGroup(StudyGroupModel group) async {
    final fields = group.toMap()
      ..remove('id')
      ..remove('members')
      ..remove('creatorId')
      ..remove('creatorName');
    await _api.post('/study-groups/', body: fields);
  }

  Future<void> joinGroup(String groupId) async {
    await _api.post('/study-groups/$groupId/join/');
  }

  Future<void> leaveGroup(String groupId) async {
    await _api.post('/study-groups/$groupId/leave/');
  }

  Future<List<StudyGroupModel>> _fetch(String query) async {
    final data = await _api.get('/study-groups/$query');
    if (data is! List) return const [];
    return data
        .map((e) => StudyGroupModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()))
        .toList();
  }
}
