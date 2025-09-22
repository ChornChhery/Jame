// FILE: lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../models/product.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../widgets/add_edit_product_dialog.dart';
import '../widgets/product_details_dialog.dart';
import '../widgets/manual_sale_dialog.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedNavIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _initializeAnimations() {
    try {
      _animationController = AnimationController(
        duration: Duration(milliseconds: 1000),
        vsync: this,
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
      );
      _isInitialized = true;
      _animationController.forward();
    } catch (e) {
      debugPrint('Animation initialization failed: $e');
      _isInitialized = false;
    }
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    if (auth.currentUser != null && auth.currentUser!.id != null) {
      // Start background connection test (non-blocking)
      auth.testServerConnectionBackground();
      
      try {
        // Load data immediately without waiting for connection test
        await app.loadProducts(auth.currentUser!.id!);
        await app.loadSales(auth.currentUser!.id!);
        
        // Check connection status after data loading
        final connectionAvailable = await auth.testServerConnection();
        if (!connectionAvailable && mounted) {
          // Show warning only if connection is down
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('⚠️ ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ แอปทำงานในโหมดจำกัด'), // Cannot connect to server, working in limited mode
                  ),
                ],
              ),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        // Handle data loading errors gracefully
        debugPrint('⚠️ Data loading failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('โหลดข้อมูลไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'), // Data loading failed, please try again
              backgroundColor: AppConstants.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.all(16),
            ),
          );
        }
      }
    } else {
      debugPrint('⚠️ Cannot load data: User or User ID is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer2<AuthProvider, AppProvider>(
          builder: (context, auth, app, child) {
            if (auth.currentUser == null) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppConstants.primaryDarkBlue,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _loadData(),
              color: AppConstants.primaryDarkBlue,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: _isInitialized
                    ? FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              // Custom Header
                              _buildModernHeader(auth.currentUser!),
                              
                              // Content
                              Padding(
                                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sales Overview Cards
                                    _buildSalesOverview(app, auth.currentUser!.id!),
                                    SizedBox(height: 24),

                                    // Quick Actions Grid
                                    _buildQuickActionsGrid(),
                                    SizedBox(height: 24),

                                    // Recent Activities & Alerts
                                    _buildRecentSection(app, auth.currentUser!.id!),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Fallback content without animation
                          _buildModernHeader(auth.currentUser!),
                          Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSalesOverview(app, auth.currentUser!.id!),
                                SizedBox(height: 24),
                                _buildQuickActionsGrid(),
                                SizedBox(height: 24),
                                _buildRecentSection(app, auth.currentUser!.id!),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernHeader(user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryDarkBlue,
            AppConstants.primaryDarkBlue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryDarkBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          children: [
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      user.firstName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Connection status indicator
                    Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_done,
                                color: Colors.blue,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'พร้อมใช้',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () {
                          // Show notifications
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppConstants.profileRoute),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            user.firstName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryDarkBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Shop info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryYellow.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.store_rounded,
                      color: AppConstants.primaryDarkBlue,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.shopName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (user.shopAddress != null && user.shopAddress!.isNotEmpty)
                          Text(
                            user.shopAddress!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
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

  Widget _buildSalesOverview(AppProvider app, int userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ภาพรวมยอดขาย',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryDarkBlue,
          ),
        ),
        SizedBox(height: 16),
        
        // Main sales card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.successGreen,
                AppConstants.successGreen.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppConstants.successGreen.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ยอดขายวันนี้',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatDate(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Fixed: Remove FutureBuilder to prevent setState during build
                Text(
                  AppUtils.formatCurrency(_getTodaySalesStatic(app)),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // Stats row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'สินค้าทั้งหมด',
                '${app.products.length}',
                Icons.inventory_2_outlined,
                AppConstants.softBlue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'ขายแล้ววันนี้',
                '${app.sales.where((s) => _isToday(s.saleDate)).length}',
                Icons.receipt_outlined,
                AppConstants.accentOrange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'ในตะกร้า',
                '${app.cartItemCount}',
                Icons.shopping_cart_outlined,
                AppConstants.primaryYellow,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppConstants.textDarkGray,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'title': 'สแกนสินค้า',
        'icon': Icons.qr_code_scanner,
        'color': AppConstants.primaryYellow,
        'route': AppConstants.scannerRoute,
        'gradient': [AppConstants.primaryYellow, AppConstants.primaryYellow.withOpacity(0.7)],
      },
      {
        'title': 'ขายด่วน',
        'icon': Icons.point_of_sale,
        'color': Colors.purple,
        'isManualSale': true,
        'gradient': [Colors.purple, Colors.purple.withOpacity(0.7)],
      },
      {
        'title': 'จัดการสินค้า',
        'icon': Icons.inventory_2_outlined,
        'color': AppConstants.softBlue,
        'route': AppConstants.productsRoute,
        'gradient': [AppConstants.softBlue, AppConstants.softBlue.withOpacity(0.7)],
      },
      {
        'title': 'ตะกร้าสินค้า',
        'icon': Icons.shopping_cart_outlined,
        'color': AppConstants.accentOrange,
        'route': AppConstants.cartRoute,
        'gradient': [AppConstants.accentOrange, AppConstants.accentOrange.withOpacity(0.7)],
      },
      {
        'title': 'รายงานขาย',
        'icon': Icons.analytics_outlined,
        'color': AppConstants.successGreen,
        'route': AppConstants.reportsRoute,
        'gradient': [AppConstants.successGreen, AppConstants.successGreen.withOpacity(0.7)],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เมนูหลัก',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryDarkBlue,
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              action['title'] as String,
              action['icon'] as IconData,
              action['gradient'] as List<Color>,
              () {
                if (action['isManualSale'] == true) {
                  _showManualSaleDialog();
                } else {
                  Navigator.pushNamed(context, action['route'] as String);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, List<Color> gradient, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection(AppProvider app, int userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'กิจกรรมล่าสุด',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryDarkBlue,
          ),
        ),
        SizedBox(height: 16),
        
        // Low stock alerts - using static data to prevent setState during build
        _buildLowStockAlertsStatic(app),
        
        SizedBox(height: 16),
        
        // Recent sales
        _buildRecentSalesCard(app.sales.take(3).toList()),
      ],
    );
  }

  Widget _buildLowStockAlertsStatic(AppProvider app) {
    // Filter low stock products from existing data to prevent setState during build
    final lowStockProducts = app.products.where((p) => p.quantity <= p.lowStock).take(5).toList();
    
    if (lowStockProducts.isEmpty) {
      return _buildNoAlertsCard();
    }
    
    return _buildLowStockCard(lowStockProducts);
  }

  Widget _buildLowStockCard(List lowStockProducts) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.errorRed.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppConstants.errorRed,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'แจ้งเตือนสินค้าใกล้หมด (${lowStockProducts.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.errorRed,
                  ),
                ),
              ],
            ),
          ),
          ...lowStockProducts.take(3).map((product) => Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppConstants.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: AppConstants.errorRed,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryDarkBlue,
                        ),
                      ),
                      Text(
                        'เหลือ ${product.quantity} ${product.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.textDarkGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'น้อยกว่า ${product.lowStock}',
                    style: TextStyle(
                      color: AppConstants.errorRed,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          if (lowStockProducts.length > 3)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              child: Text(
                'และอีก ${lowStockProducts.length - 3} รายการ',
                style: TextStyle(
                  color: AppConstants.textDarkGray,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoAlertsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppConstants.successGreen,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'ไม่มีการแจ้งเตือน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          Text(
            'สินค้าทั้งหมดมีสต็อกเพียงพอ',
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textDarkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSalesCard(List sales) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'การขายล่าสุด',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryDarkBlue,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppConstants.reportsRoute),
                  child: Text(
                    'ดูทั้งหมด',
                    style: TextStyle(
                      color: AppConstants.primaryDarkBlue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (sales.isEmpty)
            Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      color: AppConstants.textDarkGray.withOpacity(0.5),
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ยังไม่มีการขาย',
                      style: TextStyle(
                        color: AppConstants.textDarkGray,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...sales.map((sale) => Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppConstants.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_outlined,
                      color: AppConstants.successGreen,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.receiptNumber,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryDarkBlue,
                          ),
                        ),
                        Text(
                          AppUtils.formatDateTime(sale.saleDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.textDarkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppUtils.formatCurrency(sale.totalAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.successGreen,
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildModernBottomNav() {
    final items = [
      {'icon': Icons.dashboard, 'label': 'แดชบอร์ด', 'route': null},
      {'icon': Icons.inventory_2_outlined, 'label': 'สินค้า', 'route': AppConstants.productsRoute},
      {'icon': Icons.qr_code_scanner, 'label': 'สแกน', 'route': AppConstants.scannerRoute},
      {'icon': Icons.shopping_cart_outlined, 'label': 'ตะกร้า', 'route': AppConstants.cartRoute},
      {'icon': Icons.analytics_outlined, 'label': 'รายงาน', 'route': AppConstants.reportsRoute},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _selectedNavIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedNavIndex = index);
                  if (item['route'] != null) {
                    Navigator.pushNamed(context, item['route'] as String);
                  }
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppConstants.primaryDarkBlue.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: isSelected 
                            ? AppConstants.primaryDarkBlue 
                            : AppConstants.textDarkGray,
                        size: 24,
                      ),
                      SizedBox(height: 4),
                                            Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isSelected 
                              ? AppConstants.primaryDarkBlue 
                              : AppConstants.textDarkGray,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  double _getTodaySalesStatic(AppProvider app) {
    // Calculate today's sales from existing sales data without async call
    final today = DateTime.now();
    final todaySales = app.sales.where((sale) => _isToday(sale.saleDate));
    return todaySales.fold<double>(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'สวัสดีตอนเช้า';
    if (hour < 17) return 'สวัสดีตอนบ่าย';
    return 'สวัสดีตอนเย็น';
  }

  String _formatDate(DateTime date) {
    final months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _animationController.dispose();
    }
    super.dispose();
  }

  void _showManualSaleDialog() {
    showDialog(
      context: context,
      builder: (context) => ManualSaleDialog(
        onSaleCompleted: () {
          _loadData(); // Refresh dashboard data
        },
      ),
    );
  }
}

// ================================
// PRODUCTS MANAGEMENT SCREEN
// ================================

class ProductsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const ProductsScreen({Key? key, this.arguments}) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = false;
  List<Product> _filteredProducts = [];
  
  final List<String> _thaiCategories = [
    'อาหารและเครื่องดื่ม',
    'ของใช้ในบ้าน',
    'เครื่องเขียน',
    'ยาและอุปกรณ์การแพทย์',
    'เสื้อผ้าและเครื่องแต่งกาย',
    'อิเล็กทรอนิกส์',
    'เครื่องใช้ในครัว',
    'อื่นๆ'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _loadProducts();
    
    // Add listener to search controller
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _searchProducts();
    });
    
    // Handle navigation arguments for scanner integration
    if (widget.arguments != null) {
      final args = widget.arguments!;
      if (args['mode'] == 'add') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAddEditProductDialog(prefilledCode: args['code']);
        });
      } else if (args['mode'] == 'view' && args['product'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showProductDetailsDialog(args['product']);
        });
      }
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    if (auth.currentUser?.id != null) {
      await app.loadProducts(auth.currentUser!.id!);
    }
    
    setState(() => _isLoading = false);
    _searchProducts();
  }

  void _searchProducts() {
    final app = Provider.of<AppProvider>(context, listen: false);
    List<Product> products = app.products;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      products = products.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               product.code.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      products = products.where((product) {
        return product.category == _selectedCategory;
      }).toList();
    }

    setState(() {
      _filteredProducts = products;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchAndFilter(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductsList(),
                  _buildLowStockAlerts(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // Placeholder for the remaining methods
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryDarkBlue,
            AppConstants.primaryDarkBlue.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'จัดการสินค้า',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<AppProvider>(
                  builder: (context, app, child) {
                    return Text(
                      'ทั้งหมด ${app.products.length} รายการ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาสินค้า...', // Search products...
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          _searchProducts();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => _searchProducts(),
            ),
          ),
          SizedBox(height: 12),
          
          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _thaiCategories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: EdgeInsets.only(left: 4, right: 8),
                    child: FilterChip(
                      label: Text('ทั้งหมด'), // All
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = null;
                        });
                        _searchProducts();
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppConstants.primaryDarkBlue.withOpacity(0.2),
                      checkmarkColor: AppConstants.primaryDarkBlue,
                    ),
                  );
                }
                
                final category = _thaiCategories[index - 1];
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                      _searchProducts();
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppConstants.primaryDarkBlue.withOpacity(0.2),
                    checkmarkColor: AppConstants.primaryDarkBlue,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppConstants.primaryDarkBlue,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2),
                SizedBox(width: 8),
                Text('รายการสินค้า'), // Product List
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber),
                SizedBox(width: 8),
                Text('สต็อกต่ำ'), // Low Stock
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return Consumer<AppProvider>(
      builder: (context, app, child) {
        if (_isLoading && app.products.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: AppConstants.primaryDarkBlue,
              ),
            ),
          );
        }

        if (app.products.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีสินค้า',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'เริ่มต้นด้วยการเพิ่มสินค้าใหม่',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) {
            final product = _filteredProducts[index];
            final isLowStock = product.quantity <= product.lowStock;
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLowStock ? Colors.orange[300]! : Colors.grey[200]!,
                  width: isLowStock ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.image != null && product.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.inventory_2,
                                color: AppConstants.primaryDarkBlue,
                                size: 24,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.inventory_2,
                          color: AppConstants.primaryDarkBlue,
                          size: 24,
                        ),
                ),
                title: Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.code != null && product.code!.isNotEmpty)
                      Text(
                        'รหัส: ${product.code}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '฿${NumberFormat('#,##0.00').format(product.price)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryDarkBlue,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLowStock ? Colors.orange : Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'คงเหลือ ${product.quantity}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: SizedBox(
                  width: 90, // Further reduced trailing width
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Compact Add to Cart button
                      GestureDetector(
                        onTap: product.quantity > 0 ? () => _addToCart(product) : null,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: product.quantity > 0 
                                ? AppConstants.primaryDarkBlue.withOpacity(0.1)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.add_shopping_cart,
                            color: product.quantity > 0 
                                ? AppConstants.primaryDarkBlue 
                                : Colors.grey[400],
                            size: 14,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      if (isLowStock)
                        Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 14,
                        ),
                      if (isLowStock)
                        SizedBox(width: 4),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 14,
                        constraints: BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'add_to_cart':
                              _addToCart(product);
                              break;
                            case 'view':
                              _showProductDetailsDialog(product);
                              break;
                            case 'edit':
                              _showAddEditProductDialog(product: product);
                              break;
                            case 'delete':
                              _showDeleteConfirmDialog(product);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'add_to_cart',
                            height: 35,
                            child: Row(
                              children: [
                                Icon(Icons.add_shopping_cart, size: 14, color: AppConstants.primaryDarkBlue),
                                SizedBox(width: 4),
                                Expanded(child: Text('เพิ่มในตะกร้า', style: TextStyle(color: AppConstants.primaryDarkBlue, fontSize: 11))),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'view',
                            height: 35,
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 14),
                                SizedBox(width: 4),
                                Expanded(child: Text('ดูรายละเอียด', style: TextStyle(fontSize: 11))),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            height: 35,
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 14),
                                SizedBox(width: 4),
                                Expanded(child: Text('แก้ไข', style: TextStyle(fontSize: 11))),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            height: 35,
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 14, color: Colors.red),
                                SizedBox(width: 4),
                                Expanded(child: Text('ลบ', style: TextStyle(color: Colors.red, fontSize: 11))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                onTap: () => _showProductDetailsDialog(product),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLowStockAlerts() {
    return Consumer<AppProvider>(
      builder: (context, app, child) {
        final lowStockProducts = app.products
            .where((product) => product.quantity <= product.lowStock)
            .toList();

        if (lowStockProducts.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'สต็อกปกติ',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ไม่มีสินค้าที่มีสต็อกต่ำ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: lowStockProducts.length,
          itemBuilder: (context, index) {
            final product = lowStockProducts[index];
            final urgencyLevel = product.quantity == 0 ? 2 : 
                               product.quantity <= (product.lowStock * 0.5) ? 1 : 0;
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: urgencyLevel == 2 ? Colors.red :
                         urgencyLevel == 1 ? Colors.orange : Colors.amber,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: (urgencyLevel == 2 ? Colors.red :
                           urgencyLevel == 1 ? Colors.orange : Colors.amber)
                           .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    urgencyLevel == 2 ? Icons.error :
                    urgencyLevel == 1 ? Icons.warning : Icons.info,
                    color: urgencyLevel == 2 ? Colors.red :
                           urgencyLevel == 1 ? Colors.orange : Colors.amber,
                    size: 24,
                  ),
                ),
                title: Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      urgencyLevel == 2 ? 'หมด! ต้องเติมสต็อกด่วน' :
                      urgencyLevel == 1 ? 'สต็อกต่ำมาก! ควรเติมสต็อก' :
                      'สต็อกต่ำ แนะนำให้เติมสต็อก',
                      style: TextStyle(
                        color: urgencyLevel == 2 ? Colors.red :
                               urgencyLevel == 1 ? Colors.orange : Colors.amber[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'คงเหลือ: ${product.quantity}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'ขั้นต่ำ: ${product.lowStock}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => _showAddEditProductDialog(product: product),
                  child: Text('เติมสต็อก'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryDarkBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size(0, 32),
                  ),
                ),
                onTap: () => _showProductDetailsDialog(product),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddEditProductDialog(),
      backgroundColor: AppConstants.primaryDarkBlue,
      foregroundColor: Colors.white,
      icon: Icon(Icons.add),
      label: Text('เพิ่มสินค้า'),
    );
  }

  void _showAddEditProductDialog({Product? product, String? prefilledCode}) {
    showDialog(
      context: context,
      builder: (context) => AddEditProductDialog(
        product: product,
        prefilledCode: prefilledCode,
        onSaved: () {
          _loadProducts();
        },
      ),
    );
  }

  void _showProductDetailsDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailsDialog(
        product: product,
        onEdit: () {
          Navigator.pop(context);
          _showAddEditProductDialog(product: product);
        },
        onDelete: () {
          Navigator.pop(context);
          _showDeleteConfirmDialog(product);
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบสินค้า "${product.name}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                
                await appProvider.deleteProduct(
                  product.id!,
                  authProvider.currentUser!.id!,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ลบสินค้าเรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                _loadProducts();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เกิดข้อผิดพลาด: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product) {
    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สินค้านี้หมดสต็อกแล้ว'),
          backgroundColor: AppConstants.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.addToCart(product, quantity: 1);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เพิ่ม ${product.name} ในตะกร้าแล้ว'),
        backgroundColor: AppConstants.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'ดูตะกร้า',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, AppConstants.cartRoute);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}