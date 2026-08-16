import '../models/notice_model.dart';
import 'api_client.dart';

class NoticeService {
  static final _api = ApiClient.instance;

  Stream<List<NoticeModel>> getNotices() => pollStream(() => _fetch(''));

  Stream<List<NoticeModel>> getNoticesByCategory(String category) =>
      pollStream(() => _fetch('?category=$category'));

  Future<void> addNotice(NoticeModel notice) async {
    final fields = notice.toMap()
      ..remove('id')
      ..remove('createdAt')
      ..remove('userId')
      ..remove('authorName')
      ..remove('attachmentUrl');
    await _api.post('/notices/', body: fields);
  }

  Future<void> deleteNotice(String noticeId) async {
    await _api.delete('/notices/$noticeId/');
  }

  Future<List<NoticeModel>> _fetch(String query) async {
    final data = await _api.get('/notices/$query');
    if (data is! List) return const [];
    return data
        .map((e) => NoticeModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()))
        .toList();
  }
}
