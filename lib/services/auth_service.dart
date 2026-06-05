import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

/// Authentication service — wraps Supabase Auth.
/// Admin login is special-cased with hardcoded credentials.
class AuthService {
  // ── Current user ─────────────────────────────────────────────────────────────

  static AppUser? _cachedUser;

  static AppUser? get currentUser => _cachedUser;
  static bool get isLoggedIn => SupabaseService.isLoggedIn && _cachedUser != null;

  /// Loads the profile for the currently authenticated user from Supabase.
  static Future<AppUser?> loadCurrentUser() async {
    final authUser = SupabaseService.currentAuthUser;
    if (authUser == null) {
      _cachedUser = null;
      return null;
    }
    try {
      final data = await SupabaseService.profiles
          .select('*, vendor_profiles!vendor_profiles_user_id_fkey(*)')
          .eq('id', authUser.id)
          .maybeSingle();

      if (data == null) {
        _cachedUser = null;
        return null;
      }
      _cachedUser = AppUser.fromMap(data);
      dev.log('[Auth] Loaded user: ${_cachedUser?.name} (${_cachedUser?.role.name})', name: 'BiyerBajar');
      return _cachedUser;
    } catch (e) {
      SupabaseService.debugLog('loadCurrentUser failed', error: e);
      return null;
    }
  }

  // ── Sign Up ──────────────────────────────────────────────────────────────────

  static Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? nidNumber,
    String? businessName,
    String? vendorCategory,
    String? location,
    String? city,
  }) async {
    dev.log('[Auth] Signup attempt: $email (${role.name})', name: 'BiyerBajar');

    // Admin signup is blocked — admin is added by main admin only
    if (role == UserRole.admin) {
      return AuthResult.error('Admin accounts can only be created by the main admin.');
    }

    try {
      // 1. Create Supabase Auth user
      final res = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.name,
          'phone': phone,
        },
      );

      if (res.user == null) {
        return AuthResult.error('Signup failed. Please try again.');
      }

      final userId = res.user!.id;

      // 2. Upsert profile row (trigger also creates it, this adds extra fields)
      await SupabaseService.profiles.upsert({
        'id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'nid_number': nidNumber,
        'city': city ?? location,
      });

      // 3. If vendor, create vendor_profiles row
      if (role == UserRole.vendor) {
        await SupabaseService.vendorProfiles.upsert({
          'user_id': userId,
          'business_name': businessName ?? name,
          'category': vendorCategory,
          'location': location,
          'days_on_platform': 1,
          'badge_tier': 'newcomer',
        });
      }

      await loadCurrentUser();
      dev.log('[Auth] Signup success: $userId', name: 'BiyerBajar');
      return AuthResult.success(_cachedUser!);
    } on AuthException catch (e) {
      SupabaseService.debugLog('Signup AuthException', error: e.message);
      return AuthResult.error(_friendlyAuthError(e.message));
    } catch (e) {
      SupabaseService.debugLog('Signup error', error: e);
      return AuthResult.error('An unexpected error occurred. Please try again.');
    }
  }

  // ── Sign In ──────────────────────────────────────────────────────────────────

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    dev.log('[Auth] Login attempt: $email', name: 'BiyerBajar');

    // Hardcoded main admin check
    if (email.trim().toLowerCase() == SupabaseConfig.mainAdminEmail.toLowerCase() &&
        password == SupabaseConfig.mainAdminPassword) {
      return _loginAdmin(email, password);
    }

    try {
      final res = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.user == null) return AuthResult.error('Login failed.');

      await loadCurrentUser();
      if (_cachedUser == null) return AuthResult.error('Profile not found. Please sign up first.');

      dev.log('[Auth] Login success: ${_cachedUser?.name}', name: 'BiyerBajar');
      return AuthResult.success(_cachedUser!);
    } on AuthException catch (e) {
      SupabaseService.debugLog('Login AuthException', error: e.message);
      return AuthResult.error(_friendlyAuthError(e.message));
    } catch (e) {
      SupabaseService.debugLog('Login error', error: e);
      return AuthResult.error('An unexpected error occurred.');
    }
  }

  static Future<AuthResult> _loginAdmin(String email, String password) async {
    try {
      // Try Supabase Auth first (admin may have been registered)
      try {
        final res = await SupabaseService.client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        if (res.user != null) {
          await loadCurrentUser();
          if (_cachedUser != null && _cachedUser!.role == UserRole.admin) {
            return AuthResult.success(_cachedUser!);
          }
        }
      } catch (_) {}

      // Fallback: sign up admin if not exists
      try {
        final res = await SupabaseService.client.auth.signUp(
          email: email.trim(),
          password: password,
          data: {'name': 'Samir (Main Admin)', 'role': 'admin'},
        );
        if (res.user != null) {
          await SupabaseService.profiles.upsert({
            'id': res.user!.id,
            'name': 'Samir (Main Admin)',
            'email': email.trim(),
            'role': 'admin',
          });
          await loadCurrentUser();
          if (_cachedUser != null) return AuthResult.success(_cachedUser!);
        }
      } catch (_) {}

      // Last resort: create local admin user without auth (dev mode)
      _cachedUser = AppUser(
        id: 'admin-hardcoded',
        name: 'Samir (Main Admin)',
        email: email,
        phone: '00000000000',
        role: UserRole.admin,
        isMainAdmin: true,
      );
      return AuthResult.success(_cachedUser!);
    } catch (e) {
      SupabaseService.debugLog('Admin login error', error: e);
      return AuthResult.error('Admin login failed.');
    }
  }

  // ── Forgot Password (Phone OTP) ───────────────────────────────────────────

  /// Step 1: Find user by phone and send OTP via Supabase Phone Auth.
  static Future<AuthResult> sendPhoneOtp(String phone) async {
    dev.log('[Auth] Sending OTP to: $phone', name: 'BiyerBajar');
    try {
      // Check phone exists in our profiles first
      final data = await SupabaseService.profiles
          .select('id, email, name, role')
          .eq('phone', phone.trim())
          .maybeSingle();
      if (data == null) {
        return AuthResult.error('No account found with this phone number.');
      }
      // Send OTP via Supabase phone auth
      await SupabaseService.client.auth.signInWithOtp(
        phone: '+88${phone.trim()}',
      );
      dev.log('[Auth] OTP sent to +88$phone', name: 'BiyerBajar');
      return AuthResult.success(null);
    } on AuthException catch (e) {
      SupabaseService.debugLog('sendPhoneOtp AuthException', error: e.message);
      // Fallback: if phone auth not enabled, use direct lookup
      if (e.message.toLowerCase().contains('phone') ||
          e.message.toLowerCase().contains('provider') ||
          e.message.toLowerCase().contains('sms')) {
        dev.log('[Auth] Phone OTP not configured — using dev fallback', name: 'BiyerBajar');
        return AuthResult.error(
          'SMS service not yet configured. Please contact support or use email reset.',
        );
      }
      return AuthResult.error(_friendlyAuthError(e.message));
    } catch (e) {
      SupabaseService.debugLog('sendPhoneOtp error', error: e);
      return AuthResult.error('Could not send OTP. Please try again.');
    }
  }

  /// Step 2: Verify OTP entered by user.
  static Future<AuthResult> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    dev.log('[Auth] Verifying OTP for: $phone', name: 'BiyerBajar');
    try {
      final res = await SupabaseService.client.auth.verifyOTP(
        phone: '+88${phone.trim()}',
        token: otp.trim(),
        type: OtpType.sms,
      );
      if (res.user == null) {
        return AuthResult.error('Invalid or expired OTP. Please try again.');
      }
      await loadCurrentUser();
      return AuthResult.success(_cachedUser);
    } on AuthException catch (e) {
      SupabaseService.debugLog('verifyPhoneOtp AuthException', error: e.message);
      return AuthResult.error('Invalid OTP: ${e.message}');
    } catch (e) {
      SupabaseService.debugLog('verifyPhoneOtp error', error: e);
      return AuthResult.error('OTP verification failed. Please try again.');
    }
  }

  /// Step 3: Set new password (called after OTP verified — user is now authenticated).
  static Future<AuthResult> setNewPassword(String newPassword) async {
    dev.log('[Auth] Setting new password after OTP verification', name: 'BiyerBajar');
    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return AuthResult.success(_cachedUser);
    } on AuthException catch (e) {
      SupabaseService.debugLog('setNewPassword AuthException', error: e.message);
      return AuthResult.error(_friendlyAuthError(e.message));
    } catch (e) {
      SupabaseService.debugLog('setNewPassword error', error: e);
      return AuthResult.error('Failed to update password. Please try again.');
    }
  }

  /// Legacy dev-mode fallback: find user by phone (no OTP).
  static Future<AppUser?> findUserByPhone(String phone) async {
    try {
      final data = await SupabaseService.profiles
          .select()
          .eq('phone', phone.trim())
          .maybeSingle();
      if (data == null) return null;
      return AppUser.fromMap(data);
    } catch (e) {
      SupabaseService.debugLog('findUserByPhone error', error: e);
      return null;
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    dev.log('[Auth] Logout', name: 'BiyerBajar');
    _cachedUser = null;
    try {
      await SupabaseService.client.auth.signOut();
    } catch (e) {
      SupabaseService.debugLog('Logout error', error: e);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  static String _friendlyAuthError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'This email is already registered. Please sign in.';
    }
    if (m.contains('password')) return 'Password must be at least 6 characters.';
    if (m.contains('email')) return 'Please enter a valid email address.';
    if (m.contains('network')) return 'Network error. Check your connection.';
    return msg;
  }
}

/// Wraps auth results cleanly.
class AuthResult {
  final AppUser? user;
  final String? errorMessage;
  bool get isSuccess => errorMessage == null;

  AuthResult._({this.user, this.errorMessage});
  factory AuthResult.success(AppUser? user) => AuthResult._(user: user);
  factory AuthResult.error(String msg)       => AuthResult._(errorMessage: msg);
}
