import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isEditing = false;
  bool _isLoading = false;

  // Personal Information Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  // Shop Information Controllers
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  final _shopEmailController = TextEditingController();

  // Payment Information Controllers
  final _promptPayController = TextEditingController();
  String _selectedCurrency = 'THB';
  
  // Profile image
  XFile? _profileImage;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    _shopEmailController.dispose();
    _promptPayController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _emailController.text = user.email ?? '';
      _shopNameController.text = user.shopName ?? '';
      _shopAddressController.text = user.shopAddress ?? '';
      _shopPhoneController.text = user.shopPhone ?? '';
      _shopEmailController.text = user.shopEmail ?? '';
      _promptPayController.text = user.paymentQr ?? '';
      _selectedCurrency = user.currency ?? 'THB';
      _profileImagePath = user.profileImage;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Save image if selected
      String? imagePath = _profileImagePath;
      if (_profileImage != null) {
        imagePath = await AppUtils.saveImageToDocuments(_profileImage!);
        if (imagePath == null) {
          _showErrorMessage('ไม่สามารถบันทึกรูปภาพได้');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final updatedUser = User(
        id: authProvider.currentUser?.id,
        username: authProvider.currentUser?.username ?? '',
        email: _emailController.text.trim(),
        password: authProvider.currentUser?.password ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        shopName: _shopNameController.text.trim(),
        shopAddress: _shopAddressController.text.trim(),
        shopPhone: _shopPhoneController.text.trim(),
        shopEmail: _shopEmailController.text.trim(),
        currency: _selectedCurrency,
        paymentQr: _promptPayController.text.trim(),
        profileImage: imagePath,
      );

      await authProvider.updateProfile(updatedUser);
      
      setState(() {
        _isEditing = false;
        _profileImage = null; // Clear temporary image
        _profileImagePath = imagePath; // Update with saved path
      });

      _showSuccessMessage('บันทึกข้อมูลเรียบร้อยแล้ว');
    } catch (e) {
      _showErrorMessage('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await _showLogoutDialog();
    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: AppConstants.errorRed),
            ),
            const SizedBox(width: 12),
            const Text('ออกจากระบบ'),
          ],
        ),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppConstants.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Show image upload options
  void _showImageUploadOptions() {
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
                child: Icon(Icons.camera_alt_rounded, color: AppConstants.primaryDarkBlue),
              ),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(context);
                _captureImage();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library_rounded, color: AppConstants.primaryDarkBlue),
              ),
              title: const Text('เลือกจากแกลเลอรี่'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Capture image from camera
  Future<void> _captureImage() async {
    final XFile? image = await AppUtils.captureImage();
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
    }
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await AppUtils.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            child: _isLoading
                ? _buildLoadingWidget()
                : Form(
                    key: _formKey,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPersonalInfoTab(),
                        _buildShopInfoTab(),
                        _buildPaymentInfoTab(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.primaryDarkBlue,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'โปรไฟล์',
          style: TextStyle(
            color: AppConstants.primaryWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.primaryDarkBlue,
                Color(0xFF2196F3),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 60,
                right: -50,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryYellow.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveProfile,
              icon: const Icon(Icons.save, size: 18, color: AppConstants.primaryDarkBlue),
              label: const Text('บันทึก', style: TextStyle(color: AppConstants.primaryDarkBlue)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryYellow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          )
        else
          IconButton(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit, color: AppConstants.primaryWhite),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppConstants.primaryWhite),
          onSelected: (value) {
            if (value == 'logout') _logout();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppConstants.errorRed, size: 20),
                  SizedBox(width: 12),
                  Text('ออกจากระบบ'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppConstants.primaryDarkBlue,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppConstants.primaryYellow,
            indicatorWeight: 3,
            labelColor: AppConstants.primaryWhite,
            unselectedLabelColor: AppConstants.primaryWhite.withOpacity(0.7),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.person, size: 20), text: 'ข้อมูลส่วนตัว'),
              Tab(icon: Icon(Icons.store, size: 20), text: 'ข้อมูลร้าน'),
              Tab(icon: Icon(Icons.payment, size: 20), text: 'การชำระเงิน'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppConstants.primaryDarkBlue,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'กำลังบันทึกข้อมูล...',
            style: TextStyle(
              color: AppConstants.textDarkGray,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfilePictureSection(),
          const SizedBox(height: 32),
          _buildPersonalInfoCard(),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.primaryWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppConstants.primaryYellow, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: AppConstants.lightGray,
                  // Display selected image or saved image or default icon
                  child: _profileImage != null
                    ? ClipOval(
                        child: Image.file(
                          File(_profileImage!.path),
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      )
                    : (_profileImagePath != null && _profileImagePath!.isNotEmpty)
                      ? ClipOval(
                          child: Image.file(
                            File(_profileImagePath!),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 65,
                                color: AppConstants.textDarkGray.withOpacity(0.5),
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 65,
                          color: AppConstants.textDarkGray.withOpacity(0.5),
                        ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.primaryYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 20, color: AppConstants.primaryDarkBlue),
                      onPressed: _showImageUploadOptions,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_firstNameController.text} ${_lastNameController.text}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _emailController.text,
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textDarkGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildCard(
      title: 'ข้อมูลส่วนตัว',
      icon: Icons.person_outline,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  controller: _firstNameController,
                  label: 'ชื่อ',
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อ' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernTextField(
                  controller: _lastNameController,
                  label: 'นามสกุล',
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกนามสกุล' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _emailController,
            label: 'อีเมล',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            enabled: _isEditing,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                return 'รูปแบบอีเมลไม่ถูกต้อง';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShopInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildShopInfoCard(),
          const SizedBox(height: 20),
          _buildCurrencyCard(),
        ],
      ),
    );
  }

  Widget _buildShopInfoCard() {
    return _buildCard(
      title: 'ข้อมูลร้านค้า',
      icon: Icons.store_outlined,
      child: Column(
        children: [
          _buildModernTextField(
            controller: _shopNameController,
            label: 'ชื่อร้าน',
            icon: Icons.store,
            enabled: _isEditing,
            validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อร้าน' : null,
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _shopAddressController,
            label: 'ที่อยู่ร้าน',
            icon: Icons.location_on_outlined,
            maxLines: 3,
            enabled: _isEditing,
            validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกที่อยู่ร้าน' : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  controller: _shopPhoneController,
                  label: 'เบอร์โทรร้าน',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: _isEditing,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernTextField(
                  controller: _shopEmailController,
                  label: 'อีเมลร้าน',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: _isEditing,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyCard() {
    return _buildCard(
      title: 'สกุลเงิน',
      icon: Icons.attach_money,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppConstants.lightGray),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedCurrency,
          decoration: InputDecoration(
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.monetization_on, color: AppConstants.primaryDarkBlue),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: const [
            DropdownMenuItem(value: 'THB', child: Text('฿ บาทไทย (THB)')),
            DropdownMenuItem(value: 'USD', child: Text('\$ ดอลลาร์สหรัฐ (USD)')),
          ],
          onChanged: _isEditing ? (value) => setState(() => _selectedCurrency = value!) : null,
        ),
      ),
    );
  }

  Widget _buildPaymentInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildPromptPayCard(),
          const SizedBox(height: 20),
          _buildPaymentMethodsCard(),
          const SizedBox(height: 20),
          _buildSecurityCard(),
        ],
      ),
    );
  }

  Widget _buildPromptPayCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryYellow.withOpacity(0.1),
            AppConstants.primaryWhite,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.primaryYellow, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryYellow,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryYellow.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code,
                  color: AppConstants.primaryDarkBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'PromptPay',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryDarkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildModernTextField(
            controller: _promptPayController,
            label: 'หมายเลข PromptPay',
            icon: Icons.account_balance_wallet,
            keyboardType: TextInputType.phone,
            enabled: _isEditing,
            hint: 'เบอร์โทรศัพท์หรือเลขประจำตัวผู้เสียภาษี',
            validator: (value) {
              if (value?.isNotEmpty ?? false) {
                if (!RegExp(r'^[0-9]{10,13}$').hasMatch(value!.replaceAll('-', ''))) {
                  return 'รูปแบบ PromptPay ไม่ถูกต้อง';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return _buildInfoCard(
      'วิธีการชำระเงินที่รองรับ',
      Icons.payment,
      [
        'PromptPay QR Code',
        'เงินสด (Cash)',
        'การโอนเงินผ่านธนาคาร',
        'บัตรเครดิต/เดบิต (ในอนาคต)',
      ],
      Colors.blue.shade50,
    );
  }

  Widget _buildSecurityCard() {
    return _buildInfoCard(
      'ความปลอดภัย',
      Icons.security,
      [
        'ข้อมูลการชำระเงินถูกเข้ารหัส',
        'ไม่เก็บข้อมูลบัตรเครดิต',
        'ปฏิบัติตามมาตรฐาน PCI DSS',
      ],
      Colors.green.shade50,
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.primaryWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppConstants.primaryDarkBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryDarkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: enabled ? AppConstants.primaryDarkBlue : Colors.grey,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.lightGray.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.lightGray.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryDarkBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.errorRed),
        ),
        filled: true,
        fillColor: enabled ? AppConstants.primaryWhite : AppConstants.lightGray.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: enabled ? AppConstants.primaryDarkBlue : Colors.grey,
          fontSize: 14,
        ),
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<String> items, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppConstants.primaryDarkBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryDarkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppConstants.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: AppConstants.textDarkGray,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}