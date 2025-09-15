// FILE: lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../core/constants.dart';
import '../core/utils.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    if (auth.currentUser != null) {
      await app.loadProducts(auth.currentUser!.id!);
      await app.loadSales(auth.currentUser!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      appBar: AppBar(
        title: Text(AppConstants.dashboard),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, AppConstants.profileRoute),
          ),
        ],
      ),
      body: Consumer2<AuthProvider, AppProvider>(
        builder: (context, auth, app, child) {
          if (auth.currentUser == null) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome header
                _buildWelcomeHeader(auth.currentUser!),
                SizedBox(height: 24),

                // Sales summary
                _buildSalesSummary(app, auth.currentUser!.id!),
                SizedBox(height: 24),

                // Quick actions
                _buildQuickActions(),
                SizedBox(height: 24),

                // Low stock alerts
                _buildLowStockAlerts(app, auth.currentUser!.id!),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildWelcomeHeader(user) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppConstants.primaryYellow,
              child: Text(
                user.firstName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryDarkBlue,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สวัสดี ${user.firstName}!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.shopName,
                    style: TextStyle(
                      color: AppConstants.textDarkGray.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesSummary(AppProvider app, int userId) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ยอดขายวันนี้',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            FutureBuilder<double>(
              future: app.getTodaySales(userId),
              builder: (context, snapshot) {
                return Text(
                  AppUtils.formatCurrency(snapshot.data ?? 0.0),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.successGreen,
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('สินค้า', '${app.products.length}', Icons.inventory),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('ขายแล้ว', '${app.sales.length}', Icons.receipt),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('ในตะกร้า', '${app.cartItemCount}', Icons.shopping_cart),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppConstants.primaryDarkBlue),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppConstants.textDarkGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เมนูหลัก',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildActionCard(
              'สแกนสินค้า',
              Icons.qr_code_scanner,
              AppConstants.primaryYellow,
              () => Navigator.pushNamed(context, AppConstants.scannerRoute),
            ),
            _buildActionCard(
              'สินค้า',
              Icons.inventory,
              AppConstants.softBlue,
              () => Navigator.pushNamed(context, AppConstants.productsRoute),
            ),
            _buildActionCard(
              'ตะกร้า',
              Icons.shopping_cart,
              AppConstants.accentOrange,
              () => Navigator.pushNamed(context, AppConstants.cartRoute),
            ),
            _buildActionCard(
              'รายงาน',
              Icons.analytics,
              AppConstants.successGreen,
              () => Navigator.pushNamed(context, AppConstants.reportsRoute),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockAlerts(AppProvider app, int userId) {
    return FutureBuilder<List>(
      future: app.getLowStockProducts(userId),
      builder: (context, snapshot) {
        final lowStockProducts = snapshot.data ?? [];
        
        if (lowStockProducts.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'แจ้งเตือนสินค้าใกล้หมด',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.errorRed,
              ),
            ),
            SizedBox(height: 12),
            ...lowStockProducts.take(3).map((product) => Card(
              child: ListTile(
                leading: Icon(
                  Icons.warning,
                  color: AppConstants.errorRed,
                ),
                title: Text(product.name),
                subtitle: Text('เหลือ ${product.quantity} ${product.unit}'),
                trailing: Text(
                  'น้อยกว่า ${product.lowStock}',
                  style: TextStyle(
                    color: AppConstants.errorRed,
                    fontSize: 12,
                  ),
                ),
              ),
            )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: AppConstants.dashboard,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: AppConstants.products,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: AppConstants.scanner,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: AppConstants.cart,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: AppConstants.reports,
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            Navigator.pushNamed(context, AppConstants.productsRoute);
            break;
          case 2:
            Navigator.pushNamed(context, AppConstants.scannerRoute);
            break;
          case 3:
            Navigator.pushNamed(context, AppConstants.cartRoute);
            break;
          case 4:
            Navigator.pushNamed(context, AppConstants.reportsRoute);
            break;
        }
      },
    );
  }
}