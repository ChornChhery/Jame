// FILE: lib/screens/payment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../core/translations.dart';
import '../widgets/language_switch_button.dart';
import '../models/sale.dart';
import '../core/constants.dart';
import '../core/utils.dart';

class PaymentHistoryScreen extends StatefulWidget {
  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  bool _isLoading = true;
  String _sortOption = 'date_desc'; // Default sort by date descending
  String _filterOption = 'all'; // Default show all sales
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSalesData();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  Future<void> _loadSalesData() async {
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final app = Provider.of<AppProvider>(context, listen: false);
      
      if (auth.currentUser?.id != null) {
        await app.loadSales(auth.currentUser!.id!);
        _sales = List.from(app.sales);
        
        // Load sale items with product details for all sales
        final salesWithItems = <Sale>[];
        for (var sale in _sales) {
          try {
            final items = await app.getSaleItemsWithProducts(sale.id!);
            salesWithItems.add(sale.copyWith(items: items));
          } catch (e) {
            debugPrint('Error loading sale items for sale ${sale.id}: $e');
            salesWithItems.add(sale);
          }
        }
        
        _sales = salesWithItems;
        _applyFiltersAndSorting();
      }
    } catch (e) {
      debugPrint('Error loading sales data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.t('ui_error_loading_data', [e.toString()])),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFiltersAndSorting() {
    setState(() {
      // Apply search filter
      List<Sale> filtered = _sales;
      if (_searchQuery.isNotEmpty) {
        filtered = _sales.where((sale) {
          return sale.receiptNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (sale.customerName != null && sale.customerName!.toLowerCase().contains(_searchQuery.toLowerCase()));
        }).toList();
      }
      
      // Apply date filter
      if (_startDate != null && _endDate != null) {
        filtered = filtered.where((sale) {
          final saleDate = AppUtils.toShopTime(sale.saleDate);
          return saleDate.isAfter(_startDate!) && saleDate.isBefore(_endDate!.add(Duration(days: 1)));
        }).toList();
      }
      
      // Apply payment method filter
      if (_filterOption != 'all') {
        filtered = filtered.where((sale) => sale.paymentMethod == _filterOption).toList();
      }
      
      // Apply sorting
      filtered.sort((a, b) {
        switch (_sortOption) {
          case 'date_asc':
            return a.saleDate.compareTo(b.saleDate);
          case 'date_desc':
            return b.saleDate.compareTo(a.saleDate);
          case 'amount_asc':
            return a.totalAmount.compareTo(b.totalAmount);
          case 'amount_desc':
            return b.totalAmount.compareTo(a.totalAmount);
          case 'receipt_asc':
            return a.receiptNumber.compareTo(b.receiptNumber);
          case 'receipt_desc':
            return b.receiptNumber.compareTo(a.receiptNumber);
          default:
            return b.saleDate.compareTo(a.saleDate); // Default to date descending
        }
      });
      
      _filteredSales = filtered;
    });
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
                          _buildFiltersAndSearch(),
                          _buildSalesSummary(),
                          _buildSalesList(),
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
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          context.tr('sales_history'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
                top: 40,
                right: -20,
                child: Icon(
                  Icons.history,
                  size: 100,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        const Center(
          child: Padding(
            padding: EdgeInsets.only(right: 4),
            child: LanguageSwitchButton(isDarkBackground: true, compact: true),
          ),
        ),
        IconButton(
          onPressed: _loadSalesData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppConstants.primaryYellow,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              AppTranslations.t('ui_loading_data'),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersAndSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: AppConstants.lightGray,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFiltersAndSorting();
              },
              decoration: InputDecoration(
                hintText: AppTranslations.t('ui_search_by_receipt_number_or_customer'),
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: AppConstants.primaryDarkBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _applyFiltersAndSorting();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Filter and sort options
          Row(
            children: [
              // Filter dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppConstants.lightGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<String>(
                    value: _filterOption,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(Icons.filter_list, color: AppConstants.primaryDarkBlue),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(AppTranslations.t('ui_all'))),
                      DropdownMenuItem(value: 'QR', child: Text(AppTranslations.t('ui_promptpay'))),
                      DropdownMenuItem(value: 'Cash', child: Text(AppTranslations.t('ui_cash'))),
                    ],
                    onChanged: (value) {
                      setState(() => _filterOption = value!);
                      _applyFiltersAndSorting();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Sort dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppConstants.lightGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<String>(
                    value: _sortOption,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(Icons.sort, color: AppConstants.primaryDarkBlue),
                    items: [
                      DropdownMenuItem(value: 'date_desc', child: Text(AppTranslations.t('ui_newest_first'))),
                      DropdownMenuItem(value: 'date_asc', child: Text(AppTranslations.t('ui_oldest_first'))),
                      DropdownMenuItem(value: 'amount_desc', child: Text(AppTranslations.t('ui_highest_amount'))),
                      DropdownMenuItem(value: 'amount_asc', child: Text(AppTranslations.t('ui_lowest_amount'))),
                      DropdownMenuItem(value: 'receipt_asc', child: Text(AppTranslations.t('ui_receipt_number_a_z'))),
                      DropdownMenuItem(value: 'receipt_desc', child: Text(AppTranslations.t('ui_receipt_number_z_a'))),
                    ],
                    onChanged: (value) {
                      setState(() => _sortOption = value!);
                      _applyFiltersAndSorting();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Date range filter
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  _startDate,
                  AppTranslations.t('ui_start_date'),
                  _selectStartDate,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 20, color: Colors.grey[600]),
              ),
              Expanded(
                child: _buildDateButton(
                  _endDate,
                  AppTranslations.t('ui_end_date'),
                  _selectEndDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(DateTime? date, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                    date != null ? AppUtils.formatDate(date) : AppTranslations.t('ui_select_date'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: date != null ? AppConstants.primaryDarkBlue : Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('en', 'US'),
    );
    
    if (picked != null) {
      setState(() => _startDate = picked);
      _applyFiltersAndSorting();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('en', 'US'),
    );
    
    if (picked != null) {
      setState(() => _endDate = picked);
      _applyFiltersAndSorting();
    }
  }

  Widget _buildSalesSummary() {
    final totalSales = _filteredSales.length;
    final totalAmount = _filteredSales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  Text(
                    AppTranslations.t('ui_number_of_sales'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalSales',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppTranslations.t('ui_items'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  Text(
                    AppTranslations.t('ui_total_sales'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppUtils.formatCurrency(totalAmount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppTranslations.t('ui_baht'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  Widget _buildSalesList() {
    if (_filteredSales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty || _startDate != null || _filterOption != 'all'
                    ? AppTranslations.t('ui_no_data_matches_the_filters')
                    : AppTranslations.t('ui_no_payment_history_yet'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty || _startDate != null || _filterOption != 'all'
                    ? AppTranslations.t('ui_try_changing_your_search_filters')
                    : AppTranslations.t('ui_transactions_will_appear_here'),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredSales.length,
        itemBuilder: (context, index) {
          final sale = _filteredSales[index];
          final isHighValue = sale.totalAmount > 1000;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isHighValue ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
                width: isHighValue ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: sale.paymentMethod == 'Cash' 
                          ? AppConstants.accentOrange.withOpacity(0.2) 
                          : AppConstants.softBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sale.paymentMethod == 'Cash' 
                            ? AppConstants.accentOrange.withOpacity(0.5) 
                            : AppConstants.softBlue.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      sale.paymentMethod == 'Cash' ? Icons.money : Icons.qr_code,
                      color: sale.paymentMethod == 'Cash' ? AppConstants.accentOrange : AppConstants.softBlue,
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            AppTranslations.t('ui_high_value'),
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
                        AppUtils.formatDateTime(sale.saleDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            sale.paymentMethod == 'Cash' ? Icons.money : Icons.qr_code,
                            size: 12,
                            color: sale.paymentMethod == 'Cash' ? AppConstants.accentOrange : AppConstants.softBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sale.paymentMethod == 'Cash' ? AppTranslations.t('ui_cash') : AppTranslations.t('ui_promptpay'),
                            style: TextStyle(
                              fontSize: 11,
                              color: sale.paymentMethod == 'Cash' ? AppConstants.accentOrange : AppConstants.softBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.account_circle, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sale.customerName ?? AppTranslations.t('ui_walk_in_customer'),
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(
                    AppUtils.formatCurrency(sale.totalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryDarkBlue,
                    ),
                  ),
                  onTap: () => _viewReceiptDetails(sale),
                ),
                // Action buttons for print and share
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _printReceipt(sale),
                        icon: const Icon(Icons.print, size: 16),
                        label: Text(AppTranslations.t('ui_print')),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _shareReceipt(sale),
                        icon: const Icon(Icons.share, size: 16),
                        label: Text(AppTranslations.t('ui_share')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _viewReceiptDetails(Sale sale) {
    // Navigate to receipt details screen
    // For now, we'll show a simple dialog with sale details
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppTranslations.t('ui_receipt_details')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppTranslations.t('ui_receipt_no', [sale.receiptNumber])),
                const SizedBox(height: 8),
                Text(AppTranslations.t('ui_date', [AppUtils.formatDateTime(sale.saleDate)])),
                const SizedBox(height: 8),
                Text(AppTranslations.t('ui_amount', [AppUtils.formatCurrency(sale.totalAmount)])),
                const SizedBox(height: 8),
                Text(AppTranslations.t('ui_payment_method', [sale.paymentMethod == 'Cash' ? AppTranslations.t('ui_cash') : AppTranslations.t('ui_promptpay')])),
                if (sale.customerName != null) ...[
                  const SizedBox(height: 8),
                  Text(AppTranslations.t('ui_customer', [sale.customerName])),
                ],
                if (sale.customerPhone != null) ...[
                  const SizedBox(height: 8),
                  Text(AppTranslations.t('ui_phone', [sale.customerPhone])),
                ],
                const SizedBox(height: 16),
                Text(
                  AppTranslations.t('ui_items_2'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (sale.items != null && sale.items!.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: sale.items!.map((item) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Product image
                              if (item.product?.image != null && item.product!.image!.isNotEmpty) ...[
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.product!.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.image_not_supported,
                                          size: 30,
                                          color: Colors.grey[400],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ] else ...[
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppConstants.lightGray,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2,
                                    size: 30,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              // Product details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product?.name ?? AppTranslations.t('ui_unnamed_product'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(AppTranslations.t('ui_text', [item.quantity, item.product?.unit ?? AppTranslations.t('ui_unit')])),
                                        Text(AppUtils.formatCurrency(item.totalPrice)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppTranslations.t('ui_no_item_data'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppTranslations.t('ui_close')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _printReceipt(sale);
              },
              child: Text(AppTranslations.t('ui_print')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareReceipt(sale);
              },
              child: Text(AppTranslations.t('ui_share')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareReceipt(Sale sale) async {
    try {
      final pdfBytes = await _generatePDF(sale);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/receipt_${sale.receiptNumber}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: AppTranslations.t('ui_receipt_no_2', [sale.receiptNumber]),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.t('ui_unable_to_share_the_receipt', [e.toString()])),
            backgroundColor: AppConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _printReceipt(Sale sale) async {
    try {
      final pdfBytes = await _generatePDF(sale);
      await Printing.layoutPdf(
        onLayout: (format) => Future.value(Uint8List.fromList(pdfBytes)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.t('ui_unable_to_print_the_receipt', [e.toString()])),
            backgroundColor: AppConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<List<int>> _generatePDF(Sale sale) async {
    final pdf = pw.Document();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser!;
    
    // Load sale items if not already loaded
    List<SaleItem> saleItems = sale.items ?? [];
    if (saleItems.isEmpty) {
      final app = Provider.of<AppProvider>(context, listen: false);
      saleItems = await app.getSaleItemsWithProducts(sale.id!);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      user.shopName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (user.shopAddress != null && user.shopAddress!.isNotEmpty)
                      pw.Text(
                        user.shopAddress!,
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    if (user.shopPhone != null && user.shopPhone!.isNotEmpty)
                      pw.Text(
                        AppTranslations.t('ui_tel', [user.shopPhone]),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 2),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        AppTranslations.t('ui_receipt'),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              
              // Receipt details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    AppTranslations.t('ui_receipt_no', [sale.receiptNumber]),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    AppTranslations.t('ui_date', [DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate)]),
                  ),
                ],
              ),
              
              if (sale.customerName != null && 
                  sale.customerName!.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text(AppTranslations.t('ui_customer', [sale.customerName])),
              ],
              
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              
              // Items table
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          AppTranslations.t('ui_items'),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          AppTranslations.t('ui_qty'),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          AppTranslations.t('ui_price_unit'),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          AppTranslations.t('ui_total'),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  ...saleItems.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.product?.name ?? AppTranslations.t('ui_product_name_not_found'),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              AppTranslations.t('ui_code', [item.product?.code ?? '-']),
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${item.quantity}',
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '฿${NumberFormat('#,##0.00').format(item.unitPrice)}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '฿${NumberFormat('#,##0.00').format(item.totalPrice)}',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
              
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              
              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(AppTranslations.t('ui_number_of_items')),
                      pw.SizedBox(height: 5),
                      pw.Text(AppTranslations.t('ui_payment_method_2')),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        AppTranslations.t('ui_total_2'),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(AppTranslations.t('ui_items_3', [saleItems.length])),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        sale.paymentMethod == 'Cash' 
                            ? AppTranslations.t('ui_cash') 
                            : 'PromptPay',
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        '฿${NumberFormat('#,##0.00').format(sale.totalAmount)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 40),
              
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      AppTranslations.t('ui_thank_you_for_your_business'),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Powered by Jame POS',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }
}