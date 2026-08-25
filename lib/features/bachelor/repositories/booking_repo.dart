import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../notifications/models/app_notification_model.dart';
import '../models/booking_model.dart';
import '../../../core/services/api_service.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();

  // Create a new booking request and update post availability
  Future<String> createBooking(BookingModel booking) async {
    try {
      AppLogger.i(
        'Saving booking request (PostId: ${booking.postId})',
        tag: 'BOOKING_REPO',
      );
      final docRef = _firestore
          .collection(ApiConstants.bookingsCollection)
          .doc();
      final bookingWithId = booking.copyWith(bookingId: docRef.id);

      await _firestore.runTransaction((transaction) async {
        // 1. Read: Get the Post document FIRST
        final postRef = _firestore
            .collection(ApiConstants.postsCollection)
            .doc(booking.postId);
        final postSnapshot = await transaction.get(postRef);

        // 2. Write: Save the booking
        transaction.set(docRef, bookingWithId.toMap());

        // 3. Write: Update Post availability
        if (postSnapshot.exists) {
          // Forcefully set to unavailable so no one else can book it
          transaction.update(postRef, {'seatCount': 0, 'isAvailable': false});
        }
      });

      AppLogger.s(
        'Booking request saved successfully and post updated in Firestore',
        tag: 'BOOKING_REPO',
      );
      
      try {
        await _apiService.dio.post(ApiConstants.bookings, data: bookingWithId.toMap());
        AppLogger.s('Booking request synced with API Backend', tag: 'BOOKING_REPO');
      } catch (e) {
        AppLogger.e('Failed to sync booking with API: $e', e, null, 'BOOKING_REPO');
        // We don't throw here to avoid failing the whole process if only the custom backend fails, 
        // since Firestore succeeded. Or we could throw, depending on strictness.
      }
      
      // Notify the landlord
      NotificationService().sendAndStore(
        receiverUid: booking.landlordUid,
        title: 'New Booking Request! 🔔',
        body: '${booking.bachelorName} requested to book your room.',
        type: NotificationType.bookingRequest,
        senderUid: booking.bachelorUid,
        relatedId: booking.postId,
      );

      return docRef.id;
    } catch (e, stack) {
      AppLogger.e(
        'Failed to save booking request: $e',
        e,
        stack,
        'BOOKING_REPO',
      );
      throw 'Failed to save booking request: $e';
    }
  }

  // Stream booking status for a specific post & bachelor
  Stream<List<BookingModel>> getBookingStreamForPost(
    String postId,
    String bachelorUid,
  ) {
    return _firestore
        .collection(ApiConstants.bookingsCollection)
        .where('postId', isEqualTo: postId)
        .where('bachelorUid', isEqualTo: bachelorUid)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          bookings.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return bookings;
        });
  }

  // Stream pending bookings for Admin Dashboard
  Stream<List<BookingModel>> getPendingBookingsStream() {
    return _firestore
        .collection(ApiConstants.bookingsCollection)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .where((booking) => booking.paymentStatus == 'pending')
              .toList();
          bookings.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return bookings;
        });
  }

  // Stream ALL bookings (pending, approved, rejected) for Admin Dashboard
  Stream<List<BookingModel>> getAllBookingsStream() {
    return _firestore
        .collection(ApiConstants.bookingsCollection)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          bookings.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return bookings;
        });
  }

  // Stream all bookings for a specific bachelor (My Bookings screen)
  Stream<List<BookingModel>> getBookingsForBachelor(String bachelorUid) {
    return _firestore
        .collection(ApiConstants.bookingsCollection)
        .where('bachelorUid', isEqualTo: bachelorUid)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          bookings.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return bookings;
        });
  }

  // Stream all leads for a specific landlord
  Stream<List<BookingModel>> getLeadsForLandlord(String landlordUid) {
    return _firestore
        .collection(ApiConstants.bookingsCollection)
        .where('landlordUid', isEqualTo: landlordUid)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          bookings.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return bookings;
        });
  }

  // Stream all leads for a specific mess post
  Stream<List<BookingModel>> getLeadsForPost(String postId) {
    return _firestore
        .collection(ApiConstants.bookingsCollection)
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          bookings.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return bookings;
        });
  }

  // Approve a booking by Admin
  Future<void> approveBooking(String bookingId) async {
    try {
      final docSnapshot = await _firestore
          .collection(ApiConstants.bookingsCollection)
          .doc(bookingId)
          .get();
          
      await _firestore
          .collection(ApiConstants.bookingsCollection)
          .doc(bookingId)
          .update({'isUnlocked': true, 'paymentStatus': 'approved'});
          
      if (docSnapshot.exists) {
        final booking = BookingModel.fromMap(docSnapshot.data()!, docSnapshot.id);
        NotificationService().sendAndStore(
          receiverUid: booking.bachelorUid,
          title: 'Booking Approved! 🎉',
          body: 'Your payment was verified. You can now contact the landlord.',
          type: NotificationType.bookingApproved,
          relatedId: booking.postId,
        );
        NotificationService().sendAndStore(
          receiverUid: booking.landlordUid,
          title: 'Booking Payment Verified 💰',
          body: '${booking.bachelorName} has paid the booking fee. They might contact you soon.',
          type: NotificationType.paymentVerified,
          relatedId: booking.postId,
        );
      }
      
      AppLogger.s('Booking approved: $bookingId', tag: 'BOOKING_REPO');
    } catch (e) {
      throw 'Failed to approve booking: $e';
    }
  }

  // Reject a booking by Admin
  Future<void> rejectBooking(String bookingId) async {
    try {
      final docSnapshot = await _firestore
          .collection(ApiConstants.bookingsCollection)
          .doc(bookingId)
          .get();
          
      await _firestore
          .collection(ApiConstants.bookingsCollection)
          .doc(bookingId)
          .update({'isUnlocked': false, 'paymentStatus': 'rejected'});
          
      if (docSnapshot.exists) {
        final booking = BookingModel.fromMap(docSnapshot.data()!, docSnapshot.id);
        NotificationService().sendAndStore(
          receiverUid: booking.bachelorUid,
          title: 'Booking Rejected ❌',
          body: 'Your booking request was rejected or payment could not be verified.',
          type: NotificationType.bookingRejected,
          relatedId: booking.postId,
        );
      }
      
      AppLogger.s('Booking rejected: $bookingId', tag: 'BOOKING_REPO');
    } catch (e) {
      throw 'Failed to reject booking: $e';
    }
  }

  // Delete a booking (Landlord or Admin)
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore
          .collection(ApiConstants.bookingsCollection)
          .doc(bookingId)
          .delete();
      AppLogger.s('Booking deleted: $bookingId', tag: 'BOOKING_REPO');
    } catch (e) {
      throw 'Failed to delete booking: $e';
    }
  }

  // ─── Custom API Integration for Leads ──────────────────────────────────

  Future<List<BookingModel>> getLandlordLeadsFromApi(String landlordUid) async {
    try {
      final response = await _apiService.dio.get(ApiConstants.landlordLeads(landlordUid));
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) {
          // Since the API returns camelCase/snake_case mix depending on how we structured it,
          // BookingModel.fromMap should handle it. Wait, the API returns camelCase json keys based on our map
          return BookingModel.fromMap(json, json['bookingId']?.toString() ?? json['booking_id']?.toString() ?? '');
        }).toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('Failed to fetch landlord leads from API: $e', e, null, 'BOOKING_REPO');
      throw 'Failed to fetch leads: $e';
    }
  }

  Future<List<BookingModel>> getPostLeadsFromApi(String postId) async {
    try {
      final response = await _apiService.dio.get(ApiConstants.postLeads(postId));
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) {
          return BookingModel.fromMap(json, json['bookingId']?.toString() ?? json['booking_id']?.toString() ?? '');
        }).toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('Failed to fetch post leads from API: $e', e, null, 'BOOKING_REPO');
      throw 'Failed to fetch leads: $e';
    }
  }

  Future<void> approveBookingApi(String bookingId) async {
    try {
      await _apiService.dio.put(ApiConstants.bookingApprove(bookingId));
      AppLogger.s('Booking approved via API: $bookingId', tag: 'BOOKING_REPO');
    } catch (e) {
      throw 'Failed to approve booking via API: $e';
    }
  }

  Future<void> rejectBookingApi(String bookingId) async {
    try {
      await _apiService.dio.put(ApiConstants.bookingReject(bookingId));
      AppLogger.s('Booking rejected via API: $bookingId', tag: 'BOOKING_REPO');
    } catch (e) {
      throw 'Failed to reject booking via API: $e';
    }
  }

  Future<void> deleteBookingApi(String bookingId) async {
    try {
      await _apiService.dio.delete(ApiConstants.bookingDelete(bookingId));
      AppLogger.s('Booking deleted via API: $bookingId', tag: 'BOOKING_REPO');
    } catch (e) {
      throw 'Failed to delete booking via API: $e';
    }
  }
}
