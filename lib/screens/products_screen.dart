// FILE: lib/screens/products_screen.dart
import 'package:flutter/material.dart';
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
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  bool _isLoading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
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
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isLoading = true);
    });
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    if (auth.currentUser?.id != null) {
      await app.loadProducts(auth.currentUser!.id!);
    }
    
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isLoading = false);
      _searchProducts();
    });
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
    _searchProducts();
  }

  void _searchProducts() {
    final app = Provider.of<AppProvider>(context, listen: false);
    List<Product> products = app.products;

    if (_searchQuery.isNotEmpty) {
      products = products.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               product.code.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _filteredProducts = products);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      appBar: AppBar(
        title: const Text('จัดการสินค้า'),
        backgroundColor: AppConstants.primaryDarkBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: _isLoading ? _buildLoadingWidget() : _buildTabContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(),
        backgroundColor: AppConstants.primaryYellow,
        foregroundColor: AppConstants.primaryDarkBlue,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสินค้า'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ค้นหาสินค้า...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppConstants.lightGray,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    // Get the product count safely without causing rebuild issues
    final productCount = _filteredProducts.length;
    
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppConstants.primaryDarkBlue,
        unselectedLabelColor: AppConstants.textDarkGray,
        indicatorColor: AppConstants.primaryYellow,
        tabs: [
          Tab(text: 'สินค้าทั้งหมด ($productCount)'),
          const Tab(text: 'สต็อกต่ำ'),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(color: AppConstants.primaryYellow),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'ยังไม่มีสินค้า' : 'ไม่พบสินค้า',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index]),
    );
  }

  Widget _buildLowStockList() {
    // Fixed: Remove Consumer to prevent setState during build
    // Using static data approach with direct provider access
    final app = Provider.of<AppProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (auth.currentUser?.id == null) {
      return _buildLoadingWidget();
    }
    
    // Filter low stock products from existing data
    final lowStockProducts = app.products
        .where((p) => p.quantity <= p.lowStock)
        .take(10)
        .toList();
    
    if (lowStockProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('สต็อกสินค้าเพียงพอ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lowStockProducts.length,
      itemBuilder: (context, index) => _buildLowStockCard(lowStockProducts[index]),
    );
  }

  Widget _buildProductCard(Product product) {
    final isLowStock = product.quantity <= product.lowStock;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildProductImage(product),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รหัส: ${product.code}'),
            Text('${AppUtils.formatCurrency(product.price)} | เหลือ ${product.quantity} ${product.unit}'),
            if (isLowStock)
              Text('สต็อกต่ำ!', style: TextStyle(color: AppConstants.errorRed, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _addToCart(product),
              icon: const Icon(Icons.add_shopping_cart, color: AppConstants.primaryDarkBlue),
              tooltip: 'เพิ่มในตะกร้า',
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleProductAction(value, product),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'addToCart', child: Text('เพิ่มในตะกร้า')),
                const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                const PopupMenuItem(value: 'delete', child: Text('ลบ')),
              ],
            ),
          ],
        ),
        onTap: () => _showProductDetailsDialog(product),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      width: 50,
      height: 50,
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
    );
  }

  Widget _buildLowStockCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppConstants.errorRed.withOpacity(0.05),
      child: ListTile(
        leading: _buildProductImage(product),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('เหลือ ${product.quantity} ${product.unit} (เตือนที่ ${product.lowStock})'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _showAddStockDialog(product),
              child: const Text('เพิ่มสต็อก'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _addToCart(product),
              icon: const Icon(Icons.add_shopping_cart),
              tooltip: 'เพิ่มในตะกร้า',
            ),
          ],
        ),
        onTap: () => _showProductDetailsDialog(product),
      ),
    );
  }

  void _handleProductAction(String action, Product product) {
    switch (action) {
      case 'addToCart':
        _addToCart(product);
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
    final app = Provider.of<AppProvider>(context, listen: false);
    app.addToCart(product);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เพิ่ม ${product.name} ในตะกร้าแล้ว'),
        backgroundColor: AppConstants.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
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
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final quantityController = TextEditingController(text: product?.quantity.toString() ?? '');
    final lowStockController = TextEditingController(text: product?.lowStock.toString() ?? '5');
    final unitController = TextEditingController(text: product?.unit ?? 'ชิ้น');
    final categoryController = TextEditingController(text: product?.category ?? '');
    final imageController = TextEditingController(text: product?.image ?? '');
    
    // Predefined categories
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
          return AlertDialog(
            title: Text(isEditing ? 'แก้ไขสินค้า' : 'เพิ่มสินค้าใหม่'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController, 
                    decoration: const InputDecoration(
                      labelText: 'ชื่อสินค้า',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppConstants.lightGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController, 
                    decoration: const InputDecoration(
                      labelText: 'ราคา',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppConstants.lightGray,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController, 
                    decoration: const InputDecoration(
                      labelText: 'จำนวน',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppConstants.lightGray,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lowStockController, 
                    decoration: const InputDecoration(
                      labelText: 'จุดเตือนสต็อกต่ำ',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppConstants.lightGray,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: unitController, 
                    decoration: const InputDecoration(
                      labelText: 'หน่วย',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppConstants.lightGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    hint: const Text('เลือกหมวดหมู่'),
                    decoration: const InputDecoration(
                      labelText: 'หมวดหมู่',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppConstants.lightGray,
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageController, 
                    decoration: const InputDecoration(
                      labelText: 'ลิงค์รูปภาพ',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppConstants.lightGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Add image upload button
                  ElevatedButton.icon(
                    onPressed: () => _showImageUploadOptions(context, imageController),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('อัปโหลดรูปภาพ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryDarkBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () => _saveProduct(
                  isEditing, product, nameController, priceController,
                  quantityController, lowStockController, unitController, categoryController, imageController,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEditing ? AppConstants.primaryDarkBlue : AppConstants.primaryYellow,
                  foregroundColor: isEditing ? Colors.white : AppConstants.primaryDarkBlue,
                ),
                child: Text(isEditing ? 'บันทึก' : 'เพิ่ม'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImageUploadOptions(BuildContext context, TextEditingController imageController) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'เลือกวิธีอัปโหลดรูปภาพ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('ใช้ลิงก์รูปภาพ'),
              onTap: () {
                Navigator.pop(context);
                _showImageUrlDialog(imageController);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(context);
                _showImageNotAvailableDialog('การถ่ายรูปจะใช้งานได้ในเวอร์ชันถัดไป');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากแกลเลอรี่'),
              onTap: () {
                Navigator.pop(context);
                _showImageNotAvailableDialog('การเลือกจากแกลเลอรี่จะใช้งานได้ในเวอร์ชันถัดไป');
              },
            ),
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
        title: const Text('ใส่ลิงค์รูปภาพ'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'URL ของรูปภาพ',
            border: OutlineInputBorder(),
          ),
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
              Navigator.pop(context);
            },
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
        title: const Text('แจ้งเตือน'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _saveProduct(bool isEditing, Product? existingProduct, TextEditingController nameController,
      TextEditingController priceController,
      TextEditingController quantityController, TextEditingController lowStockController,
      TextEditingController unitController, TextEditingController categoryController, TextEditingController imageController) async {
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    if (auth.currentUser?.id == null) return;

    final product = Product(
      id: isEditing ? existingProduct!.id : null,
      userId: auth.currentUser!.id!,
      name: nameController.text,
      // Generate a random code instead of using user input
      code: existingProduct?.code ?? 'P${DateTime.now().millisecondsSinceEpoch}',
      price: double.tryParse(priceController.text) ?? 0,
      quantity: int.tryParse(quantityController.text) ?? 0,
      lowStock: int.tryParse(lowStockController.text) ?? 5,
      unit: unitController.text,
      category: categoryController.text.isNotEmpty ? categoryController.text : null,
      image: imageController.text.isNotEmpty ? imageController.text : null,
      // createdAt and updatedAt will be set automatically by the Product constructor
    );

    bool success;
    if (isEditing) {
      success = await app.updateProduct(product);
    } else {
      success = await app.addProduct(product);
    }

    Navigator.pop(context);
    
    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'อัพเดทสินค้าสำเร็จ' : 'เพิ่มสินค้าสำเร็จ')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาด'), backgroundColor: AppConstants.errorRed),
      );
    }
  }

  void _showDeleteConfirmDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการลบสินค้า "${product.name}" ใช่หรือไม่?'),
            const SizedBox(height: 12),
            const Text(
              'หมายเหตุ: หากสินค้านี้เคยถูกขายไปแล้ว ระบบจะลบประวัติการขายที่เกี่ยวข้องด้วย',
              style: TextStyle(
                fontSize: 12,
                color: AppConstants.textDarkGray,
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
            onPressed: () => _deleteProduct(product),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorRed),
            child: const Text('ลบ'),
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
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบสินค้าสำเร็จ'),
            backgroundColor: AppConstants.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถลบสินค้าได้ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: AppConstants.errorRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  void _showAddStockDialog(Product product) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('เพิ่มสต็อก - ${product.name}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'จำนวนที่เพิ่ม',
            hintText: 'ปัจจุบัน: ${product.quantity} ${product.unit}',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => _addStock(product, controller.text),
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  void _addStock(Product product, String amountText) async {
    final amount = int.tryParse(amountText) ?? 0;
    if (amount <= 0) return;
    
    final app = Provider.of<AppProvider>(context, listen: false);
    final updatedProduct = product.copyWith(quantity: product.quantity + amount);
    
    Navigator.pop(context);
    
    final success = await app.updateProduct(updatedProduct);
    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เพิ่มสต็อก ${product.name} สำเร็จ')),
      );
    }
  }

  void _showProductDetailsDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(product),
            const SizedBox(height: 8),
            Text('รหัส: ${product.code}'),
            Text('ราคา: ${AppUtils.formatCurrency(product.price)}'),
            Text('จำนวน: ${product.quantity} ${product.unit}'),
            Text('หมวดหมู่: ${product.category}'),
            Text('จุดเตือนสต็อกต่ำ: ${product.lowStock}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addToCart(product);
            },
            child: const Text('เพิ่มในตะกร้า'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditProductDialog(product);
            },
            child: const Text('แก้ไข'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}