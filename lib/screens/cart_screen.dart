import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../core/constants.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, app, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: app.cartItems.isEmpty
                          ? _buildEmptyCart()
                          : Column(
                              children: [
                                Expanded(child: _buildCartItems(app)),
                                _buildCartSummary(app),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
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
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ตะกร้าสินค้า',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Fixed: Remove Consumer to prevent setState during build
                Builder(
                  builder: (context) {
                    final app = Provider.of<AppProvider>(context, listen: false);
                    return Text(
                      '${app.cartItems.length} รายการ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Fixed: Remove Consumer to prevent setState during build
          Builder(
            builder: (context) {
              final app = Provider.of<AppProvider>(context, listen: false);
              if (app.cartItems.isEmpty) return const SizedBox();
              
              return IconButton(
                onPressed: () => _showClearCartDialog(app),
                icon: const Icon(
                  Icons.delete_sweep,
                  color: Colors.white,
                  size: 24,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: AppConstants.primaryDarkBlue.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ตะกร้าสินค้าว่างเปล่า',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เริ่มเพิ่มสินค้าโดยการสแกน QR หรือเลือกจากรายการสินค้า',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppConstants.scannerRoute),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('สแกน QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryDarkBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppConstants.productsRoute),
                    icon: const Icon(Icons.inventory_2),
                    label: const Text('เลือกสินค้า'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryDarkBlue,
                      side: const BorderSide(color: AppConstants.primaryDarkBlue),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  Widget _buildCartItems(AppProvider app) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: app.cartItems.length,
      itemBuilder: (context, index) {
        final cartItem = app.cartItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Product Image
                    _buildProductImage(cartItem.product),
                    const SizedBox(width: 16),
                    
                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cartItem.product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'รหัส: ${cartItem.product.code}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${NumberFormat('#,##0.00').format(cartItem.product.price)}/${cartItem.product.unit}',
                            style: TextStyle(
                              color: AppConstants.primaryDarkBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Remove button
                    IconButton(
                      onPressed: () => _showRemoveItemDialog(app, cartItem),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red[400],
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Quantity controls and total
                Row(
                  children: [
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: cartItem.quantity > 1
                                ? () => _updateCartItemQuantity(app, cartItem, cartItem.quantity - 1)
                                : null,
                            icon: const Icon(Icons.remove),
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            padding: EdgeInsets.zero,
                            color: cartItem.quantity > 1 
                                ? AppConstants.primaryDarkBlue 
                                : Colors.grey[400],
                          ),
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.symmetric(
                                vertical: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Text(
                              '${cartItem.quantity}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: cartItem.quantity < cartItem.product.quantity
                                ? () => _updateCartItemQuantity(app, cartItem, cartItem.quantity + 1)
                                : null,
                            icon: const Icon(Icons.add),
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            padding: EdgeInsets.zero,
                            color: cartItem.quantity < cartItem.product.quantity 
                                ? AppConstants.primaryDarkBlue 
                                : Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Item total
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'รวม',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '฿${NumberFormat('#,##0.00').format(cartItem.totalPrice)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppConstants.primaryDarkBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Stock warning
                if (cartItem.quantity >= cartItem.product.quantity)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange[700],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'สต็อกไม่เพียงพอ',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
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
    );
  }

  void _updateCartItemQuantity(AppProvider app, CartItem cartItem, int newQuantity) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser?.id != null) {
      app.updateCartItemQuantityWithPersistence(auth.currentUser!.id!, cartItem.product.id!, newQuantity);
    } else {
      app.updateCartItemQuantity(cartItem.product.id!, newQuantity);
    }
  }

  void _showRemoveItemDialog(AppProvider app, CartItem cartItem) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบออกจากตะกร้า'),
        content: Text('คุณต้องการลบ \"${cartItem.product.name}\" ออกจากตะกร้าหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              // Store the ScaffoldMessenger state at the very beginning to ensure we have a valid reference
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              if (auth.currentUser?.id != null) {
                app.removeFromCartWithPersistence(auth.currentUser!.id!, cartItem.product.id!);
              } else {
                app.removeFromCart(cartItem.product.id!);
              }
              Navigator.pop(context);
              
              // Use a delayed callback to show snackbar after dialog is completely dismissed
              Future.delayed(Duration(milliseconds: 50), () {
                // Show snackbar using the stored scaffold messenger reference
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('ลบ ${cartItem.product.name} ออกจากตะกร้าแล้ว'),
                    backgroundColor: AppConstants.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(AppProvider app) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ล้างตะกร้าสินค้า'),
        content: const Text('คุณต้องการล้างสินค้าทั้งหมดในตะกร้าหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              // Store the ScaffoldMessenger state at the very beginning to ensure we have a valid reference
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              if (auth.currentUser?.id != null) {
                app.clearCartWithPersistence(auth.currentUser!.id!);
              } else {
                app.clearCart();
              }
              Navigator.pop(context);
              
              // Use a delayed callback to show snackbar after dialog is completely dismissed
              Future.delayed(Duration(milliseconds: 100), () {
                // Show snackbar using the stored scaffold messenger reference
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('ล้างสินค้าในตะกร้าแล้ว'),
                    backgroundColor: AppConstants.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ล้างตะกร้า'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      width: 60,
      height: 60,
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
                  // Log the error for debugging
                  print('Image loading error in cart: $error');
                  return Icon(
                    Icons.inventory_2,
                    color: AppConstants.primaryDarkBlue,
                    size: 24,
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
              size: 24,
            ),
    );
  }

  Widget _buildCartSummary(AppProvider app) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายการสินค้า (${app.cartItemCount} ชิ้น)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '฿${NumberFormat('#,##0.00').format(app.cartTotal)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            const Divider(),
            const SizedBox(height: 8),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรวมทั้งสิ้น',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '฿${NumberFormat('#,##0.00').format(app.cartTotal)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryDarkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppConstants.scannerRoute),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('เพิ่มสินค้า'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryDarkBlue,
                      side: const BorderSide(color: AppConstants.primaryDarkBlue),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _canProceedToPayment(app) ? () => _proceedToPayment() : null,
                    icon: const Icon(Icons.payment),
                    label: const Text('ชำระเงิน'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryDarkBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Stock warning if any
            if (_hasStockWarnings(app))
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'มีสินค้าบางรายการที่จำนวนในตะกร้าเกินสต็อกที่มี กรุณาปรับจำนวนก่อนชำระเงิน',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
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
  }

  bool _canProceedToPayment(AppProvider app) {
    if (app.cartItems.isEmpty) return false;
    
    // Check if any items exceed available stock
    for (var item in app.cartItems) {
      if (item.quantity > item.product.quantity) {
        return false;
      }
    }
    return true;
  }

  bool _hasStockWarnings(AppProvider app) {
    return app.cartItems.any((item) => item.quantity > item.product.quantity);
  }

  void _proceedToPayment() {
    Navigator.pushNamed(context, AppConstants.paymentRoute);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}