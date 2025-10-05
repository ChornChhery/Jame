import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../models/sale.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      appBar: AppBar(
        title: Text('การแจ้งเตือน'),
        backgroundColor: AppConstants.primaryDarkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer2<AuthProvider, AppProvider>(
        builder: (context, auth, app, child) {
          // Get low stock products
          final lowStockProducts = app.products
              .where((product) => product.quantity <= product.lowStock)
              .toList();
          
          // Get cart items
          final cartItems = app.cartItems.toList();
          
          return Column(
            children: [
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppConstants.primaryDarkBlue,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppConstants.textDarkGray,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber, size: 16),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'สินค้าใกล้หมด',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (lowStockProducts.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(left: 4),
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppConstants.errorRed,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${lowStockProducts.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart, size: 16),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'ตะกร้าสินค้า',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (cartItems.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(left: 4),
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppConstants.accentOrange,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${cartItems.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Low Stock Tab
                    _buildLowStockTab(lowStockProducts),
                    
                    // Cart Items Tab
                    _buildCartItemsTab(cartItems),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLowStockTab(List<Product> lowStockProducts) {
    if (lowStockProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: AppConstants.successGreen,
            ),
            SizedBox(height: 16),
            Text(
              'ไม่มีสินค้าใกล้หมด',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppConstants.textDarkGray,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'สินค้าทั้งหมดมีสต็อกเพียงพอ',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textDarkGray.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: lowStockProducts.length,
      itemBuilder: (context, index) {
        final product = lowStockProducts[index];
        final urgencyLevel = product.quantity == 0 ? 2 : 
                           product.quantity <= (product.lowStock * 0.5) ? 1 : 0;
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: urgencyLevel == 2 ? AppConstants.errorRed :
                     urgencyLevel == 1 ? Colors.orange : Colors.amber,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (urgencyLevel == 2 ? AppConstants.errorRed :
                       urgencyLevel == 1 ? Colors.orange : Colors.amber)
                       .withOpacity(0.1),
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
                            urgencyLevel == 2 ? Icons.error :
                            urgencyLevel == 1 ? Icons.warning : Icons.info,
                            color: urgencyLevel == 2 ? AppConstants.errorRed :
                                   urgencyLevel == 1 ? Colors.orange : Colors.amber,
                            size: 24,
                          );
                        },
                        headers: const {
                          'Accept': 'image/*',
                        },
                      ),
                    )
                  : Icon(
                      urgencyLevel == 2 ? Icons.error :
                      urgencyLevel == 1 ? Icons.warning : Icons.info,
                      color: urgencyLevel == 2 ? AppConstants.errorRed :
                             urgencyLevel == 1 ? Colors.orange : Colors.amber,
                      size: 24,
                    ),
            ),
            title: Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgencyLevel == 2 ? 'หมด! ต้องเติมสต็อกด่วน' :
                  urgencyLevel == 1 ? 'สต็อกต่ำมาก! ควรเติมสต็อก' :
                  'สต็อกต่ำ แนะนำให้เติมสต็อก',
                  style: TextStyle(
                    color: urgencyLevel == 2 ? AppConstants.errorRed :
                           urgencyLevel == 1 ? Colors.orange : Colors.amber[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'คงเหลือ: ${product.quantity} ${product.unit}',
                        style: TextStyle(
                          color: AppConstants.textDarkGray,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'ขั้นต่ำ: ${product.lowStock}',
                      style: TextStyle(
                        color: AppConstants.textDarkGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // Navigate to product details or edit page
                Navigator.pushNamed(
                  context, 
                  '/products', 
                  arguments: {'product': product}
                );
              },
              child: Text('ดูรายละเอียด'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryDarkBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size(0, 32),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartItemsTab(List cartItems) {
    if (cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppConstants.textDarkGray.withOpacity(0.6),
            ),
            SizedBox(height: 16),
            Text(
              'ไม่มีสินค้าในตะกร้า',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppConstants.textDarkGray,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'เพิ่มสินค้าในตะกร้าเพื่อทำการขาย',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textDarkGray.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Add button to go to cart page
        Container(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_shopping_cart, color: Colors.white),
                SizedBox(width: 8),
                Text('ไปยังหน้าตะกร้าสินค้า'),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryDarkBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final cartItem = cartItems[index];
              final product = cartItem.product;
              
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppConstants.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: product?.image != null && product!.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.shopping_cart,
                                  color: AppConstants.accentOrange,
                                  size: 24,
                                );
                              },
                              headers: const {
                                'Accept': 'image/*',
                              },
                            ),
                          )
                        : Icon(
                            Icons.shopping_cart,
                            color: AppConstants.accentOrange,
                            size: 24,
                          ),
                  ),
                  title: Text(
                    product?.name ?? 'ไม่ระบุสินค้า',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cartItem.quantity} ${product?.unit ?? 'หน่วย'}',
                        style: TextStyle(
                          color: AppConstants.textDarkGray,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ราคาต่อหน่วย: ${AppUtils.formatCurrency(product?.price ?? 0)}',
                        style: TextStyle(
                          color: AppConstants.textDarkGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppUtils.formatCurrency((product?.price ?? 0) * cartItem.quantity),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppConstants.accentOrange,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'รวม ${cartItem.quantity} หน่วย',
                        style: TextStyle(
                          color: AppConstants.textDarkGray.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
