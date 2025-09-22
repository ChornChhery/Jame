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
        return sale.saleDate.isAfter(_startDate) && 
               sale.saleDate.isBefore(_endDate.add(Duration(days: 1)));
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
      
      // Hourly stats for Thai business hours analysis
      final hour = sale.saleDate.hour;
      hourlyStats[hour.toString()] = (hourlyStats[hour.toString()] ?? 0) + 1;
      
      // Daily revenue for trend analysis
      final dateKey = DateFormat('dd/MM').format(sale.saleDate);
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
      actions: [
        IconButton(
          onPressed: _showDateRangePicker,
          icon: const Icon(Icons.date_range, color: Colors.white),
        ),
        IconButton(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 400,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppConstants.primaryYellow),
            SizedBox(height: 16),
            Text(
              'กำลังโหลดข้อมูลรายงาน...',
              style: TextStyle(
                color: AppConstants.textDarkGray,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['วันนี้', 'สัปดาห์นี้', 'เดือนนี้', 'ปีนี้', 'กำหนดเอง'];
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: periods.map((period) {
            final isSelected = _selectedPeriod == period;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (selected) => _selectPeriod(period),
                backgroundColor: Colors.white,
                selectedColor: AppConstants.primaryYellow,
                labelStyle: TextStyle(
                  color: isSelected ? AppConstants.primaryDarkBlue : AppConstants.textDarkGray,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? AppConstants.primaryYellow : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSummaryCard(
                'รายได้รวม',
                AppUtils.formatCurrency(_salesData['totalRevenue'] ?? 0),
                Icons.attach_money,
                AppConstants.successGreen,
                'จากยอดขาย ${_salesData['totalSales'] ?? 0} รายการ',
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard(
                'กำไรสุทธิ',
                AppUtils.formatCurrency(_salesData['totalProfit'] ?? 0),
                Icons.trending_up,
                AppConstants.primaryYellow,
                'อัตรากำไร ${(_salesData['profitMargin'] ?? 0).toStringAsFixed(1)}%',
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryCard(
                'ยอดขายเฉลี่ย',
                AppUtils.formatCurrency(_salesData['averageSale'] ?? 0),
                Icons.shopping_cart,
                AppConstants.softBlue,
                'ต่อรายการขาย',
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard(
                'สินค้าที่ขาย',
                '${_salesData['totalItems'] ?? 0} รายการ',
                Icons.inventory_2,
                AppConstants.accentOrange,
                'รวมทุกประเภท',
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textDarkGray,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppConstants.primaryDarkBlue,
            unselectedLabelColor: AppConstants.textDarkGray,
            indicatorColor: AppConstants.primaryYellow,
            tabs: const [
              Tab(text: 'แนวโน้มขาย'),
              Tab(text: 'สินค้าขายดี'),
              Tab(text: 'สต็อกต่ำ'),
              Tab(text: 'รายการล่าสุด'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTrendTab(),
                _buildTopProductsTab(),
                _buildLowStockTab(),
                _buildRecentSalesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrendTab() {
    final dailyRevenue = _salesData['dailyRevenue'] as Map<String, double>? ?? {};
    final hourlyStats = _salesData['hourlyStats'] as Map<String, int>? ?? {};
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แนวโน้มรายได้รายวัน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 2,
            child: dailyRevenue.isNotEmpty 
                ? LineChart(_buildLineChartData(dailyRevenue))
                : _buildEmptyChart('ไม่มีข้อมูลการขายในช่วงเวลานี้'),
          ),
          const SizedBox(height: 20),
          const Text(
            'ช่วงเวลาการขาย (ชั่วโมงไทย)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 1,
            child: hourlyStats.isNotEmpty
                ? BarChart(_buildBarChartData(hourlyStats))
                : _buildEmptyChart('ไม่มีข้อมูลการขาย'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'สินค้าขายดีที่สุด',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryDarkBlue,
                ),
              ),
              const Spacer(),
              Text(
                'ท็อป ${_topProducts.length} อันดับ',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textDarkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _topProducts.isNotEmpty
                ? ListView.builder(
                    itemCount: _topProducts.length,
                    itemBuilder: (context, index) {
                      final product = _topProducts[index];
                      final rank = index + 1;
                      return _buildTopProductItem(product, rank);
                    },
                  )
                : _buildEmptyState(
                    'ยังไม่มีข้อมูลการขาย',
                    'เริ่มขายสินค้าเพื่อดูสถิติสินค้าขายดี',
                    Icons.star_outline,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'สินค้าสต็อกต่ำ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryDarkBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _lowStockProducts.isNotEmpty 
                      ? AppConstants.errorRed.withOpacity(0.1)
                      : AppConstants.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_lowStockProducts.length} รายการ',
                  style: TextStyle(
                    fontSize: 12,
                    color: _lowStockProducts.isNotEmpty 
                        ? AppConstants.errorRed
                        : AppConstants.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _lowStockProducts.isNotEmpty
                ? ListView.builder(
                    itemCount: _lowStockProducts.length,
                    itemBuilder: (context, index) {
                      return _buildLowStockItem(_lowStockProducts[index]);
                    },
                  )
                : _buildEmptyState(
                    'สต็อกสินค้าเพียงพอ',
                    'ทุกสินค้ามีจำนวนเหลือมากกว่าจุดเตือน',
                    Icons.check_circle_outline,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSalesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายการขายล่าสุด',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _recentSales.isNotEmpty
                ? ListView.builder(
                    itemCount: _recentSales.length,
                    itemBuilder: (context, index) {
                      return _buildRecentSaleItem(_recentSales[index]);
                    },
                  )
                : _buildEmptyState(
                    'ยังไม่มีรายการขาย',
                    'รายการขายของคุณจะปรากฏที่นี่',
                    Icons.receipt_outlined,
                  ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(Map<String, double> dailyRevenue) {
    final spots = dailyRevenue.entries.map((entry) {
      // Parse day/month format to get x coordinate
      final parts = entry.key.split('/');
      final day = double.parse(parts[0]);
      return FlSpot(day, entry.value);
    }).toList();
    
    spots.sort((a, b) => a.x.compareTo(b.x));
    
    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppConstants.primaryYellow,
          barWidth: 3,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: AppConstants.primaryYellow.withOpacity(0.1),
          ),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return Text(
                AppUtils.formatCurrency(value),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
    );
  }

  BarChartData _buildBarChartData(Map<String, int> hourlyStats) {
    final barGroups = hourlyStats.entries.map((entry) {
      final hour = int.parse(entry.key);
      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: _getHourBarColor(hour),
            width: 12,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    }).toList();
    
    return BarChartData(
      barGroups: barGroups,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final hour = value.toInt();
              return Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: const TextStyle(fontSize: 8),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
    );
  }

  Color _getHourBarColor(int hour) {
    // Thai business peak hours: 8-10 AM, 5-7 PM
    if ((hour >= 8 && hour <= 10) || (hour >= 17 && hour <= 19)) {
      return AppConstants.primaryYellow;
    }
    return AppConstants.softBlue;
  }

  Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: AppConstants.textDarkGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppConstants.textDarkGray,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductItem(Product product, int rank) {
    final rankColors = [
      AppConstants.primaryYellow, // Gold
      Colors.grey.shade400,        // Silver
      Colors.brown.shade400,       // Bronze
    ];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : AppConstants.textDarkGray;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.lightGray,
        borderRadius: BorderRadius.circular(8),
        border: rank <= 3 ? Border.all(color: rankColor.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppConstants.primaryDarkBlue,
                  ),
                ),
                Text(
                  'รหัส: ${product.code}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textDarkGray,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppUtils.formatCurrency(product.price),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.successGreen,
                ),
              ),
              Text(
                'คงเหลือ: ${product.quantity} ${product.unit}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textDarkGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockItem(Product product) {
    final stockPercentage = product.lowStock > 0 
        ? (product.quantity / product.lowStock * 100).clamp(0, 100)
        : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.errorRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.errorRed.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppConstants.primaryDarkBlue,
                      ),
                    ),
                    Text(
                      'รหัส: ${product.code}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textDarkGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'เหลือ ${product.quantity} ${product.unit}',
                  style: const TextStyle(
                    color: AppConstants.errorRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: stockPercentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    stockPercentage < 50 ? AppConstants.errorRed : AppConstants.primaryYellow,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${stockPercentage.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: stockPercentage < 50 ? AppConstants.errorRed : AppConstants.primaryYellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSaleItem(Sale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.receipt,
                  color: AppConstants.successGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.receiptNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppConstants.primaryDarkBlue,
                      ),
                    ),
                    Text(
                      AppUtils.formatDateTime(sale.saleDate),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppConstants.textDarkGray,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                AppUtils.formatCurrency(sale.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.successGreen,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${sale.items?.length ?? 0} รายการสินค้า',
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textDarkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppConstants.textDarkGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textDarkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.textDarkGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _selectPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    
    final now = DateTime.now();
    switch (period) {
      case 'วันนี้':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'สัปดาห์นี้':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'เดือนนี้':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'ปีนี้':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'กำหนดเอง':
        _showDateRangePicker();
        return;
    }
    
    _loadReportsData();
  }

  void _showDateRangePicker() {
    // Implementation for custom date range picker
  }

  void _refreshData() {
    _loadReportsData();
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