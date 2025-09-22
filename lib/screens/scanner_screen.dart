// FILE: lib/screens/scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../models/product.dart';

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with TickerProviderStateMixin {
  MobileScannerController? _scannerController;
  bool _isScanning = true;
  bool _hasScanned = false;
  String? _lastScannedCode;
  Product? _scannedProduct;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  bool _isProcessing = false;
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    // Delay animation initialization to avoid issues during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAnimations();
    });
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _initializeAnimations() {
    if (_animationsInitialized) return;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.repeat(reverse: true);
    _animationsInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view
          _buildCameraView(),
          
          // Top bar
          _buildTopBar(),
          
          // Scanning overlay
          _buildScanningOverlay(),
          
          // Bottom panel
          _buildBottomPanel(),
          
          // Product info panel (when product found)
          if (_scannedProduct != null) _buildProductInfoPanel(),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: MobileScanner(
        controller: _scannerController,
        onDetect: _onQRCodeDetected,
        overlay: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Back button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'สแกน QR Code สินค้า',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Flash toggle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: IconButton(
                onPressed: () => _scannerController?.toggleTorch(),
                icon: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        child: Stack(
          children: [
            // Scanning frame
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hasScanned ? AppConstants.successGreen : AppConstants.primaryYellow,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            
            // Corner indicators
            ...[
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ].map((alignment) => Align(
              alignment: alignment,
              child: Builder(
                builder: (context) {
                  // Check if animations are initialized
                  if (!_animationsInitialized) {
                    return Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _hasScanned ? AppConstants.successGreen : AppConstants.primaryYellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }
                  return AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _hasScanned ? AppConstants.successGreen : AppConstants.primaryYellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )),
            
            // Center scanning line
            if (!_hasScanned)
              Builder(
                builder: (context) {
                  // Check if animations are initialized
                  if (!_animationsInitialized) {
                    return const SizedBox();
                  }
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: 125 * _animationController.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppConstants.primaryYellow,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Instructions
              Builder(
                builder: (context) {
                  // Check if animations are initialized
                  if (!_animationsInitialized) {
                    return Text(
                      _isProcessing
                          ? 'กำลังค้นหาข้อมูลสินค้า...'
                          : _hasScanned
                              ? 'พบสินค้าแล้ว!'
                              : 'วางกล้องให้ตรงกับ QR Code ของสินค้า',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      _isProcessing
                          ? 'กำลังค้นหาข้อมูลสินค้า...'
                          : _hasScanned
                              ? 'พบสินค้าแล้ว!'
                              : 'วางกล้องให้ตรงกับ QR Code ของสินค้า',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              
              if (_lastScannedCode != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'รหัส: $_lastScannedCode',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  // Manual input
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showManualInputDialog,
                      icon: const Icon(Icons.keyboard, size: 18),
                      label: const Text('ใส่รหัสสินค้า'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Add new product
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddProductDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('เพิ่มสินค้าใหม่'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryYellow,
                        foregroundColor: AppConstants.primaryDarkBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // View Cart button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppConstants.cartRoute),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('ดูตะกร้าสินค้า'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfoPanel() {
    return Positioned(
      top: 120,
      left: 20,
      right: 20,
      child: Builder(
        builder: (context) {
          // Check if animations are initialized
          if (!_animationsInitialized) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      _buildProductImage(_scannedProduct!),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'พบสินค้า',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textDarkGray,
                              ),
                            ),
                            Text(
                              _scannedProduct!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryDarkBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _scannedProduct = null;
                            _hasScanned = false;
                            _lastScannedCode = null;
                          });
                          _resumeScanning();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: AppConstants.textDarkGray,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Product details
                  Row(
                    children: [
                      Expanded(
                        child: _buildProductDetail(
                          'ราคา',
                          AppUtils.formatCurrency(_scannedProduct!.price),
                          Icons.attach_money,
                          AppConstants.successGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildProductDetail(
                          'คงเหลือ',
                          '${_scannedProduct!.quantity} ${_scannedProduct!.unit}',
                          Icons.inventory,
                          _scannedProduct!.quantity <= _scannedProduct!.lowStock
                              ? AppConstants.errorRed
                              : AppConstants.softBlue,
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
                          onPressed: () => _addToCart(_scannedProduct!),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('เพิ่มในตะกร้า'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppConstants.primaryDarkBlue,
                            side: const BorderSide(color: AppConstants.primaryDarkBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _viewProductDetails(_scannedProduct!),
                          icon: const Icon(Icons.info),
                          label: const Text('ดูรายละเอียด'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryDarkBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      _buildProductImage(_scannedProduct!),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'พบสินค้า',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textDarkGray,
                              ),
                            ),
                            Text(
                              _scannedProduct!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryDarkBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _scannedProduct = null;
                            _hasScanned = false;
                            _lastScannedCode = null;
                          });
                          _resumeScanning();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: AppConstants.textDarkGray,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Product details
                  Row(
                    children: [
                      Expanded(
                        child: _buildProductDetail(
                          'ราคา',
                          AppUtils.formatCurrency(_scannedProduct!.price),
                          Icons.attach_money,
                          AppConstants.successGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildProductDetail(
                          'คงเหลือ',
                          '${_scannedProduct!.quantity} ${_scannedProduct!.unit}',
                          Icons.inventory,
                          _scannedProduct!.quantity <= _scannedProduct!.lowStock
                              ? AppConstants.errorRed
                              : AppConstants.softBlue,
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
                          onPressed: () => _addToCart(_scannedProduct!),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('เพิ่มในตะกร้า'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppConstants.primaryDarkBlue,
                            side: const BorderSide(color: AppConstants.primaryDarkBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _viewProductDetails(_scannedProduct!),
                          icon: const Icon(Icons.info),
                          label: const Text('ดูรายละเอียด'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryDarkBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      width: 48,
      height: 48,
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

  Widget _buildProductDetail(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppConstants.textDarkGray,
            ),
          ),
        ],
      ),
    );
  }

  // Scanner event handlers
  void _onQRCodeDetected(BarcodeCapture capture) async {
    if (_hasScanned || _isProcessing) return;
    
    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;
    
    setState(() {
      _isProcessing = true;
      _lastScannedCode = barcode.rawValue;
    });
    
    await _processScannedCode(barcode.rawValue!);
  }

  Future<void> _processScannedCode(String code) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final app = Provider.of<AppProvider>(context, listen: false);
      
      if (auth.currentUser?.id == null) {
        _showErrorMessage('ไม่พบข้อมูลผู้ใช้');
        return;
      }
      
      // Search for product by code
      final product = await app.getProductByCode(code, auth.currentUser!.id!);
      
      setState(() {
        _isProcessing = false;
        if (product != null) {
          _scannedProduct = product;
          _hasScanned = true;
          _pauseScanning();
        } else {
          _showProductNotFoundDialog(code);
        }
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorMessage('เกิดข้อผิดพลาด: ${e.toString()}');
    }
  }

  void _pauseScanning() {
    _scannerController?.stop();
    setState(() => _isScanning = false);
  }

  void _resumeScanning() {
    _scannerController?.start();
    setState(() => _isScanning = true);
  }

  // Dialog functions
  void _showManualInputDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ใส่รหัสสินค้า'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'รหัสสินค้า',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _processScannedCode(controller.text.trim());
              }
            },
            child: const Text('ค้นหา'),
          ),
        ],
      ),
    );
  }

  void _showProductNotFoundDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ไม่พบสินค้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: AppConstants.textDarkGray,
            ),
            const SizedBox(height: 16),
            Text('ไม่พบสินค้าที่มีรหัส: $code'),
            const SizedBox(height: 8),
            const Text(
              'คุณต้องการเพิ่มสินค้าใหม่หรือไม่?',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanning();
            },
            child: const Text('สแกนต่อ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddProductDialog(prefilledCode: code);
            },
            child: const Text('เพิ่มสินค้าใหม่'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog({String? prefilledCode}) {
    // Navigate to add product screen with prefilled code
    Navigator.pushNamed(
      context,
      AppConstants.productsRoute,
      arguments: {'mode': 'add', 'code': prefilledCode},
    ).then((_) {
      // Resume scanning when returning from add product
      _resumeScanning();
    });
  }

  // Action handlers
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
    
    // Continue scanning after adding to cart
    setState(() {
      _scannedProduct = null;
      _hasScanned = false;
      _lastScannedCode = null;
    });
    _resumeScanning();
  }

  void _viewProductDetails(Product product) {
    Navigator.pushNamed(
      context,
      AppConstants.productsRoute,
      arguments: {'mode': 'view', 'product': product},
    ).then((_) {
      // Resume scanning when returning
      _resumeScanning();
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }
}