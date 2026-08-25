import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';

/// Thrown when the backend returns a non-2xx response.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Thrown when there is no authenticated Supabase session to attach.
class ApiAuthException implements Exception {
  final String message;
  ApiAuthException(this.message);

  @override
  String toString() => message;
}

/// Small wrapper around [http.Client] that talks to the Agrifos FastAPI
/// backend, attaching the current Supabase session's JWT as a Bearer token
/// and mapping error responses to [ApiException].
class ApiClient {
  final http.Client _http;

  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  Uri _uri(String path) => Uri.parse('${Env.apiBaseUrl}$path');

  Future<Map<String, String>> _headers() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    if (token == null) {
      throw ApiAuthException(
        'No hay una sesión activa. Inicia sesión de nuevo.',
      );
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = await _headers();
    final response = await _http
        .post(_uri(path), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _decode(response);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final headers = await _headers();
    final uri = _uri(path).replace(queryParameters: query);
    final response = await _http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
    return _decode(response);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = await _headers();
    final response = await _http
        .patch(_uri(path), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _decode(response) as Map<String, dynamic>;
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    String message = 'Error del servidor (${response.statusCode}).';
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {
      // response body wasn't JSON, keep the default message
    }
    throw ApiException(response.statusCode, message);
  }
}
