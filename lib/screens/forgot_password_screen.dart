import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/translations.dart';
import '../core/utils.dart';
import '../providers/auth_provider.dart';
import '../widgets/language_switch_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isVerificationStep = true;
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
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
        title: Text(
          _isVerificationStep
              ? context.tr('forgot_password_title')
              : context.tr('reset_password'),
        ),
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 12),
              child: LanguageSwitchButton(
                isDarkBackground: true,
                compact: true,
              ),
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isVerificationStep) {
              Navigator.pop(context);
            } else {
              setState(() => _isVerificationStep = true);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: _isVerificationStep
              ? _buildRequestCodeStep()
              : _buildResetPasswordStep(),
        ),
      ),
    );
  }

  Widget _buildRequestCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.t('ui_forgot_password'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryDarkBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppTranslations.t('ui_enter_your_email_to_receive_a'),
          style: TextStyle(fontSize: 14, color: AppConstants.textDarkGray),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          controller: _emailController,
          label: AppTranslations.t('ui_email'),
          icon: Icons.email_outlined,
          key: const ValueKey('reset-email'),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) return AppTranslations.t('ui_please_enter_your_email');
            if (!AppUtils.isValidEmail(email)) return AppTranslations.t('ui_invalid_email_format');
            if (!email.toLowerCase().endsWith('@gmail.com')) {
              return AppTranslations.t('ui_please_use_a_gmail_account_only_2');
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _infoBox(
          AppTranslations.t('ui_if_this_account_exists_we_will'),
          Icons.info_outline,
        ),
        const SizedBox(height: 32),
        _actionButton(
          key: const ValueKey('request-reset-code'),
          label: AppTranslations.t('ui_send_verification_code'),
          onPressed: _requestResetCode,
        ),
      ],
    );
  }

  Widget _buildResetPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.t('ui_set_new_password'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryDarkBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppTranslations.t('ui_enter_the_code_sent_to', [_emailController.text.trim()]),
          style: TextStyle(fontSize: 14, color: AppConstants.textDarkGray),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          controller: _verificationCodeController,
          label: AppTranslations.t('ui_6_digit_verification_code'),
          icon: Icons.pin_outlined,
          key: const ValueKey('verification-code'),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
              return AppTranslations.t('ui_please_enter_the_6_digit_verification');
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _newPasswordController,
          label: AppTranslations.t('ui_new_password'),
          icon: Icons.lock_outline,
          key: const ValueKey('new-password'),
          obscureText: _obscureNewPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
              color: AppConstants.textDarkGray,
            ),
            onPressed: () =>
                setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
          validator: (value) {
            if (value == null || value.length < 8) {
              return AppTranslations.t('ui_password_must_be_at_least_8');
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _confirmPasswordController,
          label: AppTranslations.t('ui_confirm_new_password'),
          icon: Icons.lock_outline,
          key: const ValueKey('confirm-password'),
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: AppConstants.textDarkGray,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
          validator: (value) {
            if (value != _newPasswordController.text) {
              return AppTranslations.t('ui_passwords_do_not_match');
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _infoBox(
          AppTranslations.t('ui_the_verification_code_can_be_used'),
          Icons.security_outlined,
        ),
        const SizedBox(height: 32),
        _actionButton(
          key: const ValueKey('confirm-password-reset'),
          label: AppTranslations.t('ui_reset_password'),
          onPressed: _resetPassword,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Key? key,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.textDarkGray),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.primaryDarkBlue, width: 2),
        ),
      ),
    );
  }

  Widget _infoBox(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.primaryYellow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryDarkBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppConstants.primaryDarkBlue,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required Key key,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        key: key,
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryDarkBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _requestResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().requestPasswordReset(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isVerificationStep = false);
      _showMessage(
        AppTranslations.t('ui_if_this_account_exists_we_will'),
        AppConstants.successGreen,
      );
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString(), AppConstants.errorRed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().confirmPasswordReset(
        email: _emailController.text.trim(),
        code: _verificationCodeController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _verificationCodeController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _isVerificationStep = true);
      _showMessage(AppTranslations.t('ui_password_reset_successful'), AppConstants.successGreen);
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString(), AppConstants.errorRed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
