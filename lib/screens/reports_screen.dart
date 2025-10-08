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
  
  String _selectedPeriod = 'วันนี้';
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
  
  // New analytics data
  Map<String, dynamic> _domesticExportData = {};
  Map<String, dynamic> _historicalProjectedData = {};
  List<Map<String, dynamic>> _paymentMethodData = [];
  List<Map<String, dynamic>> _categoryPerformanceData = [];
  
  // Top products filter
  String _selectedTopProductsPeriod = 'ทั้งหมด';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final app = Provider.of<AppProvider>(context, listen: false);
      
      if (auth.currentUser?.id == null) return;
      
      await app.loadProducts(auth.currentUser!.id!);
      final filteredSales = await app.getSalesByDateRange(auth.currentUser!.id!, _startDate, _endDate);
      
      final salesWithItems = <Sale>[];
      for (var sale in filteredSales) {
        try {
          final items = await app.getSaleItemsWithProducts(sale.id!);
          salesWithItems.add(sale.copyWith(items: items));
        } catch (e) {
          salesWithItems.add(sale);
        }
      }
      
      _recentSales = salesWithItems.take(10).toList();
      _salesData = _calculateSalesAnalytics(filteredSales);
      _topProducts = app.products.take(5).toList();
      _lowStockProducts = await app.getLowStockProducts(auth.currentUser!.id!);
      await _loadAdvancedAnalytics(auth.currentUser!.id!);
      
    } catch (e) {
      _showErrorMessage(context, 'เกิดข้อผิดพลาดในการโหลดข้อมูล: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAdvancedAnalytics(int userId) async {
    try {
      final app = Provider.of<AppProvider>(context, listen: false);
      
      // Load top selling products based on selected period
      DateTime topProductsStartDate, topProductsEndDate;
      final now = DateTime.now();
      
      switch (_selectedTopProductsPeriod) {
        case 'วันนี้':
          topProductsStartDate = DateTime(now.year, now.month, now.day);
          topProductsEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'เมื่อวาน':
          final yesterday = now.subtract(Duration(days: 1));
          topProductsStartDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          topProductsEndDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
          break;
        case 'สัปดาห์นี้':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(Duration(days: 6));
          topProductsStartDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          topProductsEndDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
          break;
        case 'สัปดาห์ที่แล้ว':
          final startOfLastWeek = now.subtract(Duration(days: now.weekday - 1 + 7));
          final endOfLastWeek = startOfLastWeek.add(Duration(days: 6));
          topProductsStartDate = DateTime(startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day);
          topProductsEndDate = DateTime(endOfLastWeek.year, endOfLastWeek.month, endOfLastWeek.day, 23, 59, 59);
          break;
        case 'เดือนนี้':
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
          topProductsStartDate = DateTime(now.year, now.month, 1);
          topProductsEndDate = DateTime(lastDayOfMonth.year, lastDayOfMonth.month, lastDayOfMonth.day, 23, 59, 59);
          break;
        case 'เดือนที่แล้ว':
          final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
          final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
          topProductsStartDate = DateTime(firstDayOfLastMonth.year, firstDayOfLastMonth.month, firstDayOfLastMonth.day);
          topProductsEndDate = DateTime(lastDayOfLastMonth.year, lastDayOfLastMonth.month, lastDayOfLastMonth.day, 23, 59, 59);
          break;
        default: // 'ทั้งหมด'
          // For all time, we use a wide range
          topProductsStartDate = DateTime(2000);
          topProductsEndDate = DateTime(2100);
          break;
      }
      
      _topSellingProducts = await app.getTopSellingProducts(userId, topProductsStartDate, topProductsEndDate, limit: 10);
      _customerHistory = await app.getCustomerPurchaseHistory(userId, limit: 20);
      _reorderSuggestions = await app.getReorderSuggestions(userId);
      _hourlySalesData = await app.getSalesByHour(userId, _startDate, _endDate);
      _dailySalesData = await app.getSalesByDay(userId, _startDate, _endDate);
      _inventoryMovement = await app.getInventoryMovement(userId, _startDate, _endDate);
      _salesTrends = await app.getSalesTrends(userId, _startDate, _endDate);
      _productPerformance = await app.getProductPerformance(userId, _startDate, _endDate, limit: 15);
      _customerSegmentation = await app.getCustomerSegmentation(userId, limit: 100);
      
      // Load new analytics data
      _domesticExportData = await app.getDomesticExportSales(userId, _startDate, _endDate);
      _historicalProjectedData = await app.getHistoricalProjectedRevenue(userId, _startDate, _endDate);
      _paymentMethodData = await app.getPaymentMethodDistribution(userId, _startDate, _endDate);
      _categoryPerformanceData = await app.getCategoryPerformanceForRadar(userId, _startDate, _endDate);
      
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
      totalCost += sale.totalAmount * 0.7;
      
      final saleDateThai = AppUtils.toThaiTime(sale.saleDate);
      final hour = saleDateThai.hour;
      hourlyStats[hour.toString()] = (hourlyStats[hour.toString()] ?? 0) + 1;
      
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
      backgroundColor: const Color(0xFFF5F7FA),
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
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.primaryDarkBlue,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'รายงานการขาย',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryDarkBlue,
                    AppConstants.primaryDarkBlue.withOpacity(0.85),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 50,
              child: Icon(
                Icons.analytics_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 500,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryYellow.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                color: AppConstants.primaryYellow,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'กำลังโหลดข้อมูล...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.date_range,
                  color: AppConstants.primaryDarkBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'เลือกช่วงเวลา',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryDarkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // First row - today, yesterday, this week
          Row(
            children: [
              Expanded(child: _buildPeriodChip('วันนี้', Icons.today)),
              const SizedBox(width: 10),
              Expanded(child: _buildPeriodChip('เมื่อวาน', Icons.calendar_today)),
              const SizedBox(width: 10),
              Expanded(child: _buildPeriodChip('สัปดาห์นี้', Icons.view_week)),
            ],
          ),
          const SizedBox(height: 10),
          // Second row - last week, this month, last month
          Row(
            children: [
              Expanded(child: _buildPeriodChip('สัปดาห์ที่แล้ว', Icons.date_range)),
              const SizedBox(width: 10),
              Expanded(child: _buildPeriodChip('เดือนนี้', Icons.calendar_month)),
              const SizedBox(width: 10),
              Expanded(child: _buildPeriodChip('เดือนที่แล้ว', Icons.event)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    _startDate,
                    'วันเริ่มต้น',
                    _selectStartDate,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, size: 20, color: Colors.grey[600]),
                ),
                Expanded(
                  child: _buildDateButton(
                    _endDate,
                    'วันสิ้นสุด',
                    _selectEndDate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String period, IconData icon) {
    final isSelected = _selectedPeriod == period;
    
    return Material(
      color: isSelected ? AppConstants.primaryDarkBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _selectPeriod(period),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppConstants.primaryDarkBlue : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                period,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(DateTime date, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppConstants.primaryDarkBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppUtils.formatDateThai(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryDarkBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectPeriod(String period) {
    setState(() => _selectedPeriod = period);
    
    final now = DateTime.now();
    switch (period) {
      case 'วันนี้':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'เมื่อวาน':
        final yesterday = now.subtract(Duration(days: 1));
        _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        _endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'สัปดาห์นี้':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        _startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _endDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
        break;
      case 'สัปดาห์ที่แล้ว':
        final startOfLastWeek = now.subtract(Duration(days: now.weekday - 1 + 7));
        final endOfLastWeek = startOfLastWeek.add(Duration(days: 6));
        _startDate = DateTime(startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day);
        _endDate = DateTime(endOfLastWeek.year, endOfLastWeek.month, endOfLastWeek.day, 23, 59, 59);
        break;
      case 'เดือนนี้':
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(lastDayOfMonth.year, lastDayOfMonth.month, lastDayOfMonth.day, 23, 59, 59);
        break;
      case 'เดือนที่แล้ว':
        final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
        _startDate = DateTime(firstDayOfLastMonth.year, firstDayOfLastMonth.month, firstDayOfLastMonth.day);
        _endDate = DateTime(lastDayOfLastMonth.year, lastDayOfLastMonth.month, lastDayOfLastMonth.day, 23, 59, 59);
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
        _selectedPeriod = '';
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
        _selectedPeriod = '';
      });
      _loadReportsData();
    }
  }

  Widget _buildSummaryCards() {
    final totalRevenue = _salesData['totalRevenue'] ?? 0.0;
    final totalSales = _salesData['totalSales'] ?? 0;
    final totalProfit = _salesData['totalProfit'] ?? 0.0;
    final profitMargin = _salesData['profitMargin'] ?? 0.0;
    
    // Add a link to payment history at the top
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Link to payment history
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.paymentHistoryRoute);
              },
              icon: const Icon(Icons.history, size: 20),
              label: const Text('ดูประวัติการชำระเงินทั้งหมด'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppConstants.primaryDarkBlue,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildModernSummaryCard(
                  'รายได้ทั้งหมด',
                  AppUtils.formatCurrency(totalRevenue),
                  Icons.account_balance_wallet_outlined,
                  LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                  '$totalSales รายการ',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernSummaryCard(
                  'กำไรสุทธิ',
                  AppUtils.formatCurrency(totalProfit),
                  Icons.trending_up,
                  LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                  ),
                  '${profitMargin.toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFullWidthSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildModernSummaryCard(
    String title,
    String value,
    IconData icon,
    Gradient gradient,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Icon(Icons.arrow_forward, color: Colors.white.withOpacity(0.7), size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthSummaryCard() {
    final totalSales = _salesData['totalSales'] ?? 0;
    final averageSale = _salesData['averageSale'] ?? 0.0;
    final totalItems = _salesData['totalItems'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStat(
              'จำนวนการขาย',
              '$totalSales',
              Icons.shopping_cart_outlined,
              Colors.orange,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
            child: _buildMiniStat(
              'ค่าเฉลี่ย/ครั้ง',
              AppUtils.formatCurrency(averageSale),
              Icons.receipt_long,
              Colors.purple,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
            child: _buildMiniStat(
              'จำนวนสินค้า',
              '$totalItems',
              Icons.inventory_2_outlined,
              Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryDarkBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppConstants.primaryDarkBlue,
              unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: AppConstants.primaryYellow,
                  width: 3,
                ),
              ),
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.receipt_long, size: 20), text: 'ยอดขาย'),
                Tab(icon: Icon(Icons.star, size: 20), text: 'สินค้ายอดนิยม'),
                Tab(icon: Icon(Icons.warning_amber, size: 20), text: 'สต็อกต่ำ'),
                Tab(icon: Icon(Icons.analytics, size: 20), text: 'วิเคราะห์'),
                Tab(icon: Icon(Icons.shopping_cart, size: 20), text: 'แนะนำสั่งซื้อ'),
              ],
            ),
          ),
          SizedBox(
            height: 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(),
                _buildTopProductsTab(),
                _buildLowStockTab(),
                _buildAnalyticsTab(),
                _buildReorderSuggestionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Continuing with improved tab content methods...
  Widget _buildSalesTab() {
    if (_recentSales.isEmpty) {
      return _buildEmptyState(
        Icons.receipt_long,
        'ยังไม่มีข้อมูลการขาย',
        'ข้อมูลการขายจะแสดงที่นี่เมื่อมีรายการขาย',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentSales.length,
      itemBuilder: (context, index) {
        final sale = _recentSales[index];
        final itemCount = sale.items?.length ?? 0;
        final isHighValue = sale.totalAmount > 1000;
        
        // Get the first product image if available
        String? firstProductImage;
        if (sale.items != null && sale.items!.isNotEmpty && sale.items!.first.product != null) {
          firstProductImage = sale.items!.first.product!.image;
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighValue ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
              width: isHighValue ? 2 : 1,
            ),
            boxShadow: isHighValue
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isHighValue
                      ? [Colors.green, Colors.green.shade700]
                      : [Colors.blue.shade100, Colors.blue.shade200],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: firstProductImage != null && firstProductImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        firstProductImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            isHighValue ? Icons.star : Icons.receipt,
                            color: isHighValue ? Colors.white : Colors.blue.shade700,
                            size: 24,
                          );
                        },
                        headers: const {
                          'Accept': 'image/*',
                        },
                      ),
                    )
                  : Icon(
                      isHighValue ? Icons.star : Icons.receipt,
                      color: isHighValue ? Colors.white : Colors.blue.shade700,
                      size: 24,
                    ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    sale.receiptNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isHighValue) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      'มูลค่าสูง',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  AppUtils.formatDateTimeThai(sale.saleDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '$itemCount รายการ',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    if (sale.customerName != null && sale.customerName!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          sale.customerName!,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppUtils.formatCurrency(sale.totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isHighValue ? Colors.green.shade700 : AppConstants.primaryDarkBlue,
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
    // Define time period options
    final List<String> timePeriods = [
      'ทั้งหมด',
      'วันนี้',
      'เมื่อวาน',
      'สัปดาห์นี้',
      'สัปดาห์ที่แล้ว',
      'เดือนนี้',
      'เดือนที่แล้ว',
    ];
    
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
                  'แสดงสินค้ายอดนิยม:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.primaryDarkBlue,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedTopProductsPeriod,
                  items: timePeriods.map((String period) {
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
                      _loadAdvancedAnalytics(Provider.of<AuthProvider>(context, listen: false).currentUser!.id!);
                    }
                  },
                  icon: Icon(Icons.arrow_drop_down, color: AppConstants.primaryDarkBlue),
                  underline: Container(),
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
          
          // Top products list
          if (_topSellingProducts.isEmpty)
            _buildEmptyState(
              Icons.inventory_2,
              'ยังไม่มีข้อมูลสินค้ายอดนิยม',
              'ข้อมูลจะแสดงเมื่อมีการขายสินค้า',
            )
          else
            Container(
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
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      'สินค้ายอดนิยม ($_selectedTopProductsPeriod)',
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
                    itemCount: _topSellingProducts.length,
                    itemBuilder: (context, index) {
                      final product = _topSellingProducts[index];
                      
                      String? _safeString(dynamic value) {
                        if (value == null) return null;
                        if (value is List<int>) return String.fromCharCodes(value);
                        if (value is String) return value.isEmpty ? null : value;
                        return value.toString();
                      }
                      
                      final productName = _safeString(product['name']) ?? 'ไม่ระบุ';
                      final productImage = _safeString(product['image']);
                      final totalRevenue = (product['total_revenue'] is int 
                          ? product['total_revenue'].toDouble() 
                          : product['total_revenue'] as double?) ?? 0.0;
                      final totalQuantity = (product['total_quantity'] is double
                          ? product['total_quantity'].toInt()
                          : product['total_quantity'] as int?) ?? 0;
                      
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppConstants.primaryYellow,
                                    AppConstants.primaryYellow.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: productImage != null && productImage.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        productImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: AppConstants.primaryDarkBlue,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          );
                                        },
                                        headers: const {
                                          'Accept': 'image/*',
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: AppConstants.primaryDarkBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '$totalQuantity หน่วย',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                AppUtils.formatCurrency(totalRevenue),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLowStockTab() {
    if (_lowStockProducts.isEmpty) {
      return _buildEmptyState(
        Icons.check_circle_outline,
        'สต็อกสินค้าเพียงพอ',
        'ไม่มีสินค้าที่ต้องเตือนในขณะนี้',
        color: Colors.green,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCritical
                  ? [Colors.red.shade50, Colors.red.shade50]
                  : [Colors.orange.shade50, Colors.orange.shade50],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCritical ? Colors.red.shade200 : Colors.orange.shade200,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCritical
                        ? [Colors.red.shade200, Colors.red.shade400]
                        : [Colors.orange.shade200, Colors.orange.shade400],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: productImage != null && productImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          productImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              isCritical ? Icons.error : Icons.warning_amber,
                              color: isCritical ? Colors.white : Colors.white,
                              size: 24,
                            );
                          },
                          headers: const {
                            'Accept': 'image/*',
                          },
                        ),
                      )
                    : Icon(
                        isCritical ? Icons.error : Icons.warning_amber,
                        color: isCritical ? Colors.white : Colors.white,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCritical ? Colors.red.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'เหลือ ${product.quantity} ${product.unit}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCritical ? Colors.red.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${stockPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    AppUtils.formatCurrency(product.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCritical ? Colors.red.shade700 : Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCritical ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCritical ? 'วิกฤติ' : 'ต่ำ',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    final growthRate = _salesTrends['growthRate'] as double? ?? 0.0;
    final isGrowing = growthRate >= 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Growth indicator card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isGrowing
                    ? [Colors.green.shade50, Colors.green.shade100]
                    : [Colors.red.shade50, Colors.red.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isGrowing ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isGrowing ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGrowing ? Icons.trending_up : Icons.trending_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGrowing ? 'เติบโตดี' : 'ลดลงเล็กน้อย',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isGrowing ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isGrowing ? '+' : ''}${growthRate.toStringAsFixed(1)}% เมื่อเทียบกับช่วงก่อน',
                        style: TextStyle(
                          fontSize: 12,
                          color: isGrowing ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Charts section header
          _buildSectionHeader('กราฟวิเคราะห์', Icons.bar_chart),
          const SizedBox(height: 12),
          
          // Daily Sales Trend Chart (Improved from Hourly)
          _buildChartCard(
            'แนวโน้มยอดขายรายวัน',
            200,
            _buildDailySalesTrendChart(),
          ),
          const SizedBox(height: 16),
          
          // Revenue vs Profit Chart (Improved Profit/Loss Chart)
          _buildChartCard(
            'รายได้ vs กำไร',
            200,
            _buildRevenueProfitChart(),
          ),
          const SizedBox(height: 16),
          
          // Product Category Performance Chart
          _buildChartCard(
            'ประสิทธิภาพตามหมวดหมู่สินค้า',
            200,
            _buildCategoryPerformanceChart(),
          ),
          const SizedBox(height: 16),
          
          // Customer Segmentation Chart
          _buildChartCard(
            'การแบ่งกลุ่มลูกค้า',
            200,
            _buildCustomerSegmentationChart(),
          ),
          const SizedBox(height: 16),
          
          // Domestic and Export Sales Growth Chart
          _buildChartCard(
            'ยอดขายในประเทศ vs ต่างประเทศ',
            250,
            _buildDomesticExportSalesChart(),
          ),
          const SizedBox(height: 16),
          
          // Historical and Projected Revenue Chart
          _buildChartCard(
            'รายได้ในอดีตและการคาดการณ์',
            250,
            _buildHistoricalProjectedRevenueChart(),
          ),
          const SizedBox(height: 16),
          
          // Payment Method Distribution Pie Chart
          _buildChartCard(
            'การกระจายตามวิธีการชำระเงิน',
            250,
            _buildPaymentMethodPieChart(),
          ),
          const SizedBox(height: 16),
          
          // Category Performance Bar Chart
          _buildChartCard(
            'ประสิทธิภาพตามหมวดหมู่สินค้า (เปอร์เซ็นต์)',
            250,
            _buildCategoryPerformanceRadarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderSuggestionsTab() {
    if (_reorderSuggestions.isEmpty) {
      return _buildEmptyState(
        Icons.check_circle_outline,
        'ไม่มีสินค้าที่ต้องสั่งซื้อ',
        'สินค้าทั้งหมดมีสต็อกเพียงพอในขณะนี้',
        color: Colors.green,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reorderSuggestions.length,
      itemBuilder: (context, index) {
        final product = _reorderSuggestions[index];
        
        String? _safeString(dynamic value) {
          if (value == null) return null;
          if (value is List<int>) return String.fromCharCodes(value);
          if (value is String) return value.isEmpty ? null : value;
          return value.toString();
        }
        
        final productName = _safeString(product['name']) ?? 'ไม่ระบุชื่อ';
        final productImage = _safeString(product['image']);
        final currentQuantity = (product['quantity'] is int 
            ? product['quantity'] as int? 
            : (product['quantity'] as double?)?.toInt()) ?? 0;
        final daysUntilOutOfStock = (product['days_until_out_of_stock'] as double?) ?? 999.0;
        
        Color urgencyColor = Colors.green;
        String urgencyText = 'สต็อกเพียงพอ';
        IconData urgencyIcon = Icons.check_circle;
        
        if (daysUntilOutOfStock <= 3) {
          urgencyColor = Colors.red;
          urgencyText = 'สั่งซื้อทันที';
          urgencyIcon = Icons.error;
        } else if (daysUntilOutOfStock <= 7) {
          urgencyColor = Colors.orange;
          urgencyText = 'สั่งซื้อเร็วๆ นี้';
          urgencyIcon = Icons.warning;
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: urgencyColor.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        urgencyColor.withOpacity(0.2),
                        urgencyColor.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: productImage != null && productImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            productImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(urgencyIcon, color: urgencyColor, size: 24);
                            },
                            headers: const {
                              'Accept': 'image/*',
                            },
                          ),
                        )
                      : Icon(urgencyIcon, color: urgencyColor, size: 24),
                ),
                title: Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'สต็อกปัจจุบัน: $currentQuantity หน่วย',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    urgencyText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'หมดสต็อกใน',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          Text(
                            '${daysUntilOutOfStock.toStringAsFixed(0)} วัน',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: urgencyColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: Colors.grey[400], size: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle, {Color? color}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (color ?? Colors.grey).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: color ?? Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryDarkBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppConstants.primaryDarkBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryDarkBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(String title, double height, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }

  Widget _buildProfitLossChart(double totalRevenue, double totalCost, double totalProfit) {
    if (totalRevenue == 0) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: totalRevenue * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['รายได้', 'ต้นทุน', 'กำไร'];
                return Text(
                  titles[value.toInt()],
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: totalRevenue, color: Colors.blue, width: 40)],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: totalCost, color: Colors.orange, width: 40)],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: totalProfit, color: Colors.green, width: 40)],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart() {
    final hourlyStats = _salesData['hourlyStats'] as Map<String, int>? ?? {};
    
    if (hourlyStats.isEmpty) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: hourlyStats.entries.map((entry) {
          return BarChartGroupData(
            x: int.parse(entry.key),
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: AppConstants.primaryDarkBlue,
                width: 16,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // New chart implementations
  Widget _buildDailySalesTrendChart() {
    final dailyData = _dailySalesData['dailyData'] as List? ?? [];
    
    if (dailyData.isEmpty) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    // Sort by date and take last 7 days
    final sortedData = List.from(dailyData)..sort((a, b) {
      // Handle both String and DateTime types for sale_day
      DateTime dateA, dateB;
      
      if (a['sale_day'] is DateTime) {
        dateA = a['sale_day'] as DateTime;
      } else if (a['sale_day'] is String) {
        dateA = DateTime.parse(a['sale_day'] as String);
      } else {
        // Fallback for other types
        dateA = DateTime.now();
      }
      
      if (b['sale_day'] is DateTime) {
        dateB = b['sale_day'] as DateTime;
      } else if (b['sale_day'] is String) {
        dateB = DateTime.parse(b['sale_day'] as String);
      } else {
        // Fallback for other types
        dateB = DateTime.now();
      }
      
      return dateA.compareTo(dateB);
    });
    
    final recentData = sortedData.length > 7 
        ? sortedData.sublist(sortedData.length - 7) 
        : sortedData;
    
    final List<FlSpot> spots = [];
    for (int i = 0; i < recentData.length; i++) {
      final revenue = (recentData[i]['total_revenue'] as double?) ?? 0.0;
      spots.add(FlSpot(i.toDouble(), revenue));
    }
    
    if (spots.isEmpty) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppConstants.primaryDarkBlue,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: AppConstants.primaryDarkBlue.withOpacity(0.2),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppConstants.primaryDarkBlue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < recentData.length) {
                  // Handle both String and DateTime types for sale_day
                  DateTime date;
                  final saleDay = recentData[value.toInt()]['sale_day'];
                  
                  if (saleDay is DateTime) {
                    date = saleDay;
                  } else if (saleDay is String) {
                    date = DateTime.parse(saleDay);
                  } else {
                    // Fallback for other types
                    date = DateTime.now();
                  }
                  
                  return Text(
                    DateFormat('dd/MM', 'th_TH').format(date),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  AppUtils.formatCurrency(value),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
        gridData: FlGridData(
          show: true,
          horizontalInterval: (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) / 5),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildRevenueProfitChart() {
    final totalRevenue = _salesData['totalRevenue'] ?? 0.0;
    final totalProfit = _salesData['totalProfit'] ?? 0.0;
    
    if (totalRevenue == 0) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: totalRevenue * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['รายได้', 'กำไร'];
                return Text(
                  titles[value.toInt()],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  AppUtils.formatCurrency(value),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: totalRevenue,
                color: AppConstants.primaryDarkBlue,
                width: 40,
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: totalProfit,
                color: Colors.green,
                width: 40,
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformanceChart() {
    // Group products by category and sum their revenue
    final Map<String, double> categoryRevenue = {};
    
    for (var product in _topSellingProducts) {
      String? category = product['category'] as String?;
      if (category == null || category.isEmpty) {
        category = 'ไม่ระบุหมวดหมู่';
      }
      
      final revenue = (product['total_revenue'] as num?)?.toDouble() ?? 0.0;
      categoryRevenue[category] = (categoryRevenue[category] ?? 0.0) + revenue;
    }
    
    if (categoryRevenue.isEmpty) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    // Sort categories by revenue and take top 5
    final sortedCategories = categoryRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCategories = sortedCategories.length > 5 
        ? sortedCategories.sublist(0, 5) 
        : sortedCategories;
    
    return PieChart(
      PieChartData(
        sections: List.generate(topCategories.length, (index) {
          final category = topCategories[index];
          final percentage = (category.value / categoryRevenue.values.reduce((a, b) => a + b)) * 100;
          
          // Generate colors for each category
          final colors = [
            AppConstants.primaryDarkBlue,
            AppConstants.primaryYellow,
            AppConstants.accentOrange,
            AppConstants.successGreen,
            AppConstants.softBlue,
          ];
          
          return PieChartSectionData(
            value: category.value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 50,
            color: colors[index % colors.length],
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildCustomerSegmentationChart() {
    final segments = _customerSegmentation['segments'] as Map<String, dynamic>? ?? {};
    
    final highValue = segments['highValue'] as int? ?? 0;
    final mediumValue = segments['mediumValue'] as int? ?? 0;
    final lowValue = segments['lowValue'] as int? ?? 0;
    
    final totalCustomers = highValue + mediumValue + lowValue;
    
    if (totalCustomers == 0) {
      return Center(
        child: Text('ยังไม่มีข้อมูลลูกค้า', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: totalCustomers.toDouble() * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['สูง', 'กลาง', 'ต่ำ'];
                return Text(
                  titles[value.toInt()],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: highValue.toDouble(),
                color: Colors.green,
                width: 30,
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: mediumValue.toDouble(),
                color: AppConstants.primaryYellow,
                width: 30,
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: lowValue.toDouble(),
                color: Colors.grey,
                width: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New chart implementations for requested graph types

  /// Domestic and Export Sales Growth Financial Graph
  Widget _buildDomesticExportSalesChart() {
    final dailyData = _domesticExportData['dailyData'] as List? ?? [];
    
    if (dailyData.isEmpty) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    // Sort by date and take last 7 days
    final sortedData = List.from(dailyData)..sort((a, b) {
      DateTime dateA, dateB;
      
      if (a['sale_day'] is DateTime) {
        dateA = a['sale_day'] as DateTime;
      } else if (a['sale_day'] is String) {
        dateA = DateTime.parse(a['sale_day'] as String);
      } else {
        dateA = DateTime.now();
      }
      
      if (b['sale_day'] is DateTime) {
        dateB = b['sale_day'] as DateTime;
      } else if (b['sale_day'] is String) {
        dateB = DateTime.parse(b['sale_day'] as String);
      } else {
        dateB = DateTime.now();
      }
      
      return dateA.compareTo(dateB);
    });
    
    final recentData = sortedData.length > 7 
        ? sortedData.sublist(sortedData.length - 7) 
        : sortedData;
    
    final List<FlSpot> domesticSpots = [];
    final List<FlSpot> exportSpots = [];
    
    for (int i = 0; i < recentData.length; i++) {
      final domesticRevenue = (recentData[i]['domestic_revenue'] as double?) ?? 0.0;
      final exportRevenue = (recentData[i]['export_revenue'] as double?) ?? 0.0;
      
      domesticSpots.add(FlSpot(i.toDouble(), domesticRevenue));
      exportSpots.add(FlSpot(i.toDouble(), exportRevenue));
    }
    
    if (domesticSpots.isEmpty && exportSpots.isEmpty) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: domesticSpots,
            isCurved: true,
            color: AppConstants.primaryDarkBlue,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: AppConstants.primaryDarkBlue.withOpacity(0.2),
            ),
            dotData: FlDotData(
              show: true,
            ),
          ),
          LineChartBarData(
            spots: exportSpots,
            isCurved: true,
            color: AppConstants.accentOrange,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: AppConstants.accentOrange.withOpacity(0.2),
            ),
            dotData: FlDotData(
              show: true,
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < recentData.length) {
                  DateTime date;
                  final saleDay = recentData[value.toInt()]['sale_day'];
                  
                  if (saleDay is DateTime) {
                    date = saleDay;
                  } else if (saleDay is String) {
                    date = DateTime.parse(saleDay);
                  } else {
                    date = DateTime.now();
                  }
                  
                  return Text(
                    DateFormat('dd/MM', 'th_TH').format(date),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  AppUtils.formatCurrency(value),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
        gridData: FlGridData(show: true),
      ),
    );
  }

  /// Financial Graph Historical and Projection Revenue
  Widget _buildHistoricalProjectedRevenueChart() {
    final historicalData = _historicalProjectedData['historicalData'] as List? ?? [];
    final projectionAverage = _historicalProjectedData['projectionAverage'] as double? ?? 0.0;
    
    if (historicalData.isEmpty) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    // Sort by date
    final sortedData = List.from(historicalData)..sort((a, b) {
      DateTime dateA, dateB;
      
      if (a['period'] is DateTime) {
        dateA = a['period'] as DateTime;
      } else if (a['period'] is String) {
        dateA = DateTime.parse(a['period'] as String);
      } else {
        dateA = DateTime.now();
      }
      
      if (b['period'] is DateTime) {
        dateB = b['period'] as DateTime;
      } else if (b['period'] is String) {
        dateB = DateTime.parse(b['period'] as String);
      } else {
        dateB = DateTime.now();
      }
      
      return dateA.compareTo(dateB);
    });
    
    // Take last 10 days of historical data
    final recentHistoricalData = sortedData.length > 10 
        ? sortedData.sublist(sortedData.length - 10) 
        : sortedData;
    
    // Generate 5 days of projected data
    final List<Map<String, dynamic>> projectedData = [];
    DateTime lastDate = DateTime.now();
    
    if (recentHistoricalData.isNotEmpty) {
      final lastEntry = recentHistoricalData.last;
      if (lastEntry['period'] is DateTime) {
        lastDate = lastEntry['period'] as DateTime;
      } else if (lastEntry['period'] is String) {
        lastDate = DateTime.parse(lastEntry['period'] as String);
      }
    }
    
    // Generate projected data for next 5 days
    for (int i = 1; i <= 5; i++) {
      final projectedDate = lastDate.add(Duration(days: i));
      final projectedRevenue = projectionAverage * (1 + (i * 0.05)); // 5% growth per day
      
      projectedData.add({
        'period': projectedDate,
        'actual_revenue': projectedRevenue,
      });
    }
    
    final List<FlSpot> historicalSpots = [];
    final List<FlSpot> projectedSpots = [];
    
    // Add historical data points
    for (int i = 0; i < recentHistoricalData.length; i++) {
      final revenue = (recentHistoricalData[i]['actual_revenue'] as double?) ?? 0.0;
      historicalSpots.add(FlSpot(i.toDouble(), revenue));
    }
    
    // Add projected data points (starting after historical data)
    for (int i = 0; i < projectedData.length; i++) {
      final revenue = (projectedData[i]['actual_revenue'] as double?) ?? 0.0;
      projectedSpots.add(FlSpot((recentHistoricalData.length + i).toDouble(), revenue));
    }
    
    if (historicalSpots.isEmpty && projectedSpots.isEmpty) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: historicalSpots,
            isCurved: true,
            color: AppConstants.primaryDarkBlue,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: AppConstants.primaryDarkBlue.withOpacity(0.2),
            ),
            dotData: FlDotData(
              show: true,
            ),
          ),
          LineChartBarData(
            spots: projectedSpots,
            isCurved: true,
            color: AppConstants.successGreen,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: AppConstants.successGreen.withOpacity(0.2),
            ),
            dotData: FlDotData(
              show: true,
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final totalDataPoints = recentHistoricalData.length + projectedData.length;
                if (value.toInt() < totalDataPoints) {
                  DateTime date;
                  
                  if (value.toInt() < recentHistoricalData.length) {
                    // Historical data point
                    final dataPoint = recentHistoricalData[value.toInt()];
                    if (dataPoint['period'] is DateTime) {
                      date = dataPoint['period'] as DateTime;
                    } else if (dataPoint['period'] is String) {
                      date = DateTime.parse(dataPoint['period'] as String);
                    } else {
                      date = DateTime.now();
                    }
                  } else {
                    // Projected data point
                    final projectedIndex = value.toInt() - recentHistoricalData.length;
                    if (projectedIndex < projectedData.length) {
                      final dataPoint = projectedData[projectedIndex];
                      if (dataPoint['period'] is DateTime) {
                        date = dataPoint['period'] as DateTime;
                      } else if (dataPoint['period'] is String) {
                        date = DateTime.parse(dataPoint['period'] as String);
                      } else {
                        date = DateTime.now().add(Duration(days: projectedIndex + 1));
                      }
                    } else {
                      date = DateTime.now();
                    }
                  }
                  
                  return Text(
                    DateFormat('dd/MM', 'th_TH').format(date),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  AppUtils.formatCurrency(value),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
        gridData: FlGridData(show: true),
      ),
    );
  }

  /// Payment Method Distribution Pie Chart
  Widget _buildPaymentMethodPieChart() {
    if (_paymentMethodData.isEmpty) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    // Calculate total revenue for percentage calculation
    double totalRevenue = 0;
    for (var method in _paymentMethodData) {
      totalRevenue += (method['total_revenue'] as double?) ?? 0.0;
    }
    
    if (totalRevenue == 0) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    // Sort by revenue and take top 5 methods
    final sortedData = List.from(_paymentMethodData)..sort((a, b) {
      final revenueA = (a['total_revenue'] as double?) ?? 0.0;
      final revenueB = (b['total_revenue'] as double?) ?? 0.0;
      return revenueB.compareTo(revenueA);
    });
    
    final topData = sortedData.length > 5 
        ? sortedData.sublist(0, 5) 
        : sortedData;
    
    return PieChart(
      PieChartData(
        sections: List.generate(topData.length, (index) {
          final method = topData[index];
          final methodName = method['payment_method'] as String? ?? 'ไม่ระบุ';
          final revenue = (method['total_revenue'] as double?) ?? 0.0;
          final percentage = (revenue / totalRevenue) * 100;
          
          // Generate colors for each payment method
          final colors = [
            AppConstants.primaryDarkBlue,
            AppConstants.primaryYellow,
            AppConstants.accentOrange,
            AppConstants.successGreen,
            AppConstants.softBlue,
          ];
          
          return PieChartSectionData(
            value: revenue,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 50,
            color: colors[index % colors.length],
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        centerSpaceColor: Colors.white,
        startDegreeOffset: 90,
      ),
    );
  }

  /// Category Performance Chart (Bar Chart visualization)
  Widget _buildCategoryPerformanceRadarChart() {
    if (_categoryPerformanceData.isEmpty) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    // Sort by revenue and take top 6 categories
    final sortedData = List.from(_categoryPerformanceData)..sort((a, b) {
      final revenueA = (a['total_revenue'] as double?) ?? 0.0;
      final revenueB = (b['total_revenue'] as double?) ?? 0.0;
      return revenueB.compareTo(revenueA);
    });
    
    final topData = sortedData.length > 6 
        ? sortedData.sublist(0, 6) 
        : sortedData;
    
    // Ensure we have at least one data entry to avoid empty chart
    if (topData.isEmpty) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    // Find max revenue for normalization
    double maxRevenue = 0;
    for (var category in topData) {
      final revenue = (category['total_revenue'] as double?) ?? 0.0;
      if (revenue > maxRevenue) maxRevenue = revenue;
    }
    
    if (maxRevenue == 0) {
      return Center(
        child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    // Bar chart visualization for category performance
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100, // Percentage scale
        barGroups: topData.asMap().entries.map((entry) {
          final category = entry.value;
          final index = entry.key;
          final categoryName = category['category'] as String? ?? 'ไม่ระบุ';
          final revenue = (category['total_revenue'] as double?) ?? 0.0;
          final percentage = (revenue / maxRevenue) * 100;
          
          // Generate colors for each category
          final colors = [
            AppConstants.primaryDarkBlue,
            AppConstants.primaryYellow,
            AppConstants.accentOrange,
            AppConstants.successGreen,
            AppConstants.softBlue,
            Colors.purple,
          ];
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: percentage,
                color: colors[index % colors.length],
                width: 20,
                borderRadius: BorderRadius.zero,
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < topData.length) {
                  final categoryName = topData[value.toInt()]['category'] as String? ?? 'ไม่ระบุ';
                  // Truncate long names
                  final displayName = categoryName.length > 10 
                      ? '${categoryName.substring(0, 7)}...' 
                      : categoryName;
                  return Text(
                    displayName,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.grey[800]!,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final categoryName = topData[groupIndex]['category'] as String? ?? 'ไม่ระบุ';
              final revenue = (topData[groupIndex]['total_revenue'] as double? ?? 0.0);
              return BarTooltipItem(
                '$categoryName\n${AppUtils.formatCurrency(revenue)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}