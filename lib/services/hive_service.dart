import 'package:hive_flutter/hive_flutter.dart';

/// HiveService — now used only for local session management.
/// All entity data (posts, bids, users) is stored in Supabase.
class HiveService {
  static const String _sessionBox = 'session';

  static Box get session => Hive.box(_sessionBox);

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_sessionBox);
  }

  // ── Session ──────────────────────────────────────────────────────────────
  static void setCurrentUserId(String id) => session.put('currentUserId', id);
  static String? getCurrentUserId() => session.get('currentUserId') as String?;
  static void clearSession() => session.delete('currentUserId');

  // ── First-launch seed flag ────────────────────────────────────────────────
  static bool get isFirstLaunch => session.get('seeded') == null;
  static void markSeeded() => session.put('seeded', true);

  // ── Stub: bid count per post (returns 0; real data comes from Supabase) ───
  static List<dynamic> getBidsForPost(String postId) => const [];
}
