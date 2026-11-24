import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/constants.dart';
import '../core/utils.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../core/translations.dart';
import '../widgets/language_switch_button.dart';
import '../models/product.dart';
import '../widgets/product_form_dialog.dart';

class ProductsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ProductsScreen({Key? key, this.arguments}) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    // Always rebuild to ensure counts are updated
    return true;
  }
}

class _ProductsScreenState extends State<ProductsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isGridView = false;
  String _sortBy = 'name';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );
    _fabAnimationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _searchController.addListener(_onSearchChanged);
    _handleArguments();
  }

  void _handleArguments() {
    if (widget.arguments != null) {
      final args = widget.arguments!;
      if (args['mode'] == 'add') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAddProductDialog();
        });
      }
    }
  }

  Future<void> _loadData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isLoading = true);
    });
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final app = Provider.of<AppProvider>(context, listen: false);
      
      if (auth.currentUser?.id != null) {
        await app.loadProducts(auth.currentUser!.id!);
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _isLoading = false);
        _searchProducts();
      });
    }
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
    _searchProducts();
  }

  void _searchProducts() {
    try {
      final app = Provider.of<AppProvider>(context, listen: false);
      List<Product> products = app.products;

      if (_searchQuery.isNotEmpty) {
        products = products.where((product) {
          return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 product.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 (product.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        }).toList();
      }

      products.sort((a, b) {
        switch (_sortBy) {
          case 'name':
            return a.name.compareTo(b.name);
          case 'price':
            return a.price.compareTo(b.price);
          case 'quantity':
            return b.quantity.compareTo(a.quantity);
          case 'category':
            return (a.category ?? '').compareTo(b.category ?? '');
          default:
            return a.name.compareTo(b.name);
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _filteredProducts = products);
      });
    } catch (e) {
      print('Error searching products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildSearchAndFilters()),
          _buildSliverTabBar(),
          SliverFillRemaining(
            child: _isLoading ? _buildLoadingWidget() : _buildTabContent(),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton(
          onPressed: () => _showAddProductDialog(),
          backgroundColor: AppConstants.primaryYellow,
          foregroundColor: AppConstants.primaryDarkBlue,
          elevation: 5,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppConstants.primaryDarkBlue,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          context.tr('nav_products'),
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
                  Icons.inventory_2_outlined,
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
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            switch (value) {
              case 'export':
                _showExportDialog();
                break;
              case 'import':
                _showImportDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download_rounded),
                  SizedBox(width: 8),
                  Text(AppTranslations.t('ui_export_data')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.upload_rounded),
                  SizedBox(width: 8),
                  Text(AppTranslations.t('ui_import_data')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppTranslations.t('ui_search_products_codes_or_categories'),
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search_rounded, 
                  color: AppConstants.primaryDarkBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, 
                          color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _searchProducts();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppConstants.lightGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(Icons.sort_rounded, 
                      color: AppConstants.primaryDarkBlue),
                    items: [
                      DropdownMenuItem(value: 'name', child: Text(AppTranslations.t('ui_sort_by_name'))),
                      DropdownMenuItem(value: 'price', child: Text(AppTranslations.t('ui_sort_by_price'))),
                      DropdownMenuItem(value: 'quantity', child: Text(AppTranslations.t('ui_sort_by_quantity'))),
                      DropdownMenuItem(value: 'category', child: Text(AppTranslations.t('ui_sort_by_category'))),
                    ],
                    onChanged: (value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() => _sortBy = value!);
                        _searchProducts();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.lightGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => _isGridView = false);
                        });
                      },
                      icon: Icon(
                        Icons.view_list_rounded,
                        color: !_isGridView 
                          ? AppConstants.primaryDarkBlue 
                          : Colors.grey[600],
                      ),
                      tooltip: AppTranslations.t('ui_list_view'),
                    ),
                    IconButton(
                      onPressed: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => _isGridView = true);
                        });
                      },
                      icon: Icon(
                        Icons.grid_view_rounded,
                        color: _isGridView 
                          ? AppConstants.primaryDarkBlue 
                          : Colors.grey[600],
                      ),
                      tooltip: AppTranslations.t('ui_grid_view'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverTabBar() {
    // Use filtered products for tab counts instead of all products
    final allProductCount = _filteredProducts.length;
    final lowStockCount = _filteredProducts
        .where((p) => p.quantity <= p.lowStock).length;
    
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryDarkBlue,
          unselectedLabelColor: AppConstants.textDarkGray,
          indicatorColor: AppConstants.primaryYellow,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_rounded),
                  const SizedBox(width: 8),
                  Text(AppTranslations.t('ui_all_products', [allProductCount])),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_rounded, 
                    color: lowStockCount > 0 ? AppConstants.errorRed : null),
                  const SizedBox(width: 8),
                  Text(AppTranslations.t('ui_low_stock_products_2', [lowStockCount])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppConstants.primaryYellow,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            AppTranslations.t('ui_loading_products'),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProductsList(),
        _buildLowStockList(),
      ],
    );
  }

  Widget _buildProductsList() {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        title: _searchQuery.isEmpty ? AppTranslations.t('ui_no_products_yet') : AppTranslations.t('ui_no_products_found'),
        subtitle: _searchQuery.isEmpty 
          ? AppTranslations.t('ui_get_started_by_adding_your_first')
          : AppTranslations.t('ui_try_changing_your_search_term_or'),
        actionText: _searchQuery.isEmpty ? AppTranslations.t('ui_add_first_product') : AppTranslations.t('ui_clear_search'),
        onAction: _searchQuery.isEmpty 
          ? _showAddProductDialog 
          : () {
              _searchController.clear();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _searchQuery = '');
                _searchProducts();
              });
            },
      );
    }

    return _isGridView ? _buildProductsGrid() : _buildProductsListView();
  }

  Widget _buildProductsListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) => _buildEnhancedProductCard(_filteredProducts[index]),
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) => _buildProductGridCard(_filteredProducts[index]),
    );
  }

  Widget _buildLowStockList() {
    final lowStockProducts = _filteredProducts
        .where((p) => p.quantity <= p.lowStock)
        .toList();
    
    if (lowStockProducts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppConstants.successGreen,
        title: AppTranslations.t('ui_stock_is_sufficient'),
        subtitle: AppTranslations.t('ui_no_products_are_low_on_stock'),
      );
    }
    
    return _isGridView 
      ? _buildLowStockGrid(lowStockProducts) 
      : _buildLowStockListview(lowStockProducts);
  }

  Widget _buildLowStockListview(List<Product> lowStockProducts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lowStockProducts.length,
      itemBuilder: (context, index) => _buildEnhancedProductCard(lowStockProducts[index]),
    );
  }

  Widget _buildLowStockGrid(List<Product> lowStockProducts) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: lowStockProducts.length,
      itemBuilder: (context, index) => _buildProductGridCard(lowStockProducts[index]),
    );
  }

  Widget _buildEnhancedProductCard(Product product) {
    final isLowStock = product.quantity <= product.lowStock;
    
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
        border: isLowStock
            ? Border.all(color: AppConstants.errorRed.withOpacity(0.3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showProductDetailsDialog(product),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildEnhancedProductImage(product, size: 50),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.category != null)
                            Container(
                              constraints: const BoxConstraints(maxWidth: 90), // Increased from 65 to 90
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.category!,
                                style: TextStyle(
                                  fontSize: 14, // Increased from 8 to 12
                                  color: AppConstants.primaryDarkBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppTranslations.t('ui_code', [product.code]),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryYellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppUtils.formatCurrency(product.price),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.primaryDarkBlue,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: product.quantity <= 0
                                  ? Colors.grey.withOpacity(0.1)
                                  : isLowStock 
                                    ? AppConstants.errorRed.withOpacity(0.1)
                                    : AppConstants.successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.quantity <= 0 ? AppTranslations.t('ui_out_of_stock') : '${product.quantity} ${product.unit}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: product.quantity <= 0
                                    ? Colors.grey
                                    : isLowStock 
                                      ? AppConstants.errorRed
                                      : AppConstants.successGreen,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isLowStock) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              size: 12,
                              color: AppConstants.errorRed,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                AppTranslations.t('ui_low_stock_should_restock'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.errorRed,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: product.quantity > 0 ? () => _showAddToCartDialog(product) : null,
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 24), // Increased from 20 to 24
                        color: product.quantity > 0 ? AppConstants.primaryDarkBlue : Colors.grey,
                        tooltip: product.quantity > 0 ? AppTranslations.t('ui_add_to_cart') : AppTranslations.t('ui_product_out_of_stock'),
                        padding: const EdgeInsets.all(0),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 4),
                      const SizedBox(width: 10),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, 
                          color: Colors.grey[600], size: 20),
                        onSelected: (value) => _handleProductAction(value, product),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'addStock',
                            child: Row(
                              children: [
                                Icon(Icons.add_box_rounded, size: 16),
                                SizedBox(width: 6),
                                Text(AppTranslations.t('ui_restock'), style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 16),
                                SizedBox(width: 6),
                                Text(AppTranslations.t('ui_edit'), style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, color: Colors.red, size: 16),
                                SizedBox(width: 6),
                                Text(AppTranslations.t('ui_delete'), style: TextStyle(color: Colors.red, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                        padding: const EdgeInsets.all(0),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      );
    }

  Widget _buildProductGridCard(Product product) {
    final isLowStock = product.quantity <= product.lowStock;
    
    return Container(
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
        border: isLowStock
            ? Border.all(color: AppConstants.errorRed.withOpacity(0.3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showProductDetailsDialog(product),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Center(child: _buildEnhancedProductImage(product, size: 60)),
                    if (isLowStock)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppConstants.errorRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    AppUtils.formatCurrency(product.price),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryDarkBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      product.quantity <= 0 ? Icons.block : Icons.inventory_2_rounded,
                      size: 12,
                      color: product.quantity <= 0 
                        ? Colors.grey 
                        : isLowStock ? AppConstants.errorRed : Colors.grey[600],
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        product.quantity <= 0 ? AppTranslations.t('ui_out_of_stock') : '${product.quantity} ${product.unit}',
                        style: TextStyle(
                          fontSize: 11,
                          color: product.quantity <= 0 
                            ? Colors.grey 
                            : isLowStock ? AppConstants.errorRed : Colors.grey[600],
                          fontWeight: product.quantity <= 0 
                            ? FontWeight.normal 
                            : isLowStock ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.quantity <= 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppTranslations.t('ui_out_of_stock'),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppConstants.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppTranslations.t('ui_low_stock'),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppConstants.errorRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: product.quantity > 0 ? () => _showAddToCartDialog(product) : null,
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                        color: product.quantity > 0 ? AppConstants.primaryDarkBlue : Colors.grey,
                        tooltip: product.quantity > 0 ? AppTranslations.t('ui_add_to_cart') : AppTranslations.t('ui_product_out_of_stock'),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, 
                          color: Colors.grey[600], size: 20),
                        onSelected: (value) => _handleProductAction(value, product),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'addStock',
                            child: Row(
                              children: [
                                Icon(Icons.add_box_rounded, size: 16),
                                SizedBox(width: 6),
                                Text(AppTranslations.t('ui_restock'), style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 16),
                                SizedBox(width: 6),
                                Text(AppTranslations.t('ui_edit'), style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, color: Colors.red, size: 16),
                                SizedBox(width: 6),
                                Text(AppTranslations.t('ui_delete'), style: TextStyle(color: Colors.red, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                        padding: const EdgeInsets.all(0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedProductImage(Product product, {double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryDarkBlue.withOpacity(0.1),
            AppConstants.primaryYellow.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryDarkBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: product.image != null && product.image!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.image!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Log the error for debugging
                  print('Image loading error: $error');
                  return Icon(
                    Icons.inventory_2_rounded,
                    color: AppConstants.primaryDarkBlue,
                    size: size * 0.4,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryYellow,
                      strokeWidth: 2,
                    ),
                  );
                },
                // Add headers to handle WebP and other formats
                headers: const {
                  'Accept': 'image/*',
                },
              ),
            )
          : Icon(
              Icons.inventory_2_rounded,
              color: AppConstants.primaryDarkBlue,
              size: size * 0.4,
            ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionText,
    VoidCallback? onAction,
    Color? iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.grey).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.textDarkGray,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryYellow,
                  foregroundColor: AppConstants.primaryDarkBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleProductAction(String action, Product product) {
    switch (action) {
      case 'addToCart':
        _addToCart(product);
        break;
      case 'addStock':
        _showAddStockDialog(product);
        break;
      case 'edit':
        _showEditProductDialog(product);
        break;
      case 'delete':
        _showDeleteConfirmDialog(product);
        break;
    }
  }

  Future<void> _addToCart(Product product) async {
    // Store the ScaffoldMessenger state at the very beginning to ensure we have a valid reference
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (product.quantity <= 0) {
      // Use a delayed callback to show snackbar after any potential widget disposal
      Future.delayed(Duration(milliseconds: 100), () {
        // Show snackbar using the stored scaffold messenger reference
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(AppTranslations.t('ui_this_product_is_out_of_stock')),
            backgroundColor: AppConstants.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
          ),
        );
      });
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      if (authProvider.currentUser?.id != null) {
        await appProvider.addToCartWithPersistence(
          authProvider.currentUser!.id!,
          product,
          quantity: 1,
        );
      } else {
        appProvider.addToCart(product, quantity: 1);
      }
    } catch (error) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppConstants.errorRed,
        ),
      );
      return;
    }
    
    // Use a delayed callback to show snackbar after any potential widget disposal
    Future.delayed(Duration(milliseconds: 100), () {
      // Show snackbar using the stored scaffold messenger reference
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(AppTranslations.t('ui_added_to_the_cart', [product.name])),
          backgroundColor: AppConstants.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          action: SnackBarAction(
            label: AppTranslations.t('ui_view_cart_2'),
            textColor: Colors.white,
            onPressed: () {
              // Note: We can't safely navigate from here as the context might be disposed
            },
          ),
        ),
      );
    });
  }

  void _showAddToCartDialog(Product product) {
    // Check if product is out of stock
    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.t('ui_is_out_of_stock', [product.name])),
          backgroundColor: AppConstants.errorRed,
        ),
      );
      return;
    }
    
    final quantityController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_shopping_cart_rounded,
                color: AppConstants.primaryDarkBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.t('ui_add_to_cart'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.lightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    color: AppConstants.primaryDarkBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.t('ui_current_stock', [product.quantity, product.unit]),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppTranslations.t('ui_quantity_needed'),
                hintText: AppTranslations.t('ui_enter_quantity_needed'),
                prefixIcon: const Icon(Icons.numbers_rounded),
                suffix: Text(product.unit),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppConstants.primaryYellow),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.t('ui_cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () => _addToCartConfirmed(product, quantityController.text),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: Text(AppTranslations.t('ui_add_to_cart')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryYellow,
              foregroundColor: AppConstants.primaryDarkBlue,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCartConfirmed(
    Product product,
    String quantityText,
  ) async {
    // Store the ScaffoldMessenger state at the very beginning to ensure we have a valid reference
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final quantity = int.tryParse(quantityText) ?? 0;
    if (quantity <= 0) {
      // Pop the dialog first
      Navigator.pop(context);
      
      // Use a delayed callback to show snackbar after dialog is completely dismissed
      Future.delayed(Duration(milliseconds: 100), () {
        // Show snackbar using the stored scaffold messenger reference
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(AppTranslations.t('ui_please_enter_a_valid_quantity')),
            backgroundColor: AppConstants.errorRed,
          ),
        );
      });
      return;
    }
    
    if (quantity > product.quantity) {
      // Pop the dialog first
      Navigator.pop(context);
      
      // Use a delayed callback to show snackbar after dialog is completely dismissed
      Future.delayed(Duration(milliseconds: 100), () {
        // Show snackbar using the stored scaffold messenger reference
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(AppTranslations.t('ui_requested_quantity_exceeds_available_stock', [product.quantity, product.unit])),
            backgroundColor: AppConstants.errorRed,
          ),
        );
      });
      return;
    }
    
    // Add the product to the cart using AppProvider with persistence
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      if (authProvider.currentUser?.id != null) {
        await appProvider.addToCartWithPersistence(
          authProvider.currentUser!.id!,
          product,
          quantity: quantity,
        );
      } else {
        appProvider.addToCart(product, quantity: quantity);
      }
    } catch (error) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppConstants.errorRed,
        ),
      );
      return;
    }
    
    // Pop the dialog first
    Navigator.pop(context);
    
    // Use a delayed callback to show snackbar after dialog is completely dismissed
    Future.delayed(Duration(milliseconds: 100), () {
      // Show snackbar using the stored scaffold messenger reference
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppTranslations.t('ui_added_x_to_the_cart', [product.name, quantity, product.unit]),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppConstants.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    });
  }

  void _showProductDetailsDialog(Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppTranslations.t('ui_product_details'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Center(
                child: _buildEnhancedProductImage(product, size: 100),
              ),
              const SizedBox(height: 20),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(AppTranslations.t('ui_product_code'), product.code),
                    const SizedBox(height: 12),
                    _buildDetailRow(AppTranslations.t('ui_price'), AppUtils.formatCurrency(product.price)),
                    const SizedBox(height: 12),
                    _buildDetailRow(AppTranslations.t('ui_quantity_in_stock'), '${product.quantity} ${product.unit}'),
                    const SizedBox(height: 12),
                    _buildDetailRow(AppTranslations.t('ui_low_stock_threshold'), '${product.lowStock} ${product.unit}'),
                    if (product.category != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(AppTranslations.t('ui_category'), product.category!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddToCartDialog(product);
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: Text(AppTranslations.t('ui_add_to_cart')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryYellow,
                        foregroundColor: AppConstants.primaryDarkBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditProductDialog(product);
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: Text(AppTranslations.t('ui_edit_product')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      label: Text(AppTranslations.t('ui_close')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddProductDialog({String? prefilledCode}) {
    _showProductFormDialog(null, prefilledCode);
  }

  void _showEditProductDialog(Product product) {
    _showProductFormDialog(product, null);
  }

  void _showProductFormDialog(Product? product, String? prefilledCode) {
    final isEditing = product != null;
    const categories = <String>[
      'Food & Beverage',
      'Household Items',
      'Stationery',
      'Medicine & Medical Supplies',
      'Clothing & Apparel',
      'Electronics',
      'Kitchenware',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => ProductFormDialog(
        product: product,
        prefilledCode: prefilledCode,
        categories: categories,
        onPickImage: (imageController) =>
            _showImageUploadOptions(dialogContext, imageController),
        onSave: (v) => _saveProduct(
          isEditing,
          product,
          TextEditingController(text: v.name),
          TextEditingController(text: v.price.toString()),
          TextEditingController(text: v.quantity.toString()),
          TextEditingController(text: v.lowStock.toString()),
          TextEditingController(text: v.unit),
          TextEditingController(text: v.category),
          TextEditingController(text: v.image),
          code: v.code.isEmpty ? null : v.code,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          prefixIcon: Icon(icon, color: AppConstants.primaryDarkBlue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: required ? AppConstants.errorRed : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _showImageUploadOptions(BuildContext context, TextEditingController imageController) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppTranslations.t('ui_choose_how_to_upload_the_image'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.link_rounded, color: AppConstants.primaryDarkBlue),
              ),
              title: Text(AppTranslations.t('ui_use_image_link')),
              subtitle: Text(AppTranslations.t('ui_enter_an_image_url_from_the')),
              onTap: () {
                Navigator.pop(context);
                _showImageUrlDialog(imageController);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt_rounded, color: AppConstants.primaryDarkBlue),
              ),
              title: Text(AppTranslations.t('ui_take_photo')),
              subtitle: Text(AppTranslations.t('ui_use_the_camera_to_take_a')),
              onTap: () {
                Navigator.pop(context);
                _captureImage(context, imageController);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library_rounded, color: AppConstants.primaryDarkBlue),
              ),
              title: Text(AppTranslations.t('ui_choose_from_gallery')),
              subtitle: Text(AppTranslations.t('ui_choose_a_photo_from_the_device')),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery(context, imageController);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showImageUrlDialog(TextEditingController imageController) {
    final urlController = TextEditingController(text: imageController.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.link_rounded),
            SizedBox(width: 8),
            Text(AppTranslations.t('ui_enter_image_link')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: AppTranslations.t('ui_image_url'),
                hintText: 'https://example.com/image.jpg',
                prefixIcon: Icon(Icons.image_rounded),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Text(
              AppTranslations.t('ui_enter_an_image_link_that_is'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.t('ui_cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              imageController.text = urlController.text;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryYellow,
              foregroundColor: AppConstants.primaryDarkBlue,
            ),
            child: Text(AppTranslations.t('ui_save')),
          ),
        ],
      ),
    );
  }

  void _showImageNotAvailableDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text(AppTranslations.t('ui_notice')),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryYellow,
              foregroundColor: AppConstants.primaryDarkBlue,
            ),
            child: Text(AppTranslations.t('ui_ok')),
          ),
        ],
      ),
    );
  }

  void _saveProduct(bool isEditing, Product? existingProduct, 
      TextEditingController nameController, TextEditingController priceController,
      TextEditingController quantityController, TextEditingController lowStockController,
      TextEditingController unitController, TextEditingController categoryController, 
      TextEditingController imageController, {String? code}) async {
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    if (auth.currentUser?.id == null) return;

    final product = Product(
      id: isEditing ? existingProduct!.id : null,
      userId: auth.currentUser!.id!,
      name: nameController.text,
      code: existingProduct?.code ?? code ?? 'P${DateTime.now().millisecondsSinceEpoch}',
      price: double.tryParse(priceController.text) ?? 0,
      quantity: int.tryParse(quantityController.text) ?? 0,
      lowStock: int.tryParse(lowStockController.text) ?? 5,
      unit: unitController.text,
      category: categoryController.text.isNotEmpty ? categoryController.text : null,
      image: imageController.text.isNotEmpty ? imageController.text : null,
    );

    bool success;
    if (isEditing) {
      success = await app.updateProduct(product);
    } else {
      success = await app.addProduct(product);
    }

    Navigator.pop(context);
    
    if (success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? AppTranslations.t('ui_product_updated_successfully') : AppTranslations.t('ui_product_added_successfully'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppConstants.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.t('ui_an_error_occurred_please_try_again'),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
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

  void _showDeleteConfirmDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppConstants.errorRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppTranslations.t('ui_confirm_deletion'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: AppConstants.textDarkGray),
                children: [
                  TextSpan(text: AppTranslations.t('ui_do_you_want_to_delete_product')),
                  TextSpan(
                    text: '"${product.name}"',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: AppTranslations.t('ui_delete_product_suffix')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstants.errorRed.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: AppConstants.errorRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppTranslations.t('ui_note_if_this_product_has_been'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.textDarkGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.t('ui_cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () => _deleteProduct(product),
            icon: const Icon(Icons.delete_rounded),
            label: Text(AppTranslations.t('ui_delete_product')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorRed,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(Product product) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    // Store the ScaffoldMessenger state at the very beginning to ensure we have a valid reference
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    Navigator.pop(context);
    
    try {
      final success = await app.deleteProduct(product.id!, auth.currentUser!.id!);
      
      if (success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadData();
        });
        
        // Use a delayed callback to show snackbar after dialog is completely dismissed
        Future.delayed(Duration(milliseconds: 100), () {
          // Show snackbar using the stored scaffold messenger reference
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppTranslations.t('ui_product_deleted_successfully'),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: AppConstants.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        });
      } else {
        // Use a delayed callback to show snackbar after dialog is completely dismissed
        Future.delayed(Duration(milliseconds: 100), () {
          // Show snackbar using the stored scaffold messenger reference
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppTranslations.t('ui_unable_to_delete_the_product_please'),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: AppConstants.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        });
      }
    } catch (e) {
      // Use a delayed callback to show snackbar after dialog is completely dismissed
      Future.delayed(Duration(milliseconds: 100), () {
        // Show snackbar using the stored scaffold messenger reference
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppTranslations.t('ui_an_error_occurred', [e.toString()]),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppConstants.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      });
    }
  }

  void _showAddStockDialog(Product product) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_box_rounded,
                color: AppConstants.primaryDarkBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.t('ui_add_stock'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.lightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    color: AppConstants.primaryDarkBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.t('ui_current_stock', [product.quantity, product.unit]),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppTranslations.t('ui_quantity_to_add'),
                hintText: AppTranslations.t('ui_enter_quantity_to_add'),
                prefixIcon: const Icon(Icons.add_rounded),
                suffix: Text(product.unit),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppConstants.primaryYellow),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.t('ui_cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () => _addStock(product, controller.text),
            icon: const Icon(Icons.add_rounded),
            label: Text(AppTranslations.t('ui_add_stock')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryYellow,
              foregroundColor: AppConstants.primaryDarkBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _addStock(Product product, String amountText) async {
    final amount = int.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.t('ui_please_enter_a_valid_quantity')),
          backgroundColor: AppConstants.errorRed,
        ),
      );
      return;
    }
    
    final app = Provider.of<AppProvider>(context, listen: false);
    final updatedProduct = product.copyWith(quantity: product.quantity + amount);
    
    Navigator.pop(context);
    
    final success = await app.updateProduct(updatedProduct);
    if (success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppTranslations.t('ui_added_of_to_stock_successfully', [product.name, amount, product.unit]),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppConstants.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.t('ui_error_adding_stock'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.download_rounded),
            SizedBox(width: 8),
            Text(AppTranslations.t('ui_export_product_data')),
          ],
        ),
        content: Text(AppTranslations.t('ui_the_export_feature_will_be_available')),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryYellow,
              foregroundColor: AppConstants.primaryDarkBlue,
            ),
            child: Text(AppTranslations.t('ui_ok')),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.upload_rounded),
            SizedBox(width: 8),
            Text(AppTranslations.t('ui_import_product_data')),
          ],
        ),
        content: Text(AppTranslations.t('ui_the_import_feature_will_be_available')),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryYellow,
              foregroundColor: AppConstants.primaryDarkBlue,
            ),
            child: Text(AppTranslations.t('ui_ok')),
          ),
        ],
      ),
    );
  }

  // Capture image from camera for products
  Future<void> _captureImage(BuildContext context, TextEditingController imageController) async {
    final XFile? image = await AppUtils.captureImage();
    if (image != null) {
      // Save image to documents directory
      final savedPath = await AppUtils.saveImageToDocuments(image);
      if (savedPath != null) {
        // Update the image controller with the saved path
        imageController.text = savedPath;
      } else {
        // Show error if failed to save
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.t('ui_unable_to_save_the_image')),
            backgroundColor: AppConstants.errorRed,
          ),
        );
      }
    }
  }

  // Pick image from gallery for products
  Future<void> _pickImageFromGallery(BuildContext context, TextEditingController imageController) async {
    final XFile? image = await AppUtils.pickImageFromGallery();
    if (image != null) {
      // Save image to documents directory
      final savedPath = await AppUtils.saveImageToDocuments(image);
      if (savedPath != null) {
        // Update the image controller with the saved path
        imageController.text = savedPath;
      } else {
        // Show error if failed to save
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.t('ui_unable_to_save_the_image')),
            backgroundColor: AppConstants.errorRed,
          ),
        );
      }
    }
  }

}
