import 'package:uuid/uuid.dart';
import '../models/bid_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'hive_service.dart';

class PostService {
  static const _uuid = Uuid();

  static EventPost createPost({
    required AppUser host,
    required String location,
    required DateTime eventDate,
    required int guestCapacity,
    required String serviceCategory,
    required int budgetCeiling,
    required String description,
  }) {
    final post = EventPost(
      id: _uuid.v4(),
      hostId: host.id,
      hostName: host.name,
      hostPhone: host.phone,
      location: location,
      eventDate: eventDate,
      guestCapacity: guestCapacity,
      serviceCategory: serviceCategory,
      budgetCeiling: budgetCeiling,
      description: description,
      createdAt: DateTime.now(),
    );
    HiveService.savePost(post);
    return post;
  }

  static List<EventPost> getMyPosts(String hostId) =>
      HiveService.getPostsByHost(hostId);

  static List<EventPost> getOpenPosts() => HiveService.getOpenPosts();

  static List<EventPost> getOpenPostsForVendorCategory(String category) =>
      HiveService.getOpenPosts()
          .where((p) =>
              p.serviceCategory.toLowerCase() == category.toLowerCase())
          .toList();

  static void acceptBid(String postId, String bidId) {
    final post = HiveService.getPost(postId);
    if (post == null) return;
    // Mark the selected bid accepted
    HiveService.updateBidStatus(bidId, BidStatus.accepted);
    // Reject all other bids for this post
    final otherBids = HiveService.getBidsForPost(postId)
        .where((b) => b.id != bidId)
        .toList();
    for (final bid in otherBids) {
      HiveService.updateBidStatus(bid.id, BidStatus.rejected);
    }
    // Update post status
    final updated = post.copyWith(
      status: PostStatus.booked,
      selectedBidId: bidId,
    );
    HiveService.savePost(updated);
  }

  static void cancelPost(String postId) {
    final post = HiveService.getPost(postId);
    if (post == null) return;
    HiveService.savePost(post.copyWith(status: PostStatus.cancelled));
  }

  static int getBidCount(String postId) =>
      HiveService.getBidsForPost(postId).length;
}
