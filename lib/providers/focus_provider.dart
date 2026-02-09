import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

class DailyFocus {
  final String id;
  final String title;
  final String? reason;
  final DateTime date;

  DailyFocus({
    required this.id,
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
    return await service.getCurrentActiveFocus(authState.uid);
  }

  Future<void> setFocus(String title, String? reason) async {
    final authState = await ref.read(authStateProvider.future);
    if (authState == null) return;

    final focusId = DateTime.now().millisecondsSinceEpoch.toString();
    final focus = DailyFocus(
      id: focusId,
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

    final currentFocus = state.value;
    if (currentFocus == null) return;

    state = const AsyncValue.data(null);
    
    try {
      final service = ref.read(firestoreServiceProvider);
      await service.deleteDailyFocus(authState.uid, currentFocus.id);
    } catch (e) {
      log('FOCUS: Error deleting from Firestore: $e');
    }
  }

  void clearFocusFromUI() {
    state = const AsyncValue.data(null);
  }
}
