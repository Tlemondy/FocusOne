import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/focus_session.dart';
import '../services/session_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'focus_provider.dart';

final sessionServiceProvider = Provider((ref) => SessionService());

final activeSessionProvider = NotifierProvider<ActiveSessionNotifier, ActiveSessionState?>(
  ActiveSessionNotifier.new,
);

class ActiveSessionState {
  final String focusDateId;
  final DateTime startedAt;
  final int selectedDurationMinutes;
  final int remainingSeconds;
  final bool isRunning;
  final String sessionNote;

  ActiveSessionState({
    required this.focusDateId,
    required this.startedAt,
    required this.selectedDurationMinutes,
    required this.remainingSeconds,
    required this.isRunning,
    this.sessionNote = '',
  });

  ActiveSessionState copyWith({
    String? focusDateId,
    DateTime? startedAt,
    int? selectedDurationMinutes,
    int? remainingSeconds,
    bool? isRunning,
    String? sessionNote,
  }) {
    return ActiveSessionState(
      focusDateId: focusDateId ?? this.focusDateId,
      startedAt: startedAt ?? this.startedAt,
      selectedDurationMinutes: selectedDurationMinutes ?? this.selectedDurationMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      sessionNote: sessionNote ?? this.sessionNote,
    );
  }
}

class ActiveSessionNotifier extends Notifier<ActiveSessionState?> {
  Timer? _timer;

  @override
  ActiveSessionState? build() => null;

  void startSession(String focusDateId, int durationMinutes) {
    state = ActiveSessionState(
      focusDateId: focusDateId,
      startedAt: DateTime.now(),
      selectedDurationMinutes: durationMinutes,
      remainingSeconds: durationMinutes * 60,
      isRunning: true,
      sessionNote: '',
    );
    _startTimer();
  }

  void updateSessionNote(String note) {
    if (state != null) {
      state = state!.copyWith(sessionNote: note);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == null || !state!.isRunning) {
        timer.cancel();
        return;
      }

      final newRemaining = state!.remainingSeconds - 1;
      if (newRemaining <= 0) {
        timer.cancel();
        state = state!.copyWith(remainingSeconds: 0, isRunning: false);
      } else {
        state = state!.copyWith(remainingSeconds: newRemaining);
      }
    });
  }

  void pauseSession() {
    if (state != null) {
      _timer?.cancel();
      state = state!.copyWith(isRunning: false);
    }
  }

  void resumeSession() {
    if (state != null) {
      state = state!.copyWith(isRunning: true);
      _startTimer();
    }
  }

  Future<void> endSession({int? rating, String? note}) async {
    if (state == null) return;

    final endedAt = DateTime.now();
    final actualDuration = endedAt.difference(state!.startedAt).inMinutes;
    
    log('SESSION: Ending session - Duration: $actualDuration minutes');
    
    // Temporarily allow any duration for testing
    // if (actualDuration < 1) {
    //   log('SESSION: Session too short, discarding');
    //   clearSession();
    //   return;
    // }

    final session = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      focusDateId: state!.focusDateId,
      startedAt: state!.startedAt,
      endedAt: endedAt,
      durationMinutes: actualDuration == 0 ? 1 : actualDuration,
      status: state!.remainingSeconds == 0 ? 'completed' : 'ended_early',
      rating: rating,
      note: note,
    );

    log('SESSION: Saving session - ID: ${session.id}, DateID: ${session.focusDateId}');

    try {
      final authState = await ref.read(authStateProvider.future);
      if (authState != null) {
        log('SESSION: User ID: ${authState.uid}');
        final service = ref.read(sessionServiceProvider);
        await service.saveSession(authState.uid, session);
        log('SESSION: Session saved successfully');
        
        // Mark focus as completed
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.markFocusCompleted(authState.uid, state!.focusDateId);
        log('SESSION: Focus marked as completed');
        
        // Clear focus from home screen UI
        ref.read(dailyFocusProvider.notifier).clearFocusFromUI();
        log('SESSION: Focus cleared from home screen');
      } else {
        log('SESSION: No auth state found');
      }
    } catch (e, stackTrace) {
      log('SESSION: Error saving session: $e');
      log('SESSION: Stack trace: $stackTrace');
    }

    clearSession();
  }

  void clearSession() {
    _timer?.cancel();
    state = null;
  }
}
