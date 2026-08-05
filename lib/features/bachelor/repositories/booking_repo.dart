import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new booking request
  Future<String> createBooking(BookingModel booking) async {
    try {
      AppLogger.i('Saving booking request (PostId: ${booking.postId})', tag: 'BOOKING_REPO');
      final docRef = _firestore.collection(ApiConstants.bookingsCollection).doc();
      final bookingWithId = booking.copyWith(bookingId: docRef.id);
      await docRef.set(bookingWithId.toMap());
      AppLogger.s('Booking request saved successfully', tag: 'BOOKING_REPO');
      return docRef.id;
    } catch (e, stack) {
      AppLogger.e('Failed to save booking request: $e', e, stack, 'BOOKING_REPO');
      throw 'Failed to save booking request: $e';
    }
  }

  // Stream booking status for a specific post & bachelor
  Stream<List<BookingModel>> getBookingStreamForPost(String postId, String bachelorUid) {
    return _firestore
        .collection(ApiConstants.bookingsCollection)
        .where('postId', isEqualTo: postId)
        .where('bachelorUid', isEqualTo: bachelorUid)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
      bookings.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
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
      bookings.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
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
      bookings.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
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
      bookings.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
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
      bookings.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
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
      bookings.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return bookings;
    });
  }

  // Approve a booking by Admin
  Future<void> approveBooking(String bookingId) async {
    try {
      await _firestore
          .collection(ApiConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'isUnlocked': true,
        'paymentStatus': 'approved',
      });
      AppLogger.s('Booking approved: $bookingId', tag: 'BOOKING_REPO');
    } catch (e) {
      throw 'Failed to approve booking: $e';
    }
  }

  // Reject a booking by Admin
  Future<void> rejectBooking(String bookingId) async {
    try {
      await _firestore
          .collection(ApiConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'isUnlocked': false,
        'paymentStatus': 'rejected',
      });
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
}
