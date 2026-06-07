// ── Vendor Package, Menu & Discount Models ────────────────────────────────────

class VendorPackage {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final int price;
  final String priceType;   // 'fixed' | 'per_head' | 'per_day' | 'negotiable'
  final List<String> includes;
  final bool isPopular;
  final bool isActive;
  final int sortOrder;

  const VendorPackage({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.price,
    this.priceType = 'fixed',
    this.includes = const [],
    this.isPopular = false,
    this.isActive = true,
    this.sortOrder = 0,
  });

  String get priceLabel {
    switch (priceType) {
      case 'per_head':    return '৳$price / person';
      case 'per_day':     return '৳$price / day';
      case 'negotiable':  return 'Negotiable (from ৳$price)';
      default:            return '৳$price';
    }
  }

  factory VendorPackage.fromMap(Map<dynamic, dynamic> m) {
    final raw = m['includes'];
    List<String> includes = [];
    if (raw is List) {
      includes = raw.map((e) => e.toString()).toList();
    }
    return VendorPackage(
      id:          m['id'] as String,
      vendorId:    m['vendor_id'] as String,
      name:        m['name'] as String? ?? '',
      description: m['description'] as String?,
      price:       (m['price'] as int?) ?? 0,
      priceType:   (m['price_type'] as String?) ?? 'fixed',
      includes:    includes,
      isPopular:   (m['is_popular'] as bool?) ?? false,
      isActive:    (m['is_active'] as bool?) ?? true,
      sortOrder:   (m['sort_order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'vendor_id':   vendorId,
    'name':        name,
    'description': description,
    'price':       price,
    'price_type':  priceType,
    'includes':    includes,
    'is_popular':  isPopular,
    'is_active':   isActive,
    'sort_order':  sortOrder,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class MenuItem {
  final String name;
  final String? description;
  final bool isVeg;

  const MenuItem({required this.name, this.description, this.isVeg = false});

  factory MenuItem.fromMap(Map m) => MenuItem(
    name:        m['name'] as String? ?? '',
    description: m['description'] as String?,
    isVeg:       (m['is_veg'] as bool?) ?? false,
  );

  Map<String, dynamic> toMap() => {
    'name':        name,
    'description': description,
    'is_veg':      isVeg,
  };
}

class VendorMenu {
  final String id;
  final String vendorId;
  final String menuName;
  final String mealType;   // 'breakfast' | 'lunch' | 'dinner' | 'snacks' | 'all'
  final List<MenuItem> items;
  final int? perHeadPrice;
  final int minGuests;
  final int? maxGuests;
  final bool isActive;

  const VendorMenu({
    required this.id,
    required this.vendorId,
    required this.menuName,
    this.mealType = 'all',
    this.items = const [],
    this.perHeadPrice,
    this.minGuests = 0,
    this.maxGuests,
    this.isActive = true,
  });

  factory VendorMenu.fromMap(Map<dynamic, dynamic> m) {
    final raw = m['items'];
    List<MenuItem> items = [];
    if (raw is List) {
      items = raw
          .whereType<Map>()
          .map((e) => MenuItem.fromMap(e))
          .toList();
    }
    return VendorMenu(
      id:           m['id'] as String,
      vendorId:     m['vendor_id'] as String,
      menuName:     m['menu_name'] as String? ?? '',
      mealType:     (m['meal_type'] as String?) ?? 'all',
      items:        items,
      perHeadPrice: m['per_head_price'] as int?,
      minGuests:    (m['min_guests'] as int?) ?? 0,
      maxGuests:    m['max_guests'] as int?,
      isActive:     (m['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'vendor_id':      vendorId,
    'menu_name':      menuName,
    'meal_type':      mealType,
    'items':          items.map((i) => i.toMap()).toList(),
    'per_head_price': perHeadPrice,
    'min_guests':     minGuests,
    'max_guests':     maxGuests,
    'is_active':      isActive,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class VendorDiscount {
  final String id;
  final String vendorId;
  final String title;
  final String? description;
  final String discountType;   // 'percentage' | 'flat'
  final int discountValue;
  final int minBookingAmt;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;

  const VendorDiscount({
    required this.id,
    required this.vendorId,
    required this.title,
    this.description,
    this.discountType = 'percentage',
    required this.discountValue,
    this.minBookingAmt = 0,
    this.validFrom,
    this.validUntil,
    this.isActive = true,
  });

  String get displayValue =>
      discountType == 'percentage' ? '$discountValue% OFF' : '৳$discountValue OFF';

  bool get isExpired =>
      validUntil != null && validUntil!.isBefore(DateTime.now());

  factory VendorDiscount.fromMap(Map<dynamic, dynamic> m) => VendorDiscount(
    id:              m['id'] as String,
    vendorId:        m['vendor_id'] as String,
    title:           m['title'] as String? ?? '',
    description:     m['description'] as String?,
    discountType:    (m['discount_type'] as String?) ?? 'percentage',
    discountValue:   (m['discount_value'] as int?) ?? 0,
    minBookingAmt:   (m['min_booking_amt'] as int?) ?? 0,
    validFrom:       m['valid_from'] != null
                       ? DateTime.tryParse(m['valid_from'] as String)
                       : null,
    validUntil:      m['valid_until'] != null
                       ? DateTime.tryParse(m['valid_until'] as String)
                       : null,
    isActive:        (m['is_active'] as bool?) ?? true,
  );

  Map<String, dynamic> toMap() => {
    'vendor_id':        vendorId,
    'title':            title,
    'description':      description,
    'discount_type':    discountType,
    'discount_value':   discountValue,
    'min_booking_amt':  minBookingAmt,
    'valid_from':       validFrom?.toIso8601String().substring(0, 10),
    'valid_until':      validUntil?.toIso8601String().substring(0, 10),
    'is_active':        isActive,
  };
}

// ── Rich Vendor Profile (extended view for search results) ────────────────────

class RichVendorProfile {
  final String userId;
  final String businessName;
  final String? bio;
  final String category;
  final String? location;
  final String? address;
  final String? city;
  final double rating;
  final int totalBookings;
  final int totalReviews;
  final bool isVerified;
  final String approvalStatus;
  final String subscriptionTier;
  final String? coverPhotoUrl;
  final List<String> portfolioUrls;
  final List<String> specialtyTags;
  final int? capacity;
  final int? priceRangeMin;
  final int? priceRangeMax;
  final String availabilityStatus;
  final int yearsExperience;

  // Joined
  final List<VendorPackage> packages;
  final List<VendorDiscount> discounts;

  // Category-specific structured data (JSONB)
  final Map<String, dynamic> categoryDetails;

  const RichVendorProfile({
    required this.userId,
    required this.businessName,
    this.bio,
    required this.category,
    this.location,
    this.address,
    this.city,
    this.rating = 0.0,
    this.totalBookings = 0,
    this.totalReviews = 0,
    this.isVerified = false,
    this.approvalStatus = 'pending',
    this.subscriptionTier = 'free',
    this.coverPhotoUrl,
    this.portfolioUrls = const [],
    this.specialtyTags = const [],
    this.capacity,
    this.priceRangeMin,
    this.priceRangeMax,
    this.availabilityStatus = 'available',
    this.yearsExperience = 0,
    this.packages = const [],
    this.discounts = const [],
    this.categoryDetails = const {},
  });

  bool get isApproved => approvalStatus == 'approved';

  String get priceRangeDisplay {
    if (priceRangeMin == null && priceRangeMax == null) return 'Price on request';
    if (priceRangeMin != null && priceRangeMax != null) {
      return '৳${priceRangeMin} – ৳${priceRangeMax}';
    }
    if (priceRangeMin != null) return 'From ৳${priceRangeMin}';
    return 'Up to ৳${priceRangeMax}';
  }

  bool fitsbudget(int budget) {
    if (priceRangeMin == null) return true;
    return priceRangeMin! <= budget;
  }

  factory RichVendorProfile.fromMap(Map<dynamic, dynamic> m) {
    final pkgsRaw = m['packages'] as List? ?? [];
    final discRaw = m['discounts'] as List? ?? [];

    return RichVendorProfile(
      userId:             m['user_id'] as String? ?? m['id'] as String? ?? '',
      businessName:       m['business_name'] as String? ?? '',
      bio:                m['bio'] as String?,
      category:           m['category'] as String? ?? '',
      location:           m['location'] as String?,
      address:            m['address'] as String?,
      city:               m['city'] as String?,
      rating:             (m['rating'] as num?)?.toDouble() ?? 0.0,
      totalBookings:      (m['total_bookings'] as int?) ?? 0,
      totalReviews:       (m['total_reviews'] as int?) ?? 0,
      isVerified:         (m['is_verified'] as bool?) ?? false,
      approvalStatus:     (m['approval_status'] as String?) ?? 'pending',
      subscriptionTier:   (m['subscription_tier'] as String?) ?? 'free',
      coverPhotoUrl:      m['cover_photo_url'] as String?,
      portfolioUrls:      _parseStringList(m['portfolio_urls']),
      specialtyTags:      _parseStringList(m['specialty_tags']),
      capacity:           m['capacity'] as int?,
      priceRangeMin:      m['price_range_min'] as int?,
      priceRangeMax:      m['price_range_max'] as int?,
      availabilityStatus: (m['availability_status'] as String?) ?? 'available',
      yearsExperience:    (m['years_experience'] as int?) ?? 0,
      packages:           pkgsRaw.whereType<Map>()
                            .map((e) => VendorPackage.fromMap(e)).toList(),
      discounts:          discRaw.whereType<Map>()
                            .map((e) => VendorDiscount.fromMap(e)).toList(),
      categoryDetails:    _parseCategoryDetails(m['category_details']),
    );
  }

  static Map<String, dynamic> _parseCategoryDetails(dynamic v) {
    if (v == null) return {};
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  static List<String> _parseStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}
