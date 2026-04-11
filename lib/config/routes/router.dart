import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_motion.dart';

import '../../pages/tabs_base.dart';
import '../../pages/login/login_page.dart';
import '../../pages/register/register_page.dart';
import '../../pages/home/home_page.dart';
import '../../pages/history/history_page.dart';
import '../../pages/insights/insights_page.dart';
import '../../pages/friends/friends_page.dart';
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
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            _buildTransitionPage(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const RegisterPage(),
        ),
      ),
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      ShellRoute(
        builder: (context, state, child) => TabsBase(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HistoryPage()),
          ),
          GoRoute(
            path: '/insights',
            name: 'insights',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: InsightsPage()),
          ),
          GoRoute(
            path: '/friends',
            name: 'friends',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FriendsPage()),
          ),
          GoRoute(
            path: '/focus-detail/:dateId',
            name: 'focus-detail',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return _buildTransitionPage(
                key: state.pageKey,
                child: FocusDetailPage(
                  dateId: state.pathParameters['dateId']!,
                  title: extra['title'],
                  reason: extra['reason'],
                  date: extra['date'],
                ),
              );
            },
          ),
          GoRoute(
            path: '/note-viewer',
            name: 'note-viewer',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return _buildTransitionPage(
                key: state.pageKey,
                child: NoteViewerPage(
                  note: extra['note'],
                  sessionId: extra['sessionId'],
                  focusDateId: extra['focusDateId'],
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/focus-session',
        name: 'focus-session',
        pageBuilder: (context, state) {
          final extra = (state.extra as Map<String, dynamic>?) ?? const {};
          return _buildTransitionPage(
            key: state.pageKey,
            child: FocusSessionPage(
              focusTitle: (extra['title'] as String?) ?? '',
              focusReason: extra['reason'] as String?,
              focusDateId: (extra['dateId'] as String?) ?? '',
              sharedSessionId: extra['sharedSessionId'] as String?,
              preselectedFriendIds:
                  (extra['friendIds'] as List<dynamic>? ?? const [])
                      .whereType<String>()
                      .toList(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const SettingsPage(),
          horizontal: true,
        ),
      ),
      GoRoute(
        path: '/qr-scanner',
        name: 'qr-scanner',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const QRScannerPage(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(state.error.toString(), textAlign: TextAlign.center),
      ),
    ),
  );
});

CustomTransitionPage<void> _buildTransitionPage({
  required LocalKey key,
  required Widget child,
  bool horizontal = false,
}) {
  return CustomTransitionPage(
    key: key,
    transitionDuration: AppMotion.medium,
    reverseTransitionDuration: AppMotion.fast,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.emphasized,
        reverseCurve: AppMotion.exit,
      );
      final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
      final scale = Tween<double>(
        begin: horizontal ? 0.972 : 0.978,
        end: 1,
      ).animate(curved);

      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}
