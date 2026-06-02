import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/bid_model.dart';

class HiveService {
  static const String _usersBox = 'users';
  static const String _postsBox = 'posts';
  static const String _bidsBox = 'bids';
  static const String _sessionBox = 'session';

  static Box get users => Hive.box(_usersBox);
  static Box get posts => Hive.box(_postsBox);
  static Box get bids => Hive.box(_bidsBox);
  static Box get session => Hive.box(_sessionBox);

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_usersBox);
    await Hive.openBox(_postsBox);
    await Hive.openBox(_bidsBox);
    await Hive.openBox(_sessionBox);
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  static void saveUser(AppUser user) =>
      users.put(user.id, user.toMap());

  static AppUser? getUser(String id) {
    final data = users.get(id);
    if (data == null) return null;
    return AppUser.fromMap(data as Map);
  }

  static List<AppUser> getAllUsers() => users.values
      .map((v) => AppUser.fromMap(v as Map))
      .toList();

  static AppUser? findUserByPhone(String phone) {
    try {
      return getAllUsers().firstWhere((u) => u.phone == phone);
    } catch (_) {
      return null;
    }
  }

  // ── Session ─────────────────────────────────────────────────────────────────

  static void setCurrentUserId(String id) =>
      session.put('currentUserId', id);

  static String? getCurrentUserId() =>
      session.get('currentUserId') as String?;

  static AppUser? getCurrentUser() {
    final id = getCurrentUserId();
    if (id == null) return null;
    return getUser(id);
  }

  static void clearSession() => session.delete('currentUserId');

  // ── Posts ──────────────────────────────────────────────────────────────────

  static void savePost(EventPost post) =>
      posts.put(post.id, post.toMap());

  static EventPost? getPost(String id) {
    final data = posts.get(id);
    if (data == null) return null;
    return EventPost.fromMap(data as Map);
  }

  static List<EventPost> getAllPosts() => posts.values
      .map((v) => EventPost.fromMap(v as Map))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  static List<EventPost> getPostsByHost(String hostId) =>
      getAllPosts().where((p) => p.hostId == hostId).toList();

  static List<EventPost> getOpenPosts() =>
      getAllPosts().where((p) => p.status == PostStatus.open).toList();

  // ── Bids ────────────────────────────────────────────────────────────────────

  static void saveBid(Bid bid) => bids.put(bid.id, bid.toMap());

  static Bid? getBid(String id) {
    final data = bids.get(id);
    if (data == null) return null;
    return Bid.fromMap(data as Map);
  }

  static List<Bid> getAllBids() => bids.values
      .map((v) => Bid.fromMap(v as Map))
      .toList()
    ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  static List<Bid> getBidsForPost(String postId) =>
      getAllBids().where((b) => b.postId == postId).toList();

  static List<Bid> getBidsByVendor(String vendorId) =>
      getAllBids().where((b) => b.vendorId == vendorId).toList();

  static bool hasVendorBidOnPost(String vendorId, String postId) =>
      getAllBids().any((b) => b.vendorId == vendorId && b.postId == postId);

  static void updateBidStatus(String bidId, BidStatus status) {
    final bid = getBid(bidId);
    if (bid == null) return;
    final updated = Bid(
      id: bid.id,
      postId: bid.postId,
      vendorId: bid.vendorId,
      vendorName: bid.vendorName,
      vendorBusinessName: bid.vendorBusinessName,
      vendorCategory: bid.vendorCategory,
      vendorLocation: bid.vendorLocation,
      vendorRating: bid.vendorRating,
      vendorTotalBookings: bid.vendorTotalBookings,
      vendorDaysOnPlatform: bid.vendorDaysOnPlatform,
      vendorIsVerified: bid.vendorIsVerified,
      quotedPrice: bid.quotedPrice,
      packageDescription: bid.packageDescription,
      includedServices: bid.includedServices,
      submittedAt: bid.submittedAt,
      status: status,
    );
    saveBid(updated);
  }

  // ── Seed ───────────────────────────────────────────────────────────────────

  static bool get isFirstLaunch =>
      session.get('seeded') == null;

  static void markSeeded() => session.put('seeded', true);
}
