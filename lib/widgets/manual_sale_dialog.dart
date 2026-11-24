import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../core/constants.dart';
import '../core/translations.dart';

class ManualSaleDialog extends StatefulWidget {
  final VoidCallback? onSaleCompleted;

  const ManualSaleDialog({Key? key, this.onSaleCompleted}) : super(key: key);

  @override
  _ManualSaleDialogState createState() => _ManualSaleDialogState();
}

class _ManualSaleDialogState extends State<ManualSaleDialog> {
  Product? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  String _paymentMethod = 'Cash';
  bool _isLoading = false;
  
  List<Product> _searchResults = [];
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadProducts() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    if (auth.currentUser?.id != null) {
      await app.loadProducts(auth.currentUser!.id!);
      setState(() {
        _searchResults = app.products.where((p) => p.quantity > 0).toList();
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final app = Provider.of<AppProvider>(context, listen: false);
    
    setState(() {
      if (query.isEmpty) {
        _searchResults = app.products.where((p) => p.quantity > 0).toList();
      } else {
        _searchResults = app.products.where((p) => 
          p.quantity > 0 && (
            p.name.toLowerCase().contains(query) ||
            p.code.toLowerCase().contains(query)
          )
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppTranslations.t('ui_quick_sale_select_product')),
            backgroundColor: AppConstants.primaryDarkBlue,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppTranslations.t('ui_search_products'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              
              // Product selection
              Expanded(
                flex: 2,
                child: _buildProductSelection(),
              ),
              
              // Selected product and quantity
              if (_selectedProduct != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryDarkBlue.withOpacity(0.05),
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: _buildSelectedProductSection(),
                ),
              ],
              
              // Sale details and action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _buildSaleSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSelection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? AppTranslations.t('ui_no_products_in_stock') : AppTranslations.t('ui_no_matching_products_found'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        final isSelected = _selectedProduct?.id == product.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryDarkBlue.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppConstants.primaryDarkBlue : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: AppConstants.primaryDarkBlue,
              ),
            ),
            title: Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppConstants.primaryDarkBlue : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppTranslations.t('ui_code', [product.code])),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '฿${NumberFormat('#,##0.00').format(product.price)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryDarkBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppTranslations.t('ui_in_stock_3', [product.quantity]),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: isSelected
                ? const Icon(
                    Icons.check_circle,
                    color: AppConstants.primaryDarkBlue,
                  )
                : null,
            onTap: () {
              setState(() {
                _selectedProduct = product;
                // Reset quantity when selecting new product
                _quantityController.text = '1';
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedProductSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.shopping_cart,
              color: AppConstants.primaryDarkBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              AppTranslations.t('ui_selected_product'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryDarkBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedProduct!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '฿${NumberFormat('#,##0.00').format(_selectedProduct!.price)} / ${_selectedProduct!.unit}',
                    style: const TextStyle(
                      color: AppConstants.primaryDarkBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Quantity input
            SizedBox(
              width: 100,
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppTranslations.t('ui_qty'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {}); // Refresh to update total
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Total
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.primaryDarkBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConstants.primaryDarkBlue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.t('ui_total_2'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '฿${NumberFormat('#,##0.00').format(_calculateTotal())}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryDarkBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaleSection() {
    return Column(
      children: [
        // Customer info (optional)
        ExpansionTile(
          title: Text(AppTranslations.t('ui_customer_information_optional')),
          leading: const Icon(Icons.person_outline),
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: AppTranslations.t('ui_customer_name'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerPhoneController,
              decoration: InputDecoration(
                labelText: AppTranslations.t('ui_phone_number'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Payment method
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.t('ui_payment_method_3'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text(AppTranslations.t('ui_cash')),
                      value: 'Cash',
                      groupValue: _paymentMethod,
                      onChanged: (value) => setState(() => _paymentMethod = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('QR Code'),
                      value: 'QR',
                      groupValue: _paymentMethod,
                      onChanged: (value) => setState(() => _paymentMethod = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Complete sale button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectedProduct != null && !_isLoading ? _completeSale : null,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isLoading ? AppTranslations.t('ui_processing') : AppTranslations.t('ui_sale_completed')),
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
    );
  }

  double _calculateTotal() {
    if (_selectedProduct == null) return 0.0;
    
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    return _selectedProduct!.price * quantity;
  }

  Future<void> _completeSale() async {
    if (_selectedProduct == null) return;
    
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.t('ui_please_enter_a_valid_quantity')),
          backgroundColor: AppConstants.errorRed,
        ),
      );
      return;
    }
    
    if (quantity > _selectedProduct!.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.t('ui_insufficient_quantity_left', [_selectedProduct!.quantity, _selectedProduct!.unit])),
          backgroundColor: AppConstants.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final app = Provider.of<AppProvider>(context, listen: false);
      
      if (auth.currentUser?.id != null) {
        await app.clearCartWithPersistence(auth.currentUser!.id!);
        await app.addToCartWithPersistence(
          auth.currentUser!.id!,
          _selectedProduct!,
          quantity: quantity,
        );
      } else {
        // Fallback to in-memory operations
        app.clearCart(); // Clear existing cart
        app.addToCart(_selectedProduct!, quantity: quantity);
      }
      
      // Complete the sale
      final success = await app.completeSale(
        auth.currentUser!.id!,
        auth.currentUser!.username,
      );

      if (success) {
        Navigator.pop(context);
        widget.onSaleCompleted?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.t('ui_product_sold_successfully')),
            backgroundColor: AppConstants.successGreen,
          ),
        );
        
        // Navigate to receipt
        Navigator.pushNamed(context, AppConstants.receiptRoute);
      } else {
        throw Exception(AppTranslations.t('ui_unable_to_record_the_sale'));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.t('ui_an_error_occurred', [e])),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}