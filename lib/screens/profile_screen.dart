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
  bool _hasUnsavedChanges = false;

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
    _setupChangeListeners();
  }

  void _setupChangeListeners() {
    // Listen to text changes to detect unsaved changes
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _shopNameController.addListener(_onFieldChanged);
    _shopAddressController.addListener(_onFieldChanged);
    _shopPhoneController.addListener(_onFieldChanged);
    _shopEmailController.addListener(_onFieldChanged);
    _promptPayController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_isEditing && !_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
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
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save image if selected
      String? imagePath = _profileImagePath;
      if (_profileImage != null) {
        imagePath = await AppUtils.saveImageToDocuments(_profileImage!);
        if (imagePath == null) {
          _showErrorMessage('ไม่สามารถบันทึกรูปภาพได้');
          setState(() => _isLoading = false);
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
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _hasUnsavedChanges = false;
          _profileImage = null;
          _profileImagePath = imagePath;
        });

        _showSuccessMessage('บันทึกข้อมูลเรียบร้อยแล้ว');
      }
    } catch (e) {
      _showErrorMessage('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelEdit() {
    if (_hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 12),
              Text('ยกเลิกการแก้ไข'),
            ],
          ),
          content: const Text('คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก\nต้องการยกเลิกการแก้ไขหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('กลับไปแก้ไข'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadUserData(); // Reload original data
                setState(() {
                  _isEditing = false;
                  _hasUnsavedChanges = false;
                  _profileImage = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('ยกเลิก'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _isEditing = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await _showLogoutDialog();
    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ออกจากระบบ'),
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppConstants.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showImageUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
              'เลือกรูปโปรไฟล์',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เลือกวิธีการอัปโหลดรูปภาพของคุณ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildImageOptionCard(
                      icon: Icons.camera_alt_rounded,
                      label: 'ถ่ายรูป',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _captureImage();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageOptionCard(
                      icon: Icons.photo_library_rounded,
                      label: 'แกลเลอรี่',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOptionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    final XFile? image = await AppUtils.captureImage();
    if (image != null) {
      setState(() {
        _profileImage = image;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await AppUtils.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _profileImage = image;
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges && _isEditing) {
          _cancelEdit();
          return false;
        }
        return true;
      },
      child: Scaffold(
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
        floatingActionButton: _isEditing && _hasUnsavedChanges
            ? _buildFloatingActionButtons()
            : null,
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          onPressed: _isLoading ? null : _saveProfile,
          backgroundColor: AppConstants.successGreen,
          icon: const Icon(Icons.check, color: Colors.white),
          label: const Text(
            'บันทึก',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          heroTag: 'save',
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          onPressed: _isLoading ? null : _cancelEdit,
          backgroundColor: Colors.grey[600],
          child: const Icon(Icons.close, color: Colors.white),
          heroTag: 'cancel',
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.primaryDarkBlue,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'โปรไฟล์',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryDarkBlue,
                    AppConstants.primaryDarkBlue.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppConstants.primaryYellow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/pattern.png', // Add a subtle pattern if available
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!_isEditing)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('แก้ไข'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryYellow,
                foregroundColor: AppConstants.primaryDarkBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                elevation: 2,
              ),
            ),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          decoration: BoxDecoration(
            color: AppConstants.primaryDarkBlue,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppConstants.primaryYellow,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.person, size: 20),
                text: 'ส่วนตัว',
              ),
              Tab(
                icon: Icon(Icons.store, size: 20),
                text: 'ร้านค้า',
              ),
              Tab(
                icon: Icon(Icons.payment, size: 20),
                text: 'ชำระเงิน',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryDarkBlue.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: AppConstants.primaryDarkBlue,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'กำลังบันทึกข้อมูล...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppConstants.textDarkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กรุณารอสักครู่',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
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
          const SizedBox(height: 24),
          _buildPersonalInfoCard(),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    final displayName = '${_firstNameController.text} ${_lastNameController.text}'.trim();
    final email = _emailController.text;
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppConstants.primaryYellow,
                      AppConstants.primaryYellow.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryYellow.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: AppConstants.lightGray,
                    child: _profileImage != null
                        ? ClipOval(
                            child: Image.file(
                              File(_profileImage!.path),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (_profileImagePath != null && _profileImagePath!.isNotEmpty)
                            ? ClipOval(
                                child: Image.file(
                                  File(_profileImagePath!),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar();
                                  },
                                ),
                              )
                            : _buildDefaultAvatar(),
                  ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppConstants.primaryYellow,
                          AppConstants.primaryYellow.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryYellow.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showImageUploadOptions,
                        borderRadius: BorderRadius.circular(50),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: AppConstants.primaryDarkBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            displayName.isEmpty ? 'ไม่มีชื่อ' : displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryDarkBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.primaryDarkBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: AppConstants.primaryDarkBlue.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  email.isEmpty ? 'ไม่มีอีเมล' : email,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppConstants.primaryDarkBlue.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'กดไอคอนกล้องเพื่อเปลี่ยนรูปโปรไฟล์',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 70,
      color: AppConstants.textDarkGray.withOpacity(0.4),
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
                  icon: Icons.badge_outlined,
                  enabled: _isEditing,
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อ' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernTextField(
                  controller: _lastNameController,
                  label: 'นามสกุล',
                  icon: Icons.badge_outlined,
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
          const SizedBox(height: 20),
          _buildShopStatsCard(),
          const SizedBox(height: 100), // Space for FAB
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
            hint: 'กรอกที่อยู่ร้านค้าของคุณ',
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
                  hint: '0812345678',
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[0-9]{9,10}$').hasMatch(value.replaceAll('-', ''))) {
                        return 'เบอร์โทรไม่ถูกต้อง';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernTextField(
                  controller: _shopEmailController,
                  label: 'อีเมลร้าน',
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  enabled: _isEditing,
                  hint: 'shop@example.com',
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'อีเมลไม่ถูกต้อง';
                      }
                    }
                    return null;
                  },
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
          color: _isEditing ? Colors.white : Colors.grey[50],
          border: Border.all(
            color: _isEditing ? AppConstants.primaryDarkBlue : Colors.grey[300]!,
            width: _isEditing ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedCurrency,
          decoration: InputDecoration(
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.monetization_on,
                color: _isEditing ? AppConstants.primaryDarkBlue : Colors.grey,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: const [
            DropdownMenuItem(
              value: 'THB',
              child: Row(
                children: [
                  Text('฿', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(width: 12),
                  Text('บาทไทย (THB)'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'USD',
              child: Row(
                children: [
                  Text('\$', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(width: 12),
                  Text('ดอลลาร์สหรัฐ (USD)'),
                ],
              ),
            ),
          ],
          onChanged: _isEditing
              ? (value) {
                  setState(() {
                    _selectedCurrency = value!;
                    _hasUnsavedChanges = true;
                  });
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildShopStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryDarkBlue.withOpacity(0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.primaryDarkBlue.withOpacity(0.1)),
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
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppConstants.primaryDarkBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'สถิติร้านค้า',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryDarkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.shopping_cart,
                  label: 'ยอดขาย',
                  value: '-',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.inventory_2,
                  label: 'สินค้า',
                  value: '-',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
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
          const SizedBox(height: 100), // Space for FAB
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
            AppConstants.primaryYellow.withOpacity(0.15),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryYellow.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryYellow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppConstants.primaryYellow,
                      AppConstants.primaryYellow.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryYellow.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  color: AppConstants.primaryDarkBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PromptPay',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'รับชำระเงินผ่าน QR Code',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildModernTextField(
            controller: _promptPayController,
            label: 'หมายเลข PromptPay',
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.phone,
            enabled: _isEditing,
            hint: 'เบอร์โทร 10 หลัก หรือเลขประจำตัว 13 หลัก',
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final cleaned = value.replaceAll('-', '').replaceAll(' ', '');
                if (!RegExp(r'^[0-9]{10}$|^[0-9]{13}$').hasMatch(cleaned)) {
                  return 'กรุณากรอกเบอร์โทร 10 หลัก หรือเลขประจำตัว 13 หลัก';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'หมายเลข PromptPay จะใช้สำหรับสร้าง QR Code รับชำระเงินจากลูกค้า',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      height: 1.4,
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

  Widget _buildPaymentMethodsCard() {
    return _buildInfoCard(
      'วิธีการชำระเงินที่รองรับ',
      Icons.payment,
      [
        'PromptPay QR Code - รับเงินผ่านแอปธนาคาร',
        'เงินสด (Cash) - รับเงินสดโดยตรง',
        'การโอนเงินผ่านธนาคาร',
        'บัตรเครดิต/เดบิต (เร็วๆ นี้)',
      ],
      Colors.blue[50]!,
      Colors.blue,
    );
  }

  Widget _buildSecurityCard() {
    return _buildInfoCard(
      'ความปลอดภัยและความเป็นส่วนตัว',
      Icons.security,
      [
        'ข้อมูลทั้งหมดถูกเข้ารหัสอย่างปลอดภัย',
        'ไม่มีการเก็บข้อมูลบัตรเครดิต/เดบิต',
        'ข้อมูลส่วนตัวไม่ถูกแชร์กับบุคคลที่สาม',
        'ปฏิบัติตามมาตรฐานความปลอดภัย',
      ],
      Colors.green[50]!,
      Colors.green,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppConstants.primaryDarkBlue, size: 22),
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
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: enabled ? AppConstants.primaryDarkBlue : Colors.grey[400],
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppConstants.primaryDarkBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.errorRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: enabled ? AppConstants.primaryDarkBlue : Colors.grey[500],
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData icon,
    List<String> items,
    Color backgroundColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 15,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: AppConstants.textDarkGray,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}