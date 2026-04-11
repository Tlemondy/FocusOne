import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/focus_session.dart';
import '../models/friend_models.dart';
import '../models/shared_session.dart';
import 'friend_service.dart';

class SharedSessionService {
  SharedSessionService({FriendService? friendService})
    : _friendService = friendService ?? FriendService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FriendService _friendService;

  CollectionReference<Map<String, dynamic>> get _sharedSessions =>
      _db.collection('shared_sessions');

  DocumentReference<Map<String, dynamic>> _sharedSessionDoc(String sessionId) {
    return _sharedSessions.doc(sessionId);
  }

  CollectionReference<Map<String, dynamic>> _notesCollection(String sessionId) {
    return _sharedSessionDoc(sessionId).collection('notes');
  }

  Stream<List<SharedStudySession>> watchSessionsForUser(String userId) {
    return _sharedSessions
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        SharedStudySession.fromFirestore(doc.id, doc.data()),
                  )
                  .toList()
                ..sort((a, b) => b.startedAt.compareTo(a.startedAt)),
        );
  }

  Stream<SharedStudySession?> watchSession(String sessionId) {
    return _sharedSessionDoc(sessionId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return SharedStudySession.fromFirestore(sessionId, snapshot.data()!);
    });
  }

  Stream<List<SharedSessionNote>> watchNotes(String sessionId) {
    return _notesCollection(sessionId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SharedSessionNote.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> createSharedSession({
    required PublicUserProfile hostProfile,
    required List<FriendConnection> invitedFriends,
    required String focusTitle,
    required String? focusReason,
    required String hostFocusDateId,
    required int durationMinutes,
  }) async {
    final now = DateTime.now();
    final sessionId = now.microsecondsSinceEpoch.toString();
    final participants = <SharedSessionParticipant>[
      SharedSessionParticipant(
        uid: hostProfile.uid,
        displayName: hostProfile.displayName,
        photoUrl: hostProfile.photoUrl,
        photoDataBase64: hostProfile.photoDataBase64,
        photoMimeType: hostProfile.photoMimeType,
      ),
      ...invitedFriends.map(
        (friend) => SharedSessionParticipant(
          uid: friend.uid,
          displayName: friend.displayName,
          photoUrl: friend.photoUrl,
          photoDataBase64: friend.photoDataBase64,
          photoMimeType: friend.photoMimeType,
        ),
      ),
    ];

    final session = SharedStudySession(
      id: sessionId,
      hostId: hostProfile.uid,
      hostFocusDateId: hostFocusDateId,
      focusTitle: focusTitle,
      focusReason: focusReason,
      durationMinutes: durationMinutes,
      status: 'running',
      participantIds: participants.map((p) => p.uid).toList(),
      participants: participants,
      startedAt: now,
      endsAt: now.add(Duration(minutes: durationMinutes)),
    );

    await _sharedSessionDoc(
      sessionId,
    ).set({...session.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    return sessionId;
  }

  Future<void> pauseSession(SharedStudySession session) async {
    final remaining = session.remainingSecondsAt(DateTime.now());
    await _sharedSessionDoc(session.id).set({
      'status': 'paused',
      'pausedRemainingSeconds': remaining,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resumeSession(SharedStudySession session) async {
    final remaining =
        session.pausedRemainingSeconds ??
        session.remainingSecondsAt(DateTime.now());
    final now = DateTime.now();
    await _sharedSessionDoc(session.id).set({
      'status': 'running',
      'endsAt': Timestamp.fromDate(now.add(Duration(seconds: remaining))),
      'pausedRemainingSeconds': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> completeSessionForUser({
    required SharedStudySession session,
    required String userId,
    required String displayName,
    int? rating,
    String? privateNote,
  }) async {
    final now = DateTime.now();
    final remaining = session.remainingSecondsAt(now);
    final status = remaining == 0 ? 'completed' : 'ended_early';
    final durationCompleted = remaining == 0
        ? session.durationMinutes
        : ((session.durationMinutes * 60 - remaining) / 60).round().clamp(
            1,
            session.durationMinutes,
          );

    final focusId = userId == session.hostId
        ? session.hostFocusDateId
        : 'shared_${session.id}';

    await _db
        .collection('users')
        .doc(userId)
        .collection('focuses')
        .doc(focusId)
        .set({
          'title': session.focusTitle,
          'reason': session.focusReason,
          'date': Timestamp.fromDate(session.startedAt),
          'createdAt': Timestamp.fromDate(session.startedAt),
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'isShared': true,
          'sharedSessionId': session.id,
        }, SetOptions(merge: true));

    final personalSession = FocusSession(
      id: session.id,
      focusDateId: focusId,
      startedAt: session.startedAt,
      endedAt: now,
      durationMinutes: durationCompleted,
      status: status,
      rating: rating,
      note: privateNote,
      isShared: true,
      sharedSessionId: session.id,
      participantIds: session.participantIds,
      participantNames: session.participants.map((p) => p.displayName).toList(),
    );

    await _db
        .collection('users')
        .doc(userId)
        .collection('focuses')
        .doc(focusId)
        .collection('sessions')
        .doc(session.id)
        .set(personalSession.toMap(), SetOptions(merge: true));

    await _friendService.recordSessionStats(
      userId: userId,
      durationMinutes: durationCompleted,
      status: status,
      rating: rating,
    );

    await _sharedSessionDoc(session.id).set({
      'status': 'completed',
      'endedAt': FieldValue.serverTimestamp(),
      'completedParticipantIds': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addNote({
    required String sessionId,
    required String authorId,
    required String authorName,
    required String content,
    String? authorPhotoUrl,
    String? authorPhotoDataBase64,
    String? authorPhotoMimeType,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return;

    final noteId = DateTime.now().microsecondsSinceEpoch.toString();
    final note = SharedSessionNote(
      id: noteId,
      authorId: authorId,
      authorName: authorName,
      content: text,
      createdAt: DateTime.now(),
      authorPhotoUrl: authorPhotoUrl,
      authorPhotoDataBase64: authorPhotoDataBase64,
      authorPhotoMimeType: authorPhotoMimeType,
    );

    await _notesCollection(sessionId).doc(noteId).set(note.toMap());
  }
}
