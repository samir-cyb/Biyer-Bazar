enum VendorTier { premium, verified, freshTalent }

enum VendorCategory {
  photography,
  catering,
  decor,
  makeup,
  venue,
  attire,
  logistics,
}

extension VendorCategoryLabel on VendorCategory {
  String get label {
    switch (this) {
      case VendorCategory.photography:
        return 'Photography & Video';
      case VendorCategory.catering:
        return 'Catering';
      case VendorCategory.decor:
        return 'Decor & Lighting';
      case VendorCategory.makeup:
        return 'Makeup Artist';
      case VendorCategory.venue:
        return 'Venue';
      case VendorCategory.attire:
        return 'Attire & Jewelry';
      case VendorCategory.logistics:
        return 'Logistics';
    }
  }
}

class VendorProfile {
  final String id;
  final String name;
  final String tagline;
  final VendorCategory category;
  final String location;
  final double rating;
  final int totalBookings;
  final int daysOnPlatform;
  final bool isVerified;
  final List<String> portfolioImageUrls;
  final String subscriptionTier; // 'free' | 'premium'

  VendorTier get tier {
    if (rating >= 4.5 && totalBookings >= 20) return VendorTier.premium;
    if (totalBookings < 5 || daysOnPlatform < 60) return VendorTier.freshTalent;
    return VendorTier.verified;
  }

  const VendorProfile({
    required this.id,
    required this.name,
    required this.tagline,
    required this.category,
    required this.location,
    required this.rating,
    required this.totalBookings,
    required this.daysOnPlatform,
    required this.isVerified,
    required this.portfolioImageUrls,
    this.subscriptionTier = 'free',
  });
}

class VendorBid {
  final String bidId;
  final String jobId;
  final VendorProfile vendor;
  final int quotedPrice; // in BDT, hidden from other vendors
  final String packageDescription;
  final List<String> includedServices;
  final DateTime submittedAt;
  bool isRevealed; // only revealed to the host after selection

  VendorBid({
    required this.bidId,
    required this.jobId,
    required this.vendor,
    required this.quotedPrice,
    required this.packageDescription,
    required this.includedServices,
    required this.submittedAt,
    this.isRevealed = false,
  });
}
