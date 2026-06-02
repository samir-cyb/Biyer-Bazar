import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_theme.dart';
import 'models/user_model.dart';
import 'services/hive_service.dart';
import 'services/auth_service.dart';
import 'services/seed_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/host/host_shell.dart';
import 'screens/vendor/vendor_shell.dart';
import 'screens/admin/admin_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Init Hive and open all boxes
  await HiveService.init();

  // Seed on first launch
  SeedService.seed();

  runApp(const BiyerBajarApp());
}

class BiyerBajarApp extends StatelessWidget {
  const BiyerBajarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BiyerBajar — বিয়ের বাজার',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _resolveHome(),
    );
  }

  Widget _resolveHome() {
    final user = AuthService.currentUser;
    if (user == null) return const WelcomeScreen();
    switch (user.role) {
      case UserRole.host:
        return const HostShell();
      case UserRole.vendor:
        return const VendorShell();
      case UserRole.admin:
        return const AdminShell();
    }
  }
}
