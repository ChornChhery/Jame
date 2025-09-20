// FILE: lib/screens/auth_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../models/product.dart';
import '../core/constants.dart';
import '../core/utils.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                // Header Section with Background
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppConstants.primaryDarkBlue,
                          AppConstants.primaryDarkBlue.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo with modern design
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppConstants.primaryYellow,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.store_rounded,
                                size: 50,
                                color: AppConstants.primaryDarkBlue,
                              ),
                            ),
                            SizedBox(height: 24),
                            
                            // App Name
                            Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              AppConstants.loginTitle,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Form Section
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Welcome text
                            Text(
                              'ยินดีต้อนรับกลับ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryDarkBlue,
                              ),
                            ),
                            Text(
                              'เข้าสู่ระบบเพื่อดำเนินการต่อ',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppConstants.textDarkGray,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 40),

                            // Email field with modern design
                            _buildModernTextField(
                              controller: _emailController,
                              label: AppConstants.email,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
                                if (!AppUtils.isValidEmail(value!)) return 'รูปแบบอีเมลไม่ถูกต้อง';
                                return null;
                              },
                            ),
                            SizedBox(height: 20),

                            // Password field
                            _buildModernTextField(
                              controller: _passwordController,
                              label: AppConstants.password,
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppConstants.textDarkGray,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'กรุณากรอกรหัสผ่าน';
                                if (!AppUtils.isValidPassword(value!)) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                                return null;
                              },
                            ),
                            SizedBox(height: 32),

                            // Login button
                            Consumer<AuthProvider>(
                              builder: (context, auth, child) {
                                return Container(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: auth.isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppConstants.primaryDarkBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: auth.isLoading
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            AppConstants.login,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 24),

                            // Signup link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ยังไม่มีบัญชี? ',
                                  style: TextStyle(
                                    color: AppConstants.textDarkGray,
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, AppConstants.signupRoute),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'สมัครสมาชิก',
                                    style: TextStyle(
                                      color: AppConstants.primaryDarkBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
        color: AppConstants.primaryDarkBlue,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.textDarkGray),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: AppConstants.textDarkGray,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppConstants.primaryDarkBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppConstants.errorRed,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppConstants.errorRed,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // Start background connection test (non-blocking)
    auth.testServerConnectionBackground();
    
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
    } else {
      // Check connection status after login attempt
      final serverConnected = await auth.testServerConnection();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serverConnected 
              ? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' // Email or password incorrect
              : 'ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่อีกครั้ง'), // Cannot login, try again
          backgroundColor: serverConnected ? AppConstants.errorRed : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.primaryDarkBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          AppConstants.signupTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Progress indicator
                  Row(
                    children: [
                      _buildStepIndicator(0, 'ข้อมูลส่วนตัว'),
                      Expanded(child: _buildStepLine(0 < _currentStep)),
                      _buildStepIndicator(1, 'ข้อมูลร้าน'),
                    ],
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: _currentStep == 0 ? _buildPersonalInfoStep() : _buildShopInfoStep(),
                  ),
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _currentStep = 0);
                          _animationController.reset();
                          _animationController.forward();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.primaryDarkBlue,
                          side: BorderSide(color: AppConstants.primaryDarkBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('ย้อนกลับ'),
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        return ElevatedButton(
                          onPressed: auth.isLoading ? null : (_currentStep == 0 ? _nextStep : _handleSignup),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryDarkBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: auth.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _currentStep == 0 ? 'ถัดไป' : AppConstants.signup,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        );
                      },
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

  Widget _buildStepIndicator(int step, String label) {
    bool isActive = step <= _currentStep;
    bool isCurrent = step == _currentStep;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppConstants.primaryYellow : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? AppConstants.primaryDarkBlue : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Container(
      height: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isCompleted ? AppConstants.primaryYellow : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ข้อมูลส่วนตัว',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryDarkBlue,
          ),
        ),
        Text(
          'กรอกข้อมูลส่วนตัวของคุณ',
          style: TextStyle(
            fontSize: 14,
            color: AppConstants.textDarkGray,
          ),
        ),
        SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _firstNameController,
                label: 'ชื่อ',
                icon: Icons.person_outline,
                validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อ' : null,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: _lastNameController,
                label: 'นามสกุล',
                icon: Icons.person_outline,
                validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกนามสกุล' : null,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        _buildModernTextField(
          controller: _usernameController,
          label: 'ชื่อผู้ใช้',
          icon: Icons.account_circle_outlined,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'กรุณากรอกชื่อผู้ใช้';
            if (value!.length < 3) return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร';
            return null;
          },
        ),
        SizedBox(height: 20),

        _buildModernTextField(
          controller: _emailController,
          label: AppConstants.email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
            if (!AppUtils.isValidEmail(value!)) return 'รูปแบบอีเมลไม่ถูกต้อง';
            return null;
          },
        ),
        SizedBox(height: 20),

        _buildModernTextField(
          controller: _passwordController,
          label: AppConstants.password,
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppConstants.textDarkGray,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'กรุณากรอกรหัสผ่าน';
            if (!AppUtils.isValidPassword(value!)) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
            return null;
          },
        ),
        SizedBox(height: 20),

        _buildModernTextField(
          controller: _confirmPasswordController,
          label: 'ยืนยันรหัสผ่าน',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: AppConstants.textDarkGray,
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (value) {
            if (value != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildShopInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ข้อมูลร้าน',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryDarkBlue,
          ),
        ),
        Text(
          'กรอกข้อมูลร้านค้าของคุณ',
          style: TextStyle(
            fontSize: 14,
            color: AppConstants.textDarkGray,
          ),
        ),
        SizedBox(height: 32),

        _buildModernTextField(
          controller: _shopNameController,
          label: AppConstants.shopName,
          icon: Icons.store_outlined,
          validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อร้าน' : null,
        ),
        SizedBox(height: 20),

        _buildModernTextField(
          controller: _shopAddressController,
          label: 'ที่อยู่ร้าน',
          icon: Icons.location_on_outlined,
          maxLines: 3,
        ),
        SizedBox(height: 20),

        _buildModernTextField(
          controller: _shopPhoneController,
          label: 'เบอร์โทรร้าน',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 32),

        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.primaryYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppConstants.primaryYellow.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.primaryDarkBlue,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ข้อมูลร้านค้าจะถูกใช้ในการออกใบเสร็จและเอกสารทางการเงิน',
                  style: TextStyle(
                    color: AppConstants.primaryDarkBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'มีบัญชีแล้ว? ',
              style: TextStyle(
                color: AppConstants.textDarkGray,
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'เข้าสู่ระบบ',
                style: TextStyle(
                  color: AppConstants.primaryDarkBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 16,
        color: AppConstants.primaryDarkBlue,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.textDarkGray),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: AppConstants.textDarkGray,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppConstants.primaryDarkBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppConstants.errorRed,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppConstants.errorRed,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    
    setState(() => _currentStep = 1);
    _animationController.reset();
    _animationController.forward();
  }

  bool _validateCurrentStep() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }

    // Validate only the fields in current step
    if (_currentStep == 0) {
      bool isValid = true;
      if (_firstNameController.text.trim().isEmpty) isValid = false;
      if (_lastNameController.text.trim().isEmpty) isValid = false;
      if (_usernameController.text.trim().isEmpty || _usernameController.text.trim().length < 3) isValid = false;
      if (_emailController.text.trim().isEmpty || !AppUtils.isValidEmail(_emailController.text.trim())) isValid = false;
      if (_passwordController.text.isEmpty || !AppUtils.isValidPassword(_passwordController.text)) isValid = false;
      if (_confirmPasswordController.text != _passwordController.text) isValid = false;
      
      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้อง'),
            backgroundColor: AppConstants.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
      return isValid;
    }
    return true;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // Start background connection test (non-blocking)
    auth.testServerConnectionBackground();
    
    final error = await auth.signup(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      shopName: _shopNameController.text.trim(),
      shopAddress: _shopAddressController.text.trim().isEmpty ? null : _shopAddressController.text.trim(),
      shopPhone: _shopPhoneController.text.trim().isEmpty ? null : _shopPhoneController.text.trim(),
    );

    if (error == null) {
      Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
    } else {
      // Check connection status after signup attempt
      final serverConnected = await auth.testServerConnection();
      
      String message = error;
      if (!serverConnected) {
        message = '⚠️ ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ ไม่สามารถสมัครสมาชิกได้'; // Cannot connect to server, cannot register
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: serverConnected ? AppConstants.errorRed : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

// ================================
// QR SCANNER SCREEN
// ================================

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

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _initializeAnimations();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _initializeAnimations() {
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
              child: AnimatedBuilder(
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
              ),
            )),
            
            // Center scanning line
            if (!_hasScanned)
              AnimatedBuilder(
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
              FadeTransition(
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
      child: FadeTransition(
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppConstants.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: AppConstants.successGreen,
                      size: 24,
                    ),
                  ),
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
    _scannerController?.dispose();
    _animationController.dispose();
    super.dispose();
  }
}