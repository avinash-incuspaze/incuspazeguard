import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'config/env.dart';
import 'screens/login/login_screen.dart';
import 'screens/main_shell/main_shell_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IncuspazeGuardApp());
}

class IncuspazeGuardApp extends StatelessWidget {
  const IncuspazeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: Env.appName,
      theme: AppTheme.light,
      getPages: AppPages.routes,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _authService.isLoggedIn().then((v) {
      if (mounted) {
        setState(() {
          _checking = false;
          _loggedIn = v;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _loggedIn ? const MainShellScreen() : const LoginScreen();
  }
}
