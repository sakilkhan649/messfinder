import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../models/user_model.dart';

class AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Sign Up with Email and Password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.i('Starting account registration -> Email: $email',
          tag: 'AUTH_REPO');
      final credential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      )
          .timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          throw 'Registration timeout! No response from Firebase server. Please disable "Email enumeration protection" in Firebase Console > Authentication > Settings > User actions.';
        },
      );
      AppLogger.s(
          'Registration successful -> UserID: ${credential.user?.uid}',
          tag: 'AUTH_REPO');
      return credential;
    } on FirebaseAuthException catch (e, stack) {
      AppLogger.e('FirebaseAuthException (SignUp): ${e.code} | ${e.message}', e,
          stack, 'AUTH_REPO');
      if (e.code == 'configuration-not-found' ||
          e.code == 'operation-not-allowed' ||
          (e.message ?? '').contains('CONFIGURATION_NOT_FOUND')) {
        throw 'Email/Password login is not enabled in Firebase Console! Please enable it under Firebase Console > Authentication > Sign-in method.';
      }
      if (e.code == 'email-already-in-use') {
        throw 'An account already exists with this email address.';
      }
      if (e.code == 'weak-password') {
        throw 'Password is too weak. Please use at least 6 characters.';
      }
      throw e.message ?? 'Registration failed';
    } catch (e, stack) {
      AppLogger.e('Registration failed: $e', e, stack, 'AUTH_REPO');
      if (e.toString().contains('CONFIGURATION_NOT_FOUND') ||
          e.toString().contains('operation-not-allowed')) {
        throw 'Email/Password login is not enabled in Firebase Console! Please enable it under Firebase Console > Authentication > Sign-in method.';
      }
      throw e.toString();
    }
  }

  // Login with Email and Password
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.i('Attempting login -> Email: $email',
          tag: 'AUTH_REPO');
      final credential = await _auth
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw 'Login timeout! Please check your internet connection.',
          );
      AppLogger.s('Login successful -> UserID: ${credential.user?.uid}',
          tag: 'AUTH_REPO');
      return credential;
    } on FirebaseAuthException catch (e, stack) {
      AppLogger.e('FirebaseAuthException (Login): ${e.code} | ${e.message}', e,
          stack, 'AUTH_REPO');
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        throw 'Invalid email or password. Please try again.';
      }
      throw e.message ?? 'Login failed';
    } catch (e, stack) {
      AppLogger.e('Login failed: $e', e, stack, 'AUTH_REPO');
      throw e.toString();
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AppLogger.i('Sending password reset email -> $email',
          tag: 'AUTH_REPO');
      await _auth
          .sendPasswordResetEmail(email: email)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw 'Timeout sending reset link. Please check your internet connection.',
          );
      AppLogger.s('Password reset email sent', tag: 'AUTH_REPO');
    } on FirebaseAuthException catch (e, stack) {
      AppLogger.e('Reset email failed: ${e.message}', e, stack, 'AUTH_REPO');
      if (e.code == 'user-not-found') {
        throw 'No account found with this email address.';
      }
      if (e.code == 'invalid-email') {
        throw 'Invalid email address format.';
      }
      throw e.message ?? 'Failed to send password reset link';
    } catch (e, stack) {
      AppLogger.e('Reset email failed: $e', e, stack, 'AUTH_REPO');
      throw 'Failed to send password reset link: $e';
    }
  }

  // Save user details to Firestore 'users' collection
  Future<void> saveUserData(UserModel user) async {
    try {
      AppLogger.i('Saving user data to Firestore: ${user.uid}',
          tag: 'AUTH_REPO');
      await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw 'Timeout connecting to Firestore. Please check if Firestore Database is created in Firebase Console.',
          );
      AppLogger.s('User data saved successfully', tag: 'AUTH_REPO');
    } catch (e, stack) {
      AppLogger.e(
          'Failed to save user data: $e', e, stack, 'AUTH_REPO');
      throw 'Failed to save user data: $e';
    }
  }

  // Fetch current user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      AppLogger.i('Fetching user data from Firestore: $uid',
          tag: 'AUTH_REPO');
      final doc = await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw 'Timeout fetching user data. Please check your internet connection.',
          );
      if (doc.exists && doc.data() != null) {
        AppLogger.s('User data retrieved -> Role: ${doc.data()!['role']}',
            tag: 'AUTH_REPO');
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      AppLogger.w('No user data found in Firestore',
          tag: 'AUTH_REPO');
      return null;
    } catch (e, stack) {
      AppLogger.e('Error fetching user data: $e', e, stack, 'AUTH_REPO');
      throw 'Failed to retrieve user data: $e';
    }
  }

  // Check if a user is already logged in
  User? get currentFirebaseUser => _auth.currentUser;

  // Sign out
  Future<void> logout() async {
    try {
      AppLogger.i('Logging out...', tag: 'AUTH_REPO');
      await _auth.signOut();
      AppLogger.s('Logout completed', tag: 'AUTH_REPO');
    } catch (e, stack) {
      AppLogger.e('Error logging out: $e', e, stack, 'AUTH_REPO');
    }
  }
}
