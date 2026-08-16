import '../models/tutor_model.dart';
import 'api_client.dart';

class TutorService {
  static final _api = ApiClient.instance;

  Stream<List<TutorModel>> getTutors() => pollStream(() => _fetch(''));

  Future<void> addTutor(TutorModel tutor) async {
    final fields = tutor.toMap()
      ..remove('id')
      ..remove('postedAt')
      ..remove('userId')
      ..remove('posterName')
      ..remove('applicants')
      ..remove('jobId');
    await _api.post('/tutors/', body: fields);
  }

  Future<void> applyForTuition({
    required String tuitionId,
    required String note,
    required String phone,
  }) async {
    await _api.post('/tutors/$tuitionId/apply/',
        body: {'note': note, 'phone': phone});
  }

  Stream<List<TutorModel>> searchTutors(String query) {
    final q = query.trim();
    return pollStream(() => _fetch(q.isEmpty ? '' : '?search=$q'));
  }

  Future<List<TutorModel>> _fetch(String query) async {
    final data = await _api.get('/tutors/$query');
    if (data is! List) return const [];
    return data
        .map((e) => TutorModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()))
        .toList();
  }
}
