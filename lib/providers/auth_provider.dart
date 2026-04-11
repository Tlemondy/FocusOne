import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/friend_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final authFirestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);
final authFriendServiceProvider = Provider<FriendService>(
  (ref) => FriendService(),
);

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  void _log(String message) {
    debugPrint('PROFILE PHOTO AUTH CONTROLLER: $message');
  }

  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> signIn(String email, String password) async {
    debugPrint('AUTH: Attempting sign in for: $email');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(email, password);
      final user = authService.currentUser;
      if (user != null) {
        final firestore = ref.read(authFirestoreServiceProvider);
        await firestore.syncUserProfile(
          userId: user.uid,
          email: user.email ?? email,
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL,
        );
        final profile = await firestore.getUserProfile(user.uid);
        await ref
            .read(authFriendServiceProvider)
            .syncPublicProfile(
              userId: user.uid,
              email: user.email ?? email,
              displayName: profile?.displayName ?? user.displayName ?? '',
              photoUrl: profile?.photoUrl ?? user.photoURL,
              photoDataBase64: profile?.photoDataBase64,
              photoMimeType: profile?.photoMimeType,
            );
      }
    });
    if (state.hasError) {
      debugPrint('AUTH: Sign in failed: ${state.error}');
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    debugPrint('AUTH: Attempting sign up for: $email');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(email, password, name);
      final user = authService.currentUser;
      if (user != null) {
        final firestore = ref.read(authFirestoreServiceProvider);
        await firestore.syncUserProfile(
          userId: user.uid,
          email: user.email ?? email,
          displayName: user.displayName ?? name,
          photoUrl: user.photoURL,
        );
        await ref
            .read(authFriendServiceProvider)
            .syncPublicProfile(
              userId: user.uid,
              email: user.email ?? email,
              displayName: user.displayName ?? name,
              photoUrl: user.photoURL,
            );
      }
    });
    if (state.hasError) {
      debugPrint('AUTH: Sign up failed: ${state.error}');
    }
  }

  Future<void> signOut() async {
    debugPrint('AUTH: Attempting sign out');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
    });
    if (state.hasError) {
      debugPrint('AUTH: Sign out failed: ${state.error}');
    }
  }

  Future<void> updateDisplayName(String name) async {
    debugPrint('AUTH: Updating display name to: $name');
    final authService = ref.read(authServiceProvider);
    await authService.updateDisplayName(name);
    final user = authService.currentUser;
    if (user != null) {
      final firestore = ref.read(authFirestoreServiceProvider);
      await firestore.updateUserDisplayName(user.uid, name);
      final profile = await firestore.getUserProfile(user.uid);
      await ref
          .read(authFriendServiceProvider)
          .syncPublicProfile(
            userId: user.uid,
            email: user.email ?? '',
            displayName: name,
            photoUrl: profile?.photoUrl ?? user.photoURL,
            photoDataBase64: profile?.photoDataBase64,
            photoMimeType: profile?.photoMimeType,
          );
    }
  }

  Future<void> updatePhotoURL(String? photoURL) async {
    _log('updatePhotoURL requested photoUrl=$photoURL');
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user != null) {
      _log('firestore photo update start userId=${user.uid}');
      await ref
          .read(authFirestoreServiceProvider)
          .updateUserProfilePhoto(user.uid, photoURL);
      _log('firestore photo update complete userId=${user.uid}');
      final profile = await ref
          .read(authFirestoreServiceProvider)
          .getUserProfile(user.uid);
      await ref
          .read(authFriendServiceProvider)
          .syncPublicProfile(
            userId: user.uid,
            email: user.email ?? '',
            displayName: profile?.displayName ?? user.displayName ?? '',
            photoUrl: photoURL,
            photoDataBase64: null,
            photoMimeType: null,
          );
      try {
        _log('auth photo update start userId=${user.uid}');
        await authService
            .updatePhotoURL(photoURL)
            .timeout(const Duration(seconds: 8));
        _log('auth photo update complete userId=${user.uid}');
      } catch (e) {
        _log(
          'auth photo update non-blocking failure userId=${user.uid} error=$e',
        );
      }
    } else {
      _log('updatePhotoURL skipped no current user');
    }
  }

  Future<void> updateEmbeddedProfilePhoto({
    required String photoDataBase64,
    required String photoMimeType,
  }) async {
    _log(
      'updateEmbeddedProfilePhoto requested bytes=${photoDataBase64.length} mime=$photoMimeType',
    );
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) {
      _log('updateEmbeddedProfilePhoto skipped no current user');
      return;
    }

    await ref
        .read(authFirestoreServiceProvider)
        .updateEmbeddedUserProfilePhoto(
          user.uid,
          photoDataBase64: photoDataBase64,
          photoMimeType: photoMimeType,
        );
    final profile = await ref
        .read(authFirestoreServiceProvider)
        .getUserProfile(user.uid);
    await ref
        .read(authFriendServiceProvider)
        .syncPublicProfile(
          userId: user.uid,
          email: user.email ?? '',
          displayName: profile?.displayName ?? user.displayName ?? '',
          photoUrl: null,
          photoDataBase64: photoDataBase64,
          photoMimeType: photoMimeType,
        );

    try {
      _log('embedded photo auth url clear start userId=${user.uid}');
      await authService
          .updatePhotoURL(null)
          .timeout(const Duration(seconds: 8));
      _log('embedded photo auth url clear complete userId=${user.uid}');
    } catch (e) {
      _log(
        'embedded photo auth url clear non-blocking failure userId=${user.uid} error=$e',
      );
    }
  }

  Future<void> clearProfilePhoto() async {
    _log('clearProfilePhoto requested');
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) {
      _log('clearProfilePhoto skipped no current user');
      return;
    }

    await ref
        .read(authFirestoreServiceProvider)
        .clearUserProfilePhoto(user.uid);
    final profile = await ref
        .read(authFirestoreServiceProvider)
        .getUserProfile(user.uid);
    await ref
        .read(authFriendServiceProvider)
        .syncPublicProfile(
          userId: user.uid,
          email: user.email ?? '',
          displayName: profile?.displayName ?? user.displayName ?? '',
          photoUrl: null,
          photoDataBase64: null,
          photoMimeType: null,
        );

    try {
      _log('clearProfilePhoto auth url clear start userId=${user.uid}');
      await authService
          .updatePhotoURL(null)
          .timeout(const Duration(seconds: 8));
      _log('clearProfilePhoto auth url clear complete userId=${user.uid}');
    } catch (e) {
      _log(
        'clearProfilePhoto auth url clear non-blocking failure userId=${user.uid} error=$e',
      );
    }
  }
}
