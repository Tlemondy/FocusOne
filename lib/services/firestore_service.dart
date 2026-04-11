import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_profile.dart';
import '../providers/focus_provider.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _log(String message) {
    log(message, name: 'PROFILE PHOTO FIRESTORE');
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _db.collection('users').doc(userId);
  }

  DocumentReference<Map<String, dynamic>> _profileDoc(String userId) {
    return _userDoc(userId).collection('profile').doc('data');
  }

  Future<void> syncUserProfile({
    required String userId,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      _log(
        'syncUserProfile start userId=$userId email=$email displayName=$displayName photoUrl=$photoUrl',
      );
      final data = <String, dynamic>{
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (photoUrl != null) {
        data['photoUrl'] = photoUrl;
      }

      await _profileDoc(userId).set(data, SetOptions(merge: true));
      _log('syncUserProfile complete userId=$userId');
    } catch (e) {
      _log('syncUserProfile error userId=$userId error=$e');
      rethrow;
    }
  }

  Stream<AppUserProfile?> watchUserProfile(String userId) {
    return _profileDoc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return AppUserProfile.fromFirestore(userId, snapshot.data()!);
    });
  }

  Future<AppUserProfile?> getUserProfile(String userId) async {
    try {
      final snapshot = await _profileDoc(userId).get();
      if (!snapshot.exists) return null;
      return AppUserProfile.fromFirestore(userId, snapshot.data()!);
    } catch (e) {
      log('FIRESTORE: Error getting user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfilePhoto(String userId, String? photoUrl) async {
    try {
      _log('updateUserProfilePhoto start userId=$userId photoUrl=$photoUrl');
      await _profileDoc(userId).set({
        'photoUrl': photoUrl,
        'photoDataBase64': null,
        'photoMimeType': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _log('updateUserProfilePhoto complete userId=$userId');
    } catch (e) {
      _log('updateUserProfilePhoto error userId=$userId error=$e');
      rethrow;
    }
  }

  Future<void> updateEmbeddedUserProfilePhoto(
    String userId, {
    required String photoDataBase64,
    required String photoMimeType,
  }) async {
    try {
      _log(
        'updateEmbeddedUserProfilePhoto start userId=$userId bytes=${photoDataBase64.length} mime=$photoMimeType',
      );
      await _profileDoc(userId).set({
        'photoUrl': null,
        'photoDataBase64': photoDataBase64,
        'photoMimeType': photoMimeType,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _log('updateEmbeddedUserProfilePhoto complete userId=$userId');
    } catch (e) {
      _log('updateEmbeddedUserProfilePhoto error userId=$userId error=$e');
      rethrow;
    }
  }

  Future<void> clearUserProfilePhoto(String userId) async {
    try {
      _log('clearUserProfilePhoto start userId=$userId');
      await _profileDoc(userId).set({
        'photoUrl': null,
        'photoDataBase64': null,
        'photoMimeType': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _log('clearUserProfilePhoto complete userId=$userId');
    } catch (e) {
      _log('clearUserProfilePhoto error userId=$userId error=$e');
      rethrow;
    }
  }

  Future<void> updateUserDisplayName(String userId, String displayName) async {
    try {
      await _profileDoc(userId).set({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      log('FIRESTORE: Error updating display name: $e');
      rethrow;
    }
  }

  Future<void> saveDailyFocus(String userId, DailyFocus focus) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('focuses')
          .doc(focus.id)
          .set({
            'title': focus.title,
            'reason': focus.reason,
            'date': Timestamp.fromDate(focus.date),
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });
    } catch (e) {
      log('FIRESTORE: Error saving focus: $e');
      rethrow;
    }
  }

  Future<DailyFocus?> getCurrentActiveFocus(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('focuses')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();

      return DailyFocus(
        id: doc.id,
        title: data['title'],
        reason: data['reason'],
        date: (data['date'] as Timestamp).toDate(),
      );
    } catch (e) {
      log('FIRESTORE: Error getting active focus: $e');
      return null;
    }
  }

  Future<void> markFocusCompleted(String userId, String focusId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('focuses')
          .doc(focusId)
          .update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      log('FIRESTORE: Error marking focus completed: $e');
      rethrow;
    }
  }

  Future<void> deleteDailyFocus(String userId, String focusId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('focuses')
          .doc(focusId)
          .delete();
    } catch (e) {
      log('FIRESTORE: Error deleting focus: $e');
      rethrow;
    }
  }

  Future<void> deleteCompletedFocus(String userId, String focusId) async {
    try {
      final sessionsRef = _db
          .collection('users')
          .doc(userId)
          .collection('focuses')
          .doc(focusId)
          .collection('sessions');

      final sessionsSnapshot = await sessionsRef.get();
      for (final doc in sessionsSnapshot.docs) {
        await doc.reference.delete();
      }

      await _db
          .collection('users')
          .doc(userId)
          .collection('focuses')
          .doc(focusId)
          .delete();
    } catch (e) {
      log('FIRESTORE: Error deleting completed focus: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCompletedFocuses(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('focuses')
          .where('status', isEqualTo: 'completed')
          .get();

      final focuses = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      focuses.sort((a, b) {
        final aTime = a['completedAt'] as Timestamp?;
        final bTime = b['completedAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return focuses;
    } catch (e) {
      log('FIRESTORE: Error getting completed focuses: $e');
      return [];
    }
  }
}
