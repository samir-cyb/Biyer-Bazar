/// BiyerBajar — Supabase Configuration
class SupabaseConfig {
  static const String url = 'https://tqmyqwjrsypkibaryrkb.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxbXlxd2pyc3lwa2liYXJ5cmtiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM5MTYzMjcsImV4cCI6MjA3OTQ5MjMyN30.l2QOHWeGfU8CqgwQ9GprwveG4apo9u2cBt5aMvOAU5w';

  // Storage bucket names (created by migration)
  static const String avatarsBucket    = 'avatars';
  static const String portfoliosBucket = 'portfolios';

  // Hardcoded main admin credentials (checked client-side for dev)
  static const String mainAdminEmail    = 'redwansamir90@gmail.com';
  static const String mainAdminPassword = 'samir7232';
}
