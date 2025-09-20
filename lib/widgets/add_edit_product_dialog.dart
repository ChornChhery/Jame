import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';

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
    'อาหารและเครื่องดื่ม',
    'ของใช้ในบ้าน',
    'เครื่องเขียน',
    'ยาและอุปกรณ์การแพทย์',
    'เสื้อผ้าและเครื่องแต่งกาย',
    'อิเล็กทรอนิกส์',
    'เครื่องใช้ในครัว',
    'อื่นๆ'
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
      _unitController.text = 'ชิ้น';
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
            title: Text(widget.product == null ? 'เพิ่มสินค้า' : 'แก้ไขสินค้า'),
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
                    labelText: 'ชื่อสินค้า *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกชื่อสินค้า';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'รหัสสินค้า *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสสินค้า';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'หมวดหมู่',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
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
                    labelText: 'ราคา (บาท) *',
                    border: OutlineInputBorder(),
                    prefixText: '฿ ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกราคา';
                    }
                    if (double.tryParse(value) == null) {
                      return 'กรุณากรอกราคาที่ถูกต้อง';
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
                          labelText: 'จำนวนคงเหลือ *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกจำนวน';
                          }
                          if (int.tryParse(value) == null) {
                            return 'กรุณากรอกจำนวนที่ถูกต้อง';
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
                          labelText: 'หน่วย',
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
                    labelText: 'แจ้งเตือนสต็อกต่ำ',
                    border: OutlineInputBorder(),
                    helperText: 'แจ้งเตือนเมื่อสินค้าเหลือน้อยกว่าจำนวนนี้',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (int.tryParse(value) == null) {
                        return 'กรุณากรอกจำนวนที่ถูกต้อง';
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
                      : Text(widget.product == null ? 'เพิ่มสินค้า' : 'บันทึกการแก้ไข'),
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
        unit: _unitController.text.trim().isEmpty ? 'ชิ้น' : _unitController.text.trim(),
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
          content: Text(widget.product == null ? 'เพิ่มสินค้าเรียบร้อยแล้ว' : 'แก้ไขสินค้าเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
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