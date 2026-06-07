// lib/core/vendor_category_config.dart
//
// Per-category structured field definitions and package templates.
// Stored as JSONB in vendor_profiles.category_details.
// Used by vendor_profile_setup.dart (edit) and vendor_detail_screen.dart (display).

// ── Field type enum ────────────────────────────────────────────────────────────
enum CatFieldType { text, number, bool_, dropdown, multiselect }

// ── Single field definition ────────────────────────────────────────────────────
class CategoryField {
  final String key;
  final String label;
  final CatFieldType type;
  final List<String>? options; // for dropdown / multiselect
  final String? hint;

  const CategoryField({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.hint,
  });
}

// ── Package template ───────────────────────────────────────────────────────────
class PackageTemplate {
  final String name;
  final String description;
  final int price;
  final String priceType; // 'fixed' | 'per_head' | 'per_day' | 'negotiable'
  final List<String> includes;

  const PackageTemplate({
    required this.name,
    required this.description,
    required this.price,
    required this.priceType,
    required this.includes,
  });
}

// ── Category-level config ──────────────────────────────────────────────────────
class CategoryConfig {
  final String sectionTitle;
  final List<CategoryField> fields;
  final List<PackageTemplate> packageTemplates;

  const CategoryConfig({
    required this.sectionTitle,
    required this.fields,
    this.packageTemplates = const [],
  });
}

// ── Central registry ───────────────────────────────────────────────────────────
class VendorCategoryConfig {
  VendorCategoryConfig._();

  // ── Photography & Video / Videography / Drone ─────────────────────────────
  static const _photography = CategoryConfig(
    sectionTitle: '📷 Photography & Video Details',
    fields: [
      CategoryField(key: 'cameras', label: 'Camera / Equipment Brands',
          type: CatFieldType.multiselect,
          options: ['Canon', 'Sony', 'Nikon', 'Fujifilm', 'Panasonic', 'RED Cinema', 'Blackmagic', 'DJI (Drone)']),
      CategoryField(key: 'delivery_days', label: 'Photo/Video Delivery (days)',
          type: CatFieldType.number, hint: 'e.g. 14'),
      CategoryField(key: 'raw_files', label: 'RAW Files Provided',
          type: CatFieldType.bool_),
      CategoryField(key: 'shooters_count', label: 'Number of Photographers / Crew',
          type: CatFieldType.number, hint: 'e.g. 2'),
      CategoryField(key: 'editing_style', label: 'Editing / Filming Style',
          type: CatFieldType.multiselect,
          options: ['Cinematic', 'Documentary', 'Candid', 'Traditional', 'Moody', 'Bright & Airy', 'Same-Day Edit']),
      CategoryField(key: 'album_included', label: 'Printed Album Included',
          type: CatFieldType.bool_),
      CategoryField(key: 'drone_shots', label: 'Drone Shots Available',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Basic Coverage',
        description: '1 photographer, 4-hour coverage, 100 edited photos.',
        price: 15000,
        priceType: 'fixed',
        includes: ['1 Photographer', '4 Hours Coverage', '100 Edited Photos', 'Online Delivery'],
      ),
      PackageTemplate(
        name: 'Standard Wedding',
        description: '2 photographers, full-day coverage, 300 photos + printed album.',
        price: 40000,
        priceType: 'fixed',
        includes: ['2 Photographers', 'Full Day (10 hrs)', '300 Edited Photos', 'Printed Album', 'USB Drive'],
      ),
      PackageTemplate(
        name: 'Premium Cinematic',
        description: 'Photo + video team, drone shots, same-day highlights, RAW files.',
        price: 75000,
        priceType: 'fixed',
        includes: ['2 Photographers', '1 Videographer', 'Drone Shots', 'Same-Day Highlight Reel', 'RAW Files', 'Printed Album'],
      ),
    ],
  );

  // ── Catering & Food ───────────────────────────────────────────────────────
  static const _catering = CategoryConfig(
    sectionTitle: '🍽️ Catering Details',
    fields: [
      CategoryField(key: 'min_guests', label: 'Minimum Guests',
          type: CatFieldType.number, hint: 'e.g. 50'),
      CategoryField(key: 'max_guests', label: 'Maximum Guests',
          type: CatFieldType.number, hint: 'e.g. 1000'),
      CategoryField(key: 'cuisine_types', label: 'Cuisine Types',
          type: CatFieldType.multiselect,
          options: ['Bangladeshi', 'Indian', 'Chinese', 'Continental', 'BBQ / Grill', 'Italian', 'Middle Eastern', 'Sweets & Desserts']),
      CategoryField(key: 'service_style', label: 'Service Style',
          type: CatFieldType.multiselect,
          options: ['Buffet', 'Plated Service', 'Live Counter', 'Box Meal', 'Home Delivery']),
      CategoryField(key: 'halal_certified', label: 'Halal Certified',
          type: CatFieldType.bool_),
      CategoryField(key: 'own_staff', label: 'Own Service Staff Included',
          type: CatFieldType.bool_),
      CategoryField(key: 'setup_included', label: 'Tables & Chairs Setup Included',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Economy Buffet',
        description: 'Min 50 guests — 5 main dishes, rice, dal, soft drinks.',
        price: 350,
        priceType: 'per_head',
        includes: ['5 Main Dishes', 'Rice & Dal', 'Salad', 'Soft Drinks', 'Service Staff'],
      ),
      PackageTemplate(
        name: 'Standard Banquet',
        description: 'Min 100 guests — 10 items, dessert counter, full service.',
        price: 600,
        priceType: 'per_head',
        includes: ['10 Dishes', 'Dessert Counter', 'Cold Drinks', 'Full Staff', 'Crockery & Cutlery'],
      ),
      PackageTemplate(
        name: 'Premium Feast',
        description: 'Min 200 guests — 15+ items, live counters, mocktail bar.',
        price: 900,
        priceType: 'per_head',
        includes: ['15+ Dishes', 'Live BBQ Counter', 'Mocktails Bar', 'Dessert Station', 'Full Setup & Staff'],
      ),
    ],
  );

  // ── Cake & Desserts ───────────────────────────────────────────────────────
  static const _cakesDesserts = CategoryConfig(
    sectionTitle: '🎂 Cake & Desserts Details',
    fields: [
      CategoryField(key: 'cake_types', label: 'Specialties',
          type: CatFieldType.multiselect,
          options: ['Wedding Cake', 'Custom Theme Cake', 'Dessert Table', 'Pastries', 'Bengali Sweets', 'Chocolate Fountain', 'Cupcake Tower', 'Mousse Cake']),
      CategoryField(key: 'min_order_days', label: 'Advance Order Required (days)',
          type: CatFieldType.number, hint: 'e.g. 5'),
      CategoryField(key: 'delivery_available', label: 'Delivery Available',
          type: CatFieldType.bool_),
      CategoryField(key: 'custom_design', label: 'Custom Design Orders Accepted',
          type: CatFieldType.bool_),
      CategoryField(key: 'egg_free', label: 'Egg-Free Options Available',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Small Celebration Cake',
        description: '3-tier fondant cake, custom message, ~2 kg.',
        price: 5000,
        priceType: 'fixed',
        includes: ['3-Tier Fondant', 'Custom Message', '~2 Kg', 'Delivery Included'],
      ),
      PackageTemplate(
        name: 'Wedding Cake + Sweets',
        description: 'Premium 5-tier wedding cake + 5 kg Bengali sweets assorted.',
        price: 18000,
        priceType: 'fixed',
        includes: ['5-Tier Wedding Cake', '5 Kg Sweets', 'Custom Design', 'Cake Stand', 'Delivery'],
      ),
      PackageTemplate(
        name: 'Full Dessert Spread',
        description: 'Complete dessert table for 200+ guests.',
        price: 40000,
        priceType: 'fixed',
        includes: ['Wedding Cake', 'Pastry Tower', 'Sweets Platter', 'Dessert Table Setup', 'Staff'],
      ),
    ],
  );

  // ── Venue & Hall ──────────────────────────────────────────────────────────
  static const _venue = CategoryConfig(
    sectionTitle: '🏛️ Venue Details',
    fields: [
      CategoryField(key: 'venue_type', label: 'Venue Type',
          type: CatFieldType.dropdown,
          options: ['Indoor Hall', 'Outdoor Garden', 'Both (Indoor + Outdoor)', 'Rooftop', 'Poolside']),
      CategoryField(key: 'ac_available', label: 'Air Conditioning',
          type: CatFieldType.bool_),
      CategoryField(key: 'generator_backup', label: 'Generator Backup',
          type: CatFieldType.bool_),
      CategoryField(key: 'parking_capacity', label: 'Parking Spots',
          type: CatFieldType.number, hint: 'e.g. 100'),
      CategoryField(key: 'catering_policy', label: 'Catering Policy',
          type: CatFieldType.dropdown,
          options: ['Own Catering Only', 'External Catering Allowed', 'Both Options']),
      CategoryField(key: 'areas', label: 'Available Areas',
          type: CatFieldType.multiselect,
          options: ['Main Hall', 'Garden', 'Rooftop', 'Poolside', 'Bridal Room', 'Groom Room', 'Entrance Foyer', 'Parking']),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Afternoon Slot',
        description: '4-hour slot, up to 200 guests.',
        price: 80000,
        priceType: 'fixed',
        includes: ['4-Hour Slot', 'Up to 200 Guests', 'Tables & Chairs', 'AC Hall', 'Parking'],
      ),
      PackageTemplate(
        name: 'Full Day Venue',
        description: '8 hours, up to 500 guests, stage included.',
        price: 160000,
        priceType: 'fixed',
        includes: ['8-Hour Booking', 'Up to 500 Guests', 'Stage Setup', 'Bridal Room', 'Parking', 'Generator'],
      ),
      PackageTemplate(
        name: 'Premium Weekend',
        description: 'Full weekend (2 days), all areas, complete coordination.',
        price: 350000,
        priceType: 'fixed',
        includes: ['2-Day Booking', 'All Areas', 'Catering Team', 'Decor Coordination', 'Bridal Suite', 'Full Staff'],
      ),
    ],
  );

  // ── Decor, Stage & Mandap ─────────────────────────────────────────────────
  static const _decor = CategoryConfig(
    sectionTitle: '✨ Decor & Setup Details',
    fields: [
      CategoryField(key: 'decor_styles', label: 'Decor Styles',
          type: CatFieldType.multiselect,
          options: ['Traditional Bengali', 'Modern Minimalist', 'Royal / Grand', 'Floral & Garden', 'LED & Lights', 'Bollywood', 'Rustic', 'Bohemian']),
      CategoryField(key: 'setup_hours', label: 'Setup Time Required (hours)',
          type: CatFieldType.number, hint: 'e.g. 6'),
      CategoryField(key: 'team_size', label: 'Decorators in Team',
          type: CatFieldType.number, hint: 'e.g. 10'),
      CategoryField(key: 'includes_teardown', label: 'Teardown / Cleanup Included',
          type: CatFieldType.bool_),
      CategoryField(key: 'stage_setup', label: 'Stage / Mandap Setup',
          type: CatFieldType.bool_),
      CategoryField(key: 'outdoor_available', label: 'Outdoor Decoration Available',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Stage & Backdrop',
        description: 'Main stage with custom backdrop, sofa, and basic floral.',
        price: 25000,
        priceType: 'fixed',
        includes: ['Custom Backdrop', 'Stage Sofa Set', 'Floral Arrangement', 'Carpet & Lighting'],
      ),
      PackageTemplate(
        name: 'Classic Full Venue',
        description: 'Complete venue decoration — stage, tables, entrance arch.',
        price: 65000,
        priceType: 'fixed',
        includes: ['Stage Backdrop', 'Table Centerpieces', 'Entrance Arch', 'Fairy Lights', 'Floor Runners', 'Cleanup'],
      ),
      PackageTemplate(
        name: 'Royal Grand Decor',
        description: 'Premium full-venue, ceiling draping, photo booth, custom theme.',
        price: 150000,
        priceType: 'fixed',
        includes: ['Premium Stage', 'Ceiling Draping', 'Table Settings', 'Photo Booth', 'Floral Pathway', 'Custom Theme', 'Cleanup'],
      ),
    ],
  );

  // ── Flower & Garland ──────────────────────────────────────────────────────
  static const _floral = CategoryConfig(
    sectionTitle: '🌸 Flower & Garland Details',
    fields: [
      CategoryField(key: 'floral_types', label: 'Flower Types Used',
          type: CatFieldType.multiselect,
          options: ['Fresh Flowers', 'Artificial / Silk', 'Mixed', 'Imported Varieties', 'Seasonal Local']),
      CategoryField(key: 'garland_types', label: 'Garland Specialties',
          type: CatFieldType.multiselect,
          options: ['Bride-Groom Garland', 'Entrance Garland', 'Car Decoration', 'Flower Shower', 'Stage Garland', 'Table Arrangements']),
      CategoryField(key: 'delivery_available', label: 'Delivery Available',
          type: CatFieldType.bool_),
      CategoryField(key: 'custom_orders', label: 'Custom Orders Accepted',
          type: CatFieldType.bool_),
      CategoryField(key: 'advance_days', label: 'Advance Order Required (days)',
          type: CatFieldType.number, hint: 'e.g. 3'),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Basic Garland Set',
        description: 'Bride & groom garlands + 2 entrance garlands.',
        price: 5000,
        priceType: 'fixed',
        includes: ['Bride Garland', 'Groom Garland', '2 Entrance Garlands', 'Flower Basket'],
      ),
      PackageTemplate(
        name: 'Wedding Floral Package',
        description: 'Full wedding garlands, entrance arch, stage flowers, car decoration.',
        price: 20000,
        priceType: 'fixed',
        includes: ['All Garlands', 'Entrance Arch', 'Stage Floral', 'Car Decoration', 'Flower Shower Set'],
      ),
    ],
  );

  // ── Makeup Artist ─────────────────────────────────────────────────────────
  static const _makeup = CategoryConfig(
    sectionTitle: '💄 Makeup & Styling Details',
    fields: [
      CategoryField(key: 'products_used', label: 'Products Used',
          type: CatFieldType.multiselect,
          options: ['MAC', 'NARS', 'Huda Beauty', 'Charlotte Tilbury', 'Fenty Beauty', 'Kryolan', 'Local Premium', 'International Brands']),
      CategoryField(key: 'techniques', label: 'Techniques',
          type: CatFieldType.multiselect,
          options: ['HD / High Definition', 'Airbrush', 'Traditional Bridal', 'Natural Glow', 'Smokey Eye', 'Cut Crease', 'Party Makeup']),
      CategoryField(key: 'home_service', label: 'Home Service Available',
          type: CatFieldType.bool_),
      CategoryField(key: 'trial_available', label: 'Trial Session Available',
          type: CatFieldType.bool_),
      CategoryField(key: 'saree_draping', label: 'Saree Draping Included',
          type: CatFieldType.bool_),
      CategoryField(key: 'hair_styling', label: 'Hair Styling Included',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Party Makeup',
        description: 'Full face makeup for function or party.',
        price: 3000,
        priceType: 'fixed',
        includes: ['Full Face Makeup', 'Eye Makeup', 'Setting Spray', '2-Hour Session'],
      ),
      PackageTemplate(
        name: 'Bridal Full Package',
        description: 'Complete bridal look — makeup, hair, saree draping.',
        price: 15000,
        priceType: 'fixed',
        includes: ['Full Bridal Makeup', 'HD Foundation', 'Hair Styling', 'Saree Draping', 'Touch-Up Kit', '6-Hour Session'],
      ),
      PackageTemplate(
        name: 'All Functions Package',
        description: 'Makeup for all wedding functions (3–4 events).',
        price: 35000,
        priceType: 'fixed',
        includes: ['4 Function Makeups', 'Engagement Look', 'Bridal Look', 'Reception Look', 'Hair Styling', 'Home Service'],
      ),
    ],
  );

  // ── Mehendi & Henna ───────────────────────────────────────────────────────
  static const _mehendi = CategoryConfig(
    sectionTitle: '🌿 Mehendi Details',
    fields: [
      CategoryField(key: 'mehendi_styles', label: 'Mehendi Styles',
          type: CatFieldType.multiselect,
          options: ['Arabic', 'Indian / Rajasthani', 'Bangladeshi Traditional', 'Fusion', 'Minimalist', 'Full Hand & Feet']),
      CategoryField(key: 'henna_type', label: 'Henna Type',
          type: CatFieldType.multiselect,
          options: ['Natural Henna', 'Chemical-Free', 'Imported Henna', 'Black Henna Available']),
      CategoryField(key: 'home_service', label: 'Home Service Available',
          type: CatFieldType.bool_),
      CategoryField(key: 'artists_count', label: 'Number of Artists',
          type: CatFieldType.number, hint: 'e.g. 2'),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Bride Only',
        description: 'Full bridal mehendi — both hands and feet, premium design.',
        price: 5000,
        priceType: 'fixed',
        includes: ['Both Hands', 'Both Feet', 'Arabic + Indian Design', 'Natural Henna', 'Home Service'],
      ),
      PackageTemplate(
        name: 'Bride + 10 Guests',
        description: 'Full bridal + simple designs for 10 guests.',
        price: 12000,
        priceType: 'fixed',
        includes: ['Full Bridal Mehendi', '10 Guest Designs', '2 Artists', 'Natural Henna'],
      ),
      PackageTemplate(
        name: 'Full Event Package',
        description: 'Per-guest simple pattern + complete bridal set.',
        price: 1000,
        priceType: 'per_head',
        includes: ['Per Guest Pattern', 'Full Bridal Set', 'Natural Henna', 'Multiple Artists'],
      ),
    ],
  );

  // ── Bridal Attire & Jewelry / Groom Styling / Bridal Jewellery Rental ────
  static const _attireJewelry = CategoryConfig(
    sectionTitle: '💍 Attire & Jewelry Details',
    fields: [
      CategoryField(key: 'product_types', label: 'Product Types',
          type: CatFieldType.multiselect,
          options: ['Bridal Lehenga', 'Saree', 'Sherewani', 'Salwar Kameez', 'Western Suit', 'Gold Jewelry', 'Diamond Jewelry', 'Silver Jewelry', 'Artificial Jewelry', 'Full Bridal Set']),
      CategoryField(key: 'brands', label: 'Brands / Designers',
          type: CatFieldType.text, hint: 'e.g. Aarong, local designer'),
      CategoryField(key: 'rental_available', label: 'Rental Available',
          type: CatFieldType.bool_),
      CategoryField(key: 'custom_orders', label: 'Custom / Bespoke Orders',
          type: CatFieldType.bool_),
      CategoryField(key: 'alteration_service', label: 'Alteration / Stitching',
          type: CatFieldType.bool_),
      CategoryField(key: 'delivery_available', label: 'Home Delivery Available',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Bridal Jewelry Rental',
        description: 'Full jewelry set rental for 2 days.',
        price: 15000,
        priceType: 'fixed',
        includes: ['Necklace + Earrings + Bangles', 'Tikka + Maang', '2-Day Rental', 'Packaging Box'],
      ),
      PackageTemplate(
        name: 'Complete Bridal Attire',
        description: 'Lehenga / saree + matching jewelry set (purchase).',
        price: 60000,
        priceType: 'fixed',
        includes: ['Bridal Lehenga or Saree', 'Matching Jewelry Set', 'Dupatta', 'Alteration Included'],
      ),
      PackageTemplate(
        name: 'All Events Package',
        description: 'Outfits for all wedding functions including reception.',
        price: 150000,
        priceType: 'fixed',
        includes: ['Gaye Holud Outfit', 'Bridal Set', 'Reception Outfit', 'All Jewelry', 'Storage Box'],
      ),
    ],
  );

  // ── DJ & Sound System ─────────────────────────────────────────────────────
  static const _djSound = CategoryConfig(
    sectionTitle: '🎵 DJ & Sound Details',
    fields: [
      CategoryField(key: 'equipment_brands', label: 'Equipment Brands',
          type: CatFieldType.multiselect,
          options: ['JBL', 'Bose', 'Yamaha', 'Pioneer', 'QSC', 'RCF', 'Crown', 'Local Brand']),
      CategoryField(key: 'sound_output_kw', label: 'Sound Output (KW)',
          type: CatFieldType.number, hint: 'e.g. 10'),
      CategoryField(key: 'genres', label: 'Music Genres',
          type: CatFieldType.multiselect,
          options: ['Bollywood', 'Bengali Folk / Baul', 'Classical', 'Western Pop', 'EDM', 'Sufi', 'Mixed']),
      CategoryField(key: 'lighting_included', label: 'Lighting System Included',
          type: CatFieldType.bool_),
      CategoryField(key: 'setup_hours', label: 'Setup Time (hours)',
          type: CatFieldType.number, hint: 'e.g. 2'),
      CategoryField(key: 'performance_hours', label: 'Performance Hours Included',
          type: CatFieldType.number, hint: 'e.g. 6'),
    ],
    packageTemplates: [
      PackageTemplate(
        name: '4-Hour DJ Set',
        description: 'DJ + 5KW sound system, 4-hour performance.',
        price: 18000,
        priceType: 'fixed',
        includes: ['DJ Performance', '5KW Sound System', '4 Hours', 'Mic & Wireless Mic', 'Setup & Teardown'],
      ),
      PackageTemplate(
        name: 'Full Night Sound + DJ',
        description: 'DJ + 10KW sound, full lighting, 8 hours.',
        price: 40000,
        priceType: 'fixed',
        includes: ['DJ Performance', '10KW Sound', 'LED Lighting', '8 Hours', 'Mic Setup', 'Fog Machine'],
      ),
      PackageTemplate(
        name: 'Premium Event Production',
        description: 'DJ + 20KW sound, full lighting rig, trussing, effects.',
        price: 80000,
        priceType: 'fixed',
        includes: ['DJ + Assistant', '20KW Sound', 'Full LED Rig', 'Trussing', 'Smoke & Bubble Effect', 'Projector Available'],
      ),
    ],
  );

  // ── Live Band & Music ─────────────────────────────────────────────────────
  static const _liveMusic = CategoryConfig(
    sectionTitle: '🎸 Live Band Details',
    fields: [
      CategoryField(key: 'instruments', label: 'Instruments',
          type: CatFieldType.multiselect,
          options: ['Guitar', 'Bass', 'Drums', 'Keyboard', 'Violin', 'Tabla', 'Flute', 'Sitar', 'Dhol', 'Saxophone']),
      CategoryField(key: 'genres', label: 'Genres Performed',
          type: CatFieldType.multiselect,
          options: ['Bangla Modern', 'Bangla Folk / Baul', 'Rabindra Sangeet', 'Bollywood', 'Western Pop', 'Sufi', 'Jazz', 'Classical']),
      CategoryField(key: 'band_members', label: 'Band Members',
          type: CatFieldType.number, hint: 'e.g. 6'),
      CategoryField(key: 'performance_hours', label: 'Performance Hours',
          type: CatFieldType.number, hint: 'e.g. 3'),
      CategoryField(key: 'sound_system', label: 'Own Sound System',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Short Performance',
        description: '4-piece band, 2-hour live performance.',
        price: 25000,
        priceType: 'fixed',
        includes: ['4 Musicians', '2-Hour Performance', 'Classic Repertoire', 'Sound System'],
      ),
      PackageTemplate(
        name: 'Full Event Band',
        description: '6-piece band, 4 hours, mixed genres.',
        price: 60000,
        priceType: 'fixed',
        includes: ['6 Musicians', '4-Hour Performance', 'Mixed Repertoire', 'Sound System', 'Light Rig'],
      ),
    ],
  );

  // ── Event MC / Host ───────────────────────────────────────────────────────
  static const _eventMC = CategoryConfig(
    sectionTitle: '🎤 Event MC Details',
    fields: [
      CategoryField(key: 'languages', label: 'Languages',
          type: CatFieldType.multiselect,
          options: ['Bangla', 'English', 'Hindi', 'Bilingual (Bangla + English)', 'Trilingual']),
      CategoryField(key: 'event_types', label: 'Events Covered',
          type: CatFieldType.multiselect,
          options: ['Wedding Ceremony', 'Reception', 'Engagement', 'Gaye Holud', 'Corporate Event', 'Birthday / Party']),
      CategoryField(key: 'performance_hours', label: 'Hours Included',
          type: CatFieldType.number, hint: 'e.g. 5'),
      CategoryField(key: 'script_included', label: 'Custom Script Writing',
          type: CatFieldType.bool_),
      CategoryField(key: 'games_activities', label: 'Games & Interactive Activities',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Ceremony MC',
        description: 'MC for main ceremony + reception, 4 hours bilingual.',
        price: 15000,
        priceType: 'fixed',
        includes: ['4 Hours', 'Ceremony & Reception', 'Bangla + English', 'Custom Script'],
      ),
      PackageTemplate(
        name: 'Full Day MC',
        description: 'MC for all wedding day events, games, coordination.',
        price: 30000,
        priceType: 'fixed',
        includes: ['Full Day (8 hrs)', 'All Events', 'Custom Script', 'Games & Activities', 'Coordination Support'],
      ),
    ],
  );

  // ── Invitation & Stationery ───────────────────────────────────────────────
  static const _invitation = CategoryConfig(
    sectionTitle: '✉️ Invitation & Stationery Details',
    fields: [
      CategoryField(key: 'design_types', label: 'Formats Offered',
          type: CatFieldType.multiselect,
          options: ['Digital Invite', 'Printed Card', 'Handmade / Artisan', 'Premium Box Invite', 'WhatsApp Template', 'Video Invite']),
      CategoryField(key: 'min_quantity', label: 'Minimum Print Quantity',
          type: CatFieldType.number, hint: 'e.g. 100'),
      CategoryField(key: 'print_finish', label: 'Print Finish',
          type: CatFieldType.multiselect,
          options: ['Matte', 'Glossy', 'Embossed', 'Foil Print', 'Velvet Laminate']),
      CategoryField(key: 'languages', label: 'Languages',
          type: CatFieldType.multiselect,
          options: ['Bangla', 'English', 'Both (Bangla + English)']),
      CategoryField(key: 'digital_available', label: 'Digital Invites Included',
          type: CatFieldType.bool_),
      CategoryField(key: 'free_revisions', label: 'Free Design Revisions',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Digital Pack',
        description: '50 personalised digital invites + WhatsApp version.',
        price: 3500,
        priceType: 'fixed',
        includes: ['50 Digital Invites', 'WhatsApp Version', 'Custom Design', '2 Revisions', 'PDF + Image Format'],
      ),
      PackageTemplate(
        name: 'Print Basic',
        description: '100 printed cards, matte finish, Bangla + English.',
        price: 9000,
        priceType: 'fixed',
        includes: ['100 Cards', 'Matte Finish', 'Envelope', 'Digital Version Included', 'Delivery'],
      ),
      PackageTemplate(
        name: 'Premium Boxed Set',
        description: '200 premium foil cards + digital, custom envelope.',
        price: 25000,
        priceType: 'fixed',
        includes: ['200 Premium Cards', 'Foil Print', 'Custom Envelope', 'Digital Invites', 'Gift Box Packaging'],
      ),
    ],
  );

  // ── Car Decoration & Transport ────────────────────────────────────────────
  static const _transport = CategoryConfig(
    sectionTitle: '🚗 Transport Details',
    fields: [
      CategoryField(key: 'vehicle_types', label: 'Vehicle Types',
          type: CatFieldType.multiselect,
          options: ['Sedan', 'SUV / Jeep', 'Luxury Car', 'Microbus', 'Bus', 'Decorated Bride Car', 'Vintage Car']),
      CategoryField(key: 'vehicles_count', label: 'Total Vehicles Available',
          type: CatFieldType.number, hint: 'e.g. 10'),
      CategoryField(key: 'driver_included', label: 'Driver Included',
          type: CatFieldType.bool_),
      CategoryField(key: 'fuel_included', label: 'Fuel Included',
          type: CatFieldType.bool_),
      CategoryField(key: 'decoration', label: 'Vehicle Decoration Included',
          type: CatFieldType.bool_),
      CategoryField(key: 'outstation', label: 'Outstation / Outside City',
          type: CatFieldType.bool_),
      CategoryField(key: 'night_service', label: 'Night Service Available',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Bridal Car',
        description: 'Single premium decorated car for bride.',
        price: 8000,
        priceType: 'fixed',
        includes: ['1 Luxury Sedan', 'Floral Decoration', 'Driver', 'Full Day'],
      ),
      PackageTemplate(
        name: 'Guest Fleet (5 Vehicles)',
        description: '5 vehicles for guest transport, driver + fuel.',
        price: 30000,
        priceType: 'fixed',
        includes: ['5 Vehicles', 'Drivers', 'Fuel', 'AC', 'Full Day'],
      ),
      PackageTemplate(
        name: 'Complete Logistics',
        description: '10+ vehicles for all wedding day transport needs.',
        price: 70000,
        priceType: 'fixed',
        includes: ['10+ Vehicles', 'Bridal Car', 'Guest Buses', 'Drivers + Fuel', 'Coordination', 'Night Service'],
      ),
    ],
  );

  // ── Logistics & Coordination ──────────────────────────────────────────────
  static const _logistics = CategoryConfig(
    sectionTitle: '🚚 Logistics & Coordination Details',
    fields: [
      CategoryField(key: 'services', label: 'Services Offered',
          type: CatFieldType.multiselect,
          options: ['Guest Coordination', 'Vendor Management', 'Day-of Timeline', 'Setup & Teardown', 'Equipment Transport', 'Last-Mile Delivery']),
      CategoryField(key: 'team_size', label: 'Coordination Team Size',
          type: CatFieldType.number, hint: 'e.g. 5'),
      CategoryField(key: 'vehicles_count', label: 'Vehicles Available',
          type: CatFieldType.number, hint: 'e.g. 3'),
      CategoryField(key: 'outstation', label: 'Outstation Service',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Day-of Coordination',
        description: 'On-site logistics team for the wedding day only.',
        price: 20000,
        priceType: 'fixed',
        includes: ['5-Person Team', 'Day-of Coordination', 'Vendor Liaison', 'Timeline Management'],
      ),
      PackageTemplate(
        name: 'Full Event Logistics',
        description: 'Pre-event planning + day-of execution + vendor coordination.',
        price: 50000,
        priceType: 'fixed',
        includes: ['Pre-Event Planning', 'Day-of Team', 'Vendor Management', 'Guest Coordination', 'Equipment Transport'],
      ),
    ],
  );

  // ── Wedding Planner ───────────────────────────────────────────────────────
  static const _weddingPlanner = CategoryConfig(
    sectionTitle: '📋 Wedding Planner Details',
    fields: [
      CategoryField(key: 'service_type', label: 'Service Type',
          type: CatFieldType.multiselect,
          options: ['Full Planning', 'Partial Planning', 'Day-of Coordination', 'Consultation Only', 'Design & Styling']),
      CategoryField(key: 'events_per_year', label: 'Max Events Handled / Year',
          type: CatFieldType.number, hint: 'e.g. 20'),
      CategoryField(key: 'team_size', label: 'Team Size',
          type: CatFieldType.number, hint: 'e.g. 5'),
      CategoryField(key: 'vendor_network', label: 'Vendor Network Included',
          type: CatFieldType.bool_),
      CategoryField(key: 'budget_management', label: 'Budget Management Service',
          type: CatFieldType.bool_),
      CategoryField(key: 'destination_wedding', label: 'Destination Wedding Experience',
          type: CatFieldType.bool_),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Day-of Coordinator',
        description: 'Full coordination on wedding day only.',
        price: 30000,
        priceType: 'fixed',
        includes: ['Day-of Team', 'Timeline Management', 'Vendor Liaison', 'Emergency Kit', '10-Hour Coverage'],
      ),
      PackageTemplate(
        name: 'Partial Planning (3 Months)',
        description: 'Planning support for the last 3 months before the wedding.',
        price: 80000,
        priceType: 'fixed',
        includes: ['3 Months Support', 'Vendor Selection', 'Budget Tracking', 'Timeline Creation', 'Day-of Coordination'],
      ),
      PackageTemplate(
        name: 'Full Wedding Planning',
        description: 'Complete planning from engagement to wedding day.',
        price: 200000,
        priceType: 'fixed',
        includes: ['6–12 Months Planning', 'Venue Selection', 'Vendor Management', 'Budget Control', 'Full Team', 'Day-of Execution'],
      ),
    ],
  );

  // ── Security Services ─────────────────────────────────────────────────────
  static const _security = CategoryConfig(
    sectionTitle: '🛡️ Security Details',
    fields: [
      CategoryField(key: 'guards_available', label: 'Guards Available',
          type: CatFieldType.number, hint: 'e.g. 30'),
      CategoryField(key: 'licensed', label: 'Licensed Security Agency',
          type: CatFieldType.bool_),
      CategoryField(key: 'uniform_provided', label: 'Uniform Provided',
          type: CatFieldType.bool_),
      CategoryField(key: 'armed_available', label: 'Armed Guards Available',
          type: CatFieldType.bool_),
      CategoryField(key: 'services', label: 'Services',
          type: CatFieldType.multiselect,
          options: ['Crowd Management', 'VIP Security', 'Parking Management', 'Entry Control', 'Patrol Service', 'CCTV Setup']),
    ],
    packageTemplates: [
      PackageTemplate(
        name: 'Basic Security',
        description: '5 guards, 8-hour shift, uniform included.',
        price: 15000,
        priceType: 'fixed',
        includes: ['5 Guards', '8 Hours', 'Uniform', 'Crowd Management', 'Entry Control'],
      ),
      PackageTemplate(
        name: 'Standard Event Security',
        description: '10 guards + supervisor, 12 hours.',
        price: 30000,
        priceType: 'fixed',
        includes: ['10 Guards', '1 Supervisor', '12 Hours', 'Parking Management', 'Entry Control', 'Uniform'],
      ),
      PackageTemplate(
        name: 'Premium Security',
        description: '20 guards + supervisor team, full day, VIP escort.',
        price: 60000,
        priceType: 'fixed',
        includes: ['20 Guards', '2 Supervisors', 'Full Day', 'VIP Security', 'CCTV Setup', 'Emergency Response'],
      ),
    ],
  );

  // ── Lookup ────────────────────────────────────────────────────────────────
  /// Returns the [CategoryConfig] for the given category string, or null.
  static CategoryConfig? forCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('photo') || c.contains('videography') ||
        c.contains('cinematic') || c.contains('drone'))
      return _photography;
    if (c.contains('cater') || c.contains('food')) return _catering;
    if (c.contains('cake') || c.contains('dessert')) return _cakesDesserts;
    if (c.contains('venue') || c.contains('hall')) return _venue;
    if (c.contains('flower') || c.contains('garland')) return _floral;
    if (c.contains('stage') || c.contains('mandap') ||
        c.contains('decor') || c.contains('lighting'))
      return _decor;
    if (c.contains('mehendi') || c.contains('henna')) return _mehendi;
    if (c.contains('makeup') || c.contains('beauty')) return _makeup;
    if (c.contains('groom') || c.contains('attire') ||
        c.contains('jewel') || c.contains('bridal jewel'))
      return _attireJewelry;
    if (c.contains('dj') || c.contains('sound')) return _djSound;
    if (c.contains('band') || c.contains('live')) return _liveMusic;
    if (c.contains(' mc') || c.contains('/host') || c.contains('event mc'))
      return _eventMC;
    if (c.contains('invitation') || c.contains('stationery'))
      return _invitation;
    if (c.contains('car') || c.contains('transport')) return _transport;
    if (c.contains('logistic') || c.contains('coordination'))
      return _logistics;
    if (c.contains('planner')) return _weddingPlanner;
    if (c.contains('security')) return _security;
    return null;
  }
}
