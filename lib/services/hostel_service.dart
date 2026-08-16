import 'dart:io';
import '../models/hostel_model.dart';
import 'api_client.dart';

class HostelService {
  static final _api = ApiClient.instance;

  Stream<List<HostelModel>> getHostels() => pollStream(() => _fetch(''));

  Stream<List<HostelModel>> getHostelsByGender(String gender) =>
      pollStream(() => _fetch('?gender=$gender'));

  Future<void> addHostel(HostelModel hostel, {File? image}) async {
    final fields = hostel.toMap()
      ..remove('id')
      ..remove('createdAt')
      ..remove('userId')
      ..remove('ownerName')
      ..remove('imageUrl')
      ..remove('images')
      ..remove('rating')
      ..remove('reviewCount');
    if (image != null) {
      await _api.postMultipart('/hostels/', fields: fields, files: {'image': image});
    } else {
      await _api.post('/hostels/', body: fields);
    }
  }

  Future<void> deleteHostel(String hostelId) async {
    await _api.delete('/hostels/$hostelId/');
  }

  Future<List<HostelModel>> _fetch(String query) async {
    final data = await _api.get('/hostels/$query');
    if (data is! List) return const [];
    return data
        .map((e) => HostelModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()))
        .toList();
  }
}
