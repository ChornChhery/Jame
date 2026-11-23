import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:jame/providers/auth_provider.dart';
import 'package:jame/providers/settings_provider.dart';
import 'package:jame/screens/forgot_password_screen.dart';
import 'package:jame/services/api_client.dart';
import 'package:jame/services/jame_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test_password_reset_screen_uses_email_code', (tester) async {
    final requests = <http.Request>[];
    final provider = AuthProvider(
      api: JameApi(
        client: ApiClient(
          baseUri: Uri.parse('https://api.example.test/api/v1'),
          isWeb: true,
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/api/v1/auth/session') {
              return http.Response('', 401);
            }
            if (request.url.path.endsWith('/password-reset/request')) {
              return http.Response(
                '{"message":"Code sent if account exists"}',
                202,
              );
            }
            return http.Response('{"status":"password_updated"}', 200);
          }),
        ),
      ),
    );
    await provider.initialization;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-email')),
      'owner@gmail.com',
    );
    await tester.tap(find.byKey(const ValueKey('request-reset-code')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('verification-code')), findsOneWidget);
    expect(find.byKey(const ValueKey('reset-username')), findsNothing);
    final request = requests.firstWhere(
      (item) => item.url.path.endsWith('/password-reset/request'),
    );
    expect(jsonDecode(request.body), {'email': 'owner@gmail.com'});
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('verification-code')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password')),
      'NewJamePass456!',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password')),
      'NewJamePass456!',
    );
    final confirmButton = find.byKey(const ValueKey('confirm-password-reset'));
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    final confirmation = requests.firstWhere(
      (item) => item.url.path.endsWith('/password-reset/confirm'),
    );
    expect(jsonDecode(confirmation.body), {
      'email': 'owner@gmail.com',
      'code': '123456',
      'new_password': 'NewJamePass456!',
    });
  });
}
