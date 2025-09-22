import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ProductsScreen({Key? key, this.arguments}) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
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
        child: FloatingActionButton.extended(
          onPressed: () => _showAddProductDialog(),
          backgroundColor: AppConstants.primaryYellow,
          foregroundColor: AppConstants.primaryDarkBlue,
          elevation: 8,
          icon: const Icon(Icons.add_rounded),
          label: const Text('เพิ่มสินค้า', style: TextStyle(fontWeight: FontWeight.w600)),
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
        title: const Text(
          'จัดการสินค้า',
          style: TextStyle(
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
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'รีเฟรช',
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
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download_rounded),
                  SizedBox(width: 8),
                  Text('ส่งออกข้อมูล'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.upload_rounded),
                  SizedBox(width: 8),
                  Text('นำเข้าข้อมูล'),
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
                hintText: 'ค้นหาสินค้า, รหัส, หรือหมวดหมู่...',
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
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('เรียงตามชื่อ')),
                      DropdownMenuItem(value: 'price', child: Text('เรียงตามราคา')),
                      DropdownMenuItem(value: 'quantity', child: Text('เรียงตามจำนวน')),
                      DropdownMenuItem(value: 'category', child: Text('เรียงตามหมวดหมู่')),
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
                      tooltip: 'มุมมองรายการ',
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
                      tooltip: 'มุมมองตาราง',
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
    final productCount = _filteredProducts.length;
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
                  Text('สินค้าทั้งหมด ($productCount)'),
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
                  Text('สต็อกต่ำ ($lowStockCount)'),
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
            'กำลังโหลดข้อมูลสินค้า...',
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
        title: _searchQuery.isEmpty ? 'ยังไม่มีสินค้า' : 'ไม่พบสินค้า',
        subtitle: _searchQuery.isEmpty 
          ? 'เริ่มต้นด้วยการเพิ่มสินค้าแรกของคุณ'
          : 'ลองเปลี่ยนคำค้นหาหรือปรับเกณฑ์การค้นหา',
        actionText: _searchQuery.isEmpty ? 'เพิ่มสินค้าแรก' : 'ล้างการค้นหา',
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
        title: 'สต็อกสินค้าเพียงพอ',
        subtitle: 'ไม่มีสินค้าที่มีสต็อกต่ำในขณะนี้',
      );
    }
    
    return _isGridView ? _buildProductsGrid() : _buildProductsListView();
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
                              constraints: const BoxConstraints(maxWidth: 65),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.category!,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppConstants.primaryDarkBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'รหัส: ${product.code}',
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
                                color: isLowStock 
                                  ? AppConstants.errorRed.withOpacity(0.1)
                                  : AppConstants.successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${product.quantity} ${product.unit}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isLowStock 
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
                                'สต็อกต่ำ! ควรเติมสต็อก',
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
                  width: 36,
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: () => _addToCart(product),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                        color: AppConstants.primaryDarkBlue,
                        tooltip: 'เพิ่มในตะกร้า',
                        padding: const EdgeInsets.all(0),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 4),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, 
                          color: Colors.grey[600], size: 20),
                        onSelected: (value) => _handleProductAction(value, product),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'addStock',
                            child: Row(
                              children: [
                                Icon(Icons.add_box_rounded, size: 16),
                                SizedBox(width: 6),
                                Text('เติมสต็อก', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 16),
                                SizedBox(width: 6),
                                Text('แก้ไข', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, color: Colors.red, size: 16),
                                SizedBox(width: 6),
                                Text('ลบ', style: TextStyle(color: Colors.red, fontSize: 12)),
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
                      Icons.inventory_2_rounded,
                      size: 12,
                      color: isLowStock ? AppConstants.errorRed : Colors.grey[600],
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${product.quantity} ${product.unit}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isLowStock ? AppConstants.errorRed : Colors.grey[600],
                          fontWeight: isLowStock ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppConstants.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'สต็อกต่ำ',
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
                        onPressed: () => _addToCart(product),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                        color: AppConstants.primaryDarkBlue,
                        tooltip: 'เพิ่มในตะกร้า',
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, 
                          color: Colors.grey[600], size: 20),
                        onSelected: (value) => _handleProductAction(value, product),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'addStock',
                            child: Row(
                              children: [
                                Icon(Icons.add_box_rounded, size: 16),
                                SizedBox(width: 6),
                                Text('เติมสต็อก', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 16),
                                SizedBox(width: 6),
                                Text('แก้ไข', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, color: Colors.red, size: 16),
                                SizedBox(width: 6),
                                Text('ลบ', style: TextStyle(color: Colors.red, fontSize: 12)),
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

  void _addToCart(Product product) {
    _showAddToCartDialog(product);
  }

  void _showAddProductDialog({String? prefilledCode}) {
    _showProductFormDialog(null, prefilledCode);
  }

  void _showEditProductDialog(Product product) {
    _showProductFormDialog(product, null);
  }

  void _showProductFormDialog(Product? product, String? prefilledCode) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final quantityController = TextEditingController(text: product?.quantity.toString() ?? '');
    final lowStockController = TextEditingController(text: product?.lowStock.toString() ?? '5');
    final unitController = TextEditingController(text: product?.unit ?? 'ชิ้น');
    final categoryController = TextEditingController(text: product?.category ?? '');
    final imageController = TextEditingController(text: product?.image ?? '');
    
    final List<String> categories = [
      'อาหารและเครื่องดื่ม',
      'ของใช้ในบ้าน',
      'เครื่องเขียน',
      'ยาและอุปกรณ์การแพทย์',
      'เสื้อผ้าและเครื่องแต่งกาย',
      'อิเล็กทรอนิกส์',
      'เครื่องใช้ในครัว',
      'อื่นๆ'
    ];
    
    String? selectedCategory = product?.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isEditing 
                        ? AppConstants.primaryDarkBlue 
                        : AppConstants.primaryYellow,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEditing ? Icons.edit_rounded : Icons.add_rounded,
                          color: isEditing ? Colors.white : AppConstants.primaryDarkBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEditing ? 'แก้ไขสินค้า' : 'เพิ่มสินค้าใหม่',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isEditing ? Colors.white : AppConstants.primaryDarkBlue,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isEditing ? Colors.white : AppConstants.primaryDarkBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildFormField(
                            controller: nameController,
                            label: 'ชื่อสินค้า',
                            icon: Icons.inventory_2_rounded,
                            required: true,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  controller: priceController,
                                  label: 'ราคา',
                                  icon: Icons.attach_money_rounded,
                                  keyboardType: TextInputType.number,
                                  required: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFormField(
                                  controller: quantityController,
                                  label: 'จำนวน',
                                  icon: Icons.numbers_rounded,
                                  keyboardType: TextInputType.number,
                                  required: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  controller: lowStockController,
                                  label: 'จุดเตือนสต็อกต่ำ',
                                  icon: Icons.warning_rounded,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFormField(
                                  controller: unitController,
                                  label: 'หน่วย',
                                  icon: Icons.scale_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppConstants.lightGray,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              hint: const Text('เลือกหมวดหมู่'),
                              decoration: InputDecoration(
                                labelText: 'หมวดหมู่',
                                prefixIcon: Icon(Icons.category_rounded, 
                                  color: AppConstants.primaryDarkBlue),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              ),
                              items: categories.map((String category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCategory = newValue;
                                  categoryController.text = newValue ?? '';
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            controller: imageController,
                            label: 'ลิงค์รูปภาพ',
                            icon: Icons.image_rounded,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppConstants.primaryDarkBlue.withOpacity(0.3),
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextButton.icon(
                              onPressed: () => _showImageUploadOptions(context, imageController),
                              icon: const Icon(Icons.cloud_upload_rounded),
                              label: const Text('อัปโหลดรูปภาพ'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppConstants.primaryDarkBlue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('ยกเลิก'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () => _saveProduct(
                              isEditing, product, nameController, priceController,
                              quantityController, lowStockController, unitController, 
                              categoryController, imageController,
                            ),
                            icon: Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
                            label: Text(isEditing ? 'บันทึก' : 'เพิ่มสินค้า'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEditing 
                                ? AppConstants.primaryDarkBlue 
                                : AppConstants.primaryYellow,
                              foregroundColor: isEditing 
                                ? Colors.white 
                                : AppConstants.primaryDarkBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
            const Text(
              'เลือกวิธีอัปโหลดรูปภาพ',
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
              title: const Text('ใช้ลิงค์รูปภาพ'),
              subtitle: const Text('ใส่ URL ของรูปภาพจากอินเทอร์เน็ต'),
              onTap: () {
                Navigator.pop(context);
                _showImageUrlDialog(imageController);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt_rounded, color: Colors.grey[600]),
              ),
              title: const Text('ถ่ายรูป'),
              subtitle: const Text('ใช้กล้องเพื่อถ่ายรูปสินค้า (เร็วๆ นี้)'),
              enabled: false,
              onTap: () {
                Navigator.pop(context);
                _showImageNotAvailableDialog('การถ่ายรูปจะใช้งานได้ในเวอร์ชันถัดไป');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library_rounded, color: Colors.grey[600]),
              ),
              title: const Text('เลือกจากแกลเลอรี่'),
              subtitle: const Text('เลือกรูปจากแกลเลอรี่ในเครื่อง (เร็วๆ นี้)'),
              enabled: false,
              onTap: () {
                Navigator.pop(context);
                _showImageNotAvailableDialog('การเลือกจากแกลเลอรี่จะใช้งานได้ในเวอร์ชันถัดไป');
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
        title: const Row(
          children: [
            Icon(Icons.link_rounded),
            SizedBox(width: 8),
            Text('ใส่ลิงค์รูปภาพ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL ของรูปภาพ',
                hintText: 'https://example.com/image.jpg',
                prefixIcon: Icon(Icons.image_rounded),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Text(
              'ใส่ลิงค์รูปภาพที่สามารถเข้าถึงได้จากอินเทอร์เน็ต',
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
            child: const Text('ยกเลิก'),
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
            child: const Text('บันทึก'),
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
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('แจ้งเตือน'),
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
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _saveProduct(bool isEditing, Product? existingProduct, 
      TextEditingController nameController, TextEditingController priceController,
      TextEditingController quantityController, TextEditingController lowStockController,
      TextEditingController unitController, TextEditingController categoryController, 
      TextEditingController imageController) async {
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    if (auth.currentUser?.id == null) return;

    final product = Product(
      id: isEditing ? existingProduct!.id : null,
      userId: auth.currentUser!.id!,
      name: nameController.text,
      code: existingProduct?.code ?? 'P${DateTime.now().millisecondsSinceEpoch}',
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
                isEditing ? 'อัพเดทสินค้าสำเร็จ' : 'เพิ่มสินค้าสำเร็จ',
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
              const Text(
                'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
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
            const Expanded(
              child: Text(
                'ยืนยันการลบ',
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
                  const TextSpan(text: 'คุณต้องการลบสินค้า '),
                  TextSpan(
                    text: '"${product.name}"',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' ใช่หรือไม่?'),
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
                  const Expanded(
                    child: Text(
                      'หมายเหตุ: หากสินค้านี้เคยถูกขายไปแล้ว ระบบจะลบประวัติการขายที่เกี่ยวข้องด้วย',
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
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton.icon(
            onPressed: () => _deleteProduct(product),
            icon: const Icon(Icons.delete_rounded),
            label: const Text('ลบสินค้า'),
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
    
    Navigator.pop(context);
    
    try {
      final success = await app.deleteProduct(product.id!, auth.currentUser!.id!);
      
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
                const Text(
                  'ลบสินค้าสำเร็จ',
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
                const Text(
                  'ไม่สามารถลบสินค้าได้ กรุณาลองใหม่อีกครั้ง',
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
    } catch (e) {
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
                'เกิดข้อผิดพลาด: ${e.toString()}',
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
                  const Text(
                    'เพิ่มสต็อก',
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
                    'สต็อกปัจจุบัน: ${product.quantity} ${product.unit}',
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
                labelText: 'จำนวนที่ต้องการเพิ่ม',
                hintText: 'ใส่จำนวนที่ต้องการเพิ่ม',
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
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton.icon(
            onPressed: () => _addStock(product, controller.text),
            icon: const Icon(Icons.add_rounded),
            label: const Text('เพิ่มสต็อก'),
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
        const SnackBar(
          content: Text('กรุณาใส่จำนวนที่ถูกต้อง'),
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
              Text(
                'เพิ่มสต็อก ${product.name} จำนวน $amount ${product.unit} สำเร็จ',
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
    }
  }

  void _showAddToCartDialog(Product product) {
    final TextEditingController quantityController = TextEditingController(text: '1');
    int quantity = 1;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
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
                      const Text(
                        'เพิ่มในตะกร้า',
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
                        'สต็อกคงเหลือ: ${product.quantity} ${product.unit}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('จำนวน:'),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        if (quantity > 1) {
                          setState(() {
                            quantity--;
                            quantityController.text = quantity.toString();
                          });
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: AppConstants.primaryDarkBlue,
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final newQuantity = int.tryParse(value) ?? 1;
                          if (newQuantity >= 1 && newQuantity <= product.quantity) {
                            setState(() {
                              quantity = newQuantity;
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (quantity < product.quantity) {
                          setState(() {
                            quantity++;
                            quantityController.text = quantity.toString();
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppConstants.primaryDarkBlue,
                    ),
                  ],
                ),
                if (quantity > product.quantity) ...[
                  const SizedBox(height: 8),
                  Text(
                    'จำนวนที่ระบุเกินสต็อกที่มี',
                    style: TextStyle(color: AppConstants.errorRed, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton.icon(
                onPressed: quantity > product.quantity 
                  ? null 
                  : () {
                      Navigator.pop(context);
                      _addToCartWithQuantity(product, quantity);
                    },
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('เพิ่มในตะกร้า'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryYellow,
                  foregroundColor: AppConstants.primaryDarkBlue,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addToCartWithQuantity(Product product, int quantity) {
    final app = Provider.of<AppProvider>(context, listen: false);
    app.addToCart(product, quantity: quantity);
    
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
                'เพิ่ม ${product.name} จำนวน $quantity ${product.unit} ในตะกร้าแล้ว',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppConstants.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showProductDetailsDialog(Product product) {
    final isLowStock = product.quantity <= product.lowStock;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    _buildEnhancedProductImage(product, size: 60),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'รหัส: ${product.code}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryYellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.attach_money_rounded,
                                    color: AppConstants.primaryDarkBlue,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ราคา',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    AppUtils.formatCurrency(product.price),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppConstants.primaryDarkBlue,
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
                                color: isLowStock 
                                  ? AppConstants.errorRed.withOpacity(0.1)
                                  : AppConstants.successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inventory_2_rounded,
                                    color: isLowStock 
                                      ? AppConstants.errorRed
                                      : AppConstants.successGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'จำนวน',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${product.quantity} ${product.unit}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isLowStock 
                                        ? AppConstants.errorRed
                                        : AppConstants.successGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('หมวดหมู่', product.category ?? 'ไม่ระบุ', Icons.category_rounded),
                      _buildInfoRow('หน่วย', product.unit, Icons.scale_rounded),
                      _buildInfoRow('จุดเตือนสต็อกต่ำ', '${product.lowStock}', Icons.warning_rounded),
                      if (product.createdAt != null)
                        _buildInfoRow('วันที่สร้าง', 
                          AppUtils.formatDateTimeThai(product.createdAt!), 
                          Icons.calendar_today_rounded),
                      if (isLowStock) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
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
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'สต็อกต่ำ! ควรเติมสต็อกโดยเร็ว',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.errorRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _addToCart(product);
                        },
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text('เพิ่มในตะกร้า'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditProductDialog(product);
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('แก้ไข'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryYellow,
                          foregroundColor: AppConstants.primaryDarkBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmDialog(product);
                        },
                        icon: const Icon(Icons.delete_rounded),
                        label: const Text('ลบ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.errorRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded),
            SizedBox(width: 8),
            Text('ส่งออกข้อมูลสินค้า'),
          ],
        ),
        content: const Text('ฟีเจอร์ส่งออกข้อมูลจะพร้อมใช้งานในเวอร์ชันถัดไป'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryYellow,
              foregroundColor: AppConstants.primaryDarkBlue,
            ),
            child: const Text('ตกลง'),
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
        title: const Row(
          children: [
            Icon(Icons.upload_rounded),
            SizedBox(width: 8),
            Text('นำเข้าข้อมูลสินค้า'),
          ],
        ),
        content: const Text('ฟีเจอร์นำเข้าข้อมูลจะพร้อมใช้งานในเวอร์ชันถัดไป'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryYellow,
              foregroundColor: AppConstants.primaryDarkBlue,
            ),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
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
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}