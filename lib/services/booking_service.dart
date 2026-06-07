import 'dart:developer' as dev;
import '../models/booking_model.dart';
import '../models/vendor_package_model.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class BookingService {
  static final _db = SupabaseService.client;

  // ── Create a booking ─────────────────────────────────────────────────────────
  static Future<Booking?> createBooking({
    required String hostId,
    required String vendorId,
    String? packageId,
    String? conversationId,
    required DateTime eventDate,
    required String serviceCategory,
    required int agreedAmount,
    String? notes,
  }) async {
    try {
      final insertMap = Booking(
        id: '',
        hostId: hostId,
        vendorId: vendorId,
        packageId: packageId,
        conversationId: conversationId,
        eventDate: eventDate,
        serviceCategory: serviceCategory,
        agreedAmount: agreedAmount,
        status: BookingStatus.pending,
        notes: notes,
        hostConfirmed: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toInsertMap();

      final row = await _db
          .from('bookings')
          .insert(insertMap)
          .select()
          .single();

      // Auto-create a payment record
      await _db.from('booking_payments').insert({
        'booking_id':   row['id'],
        'total_amount': agreedAmount,
        'paid_amount':  0,
        'status':       'pending',
      });

      // Notify vendor about the new booking request
      try {
        final hostProfile = await _db
            .from('profiles')
            .select('name')
            .eq('id', hostId)
            .maybeSingle();
        final hostName = hostProfile?['name'] as String? ?? 'A host';
        await NotificationService.send(
          toUserId: vendorId,
          title: '📅 New Booking Request!',
          body: '$hostName has sent you a booking request for $serviceCategory. '
              'Please review and respond.',
          type: 'booking',
          data: {'booking_id': row['id']},
        );
      } catch (e) {
        dev.log('[Booking] notify vendor error: $e', name: 'BiyerBajar');
      }

      // Increment vendor's total_bookings counter
      try {
        final vpRow = await _db
            .from('vendor_profiles')
            .select('total_bookings')
            .eq('user_id', vendorId)
            .maybeSingle();
        final current = (vpRow?['total_bookings'] as int?) ?? 0;
        await _db
            .from('vendor_profiles')
            .update({'total_bookings': current + 1})
            .eq('user_id', vendorId);
      } catch (e) {
        dev.log('[Booking] increment total_bookings error: $e', name: 'BiyerBajar');
      }

      return Booking.fromMap(row);
    } catch (e) {
      dev.log('[Booking] createBooking error: $e', name: 'BiyerBajar');
      return null;
    }
  }

  // ── Vendor confirms or rejects ────────────────────────────────────────────────
  static Future<bool> vendorRespond({
    required String bookingId,
    required bool accept,
    String? reason,
  }) async {
    try {
      final update = accept
          ? {
              'vendor_confirmed': true,
              'status':           'confirmed',
              'updated_at':       DateTime.now().toIso8601String(),
            }
          : {
              'status':               'cancelled',
              'cancellation_reason':  reason ?? 'Rejected by vendor',
              'updated_at':           DateTime.now().toIso8601String(),
            };

      await _db.from('bookings').update(update).eq('id', bookingId);

      // Notify host about the vendor's response
      try {
        final bookingRow = await _db
            .from('bookings')
            .select('host_id, service_category, vendor_id')
            .eq('id', bookingId)
            .maybeSingle();
        if (bookingRow != null) {
          final hostId    = bookingRow['host_id'] as String;
          final vendorId  = bookingRow['vendor_id'] as String;
          final category  = bookingRow['service_category'] as String? ?? 'service';
          final vendorProfile = await _db
              .from('profiles')
              .select('name')
              .eq('id', vendorId)
              .maybeSingle();
          final vendorName = vendorProfile?['name'] as String? ?? 'The vendor';
          if (accept) {
            await NotificationService.send(
              toUserId: hostId,
              title: '✅ Booking Confirmed!',
              body: '$vendorName has confirmed your booking for $category. '
                  'Please proceed with payment.',
              type: 'booking',
              data: {'booking_id': bookingId},
            );
          } else {
            await NotificationService.send(
              toUserId: hostId,
              title: '❌ Booking Declined',
              body: '$vendorName has declined your booking request for $category. '
                  'You can search for other vendors.',
              type: 'rejection',
              data: {'booking_id': bookingId},
            );
          }
        }
      } catch (e) {
        dev.log('[Booking] notify host error: $e', name: 'BiyerBajar');
      }

      return true;
    } catch (e) {
      dev.log('[Booking] vendorRespond error: $e', name: 'BiyerBajar');
      return false;
    }
  }

  // ── Complete a booking ────────────────────────────────────────────────────────
  static Future<bool> markCompleted(String bookingId) async {
    try {
      await _db.from('bookings').update({
        'status':     'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
      return true;
    } catch (e) {
      dev.log('[Booking] markCompleted error: $e', name: 'BiyerBajar');
      return false;
    }
  }

  // ── Get bookings for a host ───────────────────────────────────────────────────
  static Future<List<Booking>> getHostBookings(String hostId) async {
    try {
      final rows = await _db
          .from('bookings')
          .select()
          .eq('host_id', hostId)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => Booking.fromMap(r)).toList();
    } catch (e) {
      dev.log('[Booking] getHostBookings error: $e', name: 'BiyerBajar');
      return [];
    }
  }

  // ── Get bookings for a vendor ─────────────────────────────────────────────────
  static Future<List<Booking>> getVendorBookings(String vendorId) async {
    try {
      final rows = await _db
          .from('bookings')
          .select()
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => Booking.fromMap(r)).toList();
    } catch (e) {
      dev.log('[Booking] getVendorBookings error: $e', name: 'BiyerBajar');
      return [];
    }
  }

  // ── Record a payment ──────────────────────────────────────────────────────────
  static Future<bool> recordPayment({
    required String bookingId,
    required int paidAmount,
    required int totalAmount,
    required String paymentMethod,
    String? transactionRef,
    String? notes,
  }) async {
    try {
      final newPaid  = paidAmount;
      final isPaid   = newPaid >= totalAmount;
      final isPartial = newPaid > 0 && newPaid < totalAmount;

      await _db.from('booking_payments').upsert({
        'booking_id':      bookingId,
        'total_amount':    totalAmount,
        'paid_amount':     newPaid,
        'payment_method':  paymentMethod,
        'status':          isPaid ? 'paid' : (isPartial ? 'partial' : 'pending'),
        'transaction_ref': transactionRef,
        'notes':           notes,
        'paid_at':         isPaid ? DateTime.now().toIso8601String() : null,
        'updated_at':      DateTime.now().toIso8601String(),
      }, onConflict: 'booking_id');

      return true;
    } catch (e) {
      dev.log('[Booking] recordPayment error: $e', name: 'BiyerBajar');
      return false;
    }
  }

  // ── Get payment for a booking ─────────────────────────────────────────────────
  static Future<BookingPayment?> getPayment(String bookingId) async {
    try {
      final row = await _db
          .from('booking_payments')
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();
      if (row == null) return null;
      return BookingPayment.fromMap(row);
    } catch (e) {
      dev.log('[Booking] getPayment error: $e', name: 'BiyerBajar');
      return null;
    }
  }
}

// ── Vendor Package Service ────────────────────────────────────────────────────

class VendorPackageService {
  static final _db = SupabaseService.client;

  static Future<List<VendorPackage>> getPackages(String vendorId) async {
    try {
      final rows = await _db
          .from('vendor_packages')
          .select()
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('sort_order');
      return (rows as List).map((r) => VendorPackage.fromMap(r)).toList();
    } catch (e) {
      dev.log('[Package] getPackages error: $e', name: 'BiyerBajar');
      return [];
    }
  }

  static Future<VendorPackage?> upsertPackage(VendorPackage pkg) async {
    try {
      final map = pkg.toMap();
      dynamic row;
      if (pkg.id.isEmpty) {
        row = await _db.from('vendor_packages').insert(map).select().single();
      } else {
        row = await _db.from('vendor_packages').update(map).eq('id', pkg.id).select().single();
      }
      return VendorPackage.fromMap(row);
    } catch (e) {
      dev.log('[Package] upsert error: $e', name: 'BiyerBajar');
      return null;
    }
  }

  static Future<void> deletePackage(String packageId) async {
    try {
      await _db.from('vendor_packages').update({'is_active': false}).eq('id', packageId);
    } catch (e) {
      dev.log('[Package] delete error: $e', name: 'BiyerBajar');
    }
  }

  static Future<List<VendorMenu>> getMenus(String vendorId) async {
    try {
      final rows = await _db
          .from('vendor_menus')
          .select()
          .eq('vendor_id', vendorId)
          .eq('is_active', true);
      return (rows as List).map((r) => VendorMenu.fromMap(r)).toList();
    } catch (e) {
      dev.log('[Menu] getMenus error: $e', name: 'BiyerBajar');
      return [];
    }
  }

  static Future<List<VendorDiscount>> getDiscounts(String vendorId) async {
    try {
      final rows = await _db
          .from('vendor_discounts')
          .select()
          .eq('vendor_id', vendorId)
          .eq('is_active', true);
      return (rows as List).map((r) => VendorDiscount.fromMap(r)).toList();
    } catch (e) {
      dev.log('[Discount] getDiscounts error: $e', name: 'BiyerBajar');
      return [];
    }
  }

  static Future<List<RichVendorProfile>> searchVendors({
    String? category,
    int? maxBudget,
    int? minBudget,
    String? city,
    String? sortBy, // 'rating' | 'price_asc' | 'price_desc' | 'experience'
    int limit = 30,
  }) async {
    try {
      var query = _db
          .from('vendor_profiles')
          .select()
          .eq('approval_status', 'approved');

      if (category != null && category.isNotEmpty) {
        // category is a wildcard pattern e.g. '%Photo%' — ilike for case-insensitive partial match
        query = query.ilike('category', category);
      }
      if (maxBudget != null) {
        query = query.lte('price_range_min', maxBudget);
      }
      if (minBudget != null) {
        query = query.gte('price_range_max', minBudget);
      }
      if (city != null && city.isNotEmpty) {
        query = query.ilike('city', '%$city%');
      }

      // Sorting — resolve column/direction first, apply once at the end
      String sortColumn = 'rating';
      bool ascending = false;
      switch (sortBy) {
        case 'price_asc':
          sortColumn = 'price_range_min'; ascending = true;  break;
        case 'price_desc':
          sortColumn = 'price_range_min'; ascending = false; break;
        case 'experience':
          sortColumn = 'years_experience'; ascending = false; break;
      }

      final rows = await query
          .order(sortColumn, ascending: ascending)
          .limit(limit);

      // For each vendor, fetch packages and discounts
      final profiles = <RichVendorProfile>[];
      for (final row in rows as List) {
        final vendorId = row['user_id'] as String? ?? '';
        final pkgRows  = await _db.from('vendor_packages')
            .select().eq('vendor_id', vendorId).eq('is_active', true).limit(5);
        final discRows = await _db.from('vendor_discounts')
            .select().eq('vendor_id', vendorId).eq('is_active', true).limit(3);

        final enriched = Map<String, dynamic>.from(row as Map);
        enriched['packages']  = pkgRows;
        enriched['discounts'] = discRows;
        profiles.add(RichVendorProfile.fromMap(enriched));
      }
      return profiles;
    } catch (e) {
      dev.log('[Search] searchVendors error: $e', name: 'BiyerBajar');
      return [];
    }
  }
}
