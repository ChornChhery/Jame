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
import '../models/sale.dart';
import '../database/database_helper.dart';

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
  
  // Add mounted check for older Flutter versions
  bool get _mounted {
    try {
      return mounted;
    } catch (e) {
      // Fallback for older Flutter versions
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for changes in the AppProvider and refresh data when sales data changes
    final app = Provider.of<AppProvider>(context, listen: true);
    // The Consumer2 in the build method will automatically rebuild when app data changes
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
      
      // Only forward animation if widget is still mounted
      if (_mounted) {
        _animationController.forward().catchError((error) {
          debugPrint('Animation forward error: $error');
        });
      }
    } catch (e) {
      debugPrint('Animation initialization failed: $e');
      _isInitialized = false;
    }
  }

  Future<void> _loadData() async {
    // Check if widget is still mounted before accessing context
    if (!_mounted) return;
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final app = Provider.of<AppProvider>(context, listen: false);
      
      if (auth.currentUser != null && auth.currentUser!.id != null) {
        // Start background connection test (non-blocking)
        auth.testServerConnectionBackground();
        
        try {
          // Load data immediately without waiting for connection test
          await app.loadProducts(auth.currentUser!.id!);
          await app.loadSales(auth.currentUser!.id!);
          await app.loadCartItems(auth.currentUser!.id!); // Load cart items
          
          // Check connection status after data loading
          final connectionAvailable = await auth.testServerConnection();
          // Check if widget is still mounted before showing snackbar
          if (!connectionAvailable && _mounted) {
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
          
          // Force a rebuild to update the UI with new data
          if (_mounted) {
            setState(() {});
          }
        } catch (e) {
          // Handle data loading errors gracefully
          debugPrint('⚠️ Data loading failed: $e');
          // Check if widget is still mounted before showing snackbar
          if (_mounted) {
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
    } catch (e) {
      debugPrint('⚠️ Unexpected error in _loadData: $e');
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
                    // Notification icon with badges
                    Consumer<AppProvider>(
                      builder: (context, app, child) {
                        // Count low stock products
                        final lowStockCount = app.products
                            .where((product) => product.quantity <= product.lowStock)
                            .length;
                        
                        // Count cart items
                        final cartItemCount = app.cartItemCount;
                        
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.notifications_outlined, color: Colors.white),
                                onPressed: () {
                                  _showNotificationsDialog(context);
                                },
                              ),
                            ),
                            if (lowStockCount > 0 || cartItemCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppConstants.errorRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${lowStockCount + cartItemCount}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
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
                FutureBuilder<double>(
                  future: _getTodaySales(userId), // Use async method to get real-time data
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        '฿0.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Text(
                        '฿0.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    
                    final todaySales = snapshot.data ?? 0.0;
                    return Text(
                      AppUtils.formatCurrency(todaySales),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
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
              child: FutureBuilder<int>(
                future: _getTodaySalesCount(userId), // Use async method for real-time count
                builder: (context, snapshot) {
                  final salesCount = snapshot.data ?? 0;
                  return _buildStatCard(
                    'ขายแล้ววันนี้',
                    '$salesCount',
                    Icons.receipt_outlined,
                    AppConstants.accentOrange,
                  );
                },
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
        'subtitle': 'สแกนบาร์โค้ดสินค้า',
        'icon': Icons.qr_code_scanner,
        'color': AppConstants.primaryYellow,
        'route': AppConstants.scannerRoute,
        'gradient': [AppConstants.primaryYellow, AppConstants.primaryYellow.withOpacity(0.7)],
      },
      {
        'title': 'จัดการสินค้า',
        'subtitle': 'เพิ่ม-แก้ไขสินค้า',
        'icon': Icons.inventory_2_outlined,
        'color': AppConstants.softBlue,
        'route': AppConstants.productsRoute,
        'gradient': [AppConstants.softBlue, AppConstants.softBlue.withOpacity(0.7)],
      },
      {
        'title': 'ตะกร้าสินค้า',
        'subtitle': 'จัดการคำสั่งซื้อ',
        'icon': Icons.shopping_cart_outlined,
        'color': AppConstants.accentOrange,
        'route': AppConstants.cartRoute,
        'gradient': [AppConstants.accentOrange, AppConstants.accentOrange.withOpacity(0.7)],
      },
      {
        'title': 'รายงานขาย',
        'subtitle': 'วิเคราะห์ยอดขาย',
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
        Consumer<AppProvider>(
          builder: (context, app, child) {
            // Count cart items for the cart button badge
            final cartItemCount = app.cartItemCount;
            
            return Column(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) SizedBox(height: 12),
                  _buildActionListItem(
                    actions[i]['title'] as String,
                    actions[i]['subtitle'] as String,
                    actions[i]['icon'] as IconData,
                    actions[i]['gradient'] as List<Color>,
                    () {
                      if (actions[i]['isManualSale'] == true) {
                        _showManualSaleDialog();
                      } else {
                        Navigator.pushNamed(context, actions[i]['route'] as String);
                      }
                    },
                    actions[i]['route'] == AppConstants.cartRoute ? cartItemCount : 0,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionListItem(String title, String subtitle, IconData icon, List<Color> gradient, VoidCallback onTap, int badgeCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge for cart items
                if (badgeCount > 0)
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppConstants.errorRed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
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
        
        // Recent sales (moved to top)
        _buildRecentSalesCard(app.sales.take(3).toList()),
        
        SizedBox(height: 16),
        
        // Low stock alerts (moved to middle)
        _buildLowStockAlertsStatic(app),
        
        SizedBox(height: 16),
        
        // Top 5 products (moved to bottom)
        _buildTopProductsCard(app, userId),
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
                // Product image
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppConstants.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: product.image != null && product.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            product.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.inventory_2_outlined,
                                color: AppConstants.errorRed,
                                size: 20,
                              );
                            },
                            // Add headers to handle WebP and other formats
                            headers: const {
                              'Accept': 'image/*',
                            },
                          ),
                        )
                      : Icon(
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

  Widget _buildTopProductsCard(AppProvider app, int userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getTopSellingProducts(
        userId, 
        DateTime.now().subtract(Duration(days: 30)), // Last 30 days
        DateTime.now(),
        limit: 5
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 200,
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
            child: Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryDarkBlue,
              ),
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(); // Return empty container if no data
        }
        
        final topProducts = snapshot.data!;
        
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
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: AppConstants.primaryDarkBlue,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'สินค้ายอดนิยม (Top 5)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryDarkBlue,
                      ),
                    ),
                  ],
                ),
              ),
              ...topProducts.map((product) {
                // Safely extract string values from map, handling Blob types from MySQL
                String? _safeString(dynamic value) {
                  if (value == null) return null;
                  
                  // Handle Blob type from MySQL
                  if (value is List<int>) {
                    return String.fromCharCodes(value);
                  }
                  
                  // Handle regular string
                  if (value is String) {
                    return value.isEmpty ? null : value;
                  }
                  
                  // Convert other types to string
                  return value.toString();
                }
                
                final productName = _safeString(product['name']) ?? 'ไม่ระบุ';
                final productImage = _safeString(product['image']);
                final totalRevenue = product['total_revenue'] is int 
                    ? product['total_revenue'].toDouble() 
                    : product['total_revenue'] as double? ?? 0.0;
                final totalQuantity = product['total_quantity'] is double
                    ? product['total_quantity'].toInt()
                    : product['total_quantity'] as int? ?? 0;
                
                return Container(
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
                      // Product image
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: productImage != null && productImage.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  productImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.inventory_2,
                                      color: AppConstants.primaryDarkBlue,
                                      size: 20,
                                    );
                                  },
                                  // Add headers to handle WebP and other formats
                                  headers: const {
                                    'Accept': 'image/*',
                                  },
                                ),
                              )
                            : Icon(
                                Icons.inventory_2,
                                color: AppConstants.primaryDarkBlue,
                                size: 20,
                              ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.primaryDarkBlue,
                              ),
                            ),
                            Text(
                              'ขายได้ $totalQuantity หน่วย',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textDarkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppUtils.formatCurrency(totalRevenue),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryDarkBlue,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
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
            FutureBuilder<List<Sale>>(
              future: _loadSalesWithItems(sales),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryDarkBlue,
                      ),
                    ),
                  );
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  // Fallback to original implementation if there's an error
                  return _buildRecentSalesFallback(sales);
                }
                
                final salesWithItems = snapshot.data!;
                return _buildRecentSalesWithImages(salesWithItems);
              },
            ),
        ],
      ),
    );
  }

  Future<List<Sale>> _loadSalesWithItems(List sales) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    if (auth.currentUser?.id == null) {
      return sales as List<Sale>;
    }
    
    // Load sales with their items
    final salesWithItems = <Sale>[];
    for (var sale in sales as List<Sale>) {
      try {
        final items = await app.getSaleItemsWithProducts(sale.id!);
        salesWithItems.add(sale.copyWith(items: items));
      } catch (e) {
        debugPrint('Error loading sale items: $e');
        salesWithItems.add(sale);
      }
    }
    
    return salesWithItems;
  }

  Widget _buildRecentSalesWithImages(List<Sale> sales) {
    return Column(
      children: sales.map((sale) {
        // Get the first product image if available
        String? firstProductImage;
        if (sale.items != null && sale.items!.isNotEmpty && sale.items!.first.product != null) {
          firstProductImage = sale.items!.first.product!.image;
        }
        
        final itemCount = sale.items?.length ?? 0;
        final isHighValue = sale.totalAmount > 1000; // High value sale threshold
        
        return Container(
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
                child: firstProductImage != null && firstProductImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          firstProductImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              isHighValue ? Icons.star : Icons.receipt,
                              color: isHighValue ? Colors.green[700] : AppConstants.successGreen,
                              size: 20,
                            );
                          },
                          // Add headers to handle WebP and other formats
                          headers: const {
                            'Accept': 'image/*',
                          },
                        ),
                      )
                    : Icon(
                        isHighValue ? Icons.star : Icons.receipt,
                        color: isHighValue ? Colors.green[700] : AppConstants.successGreen,
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
                      AppUtils.formatDateTimeThai(sale.saleDate),
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
        );
      }).toList(),
    );
  }

  Widget _buildRecentSalesFallback(List sales) {
    return Column(
      children: sales.map((sale) {
        final itemCount = sale.items?.length ?? 0;
        final isHighValue = sale.totalAmount > 1000; // High value sale threshold
        
        return Container(
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
                  isHighValue ? Icons.star : Icons.receipt,
                  color: isHighValue ? Colors.green[700] : AppConstants.successGreen,
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
                      AppUtils.formatDateTimeThai(sale.saleDate),
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
        );
      }).toList(),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    final app = Provider.of<AppProvider>(context, listen: false);
    
    // Get low stock products
    final lowStockProducts = app.products
        .where((product) => product.quantity <= product.lowStock)
        .toList();
    
    // Get cart items
    final cartItems = app.cartItems.toList();
    
    // Get recent sales (today only)
    final recentSales = app.sales
        .where((sale) => _isToday(sale.saleDate))
        .toList()
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
    
    final last5Sales = recentSales.take(5).toList();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications, color: AppConstants.primaryDarkBlue),
              SizedBox(width: 8),
              Text('การแจ้งเตือน'),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Low stock notifications
                if (lowStockProducts.isNotEmpty) ...[
                  Text(
                    'แจ้งเตือนสินค้าใกล้หมด (${lowStockProducts.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryDarkBlue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    constraints: BoxConstraints(maxHeight: 150),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: lowStockProducts.length,
                      itemBuilder: (context, index) {
                        final product = lowStockProducts[index];
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
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
                                              Icons.inventory_2_outlined,
                                              color: AppConstants.errorRed,
                                              size: 20.0,
                                            );
                                          },
                                          headers: const {
                                            'Accept': 'image/*',
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.inventory_2_outlined,
                                        color: AppConstants.errorRed,
                                        size: 20.0,
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
                                        fontWeight: FontWeight.w500,
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
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                
                // Cart items notifications
                if (cartItems.isNotEmpty) ...[
                  Text(
                    'สินค้าในตะกร้า (${cartItems.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryDarkBlue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    constraints: BoxConstraints(maxHeight: 150),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = cartItems[index];
                        final product = cartItem.product;
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppConstants.accentOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: product?.image != null && product!.image!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          product.image!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.shopping_cart,
                                              color: AppConstants.accentOrange,
                                              size: 20.0,
                                            );
                                          },
                                          headers: const {
                                            'Accept': 'image/*',
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.shopping_cart,
                                        color: AppConstants.accentOrange,
                                        size: 20.0,
                                      ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product?.name ?? 'ไม่ระบุสินค้า',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${cartItem.quantity} ${product?.unit ?? 'หน่วย'} x ${AppUtils.formatCurrency(product?.price ?? 0)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppConstants.textDarkGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                AppUtils.formatCurrency((product?.price ?? 0) * cartItem.quantity),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.accentOrange,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                
                // Recent sales notifications
                if (last5Sales.isNotEmpty) ...[
                  Text(
                    'การขายล่าสุด (${last5Sales.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryDarkBlue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    constraints: BoxConstraints(maxHeight: 150),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: last5Sales.length,
                      itemBuilder: (context, index) {
                        final sale = last5Sales[index];
                        // Get the first product image if available
                        String? firstProductImage;
                        if (sale.items != null && sale.items!.isNotEmpty && sale.items!.first.product != null) {
                          firstProductImage = sale.items!.first.product!.image;
                        }
                        
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: firstProductImage != null && firstProductImage!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          firstProductImage!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.receipt,
                                              color: AppConstants.successGreen,
                                              size: 20.0,
                                            );
                                          },
                                          headers: const {
                                            'Accept': 'image/*',
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.receipt,
                                        color: AppConstants.successGreen,
                                        size: 20.0,
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
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      AppUtils.formatDateTimeThai(sale.saleDate),
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
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.successGreen,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (lowStockProducts.isEmpty && cartItems.isEmpty) ...[
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: AppConstants.successGreen,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'ไม่มีการแจ้งเตือน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'ไม่มีสินค้าใกล้หมดและยังไม่มีการขายวันนี้',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.textDarkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notifications');
              },
              child: Text('ดูการแจ้งเตือนทั้งหมด'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ปิด'),
            ),
          ],
        );
      },
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

  void _showManualSaleDialog() {
    // Check if widget is still mounted before showing dialog
    if (!_mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ManualSaleDialog(
          onSaleCompleted: () {
            // Refresh data after sale completion
            _loadData().then((_) {
              // Force UI update after data refresh
              if (_mounted) {
                setState(() {});
              }
            }).catchError((error) {
              debugPrint('Error refreshing data after sale: $error');
            });
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // Properly dispose animation controller to prevent ticker errors
    try {
      if (_isInitialized && _animationController.isAnimating) {
        _animationController.stop();
      }
      if (_isInitialized) {
        _animationController.dispose();
      }
    } catch (e) {
      debugPrint('Error disposing animation controller: $e');
    }
    super.dispose();
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
    final thaiDate = AppUtils.toThaiTime(date);
    return thaiDate.year == now.year && 
           thaiDate.month == now.month && 
           thaiDate.day == now.day;
  }
  
  // Add async method to get today's sales for real-time data
  Future<double> _getTodaySales(int userId) async {
    try {
      return await DatabaseHelper.instance.getTotalSalesToday(userId);
    } catch (e) {
      debugPrint('Error getting today sales: $e');
      return 0.0;
    }
  }
  
  // Add async method to get today's sales count for real-time data
  Future<int> _getTodaySalesCount(int userId) async {
    try {
      final sales = await DatabaseHelper.instance.getSalesToday(userId);
      return sales.length;
    } catch (e) {
      debugPrint('Error getting today sales count: $e');
      return 0;
    }
  }

}