import 'package:cloud_firestore/cloud_firestore.dart';

class SharedSessionParticipant {
  const SharedSessionParticipant({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.photoDataBase64,
    this.photoMimeType,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? photoDataBase64;
  final String? photoMimeType;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'photoDataBase64': photoDataBase64,
      'photoMimeType': photoMimeType,
    };
  }

  factory SharedSessionParticipant.fromMap(Map<String, dynamic> map) {
    return SharedSessionParticipant(
      uid: map['uid'] as String,
      displayName: (map['displayName'] as String?) ?? '',
      photoUrl: map['photoUrl'] as String?,
      photoDataBase64: map['photoDataBase64'] as String?,
      photoMimeType: map['photoMimeType'] as String?,
    );
  }
}

class SharedStudySession {
  const SharedStudySession({
    required this.id,
    required this.hostId,
    required this.hostFocusDateId,
    required this.focusTitle,
    this.focusReason,
    required this.durationMinutes,
    required this.status,
    required this.participantIds,
    required this.participants,
    required this.startedAt,
    required this.endsAt,
    this.endedAt,
    this.pausedRemainingSeconds,
    this.completedParticipantIds = const [],
  });

  final String id;
  final String hostId;
  final String hostFocusDateId;
  final String focusTitle;
  final String? focusReason;
  final int durationMinutes;
  final String status;
  final List<String> participantIds;
  final List<SharedSessionParticipant> participants;
  final DateTime startedAt;
  final DateTime endsAt;
  final DateTime? endedAt;
  final int? pausedRemainingSeconds;
  final List<String> completedParticipantIds;

  bool get isRunning => status == 'running';
  bool get isPaused => status == 'paused';
  bool get isCompleted => status == 'completed';

  int remainingSecondsAt(DateTime now) {
    if (isCompleted) return 0;
    if (isPaused && pausedRemainingSeconds != null) {
      return pausedRemainingSeconds!.clamp(0, durationMinutes * 60);
    }

    final remaining = endsAt.difference(now).inSeconds;
    return remaining.clamp(0, durationMinutes * 60);
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'hostFocusDateId': hostFocusDateId,
      'focusTitle': focusTitle,
      'focusReason': focusReason,
      'durationMinutes': durationMinutes,
      'status': status,
      'participantIds': participantIds,
      'participants': participants.map((p) => p.toMap()).toList(),
      'startedAt': Timestamp.fromDate(startedAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'endedAt': endedAt == null ? null : Timestamp.fromDate(endedAt!),
      'pausedRemainingSeconds': pausedRemainingSeconds,
      'completedParticipantIds': completedParticipantIds,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SharedStudySession.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final participantsData =
        (data['participants'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SharedSessionParticipant.fromMap)
            .toList();

    return SharedStudySession(
      id: id,
      hostId: data['hostId'] as String,
      hostFocusDateId: (data['hostFocusDateId'] as String?) ?? id,
      focusTitle: (data['focusTitle'] as String?) ?? '',
      focusReason: data['focusReason'] as String?,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 25,
      status: (data['status'] as String?) ?? 'running',
      participantIds: (data['participantIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      participants: participantsData,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (data['endsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      pausedRemainingSeconds: (data['pausedRemainingSeconds'] as num?)?.toInt(),
      completedParticipantIds:
          (data['completedParticipantIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
    );
  }
}

class SharedSessionNote {
  const SharedSessionNote({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.authorPhotoUrl,
    this.authorPhotoDataBase64,
    this.authorPhotoMimeType,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final String? authorPhotoUrl;
  final String? authorPhotoDataBase64;
  final String? authorPhotoMimeType;

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'authorPhotoDataBase64': authorPhotoDataBase64,
      'authorPhotoMimeType': authorPhotoMimeType,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SharedSessionNote.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return SharedSessionNote(
      id: id,
      authorId: (data['authorId'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      authorPhotoDataBase64: data['authorPhotoDataBase64'] as String?,
      authorPhotoMimeType: data['authorPhotoMimeType'] as String?,
    );
  }
}
