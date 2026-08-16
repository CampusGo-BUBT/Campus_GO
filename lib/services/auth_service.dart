import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_client.dart';
import 'notification_service.dart';

/// Auth flow:
///   register -> backend creates the Firebase account + Firestore profile,
///               then we sign in with FirebaseAuth so `currentUser.uid` works.
///   login    -> backend validates via Firebase, then FirebaseAuth session.
/// All other API calls send the Firebase ID token through [ApiClient].
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  String? get firebaseUid => _auth.currentUser?.uid;

  Map<String, dynamic>? profile;
  String? _userType;

  Future<String?> registerStudent({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String university,
  }) async {
    if (studentId.length != 11) {
      return 'Student ID ঠিক ১১ ডিজিটের হতে হবে';
    }
    return _register(
      body: {
        'name': name,
        'email': email,
        'password': password,
        'userType': 'student',
        'studentId': studentId,
        'university': university,
      },
      email: email,
      password: password,
    );
  }

  Future<String?> registerGuardian({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    return _register(
      body: {
        'name': name,
        'email': email,
        'password': password,
        'userType': 'guardian',
        'phone': phone,
      },
      email: email,
      password: password,
    );
  }

  Future<String?> _register({
    required Map<String, dynamic> body,
    required String email,
    required String password,
  }) async {
    try {
      await ApiClient.instance.post('/auth/register/', body: body);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await loadProfile();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  // Login goes through the backend (validates + ensures the users doc exists),
  // then hydrates the Firebase Auth session so uid-based screens keep working.
  Future<String?> login(String email, String password) async {
    try {
      await ApiClient.instance.post('/auth/login/', body: {
        'email': email.trim(),
        'password': password,
      });
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      await loadProfile();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String> getUserType() async {
    if (currentUser == null) return 'student';
    try {
      final data = await ApiClient.instance.get('/auth/user/');
      final map = Map<String, dynamic>.from(data as Map);
      _userType = map['userType']?.toString() ?? 'student';
      profile = map;
      return _userType!;
    } catch (_) {
      return _userType ?? 'student';
    }
  }

  Future<void> loadProfile() async {
    if (currentUser == null) return;
    try {
      final data = await ApiClient.instance.get('/auth/user/');
      profile = Map<String, dynamic>.from(data as Map);
      _userType = profile?['userType']?.toString() ?? 'student';
    } catch (_) {
      profile = null;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await NotificationService.clearToken();
    profile = null;
    _userType = null;
    await _auth.signOut();
    notifyListeners();
  }
}
