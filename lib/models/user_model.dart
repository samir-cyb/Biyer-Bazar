enum UserRole { host, vendor, admin }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.host:
        return 'Host';
      case UserRole.vendor:
        return 'Vendor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.host:
        return '👰';
      case UserRole.vendor:
        return '📸';
      case UserRole.admin:
        return '⚙️';
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String phone;
  final UserRole role;

  // Vendor-specific fields
  final String? businessName;
  final String? vendorCategory;
  final String? location;
  final double rating;
  final int totalBookings;
  final int daysOnPlatform;
  final bool isVerified;
  final String subscriptionTier;

  // Host-specific fields
  final String? city;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.businessName,
    this.vendorCategory,
    this.location,
    this.rating = 5.0,
    this.totalBookings = 0,
    this.daysOnPlatform = 1,
    this.isVerified = false,
    this.subscriptionTier = 'free',
    this.city,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role.index,
        'businessName': businessName,
        'vendorCategory': vendorCategory,
        'location': location,
        'rating': rating,
        'totalBookings': totalBookings,
        'daysOnPlatform': daysOnPlatform,
        'isVerified': isVerified,
        'subscriptionTier': subscriptionTier,
        'city': city,
      };

  factory AppUser.fromMap(Map<dynamic, dynamic> map) => AppUser(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String,
        role: UserRole.values[map['role'] as int],
        businessName: map['businessName'] as String?,
        vendorCategory: map['vendorCategory'] as String?,
        location: map['location'] as String?,
        rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
        totalBookings: (map['totalBookings'] as int?) ?? 0,
        daysOnPlatform: (map['daysOnPlatform'] as int?) ?? 1,
        isVerified: (map['isVerified'] as bool?) ?? false,
        subscriptionTier: (map['subscriptionTier'] as String?) ?? 'free',
        city: map['city'] as String?,
      );

  AppUser copyWith({
    String? name,
    String? businessName,
    String? vendorCategory,
    String? location,
    double? rating,
    int? totalBookings,
    bool? isVerified,
    String? subscriptionTier,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        phone: phone,
        role: role,
        businessName: businessName ?? this.businessName,
        vendorCategory: vendorCategory ?? this.vendorCategory,
        location: location ?? this.location,
        rating: rating ?? this.rating,
        totalBookings: totalBookings ?? this.totalBookings,
        daysOnPlatform: daysOnPlatform,
        isVerified: isVerified ?? this.isVerified,
        subscriptionTier: subscriptionTier ?? this.subscriptionTier,
        city: city,
      );
}
