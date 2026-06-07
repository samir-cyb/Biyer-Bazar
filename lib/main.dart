import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_theme.dart';
import 'core/app_strings.dart';
import 'models/user_model.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/platform_settings_service.dart';
import 'screens/shell/app_shell.dart';
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
  dev.log('[main] Platform settings loaded', name: 'BiyerBajar');

  final user = await AuthService.loadCurrentUser();
  dev.log('[main] Session user: ${user?.name ?? "none"}', name: 'BiyerBajar');

  runApp(UtsobApp(initialUser: user));
}

class UtsobApp extends StatefulWidget {
  final AppUser? initialUser;
  const UtsobApp({super.key, this.initialUser});

  @override
  State<UtsobApp> createState() => _UtsobAppState();
}

class _UtsobAppState extends State<UtsobApp> {
  @override
  void initState() {
    super.initState();
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

    // Admins get their own back-office shell
    if (user?.role == UserRole.admin) {
      dev.log('[main] Routing to AdminShell', name: 'BiyerBajar');
      return const AdminShell();
    }

    // Everyone else — guests, hosts, vendors — all get the unified AppShell.
    // The shell adapts its nav based on whether the user is logged in.
    dev.log('[main] Routing to AppShell (user: ${user?.name ?? "guest"})',
        name: 'BiyerBajar');
    return AppShell(initialUser: user);
  }
}
