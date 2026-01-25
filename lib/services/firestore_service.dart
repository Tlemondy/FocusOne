import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/focus_provider.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveDailyFocus(String userId, DailyFocus focus) async {
    try {
      final dateKey = _formatDate(focus.date);
      await _db.collection('users').doc(userId).collection('focuses').doc(dateKey).set({
        'title': focus.title,
        'reason': focus.reason,
        'date': Timestamp.fromDate(focus.date),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('FIRESTORE: Error saving focus: $e');
      rethrow;
    }
  }

  Future<DailyFocus?> getTodaysFocus(String userId) async {
    try {
      final dateKey = _formatDate(DateTime.now());
      final doc = await _db.collection('users').doc(userId).collection('focuses').doc(dateKey).get(); 
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return DailyFocus(
        title: data['title'],
        reason: data['reason'],
        date: (data['date'] as Timestamp).toDate(),
      );
    } catch (e) {
      log('FIRESTORE: Error getting focus: $e');
      return null;
    }
  }

  Future<void> deleteDailyFocus(String userId) async {
    try {
      final dateKey = _formatDate(DateTime.now());
      await _db.collection('users').doc(userId).collection('focuses').doc(dateKey).delete();
    } catch (e) {
      log('FIRESTORE: Error deleting focus: $e');
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
