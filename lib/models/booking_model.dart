// ── Booking Models ────────────────────────────────────────────────────────────

enum BookingStatus { pending, confirmed, completed, cancelled }

extension BookingStatusLabel on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:   return 'Pending';
      case BookingStatus.confirmed: return 'Confirmed';
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.cancelled: return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case BookingStatus.pending:   return '⏳';
      case BookingStatus.confirmed: return '✅';
      case BookingStatus.completed: return '🎉';
      case BookingStatus.cancelled: return '❌';
    }
  }

  static BookingStatus fromString(String? s) {
    switch (s) {
      case 'confirmed': return BookingStatus.confirmed;
      case 'completed': return BookingStatus.completed;
      case 'cancelled': return BookingStatus.cancelled;
      default:          return BookingStatus.pending;
    }
  }
}

class Booking {
  final String id;
  final String hostId;
  final String vendorId;
  final String? packageId;
  final String? conversationId;
  final DateTime eventDate;
  final String serviceCategory;
  final int agreedAmount;
  final BookingStatus status;
  final String? notes;
  final bool hostConfirmed;
  final bool vendorConfirmed;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined — populated from DB query
  final String? hostName;
  final String? vendorName;
  final String? vendorBusinessName;
  final String? packageName;

  const Booking({
    required this.id,
    required this.hostId,
    required this.vendorId,
    this.packageId,
    this.conversationId,
    required this.eventDate,
    required this.serviceCategory,
    required this.agreedAmount,
    required this.status,
    this.notes,
    this.hostConfirmed = false,
    this.vendorConfirmed = false,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.hostName,
    this.vendorName,
    this.vendorBusinessName,
    this.packageName,
  });

  bool get isFullyConfirmed => hostConfirmed && vendorConfirmed;

  factory Booking.fromMap(Map<dynamic, dynamic> m) {
    final host   = m['host_profile'] as Map?;
    final vendor = m['vendor_profile'] as Map?;
    final vp     = m['vendor_profile_data'] as Map?;
    final pkg    = m['package'] as Map?;

    return Booking(
      id:                 m['id'] as String,
      hostId:             m['host_id'] as String,
      vendorId:           m['vendor_id'] as String,
      packageId:          m['package_id'] as String?,
      conversationId:     m['conversation_id'] as String?,
      eventDate:          DateTime.tryParse(m['event_date'] as String? ?? '') ?? DateTime.now(),
      serviceCategory:    m['service_category'] as String? ?? '',
      agreedAmount:       (m['agreed_amount'] as int?) ?? 0,
      status:             BookingStatusLabel.fromString(m['status'] as String?),
      notes:              m['notes'] as String?,
      hostConfirmed:      (m['host_confirmed'] as bool?) ?? false,
      vendorConfirmed:    (m['vendor_confirmed'] as bool?) ?? false,
      cancellationReason: m['cancellation_reason'] as String?,
      createdAt:          DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:          DateTime.tryParse(m['updated_at'] as String? ?? '') ?? DateTime.now(),
      hostName:           host?['name'] as String?,
      vendorName:         vendor?['name'] as String?,
      vendorBusinessName: vp?['business_name'] as String?,
      packageName:        pkg?['name'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'host_id':          hostId,
    'vendor_id':        vendorId,
    'package_id':       packageId,
    'conversation_id':  conversationId,
    'event_date':       eventDate.toIso8601String().substring(0, 10),
    'service_category': serviceCategory,
    'agreed_amount':    agreedAmount,
    'notes':            notes,
    'status':           'pending',
    'host_confirmed':   true,   // host initiates, so auto-confirm host side
  };
}

// ── Payment Model ─────────────────────────────────────────────────────────────

enum PaymentStatus { pending, partial, paid, refunded }

extension PaymentStatusLabel on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:  return 'Pending';
      case PaymentStatus.partial:  return 'Partial';
      case PaymentStatus.paid:     return 'Paid';
      case PaymentStatus.refunded: return 'Refunded';
    }
  }

  static PaymentStatus fromString(String? s) {
    switch (s) {
      case 'partial':  return PaymentStatus.partial;
      case 'paid':     return PaymentStatus.paid;
      case 'refunded': return PaymentStatus.refunded;
      default:         return PaymentStatus.pending;
    }
  }
}

class BookingPayment {
  final String id;
  final String bookingId;
  final int totalAmount;
  final int paidAmount;
  final String paymentMethod;
  final PaymentStatus status;
  final String? transactionRef;
  final String? notes;
  final DateTime? paidAt;
  final DateTime createdAt;

  const BookingPayment({
    required this.id,
    required this.bookingId,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentMethod,
    required this.status,
    this.transactionRef,
    this.notes,
    this.paidAt,
    required this.createdAt,
  });

  int get remainingAmount => totalAmount - paidAmount;
  double get paidFraction => totalAmount > 0 ? paidAmount / totalAmount : 0;

  factory BookingPayment.fromMap(Map<dynamic, dynamic> m) => BookingPayment(
    id:              m['id'] as String,
    bookingId:       m['booking_id'] as String,
    totalAmount:     (m['total_amount'] as int?) ?? 0,
    paidAmount:      (m['paid_amount'] as int?) ?? 0,
    paymentMethod:   (m['payment_method'] as String?) ?? 'pending',
    status:          PaymentStatusLabel.fromString(m['status'] as String?),
    transactionRef:  m['transaction_ref'] as String?,
    notes:           m['notes'] as String?,
    paidAt:          m['paid_at'] != null
                       ? DateTime.tryParse(m['paid_at'] as String)
                       : null,
    createdAt:       DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
