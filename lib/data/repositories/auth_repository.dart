// WHAT THIS FILE DOES:
// Acts as a bridge between the raw Firebase Service and the UI.

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final FirebaseAuthService _service;

  AuthRepository(this._service);

  Future<Result<User?>> login(String email, String password) async {
    try {
      final credential = await _service.signIn(email, password);
      return Success(credential.user);
    } on FirebaseAuthException catch (e) {
      if (FirebaseAuth.instance.currentUser != null) {
        return Success(FirebaseAuth.instance.currentUser);
      }
      debugPrint('Firebase Auth Error Code: ${e.code}');
      return Failure(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      if (FirebaseAuth.instance.currentUser != null) {
        return Success(FirebaseAuth.instance.currentUser);
      }
      debugPrint('Generic Auth Error: $e');
      return const Failure(UnknownError('Connection error. Please check your network.'));
    }
  }

  Future<Result<User?>> register(String email, String password) async {
    try {
      final credential = await _service.signUp(email, password);
      return Success(credential.user);
    } on FirebaseAuthException catch (e) {
      if (FirebaseAuth.instance.currentUser != null) {
        return Success(FirebaseAuth.instance.currentUser);
      }
      debugPrint('Firebase Auth Error Code: ${e.code}');
      return Failure(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      if (FirebaseAuth.instance.currentUser != null) {
        return Success(FirebaseAuth.instance.currentUser);
      }
      debugPrint('Generic Auth Error: $e');
      return const Failure(UnknownError('Failed to create account. Please try again.'));
    }
  }

  Future<void> logout() => _service.signOut();

  Future<Result<void>> deleteAccount() async {
    try {
      await _service.deleteUser();
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return const Failure(AuthError('Please log out and log back in to delete your account.'));
      }
      return Failure(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'An account already exists with this email.';
      case 'weak-password': return 'Password is too weak.';
      case 'operation-not-allowed': return 'Email/Password login is not enabled in Firebase Console.';
      default: return 'Authentication failed: $code';
    }
  }
}
