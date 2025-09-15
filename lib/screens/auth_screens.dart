// FILE: lib/screens/auth_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';
import '../core/utils.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store,
                    size: 60,
                    color: AppConstants.primaryDarkBlue,
                  ),
                ),
                SizedBox(height: 32),
                
                // Title
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryDarkBlue,
                  ),
                ),
                Text(
                  AppConstants.loginTitle,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppConstants.textDarkGray,
                  ),
                ),
                SizedBox(height: 32),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppConstants.email,
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
                    if (!AppUtils.isValidEmail(value!)) return 'รูปแบบอีเมลไม่ถูกต้อง';
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppConstants.password,
                    prefixIcon: Icon(Icons.lock),
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
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        child: auth.isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(AppConstants.login),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),

                // Signup link
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppConstants.signupRoute),
                  child: Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      appBar: AppBar(
        title: Text(AppConstants.signupTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Personal Info
                Text(
                  'ข้อมูลส่วนตัว',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryDarkBlue,
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: 'ชื่อ',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อ' : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'นามสกุล',
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกนามสกุล' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อผู้ใช้',
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณากรอกชื่อผู้ใช้';
                    if (value!.length < 3) return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร';
                    return null;
                  },
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppConstants.email,
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
                    if (!AppUtils.isValidEmail(value!)) return 'รูปแบบอีเมลไม่ถูกต้อง';
                    return null;
                  },
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppConstants.password,
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณากรอกรหัสผ่าน';
                    if (!AppUtils.isValidPassword(value!)) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                    return null;
                  },
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'ยืนยันรหัสผ่าน',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Shop Info
                Text(
                  'ข้อมูลร้าน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryDarkBlue,
                  ),
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _shopNameController,
                  decoration: InputDecoration(
                    labelText: AppConstants.shopName,
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อร้าน' : null,
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _shopAddressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'ที่อยู่ร้าน',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _shopPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'เบอร์โทรร้าน',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                SizedBox(height: 32),

                // Signup button
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleSignup,
                        child: auth.isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(AppConstants.signup),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('มีบัญชีแล้ว? เข้าสู่ระบบ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppConstants.errorRed,
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
    super.dispose();
  }
}