// FILE: lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../models/product.dart';
import '../models/sale.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedPeriod = 'วันนี้'; // Today
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  
  // Reports data
  Map<String, dynamic> _salesData = {};
  List<Product> _topProducts = [];
  List<Product> _lowStockProducts = [];
  List<Sale> _recentSales = [];
  
  // Advanced Analytics Data
  List<Map<String, dynamic>> _topSellingProducts = [];
  List<Map<String, dynamic>> _customerHistory = [];
  List<Map<String, dynamic>> _reorderSuggestions = [];
  Map<String, dynamic> _hourlySalesData = {};
  Map<String, dynamic> _dailySalesData = {};
  Map<String, dynamic> _inventoryMovement = {};
  Map<String, dynamic> _salesTrends = {};
  List<Map<String, dynamic>> _productPerformance = [];
  Map<String, dynamic> _customerSegmentation = {};
  
  // New data for different time periods
  List<Map<String, dynamic>> _topSellingToday = [];
  List<Map<String, dynamic>> _topSellingYesterday = [];
  List<Map<String, dynamic>> _topSellingThisWeek = [];
  List<Map<String, dynamic>> _topSellingThisMonth = [];
  List<Map<String, dynamic>> _topSellingLastMonth = [];
  List<Map<String, dynamic>> _topSellingThisYear = [];
  List<Map<String, dynamic>> _topSellingLastYear = [];
  
  // Selected time period for top products tab - default to "วันนี้" (today)
  String _selectedTopProductsPeriod = 'วันนี้';

  @override
  void initState() {
    super.initState();
    // Initialize the TabController immediately but with a slight delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _tabController = TabController(length: 5, vsync: this);
      });
      _initializeControllers();
      _loadReportsData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _animationController.forward();
  }

  void _ensureTabController() {
    if (_tabController == null || _tabController!.length != 5) {
      _tabController?.dispose();
      _tabController = TabController(length: 5, vsync: this);
    }
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final app = Provider.of<AppProvider>(context, listen: false);
      
      if (auth.currentUser?.id == null) return;
      
      // Load existing data from AppProvider
      await app.loadSales(auth.currentUser!.id!);
      await app.loadProducts(auth.currentUser!.id!);
      
      // Filter sales for selected period
      final allSales = app.sales;
      final filteredSales = allSales.where((sale) {
        // Convert both dates to Thai time for comparison
        final saleDateThai = AppUtils.toThaiTime(sale.saleDate);
        final startDateThai = AppUtils.toThaiTime(_startDate);
        final endDateThai = AppUtils.toThaiTime(_endDate.add(Duration(days: 1)));
        
        return saleDateThai.isAfter(startDateThai) && 
               saleDateThai.isBefore(endDateThai);
      }).toList();
      
      // Load sale items with product details for the filtered sales
      final salesWithItems = <Sale>[];
      for (var sale in filteredSales) {
        try {
          final items = await app.getSaleItemsWithProducts(sale.id!);
          salesWithItems.add(sale.copyWith(items: items));
        } catch (e) {
          debugPrint('Error loading sale items: $e');
          salesWithItems.add(sale);
        }
      }
      
      // Update the recent sales with items
      _recentSales = salesWithItems.take(10).toList();
      
      // Calculate sales analytics
      _salesData = _calculateSalesAnalytics(filteredSales);
      
      // Get top selling products (simplified - using existing products)
      _topProducts = app.products.take(5).toList();
      
      // Get low stock products
      _lowStockProducts = await app.getLowStockProducts(auth.currentUser!.id!);
      
      // Load advanced analytics data
      await _loadAdvancedAnalytics(auth.currentUser!.id!);
      
    } catch (e) {
      _showErrorMessage('เกิดข้อผิดพลาดในการโหลดข้อมูล: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAdvancedAnalytics(int userId) async {
    try {
      final app = Provider.of<AppProvider>(context, listen: false);
      
      // Get top selling products for different time periods
      final now = DateTime.now();
      
      // Today
      _topSellingToday = await app.getTopSellingProducts(
        userId, 
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
        limit: 5
      );
      
      // Yesterday
      final yesterday = now.subtract(Duration(days: 1));
      _topSellingYesterday = await app.getTopSellingProducts(
        userId, 
        DateTime(yesterday.year, yesterday.month, yesterday.day),
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
        limit: 5
      );
      
      // This week
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      _topSellingThisWeek = await app.getTopSellingProducts(
        userId, 
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
        limit: 5
      );
      
      // This month
      _topSellingThisMonth = await app.getTopSellingProducts(
        userId, 
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
        limit: 5
      );
      
      // Last month
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0); // Last day of last month
      _topSellingLastMonth = await app.getTopSellingProducts(
        userId, 
        DateTime(lastMonth.year, lastMonth.month, 1),
        DateTime(lastMonthEnd.year, lastMonthEnd.month, lastMonthEnd.day, 23, 59, 59),
        limit: 5
      );
      
      // This year
      _topSellingThisYear = await app.getTopSellingProducts(
        userId, 
        DateTime(now.year, 1, 1),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
        limit: 5
      );
      
      // Last year
      _topSellingLastYear = await app.getTopSellingProducts(
        userId, 
        DateTime(now.year - 1, 1, 1),
        DateTime(now.year - 1, 12, 31, 23, 59, 59),
        limit: 5
      );
      
      // Get top selling products for current period
      _topSellingProducts = await app.getTopSellingProducts(
        userId, 
        _startDate, 
        _endDate,
        limit: 10
      );
      
      // Get customer purchase history
      _customerHistory = await app.getCustomerPurchaseHistory(userId, limit: 20);
      
      // Get reorder suggestions
      _reorderSuggestions = await app.getReorderSuggestions(userId);
      
      // Get hourly sales data
      _hourlySalesData = await app.getSalesByHour(userId, _startDate, _endDate);
      
      // Get daily sales data
      _dailySalesData = await app.getSalesByDay(userId, _startDate, _endDate);
      
      // Get inventory movement
      _inventoryMovement = await app.getInventoryMovement(userId, _startDate, _endDate);
      
      // Get sales trends
      _salesTrends = await app.getSalesTrends(userId, _startDate, _endDate);
      
      // Get product performance
      _productPerformance = await app.getProductPerformance(userId, _startDate, _endDate, limit: 15);
      
      // Get customer segmentation
      _customerSegmentation = await app.getCustomerSegmentation(userId, limit: 100);
      
    } catch (e) {
      debugPrint('Error loading advanced analytics: $e');
    }
  }

  Map<String, dynamic> _calculateSalesAnalytics(List<Sale> sales) {
    double totalRevenue = 0;
    double totalCost = 0;
    int totalItems = 0;
    Map<String, int> hourlyStats = {};
    Map<String, double> dailyRevenue = {};
    
    for (var sale in sales) {
      totalRevenue += sale.totalAmount;
      totalItems += sale.items?.length ?? 0;
      
      // Calculate cost (assuming 70% profit margin for demo)
      totalCost += sale.totalAmount * 0.7;
      
      // Convert sale date to Thai time for analysis
      final saleDateThai = AppUtils.toThaiTime(sale.saleDate);
      
      // Hourly stats for Thai business hours analysis
      final hour = saleDateThai.hour;
      hourlyStats[hour.toString()] = (hourlyStats[hour.toString()] ?? 0) + 1;
      
      // Daily revenue for trend analysis
      final dateKey = DateFormat('dd/MM', 'th_TH').format(saleDateThai);
      dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + sale.totalAmount;
    }
    
    return {
      'totalRevenue': totalRevenue,
      'totalCost': totalCost,
      'totalProfit': totalRevenue - totalCost,
      'totalSales': sales.length,
      'totalItems': totalItems,
      'averageSale': sales.isNotEmpty ? totalRevenue / sales.length : 0.0,
      'hourlyStats': hourlyStats,
      'dailyRevenue': dailyRevenue,
      'profitMargin': totalRevenue > 0 ? ((totalRevenue - totalCost) / totalRevenue * 100) : 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _isLoading
                ? _buildLoadingWidget()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          _buildPeriodSelector(),
                          _buildSummaryCards(),
                          _buildTabSection(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.primaryDarkBlue,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'รายงานการขาย',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.primaryDarkBlue,
                AppConstants.primaryDarkBlue.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.analytics,
                  size: 120,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 400,
      child: Center(
        child: CircularProgressIndicator(
          color: AppConstants.primaryYellow,
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกช่วงเวลา',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildPeriodButton('วันนี้', 'วันนี้'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPeriodButton('สัปดาห์นี้', 'สัปดาห์นี้'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPeriodButton('เดือนนี้', 'เดือนนี้'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectStartDate,
                        icon: Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          AppUtils.formatDateThai(_startDate),
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('ถึง', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectEndDate,
                        icon: Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          AppUtils.formatDateThai(_endDate),
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    
    return ElevatedButton(
      onPressed: () => _selectPeriod(period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppConstants.primaryDarkBlue : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppConstants.primaryDarkBlue,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppConstants.primaryDarkBlue : Colors.grey[300]!,
          ),
        ),
      ),
      child: Text(label, style: TextStyle(fontSize: 12)),
    );
  }

  void _selectPeriod(String period) {
    setState(() => _selectedPeriod = period);
    
    final now = DateTime.now();
    switch (period) {
      case 'วันนี้':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'สัปดาห์นี้':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'เดือนนี้':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month, now.day);
        break;
    }
    
    _loadReportsData();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('th', 'TH'),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _selectedPeriod = ''; // Clear period selection
      });
      _loadReportsData();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('th', 'TH'),
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _selectedPeriod = ''; // Clear period selection
      });
      _loadReportsData();
    }
  }

  Widget _buildSummaryCards() {
    final totalRevenue = _salesData['totalRevenue'] ?? 0.0;
    final totalSales = _salesData['totalSales'] ?? 0;
    final totalProfit = _salesData['totalProfit'] ?? 0.0;
    final profitMargin = _salesData['profitMargin'] ?? 0.0;
    final totalItems = _salesData['totalItems'] ?? 0;
    final averageSale = _salesData['averageSale'] ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'รายได้ทั้งหมด',
                  AppUtils.formatCurrency(totalRevenue),
                  Icons.account_balance_wallet,
                  Colors.blue,
                  subtitle: '${totalSales} รายการขาย',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'จำนวนการขาย',
                  '$totalSales ครั้ง',
                  Icons.shopping_cart,
                  Colors.green,
                  subtitle: 'เฉลี่ย ${AppUtils.formatCurrency(averageSale)} ต่อรายการ',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'กำไรสุทธิ',
                  AppUtils.formatCurrency(totalProfit),
                  Icons.trending_up,
                  Colors.purple,
                  subtitle: '${profitMargin.toStringAsFixed(1)}% ของรายได้',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'จำนวนสินค้า',
                  '$totalItems หน่วย',
                  Icons.inventory,
                  Colors.orange,
                  subtitle: 'เฉลี่ย ${(totalItems / totalSales).toStringAsFixed(1)} หน่วยต่อรายการ',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppConstants.primaryDarkBlue,
                  unselectedLabelColor: Colors.grey[600],
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    color: AppConstants.primaryYellow.withOpacity(0.2),
                  ),
                  tabs: [
                    Tab(text: 'ยอดขาย'),
                    Tab(text: 'สินค้ายอดนิยม'),
                    Tab(text: 'สต็อกต่ำ'),
                    Tab(text: 'วิเคราะห์'),
                    Tab(text: 'แนะนำการสั่งซื้อ'), // New tab for reorder suggestions
                  ],
                ),
                Container(
                  height: 500, // Increased height to accommodate more content
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesTab(),
                      _buildTopProductsTab(),
                      _buildLowStockTab(),
                      _buildAnalyticsTab(),
                      _buildReorderSuggestionsTab(), // New tab
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    if (_recentSales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีข้อมูลการขาย',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentSales.length,
      itemBuilder: (context, index) {
        final sale = _recentSales[index];
        final itemCount = sale.items?.length ?? 0;
        final isHighValue = sale.totalAmount > 1000; // High value sale threshold
        
        // Get the first product image if available
        String? firstProductImage;
        if (sale.items != null && sale.items!.isNotEmpty && sale.items!.first.product != null) {
          firstProductImage = sale.items!.first.product!.image;
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isHighValue ? Colors.green.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighValue ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: firstProductImage != null && firstProductImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        firstProductImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            isHighValue ? Icons.star : Icons.receipt,
                            color: isHighValue ? Colors.green[700] : AppConstants.primaryDarkBlue,
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
                      color: isHighValue ? Colors.green[700] : AppConstants.primaryDarkBlue,
                      size: 20,
                    ),
            ),
            title: Text(
              sale.receiptNumber,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isHighValue ? Colors.green[700] : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppUtils.formatDateTimeThai(sale.saleDate), // Use Thai format
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount รายการสินค้า',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (sale.customerName != null && sale.customerName!.isNotEmpty)
                  Text(
                    'ลูกค้า: ${sale.customerName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppUtils.formatCurrency(sale.totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHighValue ? Colors.green[700] : AppConstants.primaryDarkBlue,
                  ),
                ),
                if (isHighValue)
                  Text(
                    'มูลค่าสูง',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopProductsTab() {
    // Define time period options with Thai labels
    final Map<String, List<Map<String, dynamic>>> timePeriods = {
      'วันนี้': _topSellingToday,
      'เมื่อวาน': _topSellingYesterday,
      'สัปดาห์นี้': _topSellingThisWeek,
      'เดือนนี้': _topSellingThisMonth,
      'เดือนที่แล้ว': _topSellingLastMonth,
      'ปีนี้': _topSellingThisYear,
      'ปีที่แล้ว': _topSellingLastYear,
    };
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time period filter dropdown
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'แสดงสินค้ายอดนิยมตามช่วงเวลา:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.primaryDarkBlue,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedTopProductsPeriod,
                  items: timePeriods.keys.map((String period) {
                    return DropdownMenuItem<String>(
                      value: period,
                      child: Text(
                        period,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstants.primaryDarkBlue,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTopProductsPeriod = newValue;
                      });
                    }
                  },
                  icon: Icon(Icons.arrow_drop_down, color: AppConstants.primaryDarkBlue),
                  underline: Container(),
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
          
          // Display selected period's top products
          if (timePeriods[_selectedTopProductsPeriod]!.isNotEmpty)
            _buildTopProductsSection('สินค้ายอดนิยม ($_selectedTopProductsPeriod)', timePeriods[_selectedTopProductsPeriod]!),
          
          if (timePeriods[_selectedTopProductsPeriod]!.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีข้อมูลสินค้ายอดนิยม',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection(String title, List<Map<String, dynamic>> products) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.primaryDarkBlue.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryDarkBlue,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              
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
              final productCode = _safeString(product['code']) ?? '-';
              final productImage = _safeString(product['image']);
              final totalRevenue = product['total_revenue'] is int 
                  ? product['total_revenue'].toDouble() 
                  : product['total_revenue'] as double? ?? 0.0;
              final totalQuantity = product['total_quantity'] is double
                  ? product['total_quantity'].toInt()
                  : product['total_quantity'] as int? ?? 0;
              final saleCount = product['sale_count'] is int 
                  ? product['sale_count'] as int? ?? 0
                  : (product['sale_count'] as double? ?? 0.0).toInt();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'รหัส: $productCode',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '$saleCount ครั้งการขาย • ${totalQuantity} หน่วย',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${AppUtils.formatCurrency(totalRevenue)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockTab() {
    if (_lowStockProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green[400]),
            const SizedBox(height: 16),
            Text(
              'สต็อกสินค้าเพียงพอ',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lowStockProducts.length,
      itemBuilder: (context, index) {
        final product = _lowStockProducts[index];
        final isCritical = product.quantity <= product.lowStock ~/ 2;
        final stockPercentage = (product.quantity / product.lowStock) * 100;
        
        // Safely extract string values from product, handling Blob types from MySQL
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
        
        final productImage = _safeString(product.image);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCritical ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCritical ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCritical 
                    ? Colors.red.withOpacity(0.2) 
                    : Colors.orange.withOpacity(0.2),
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
                            isCritical ? Icons.error : Icons.warning_amber,
                            color: isCritical ? Colors.red[700] : Colors.orange[700],
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
                      isCritical ? Icons.error : Icons.warning_amber,
                      color: isCritical ? Colors.red[700] : Colors.orange[700],
                      size: 20,
                    ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เหลือ ${product.quantity} ${product.unit} (จุดเตือน: ${product.lowStock})',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCritical ? Colors.red[700] : Colors.orange[700],
                  ),
                ),
                if (isCritical)
                  Text(
                    'ระดับวิกฤติ - ควรสั่งซื้อทันที',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (stockPercentage < 50)
                  Text(
                    'ระดับต่ำ - ควรพิจารณาสั่งซื้อ',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${stockPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? Colors.red[700] : Colors.orange[700],
                  ),
                ),
                Text(
                  AppUtils.formatCurrency(product.price),
                  style: TextStyle(
                    fontSize: 12,
                    color: isCritical ? Colors.red[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    final hourlyStats = _salesData['hourlyStats'] as Map<String, int>? ?? {};
    final dailyRevenue = _salesData['dailyRevenue'] as Map<String, double>? ?? {};
    final growthRate = _salesTrends['growthRate'] as double? ?? 0.0;
    final isGrowing = growthRate >= 0;
    final totalRevenue = _salesData['totalRevenue'] ?? 0.0;
    final totalCost = _salesData['totalCost'] ?? 0.0;
    final totalProfit = _salesData['totalProfit'] ?? 0.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Growth Indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isGrowing ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isGrowing ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isGrowing ? Icons.trending_up : Icons.trending_down,
                  color: isGrowing ? Colors.green[700] : Colors.red[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGrowing 
                            ? 'กำลังเติบโตอย่างดี' 
                            : 'มีแนวโน้มลดลงเล็กน้อย',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isGrowing ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      Text(
                        isGrowing
                            ? 'เพิ่มขึ้น ${growthRate.toStringAsFixed(1)}% เมื่อเทียบกับช่วงก่อน'
                            : 'ลดลง ${growthRate.abs().toStringAsFixed(1)}% เมื่อเทียบกับช่วงก่อน',
                        style: TextStyle(
                          fontSize: 12,
                          color: isGrowing ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Profit/Loss Summary Chart
          Text(
            'ภาพรวมรายได้และกำไร',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _buildProfitLossChart(totalRevenue, totalCost, totalProfit),
          ),
          const SizedBox(height: 24),
          
          // Peak Hours Analysis
          Text(
            'วิเคราะห์ช่วงเวลาที่มียอดขายดี',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: hourlyStats.isEmpty
                ? Center(
                    child: Text(
                      'ยังไม่มีข้อมูล',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.grey[800]!,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toInt()} รายการ',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final hour = value.toInt();
                              return Text(
                                '$hour:00',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: hourlyStats.entries
                          .map(
                            (entry) => BarChartGroupData(
                              x: int.tryParse(entry.key) ?? 0,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.toDouble(),
                                  color: AppConstants.primaryDarkBlue,
                                  width: 12,
                                  borderRadius: BorderRadius.zero,
                                ),
                              ],
                            ),
                          )
                          .toList(),
                      gridData: FlGridData(show: false),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          
          // Daily Sales Trend
          Text(
            'วิเคราะห์ยอดขายในแต่ละวัน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: dailyRevenue.isEmpty
                ? Center(
                    child: Text(
                      'ยังไม่มีข้อมูล',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.grey[800]!,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              return LineTooltipItem(
                                '${AppUtils.formatCurrency(touchedSpot.y)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final dates = dailyRevenue.keys.toList();
                              final index = value.toInt();
                              if (index >= 0 && index < dates.length) {
                                return Text(
                                  dates[index],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: dailyRevenue.length.toDouble() - 1,
                      minY: 0,
                      maxY: dailyRevenue.values
                              .reduce((a, b) => a > b ? a : b)
                              .toDouble() *
                          1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: dailyRevenue.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) => FlSpot(
                                    entry.key.toDouble(),
                                    (entry.value is num) 
                                        ? (entry.value as num).toDouble() 
                                        : (entry.value is String) 
                                            ? double.tryParse(entry.value as String) ?? 0.0
                                            : (entry.value is int) 
                                                ? (entry.value as int).toDouble()
                                                : 0.0
                                  ))
                              .toList(),
                          isCurved: true,
                          color: AppConstants.primaryDarkBlue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: true),
                        ),
                      ],
                      gridData: FlGridData(show: false),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          
          // Break-Even Analysis
          Text(
            'วิเคราะห์จุดคุ้มทุน (Break-Even Analysis)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _buildBreakEvenChart(totalRevenue, totalCost, totalProfit),
          ),
          const SizedBox(height: 24),
          
          // Customer Insights Section
          Text(
            'วิเคราะห์พฤติกรรมลูกค้า',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _customerHistory.isEmpty
                ? Center(
                    child: Text(
                      'ยังไม่มีข้อมูลลูกค้า',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _customerHistory.length > 5 ? 5 : _customerHistory.length,
                    itemBuilder: (context, index) {
                      final customer = _customerHistory[index];
                      // Fix type casting issue - handle both int and double types
                      final purchaseCount = customer['purchase_count'] is int 
                          ? customer['purchase_count'] as int? ?? 0
                          : (customer['purchase_count'] as double? ?? 0.0).toInt();
                      final totalSpent = customer['total_spent'] as double? ?? 0.0;
                      // Handle both String and DateTime types for lastPurchaseDate
                      final lastPurchaseDate = customer['last_purchase_date'] is DateTime
                          ? (customer['last_purchase_date'] as DateTime).toIso8601String()
                          : customer['last_purchase_date'] as String? ?? '';
                      
                      return ListTile(
                        title: Text(
                          customer['customer_name'] as String? ?? 'ไม่ระบุชื่อ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${purchaseCount} ครั้ง • ${AppUtils.formatCurrency(totalSpent)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (lastPurchaseDate.isNotEmpty)
                              _buildLastPurchaseDate(lastPurchaseDate),
                          ],
                        ),
                        trailing: Text(
                          'อันดับ ${index + 1}',
                          style: TextStyle(
                            color: AppConstants.primaryDarkBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // Inventory Movement Analysis
          Text(
            'วิเคราะห์การเคลื่อนไหวของสต็อก',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _inventoryMovement['inventoryData'] == null || 
                   (_inventoryMovement['inventoryData'] as List).isEmpty
                ? Center(
                    child: Text(
                      'ยังไม่มีข้อมูลการเคลื่อนไหวของสต็อก',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: (_inventoryMovement['inventoryData'] as List).length > 5 
                        ? 5 
                        : (_inventoryMovement['inventoryData'] as List).length,
                    itemBuilder: (context, index) {
                      final item = (_inventoryMovement['inventoryData'] as List)[index];
                      final productName = item['name'] as String? ?? 'ไม่ระบุชื่อ';
                      // Fix type casting issue - handle both int and double types
                      final soldQuantity = item['sold_quantity'] is int 
                          ? item['sold_quantity'] as int? ?? 0
                          : (item['sold_quantity'] as double? ?? 0.0).toInt();
                      // Fix type casting issue - handle both int and double types
                      final receivedQuantity = item['received_quantity'] is int 
                          ? item['received_quantity'] as int? ?? 0
                          : (item['received_quantity'] as double? ?? 0.0).toInt();
                      
                      return ListTile(
                        title: Text(
                          productName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ขาย: $soldQuantity หน่วย',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
                            ),
                            Text(
                              'รับเข้า: $receivedQuantity หน่วย',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              soldQuantity > receivedQuantity 
                                  ? Icons.trending_down 
                                  : Icons.trending_up,
                              color: soldQuantity > receivedQuantity 
                                  ? Colors.red 
                                  : Colors.green,
                              size: 16,
                            ),
                            Text(
                              '${(soldQuantity - receivedQuantity).abs()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: soldQuantity > receivedQuantity 
                                    ? Colors.red 
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // Customer Segmentation
          Text(
            'การแบ่งกลุ่มลูกค้า',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          if (_customerSegmentation.isEmpty || _customerSegmentation['segments'] == null)
            Center(
              child: Text(
                'ยังไม่มีข้อมูลการแบ่งกลุ่มลูกค้า',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: ((_customerSegmentation['segments'] as Map)['highValue'] is num
                          ? (_customerSegmentation['segments'] as Map)['highValue']?.toDouble()
                          : (_customerSegmentation['segments'] as Map)['highValue'] is String
                              ? double.tryParse((_customerSegmentation['segments'] as Map)['highValue'] as String) ?? 0
                              : 0) ?? 0,
                      title: 'ลูกค้ามูลค่าสูง',
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.blue,
                      value: ((_customerSegmentation['segments'] as Map)['mediumValue'] is num
                          ? (_customerSegmentation['segments'] as Map)['mediumValue']?.toDouble()
                          : (_customerSegmentation['segments'] as Map)['mediumValue'] is String
                              ? double.tryParse((_customerSegmentation['segments'] as Map)['mediumValue'] as String) ?? 0
                              : 0) ?? 0,
                      title: 'ลูกค้ามูลค่าปานกลาง',
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: ((_customerSegmentation['segments'] as Map)['lowValue'] is num
                          ? (_customerSegmentation['segments'] as Map)['lowValue']?.toDouble()
                          : (_customerSegmentation['segments'] as Map)['lowValue'] is String
                              ? double.tryParse((_customerSegmentation['segments'] as Map)['lowValue'] as String) ?? 0
                              : 0) ?? 0,
                      title: 'ลูกค้ามูลค่าต่ำ',
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReorderSuggestionsTab() {
    if (_reorderSuggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ไม่มีคำแนะนำการสั่งซื้อในขณะนี้',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reorderSuggestions.length,
      itemBuilder: (context, index) {
        final product = _reorderSuggestions[index];
        
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
        
        final productName = _safeString(product['name']) ?? 'ไม่ระบุชื่อ';
        final productCode = _safeString(product['code']) ?? '';
        final productImage = _safeString(product['image']);
        // Fix type casting issue - handle both int and double types
        final currentQuantity = product['quantity'] is int 
            ? product['quantity'] as int? ?? 0
            : (product['quantity'] as double? ?? 0.0).toInt();
        // Fix type casting issue - handle both int and double types
        final lowStockLevel = product['low_stock'] is int 
            ? product['low_stock'] as int? ?? 0
            : (product['low_stock'] as double? ?? 0.0).toInt();
        final unit = _safeString(product['unit']) ?? 'หน่วย';
        final avgDailySales = product['avg_daily_sales'] as double? ?? 0.0;
        final daysUntilOutOfStock = product['days_until_out_of_stock'] as double? ?? 999.0;
        
        // Determine urgency level
        Color urgencyColor = Colors.green;
        String urgencyText = 'ปลอดภัย';
        IconData urgencyIcon = Icons.check_circle;
        
        if (daysUntilOutOfStock <= 3) {
          urgencyColor = Colors.red;
          urgencyText = 'เร่งด่วน';
          urgencyIcon = Icons.error;
        } else if (daysUntilOutOfStock <= 7) {
          urgencyColor = Colors.orange;
          urgencyText = 'ควรสั่งซื้อ';
          urgencyIcon = Icons.warning;
        } else if (daysUntilOutOfStock <= 14) {
          urgencyColor = Colors.blue;
          urgencyText = 'ต้องเฝ้าระวัง';
          urgencyIcon = Icons.info;
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.1),
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
                            urgencyIcon,
                            color: urgencyColor,
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
                      urgencyIcon,
                      color: urgencyColor,
                      size: 20,
                    ),
            ),
            title: Text(
              productName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'รหัส: $productCode',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: Text(
              urgencyText,
              style: TextStyle(
                color: urgencyColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'สต็อกปัจจุบัน',
                            '$currentQuantity $unit',
                            Icons.inventory,
                            AppConstants.primaryDarkBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'จุดสั่งซื้อ',
                            '$lowStockLevel $unit',
                            Icons.warning,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'ขาย/วัน',
                            '${avgDailySales.toStringAsFixed(1)} $unit',
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'หมดสต็อกใน',
                            '${daysUntilOutOfStock.toStringAsFixed(0)} วัน',
                            Icons.calendar_today,
                            urgencyColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastPurchaseDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return Text(
        'ซื้อล่าสุด: ${AppUtils.formatDateThai(date)}',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[500],
        ),
      );
    } catch (e) {
      // Handle parsing error gracefully
      return Text(
        'ซื้อล่าสุด: ไม่สามารถแสดงวันที่ได้',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[500],
        ),
      );
    }
  }

  Widget _buildProfitLossChart(double totalRevenue, double totalCost, double totalProfit) {
    // If no data, show empty state
    if (totalRevenue == 0 && totalCost == 0 && totalProfit == 0) {
      return Center(
        child: Text(
          'ยังไม่มีข้อมูลรายได้และกำไร',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.grey[800]!,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label = '';
              switch (groupIndex) {
                case 0:
                  label = 'รายได้';
                  break;
                case 1:
                  label = 'ต้นทุน';
                  break;
                case 2:
                  label = 'กำไร';
                  break;
              }
              return BarTooltipItem(
                '$label\n${AppUtils.formatCurrency(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return Text('รายได้', style: TextStyle(fontSize: 10, color: Colors.grey[600]));
                  case 1:
                    return Text('ต้นทุน', style: TextStyle(fontSize: 10, color: Colors.grey[600]));
                  case 2:
                    return Text('กำไร', style: TextStyle(fontSize: 10, color: Colors.grey[600]));
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  AppUtils.formatCurrency(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: totalRevenue,
                color: Colors.green,
                width: 20,
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: totalCost,
                color: Colors.red,
                width: 20,
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: totalProfit,
                color: totalProfit >= 0 ? Colors.blue : Colors.orange,
                width: 20,
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
        ],
        gridData: FlGridData(show: true),
      ),
    );
  }

  Widget _buildBreakEvenChart(double totalRevenue, double totalCost, double totalProfit) {
    // If no data, show empty state
    if (totalRevenue == 0 && totalCost == 0) {
      return Center(
        child: Text(
          'ยังไม่มีข้อมูลสำหรับการวิเคราะห์จุดคุ้มทุน',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    // Calculate break-even point (simplified)
    final double breakEvenPoint = totalCost > 0 ? (totalCost / totalRevenue) * 100 : 0.0;
    final double profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.red,
            value: breakEvenPoint.toDouble(),
            title: 'ต้นทุน\n${breakEvenPoint.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.green,
            value: (100 - breakEvenPoint).toDouble(),
            title: 'กำไร\n${profitMargin.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}