import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytestreak/domain/lesson_session.dart';
import 'package:bytestreak/screens/achievements/achievements_screen.dart';
import 'package:bytestreak/screens/auth/login_screen.dart';
import 'package:bytestreak/screens/auth/signup_details_screen.dart';
import 'package:bytestreak/screens/auth/signup_profile_screen.dart';
import 'package:bytestreak/screens/home/home_screen.dart';
import 'package:bytestreak/screens/leaderboard/leaderboard_screen.dart';
import 'package:bytestreak/screens/lesson/lesson_complete_screen.dart';
import 'package:bytestreak/screens/lesson/lesson_screen.dart';
import 'package:bytestreak/screens/lesson/quiz_intro_screen.dart';
import 'package:bytestreak/screens/onboarding/onboarding_screen.dart';
import 'package:bytestreak/screens/profile/profile_screen.dart';
import 'package:bytestreak/screens/settings/settings_screen.dart';
import 'package:bytestreak/screens/stats/stats_screen.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/widgets/app_shell.dart';

/// Routes, by address:
///
/// | Address               | Screen                                  |
/// |-----------------------|-----------------------------------------|
/// | /welcome              | 1.1 Onboarding                          |
/// | /signup, /signup/details | 1.2 and 1.2b Create profile          |
/// | /login                | 1.13 Log in                             |
/// | /home                 | 1.3 Home / LeetCode Mastery (in shell)  |
/// | /achievements         | 1.8 Achievements (in shell)             |
/// | /leaderboard          | 1.9 Leaderboard (in shell)              |
/// | /stats                | 1.10 Stats (in shell)                   |
/// | /settings             | 1.11 Settings (in shell)                |
/// | /profile              | 1.12 Profile (in shell)                 |
/// | /quiz/:id             | 1.4 Chapter quiz intro                  |
/// | /play/:id?mode=...    | 1.5 / 1.6 Questions (lesson runner)     |
/// | /practice             | Out-of-hearts practice (runner)         |
/// | /complete             | 1.14 Lesson complete                    |
///
/// Dialogs (1.7 Hints, 1.15 Out of hearts, 1.16 Badge detail, 1.17 Share)
/// open on top of these with `showDialog`, so they have no address.
final routerProvider = Provider<GoRouter>((ref) {
  // go_router re-runs `redirect` whenever this notifier changes, which is how
  // signing in or out moves you to the right screen automatically.
  final signedIn = ValueNotifier<bool>(ref.read(signedInProvider));
  ref.listen(signedInProvider, (_, next) => signedIn.value = next);
  ref.onDispose(signedIn.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: signedIn,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final public = loc == '/welcome' || loc.startsWith('/signup') || loc == '/login';
      if (!signedIn.value && !public) return '/welcome';
      if (signedIn.value && public) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', pageBuilder: (c, s) => _fade(s, const OnboardingScreen())),
      GoRoute(
        path: '/signup',
        pageBuilder: (c, s) => _fade(s, const SignupProfileScreen()),
        routes: [GoRoute(path: 'details', pageBuilder: (c, s) => _fade(s, const SignupDetailsScreen()))],
      ),
      GoRoute(path: '/login', pageBuilder: (c, s) => _fade(s, const LoginScreen())),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (c, s) => NoTransitionPage(
              key: s.pageKey,
              child: HomeScreen(focusChapterId: s.uri.queryParameters['chapter']),
            ),
          ),
          GoRoute(
            path: '/achievements',
            pageBuilder: (c, s) => const NoTransitionPage(child: AchievementsScreen()),
          ),
          GoRoute(
            path: '/leaderboard',
            pageBuilder: (c, s) => const NoTransitionPage(child: LeaderboardScreen()),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (c, s) => const NoTransitionPage(child: StatsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (c, s) => const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (c, s) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/quiz/:id',
        pageBuilder: (c, s) => _fade(s, QuizIntroScreen(lessonId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/play/:id',
        pageBuilder: (c, s) => _fade(
          s,
          LessonScreen(
            key: ValueKey(s.uri.toString()),
            lessonId: s.pathParameters['id'],
            mode: SessionMode.values.asNameMap()[s.uri.queryParameters['mode']] ?? SessionMode.lesson,
          ),
        ),
      ),
      GoRoute(
        path: '/practice',
        pageBuilder: (c, s) => _fade(s, const LessonScreen(lessonId: null, mode: SessionMode.practice)),
      ),
      GoRoute(path: '/complete', pageBuilder: (c, s) => _fade(s, const LessonCompleteScreen())),
    ],
  );
});

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
  );
}

/// Where a node on the path leads.
String routeForNode({required String lessonId, required bool isQuiz, required bool done}) {
  if (done) return '/play/$lessonId?mode=replay';
  if (isQuiz) return '/quiz/$lessonId';
  return '/play/$lessonId?mode=lesson';
}
