import 'vendor_model.dart';

enum EventRequestStatus { open, reviewing, booked, cancelled }

class EventRequest {
  final String id;
  final String hostName;
  final String hostPhone;
  final String location;
  final DateTime eventDate;
  final int guestCapacity;
  final VendorCategory category;
  final int budgetCeiling; // BDT
  final String description;
  final EventRequestStatus status;
  final DateTime createdAt;

  const EventRequest({
    required this.id,
    required this.hostName,
    required this.hostPhone,
    required this.location,
    required this.eventDate,
    required this.guestCapacity,
    required this.category,
    required this.budgetCeiling,
    required this.description,
    this.status = EventRequestStatus.open,
    required this.createdAt,
  });

  EventRequest copyWith({
    EventRequestStatus? status,
  }) {
    return EventRequest(
      id: id,
      hostName: hostName,
      hostPhone: hostPhone,
      location: location,
      eventDate: eventDate,
      guestCapacity: guestCapacity,
      category: category,
      budgetCeiling: budgetCeiling,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
