import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../main_shell/main_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final result = await _authService.sendOtp(_emailController.text.trim());
      if (!mounted) return;

      final success = result['success'] == true;
      final message =
          result['message']?.toString() ?? (success ? 'OTP sent' : 'Failed to send OTP');

      if (success) {
        setState(() => _otpSent = true);
        Get.snackbar('OTP sent', message,
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Error', message,
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyAndLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_otpController.text.trim().length != 6) {
      Get.snackbar('Invalid OTP', 'Please enter 6-digit OTP',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await _authService.verifyOtpAndLogin(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );
      if (!ok) {
        Get.snackbar('Login failed', 'Invalid email or OTP');
        return;
      }
      Get.offAll(() => const MainShellScreen());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Icon(Icons.shield_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Incuspaze Guard',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  'Guard portal login',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter email';
                    if (!GetUtils.isEmail(v.trim())) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_otpSent) ...[
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'OTP',
                      hintText: 'Enter 6-digit OTP',
                      counterText: '',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) {
                      if (!_otpSent) return null;
                      if (v == null || v.trim().isEmpty) return 'Enter OTP';
                      if (v.trim().length != 6) return 'Enter 6-digit OTP';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: _loading
                      ? null
                      : _otpSent
                          ? _verifyAndLogin
                          : _sendOtp,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_otpSent ? 'Verify & Login' : 'Send OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
