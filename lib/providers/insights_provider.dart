import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/focus_session.dart';
import 'auth_provider.dart';

class InsightsData {
  final int focusStreak;
  final int totalMinutesThisWeek;
  final double averageRating;
  final int totalSessions;
  final int completedFocuses;

  InsightsData({
    required this.focusStreak,
    required this.totalMinutesThisWeek,
    required this.averageRating,
    required this.totalSessions,
    required this.completedFocuses,
  });
}

final insightsProvider = FutureProvider<InsightsData>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) {
    return InsightsData(
      focusStreak: 0,
      totalMinutesThisWeek: 0,
      averageRating: 0,
      totalSessions: 0,
      completedFocuses: 0,
    );
  }

  final db = FirebaseFirestore.instance;
  final userId = authState.uid;

  // Get all completed focuses
  final focusesSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('focuses')
      .where('status', isEqualTo: 'completed')
      .get();

  final completedFocuses = focusesSnapshot.docs.length;

  // Calculate streak
  final focusDates = focusesSnapshot.docs
      .map((doc) => (doc.data()['completedAt'] as Timestamp?)?.toDate())
      .where((date) => date != null)
      .cast<DateTime>()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  int streak = 0;
  if (focusDates.isNotEmpty) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    DateTime checkDate = todayDate;
    for (final date in focusDates) {
      final focusDate = DateTime(date.year, date.month, date.day);
      if (focusDate == checkDate || focusDate == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = focusDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
  }

  // Get all sessions from all focuses
  final allSessions = <FocusSession>[];
  for (final focusDoc in focusesSnapshot.docs) {
    final sessionsSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('focuses')
        .doc(focusDoc.id)
        .collection('sessions')
        .get();
    
    allSessions.addAll(
      sessionsSnapshot.docs.map((doc) => FocusSession.fromMap(doc.id, doc.data())),
    );
  }

  // Calculate this week's minutes
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
  
  final thisWeekSessions = allSessions.where((s) {
    final sessionDate = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
    return sessionDate.isAfter(weekStartDate.subtract(const Duration(days: 1)));
  }).toList();

  final totalMinutesThisWeek = thisWeekSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

  // Calculate average rating
  final sessionsWithRating = allSessions.where((s) => s.rating != null).toList();
  final averageRating = sessionsWithRating.isEmpty
      ? 0.0
      : sessionsWithRating.fold<int>(0, (sum, s) => sum + s.rating!) / sessionsWithRating.length;

  return InsightsData(
    focusStreak: streak,
    totalMinutesThisWeek: totalMinutesThisWeek,
    averageRating: averageRating,
    totalSessions: allSessions.length,
    completedFocuses: completedFocuses,
  );
});
