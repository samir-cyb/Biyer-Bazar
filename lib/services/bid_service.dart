import 'package:uuid/uuid.dart';
import '../models/bid_model.dart';
import '../models/user_model.dart';
import '../logic/slot_filter_logic.dart';
import 'hive_service.dart';

class BidService {
  static const _uuid = Uuid();

  static bool canVendorBid(String vendorId, String postId) =>
      !HiveService.hasVendorBidOnPost(vendorId, postId);

  /// Submits a blind bid. Returns null if vendor already bid on this post.
  static Bid? submitBid({
    required AppUser vendor,
    required String postId,
    required int quotedPrice,
    required String packageDescription,
    required List<String> includedServices,
  }) {
    if (!canVendorBid(vendor.id, postId)) return null;

    final bid = Bid(
      id: _uuid.v4(),
      postId: postId,
      vendorId: vendor.id,
      vendorName: vendor.name,
      vendorBusinessName: vendor.businessName ?? vendor.name,
      vendorCategory: vendor.vendorCategory ?? 'General',
      vendorLocation: vendor.location ?? 'Dhaka',
      vendorRating: vendor.rating,
      vendorTotalBookings: vendor.totalBookings,
      vendorDaysOnPlatform: vendor.daysOnPlatform,
      vendorIsVerified: vendor.isVerified,
      quotedPrice: quotedPrice,
      packageDescription: packageDescription,
      includedServices: includedServices,
      submittedAt: DateTime.now(),
    );
    HiveService.saveBid(bid);
    return bid;
  }

  static List<Bid> getMyBids(String vendorId) =>
      HiveService.getBidsByVendor(vendorId);

  /// Returns 7 curated bids for a post using the slot filter algorithm.
  /// Prices are always visible to the host (not blinded).
  static List<Bid> getCuratedBidsForHost(String postId, String hostLocation) {
    final allBids = HiveService.getBidsForPost(postId);
    return SlotFilterLogic.applySevenSlotFilterOnBids(
      bids: allBids,
      requestedLocation: hostLocation,
    );
  }

  /// Returns bids visible to the requesting vendor:
  /// their own bid is full; all others are blinded (no price/name).
  static List<Bid> getBidsVisibleToVendor(
      String postId, String requestingVendorId) {
    return HiveService.getBidsForPost(postId).map((b) {
      if (b.vendorId == requestingVendorId) return b;
      return b.blinded;
    }).toList();
  }
}
