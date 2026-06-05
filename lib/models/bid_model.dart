enum BidStatus { pending, accepted, rejected }

extension BidStatusLabel on BidStatus {
  String get label {
    switch (this) {
      case BidStatus.pending:  return 'Pending';
      case BidStatus.accepted: return 'Accepted';
      case BidStatus.rejected: return 'Rejected';
    }
  }
  String get emoji {
    switch (this) {
      case BidStatus.pending:  return '⏳';
      case BidStatus.accepted: return '✅';
      case BidStatus.rejected: return '❌';
    }
  }
}

class Bid {
  final String id;
  final String postId;
  final String vendorId;
  final String vendorBusinessName;
  final String vendorCategory;
  final String vendorLocation;
  final double vendorRating;
  final int vendorTotalBookings;
  final int vendorDaysOnPlatform;
  final bool vendorIsVerified;
  final bool hasPremiumBadge;
  final String vendorBadgeTier;
  final int quotedPrice;
  final String packageDescription;
  final List<String> includedServices;
  final DateTime submittedAt;
  final BidStatus status;

  Bid({
    required this.id,
    required this.postId,
    required this.vendorId,
    required this.vendorBusinessName,
    required this.vendorCategory,
    required this.vendorLocation,
    required this.vendorRating,
    required this.vendorTotalBookings,
    required this.vendorDaysOnPlatform,
    required this.vendorIsVerified,
    this.hasPremiumBadge = false,
    this.vendorBadgeTier = 'bronze',
    required this.quotedPrice,
    required this.packageDescription,
    required this.includedServices,
    required this.submittedAt,
    this.status = BidStatus.pending,
  });

  factory Bid.fromMap(Map<dynamic, dynamic> m) => Bid(
    id:                     m['id'] as String,
    postId:                 m['post_id'] as String,
    vendorId:               m['vendor_id'] as String,
    vendorBusinessName:     m['vendor_business_name'] as String? ?? '',
    vendorCategory:         m['vendor_category'] as String? ?? '',
    vendorLocation:         m['vendor_location'] as String? ?? '',
    vendorRating:           (m['vendor_rating'] as num?)?.toDouble() ?? 5.0,
    vendorTotalBookings:    (m['vendor_total_bookings'] as int?) ?? 0,
    vendorDaysOnPlatform:   (m['vendor_days_on_platform'] as int?) ?? 1,
    vendorIsVerified:       (m['vendor_is_verified'] as bool?) ?? false,
    hasPremiumBadge:        (m['has_premium_badge'] as bool?) ?? false,
    vendorBadgeTier:        (m['vendor_badge_tier'] as String?) ?? 'bronze',
    quotedPrice:            (m['quoted_price'] as int?) ?? 0,
    packageDescription:     m['package_description'] as String? ?? '',
    includedServices:       _parseList(m['included_services']),
    submittedAt:            DateTime.tryParse(m['submitted_at'] as String? ?? '') ?? DateTime.now(),
    status:                 _parseStatus(m['status'] as String?),
  );

  Bid get blinded => Bid(
    id: id, postId: postId, vendorId: vendorId,
    vendorBusinessName: '—', vendorCategory: vendorCategory,
    vendorLocation: vendorLocation, vendorRating: vendorRating,
    vendorTotalBookings: vendorTotalBookings, vendorDaysOnPlatform: vendorDaysOnPlatform,
    vendorIsVerified: vendorIsVerified, hasPremiumBadge: hasPremiumBadge,
    vendorBadgeTier: vendorBadgeTier,
    quotedPrice: -1, packageDescription: '—', includedServices: [],
    submittedAt: submittedAt, status: status,
  );

  static BidStatus _parseStatus(String? s) {
    switch (s) {
      case 'accepted': return BidStatus.accepted;
      case 'rejected': return BidStatus.rejected;
      default:         return BidStatus.pending;
    }
  }

  static List<String> _parseList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}
