import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jame/models/user.dart';
import 'package:jame/services/api_client.dart';
import 'package:jame/services/jame_api.dart';

void main() {
  test('login maps only the public user profile', () async {
    final api = JameApi(
      client: ApiClient(
        baseUri: Uri.parse('https://api.example.test/api/v1'),
        isWeb: true,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/login');
          expect(jsonDecode(request.body)['password'], 'JamePass123!');
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
              'access_token': null,
              'token_type': null,
              'expires_in': 3600,
            }),
            200,
          );
        }),
      ),
    );

    final user = await api.login(
      email: 'owner@gmail.com',
      password: 'JamePass123!',
    );

    expect(user, isA<User>());
    expect(user.id, 42);
    expect(user.email, 'owner@gmail.com');
    expect(user.toMap().containsKey('password'), isFalse);
  });
}
