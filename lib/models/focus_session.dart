class FocusSession {
  final String id;
  final String focusDateId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMinutes;
  final String status;
  final int? rating;
  final String? note;

  FocusSession({
    required this.id,
    required this.focusDateId,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.status,
    this.rating,
    this.note,
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
    );
  }
}
