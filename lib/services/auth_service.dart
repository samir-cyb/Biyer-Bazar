import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'hive_service.dart';

class AuthService {
  static const _uuid = Uuid();

  static AppUser? get currentUser => HiveService.getCurrentUser();
  static bool get isLoggedIn => currentUser != null;

  /// Signs up a new user and saves to Hive. Returns the created user.
  static AppUser signup({
    required String name,
    required String phone,
    required UserRole role,
    String? businessName,
    String? vendorCategory,
    String? location,
    String? city,
  }) {
    final user = AppUser(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      role: role,
      businessName: businessName,
      vendorCategory: vendorCategory,
      location: location,
      daysOnPlatform:
          1, // new user — qualifies for Fresh Talent slots
      city: city,
    );
    HiveService.saveUser(user);
    HiveService.setCurrentUserId(user.id);
    return user;
  }

  /// Logs in by matching phone number. Returns user or null if not found.
  static AppUser? login(String phone) {
    final user = HiveService.findUserByPhone(phone);
    if (user != null) {
      HiveService.setCurrentUserId(user.id);
    }
    return user;
  }

  static void logout() => HiveService.clearSession();

  /// Checks whether a phone number is already registered.
  static bool phoneExists(String phone) =>
      HiveService.findUserByPhone(phone) != null;
}
