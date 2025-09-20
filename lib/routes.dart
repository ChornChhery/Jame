// FILE: lib/routes.dart
import 'package:flutter/material.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'core/constants.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.loginRoute:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      
      case AppConstants.signupRoute:
        return MaterialPageRoute(builder: (_) => SignupScreen());
      
      case AppConstants.dashboardRoute:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      
      case AppConstants.productsRoute:
        return MaterialPageRoute(builder: (_) => PlaceholderScreen(title: 'สินค้า'));
      
      case AppConstants.scannerRoute:
        return MaterialPageRoute(builder: (_) => PlaceholderScreen(title: 'สแกน'));
      
      case AppConstants.cartRoute:
        return MaterialPageRoute(builder: (_) => PlaceholderScreen(title: 'ตะกร้า'));
      
      case AppConstants.paymentRoute:
        return MaterialPageRoute(builder: (_) => PlaceholderScreen(title: 'ชำระเงิน'));
      
      case AppConstants.receiptRoute:
        return MaterialPageRoute(builder: (_) => PlaceholderScreen(title: 'ใบเสร็จ'));
      
      case AppConstants.reportsRoute:
        return MaterialPageRoute(builder: (_) => PlaceholderScreen(title: 'รายงาน'));
      
      case AppConstants.profileRoute:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('ไม่พบหน้าที่ต้องการ'),
            ),
          ),
        );
    }
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
              'หน้า$title',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'กำลังพัฒนา...',
              style: TextStyle(
                color: AppConstants.textDarkGray.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('กลับ'),
            ),
          ],
        ),
      ),
    );
  }
}