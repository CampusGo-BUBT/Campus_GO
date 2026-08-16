import '../models/job_model.dart';
import 'api_client.dart';

class JobService {
  static final _api = ApiClient.instance;

  Stream<List<JobModel>> getJobs({String query = ''}) =>
      pollStream(() => _fetch(query));

  Future<void> addJob(JobModel job) async {
    final fields = job.toMap()
      ..remove('id')
      ..remove('createdAt')
      ..remove('userId')
      ..remove('posterName')
      ..remove('applicantCount');
    await _api.post('/jobs/', body: fields);
  }

  Future<void> deleteJob(String jobId) async {
    await _api.delete('/jobs/$jobId/');
  }

  // Demo data is seeded server-side (manage.py seed); no-op kept for API parity.
  Future<void> seedJobsIfEmpty() async {}

  Future<List<JobModel>> _fetch(String query) async {
    final uri = query.isEmpty ? '/jobs/' : '/jobs/?search=$query';
    final data = await _api.get(uri);
    if (data is! List) return const [];
    return data
        .map((e) => JobModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()))
        .toList();
  }
}
