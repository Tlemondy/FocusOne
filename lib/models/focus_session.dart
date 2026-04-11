class FocusSession {
  final String id;
  final String focusDateId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMinutes;
  final String status;
  final int? rating;
  final String? note;
  final bool isShared;
  final String? sharedSessionId;
  final List<String> participantIds;
  final List<String> participantNames;

  FocusSession({
    required this.id,
    required this.focusDateId,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.status,
    this.rating,
    this.note,
    this.isShared = false,
    this.sharedSessionId,
    this.participantIds = const [],
    this.participantNames = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'focusDateId': focusDateId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status,
      'rating': rating,
      'note': note,
      'isShared': isShared,
      'sharedSessionId': sharedSessionId,
      'participantIds': participantIds,
      'participantNames': participantNames,
    };
  }

  factory FocusSession.fromMap(String id, Map<String, dynamic> map) {
    return FocusSession(
      id: id,
      focusDateId: map['focusDateId'],
      startedAt: DateTime.parse(map['startedAt']),
      endedAt: DateTime.parse(map['endedAt']),
      durationMinutes: map['durationMinutes'],
      status: map['status'],
      rating: map['rating'],
      note: map['note'],
      isShared: map['isShared'] as bool? ?? false,
      sharedSessionId: map['sharedSessionId'] as String?,
      participantIds: (map['participantIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      participantNames: (map['participantNames'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}
