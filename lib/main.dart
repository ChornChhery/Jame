// FILE: lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'services/jame_api.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'services/jame_repository.dart';
import 'routes.dart';
import 'core/theme.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Thai locale
  await initializeDateFormatting('th_TH', null);

  final api = JameApi();
  runApp(MyApp(api: api));
}

class MyApp extends StatelessWidget {
  MyApp({required this.api});

  final JameApi api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api: api)),
        ChangeNotifierProvider(
          create: (_) => AppProvider(repository: JameRepository(api: api)),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer2<AuthProvider, SettingsProvider>(
        builder: (context, auth, settings, child) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            locale: Locale(settings.language),
            initialRoute: auth.isAuthenticated
                ? AppConstants.dashboardRoute
                : AppConstants.loginRoute,
            onGenerateRoute: AppRoutes.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
