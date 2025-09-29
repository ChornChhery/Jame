// FILE: lib/screens/auth_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../screens/forgot_password_screen.dart';

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
                  flex: 3,
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
                              width: 80,
                              height: 80,
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
                                size: 40,
                                color: AppConstants.primaryDarkBlue,
                              ),
                            ),
                            SizedBox(height: 16),
                            
                            // App Name
                            Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 4),
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
                  flex: 7,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Welcome text
                            Text(
                              'ยินดีต้อนรับกลับ',
                              style: TextStyle(
                                fontSize: 20,
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
                            SizedBox(height: 12),
                            // Gmail requirement notice
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryYellow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppConstants.primaryYellow.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppConstants.primaryDarkBlue,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'เฉพาะบัญชี Gmail เท่านั้น',
                                      style: TextStyle(
                                        color: AppConstants.primaryDarkBlue,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),

                            // Email field with modern design
                            _buildModernTextField(
                              controller: _emailController,
                              label: AppConstants.email,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
                                if (!AppUtils.isValidEmail(value!)) return 'รูปแบบอีเมลไม่ถูกต้อง';
                                
                                // Only validate Gmail format if the user has typed enough characters
                                final lowercaseEmail = value.toLowerCase();
                                if (!lowercaseEmail.endsWith('@gmail.com')) {
                                  // Check for common Gmail typing mistakes
                                  if (lowercaseEmail.contains('@gmail')) {
                                    // Check for common mistakes
                                    if (lowercaseEmail.contains('gmali') || 
                                        lowercaseEmail.contains('gmal') || 
                                        lowercaseEmail.contains('gmail.')) {
                                      return 'คุณหมายถึง @gmail.com ใช่หรือไม่?';
                                    }
                                    // Check for .con instead of .com
                                    if (lowercaseEmail.endsWith('@gmail.con') || 
                                        lowercaseEmail.endsWith('@gmail.co') ||
                                        lowercaseEmail.endsWith('@gmail.cm')) {
                                      return 'คุณหมายถึง @gmail.com ใช่หรือไม่?';
                                    }
                                  }
                                  // Only show this error if user has completed typing the domain
                                  if (lowercaseEmail.split('@').length > 1) {
                                    return 'กรุณาใช้บัญชี Gmail เท่านั้น (@gmail.com)';
                                  }
                                }
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
                            SizedBox(height: 12),

                            // Remember Me checkbox
                            Row(
                              children: [
                                Consumer<AuthProvider>(
                                  builder: (context, auth, child) {
                                    return Checkbox(
                                      value: auth.rememberMe,
                                      onChanged: (value) {
                                        // Update the auth provider directly
                                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                        authProvider.rememberMe = value ?? false;
                                      },
                                      activeColor: AppConstants.primaryDarkBlue,
                                    );
                                  },
                                ),
                                Text(
                                  'จดจำฉันไว้ในระบบ',
                                  style: TextStyle(
                                    color: AppConstants.textDarkGray,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            // Forgot Password link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/forgot-password');
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'ลืมรหัสผ่าน?',
                                  style: TextStyle(
                                    color: AppConstants.primaryDarkBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),

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
                            SizedBox(height: 16),

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
    int maxLines = 1,
  }) {
    // Special handling for email field to show helper text
    bool isEmailField = label == AppConstants.email;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
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
            // Add helper text for email field
            suffix: isEmailField
                ? Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '@gmail.com',
                      style: TextStyle(
                        color: AppConstants.textDarkGray.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        // Add helper text below email field
        if (isEmailField)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
            child: Text(
              'ระบบรองรับเฉพาะบัญชี Gmail เท่านั้น',
              style: TextStyle(
                color: AppConstants.textDarkGray.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if email is a Gmail address before attempting login
    final email = _emailController.text.trim();
    final lowercaseEmail = email.toLowerCase();
    
    if (!lowercaseEmail.endsWith('@gmail.com')) {
      String errorMessage = 'เฉพาะบัญชี Gmail เท่านั้นที่สามารถเข้าสู่ระบบได้';
      
      // Check for common Gmail typing mistakes
      if (lowercaseEmail.contains('@gmail')) {
        // Check for common mistakes
        if (lowercaseEmail.contains('gmali') || 
            lowercaseEmail.contains('gmal') || 
            lowercaseEmail.contains('gmail.')) {
          errorMessage = 'คุณหมายถึง @gmail.com ใช่หรือไม่?';
        }
        // Check for .con instead of .com
        else if (lowercaseEmail.endsWith('@gmail.con') || 
                 lowercaseEmail.endsWith('@gmail.co') ||
                 lowercaseEmail.endsWith('@gmail.cm')) {
          errorMessage = 'คุณหมายถึง @gmail.com ใช่หรือไม่?';
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppConstants.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // Start background connection test (non-blocking)
    auth.testServerConnectionBackground();
    
    final success = await auth.login(
      email,
      _passwordController.text,
      rememberMe: auth.rememberMe, // Pass the rememberMe value
    );

    if (success) {
      Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
    } else {
      // Check if it's a Gmail restriction or other login issue
      bool isGmail = lowercaseEmail.endsWith('@gmail.com');
      
      // Check connection status after login attempt
      final serverConnected = await auth.testServerConnection();
      
      String errorMessage = isGmail && serverConnected 
          ? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' // Email or password incorrect
          : !isGmail 
              ? 'เฉพาะบัญชี Gmail เท่านั้นที่สามารถเข้าสู่ระบบได้' // Only Gmail accounts can log in
              : 'ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่อีกครั้ง'; // Cannot login, try again
      
      // Check for common Gmail typing mistakes
      if (!isGmail && lowercaseEmail.contains('@gmail')) {
        // Check for common mistakes
        if (lowercaseEmail.contains('gmali') || 
            lowercaseEmail.contains('gmal') || 
            lowercaseEmail.contains('gmail.')) {
          errorMessage = 'คุณหมายถึง @gmail.com ใช่หรือไม่?';
        }
        // Check for .con instead of .com
        else if (lowercaseEmail.endsWith('@gmail.con') || 
                 lowercaseEmail.endsWith('@gmail.co') ||
                 lowercaseEmail.endsWith('@gmail.cm')) {
          errorMessage = 'คุณหมายถึง @gmail.com ใช่หรือไม่?';
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: !isGmail ? Colors.orange : (serverConnected ? AppConstants.errorRed : Colors.orange),
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
            
            // Only validate Gmail format if the user has typed enough characters
            final lowercaseEmail = value.toLowerCase();
            if (!lowercaseEmail.endsWith('@gmail.com')) {
              // Don't show error if user is still typing
              if (!lowercaseEmail.contains('@')) return null;
              
              // Check for common Gmail typing mistakes
              if (lowercaseEmail.contains('@gmail')) {
                // Check for common mistakes
                if (lowercaseEmail.contains('gmali') || 
                    lowercaseEmail.contains('gmal') || 
                    lowercaseEmail.contains('gmail.')) {
                  return 'คุณหมายถึง @gmail.com ใช่หรือไม่?';
                }
                // Check for .con instead of .com
                if (lowercaseEmail.endsWith('@gmail.con') || 
                    lowercaseEmail.endsWith('@gmail.co') ||
                    lowercaseEmail.endsWith('@gmail.cm')) {
                  return 'คุณหมายถึง @gmail.com ใช่หรือไม่?';
                }
              }
              // Only show this error if user has completed typing the domain
              if (lowercaseEmail.split('@').length > 1) {
                return 'กรุณาใช้บัญชี Gmail เท่านั้น (@gmail.com)';
              }
            }
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
        SizedBox(height: 12),
        // Gmail requirement notice
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppConstants.primaryYellow.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.primaryDarkBlue,
                size: 14,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'เฉพาะบัญชี Gmail เท่านั้น',
                  style: TextStyle(
                    color: AppConstants.primaryDarkBlue,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
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
    // Special handling for email field to show helper text
    bool isEmailField = label == AppConstants.email;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
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
            // Add helper text for email field
            suffix: isEmailField
                ? Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '@gmail.com',
                      style: TextStyle(
                        color: AppConstants.textDarkGray.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        // Add helper text below email field
        if (isEmailField)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
            child: Text(
              'ระบบรองรับเฉพาะบัญชี Gmail เท่านั้น',
              style: TextStyle(
                color: AppConstants.textDarkGray.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
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