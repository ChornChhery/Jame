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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadReportsData();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 4, vsync: this);
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
      
      // Calculate sales analytics
      _salesData = _calculateSalesAnalytics(filteredSales);
      
      // Get top selling products (simplified - using existing products)
      _topProducts = app.products.take(5).toList();
      
      // Get low stock products
      _lowStockProducts = await app.getLowStockProducts(auth.currentUser!.id!);
      
      // Get recent sales
      _recentSales = filteredSales.take(10).toList();
      
    } catch (e) {
      _showErrorMessage('เกิดข้อผิดพลาดในการโหลดข้อมูล: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
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
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'จำนวนการขาย',
                  '$totalSales ครั้ง',
                  Icons.shopping_cart,
                  Colors.green,
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
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'อัตรากำไร',
                  '${profitMargin.toStringAsFixed(1)}%',
                  Icons.percent,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
                  tabs: const [
                    Tab(text: 'ยอดขาย'),
                    Tab(text: 'สินค้ายอดนิยม'),
                    Tab(text: 'สต็อกต่ำ'),
                    Tab(text: 'วิเคราะห์'),
                  ],
                ),
                Container(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesTab(),
                      _buildTopProductsTab(),
                      _buildLowStockTab(),
                      _buildAnalyticsTab(),
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
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt,
                color: AppConstants.primaryDarkBlue,
                size: 20,
              ),
            ),
            title: Text(
              sale.receiptNumber,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
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
                  '${sale.items?.length ?? 0} รายการสินค้า',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Text(
              AppUtils.formatCurrency(sale.totalAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryDarkBlue,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopProductsTab() {
    if (_topProducts.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topProducts.length,
      itemBuilder: (context, index) {
        final product = _topProducts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2,
                color: AppConstants.primaryDarkBlue,
                size: 20,
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'รหัส: ${product.code}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.quantity} ${product.unit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  AppUtils.formatCurrency(product.price),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber,
                color: Colors.orange[700] as Color,
                size: 20,
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'เหลือ ${product.quantity} ${product.unit} (จุดเตือน: ${product.lowStock})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700] as Color,
              ),
            ),
            trailing: Text(
              AppUtils.formatCurrency(product.price),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange[700] as Color,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    final hourlyStats = _salesData['hourlyStats'] as Map<String, int>? ?? {};
    final dailyRevenue = _salesData['dailyRevenue'] as Map<String, double>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                              x: int.parse(entry.key),
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
                                    entry.value.value, // Access the double value correctly
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