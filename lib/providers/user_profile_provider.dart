import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user_profile.dart';
import 'auth_provider.dart';

final userProfileProvider = StreamProvider<AppUserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final authUser = authState.value;

  if (authUser == null) {
    return Stream.value(null);
  }

  final firestore = ref.watch(authFirestoreServiceProvider);
  return firestore.watchUserProfile(authUser.uid);
});
