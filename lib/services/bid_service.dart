import 'dart:developer' as dev;
import '../models/bid_model.dart';
import '../models/user_model.dart';
import '../logic/slot_filter_logic.dart';
import 'supabase_service.dart';

class BidService {
  static Future<bool> canVendorBid(String vendorId, String postId) async {
    dev.log('[BidService] Checking if vendor $vendorId can bid on $postId', name: 'BiyerBajar');
    try {
      final res = await SupabaseService.bids
          .select('id')
          .eq('post_id', postId)
          .eq('vendor_id', vendorId)
          .limit(1);
      final canBid = (res as List).isEmpty;
      dev.log('[BidService] canVendorBid=$canBid', name: 'BiyerBajar');
      return canBid;
    } catch (e) {
      SupabaseService.debugLog('canVendorBid error', error: e);
      return true; // allow on error
    }
  }

  static Future<Bid?> submitBid({
    required AppUser vendor,
    required String postId,
    required int quotedPrice,
    required String packageDescription,
    required List<String> includedServices,
  }) async {
    dev.log('[BidService] Vendor ${vendor.displayName} bidding on post $postId', name: 'BiyerBajar');
    try {
      final data = await SupabaseService.bids.insert({
        'post_id': postId,
        'vendor_id': vendor.id,
        'vendor_business_name': vendor.businessName ?? vendor.name,
        'vendor_category': vendor.vendorCategory ?? 'General',
        'vendor_location': vendor.location ?? 'Dhaka',
        'vendor_rating': vendor.rating,
        'vendor_total_bookings': vendor.totalBookings,
        'vendor_days_on_platform': vendor.daysOnPlatform,
        'vendor_is_verified': vendor.isVerified,
        'has_premium_badge': vendor.hasPremiumBadge,
        'quoted_price': quotedPrice,
        'package_description': packageDescription,
        'included_services': includedServices,
        'status': 'pending',
      }).select().single();
      return Bid.fromMap(data);
    } catch (e) {
      SupabaseService.debugLog('submitBid error', error: e);
      return null;
    }
  }

  static Future<List<Bid>> getMyBids(String vendorId) async {
    try {
      final data = await SupabaseService.bids
          .select()
          .eq('vendor_id', vendorId)
          .order('submitted_at', ascending: false);
      return (data as List).map((d) => Bid.fromMap(d)).toList();
    } catch (e) {
      SupabaseService.debugLog('getMyBids error', error: e);
      return [];
    }
  }

  /// Returns 7-slot curated bids for a host viewing a post.
  static Future<List<Bid>> getCuratedBidsForHost(String postId, String location) async {
    try {
      final data = await SupabaseService.bids
          .select()
          .eq('post_id', postId)
          .order('submitted_at', ascending: false);
      final all = (data as List).map((d) => Bid.fromMap(d)).toList();
      return SlotFilterLogic.applySevenSlotFilterOnBids(
          bids: all, requestedLocation: location);
    } catch (e) {
      SupabaseService.debugLog('getCuratedBidsForHost error', error: e);
      return [];
    }
  }

  // Admin: get all bids
  static Future<List<Bid>> getAllBids() async {
    try {
      final data = await SupabaseService.bids
          .select()
          .order('submitted_at', ascending: false);
      return (data as List).map((d) => Bid.fromMap(d)).toList();
    } catch (e) {
      SupabaseService.debugLog('getAllBids error', error: e);
      return [];
    }
  }
}
