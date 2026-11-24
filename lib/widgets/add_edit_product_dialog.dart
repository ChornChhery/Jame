import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../core/constants.dart';
import '../core/translations.dart';

class AddEditProductDialog extends StatefulWidget {
  final Product? product;
  final String? prefilledCode;
  final VoidCallback onSaved;

  const AddEditProductDialog({
    Key? key,
    this.product,
    this.prefilledCode,
    required this.onSaved,
  }) : super(key: key);

  @override
  _AddEditProductDialogState createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _unitController = TextEditingController();
  
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Food & Beverage',
    'Household Items',
    'Stationery',
    'Medicine & Medical Supplies',
    'Clothing & Apparel',
    'Electronics',
    'Kitchenware',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final product = widget.product!;
      _nameController.text = product.name;
      _codeController.text = product.code;
      _priceController.text = product.price.toString();
      _quantityController.text = product.quantity.toString();
      _lowStockController.text = product.lowStock.toString();
      _unitController.text = product.unit;
      _selectedCategory = product.category;
    } else if (widget.prefilledCode != null) {
      _codeController.text = widget.prefilledCode!;
    }
    
    // Set default values
    if (_lowStockController.text.isEmpty) {
      _lowStockController.text = '5';
    }
    if (_unitController.text.isEmpty) {
      _unitController.text = 'pcs';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.product == null ? AppTranslations.t('ui_add_products') : AppTranslations.t('ui_edit_product')),
            backgroundColor: AppConstants.primaryDarkBlue,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppTranslations.t('ui_product_name_2'),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppTranslations.t('ui_please_enter_the_product_name');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: AppTranslations.t('ui_product_code_2'),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppTranslations.t('ui_please_enter_the_product_code');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: AppTranslations.t('ui_category'),
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(AppTranslations.label(category)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: AppTranslations.t('ui_price_baht'),
                    border: OutlineInputBorder(),
                    prefixText: '฿ ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppTranslations.t('ui_please_enter_the_price');
                    }
                    if (double.tryParse(value) == null) {
                      return AppTranslations.t('ui_please_enter_a_valid_price');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: AppTranslations.t('ui_quantity_in_stock_2'),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppTranslations.t('ui_please_enter_the_quantity');
                          }
                          if (int.tryParse(value) == null) {
                            return AppTranslations.t('ui_please_enter_a_valid_quantity');
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: InputDecoration(
                          labelText: AppTranslations.t('ui_unit_2'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: _lowStockController,
                  decoration: InputDecoration(
                    labelText: AppTranslations.t('ui_low_stock_alert'),
                    border: OutlineInputBorder(),
                    helperText: AppTranslations.t('ui_alert_when_product_quantity_falls_below'),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (int.tryParse(value) == null) {
                        return AppTranslations.t('ui_please_enter_a_valid_quantity');
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryDarkBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(widget.product == null ? AppTranslations.t('ui_add_products') : AppTranslations.t('ui_save_changes')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      final product = Product(
        id: widget.product?.id,
        userId: authProvider.currentUser!.id!,
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        lowStock: int.parse(_lowStockController.text.isEmpty ? '5' : _lowStockController.text),
        unit: _unitController.text.trim().isEmpty ? 'pcs' : _unitController.text.trim(),
      );

      if (widget.product == null) {
        await appProvider.addProduct(product);
      } else {
        await appProvider.updateProduct(product);
      }

      widget.onSaved();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product == null ? AppTranslations.t('ui_product_added_successfully') : AppTranslations.t('ui_product_edited_successfully')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.t('ui_an_error_occurred', [e])),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _lowStockController.dispose();
    _unitController.dispose();
    super.dispose();
  }
}