import 'api_client.dart';

class AdminService {
  static final _api = ApiClient.instance;

  Future<Map<String, dynamic>> dashboard() async {
    final data = await _api.get('/admin/dashboard/');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<dynamic>> pendingItems() async {
    final data = await _api.get('/admin/items/');
    return data is List ? data : [];
  }

  Future<List<dynamic>> listItems(String kind, {String? status}) async {
    final q = status == null ? '?kind=$kind' : '?kind=$kind&status=$status';
    final data = await _api.get('/admin/items/$q');
    return data is List ? data : [];
  }

  Future<List<dynamic>> users() async {
    final data = await _api.get('/admin/users/');
    return data is List ? data : [];
  }

  Future<void> moderate(String kind, String id, String action) async {
    await _api.post('/admin/moderate/$kind/$id/$action/');
  }

  Future<void> banUser(String uid) async {
    await _api.post('/admin/users/$uid/ban/');
  }

  Future<void> unbanUser(String uid) async {
    await _api.post('/admin/users/$uid/unban/');
  }
}
