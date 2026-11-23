import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jame/providers/auth_provider.dart';
import 'package:jame/services/api_client.dart';
import 'package:jame/services/jame_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('test_auth_provider_restores_session_from_api', () async {
    SharedPreferences.setMockInitialValues({});
    final api = JameApi(
      client: ApiClient(
        baseUri: Uri.parse('https://api.example.test/api/v1'),
        isWeb: true,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/session');
          return http.Response(
            jsonEncode({
              'user': {
                'id': 42,
                'username': 'owner',
                'email': 'owner@gmail.com',
                'first_name': 'Shop',
                'last_name': 'Owner',
                'shop_name': 'Jame Shop',
                'shop_address': null,
                'shop_phone': null,
                'shop_email': null,
                'currency': 'THB',
                'payment_qr': null,
                'profile_image': null,
                'created_at': '2026-01-01T00:00:00Z',
                'updated_at': '2026-01-01T00:00:00Z',
              },
              'csrf_token': 'csrf-token',
            }),
            200,
          );
        }),
      ),
    );
    final provider = AuthProvider(api: api);

    await provider.initialization;

    expect(provider.isAuthenticated, isTrue);
    expect(provider.currentUser?.email, 'owner@gmail.com');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('user_id'), isNull);
  });

  test('test_api_failure_is_reported_to_auth_provider', () async {
    final api = JameApi(
      client: ApiClient(
        baseUri: Uri.parse('https://api.example.test/api/v1'),
        isWeb: true,
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/auth/session') {
            return http.Response('', 401);
          }
          return http.Response(
            jsonEncode({
              'detail': {
                'code': 'recovery_unavailable',
                'message': 'Password recovery is temporarily unavailable.',
              },
            }),
            503,
          );
        }),
      ),
    );
    final provider = AuthProvider(api: api);
    await provider.initialization;

    final error = await provider.signup(
      username: 'owner',
      email: 'owner@gmail.com',
      password: 'JamePass123!',
      firstName: 'Shop',
      lastName: 'Owner',
      shopName: 'Jame Shop',
    );

    expect(error, 'Password recovery is temporarily unavailable.');
    expect(provider.error, 'Password recovery is temporarily unavailable.');
    expect(provider.isAuthenticated, isFalse);
  });

  test('test_auth_connectivity_check_uses_api_readiness', () async {
    var readinessRequested = false;
    final api = JameApi(
      client: ApiClient(
        baseUri: Uri.parse('https://api.example.test/api/v1'),
        isWeb: true,
        httpClient: MockClient((request) async {
          if (request.url.path == '/ready') {
            readinessRequested = true;
            return http.Response('{"status":"ok"}', 200);
          }
          return http.Response('', 401);
        }),
      ),
    );
    final provider = AuthProvider(api: api);
    await provider.initialization;

    expect(await provider.testServerConnection(), isTrue);
    expect(readinessRequested, isTrue);
  });
}
