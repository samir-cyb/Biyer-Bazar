import 'dart:developer' as dev;
import 'supabase_service.dart';

/// Cached platform settings loaded from Supabase `platform_settings` table.
/// Admin can update any value; all clients read from this single source of truth.
class PlatformSettings {
  // ── Subscription / Bid Ticket ─────────────────────────────────────────────
  final bool subscriptionEnabled;   // master toggle (admin controls)
  final int  freeBidLimit;          // bids/month when subscription ON (default 3)
  final int  subscriptionPriceMonthly; // BDT
  final int  subscriptionPriceAnnual;  // BDT

  // ── Premium Badge ─────────────────────────────────────────────────────────
  final bool premiumBadgeEnabled;
  final int  premiumBadgePrice; // BDT/month

  // ── Escrow / Commission ───────────────────────────────────────────────────
  final bool escrowEnabled;
  final double commissionRate;   // percentage, e.g. 5.0
  final int  bookingDepositAmount; // BDT

  // ── App-level ─────────────────────────────────────────────────────────────
  final bool maintenanceMode;
  final int  maxBidsPerPost;

  const PlatformSettings({
    this.subscriptionEnabled    = false,
    this.freeBidLimit           = 3,
    this.subscriptionPriceMonthly = 500,
    this.subscriptionPriceAnnual  = 5000,
    this.premiumBadgeEnabled    = true,
    this.premiumBadgePrice      = 1000,
    this.escrowEnabled          = false,
    this.commissionRate         = 5.0,
    this.bookingDepositAmount   = 10000,
    this.maintenanceMode        = false,
    this.maxBidsPerPost         = 7,
  });

  factory PlatformSettings.fromMap(Map<String, dynamic> map) {
    T v<T>(String key, T fallback) {
      final raw = map[key];
      if (raw == null) return fallback;
      if (raw is T) return raw;
      if (raw is Map && raw.containsKey('value')) {
        final inner = raw['value'];
        if (inner is T) return inner;
      }
      return fallback;
    }

    return PlatformSettings(
      subscriptionEnabled:       v('subscription_enabled', false),
      freeBidLimit:              v('free_bid_limit', 3),
      subscriptionPriceMonthly:  v('subscription_price_monthly', 500),
      subscriptionPriceAnnual:   v('subscription_price_annual', 5000),
      premiumBadgeEnabled:       v('premium_badge_enabled', true),
      premiumBadgePrice:         v('premium_badge_price', 1000),
      escrowEnabled:             v('escrow_enabled', false),
      commissionRate:            (v('commission_rate', 5.0) as num).toDouble(),
      bookingDepositAmount:      v('booking_deposit_amount', 10000),
      maintenanceMode:           v('maintenance_mode', false),
      maxBidsPerPost:            v('max_bids_per_post', 7),
    );
  }
}

class PlatformSettingsService {
  static PlatformSettings _cached = const PlatformSettings();
  static PlatformSettings get current => _cached;

  /// Load all settings from Supabase. Call once at app start.
  static Future<void> load() async {
    dev.log('[Settings] Loading platform settings', name: 'BiyerBajar');
    try {
      final rows = await SupabaseService.settings.select('key, value');
      final map = <String, dynamic>{};
      for (final row in rows as List) {
        final key = row['key'] as String;
        final val = row['value'];
        // jsonb values come as their native Dart type
        map[key] = val;
      }
      _cached = PlatformSettings.fromMap(map);
      dev.log(
        '[Settings] Loaded — subscription:${_cached.subscriptionEnabled} '
        'freeBids:${_cached.freeBidLimit} premium:${_cached.premiumBadgeEnabled} '
        'escrow:${_cached.escrowEnabled}',
        name: 'BiyerBajar',
      );
    } catch (e) {
      SupabaseService.debugLog('PlatformSettingsService.load error', error: e);
      // Use defaults if DB unavailable
    }
  }

  /// Update a single setting (admin only).
  static Future<bool> update(String key, dynamic value) async {
    dev.log('[Settings] Admin updating $key → $value', name: 'BiyerBajar');
    try {
      await SupabaseService.settings
          .upsert({'key': key, 'value': value, 'updated_at': DateTime.now().toIso8601String()});
      await load(); // refresh cache
      dev.log('[Settings] $key updated successfully', name: 'BiyerBajar');
      return true;
    } catch (e) {
      SupabaseService.debugLog('PlatformSettingsService.update error', error: e);
      return false;
    }
  }

  /// Bulk update multiple settings at once (admin).
  static Future<bool> updateAll(Map<String, dynamic> updates) async {
    dev.log('[Settings] Admin bulk update: ${updates.keys.join(', ')}', name: 'BiyerBajar');
    try {
      for (final entry in updates.entries) {
        await SupabaseService.settings.upsert({
          'key': entry.key,
          'value': entry.value,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      await load();
      return true;
    } catch (e) {
      SupabaseService.debugLog('PlatformSettingsService.updateAll error', error: e);
      return false;
    }
  }

  // ── Convenience getters for bid logic ────────────────────────────────────

  /// Whether a vendor can submit a bid without a subscription.
  /// When subscription is OFF → always true (unlimited free bids).
  /// When subscription is ON → check free bid count.
  static bool canVendorBidFree(int freeBidsUsedThisMonth) {
    if (!_cached.subscriptionEnabled) {
      dev.log('[BidTicket] Subscription OFF → unlimited bids', name: 'BiyerBajar');
      return true;
    }
    final canBid = freeBidsUsedThisMonth < _cached.freeBidLimit;
    dev.log('[BidTicket] Subscription ON → used $freeBidsUsedThisMonth/${_cached.freeBidLimit} → canBid=$canBid',
        name: 'BiyerBajar');
    return canBid;
  }

  static int get remainingFreeBids => _cached.freeBidLimit;
}
