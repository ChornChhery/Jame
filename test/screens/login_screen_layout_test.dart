import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:jame/providers/auth_provider.dart';
import 'package:jame/providers/settings_provider.dart';
import 'package:jame/services/api_client.dart';
import 'package:jame/services/jame_api.dart';
import 'package:jame/screens/auth_screens.dart';

void main() {
  testWidgets('login form remains usable on a 600px-tall screen', (
    tester,
  ) async {
    final api = JameApi(
      client: ApiClient(
        baseUri: Uri.parse('https://api.example.test/api/v1'),
        isWeb: true,
        httpClient: MockClient((request) async => http.Response('', 401)),
      ),
    );
    tester.view.physicalSize = const Size(1280, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(api: api)),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.pump();
    expect(tester.getRect(find.text('Sign Up')).bottom, lessThanOrEqualTo(600));
    expect(tester.takeException(), isNull);
  });
}
