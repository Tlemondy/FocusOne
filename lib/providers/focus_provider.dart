import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

class DailyFocus {
  final String title;
  final String? reason;
  final DateTime date;

  DailyFocus({
    required this.title,
    this.reason,
    required this.date,
  });
}

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final dailyFocusProvider = AsyncNotifierProvider<DailyFocusNotifier, DailyFocus?>(DailyFocusNotifier.new);

class DailyFocusNotifier extends AsyncNotifier<DailyFocus?> {
  @override
  Future<DailyFocus?> build() async {
    final authState = await ref.watch(authStateProvider.future);
    if (authState == null) return null;
    
    final service = ref.read(firestoreServiceProvider);
    return await service.getTodaysFocus(authState.uid);
  }

  Future<void> setFocus(String title, String? reason) async {
    final authState = await ref.read(authStateProvider.future);
    if (authState == null) return;

    final focus = DailyFocus(
      title: title,
      reason: reason,
      date: DateTime.now(),
    );

    state = AsyncValue.data(focus);
    
    try {
      final service = ref.read(firestoreServiceProvider);
      await service.saveDailyFocus(authState.uid, focus);
    } catch (e) {
      log('FOCUS: Error saving to Firestore: $e');
    }
  }

  Future<void> deleteFocus() async {
    final authState = await ref.read(authStateProvider.future);
    if (authState == null) return;

    state = const AsyncValue.data(null);
    
    try {
      final service = ref.read(firestoreServiceProvider);
      await service.deleteDailyFocus(authState.uid);
    } catch (e) {
      log('FOCUS: Error deleting from Firestore: $e');
    }
  }
}
