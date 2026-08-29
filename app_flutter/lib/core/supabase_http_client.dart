import 'dart:async';

import 'package:http/http.dart' as http;

/// Prevents Supabase requests from leaving authentication screens waiting
/// indefinitely when the provider or the current network is unavailable.
class SupabaseHttpClient extends http.BaseClient {
  SupabaseHttpClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 15),
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await _inner.send(request).timeout(timeout);
    } on TimeoutException {
      throw http.ClientException('Connection timed out.', request.url);
    }
  }

  @override
  void close() => _inner.close();
}
