import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/focus_provider.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveDailyFocus(String userId, DailyFocus focus) async {
    try {
      await _db.collection('users').doc(userId).collection('focuses').doc(focus.id).set({
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
      await _db.collection('users').doc(userId).collection('focuses').doc(focusId).update({
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
      await _db.collection('users').doc(userId).collection('focuses').doc(focusId).delete();
    } catch (e) {
      log('FIRESTORE: Error deleting focus: $e');
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
