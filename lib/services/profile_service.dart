import 'dart:developer' as dev;
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class ProfileService {
  /// Upload a profile picture and return the public URL.
  static Future<String?> uploadAvatar(File imageFile, String userId) async {
    dev.log('[Profile] Uploading avatar for $userId', name: 'BiyerBajar');
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final path = '$userId/avatar.$ext';

      await SupabaseService.avatarStorage.upload(
        path,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      final url = SupabaseService.avatarStorage.getPublicUrl(path);
      dev.log('[Profile] Avatar uploaded: $url', name: 'BiyerBajar');

      // Update profile row
      await SupabaseService.profiles
          .update({'profile_picture_url': url}).eq('id', userId);

      return url;
    } catch (e) {
      SupabaseService.debugLog('uploadAvatar error', error: e);
      return null;
    }
  }

  /// Upload a portfolio image and return the public URL.
  static Future<String?> uploadPortfolioImage(File imageFile, String vendorId, int index) async {
    dev.log('[Profile] Uploading portfolio image $index for $vendorId', name: 'BiyerBajar');
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final path = '$vendorId/portfolio_$index.$ext';

      await SupabaseService.portfolioStorage.upload(
        path,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      return SupabaseService.portfolioStorage.getPublicUrl(path);
    } catch (e) {
      SupabaseService.debugLog('uploadPortfolioImage error', error: e);
      return null;
    }
  }

  /// Update the vendor profile details.
  static Future<bool> updateVendorProfile({
    required String userId,
    String? businessName,
    String? category,
    String? location,
    String? bio,
    List<String>? portfolioUrls,
    String? availabilityStatus,
    List<String>? serviceAreas,
    int? priceRangeMin,
    int? priceRangeMax,
    int? yearsExperience,
  }) async {
    dev.log('[Profile] Updating vendor profile $userId', name: 'BiyerBajar');
    try {
      final map = <String, dynamic>{};
      if (businessName != null)       map['business_name']      = businessName;
      if (category != null)           map['category']           = category;
      if (location != null)           map['location']           = location;
      if (bio != null)                map['bio']                = bio;
      if (portfolioUrls != null)      map['portfolio_urls']     = portfolioUrls;
      if (availabilityStatus != null) map['availability_status'] = availabilityStatus;
      if (serviceAreas != null)       map['service_areas']      = serviceAreas;
      if (priceRangeMin != null)      map['price_range_min']    = priceRangeMin;
      if (priceRangeMax != null)      map['price_range_max']    = priceRangeMax;
      if (yearsExperience != null)    map['years_experience']   = yearsExperience;

      await SupabaseService.vendorProfiles.update(map).eq('user_id', userId);
      await AuthService.loadCurrentUser(); // refresh cache
      return true;
    } catch (e) {
      SupabaseService.debugLog('updateVendorProfile error', error: e);
      return false;
    }
  }

  /// Update basic profile info.
  static Future<bool> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? city,
    String? nidNumber,
  }) async {
    dev.log('[Profile] Updating profile $userId', name: 'BiyerBajar');
    try {
      final map = <String, dynamic>{};
      if (name != null)      map['name']       = name;
      if (phone != null)     map['phone']      = phone;
      if (city != null)      map['city']       = city;
      if (nidNumber != null) map['nid_number'] = nidNumber;

      await SupabaseService.profiles.update(map).eq('id', userId);
      await AuthService.loadCurrentUser();
      return true;
    } catch (e) {
      SupabaseService.debugLog('updateProfile error', error: e);
      return false;
    }
  }

  /// Get a vendor's full profile including vendor_profiles data.
  static Future<AppUser?> getVendorProfile(String vendorId) async {
    try {
      final data = await SupabaseService.profiles
          .select('*, vendor_profiles!vendor_profiles_user_id_fkey(*)')
          .eq('id', vendorId)
          .maybeSingle();
      if (data == null) return null;
      return AppUser.fromMap(data);
    } catch (e) {
      SupabaseService.debugLog('getVendorProfile error', error: e);
      return null;
    }
  }
}
