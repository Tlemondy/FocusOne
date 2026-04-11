import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend_models.dart';
import 'auth_provider.dart';

final friendsProvider = StreamProvider<List<FriendConnection>>((ref) async* {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) {
    yield const [];
    return;
  }

  yield* ref.watch(authFriendServiceProvider).watchFriends(authState.uid);
});

final currentPublicProfileProvider = FutureProvider<PublicUserProfile?>((
  ref,
) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return null;
  return ref.watch(authFriendServiceProvider).getPublicProfile(authState.uid);
});
