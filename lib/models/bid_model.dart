enum BidStatus { pending, accepted, rejected }

extension BidStatusLabel on BidStatus {
  String get label {
    switch (this) {
      case BidStatus.pending:
        return 'Pending';
      case BidStatus.accepted:
        return 'Accepted';
      case BidStatus.rejected:
        return 'Rejected';
    }
  }

  String get emoji {
    switch (this) {
      case BidStatus.pending:
        return '⏳';
      case BidStatus.accepted:
        return '✅';
      case BidStatus.rejected:
        return '❌';
    }
  }
}

class Bid {
  final String id;
  final String postId;
  final String vendorId;
  final String vendorName;
  final String vendorBusinessName;
  final String vendorCategory;
  final String vendorLocation;
  final double vendorRating;
  final int vendorTotalBookings;
  final int vendorDaysOnPlatform;
  final bool vendorIsVerified;
  final int quotedPrice;
  final String packageDescription;
  final List<String> includedServices;
  final DateTime submittedAt;
  BidStatus status;

  Bid({
    required this.id,
    required this.postId,
    required this.vendorId,
    required this.vendorName,
    required this.vendorBusinessName,
    required this.vendorCategory,
    required this.vendorLocation,
    required this.vendorRating,
    required this.vendorTotalBookings,
    required this.vendorDaysOnPlatform,
    required this.vendorIsVerified,
    required this.quotedPrice,
    required this.packageDescription,
    required this.includedServices,
    required this.submittedAt,
    this.status = BidStatus.pending,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'postId': postId,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'vendorBusinessName': vendorBusinessName,
        'vendorCategory': vendorCategory,
        'vendorLocation': vendorLocation,
        'vendorRating': vendorRating,
        'vendorTotalBookings': vendorTotalBookings,
        'vendorDaysOnPlatform': vendorDaysOnPlatform,
        'vendorIsVerified': vendorIsVerified,
        'quotedPrice': quotedPrice,
        'packageDescription': packageDescription,
        'includedServices': includedServices,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status.index,
      };

  factory Bid.fromMap(Map<dynamic, dynamic> map) => Bid(
        id: map['id'] as String,
        postId: map['postId'] as String,
        vendorId: map['vendorId'] as String,
        vendorName: map['vendorName'] as String,
        vendorBusinessName: map['vendorBusinessName'] as String,
        vendorCategory: map['vendorCategory'] as String,
        vendorLocation: map['vendorLocation'] as String,
        vendorRating: (map['vendorRating'] as num).toDouble(),
        vendorTotalBookings: map['vendorTotalBookings'] as int,
        vendorDaysOnPlatform: map['vendorDaysOnPlatform'] as int,
        vendorIsVerified: map['vendorIsVerified'] as bool,
        quotedPrice: map['quotedPrice'] as int,
        packageDescription: map['packageDescription'] as String,
        includedServices:
            (map['includedServices'] as List).map((e) => e as String).toList(),
        submittedAt: DateTime.parse(map['submittedAt'] as String),
        status: BidStatus.values[map['status'] as int],
      );

  /// Blind copy — hides the price for other vendors
  Bid get blinded => Bid(
        id: id,
        postId: postId,
        vendorId: vendorId,
        vendorName: '—',
        vendorBusinessName: '—',
        vendorCategory: vendorCategory,
        vendorLocation: vendorLocation,
        vendorRating: vendorRating,
        vendorTotalBookings: vendorTotalBookings,
        vendorDaysOnPlatform: vendorDaysOnPlatform,
        vendorIsVerified: vendorIsVerified,
        quotedPrice: -1,
        packageDescription: '—',
        includedServices: [],
        submittedAt: submittedAt,
        status: status,
      );
}
