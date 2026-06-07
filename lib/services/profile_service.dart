import 'dart:developer' as dev;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class ProfileService {
  /// Upload a profile picture and return the public URL.
  /// Uses XFile (web + mobile compatible) — no dart:io needed.
  static Future<String?> uploadAvatar(XFile imageFile, String userId) async {
    dev.log('[Profile] Uploading avatar for $userId', name: 'BiyerBajar');
    try {
      final path = '$userId/avatar.jpg';
      final bytes = await imageFile.readAsBytes();

      await SupabaseService.avatarStorage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );

      final url = SupabaseService.avatarStorage.getPublicUrl(path);
      dev.log('[Profile] Avatar uploaded: $url', name: 'BiyerBajar');

      await SupabaseService.profiles
          .update({'profile_picture_url': url}).eq('id', userId);

      return url;
    } catch (e) {
      SupabaseService.debugLog('uploadAvatar error', error: e);
      return null;
    }
  }

  /// Upload a portfolio image with compression and return the public URL.
  /// Uses XFile (web + mobile compatible) and uploadBinary — no dart:io needed.
  static Future<String?> uploadPortfolioImage(XFile imageFile, String vendorId) async {
    dev.log('[Profile] Uploading portfolio image for $vendorId', name: 'BiyerBajar');
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$vendorId/portfolio_$timestamp.jpg';
      final bytes = await imageFile.readAsBytes();

      await SupabaseService.portfolioStorage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );

      return SupabaseService.portfolioStorage.getPublicUrl(path);
    } catch (e) {
      SupabaseService.debugLog('uploadPortfolioImage error', error: e);
      return null;
    }
  }

  /// Persist the full portfolio URL list to the DB.
  static Future<bool> savePortfolioUrls(String vendorId, List<String> urls) async {
    try {
      await SupabaseService.vendorProfiles
          .update({'portfolio_urls': urls})
          .eq('user_id', vendorId);
      await AuthService.loadCurrentUser();
      return true;
    } catch (e) {
      SupabaseService.debugLog('savePortfolioUrls error', error: e);
      return false;
    }
  }

  /// Delete a portfolio image from storage and remove its URL from the DB.
  static Future<bool> deletePortfolioImage(String vendorId, String url, List<String> currentUrls) async {
    try {
      // Extract the storage path from the public URL
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // Path is everything after '/object/public/<bucket>/'
      final bucketIndex = segments.indexOf('portfolio');
      if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
        final storagePath = segments.sublist(bucketIndex + 1).join('/');
        await SupabaseService.portfolioStorage.remove([storagePath]);
      }
      final updated = currentUrls.where((u) => u != url).toList();
      return savePortfolioUrls(vendorId, updated);
    } catch (e) {
      SupabaseService.debugLog('deletePortfolioImage error', error: e);
      return false;
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
