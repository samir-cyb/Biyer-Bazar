import 'dart:developer' as dev;
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class PostService {
  static Future<EventPost?> createPost({
    required AppUser host,
    required String location,
    required DateTime eventDate,
    required int guestCapacity,
    required String serviceCategory,
    required int budgetCeiling,
    required String description,
    String? budgetPlanId,
  }) async {
    dev.log('[PostService] Creating post: $serviceCategory for ${host.name}', name: 'BiyerBajar');
    try {
      final data = await SupabaseService.eventPosts.insert({
        'host_id': host.id,
        'host_name': host.name,
        'host_phone': host.phone,
        'location': location,
        'event_date': eventDate.toIso8601String().substring(0, 10),
        'guest_capacity': guestCapacity,
        'service_category': serviceCategory,
        'budget_ceiling': budgetCeiling,
        'description': description,
        'budget_plan_id': budgetPlanId,
        'status': 'open',
      }).select().single();
      return EventPost.fromMap(data);
    } catch (e) {
      SupabaseService.debugLog('createPost error', error: e);
      return null;
    }
  }

  static Future<List<EventPost>> getMyPosts(String hostId) async {
    try {
      final data = await SupabaseService.eventPosts
          .select()
          .eq('host_id', hostId)
          .order('created_at', ascending: false);
      return (data as List).map((d) => EventPost.fromMap(d)).toList();
    } catch (e) {
      SupabaseService.debugLog('getMyPosts error', error: e);
      return [];
    }
  }

  static Future<List<EventPost>> getOpenPosts({String? categoryFilter, String? locationFilter}) async {
    try {
      var query = SupabaseService.eventPosts.select().eq('status', 'open');
      if (categoryFilter != null && categoryFilter != 'All') {
        query = query.eq('service_category', categoryFilter);
      }
      if (locationFilter != null && locationFilter != 'All') {
        query = query.eq('location', locationFilter);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((d) => EventPost.fromMap(d)).toList();
    } catch (e) {
      SupabaseService.debugLog('getOpenPosts error', error: e);
      return [];
    }
  }

  static Future<void> acceptBid(String postId, String bidId) async {
    dev.log('[PostService] Accept bid $bidId on post $postId', name: 'BiyerBajar');
    try {
      await SupabaseService.bids.update({'status': 'accepted'}).eq('id', bidId);
      // Reject all other bids
      await SupabaseService.bids
          .update({'status': 'rejected'})
          .eq('post_id', postId)
          .neq('id', bidId);
      // Update post status
      await SupabaseService.eventPosts
          .update({'status': 'booked', 'selected_bid_id': bidId}).eq('id', postId);
    } catch (e) {
      SupabaseService.debugLog('acceptBid error', error: e);
    }
  }

  static Future<void> cancelPost(String postId) async {
    try {
      await SupabaseService.eventPosts.update({'status': 'cancelled'}).eq('id', postId);
    } catch (e) {
      SupabaseService.debugLog('cancelPost error', error: e);
    }
  }

  static Future<int> getBidCount(String postId) async {
    try {
      final res = await SupabaseService.bids
          .select('id')
          .eq('post_id', postId);
      return (res as List).length;
    } catch (e) {
      SupabaseService.debugLog('getBidCount error', error: e);
      return 0;
    }
  }

  // Admin: get all posts
  static Future<List<EventPost>> getAllPosts() async {
    try {
      final data = await SupabaseService.eventPosts
          .select()
          .order('created_at', ascending: false);
      return (data as List).map((d) => EventPost.fromMap(d)).toList();
    } catch (e) {
      SupabaseService.debugLog('getAllPosts error', error: e);
      return [];
    }
  }
}
