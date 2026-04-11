import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _log(String message) {
    debugPrint('PROFILE PHOTO AUTH SERVICE: $message');
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint('AUTH SERVICE: Sign in successful for: $email');
    } catch (e, stackTrace) {
      debugPrint('AUTH SERVICE: Sign in error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      debugPrint('AUTH SERVICE: Sign up successful for: $email');
    } catch (e, stackTrace) {
      debugPrint('AUTH SERVICE: Sign up error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('AUTH SERVICE: Sign out successful');
    } catch (e, stackTrace) {
      debugPrint('AUTH SERVICE: Sign out error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateDisplayName(String name) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();
        debugPrint('AUTH SERVICE: Display name updated to: $name');
      }
    } catch (e, stackTrace) {
      debugPrint('AUTH SERVICE: Update display name error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updatePhotoURL(String? photoURL) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _log('updatePhotoURL start userId=${user.uid} photoUrl=$photoURL');
        await user.updatePhotoURL(photoURL);
        _log('updatePhotoURL complete userId=${user.uid}');
      } else {
        _log('updatePhotoURL skipped no current user');
      }
    } catch (e, stackTrace) {
      _log('updatePhotoURL error error=$e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
