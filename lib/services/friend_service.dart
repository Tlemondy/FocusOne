import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/friend_models.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _log(String message) {
    log(message, name: 'FRIEND SERVICE');
  }

  DocumentReference<Map<String, dynamic>> _publicProfileDoc(String userId) {
    return _db.collection('public_profiles').doc(userId);
  }

  CollectionReference<Map<String, dynamic>> _friendsCollection(String userId) {
    return _db.collection('users').doc(userId).collection('friends');
  }

  DocumentReference<Map<String, dynamic>> _friendDoc(
    String userId,
    String friendId,
  ) {
    return _friendsCollection(userId).doc(friendId);
  }

  Future<void> syncPublicProfile({
    required String userId,
    required String email,
    required String displayName,
    String? photoUrl,
    String? photoDataBase64,
    String? photoMimeType,
  }) async {
    _log('syncPublicProfile start userId=$userId email=$email');
    final snapshot = await _publicProfileDoc(userId).get();
    final data = <String, dynamic>{
      'displayName': displayName,
      'email': email,
      'emailLowercase': email.toLowerCase().trim(),
      'photoUrl': photoUrl,
      'photoDataBase64': photoDataBase64,
      'photoMimeType': photoMimeType,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data['stats'] = {
        'totalSessions': 0,
        'totalMinutes': 0,
        'completedSessions': 0,
        'ratingCount': 0,
        'ratingTotal': 0,
        'averageRating': 0,
      };
    }

    await _publicProfileDoc(userId).set(data, SetOptions(merge: true));
    _log(
      'syncPublicProfile complete userId=$userId existedBefore=${snapshot.exists}',
    );

    await syncFriendSnapshotToConnections(userId);
  }

  Future<void> recordSessionStats({
    required String userId,
    required int durationMinutes,
    required String status,
    int? rating,
  }) async {
    _log(
      'recordSessionStats start userId=$userId durationMinutes=$durationMinutes status=$status rating=$rating',
    );
    final statsIncrement = <String, dynamic>{
      'stats.totalSessions': FieldValue.increment(1),
      'stats.totalMinutes': FieldValue.increment(durationMinutes),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'completed') {
      statsIncrement['stats.completedSessions'] = FieldValue.increment(1);
    }

    if (rating != null) {
      statsIncrement['stats.ratingCount'] = FieldValue.increment(1);
      statsIncrement['stats.ratingTotal'] = FieldValue.increment(rating);
    }

    await _publicProfileDoc(
      userId,
    ).set(statsIncrement, SetOptions(merge: true));
    _log('recordSessionStats complete userId=$userId');
    await syncFriendSnapshotToConnections(userId);
  }

  Stream<List<FriendConnection>> watchFriends(String userId) {
    return _friendsCollection(userId)
        .orderBy('displayName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendConnection.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<PublicUserProfile?> findUserByEmail(String email) async {
    final normalized = email.toLowerCase().trim();
    _log('findUserByEmail start email=$email normalized=$normalized');
    if (normalized.isEmpty) return null;

    final snapshot = await _db
        .collection('public_profiles')
        .where('emailLowercase', isEqualTo: normalized)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    _log(
      'findUserByEmail complete normalized=$normalized foundUserId=${doc.id}',
    );
    return PublicUserProfile.fromFirestore(doc.id, doc.data());
  }

  Future<PublicUserProfile?> getPublicProfile(String userId) async {
    _log('getPublicProfile start userId=$userId path=public_profiles/$userId');
    final snapshot = await _publicProfileDoc(userId).get();
    _log('getPublicProfile complete userId=$userId exists=${snapshot.exists}');
    if (!snapshot.exists) return null;
    return PublicUserProfile.fromFirestore(userId, snapshot.data()!);
  }

  Future<void> addFriendByEmail({
    required String currentUserId,
    required String email,
  }) async {
    _log(
      'addFriendByEmail start currentUserId=$currentUserId email=$email currentPath=users/$currentUserId/friends',
    );
    final currentProfile = await getPublicProfile(currentUserId);
    if (currentProfile == null) {
      _log(
        'addFriendByEmail abort currentUserId=$currentUserId reason=noPublicProfile',
      );
      throw Exception('Your public profile is not ready yet.');
    }

    final targetProfile = await findUserByEmail(email);
    if (targetProfile == null) {
      _log(
        'addFriendByEmail abort currentUserId=$currentUserId email=$email reason=targetNotFound',
      );
      throw Exception('No account found for that email.');
    }
    if (targetProfile.uid == currentUserId) {
      _log(
        'addFriendByEmail abort currentUserId=$currentUserId reason=selfAdd',
      );
      throw Exception('You cannot add yourself.');
    }

    _log(
      'addFriendByEmail existingCheck path=users/$currentUserId/friends/${targetProfile.uid}',
    );
    final existing = await _friendDoc(currentUserId, targetProfile.uid).get();
    if (existing.exists) {
      _log(
        'addFriendByEmail abort currentUserId=$currentUserId targetUserId=${targetProfile.uid} reason=alreadyFriends',
      );
      throw Exception('This user is already your friend.');
    }

    final connectedAt = DateTime.now();
    final batch = _db.batch();
    _log(
      'addFriendByEmail batchSet currentPath=users/$currentUserId/friends/${targetProfile.uid} reciprocalPath=users/${targetProfile.uid}/friends/$currentUserId',
    );
    batch.set(
      _friendDoc(currentUserId, targetProfile.uid),
      FriendConnection.fromPublicProfile(
        targetProfile,
        connectedAt: connectedAt,
      ).toMap(),
    );
    batch.set(
      _friendDoc(targetProfile.uid, currentUserId),
      FriendConnection.fromPublicProfile(
        currentProfile,
        connectedAt: connectedAt,
      ).toMap(),
    );
    try {
      await batch.commit();
      _log(
        'addFriendByEmail complete currentUserId=$currentUserId targetUserId=${targetProfile.uid}',
      );
    } catch (e, stackTrace) {
      _log(
        'addFriendByEmail error currentUserId=$currentUserId email=$email targetUserId=${targetProfile.uid} error=$e',
      );
      _log('addFriendByEmail stackTrace=$stackTrace');
      rethrow;
    }
  }

  Future<void> removeFriend({
    required String currentUserId,
    required String friendId,
  }) async {
    _log(
      'removeFriend start currentUserId=$currentUserId friendId=$friendId currentPath=users/$currentUserId/friends/$friendId reciprocalPath=users/$friendId/friends/$currentUserId',
    );
    final batch = _db.batch();
    batch.delete(_friendDoc(currentUserId, friendId));
    batch.delete(_friendDoc(friendId, currentUserId));
    await batch.commit();
    _log(
      'removeFriend complete currentUserId=$currentUserId friendId=$friendId',
    );
  }

  Future<void> syncFriendSnapshotToConnections(String userId) async {
    try {
      _log('syncFriendSnapshotToConnections start userId=$userId');
      final publicProfile = await getPublicProfile(userId);
      if (publicProfile == null) return;

      final friendsSnapshot = await _friendsCollection(userId).get();
      _log(
        'syncFriendSnapshotToConnections friendsLoaded userId=$userId count=${friendsSnapshot.docs.length}',
      );
      if (friendsSnapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final friendDoc in friendsSnapshot.docs) {
        final connectedAt = (friendDoc.data()['connectedAt'] as Timestamp?)
            ?.toDate();
        batch.set(
          _friendDoc(friendDoc.id, userId),
          FriendConnection.fromPublicProfile(
            publicProfile,
            connectedAt: connectedAt,
          ).toMap(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      _log('syncFriendSnapshotToConnections complete userId=$userId');
    } catch (e, stackTrace) {
      _log('syncFriendSnapshotToConnections error userId=$userId error=$e');
      _log('syncFriendSnapshotToConnections stackTrace=$stackTrace');
    }
  }
}
