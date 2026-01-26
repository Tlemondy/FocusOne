import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/focus_session.dart';

class SessionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveSession(String userId, FocusSession session) async {
    try {
      log('SESSION SERVICE: Saving to path: users/$userId/focuses/${session.focusDateId}/sessions/${session.id}');
      log('SESSION SERVICE: Session data: ${session.toMap()}');
      
      await _db
          .collection('users')
          .doc(userId)
          .collection('focuses')
          .doc(session.focusDateId)
          .collection('sessions')
          .doc(session.id)
          .set(session.toMap());
      
      log('SESSION SERVICE: Save completed successfully');
    } catch (e, stackTrace) {
      log('SESSION SERVICE: Error saving session: $e');
      log('SESSION SERVICE: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<FocusSession>> getTodaySessions(String userId, String dateId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('focuses')
          .doc(dateId)
          .collection('sessions')
          .get();

      return snapshot.docs
          .map((doc) => FocusSession.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      log('SESSION SERVICE: Error getting sessions: $e');
      return [];
    }
  }

  Future<void> updateSessionNote(String userId, String focusDateId, String sessionId, String note) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('focuses')
          .doc(focusDateId)
          .collection('sessions')
          .doc(sessionId)
          .update({'note': note});
      log('SESSION SERVICE: Note updated successfully');
    } catch (e) {
      log('SESSION SERVICE: Error updating note: $e');
      rethrow;
    }
  }
}
