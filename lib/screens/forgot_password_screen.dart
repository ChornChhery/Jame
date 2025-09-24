// FILE: lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isVerificationStep = true; // true for verification, false for password reset
  User? _verifiedUser;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _shopNameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.lightGray,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryDarkBlue,
        foregroundColor: Colors.white,
        title: Text(_isVerificationStep ? 'ลืมรหัสผ่าน' : 'รีเซ็ตรหัสผ่าน'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_isVerificationStep) {
              Navigator.pop(context);
            } else {
              setState(() {
                _isVerificationStep = true;
              });
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: _isVerificationStep ? _buildVerificationStep() : _buildResetPasswordStep(),
        ),
      ),
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ลืมรหัสผ่าน?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryDarkBlue,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'กรุณากรอกข้อมูลด้านล่างเพื่อยืนยันตัวตนของคุณ',
          style: TextStyle(
            fontSize: 14,
            color: AppConstants.textDarkGray,
          ),
        ),
        SizedBox(height: 32),

        _buildTextField(
          controller: _usernameController,
          label: 'ชื่อผู้ใช้',
          icon: Icons.account_circle_outlined,
          validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อผู้ใช้' : null,
        ),
        SizedBox(height: 20),

        _buildTextField(
          controller: _shopNameController,
          label: 'ชื่อร้าน',
          icon: Icons.store_outlined,
          validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อร้าน' : null,
        ),
        SizedBox(height: 20),

        _buildTextField(
          controller: _emailController,
          label: 'อีเมล',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
            if (!AppUtils.isValidEmail(value!)) return 'รูปแบบอีเมลไม่ถูกต้อง';
            return null;
          },
        ),
        SizedBox(height: 32),

        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.primaryYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.primaryYellow.withOpacity(0.3),
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
                  'เราจะตรวจสอบข้อมูลที่คุณกรอกกับข้อมูลในระบบ หากข้อมูลถูกต้อง คุณจะสามารถตั้งรหัสผ่านใหม่ได้',
                  style: TextStyle(
                    color: AppConstants.primaryDarkBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _verifyUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryDarkBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'ยืนยันข้อมูล',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ตั้งรหัสผ่านใหม่',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryDarkBlue,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'กรุณาตั้งรหัสผ่านใหม่สำหรับบัญชีของคุณ',
          style: TextStyle(
            fontSize: 14,
            color: AppConstants.textDarkGray,
          ),
        ),
        SizedBox(height: 32),

        _buildTextField(
          controller: _newPasswordController,
          label: 'รหัสผ่านใหม่',
          icon: Icons.lock_outline,
          obscureText: _obscureNewPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
              color: AppConstants.textDarkGray,
            ),
            onPressed: () {
              setState(() {
                _obscureNewPassword = !_obscureNewPassword;
              });
            },
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'กรุณากรอกรหัสผ่าน';
            if (!AppUtils.isValidPassword(value!)) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
            return null;
          },
        ),
        SizedBox(height: 20),

        _buildTextField(
          controller: _confirmPasswordController,
          label: 'ยืนยันรหัสผ่านใหม่',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: AppConstants.textDarkGray,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'กรุณายืนยันรหัสผ่าน';
            if (value != _newPasswordController.text) return 'รหัสผ่านไม่ตรงกัน';
            return null;
          },
        ),
        SizedBox(height: 32),

        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.primaryYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.primaryYellow.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.security_outlined,
                color: AppConstants.primaryDarkBlue,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'รหัสผ่านควรมีความยาวอย่างน้อย 6 ตัวอักษร และควรมีทั้งตัวอักษรและตัวเลขเพื่อความปลอดภัย',
                  style: TextStyle(
                    color: AppConstants.primaryDarkBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryDarkBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'รีเซ็ตรหัสผ่าน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.textDarkGray),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: AppConstants.textDarkGray,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.primaryDarkBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.errorRed,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.errorRed,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Future<void> _verifyUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: AppConstants.primaryYellow,
        ),
      ),
    );

    try {
      // Verify user by username, shop name, and email
      final user = await DatabaseHelper.instance.getUserByUsername(_usernameController.text.trim());
      
      if (user != null) {
        // Check if shop name and email match
        if (user.shopName == _shopNameController.text.trim() && 
            user.email == _emailController.text.trim()) {
          // Verification successful
          Navigator.pop(context); // Remove loading indicator
          setState(() {
            _verifiedUser = user;
            _isVerificationStep = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ยืนยันข้อมูลสำเร็จ กรุณาตั้งรหัสผ่านใหม่'),
              backgroundColor: AppConstants.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(16),
            ),
          );
        } else {
          Navigator.pop(context); // Remove loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ข้อมูลไม่ตรงกับบันทึกในระบบ'),
              backgroundColor: AppConstants.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(16),
            ),
          );
        }
      } else {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่พบผู้ใช้งานในระบบ'),
            backgroundColor: AppConstants.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
          backgroundColor: AppConstants.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_verifiedUser == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: AppConstants.primaryYellow,
        ),
      ),
    );

    try {
      // Hash the new password
      final hashedPassword = AppUtils.hashPassword(_newPasswordController.text);
      
      // Update user password
      final result = await DatabaseHelper.instance.updateUserPassword(
        _verifiedUser!.id!, 
        hashedPassword
      );
      
      Navigator.pop(context); // Remove loading indicator
      
      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('รีเซ็ตรหัสผ่านสำเร็จ'),
            backgroundColor: AppConstants.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
        
        // Navigate back to login screen
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถรีเซ็ตรหัสผ่านได้'),
            backgroundColor: AppConstants.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
          backgroundColor: AppConstants.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }
}