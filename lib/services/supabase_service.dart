import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

/// Central Supabase client wrapper.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      debug: false,
    );
    dev.log('[Supabase] Initialized — project: tqmyqwjrsypkibaryrkb', name: 'BiyerBajar');
  }

  // ── Auth shortcuts ────────────────────────────────────────────────────────
  static User?    get currentAuthUser => client.auth.currentUser;
  static Session? get currentSession  => client.auth.currentSession;
  static bool     get isLoggedIn      => currentAuthUser != null;
  static String?  get currentUserId   => currentAuthUser?.id;

  // ── DB table shortcuts ────────────────────────────────────────────────────
  static SupabaseQueryBuilder get profiles            => client.from('profiles');
  static SupabaseQueryBuilder get vendorProfiles      => client.from('vendor_profiles');
  static SupabaseQueryBuilder get eventPosts          => client.from('event_posts');
  static SupabaseQueryBuilder get bids                => client.from('bids');
  static SupabaseQueryBuilder get reviews             => client.from('reviews');
  static SupabaseQueryBuilder get budgetPlans         => client.from('budget_plans');
  static SupabaseQueryBuilder get settings            => client.from('platform_settings');
  static SupabaseQueryBuilder get adminAccounts       => client.from('admin_accounts');
  static SupabaseQueryBuilder get transactions        => client.from('transactions');
  static SupabaseQueryBuilder get vendorSubscriptions => client.from('vendor_subscriptions');

  // ── v2 tables ──────────────────────────────────────────────────────────────
  static SupabaseQueryBuilder get vendorPackages      => client.from('vendor_packages');
  static SupabaseQueryBuilder get vendorMenus         => client.from('vendor_menus');
  static SupabaseQueryBuilder get vendorDiscounts     => client.from('vendor_discounts');
  static SupabaseQueryBuilder get chatConversations   => client.from('chat_conversations');
  static SupabaseQueryBuilder get chatMessages        => client.from('chat_messages');
  static SupabaseQueryBuilder get bookings            => client.from('bookings');
  static SupabaseQueryBuilder get bookingPayments     => client.from('booking_payments');

  // ── Storage shortcuts ─────────────────────────────────────────────────────
  static StorageFileApi get avatarStorage    => client.storage.from(SupabaseConfig.avatarsBucket);
  static StorageFileApi get portfolioStorage => client.storage.from(SupabaseConfig.portfoliosBucket);

  // ── Realtime ──────────────────────────────────────────────────────────────
  static RealtimeChannel subscribeToBids(String postId, void Function(dynamic) onEvent) {
    return client
        .channel('bids:$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bids',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'post_id', value: postId),
          callback: (payload) {
            dev.log('[Realtime] New bid on post $postId', name: 'BiyerBajar');
            onEvent(payload);
          },
        )
        .subscribe();
  }

  // ── Debug helper ──────────────────────────────────────────────────────────
  static void debugLog(String msg, {Object? error}) {
    if (error != null) {
      dev.log('[BiyerBajar] $msg | ERROR: $error', name: 'BiyerBajar', error: error);
    } else {
      dev.log('[BiyerBajar] $msg', name: 'BiyerBajar');
    }
  }
}
