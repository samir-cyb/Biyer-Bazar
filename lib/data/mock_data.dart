import '../models/vendor_model.dart';

// Placeholder color-based "image" URLs using picsum for dev portfolio slots
final List<VendorProfile> mockVendors = [
  // PREMIUM VENDORS
  VendorProfile(
    id: 'v001',
    name: 'Lens & Light Studio',
    tagline: 'Crafting timeless wedding stories since 2015',
    category: VendorCategory.photography,
    location: 'Dhaka',
    rating: 4.9,
    totalBookings: 87,
    daysOnPlatform: 1200,
    isVerified: true,
    subscriptionTier: 'premium',
    portfolioImageUrls: [
      'https://picsum.photos/seed/wedding1/400/300',
      'https://picsum.photos/seed/wedding2/400/300',
      'https://picsum.photos/seed/wedding3/400/300',
    ],
  ),
  VendorProfile(
    id: 'v002',
    name: 'Royal Banquet Hall',
    tagline: 'Dhaka\'s most prestigious wedding venue, 1000+ capacity',
    category: VendorCategory.venue,
    location: 'Dhaka',
    rating: 4.8,
    totalBookings: 142,
    daysOnPlatform: 900,
    isVerified: true,
    subscriptionTier: 'premium',
    portfolioImageUrls: [
      'https://picsum.photos/seed/venue1/400/300',
      'https://picsum.photos/seed/venue2/400/300',
      'https://picsum.photos/seed/venue3/400/300',
    ],
  ),
  // VERIFIED VENDORS
  VendorProfile(
    id: 'v003',
    name: 'Spice Route Caterers',
    tagline: 'Authentic Bangladeshi cuisine for every occasion',
    category: VendorCategory.catering,
    location: 'Chittagong',
    rating: 4.3,
    totalBookings: 34,
    daysOnPlatform: 420,
    isVerified: true,
    subscriptionTier: 'premium',
    portfolioImageUrls: [
      'https://picsum.photos/seed/food1/400/300',
      'https://picsum.photos/seed/food2/400/300',
      'https://picsum.photos/seed/food3/400/300',
    ],
  ),
  VendorProfile(
    id: 'v004',
    name: 'Bloom & Glow Decor',
    tagline: 'Bespoke floral & lighting design for dream weddings',
    category: VendorCategory.decor,
    location: 'Dhaka',
    rating: 4.4,
    totalBookings: 28,
    daysOnPlatform: 380,
    isVerified: true,
    subscriptionTier: 'free',
    portfolioImageUrls: [
      'https://picsum.photos/seed/decor1/400/300',
      'https://picsum.photos/seed/decor2/400/300',
      'https://picsum.photos/seed/decor3/400/300',
    ],
  ),
  VendorProfile(
    id: 'v005',
    name: 'Shimmer Makeup Studio',
    tagline: 'Bridal transformation with K-beauty techniques',
    category: VendorCategory.makeup,
    location: 'Sylhet',
    rating: 4.2,
    totalBookings: 19,
    daysOnPlatform: 290,
    isVerified: true,
    subscriptionTier: 'free',
    portfolioImageUrls: [
      'https://picsum.photos/seed/makeup1/400/300',
      'https://picsum.photos/seed/makeup2/400/300',
      'https://picsum.photos/seed/makeup3/400/300',
    ],
  ),
  // FRESH TALENT
  VendorProfile(
    id: 'v006',
    name: 'Nadia Rahman Photography',
    tagline: 'DU Film grad — editorial style, raw emotions, affordable',
    category: VendorCategory.photography,
    location: 'Dhaka',
    rating: 4.6,
    totalBookings: 3,
    daysOnPlatform: 42,
    isVerified: false,
    subscriptionTier: 'free',
    portfolioImageUrls: [
      'https://picsum.photos/seed/fresh1/400/300',
      'https://picsum.photos/seed/fresh2/400/300',
      'https://picsum.photos/seed/fresh3/400/300',
    ],
  ),
  VendorProfile(
    id: 'v007',
    name: 'Sweet Moment Bakes',
    tagline: 'Home baker — custom wedding cakes & dessert tables',
    category: VendorCategory.catering,
    location: 'Dhaka',
    rating: 4.7,
    totalBookings: 2,
    daysOnPlatform: 28,
    isVerified: false,
    subscriptionTier: 'free',
    portfolioImageUrls: [
      'https://picsum.photos/seed/cake1/400/300',
      'https://picsum.photos/seed/cake2/400/300',
      'https://picsum.photos/seed/cake3/400/300',
    ],
  ),
];

List<VendorBid> generateMockBids(String jobId) {
  return [
    VendorBid(
      bidId: 'bid_001',
      jobId: jobId,
      vendor: mockVendors[0],
      quotedPrice: 85000,
      packageDescription:
          'Full-day coverage (10 hrs), 2 photographers, edited gallery of 500+ images, cinematic highlight reel',
      includedServices: [
        'Pre-wedding shoot',
        'Full-day coverage',
        'Drone shots',
        'Online gallery',
        '2 framed prints',
      ],
      submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    VendorBid(
      bidId: 'bid_002',
      jobId: jobId,
      vendor: mockVendors[1],
      quotedPrice: 120000,
      packageDescription:
          'Premium hall booking (8 hrs), décor setup, AC, parking for 200 cars, backup generator',
      includedServices: [
        'Hall rental',
        'Basic décor',
        'Catering space',
        'Sound system',
        'Valet parking',
      ],
      submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    VendorBid(
      bidId: 'bid_003',
      jobId: jobId,
      vendor: mockVendors[2],
      quotedPrice: 45000,
      packageDescription:
          '200-pax traditional Bangladeshi wedding feast, 15 dishes, live cooking stations',
      includedServices: [
        'Biryani station',
        'Rezala',
        'Desserts',
        'Soft drinks',
        'Service staff',
      ],
      submittedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    VendorBid(
      bidId: 'bid_004',
      jobId: jobId,
      vendor: mockVendors[3],
      quotedPrice: 35000,
      packageDescription:
          'Floral arch, table centrepieces, fairy lights canopy, fresh flower petal pathway',
      includedServices: [
        'Floral arch',
        'Centrepieces',
        'Fairy lights',
        'Stage backdrop',
        'Petal pathway',
      ],
      submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    VendorBid(
      bidId: 'bid_005',
      jobId: jobId,
      vendor: mockVendors[4],
      quotedPrice: 18000,
      packageDescription:
          'Full bridal glam — HD makeup, hair styling, trials included, touch-up kit for the day',
      includedServices: [
        'Trial session',
        'HD makeup',
        'Hair styling',
        'Touch-up kit',
        'Bridesmaid discount',
      ],
      submittedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    VendorBid(
      bidId: 'bid_006',
      jobId: jobId,
      vendor: mockVendors[5],
      quotedPrice: 22000,
      packageDescription:
          'Holud & wedding day coverage, film-grain edited photos, delivery within 7 days',
      includedServices: [
        'Holud coverage',
        'Wedding day',
        'Film edits',
        'Digital gallery',
        'Sneak peek in 48hrs',
      ],
      submittedAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    VendorBid(
      bidId: 'bid_007',
      jobId: jobId,
      vendor: mockVendors[6],
      quotedPrice: 12000,
      packageDescription:
          '4-tier custom fondant cake + 50-piece dessert table with mini pastries and macarons',
      includedServices: [
        'Custom cake design',
        'Dessert table',
        'Tasting session',
        'Free delivery Dhaka',
        'Floral topper',
      ],
      submittedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];
}
