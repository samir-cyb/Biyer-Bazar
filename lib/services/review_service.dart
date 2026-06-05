import 'dart:developer' as dev;
import 'supabase_service.dart';

class ReviewModel {
  final String id;
  final String postId;
  final String hostId;
  final String vendorId;
  final String vendorName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.postId,
    required this.hostId,
    required this.vendorId,
    required this.vendorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<dynamic, dynamic> m) => ReviewModel(
    id:         m['id'] as String,
    postId:     m['post_id'] as String,
    hostId:     m['host_id'] as String,
    vendorId:   m['vendor_id'] as String,
    vendorName: (m['vendor_name'] as String?) ?? '',
    rating:     (m['rating'] as int?) ?? 5,
    comment:    (m['comment'] as String?) ?? '',
    createdAt:  DateTime.parse(m['created_at'] as String),
  );
}

class ReviewService {
  /// Submit a post-wedding review from host to vendor.
  static Future<bool> submitReview({
    required String postId,
    required String hostId,
    required String vendorId,
    required int rating,
    required String comment,
  }) async {
    dev.log('[ReviewService] Host $hostId rating vendor $vendorId: $rating★', name: 'BiyerBajar');
    try {
      await SupabaseService.reviews.insert({
        'post_id':   postId,
        'host_id':   hostId,
        'vendor_id': vendorId,
        'rating':    rating,
        'comment':   comment,
        'is_public': true,
      });
      // The Supabase trigger refresh_vendor_rating() will auto-update vendor's avg rating & badge
      dev.log('[ReviewService] Review submitted — Supabase trigger will update vendor badge', name: 'BiyerBajar');
      return true;
    } catch (e) {
      SupabaseService.debugLog('submitReview error', error: e);
      return false;
    }
  }

  /// Get all reviews for a vendor.
  static Future<List<ReviewModel>> getVendorReviews(String vendorId) async {
    try {
      final data = await SupabaseService.reviews
          .select()
          .eq('vendor_id', vendorId)
          .eq('is_public', true)
          .order('created_at', ascending: false);
      return (data as List).map((d) => ReviewModel.fromMap(d)).toList();
    } catch (e) {
      SupabaseService.debugLog('getVendorReviews error', error: e);
      return [];
    }
  }

  /// Check if a host already reviewed a vendor for a given post.
  static Future<bool> hasReviewed(String postId, String hostId, String vendorId) async {
    try {
      final res = await SupabaseService.reviews
          .select('id')
          .eq('post_id', postId)
          .eq('host_id', hostId)
          .eq('vendor_id', vendorId)
          .limit(1);
      return (res as List).isNotEmpty;
    } catch (e) {
      SupabaseService.debugLog('hasReviewed error', error: e);
      return false;
    }
  }
}
