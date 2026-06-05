enum PostStatus { open, reviewing, booked, cancelled }

extension PostStatusLabel on PostStatus {
  String get label {
    switch (this) {
      case PostStatus.open:       return 'Open';
      case PostStatus.reviewing:  return 'Reviewing Bids';
      case PostStatus.booked:     return 'Booked';
      case PostStatus.cancelled:  return 'Cancelled';
    }
  }
  String get emoji {
    switch (this) {
      case PostStatus.open:       return '🟢';
      case PostStatus.reviewing:  return '🔵';
      case PostStatus.booked:     return '✅';
      case PostStatus.cancelled:  return '❌';
    }
  }
}

class EventPost {
  final String id;
  final String hostId;
  final String hostName;
  final String hostPhone;
  final String location;
  final DateTime eventDate;
  final int guestCapacity;
  final String serviceCategory;
  final int budgetCeiling;
  final String description;
  final PostStatus status;
  final DateTime createdAt;
  final String? selectedBidId;
  final String? budgetPlanId;

  EventPost({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.hostPhone,
    required this.location,
    required this.eventDate,
    required this.guestCapacity,
    required this.serviceCategory,
    required this.budgetCeiling,
    required this.description,
    this.status = PostStatus.open,
    required this.createdAt,
    this.selectedBidId,
    this.budgetPlanId,
  });

  factory EventPost.fromMap(Map<dynamic, dynamic> m) => EventPost(
    id:              m['id'] as String,
    hostId:          m['host_id'] as String,
    hostName:        m['host_name'] as String? ?? '',
    hostPhone:       m['host_phone'] as String? ?? '',
    location:        m['location'] as String? ?? '',
    eventDate:       DateTime.tryParse(m['event_date'] as String? ?? '') ?? DateTime.now(),
    guestCapacity:   (m['guest_capacity'] as int?) ?? 0,
    serviceCategory: m['service_category'] as String? ?? '',
    budgetCeiling:   (m['budget_ceiling'] as int?) ?? 0,
    description:     m['description'] as String? ?? '',
    status:          _parseStatus(m['status'] as String?),
    createdAt:       DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    selectedBidId:   m['selected_bid_id'] as String?,
    budgetPlanId:    m['budget_plan_id'] as String?,
  );

  EventPost copyWith({PostStatus? status, String? selectedBidId}) => EventPost(
    id: id, hostId: hostId, hostName: hostName, hostPhone: hostPhone,
    location: location, eventDate: eventDate, guestCapacity: guestCapacity,
    serviceCategory: serviceCategory, budgetCeiling: budgetCeiling,
    description: description, status: status ?? this.status, createdAt: createdAt,
    selectedBidId: selectedBidId ?? this.selectedBidId, budgetPlanId: budgetPlanId,
  );

  int get daysUntilEvent => eventDate.difference(DateTime.now()).inDays;

  static PostStatus _parseStatus(String? s) {
    switch (s) {
      case 'reviewing':  return PostStatus.reviewing;
      case 'booked':     return PostStatus.booked;
      case 'cancelled':  return PostStatus.cancelled;
      default:           return PostStatus.open;
    }
  }
}
