import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shared_session.dart';
import '../services/shared_session_service.dart';
import 'auth_provider.dart';

final sharedSessionServiceProvider = Provider<SharedSessionService>(
  (ref) =>
      SharedSessionService(friendService: ref.watch(authFriendServiceProvider)),
);

final userSharedSessionsProvider = StreamProvider<List<SharedStudySession>>((
  ref,
) async* {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) {
    yield const [];
    return;
  }

  yield* ref
      .watch(sharedSessionServiceProvider)
      .watchSessionsForUser(authState.uid);
});

final activeSharedSessionsProvider = Provider<List<SharedStudySession>>((ref) {
  final sessions = ref.watch(userSharedSessionsProvider).value ?? const [];
  return sessions
      .where(
        (session) => session.status == 'running' || session.status == 'paused',
      )
      .toList();
});

final sharedSessionProvider =
    StreamProvider.family<SharedStudySession?, String>((ref, sessionId) {
      return ref.watch(sharedSessionServiceProvider).watchSession(sessionId);
    });

final sharedSessionNotesProvider =
    StreamProvider.family<List<SharedSessionNote>, String>((ref, sessionId) {
      return ref.watch(sharedSessionServiceProvider).watchNotes(sessionId);
    });
