import 'api_client.dart';

/// User profile lookups routed through the backend (no direct Firestore reads).
///
/// The backend exposes `GET /api/users/{uid}/` which returns the Firestore
/// `users/{uid}` document (name, email, userType, university, department,
/// phone, photoUrl...). Screens use [getUser] so all data access stays behind
/// the API gateway.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  /// Fetch a user's public profile. Returns an empty map on failure so callers
  /// can fall back to their existing defaults without crashing.
  Future<Map<String, dynamic>> getUser(String uid) async {
    if (uid.trim().isEmpty) return const {};
    try {
      final data = await ApiClient.instance.get('/users/$uid/');
      if (data is Map) return Map<String, dynamic>.from(data);
      return const {};
    } catch (_) {
      return const {};
    }
  }
}
