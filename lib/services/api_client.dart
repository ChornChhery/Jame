import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'api_http_client.dart';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    Uri? baseUri,
    bool? isWeb,
    Future<String?> Function()? accessTokenProvider,
  }) : _httpClient = httpClient ?? createApiHttpClient(),
       _baseUri = _withTrailingSlash(baseUri ?? ApiConfig.baseUri),
       _isWeb = isWeb ?? kIsWeb,
       _accessTokenProvider = accessTokenProvider;

  final http.Client _httpClient;
  final Uri _baseUri;
  final bool _isWeb;
  final Future<String?> Function()? _accessTokenProvider;
  String? _csrfToken;

  bool get isWeb => _isWeb;

  Uri get readinessUri =>
      _baseUri.replace(path: '/ready', query: null, fragment: null);

  static Uri _withTrailingSlash(Uri uri) {
    final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
    return uri.replace(path: path, query: null, fragment: null);
  }

  Uri _buildUri(String path, Map<String, String> queryParameters) {
    final parsed = Uri.parse(path);
    final uri = parsed.hasScheme
        ? parsed
        : _baseUri.resolve(path.startsWith('/') ? path.substring(1) : path);
    return uri.replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  void setCsrfToken(String? token) {
    _csrfToken = token;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String> queryParameters = const {},
  }) async {
    final response = await _send('GET', path, queryParameters: queryParameters);
    return _decodeJson(response);
  }

  Future<List<Map<String, dynamic>>> getJsonList(
    String path, {
    Map<String, String> queryParameters = const {},
  }) async {
    final response = await _send('GET', path, queryParameters: queryParameters);
    return _decodeJsonList(response);
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    final response = await _send('POST', path, body: body);
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    final response = await _send('PUT', path, body: body);
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> patchJson(String path, {Object? body}) async {
    final response = await _send('PATCH', path, body: body);
    return _decodeJson(response);
  }

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String> queryParameters = const {},
    Object? body,
  }) async {
    final request = http.Request(method, _buildUri(path, queryParameters))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    if (_csrfToken != null && method != 'GET') {
      request.headers['X-CSRF-Token'] = _csrfToken!;
    }
    if (!_isWeb && _accessTokenProvider != null) {
      final token = await _accessTokenProvider();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final response = await http.Response.fromStream(
        await _httpClient.send(request),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _apiException(response);
      }
      return response;
    } on http.ClientException {
      throw const ApiException(
        statusCode: 0,
        code: 'network_error',
        message: 'Unable to reach the Jame server.',
      );
    }
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.trim().isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw const ApiException(
        statusCode: 0,
        code: 'invalid_response',
        message: 'The Jame server returned an invalid response.',
      );
    }
    throw const ApiException(
      statusCode: 0,
      code: 'invalid_response',
      message: 'The Jame server returned an unexpected response.',
    );
  }

  List<Map<String, dynamic>> _decodeJsonList(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is List && decoded.every((item) => item is Map<String, dynamic>)) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } on FormatException {
      throw const ApiException(
        statusCode: 0,
        code: 'invalid_response',
        message: 'The Jame server returned an invalid response.',
      );
    }
    throw const ApiException(
      statusCode: 0,
      code: 'invalid_response',
      message: 'The Jame server returned an unexpected response.',
    );
  }

  ApiException _apiException(http.Response response) {
    var code = 'request_failed';
    var message = 'The request failed (${response.statusCode}).';
    try {
      final decoded = jsonDecode(response.body);
      final detail = decoded is Map<String, dynamic> ? decoded['detail'] : null;
      if (detail is Map<String, dynamic>) {
        code = detail['code'] as String? ?? code;
        message = detail['message'] as String? ?? message;
      } else if (detail is String && detail.isNotEmpty) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        final firstError = detail.first;
        if (firstError is Map<String, dynamic>) {
          message = firstError['msg'] as String? ?? message;
        }
      }
    } on FormatException {
      // Keep the status-based message for non-JSON proxy and server errors.
    }
    return ApiException(
      statusCode: response.statusCode,
      code: code,
      message: message,
    );
  }
}
