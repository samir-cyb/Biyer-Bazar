enum UserRole { host, vendor, admin }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.host:   return 'Host';
      case UserRole.vendor: return 'Vendor';
      case UserRole.admin:  return 'Admin';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.host:   return '👰';
      case UserRole.vendor: return '📸';
      case UserRole.admin:  return '⚙️';
    }
  }
}

// ── Vendor Badge Tiers (Bronze → Platinum) ───────────────────────────────────

enum VendorBadgeTier { bronze, silver, gold, platinum }

extension VendorBadgeLabel on VendorBadgeTier {
  String get label {
    switch (this) {
      case VendorBadgeTier.bronze:   return 'Bronze';
      case VendorBadgeTier.silver:   return 'Silver';
      case VendorBadgeTier.gold:     return 'Gold';
      case VendorBadgeTier.platinum: return 'Platinum';
    }
  }

  String get emoji {
    switch (this) {
      case VendorBadgeTier.bronze:   return '🥉';
      case VendorBadgeTier.silver:   return '🥈';
      case VendorBadgeTier.gold:     return '🥇';
      case VendorBadgeTier.platinum: return '💎';
    }
  }

  String get color {
    switch (this) {
      case VendorBadgeTier.bronze:   return '#CD7F32'; // bronze
      case VendorBadgeTier.silver:   return '#A8A9AD'; // silver
      case VendorBadgeTier.gold:     return '#D4AF37'; // gold
      case VendorBadgeTier.platinum: return '#5B9BD5'; // platinum blue
    }
  }

  /// Minimum avg rating & review count thresholds
  String get description {
    switch (this) {
      case VendorBadgeTier.bronze:   return 'New vendor — earning reputation';
      case VendorBadgeTier.silver:   return '3+ reviews, avg ≥ 3.5 ⭐';
      case VendorBadgeTier.gold:     return '5+ reviews, avg ≥ 4.0 ⭐';
      case VendorBadgeTier.platinum: return '10+ reviews, avg ≥ 4.5 ⭐';
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  // Common optional fields
  final String? nidNumber;
  final String? city;
  final String? profilePictureUrl;
  final bool isActive;

  // Vendor-specific
  final String? businessName;
  final String? vendorCategory;
  final String? location;
  final String? bio;
  final List<String> portfolioUrls;
  final double rating;
  final int totalBookings;
  final int daysOnPlatform;
  final bool isVerified;
  final String subscriptionTier;
  final bool hasPremiumBadge;
  final VendorBadgeTier badgeTier;
  final int freeBidsUsedThisMonth;

  // Admin-specific
  // Admin-specific
  final bool isMainAdmin;

  // Vendor availability
  final String availabilityStatus;
  final int totalReviews;
  final List<String> serviceAreas;
  final int? priceRangeMin;
  final int? priceRangeMax;
  final int yearsExperience;

  // Vendor profile v2 fields
  final String? address;
  final int? capacity;
  final List<String> specialtyTags;
  final String? coverPhotoUrl;
  final String approvalStatus;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.nidNumber,
    this.city,
    this.profilePictureUrl,
    this.isActive = true,
    this.businessName,
    this.vendorCategory,
    this.location,
    this.bio,
    this.portfolioUrls = const [],
    this.rating = 0.0,
    this.totalBookings = 0,
    this.daysOnPlatform = 1,
    this.isVerified = false,
    this.subscriptionTier = 'free',
    this.hasPremiumBadge = false,
    this.badgeTier = VendorBadgeTier.bronze,
    this.freeBidsUsedThisMonth = 0,
    this.isMainAdmin = false,
    this.availabilityStatus = 'available',
    this.totalReviews = 0,
    this.serviceAreas = const [],
    this.priceRangeMin,
    this.priceRangeMax,
    this.yearsExperience = 0,
    this.address,
    this.capacity,
    this.specialtyTags = const [],
    this.coverPhotoUrl,
    this.approvalStatus = 'pending',
  });

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    // Handle nested vendor_profiles join
    final vp = map['vendor_profiles'] is List
        ? (map['vendor_profiles'] as List).isNotEmpty
            ? (map['vendor_profiles'] as List).first as Map
            : null
        : map['vendor_profiles'] as Map?;

    return AppUser(
      id:                 map['id'] as String? ?? '',
      name:               map['name'] as String? ?? '',
      email:              map['email'] as String? ?? '',
      phone:              map['phone'] as String? ?? '',
      role:               _parseRole(map['role'] as String?),
      nidNumber:          map['nid_number'] as String?,
      city:               map['city'] as String?,
      profilePictureUrl:  map['profile_picture_url'] as String?,
      isActive:           (map['is_active'] as bool?) ?? true,
      businessName:       vp?['business_name'] as String?,
      vendorCategory:     vp?['category'] as String?,
      location:           vp?['location'] as String?,
      bio:                vp?['bio'] as String?,
      portfolioUrls:      _parseStringList(vp?['portfolio_urls']),
      rating:             (vp?['rating'] as num?)?.toDouble() ?? 0.0,
      totalBookings:      (vp?['total_bookings'] as int?) ?? 0,
      totalReviews:       (vp?['total_reviews'] as int?) ?? 0,
      daysOnPlatform:     (vp?['days_on_platform'] as int?) ?? 1,
      isVerified:         (vp?['is_verified'] as bool?) ?? false,
      subscriptionTier:   (vp?['subscription_tier'] as String?) ?? 'free',
      hasPremiumBadge:    (vp?['has_premium_badge'] as bool?) ?? false,
      badgeTier:          _parseBadgeTier(vp?['badge_tier'] as String?),
      freeBidsUsedThisMonth: (vp?['free_bids_used_this_month'] as int?) ?? 0,
      availabilityStatus: (vp?['availability_status'] as String?) ?? 'available',
      serviceAreas:       _parseStringList(vp?['service_areas']),
      priceRangeMin:      vp?['price_range_min'] as int?,
      priceRangeMax:      vp?['price_range_max'] as int?,
      yearsExperience:    (vp?['years_experience'] as int?) ?? 0,
      address:            vp?['address'] as String?,
      capacity:           vp?['capacity'] as int?,
      specialtyTags:      _parseStringList(vp?['specialty_tags']),
      coverPhotoUrl:      vp?['cover_photo_url'] as String?,
      approvalStatus:     (vp?['approval_status'] as String?) ?? 'pending',
    );
  }

  Map<String, dynamic> toProfileMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name,
    'nid_number': nidNumber,
    'city': city,
    'profile_picture_url': profilePictureUrl,
    'is_active': isActive,
  };

  Map<String, dynamic> toVendorProfileMap() => {
    'user_id': id,
    'business_name': businessName,
    'category': vendorCategory,
    'location': location,
    'bio': bio,
    'portfolio_urls': portfolioUrls,
    'rating': rating,
    'total_bookings': totalBookings,
    'days_on_platform': daysOnPlatform,
    'is_verified': isVerified,
    'subscription_tier': subscriptionTier,
    'has_premium_badge': hasPremiumBadge,
    'badge_tier': badgeTier.name,
    'free_bids_used_this_month': freeBidsUsedThisMonth,
    'availability_status': availabilityStatus,
    'service_areas': serviceAreas,
    'price_range_min': priceRangeMin,
    'price_range_max': priceRangeMax,
    'years_experience': yearsExperience,
  };

  AppUser copyWith({
    String? name,
    String? phone,
    String? nidNumber,
    String? city,
    String? profilePictureUrl,
    String? businessName,
    String? vendorCategory,
    String? location,
    String? bio,
    List<String>? portfolioUrls,
    double? rating,
    int? totalBookings,
    bool? isVerified,
    String? subscriptionTier,
    bool? hasPremiumBadge,
    VendorBadgeTier? badgeTier,
    int? freeBidsUsedThisMonth,
    String? availabilityStatus,
    List<String>? serviceAreas,
    int? priceRangeMin,
    int? priceRangeMax,
    int? yearsExperience,
    String? address,
    int? capacity,
    List<String>? specialtyTags,
    String? coverPhotoUrl,
    String? approvalStatus,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    role: role,
    nidNumber: nidNumber ?? this.nidNumber,
    city: city ?? this.city,
    profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    isActive: isActive,
    businessName: businessName ?? this.businessName,
    vendorCategory: vendorCategory ?? this.vendorCategory,
    location: location ?? this.location,
    bio: bio ?? this.bio,
    portfolioUrls: portfolioUrls ?? this.portfolioUrls,
    rating: rating ?? this.rating,
    totalBookings: totalBookings ?? this.totalBookings,
    daysOnPlatform: daysOnPlatform,
    isVerified: isVerified ?? this.isVerified,
    subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    hasPremiumBadge: hasPremiumBadge ?? this.hasPremiumBadge,
    badgeTier: badgeTier ?? this.badgeTier,
    freeBidsUsedThisMonth: freeBidsUsedThisMonth ?? this.freeBidsUsedThisMonth,
    isMainAdmin: isMainAdmin,
    availabilityStatus: availabilityStatus ?? this.availabilityStatus,
    serviceAreas: serviceAreas ?? this.serviceAreas,
    priceRangeMin: priceRangeMin ?? this.priceRangeMin,
    priceRangeMax: priceRangeMax ?? this.priceRangeMax,
    yearsExperience: yearsExperience ?? this.yearsExperience,
    address: address ?? this.address,
    capacity: capacity ?? this.capacity,
    specialtyTags: specialtyTags ?? this.specialtyTags,
    coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
    approvalStatus: approvalStatus ?? this.approvalStatus,
  );

  // ── Computed ──────────────────────────────────────────────────────────────────

  /// Whether vendor can still bid for free (or subscription is active).
  bool get canBidFree => freeBidsUsedThisMonth < 3;

  String get displayName => businessName ?? name;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static UserRole _parseRole(String? r) {
    switch (r) {
      case 'vendor': return UserRole.vendor;
      case 'admin':  return UserRole.admin;
      default:       return UserRole.host;
    }
  }

  static VendorBadgeTier _parseBadgeTier(String? t) {
    switch (t) {
      case 'silver':   return VendorBadgeTier.silver;
      case 'gold':     return VendorBadgeTier.gold;
      case 'platinum': return VendorBadgeTier.platinum;
      default:         return VendorBadgeTier.bronze;
    }
  }

  static List<String> _parseStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}
