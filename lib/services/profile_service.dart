import 'api_client.dart';

class ProfileService {
  static final _api = ApiClient.instance;

  Future<Map<String, dynamic>> myListings() async {
    final data = await _api.get('/profile/me/listings/');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> updateProfileFields(
      {String? name, String? university, String? studentId, String? phone}) async {
    final body = <String, dynamic>{
      'name': ?name,
      'university': ?university,
      'studentId': ?studentId,
      'phone': ?phone,
    };
    final data = await _api.patch('/profile/me/', body: body);
    return Map<String, dynamic>.from(data as Map);
  }
}
