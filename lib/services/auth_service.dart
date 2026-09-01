import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_client.dart';
import 'notification_service.dart';
import '../main.dart' show navigatorKey;
import '../screens/auth/login_screen.dart';

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
      NotificationService.init();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please check your connection and try again.';
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
      // Admin static password "1" maps to a 6-char Firebase password.
      final fbPassword = email.trim() == 'admin@gmail.com' ? '111111' : password;
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: fbPassword);
      await loadProfile();
      NotificationService.init();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please check your connection and try again.';
    }
  }

  Future<String> getUserType() async {
    if (currentUser == null) return 'student';
    try {
      final data = await ApiClient.instance.get('/auth/user/');
      if (data == null) return _userType ?? 'student';
      final map = Map<String, dynamic>.from(data as Map);
      _userType = map['userType']?.toString() ?? 'student';
      profile = map;
      return _userType!;
    } catch (_) {
      // If API fails, try loaded profile, otherwise default to student
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

  /// Sync the current Firebase user's profile into MongoDB (called after any
  /// Google/third-party sign-in). Keeps `users` in MongoDB in sync with Auth.
  Future<void> syncUserToMongo() async {
    if (currentUser == null) return;
    try {
      final data = await ApiClient.instance.post('/auth/google/');
      profile = Map<String, dynamic>.from(data as Map);
      _userType = profile?['userType']?.toString() ?? 'student';
    } catch (_) {
      // non-fatal: profile will remain null until next loadProfile()
    }
    notifyListeners();
  }

  /// Sign in with Google, then sync the MongoDB profile.
  /// Returns an error message on failure, or null on success.
  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return 'Google sign-in cancelled.';
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      await syncUserToMongo();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Google sign-in failed. Please try again.';
    }
  }

  Future<void> logout() async {
    await NotificationService.clearToken();
    profile = null;
    _userType = null;
    await _auth.signOut();
    notifyListeners();
  }

  /// Logs out and resets the app navigation back to the login screen, so the
  /// user always lands on a clean auth entry point regardless of how deep the
  /// navigator stack is.
  Future<void> logoutAndGoToLogin() async {
    await logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
