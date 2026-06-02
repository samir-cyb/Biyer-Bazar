import '../models/vendor_model.dart';
import '../models/bid_model.dart';

/// Core 7-Slot Blind Reverse-Bidding Algorithm
class SlotFilterLogic {
  // ── Old VendorBid-based filter (used by mock data / demo) ───────────────────

  static List<VendorBid> applySevenSlotFilter({
    required List<VendorBid> pool,
    required String requestedLocation,
  }) {
    final premium = <VendorBid>[];
    final verified = <VendorBid>[];
    final fresh = <VendorBid>[];

    for (final bid in pool) {
      final v = bid.vendor;
      if (v.totalBookings < 5 || v.daysOnPlatform < 60) {
        fresh.add(bid);
      } else if (v.rating >= 4.5 && v.totalBookings >= 20) {
        premium.add(bid);
      } else if (v.rating >= 4.0) {
        verified.add(bid);
      }
    }

    premium.sort((a, b) => _scoreV(b).compareTo(_scoreV(a)));
    verified.sort((a, b) => b.vendor.rating.compareTo(a.vendor.rating));
    fresh.sort((a, b) {
      final aLocal = a.vendor.location == requestedLocation ? 0 : 1;
      final bLocal = b.vendor.location == requestedLocation ? 0 : 1;
      if (aLocal != bLocal) return aLocal.compareTo(bLocal);
      return a.vendor.daysOnPlatform.compareTo(b.vendor.daysOnPlatform);
    });

    return _buildSlots(
      premiumList: premium,
      verifiedList: verified,
      freshList: fresh,
      pool: pool,
    );
  }

  static double _scoreV(VendorBid bid) {
    final v = bid.vendor;
    return v.rating * 0.6 + (v.totalBookings / 100).clamp(0.0, 1.0) * 0.4;
  }

  // ── New Bid-based filter (used with real Hive data) ──────────────────────────

  static List<Bid> applySevenSlotFilterOnBids({
    required List<Bid> bids,
    required String requestedLocation,
  }) {
    final premium = <Bid>[];
    final verified = <Bid>[];
    final fresh = <Bid>[];

    for (final bid in bids) {
      if (bid.vendorTotalBookings < 5 || bid.vendorDaysOnPlatform < 60) {
        fresh.add(bid);
      } else if (bid.vendorRating >= 4.5 && bid.vendorTotalBookings >= 20) {
        premium.add(bid);
      } else {
        verified.add(bid);
      }
    }

    premium.sort((a, b) => _scoreB(b).compareTo(_scoreB(a)));
    verified.sort((a, b) => b.vendorRating.compareTo(a.vendorRating));
    fresh.sort((a, b) {
      final aLocal = a.vendorLocation == requestedLocation ? 0 : 1;
      final bLocal = b.vendorLocation == requestedLocation ? 0 : 1;
      if (aLocal != bLocal) return aLocal.compareTo(bLocal);
      return a.vendorDaysOnPlatform.compareTo(b.vendorDaysOnPlatform);
    });

    final result = <Bid>[];

    // Slots 1–2: Premium (up to 2, backfill from verified)
    final premiumSlice = premium.take(2).toList();
    result.addAll(premiumSlice);
    if (result.length < 2) {
      final backfill = verified.take(2 - result.length).toList();
      result.addAll(backfill);
      verified.removeWhere((b) => backfill.contains(b));
    }

    // Slots 3–5: Verified (up to 3)
    final remainingVerified = verified
        .where((b) => !result.any((r) => r.id == b.id))
        .take(3)
        .toList();
    result.addAll(remainingVerified);
    if (result.length < 5) {
      result.addAll(premium.skip(2).take(5 - result.length));
    }

    // Slots 6–7: Fresh Talent (exactly 2)
    result.addAll(fresh.take(2));

    // Backfill if pool is thin
    if (result.length < 7) {
      final ids = result.map((b) => b.id).toSet();
      result.addAll(bids.where((b) => !ids.contains(b.id)).take(7 - result.length));
    }

    return result.take(7).toList();
  }

  static double _scoreB(Bid bid) =>
      bid.vendorRating * 0.6 +
      (bid.vendorTotalBookings / 100).clamp(0.0, 1.0) * 0.4;

  // ── Internal ──────────────────────────────────────────────────────────────

  static List<VendorBid> _buildSlots({
    required List<VendorBid> premiumList,
    required List<VendorBid> verifiedList,
    required List<VendorBid> freshList,
    required List<VendorBid> pool,
  }) {
    final result = <VendorBid>[];
    result.addAll(premiumList.take(2));
    if (result.length < 2) {
      final backfill = verifiedList.take(2 - result.length).toList();
      result.addAll(backfill);
      verifiedList.removeWhere((b) => backfill.contains(b));
    }
    result.addAll(verifiedList.take(3));
    if (result.length < 5) {
      result.addAll(premiumList.skip(2).take(5 - result.length));
    }
    result.addAll(freshList.take(2));
    if (result.length < 7) {
      final ids = result.map((b) => b.bidId).toSet();
      result.addAll(pool.where((b) => !ids.contains(b.bidId)).take(7 - result.length));
    }
    return result.take(7).toList();
  }
}
