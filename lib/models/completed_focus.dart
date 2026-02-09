class CompletedFocus {
  final String dateId;
  final String title;
  final String? reason;
  final DateTime date;
  final DateTime? completedAt;

  CompletedFocus({
    required this.dateId,
    required this.title,
    this.reason,
    required this.date,
    this.completedAt,
  });

  factory CompletedFocus.fromMap(String dateId, Map<String, dynamic> map) {
    return CompletedFocus(
      dateId: dateId,
      title: map['title'],
      reason: map['reason'],
      date: DateTime.parse(map['date'].toDate().toString()),
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt'].toDate().toString())
          : null,
    );
  }
}
