import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Thrown for any non-2xx API response (message = backend error detail).
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, {this.statusCode = 0});

  @override
  String toString() => message;
}

/// Thin HTTP client for the CampusGo backend.
///
/// Adds the user's current Firebase ID token as `Authorization: Bearer ...`
/// so the backend can verify it against Firebase.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Future<String?> _token() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Map<String, String> _headers({bool json = true, String? token}) {
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) {
    final base = ApiConfig.baseUrl;
    final clean = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$clean');
  }

  dynamic _decode(http.Response res) {
    dynamic data;
    try {
      if (res.body.isNotEmpty) data = jsonDecode(res.body);
    } catch (_) {
      data = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    var message = 'Request failed (${res.statusCode})';
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        message = detail.join(', ');
      } else if (data['error'] is String) {
        message = data['error'] as String;
      } else if (data['message'] is String) {
        message = data['message'] as String;
      } else {
        final parts = <String>[];
        data.forEach((k, v) {
          if (k == 'detail' || k == 'error' || k == 'message') return;
          parts.add('$k: $v');
        });
        if (parts.isNotEmpty) message = parts.join(', ');
      }
    }
    throw ApiException(message, statusCode: res.statusCode);
  }

  Future<dynamic> get(String path) async {
    final token = await _token();
    final res = await http.get(_uri(path), headers: _headers(token: token));
    return _decode(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final token = await _token();
    final res = await http.post(
      _uri(path),
      headers: _headers(token: token),
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final token = await _token();
    final res = await http.patch(
      _uri(path),
      headers: _headers(token: token),
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final token = await _token();
    final res = await http.delete(_uri(path), headers: _headers(token: token));
    return _decode(res);
  }

  Future<dynamic> postMultipart(
    String path, {
    Map<String, dynamic>? fields,
    Map<String, File>? files,
  }) {
    return _sendMultipart('POST', path, fields: fields, files: files);
  }

  Future<dynamic> patchMultipart(
    String path, {
    Map<String, dynamic>? fields,
    Map<String, File>? files,
  }) {
    return _sendMultipart('PATCH', path, fields: fields, files: files);
  }

  Future<dynamic> _sendMultipart(
    String method,
    String path, {
    Map<String, dynamic>? fields,
    Map<String, File>? files,
  }) async {
    final token = await _token();
    final request = http.MultipartRequest(method, _uri(path));
    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    fields?.forEach((k, v) {
      request.fields[k] = v?.toString() ?? '';
    });
    files?.forEach((k, file) {
      request.files.add(
        http.MultipartFile.fromBytes(
          k,
          file.readAsBytesSync(),
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      );
    });
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }
}

/// Turns a one-shot fetch into a stream that re-fetches on an interval.
///
/// Errors are swallowed so the UI keeps its last good data instead of crashing.
Stream<List<T>> pollStream<T>(
  Future<List<T>> Function() fetch, {
  Duration interval = const Duration(seconds: 15),
}) {
  final controller = StreamController<List<T>>();
  Future<void> tick() async {
    try {
      final data = await fetch();
      if (!controller.isClosed) controller.add(data);
    } catch (_) {
      // keep last emitted data on transient errors
    }
  }

  tick();
  final timer = Timer.periodic(interval, (_) => tick());
  controller.onCancel = () {
    timer.cancel();
    controller.close();
  };
  return controller.stream;
}
