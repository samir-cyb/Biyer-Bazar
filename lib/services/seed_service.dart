import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/bid_model.dart';
import 'hive_service.dart';

/// Seeds the local Hive database on first launch with:
/// - 1 Admin user
/// - 5 Mock vendors (covering different tiers and categories)
/// - 2 Demo event posts from a sample host
/// - Some bids on those demo posts
class SeedService {
  static const _uuid = Uuid();

  static void seed() {
    if (!HiveService.isFirstLaunch) return;

    // ── Admin ──────────────────────────────────────────────────────────────────
    final admin = AppUser(
      id: _uuid.v4(),
      name: 'Platform Admin',
      phone: '00000000000',
      role: UserRole.admin,
      isVerified: true,
    );
    HiveService.saveUser(admin);

    // ── Sample Host ────────────────────────────────────────────────────────────
    final host = AppUser(
      id: _uuid.v4(),
      name: 'Rina Begum',
      phone: '01700000001',
      role: UserRole.host,
      city: 'Dhaka',
    );
    HiveService.saveUser(host);

    // ── Vendors ────────────────────────────────────────────────────────────────
    final v1 = AppUser(
      id: _uuid.v4(),
      name: 'Karim Ahmed',
      phone: '01800000001',
      role: UserRole.vendor,
      businessName: 'Lens & Light Studio',
      vendorCategory: 'Photography & Video',
      location: 'Dhaka',
      rating: 4.9,
      totalBookings: 87,
      daysOnPlatform: 1200,
      isVerified: true,
      subscriptionTier: 'premium',
    );

    final v2 = AppUser(
      id: _uuid.v4(),
      name: 'Sultana Catering',
      phone: '01800000002',
      role: UserRole.vendor,
      businessName: 'Royal Feast Caterers',
      vendorCategory: 'Catering',
      location: 'Dhaka',
      rating: 4.6,
      totalBookings: 45,
      daysOnPlatform: 600,
      isVerified: true,
      subscriptionTier: 'premium',
    );

    final v3 = AppUser(
      id: _uuid.v4(),
      name: 'Bloom Decor Co.',
      phone: '01800000003',
      role: UserRole.vendor,
      businessName: 'Bloom & Glow Decor',
      vendorCategory: 'Decor & Lighting',
      location: 'Chittagong',
      rating: 4.3,
      totalBookings: 28,
      daysOnPlatform: 380,
      isVerified: true,
      subscriptionTier: 'free',
    );

    final v4 = AppUser(
      id: _uuid.v4(),
      name: 'Nadia Rahman',
      phone: '01800000004',
      role: UserRole.vendor,
      businessName: 'Nadia Rahman Photography',
      vendorCategory: 'Photography & Video',
      location: 'Dhaka',
      rating: 4.7,
      totalBookings: 3,
      daysOnPlatform: 42,
      isVerified: false,
      subscriptionTier: 'free',
    );

    final v5 = AppUser(
      id: _uuid.v4(),
      name: 'Sweet Bakes BD',
      phone: '01800000005',
      role: UserRole.vendor,
      businessName: 'Sweet Moment Bakes',
      vendorCategory: 'Catering',
      location: 'Dhaka',
      rating: 4.8,
      totalBookings: 2,
      daysOnPlatform: 28,
      isVerified: false,
      subscriptionTier: 'free',
    );

    for (final v in [v1, v2, v3, v4, v5]) {
      HiveService.saveUser(v);
    }

    // ── Demo Event Posts ───────────────────────────────────────────────────────
    final post1 = EventPost(
      id: _uuid.v4(),
      hostId: host.id,
      hostName: host.name,
      hostPhone: host.phone,
      location: 'Dhaka',
      eventDate: DateTime.now().add(const Duration(days: 45)),
      guestCapacity: 250,
      serviceCategory: 'Photography & Video',
      budgetCeiling: 50000,
      description:
          'Looking for holud + wedding day photography. Cinematic style preferred. 6–8 hours coverage. Drone shots a bonus.',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    );

    final post2 = EventPost(
      id: _uuid.v4(),
      hostId: host.id,
      hostName: host.name,
      hostPhone: host.phone,
      location: 'Dhaka',
      eventDate: DateTime.now().add(const Duration(days: 60)),
      guestCapacity: 400,
      serviceCategory: 'Catering',
      budgetCeiling: 80000,
      description:
          'Traditional Bangladeshi wedding feast for 400 guests. Need biryani station, rezala, desserts, and full service staff.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    HiveService.savePost(post1);
    HiveService.savePost(post2);

    // ── Seed Bids on Post 1 ────────────────────────────────────────────────────
    final bids = [
      Bid(
        id: _uuid.v4(),
        postId: post1.id,
        vendorId: v1.id,
        vendorName: v1.name,
        vendorBusinessName: v1.businessName!,
        vendorCategory: v1.vendorCategory!,
        vendorLocation: v1.location!,
        vendorRating: v1.rating,
        vendorTotalBookings: v1.totalBookings,
        vendorDaysOnPlatform: v1.daysOnPlatform,
        vendorIsVerified: v1.isVerified,
        quotedPrice: 45000,
        packageDescription:
            'Full-day coverage (10 hrs), 2 photographers, 500+ edited photos, cinematic highlight reel',
        includedServices: [
          'Pre-wedding shoot',
          'Full-day coverage',
          'Drone shots',
          'Online gallery',
          '2 framed prints',
        ],
        submittedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      Bid(
        id: _uuid.v4(),
        postId: post1.id,
        vendorId: v4.id,
        vendorName: v4.name,
        vendorBusinessName: v4.businessName!,
        vendorCategory: v4.vendorCategory!,
        vendorLocation: v4.location!,
        vendorRating: v4.rating,
        vendorTotalBookings: v4.totalBookings,
        vendorDaysOnPlatform: v4.daysOnPlatform,
        vendorIsVerified: v4.isVerified,
        quotedPrice: 22000,
        packageDescription:
            'Holud & wedding day coverage, film-grain editing, delivery in 7 days',
        includedServices: [
          'Holud coverage',
          'Wedding day photos',
          'Film-grain edits',
          'Digital gallery',
          'Sneak peek in 48hrs',
        ],
        submittedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    for (final b in bids) {
      HiveService.saveBid(b);
    }

    HiveService.markSeeded();
  }
}
