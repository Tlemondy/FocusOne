import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final authControllerProvider = NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> signIn(String email, String password) async {
    debugPrint('AUTH: Attempting sign in for: $email');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(email, password);
    });
    if (state.hasError) {
      debugPrint('AUTH: Sign in failed: ${state.error}');
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    debugPrint('AUTH: Attempting sign up for: $email');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(email, password, name);
    });
    if (state.hasError) {
      debugPrint('AUTH: Sign up failed: ${state.error}');
    }
  }

  Future<void> signOut() async {
    debugPrint('AUTH: Attempting sign out');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
    });
    if (state.hasError) {
      debugPrint('AUTH: Sign out failed: ${state.error}');
    }
  }
}
