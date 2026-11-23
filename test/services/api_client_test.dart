import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jame/services/api_client.dart';

void main() {
  test('test_api_client_uses_configured_base_url', () async {
    late Uri requestUri;
    final client = ApiClient(
      baseUri: Uri.parse('https://api.example.test/v2/'),
      isWeb: true,
      httpClient: MockClient((request) async {
        requestUri = request.url;
        return http.Response('{"status":"ok"}', 200);
      }),
    );

    await client.getJson(
      'auth/session',
      queryParameters: {'include': 'profile data'},
    );

    expect(requestUri.origin, 'https://api.example.test');
    expect(requestUri.path, '/v2/auth/session');
    expect(requestUri.queryParameters['include'], 'profile data');
  });

  test('test_api_client_preserves_server_error', () async {
    final client = ApiClient(
      baseUri: Uri.parse('https://api.example.test/api/v1'),
      isWeb: true,
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': {
              'code': 'invalid_credentials',
              'message': 'Email or password is incorrect.',
            },
          }),
          401,
        ),
      ),
    );

    await expectLater(
      client.getJson('auth/session'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.code, 'code', 'invalid_credentials')
            .having(
              (error) => error.message,
              'message',
              'Email or password is incorrect.',
            ),
      ),
    );
  });
}
