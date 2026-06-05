import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_theme.dart';
import 'core/app_strings.dart';
import 'models/user_model.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/platform_settings_service.dart';
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
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));

  await SupabaseService.init();
  dev.log('[main] Supabase initialized', name: 'BiyerBajar');

  await PlatformSettingsService.load();
  dev.log('[main] Platform settings loaded',name: 'BiyerBajar');

  final user = await AuthService.loadCurrentUser();
  dev.log('[main] Session user: ${user?.name ?? "none"}', name: 'BiyerBajar');

  runApp(BiyerBajarApp(initialUser: user));
}

class BiyerBajarApp extends StatefulWidget {
  final AppUser? initialUser;
  const BiyerBajarApp({super.key, this.initialUser});

  @override
  State<BiyerBajarApp> createState() => _BiyerBajarAppState();
}

class _BiyerBajarAppState extends State<BiyerBajarApp> {
  @override
  void initState() {
    super.initState();
    // Rebuild app when language changes
    AppStrings.languageNotifier.addListener(_onLangChange);
  }

  @override
  void dispose() {
    AppStrings.languageNotifier.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _resolveHome(),
    );
  }

  Widget _resolveHome() {
    final user = widget.initialUser;
    if (user == null) return const WelcomeScreen();
    dev.log('[main] Routing to ${user.role.name} shell', name: 'BiyerBajar');
    switch (user.role) {
      case UserRole.host:   return const HostShell();
      case UserRole.vendor: return const VendorShell();
      case UserRole.admin:  return const AdminShell();
    }
  }
}
