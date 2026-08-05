import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Submit a new payment request (status: pending)
  Future<void> submitPayment(PaymentModel payment) async {
    try {
      AppLogger.i('Submitting payment request to Firebase: ${payment.trxId}',
          tag: 'PAYMENT_REPO');
      // 1. TrxID Unique Constraint Check (fraud prevention)
      final duplicateQuery = await _firestore
          .collection(ApiConstants.paymentsCollection)
          .where('trxId', isEqualTo: payment.trxId.trim())
          .get();
      if (duplicateQuery.docs.isNotEmpty) {
        throw 'A payment request with this TrxID (${payment.trxId}) has already been submitted. Please enter a valid TrxID.';
      }

      await _firestore
          .collection(ApiConstants.paymentsCollection)
          .doc(payment.paymentId)
          .set(payment.toMap())
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw 'Timeout connecting to Firestore database! Please check if Firestore Database is created in Firebase Console.';
      });
      AppLogger.s('Payment saved successfully to Firebase: ${payment.paymentId}',
          tag: 'PAYMENT_REPO');
    } catch (e, stack) {
      AppLogger.e('Failed to submit payment request: $e', e, stack, 'PAYMENT_REPO');
      throw e.toString();
    }
  }

  // Activate user account (isPaid = true) upon verification
  Future<void> activateUserAccount(String userUid) async {
    try {
      AppLogger.i('Activating user account: $userUid', tag: 'PAYMENT_REPO');
      await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(userUid)
          .update({'isPaid': true});
      AppLogger.s('User account activated successfully', tag: 'PAYMENT_REPO');
    } catch (e, stack) {
      AppLogger.e('Error activating user account: $e', e, stack, 'PAYMENT_REPO');
    }
  }

  // Get user's latest payment request status, optionally filtered by role
  Future<PaymentModel?> getMyPaymentStatus(String userUid, {String? role}) async {
    try {
      AppLogger.i(
          'Checking payment status for user: $userUid${role != null ? " | Role: $role" : ""}',
          tag: 'PAYMENT_REPO');
      final query = await _firestore
          .collection(ApiConstants.paymentsCollection)
          .where('userUid', isEqualTo: userUid)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw 'Timeout fetching data from Firebase database';
      });

      if (query.docs.isNotEmpty) {
        // Map all docs to PaymentModel
        var payments = query.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList();

        // Filter by role in Dart (avoids Firestore composite index requirement)
        if (role != null) {
          payments = payments.where((p) => p.role == role).toList();
        }

        if (payments.isEmpty) {
          AppLogger.w('No payment record found for this role',
              tag: 'PAYMENT_REPO');
          return null;
        }

        // Sort by date descending (in-memory — no Firestore index needed)
        payments.sort((a, b) =>
            (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));

        final model = payments.first;
        AppLogger.s('Payment status retrieved: ${model.status}',
            tag: 'PAYMENT_REPO');
        return model;
      }
      AppLogger.w('No payment record found', tag: 'PAYMENT_REPO');
      return null;
    } catch (e, stack) {
      AppLogger.e('Failed to retrieve payment status: $e', e, stack, 'PAYMENT_REPO');
      throw 'Failed to retrieve payment status: $e';
    }
  }

  // Stream of all pending payments (For Admin Dashboard in Step 4)
  Stream<List<PaymentModel>> getAllPendingPayments() {
    AppLogger.i('Starting pending payments stream...', tag: 'PAYMENT_REPO');
    return _firestore
        .collection(ApiConstants.paymentsCollection)
        .where('status', isEqualTo: ApiConstants.statusPending)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
      AppLogger.i('Total pending requests found: ${list.length}',
          tag: 'PAYMENT_REPO');
      return list;
    });
  }

  // Stream of Approved payments
  Stream<List<PaymentModel>> getApprovedPayments() {
    return _firestore
        .collection(ApiConstants.paymentsCollection)
        .where('status', isEqualTo: ApiConstants.statusApproved)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Stream of Rejected payments
  Stream<List<PaymentModel>> getRejectedPayments() {
    return _firestore
        .collection(ApiConstants.paymentsCollection)
        .where('status', isEqualTo: ApiConstants.statusRejected)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Stream of All payments (for analytics/statistics)
  Stream<List<PaymentModel>> getAllPayments() {
    return _firestore
        .collection(ApiConstants.paymentsCollection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Admin approves or rejects payment
  Future<void> updatePaymentStatus({
    required String paymentId,
    required String userUid,
    required String newStatus,
  }) async {
    try {
      AppLogger.i(
          'Updating payment status -> ID: $paymentId | Status: $newStatus',
          tag: 'PAYMENT_REPO');
      final batch = _firestore.batch();
      final paymentRef = _firestore
          .collection(ApiConstants.paymentsCollection)
          .doc(paymentId);
      final userRef = _firestore
          .collection(ApiConstants.usersCollection)
          .doc(userUid);

      batch.update(paymentRef, {'status': newStatus});

      if (newStatus == ApiConstants.statusApproved) {
        batch.update(userRef, {'isPaid': true});
      }

      await batch.commit().timeout(const Duration(seconds: 10), onTimeout: () {
        throw 'Timeout updating Firebase database';
      });
      AppLogger.s('Payment status updated successfully: $newStatus',
          tag: 'PAYMENT_REPO');
    } catch (e, stack) {
      AppLogger.e('Failed to update payment status: $e', e, stack, 'PAYMENT_REPO');
      throw 'Failed to update payment status: $e';
    }
  }

  // Admin deletes payment and user record
  Future<void> deletePaymentRecord({
    required String paymentId,
    required String userUid,
  }) async {
    try {
      AppLogger.w(
          'Deleting payment and user record -> PaymentID: $paymentId | UserID: $userUid',
          tag: 'PAYMENT_REPO');
      final batch = _firestore.batch();
      final paymentRef = _firestore
          .collection(ApiConstants.paymentsCollection)
          .doc(paymentId);
      final userRef =
          _firestore.collection(ApiConstants.usersCollection).doc(userUid);

      batch.delete(paymentRef);
      if (userUid.isNotEmpty) {
        batch.delete(userRef);
      }

      await batch.commit().timeout(const Duration(seconds: 10), onTimeout: () {
        throw 'Timeout updating Firebase database';
      });
      AppLogger.s('Record deleted successfully', tag: 'PAYMENT_REPO');
    } catch (e, stack) {
      AppLogger.e('Failed to delete record: $e', e, stack, 'PAYMENT_REPO');
      throw 'Failed to delete record: $e';
    }
  }

  // Consume payment token (Pay-per-post / Pay-per-booking)
  // Every time a user posts an ad OR confirms a booking, this consumes their approved status so they must pay again for the next post/booking!
  Future<void> consumeUserPaymentToken(String userUid) async {
    try {
      AppLogger.i('Consuming payment token -> UserID: $userUid',
          tag: 'PAYMENT_REPO');
      await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(userUid)
          .update({'isPaid': false});
      AppLogger.s('Payment token consumed successfully (isPaid -> false)',
          tag: 'PAYMENT_REPO');
    } catch (e, stack) {
      AppLogger.e('Failed to consume payment token: $e', e, stack, 'PAYMENT_REPO');
    }
  }
}

