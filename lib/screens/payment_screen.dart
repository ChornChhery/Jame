import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../core/translations.dart';
import '../widgets/language_switch_button.dart';
import '../models/product.dart';
import '../core/constants.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _qrAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _qrScaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isProcessing = false;
  bool _isPaymentConfirmed = false;
  String _paymentMethod = 'PromptPay'; // Default to PromptPay (QR)
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkCartValidation();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _qrAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    
    _qrScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _qrAnimationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
    _qrAnimationController.forward();
  }

  void _checkCartValidation() {
    final app = Provider.of<AppProvider>(context, listen: false);
    if (app.cartItems.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Store the ScaffoldMessenger state at the very beginning to ensure we have a valid reference
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        
        Navigator.pop(context);
        
        // Use a delayed callback to show snackbar after dialog is completely dismissed
        Future.delayed(Duration(milliseconds: 100), () {
          // Show snackbar using the stored scaffold messenger reference
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(AppTranslations.t('ui_your_cart_is_empty_please_add')),
              backgroundColor: AppConstants.errorRed,
            ),
          );
        });
      });
    }
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
                  if (app.cartItems.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildOrderSummary(app),
                            const SizedBox(height: 20),
                            _buildCustomerInfo(),
                            const SizedBox(height: 20),
                            _buildPaymentMethods(),
                            const SizedBox(height: 20),
                            if (_paymentMethod == 'PromptPay')
                              _buildPromptPayQR(app),
                            if (_paymentMethod == 'Cash')
                              _buildCashPayment(app),
                            const SizedBox(height: 20),
                            _buildPaymentActions(app),
                          ],
                        ),
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
                Text(
                  context.tr('nav_payment'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  context.tr('payment_method'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const LanguageSwitchButton(isDarkBackground: true, compact: true),
          const SizedBox(width: 8),
          if (_isProcessing)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(AppProvider app) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: AppConstants.primaryDarkBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.t('ui_order_summary'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Order items summary
          ...app.cartItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.product.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${item.quantity} ${item.product.unit}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '฿${NumberFormat('#,##0.00').format(item.totalPrice)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const Divider(height: 24),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.t('ui_total_items', [app.cartItemCount]),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
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
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppConstants.primaryDarkBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.t('ui_customer_information_optional'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText: AppTranslations.t('ui_customer_name'),
              hintText: AppTranslations.t('ui_enter_customer_name'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _customerPhoneController,
            decoration: InputDecoration(
              labelText: AppTranslations.t('ui_phone_number'),
              hintText: AppTranslations.t('ui_enter_phone_number'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: AppConstants.primaryDarkBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.t('ui_payment_method_3'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // PromptPay option
          _buildPaymentOption(
            'PromptPay',
            'PromptPay QR Code',
            AppTranslations.t('ui_scan_the_qr_code_to_pay'),
            Icons.qr_code,
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          // Cash option
          _buildPaymentOption(
            'Cash',
            AppTranslations.t('ui_cash'),
            AppTranslations.t('ui_pay_with_cash_and_record_the'),
            Icons.money,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, String title, String subtitle, IconData icon, Color color) {
    final isSelected = _paymentMethod == value;
    
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppConstants.primaryDarkBlue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppConstants.primaryDarkBlue.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppConstants.primaryDarkBlue : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value!),
              activeColor: AppConstants.primaryDarkBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptPayQR(AppProvider app) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_2,
                color: AppConstants.primaryDarkBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'PromptPay QR Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // QR Code
          ScaleTransition(
            scale: _qrScaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: _generatePromptPayQR(app.cartTotal),
                version: QrVersions.auto,
                size: 200.0,
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            '฿${NumberFormat('#,##0.00').format(app.cartTotal)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            AppTranslations.t('ui_ask_the_customer_to_scan_the'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppTranslations.t('ui_this_qr_code_works_with_all'),
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashPayment(AppProvider app) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.money,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.t('ui_pay_with_cash'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.green[700],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '฿${NumberFormat('#,##0.00').format(app.cartTotal)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppTranslations.t('ui_amount_due'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppTranslations.t('ui_receive_cash_from_the_customer_then'),
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
    );
  }

  Widget _buildPaymentActions(AppProvider app) {
    return Column(
      children: [
        // Confirm Payment Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _confirmPayment(app),
            icon: _isProcessing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isProcessing ? AppTranslations.t('ui_processing') : AppTranslations.t('ui_confirm_payment')),
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
        
        const SizedBox(height: 12),
        
        // Back to Cart Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: Text(AppTranslations.t('ui_back_to_cart')),
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
    );
  }

  String _generatePromptPayQR(double amount) {
    // Simple PromptPay QR format for Thailand
    // In real implementation, you would use proper PromptPay QR generation library
    // This is a simplified version for demonstration
    final String promptPayID = "0123456789"; // Replace with actual PromptPay ID
    final String amountStr = amount.toStringAsFixed(2);
    
    // Simplified QR data format (real PromptPay QR is more complex)
    return "00020101021129370016A000000677010111011301${promptPayID}520454035405${amountStr}5802TH6304";
  }

  Future<void> _confirmPayment(AppProvider app) async {
    setState(() => _isProcessing = true);
    
    // Store the ScaffoldMessenger reference at the beginning
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      // Removed for security - was: debugPrint('Starting sale completion process...');
      
      // Complete the sale with the selected payment method
      final success = await app.completeSale(
        auth.currentUser!.id!,
        auth.currentUser!.username,
        paymentMethod: _paymentMethod, // Fix: Pass the actual selected payment method
      );
      
      // Removed for security - was: debugPrint('Sale completion result: $success');
      
      // Check if the widget is still mounted before proceeding
      if (!mounted) {
        // Removed for security - was: debugPrint('Widget is no longer mounted after sale completion');
        return;
      }
      
      if (success) {
        setState(() => _isPaymentConfirmed = true);
        
        // Navigate to receipt immediately to prevent context issues
        // Removed for security - was: debugPrint('Navigating to receipt screen...');
        Navigator.pushReplacementNamed(context, AppConstants.receiptRoute);
        
        // Show success message on the receipt screen using the stored scaffold messenger reference
        Future.delayed(Duration(milliseconds: 100), () {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(_paymentMethod == 'Cash' 
                  ? AppTranslations.t('ui_cash_payment_completed') 
                  : AppTranslations.t('ui_qr_code_payment_completed')),
              backgroundColor: AppConstants.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      } else {
        // Removed for security - was: debugPrint('Sale completion failed');
        // Show error message immediately before any potential navigation
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(AppTranslations.t('ui_unable_to_record_the_sale')),
            backgroundColor: AppConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Removed for security - was: debugPrint('Error during sale completion: $e');
      // Show error message immediately before any potential navigation
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(AppTranslations.t('ui_an_error_occurred', [e])),
          backgroundColor: AppConstants.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // Only update state if still mounted
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _qrAnimationController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }
}