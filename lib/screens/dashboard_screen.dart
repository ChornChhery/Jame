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

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _animationController.forward();
  }

  Future<void> _loadData() async {
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
                child: FadeTransition(
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
                FutureBuilder<double>(
                  future: app.getTodaySales(userId),
                  builder: (context, snapshot) {
                    return Text(
                      AppUtils.formatCurrency(snapshot.data ?? 0.0),
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
            childAspectRatio: 1.1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              action['title'] as String,
              action['icon'] as IconData,
              action['gradient'] as List<Color>,
              () => Navigator.pushNamed(context, action['route'] as String),
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
        
        // Low stock alerts
        FutureBuilder<List>(
          future: app.getLowStockProducts(userId),
          builder: (context, snapshot) {
            final lowStockProducts = snapshot.data ?? [];
            
            if (lowStockProducts.isEmpty) {
              return _buildNoAlertsCard();
            }

            return _buildLowStockCard(lowStockProducts);
          },
        ),
        SizedBox(height: 16),
        
        // Recent sales
        _buildRecentSalesCard(app.sales.take(3).toList()),
      ],
    );
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
    _animationController.dispose();
    super.dispose();
  }
}