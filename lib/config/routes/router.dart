import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../pages/tabs_base.dart';
import '../../pages/login/login_page.dart';
import '../../pages/register/register_page.dart';
import '../../pages/history/focus_detail_page.dart';
import '../../pages/history/note_viewer_page.dart';
import '../../pages/focus_session/focus_session_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../pages/friends/qr_scanner_page.dart';
import '../../providers/auth_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: Duration(milliseconds: 10),
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: Duration(milliseconds: 10),
          key: state.pageKey,
          child: const RegisterPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const TabsBase(),
        routes: [
          GoRoute(
            path: 'focus-detail/:dateId',
            name: 'focus-detail',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return CustomTransitionPage(
                key: state.pageKey,
                child: FocusDetailPage(
                  dateId: state.pathParameters['dateId']!,
                  title: extra['title'],
                  reason: extra['reason'],
                  date: extra['date'],
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
          ),
          GoRoute(
            path: 'focus-session',
            name: 'focus-session',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return CustomTransitionPage(
                key: state.pageKey,
                child: FocusSessionPage(
                  focusTitle: extra['title'],
                  focusReason: extra['reason'],
                  focusDateId: extra['dateId'],
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
          ),
          GoRoute(
            path: 'note-viewer',
            name: 'note-viewer',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return CustomTransitionPage(
                key: state.pageKey,
                child: NoteViewerPage(
                  note: extra['note'],
                  sessionId: extra['sessionId'],
                  focusDateId: extra['focusDateId'],
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
          ),
          GoRoute(
            path: 'insights',
            name: 'insights',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const TabsBase(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: 'qr-scanner',
            name: 'qr-scanner',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const QRScannerPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          state.error.toString(),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
});