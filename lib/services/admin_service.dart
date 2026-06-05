import 'dart:developer' as dev;
import '../models/user_model.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

/// Aggregate stats for the admin analytics dashboard.
class PlatformStats {
  final int totalUsers;
  final int totalHosts;
  final int totalVendors;
  final int totalPosts;
  final int openPosts;
  final int bookedPosts;
  final int totalBids;
  final int totalReviews;
  final int verifiedVendors;
  final int premiumVendors;
  final int newUsersToday;
  final int newUsersThisMonth;
  final int bronzeVendors;
  final int silverVendors;
  final int goldVendors;
  final int platinumVendors;
  final int activeSubscriptions;
  final int pendingTransactions;
  final int totalCommissionEarned;

  const PlatformStats({
    this.totalUsers = 0,
    this.totalHosts = 0,
    this.totalVendors = 0,
    this.totalPosts = 0,
    this.openPosts = 0,
    this.bookedPosts = 0,
    this.totalBids = 0,
    this.totalReviews = 0,
    this.verifiedVendors = 0,
    this.premiumVendors = 0,
    this.newUsersToday = 0,
    this.newUsersThisMonth = 0,
    this.bronzeVendors = 0,
    this.silverVendors = 0,
    this.goldVendors = 0,
    this.platinumVendors = 0,
    this.activeSubscriptions = 0,
    this.pendingTransactions = 0,
    this.totalCommissionEarned = 0,
  });
}

class AdminService {
  // ── Analytics ─────────────────────────────────────────────────────────────

  static Future<PlatformStats> getPlatformStats() async {
    dev.log('[Admin] Loading platform stats', name: 'BiyerBajar');

    // Run each query independently — one failure won't zero out everything
    List profiles = [], posts = [], bids = [], reviews = [], vendors = [],
        subs = [], txns = [];

    try { profiles = await SupabaseService.profiles.select('id, role, created_at'); }
    catch (e) { SupabaseService.debugLog('stats profiles error', error: e); }

    try { posts = await SupabaseService.eventPosts.select('id, status'); }
    catch (e) { SupabaseService.debugLog('stats posts error', error: e); }

    try { bids = await SupabaseService.bids.select('id'); }
    catch (e) { SupabaseService.debugLog('stats bids error', error: e); }

    try { reviews = await SupabaseService.reviews.select('id'); }
    catch (e) { SupabaseService.debugLog('stats reviews error', error: e); }

    try { vendors = await SupabaseService.vendorProfiles
        .select('user_id, is_verified, has_premium_badge, badge_tier'); }
    catch (e) { SupabaseService.debugLog('stats vendors error', error: e); }

    try { subs = await SupabaseService.vendorSubscriptions.select('id, status'); }
    catch (e) { SupabaseService.debugLog('stats subs error', error: e); }

    try { txns = await SupabaseService.transactions.select('id, status, commission_amt'); }
    catch (e) {
      // column might still be commission_bdt on some deployments
      try { txns = await SupabaseService.transactions.select('id, status'); }
      catch (_) {}
      SupabaseService.debugLog('stats txns error', error: e);
    }

    final now        = DateTime.now();
    final today      = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    int totalCommission = 0;
    for (final t in txns) {
      if (t['status'] == 'completed') {
        totalCommission += (t['commission_amt'] as int? ?? 0);
      }
    }

    final stats = PlatformStats(
      totalUsers:   profiles.length,
      totalHosts:   profiles.where((p) => p['role'] == 'host').length,
      totalVendors: profiles.where((p) => p['role'] == 'vendor').length,
      totalPosts:   posts.length,
      openPosts:    posts.where((p) => p['status'] == 'open').length,
      bookedPosts:  posts.where((p) => p['status'] == 'booked').length,
      totalBids:    bids.length,
      totalReviews: reviews.length,
      verifiedVendors: vendors.where((v) => v['is_verified'] == true).length,
      premiumVendors:  vendors.where((v) => v['has_premium_badge'] == true).length,
      newUsersToday: profiles.where((p) {
        final d = DateTime.tryParse(p['created_at'] as String? ?? '');
        return d != null && d.isAfter(today);
      }).length,
      newUsersThisMonth: profiles.where((p) {
        final d = DateTime.tryParse(p['created_at'] as String? ?? '');
        return d != null && d.isAfter(monthStart);
      }).length,
      bronzeVendors:   vendors.where((v) => v['badge_tier'] == 'bronze').length,
      silverVendors:   vendors.where((v) => v['badge_tier'] == 'silver').length,
      goldVendors:     vendors.where((v) => v['badge_tier'] == 'gold').length,
      platinumVendors: vendors.where((v) => v['badge_tier'] == 'platinum').length,
      activeSubscriptions:  subs.where((s) => s['status'] == 'active').length,
      pendingTransactions:  txns.where((t) => t['status'] == 'pending').length,
      totalCommissionEarned: totalCommission,
    );

    dev.log('[Admin] Stats — users:${stats.totalUsers} vendors:${stats.totalVendors} '
        'posts:${stats.totalPosts} bids:${stats.totalBids}', name: 'BiyerBajar');
    return stats;
  }

  // ── User Management ───────────────────────────────────────────────────────

  static Future<List<AppUser>> getAllUsers({String? roleFilter}) async {
    dev.log('[Admin] Loading all users role=$roleFilter', name: 'BiyerBajar');
    try {
      var q = SupabaseService.profiles.select('*, vendor_profiles!vendor_profiles_user_id_fkey(*)');
      if (roleFilter != null) q = q.eq('role', roleFilter);
      final data = await q.order('created_at', ascending: false).limit(200);
      return (data as List).map((d) => AppUser.fromMap(d)).toList();
    } catch (e) {
      SupabaseService.debugLog('getAllUsers error', error: e);
      return [];
    }
  }

  static Future<bool> toggleUserActive(String userId, bool isActive) async {
    dev.log('[Admin] user $userId active=$isActive', name: 'BiyerBajar');
    try {
      await SupabaseService.profiles
          .update({'is_active': isActive}).eq('id', userId);
      return true;
    } catch (e) {
      SupabaseService.debugLog('toggleUserActive error', error: e);
      return false;
    }
  }

  // ── Vendor Management ─────────────────────────────────────────────────────

  static Future<bool> verifyVendor(String vendorId, bool verified) async {
    dev.log('[Admin] vendor $vendorId verified=$verified', name: 'BiyerBajar');
    try {
      await SupabaseService.vendorProfiles
          .update({'is_verified': verified}).eq('user_id', vendorId);
      return true;
    } catch (e) {
      SupabaseService.debugLog('verifyVendor error', error: e);
      return false;
    }
  }

  static Future<bool> grantPremiumBadge(String vendorId, bool grant) async {
    dev.log('[Admin] vendor $vendorId premium=$grant', name: 'BiyerBajar');
    try {
      await SupabaseService.vendorProfiles
          .update({'has_premium_badge': grant}).eq('user_id', vendorId);
      return true;
    } catch (e) {
      SupabaseService.debugLog('grantPremiumBadge error', error: e);
      return false;
    }
  }

  static Future<bool> overrideBadgeTier(String vendorId, String tier) async {
    dev.log('[Admin] vendor $vendorId badge_tier → $tier', name: 'BiyerBajar');
    try {
      await SupabaseService.vendorProfiles
          .update({'badge_tier': tier}).eq('user_id', vendorId);
      return true;
    } catch (e) {
      SupabaseService.debugLog('overrideBadgeTier error', error: e);
      return false;
    }
  }

  // ── Junior Admin Management ───────────────────────────────────────────────

  static Future<String?> addJuniorAdmin(String email) async {
    dev.log('[Admin] Adding junior admin: $email', name: 'BiyerBajar');
    try {
      final data = await SupabaseService.profiles
          .select('id, role').eq('email', email.trim()).maybeSingle();
      if (data == null) return 'No account found with that email.';
      if (data['role'] == 'admin') return 'This user is already an admin.';

      final userId     = data['id'] as String;
      final mainAdminId = AuthService.currentUser?.id ?? '';

      await SupabaseService.profiles
          .update({'role': 'admin'}).eq('id', userId);
      await SupabaseService.adminAccounts.insert({
        'user_id': userId,
        'added_by': mainAdminId,
      });
      dev.log('[Admin] Junior admin added: $userId', name: 'BiyerBajar');
      return null; // null = success
    } catch (e) {
      SupabaseService.debugLog('addJuniorAdmin error', error: e);
      return 'Failed to add admin. Please try again.';
    }
  }

  static Future<bool> removeJuniorAdmin(String userId) async {
    dev.log('[Admin] Removing junior admin: $userId', name: 'BiyerBajar');
    try {
      await SupabaseService.profiles
          .update({'role': 'host'}).eq('id', userId);
      await SupabaseService.adminAccounts.delete().eq('user_id', userId);
      return true;
    } catch (e) {
      SupabaseService.debugLog('removeJuniorAdmin error', error: e);
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getJuniorAdmins() async {
    try {
      final data = await SupabaseService.adminAccounts
          .select('user_id, added_by, created_at, profiles!user_id(name, email, phone)')
          .order('created_at', ascending: false);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      SupabaseService.debugLog('getJuniorAdmins error', error: e);
      return [];
    }
  }

  // ── Transaction Management ────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllTransactions({
    String? statusFilter,
  }) async {
    dev.log('[Admin] Loading transactions status=$statusFilter', name: 'BiyerBajar');
    try {
      var q = SupabaseService.transactions.select('*');
      if (statusFilter != null) q = q.eq('status', statusFilter);
      final data = await q.order('created_at', ascending: false).limit(100);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      SupabaseService.debugLog('getAllTransactions error', error: e);
      return [];
    }
  }

  static Future<bool> updateTransactionStatus(
      String txId, String status, {String? paymentRef}) async {
    dev.log('[Admin] Transaction $txId → $status', name: 'BiyerBajar');
    try {
      final update = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (paymentRef != null) update['payment_ref'] = paymentRef;

      // If completing, compute commission
      if (status == 'completed') {
        final tx = await SupabaseService.transactions
            .select('amount, commission_rate').eq('id', txId).single();
        final amount = (tx['amount'] as int? ?? 0);
        final rate   = (tx['commission_rate'] as num?)?.toDouble() ?? 5.0;
        update['commission_amt'] = (amount * rate / 100).round();
        dev.log('[Admin] Commission: ৳${update['commission_amt']}', name: 'BiyerBajar');
      }

      await SupabaseService.transactions.update(update).eq('id', txId);
      return true;
    } catch (e) {
      SupabaseService.debugLog('updateTransactionStatus error', error: e);
      return false;
    }
  }

  // ── Subscription Management ───────────────────────────────────────────────

  static Future<bool> grantSubscription(String vendorId, String plan) async {
    dev.log('[Admin] Granting $plan subscription to $vendorId', name: 'BiyerBajar');
    try {
      final now     = DateTime.now();
      final expires = plan == 'annual'
          ? now.add(const Duration(days: 365))
          : now.add(const Duration(days: 30));

      await SupabaseService.client.from('vendor_subscriptions').insert({
        'vendor_id':      vendorId,
        'plan':           plan,
        'price_paid':     plan == 'annual' ? 5000 : 500,
        'status':         'active',
        'starts_at':      now.toIso8601String(),
        'expires_at':     expires.toIso8601String(),
        'payment_method': 'admin_grant',
      });
      await SupabaseService.vendorProfiles
          .update({'subscription_tier': 'premium'}).eq('user_id', vendorId);
      dev.log('[Admin] Subscription granted until ${expires.toLocal()}', name: 'BiyerBajar');
      return true;
    } catch (e) {
      SupabaseService.debugLog('grantSubscription error', error: e);
      return false;
    }
  }

  static Future<bool> revokeSubscription(String vendorId) async {
    dev.log('[Admin] Revoking subscription for $vendorId', name: 'BiyerBajar');
    try {
      await SupabaseService.client
          .from('vendor_subscriptions')
          .update({'status': 'cancelled'}).eq('vendor_id', vendorId);
      await SupabaseService.vendorProfiles
          .update({'subscription_tier': 'free'}).eq('user_id', vendorId);
      return true;
    } catch (e) {
      SupabaseService.debugLog('revokeSubscription error', error: e);
      return false;
    }
  }

  // ── Post Management ───────────────────────────────────────────────────────

  static Future<bool> deletePost(String postId) async {
    dev.log('[Admin] Deleting post $postId', name: 'BiyerBajar');
    try {
      await SupabaseService.eventPosts.delete().eq('id', postId);
      return true;
    } catch (e) {
      SupabaseService.debugLog('deletePost error', error: e);
      return false;
    }
  }
}
