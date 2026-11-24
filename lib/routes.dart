// FILE: lib/routes.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screens.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/receipt_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/products_screen.dart' as products;
import 'screens/scanner_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/payment_history_screen.dart' as payment_history;
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'core/constants.dart';
import 'core/translations.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Public routes (no authentication required)
      case AppConstants.loginRoute:
        return MaterialPageRoute(
          builder: (context) => Consumer2<AuthProvider, SettingsProvider>(
            builder: (context, auth, _, child) {
              // Redirect to dashboard if already logged in
              if (auth.isAuthenticated) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
                });
              }
              return LoginScreen();
            },
          ),
        );
      
      case '/forgot-password':
        return MaterialPageRoute(
          builder: (context) => Consumer<SettingsProvider>(
            builder: (context, _, child) => ForgotPasswordScreen(),
          ),
        );
      
      case AppConstants.signupRoute:
        return MaterialPageRoute(
          builder: (context) => Consumer2<AuthProvider, SettingsProvider>(
            builder: (context, auth, _, child) {
              // Redirect to dashboard if already logged in
              if (auth.isAuthenticated) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
                });
              }
              return SignupScreen();
            },
          ),
        );
      
      // Protected routes (authentication required)
      case AppConstants.dashboardRoute:
        return MaterialPageRoute(
          builder: (context) => _buildProtectedRoute(
            context, 
            () => DashboardScreen(),
            AppTranslations.t('ui_dashboard'),
          ),
        );
      
      case AppConstants.productsRoute:
        return MaterialPageRoute(
          builder: (context) => _buildProtectedRoute(
            context,
            () => products.ProductsScreen(arguments: settings.arguments as Map<String, dynamic>?),
            AppTranslations.t('ui_products'),
          ),
        );
      
      case AppConstants.scannerRoute:
        return MaterialPageRoute(
          builder: (context) => _buildProtectedRoute(
            context,
            () => ScannerScreen(),
            AppTranslations.t('ui_scan'),
          ),
        );
      
      case AppConstants.cartRoute:
        return MaterialPageRoute(
          builder: (context) => _buildProtectedRoute(
            context,
            () => CartScreen(),
            AppTranslations.t('ui_cart'),
          ),
        );
      
      case AppConstants.paymentRoute:
        return MaterialPageRoute(
          builder: (context) => _buildProtectedRoute(
            context,
            () => PaymentScreen(),
            AppTranslations.t('ui_payment'),
          ),
        );
      
      case AppConstants.receiptRoute:
        return MaterialPageRoute(
          builder: (context) => _buildProtectedRoute(
            context,
            () => ReceiptScreen(),
            AppTranslations.t('ui_receipt'),
          ),
        );
      
      case AppConstants.reportsRoute:
        return MaterialPageRoute(
          builder: (context) => _buildProtectedRoute(
            context,
            () => ReportsScreen(),
            AppTranslations.t('ui_reports'),
          ),
        );
      
      case AppConstants.profileRoute:
        return MaterialPageRoute(
          builder: (context) => _buildProtectedRoute(
            context,
            () => ProfileScreen(),
            AppTranslations.t('ui_profile'),
          ),
        );
      
      case AppConstants.paymentHistoryRoute:
        return MaterialPageRoute(
          builder: (context) => _buildProtectedRoute(
            context,
            () => payment_history.PaymentHistoryScreen(),
            AppTranslations.t('ui_payment_history'),
          ),
        );
      
      case '/notifications':
        return MaterialPageRoute(
          builder: (context) => _buildProtectedRoute(
            context,
            () => NotificationsScreen(),
            AppTranslations.t('ui_notifications'),
          ),
        );
      
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppConstants.errorRed,
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppTranslations.t('ui_page_not_found'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryDarkBlue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppTranslations.t('ui_the_page_you_requested_does_not'),
                    style: TextStyle(
                      color: AppConstants.textDarkGray,
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      AppConstants.dashboardRoute,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryDarkBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppTranslations.t('ui_back_to_home')),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  /// Build protected route with authentication check
  /// Redirects to login if user is not authenticated
  static Widget _buildProtectedRoute(
    BuildContext context,
    Widget Function() screenBuilder,
    String screenName,
  ) {
    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (context, auth, _, child) {
        // Check if user is authenticated
        if (!auth.isAuthenticated || auth.currentUser == null) {
          // Show loading while checking authentication
          if (auth.isLoading) {
            return _buildAuthLoadingScreen();
          }
          
          // Redirect to login if not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
          });
          
          return _buildRedirectingScreen(screenName);
        }
        
        // User is authenticated, show the requested screen
        return screenBuilder();
      },
    );
  }

  /// Loading screen shown while checking authentication
  static Widget _buildAuthLoadingScreen() {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppConstants.primaryYellow,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.store_rounded,
                size: 40,
                color: AppConstants.primaryDarkBlue,
              ),
            ),
            SizedBox(height: 24),
            
            // Loading indicator
            CircularProgressIndicator(
              color: AppConstants.primaryDarkBlue,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            
            // Loading text
            Text(
              AppTranslations.t('ui_checking_sign_in_status'),
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.textDarkGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Screen shown while redirecting to login
  static Widget _buildRedirectingScreen(String attemptedScreen) {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 64,
              color: AppConstants.primaryDarkBlue,
            ),
            SizedBox(height: 16),
            Text(
              AppTranslations.t('ui_sign_in_required'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryDarkBlue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppTranslations.t('ui_please_sign_in_to_access_the', [attemptedScreen]),
              style: TextStyle(
                color: AppConstants.textDarkGray,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: AppConstants.primaryDarkBlue,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder screen for routes not yet implemented
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: AppConstants.textDarkGray.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              AppTranslations.t('ui_page', [title]),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppTranslations.t('ui_under_development'),
              style: TextStyle(
                color: AppConstants.textDarkGray.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppTranslations.t('ui_back')),
            ),
          ],
        ),
      ),
    );
  }
}