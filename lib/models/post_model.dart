enum PostStatus { open, reviewing, booked, cancelled }

extension PostStatusLabel on PostStatus {
  String get label {
    switch (this) {
      case PostStatus.open:
        return 'Open';
      case PostStatus.reviewing:
        return 'Reviewing Bids';
      case PostStatus.booked:
        return 'Booked';
      case PostStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case PostStatus.open:
        return '🟢';
      case PostStatus.reviewing:
        return '🔵';
      case PostStatus.booked:
        return '✅';
      case PostStatus.cancelled:
        return '❌';
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
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'hostId': hostId,
        'hostName': hostName,
        'hostPhone': hostPhone,
        'location': location,
        'eventDate': eventDate.toIso8601String(),
        'guestCapacity': guestCapacity,
        'serviceCategory': serviceCategory,
        'budgetCeiling': budgetCeiling,
        'description': description,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'selectedBidId': selectedBidId,
      };

  factory EventPost.fromMap(Map<dynamic, dynamic> map) => EventPost(
        id: map['id'] as String,
        hostId: map['hostId'] as String,
        hostName: map['hostName'] as String,
        hostPhone: map['hostPhone'] as String,
        location: map['location'] as String,
        eventDate: DateTime.parse(map['eventDate'] as String),
        guestCapacity: map['guestCapacity'] as int,
        serviceCategory: map['serviceCategory'] as String,
        budgetCeiling: map['budgetCeiling'] as int,
        description: map['description'] as String,
        status: PostStatus.values[map['status'] as int],
        createdAt: DateTime.parse(map['createdAt'] as String),
        selectedBidId: map['selectedBidId'] as String?,
      );

  EventPost copyWith({PostStatus? status, String? selectedBidId}) => EventPost(
        id: id,
        hostId: hostId,
        hostName: hostName,
        hostPhone: hostPhone,
        location: location,
        eventDate: eventDate,
        guestCapacity: guestCapacity,
        serviceCategory: serviceCategory,
        budgetCeiling: budgetCeiling,
        description: description,
        status: status ?? this.status,
        createdAt: createdAt,
        selectedBidId: selectedBidId ?? this.selectedBidId,
      );

  int get daysUntilEvent =>
      eventDate.difference(DateTime.now()).inDays;
}
