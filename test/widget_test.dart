// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jame/providers/auth_provider.dart';
import 'package:jame/providers/settings_provider.dart';
import 'package:jame/screens/auth_screens.dart';

void main() {
  testWidgets('LoginScreen renders signup link', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Sign Up'), findsOneWidget);
  });
}
