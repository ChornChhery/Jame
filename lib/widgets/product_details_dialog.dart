import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../core/constants.dart';

class ProductDetailsDialog extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductDetailsDialog({
    Key? key,
    required this.product,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Scaffold(
          appBar: AppBar(
            title: Text('รายละเอียดสินค้า'),
            backgroundColor: AppConstants.primaryDarkBlue,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: onDelete,
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: product.image != null && product.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              product.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Log the error for debugging
                                print('Image loading error in dialog: $error');
                                return Icon(
                                  Icons.inventory_2,
                                  color: AppConstants.primaryDarkBlue,
                                  size: 48,
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
                            size: 48,
                          ),
                  ),
                ),
                SizedBox(height: 24),

                // Product Name
                _buildDetailRow('ชื่อสินค้า', product.name),
                SizedBox(height: 16),

                // Product Code
                _buildDetailRow('รหัสสินค้า', product.code),
                SizedBox(height: 16),

                // Category
                if (product.category != null)
                  _buildDetailRow('หมวดหมู่', product.category!),
                if (product.category != null) SizedBox(height: 16),

                // Price
                _buildDetailRow(
                  'ราคา',
                  '฿${NumberFormat('#,##0.00').format(product.price)}',
                  valueColor: AppConstants.primaryDarkBlue,
                  valueWeight: FontWeight.bold,
                ),
                SizedBox(height: 16),

                // Quantity and Unit
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        'จำนวนคงเหลือ',
                        '${product.quantity}',
                        valueColor: product.isLowStock ? Colors.red : Colors.green,
                        valueWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailRow('หน่วย', product.unit),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Low Stock Alert
                _buildDetailRow(
                  'แจ้งเตือนสต็อกต่ำ',
                  '${product.lowStock}',
                ),
                SizedBox(height: 16),

                // Stock Status
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: product.isLowStock ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: product.isLowStock ? Colors.red : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        product.isLowStock ? Icons.warning : Icons.check_circle,
                        color: product.isLowStock ? Colors.red : Colors.green,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        product.isLowStock ? 'สต็อกต่ำ - ควรเติมสต็อก' : 'สต็อกปกติ',
                        style: TextStyle(
                          color: product.isLowStock ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Timestamps
                if (product.createdAt != null) ...[
                  _buildDetailRow(
                    'วันที่เพิ่ม',
                    DateFormat('dd/MM/yyyy HH:mm').format(product.createdAt!),
                    labelSize: 12,
                    valueSize: 12,
                    labelColor: Colors.grey[600],
                    valueColor: Colors.grey[600],
                  ),
                  SizedBox(height: 8),
                ],
                if (product.updatedAt != null) ...[
                  _buildDetailRow(
                    'วันที่แก้ไขล่าสุด',
                    DateFormat('dd/MM/yyyy HH:mm').format(product.updatedAt!),
                    labelSize: 12,
                    valueSize: 12,
                    labelColor: Colors.grey[600],
                    valueColor: Colors.grey[600],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
    FontWeight? valueWeight,
    double? labelSize,
    double? valueSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor ?? Colors.grey[600],
            fontSize: labelSize ?? 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.black87,
            fontSize: valueSize ?? 16,
            fontWeight: valueWeight ?? FontWeight.normal,
          ),
        ),
      ],
    );
  }
}