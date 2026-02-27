import 'package:get/get.dart';

import '../../screens/login/login_screen.dart';
import '../../screens/main_shell/main_shell_screen.dart';
import '../../screens/visitors_list/visitors_list_screen.dart';

abstract class AppPages {
  static const login = '/login';
  static const mainShell = '/';
  static const visitorsList = '/visitors-list';

  static final routes = [
    GetPage(name: mainShell, page: () => const MainShellScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: visitorsList, page: () => const VisitorsListScreen(showBackButton: true)),
  ];
}
