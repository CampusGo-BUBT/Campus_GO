import 'dart:io' show Platform;

/// Backend API configuration.
///
/// The app talks to the CampusGo Django gateway, which talks to Firebase.
/// Override the URL at build time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
class ApiConfig {
  ApiConfig._();

  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    // Physical Android device reaches the host PC via its LAN IP.
    // (The Android *emulator* would use 10.0.2.2 instead.)
    if (Platform.isAndroid) return 'http://192.168.0.108:8000/api';
    return 'http://localhost:8000/api';
  }
}
