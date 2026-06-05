/// Centralised list of all service categories used across the app.
/// Update this file to add/remove categories everywhere at once.
class ServiceCategories {
  static const List<String> all = [
    'Photography & Video',
    'Catering & Food',
    'Venue & Hall',
    'Decor & Lighting',
    'Makeup Artist',
    'Bridal Attire & Jewelry',
    'Groom Styling',
    'Mehendi & Henna',
    'Stage & Mandap Design',
    'DJ & Sound System',
    'Live Band & Music',
    'Invitation & Stationery',
    'Car Decoration & Transport',
    'Flower & Garland',
    'Cake & Desserts',
    'Event MC / Host',
    'Wedding Planner',
    'Security Services',
    'Videography (Cinematic)',
    'Drone Photography',
    'Bridal Jewellery Rental',
    'Logistics & Coordination',
  ];

  /// Emoji icon map for each category
  static const Map<String, String> icons = {
    'Photography & Video':       '📸',
    'Catering & Food':           '🍽️',
    'Venue & Hall':               '🏛️',
    'Decor & Lighting':          '✨',
    'Makeup Artist':             '💄',
    'Bridal Attire & Jewelry':   '💍',
    'Groom Styling':             '🤵',
    'Mehendi & Henna':           '🌿',
    'Stage & Mandap Design':     '🎪',
    'DJ & Sound System':         '🎵',
    'Live Band & Music':         '🎸',
    'Invitation & Stationery':   '✉️',
    'Car Decoration & Transport':'🚗',
    'Flower & Garland':          '🌸',
    'Cake & Desserts':           '🎂',
    'Event MC / Host':           '🎤',
    'Wedding Planner':           '📋',
    'Security Services':         '🛡️',
    'Videography (Cinematic)':   '🎬',
    'Drone Photography':         '🚁',
    'Bridal Jewellery Rental':   '💎',
    'Logistics & Coordination':  '🚚',
  };

  static String iconFor(String category) => icons[category] ?? '🎊';

  /// Maps service category name → budget category ID (from budget_model.dart)
  /// null means this service has no direct budget category mapping
  static const Map<String, String> serviceToBudgetCategory = {
    'Photography & Video':       'photo',
    'Videography (Cinematic)':   'photo',
    'Drone Photography':         'photo',
    'Catering & Food':           'venue',
    'Venue & Hall':              'venue',
    'Cake & Desserts':           'venue',
    'Decor & Lighting':          'decor',
    'Stage & Mandap Design':     'decor',
    'Flower & Garland':          'decor',
    'Makeup Artist':             'makeup',
    'Mehendi & Henna':           'makeup',
    'Bridal Attire & Jewelry':   'attire',
    'Groom Styling':             'attire',
    'Bridal Jewellery Rental':   'attire',
    'DJ & Sound System':         'music',
    'Live Band & Music':         'music',
    'Event MC / Host':           'music',
    'Car Decoration & Transport':'transport',
    'Logistics & Coordination':  'transport',
    'Invitation & Stationery':   'invitation',
    'Wedding Planner':           'contingency',
    'Security Services':         'contingency',
  };

  static String? budgetCategoryFor(String serviceCategory) =>
      serviceToBudgetCategory[serviceCategory];
}
