/// Backend API configuration.
///
/// The app talks to the CampusGo Django gateway (hosted on Render), which talks
/// to MongoDB + Firebase. Override the URL at build time for local dev with:
///   flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
class ApiConfig {
  ApiConfig._();

  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    return 'https://campusgo-backend-cn0o.onrender.com/api';
  }
}
