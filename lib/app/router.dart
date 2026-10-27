import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/chapter/chapter_screen.dart';
import '../features/chapter/film_screen.dart';
import '../features/downloads/downloads_screen.dart';
import '../features/home/home_shell.dart';
import '../features/notices/notices_screen.dart';
import '../features/onboarding/intro_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/parental_dashboard/notices_settings_screen.dart';
import '../features/parental_dashboard/parent_gate_screen.dart';
import '../features/parental_dashboard/parent_screens.dart';
import '../features/play/section_screen.dart';
import '../features/profiles/profile_edit_screen.dart';
import '../features/profiles/profiles_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/workshop/tool_screen.dart';
import 'providers.dart';

/// مسیرهایی که فقط پس از دروازه‌ی والدین باز می‌شوند.
bool isProtected(String location) => (location == '/parent' || location.startsWith('/parent/') || location.startsWith('/settings'));

final routerProvider = Provider<GoRouter>((ref) {
  final gate = ValueNotifier<int>(0);
  ref.listen(parentGateProvider, (_, _) => gate.value++);
  ref.onDispose(gate.dispose);
  return buildRouter(ref, refresh: gate);
});

GoRouter buildRouter(Ref ref, {Listenable? refresh, String initialLocation = '/'}) {
  // کلید صفحه از نشانی کامل ساخته می‌شود؛ وگرنه رفتن از /world/home به /world/nature همان
  // صفحه‌ی قبلی را با وضعیت قبلی نگه می‌دارد (pageKey در go_router فقط الگوی مسیر است).
  CustomTransitionPage<void> page(GoRouterState s, Widget child) => CustomTransitionPage(
    key: ValueKey('page:${s.uri}'),
    child: KeyedSubtree(key: ValueKey(s.uri.toString()), child: child),
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, a, _, child) {
      if (MediaQuery.maybeDisableAnimationsOf(context) == true) return child;
      return FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: .97, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refresh,
    // خبرها روی دیالوگ یا برگه‌ی باز نمی‌آیند (NoticeHost).
    observers: [ref.read(popupWatcherProvider)],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (isProtected(loc) && !ref.read(parentGateProvider.notifier).isOpen) {
        return Uri(path: '/parent-gate', queryParameters: {'next': state.uri.toString()}).toString();
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', pageBuilder: (c, s) => page(s, const SplashScreen())),
      GoRoute(path: '/intro', pageBuilder: (c, s) => page(s, const IntroScreen())),
      GoRoute(path: '/profiles', pageBuilder: (c, s) => page(s, const ProfilesScreen())),
      GoRoute(
        path: '/home',
        pageBuilder: (c, s) => page(s, HomeShell(tab: s.uri.queryParameters['tab'])),
      ),
      GoRoute(
        path: '/chapter/:id',
        pageBuilder: (c, s) => page(s, ChapterScreen(chapterId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/play/:id',
        pageBuilder: (c, s) => page(s, SectionScreen(sectionId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/film/:id',
        pageBuilder: (c, s) => page(s, FilmScreen(chapterId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/tool/:id',
        pageBuilder: (c, s) => page(s, ToolScreen(toolId: s.pathParameters['id']!)),
      ),
      GoRoute(path: '/notices', pageBuilder: (c, s) => page(s, const NoticesScreen())),
      GoRoute(
        path: '/parent-gate',
        pageBuilder: (c, s) => page(
          s,
          ParentGateScreen(next: s.uri.queryParameters['next'] ?? '/parent', popOnSuccess: s.uri.queryParameters['mode'] == 'pop'),
        ),
      ),
      GoRoute(path: '/settings', pageBuilder: (c, s) => page(s, const SettingsScreen())),
      GoRoute(path: '/parent', pageBuilder: (c, s) => page(s, const ParentDashboardScreen())),
      GoRoute(path: '/parent/profiles', pageBuilder: (c, s) => page(s, const ManageProfilesScreen())),
      GoRoute(
        path: '/parent/profile/:id',
        pageBuilder: (c, s) => page(s, ProfileEditScreen(profileId: s.pathParameters['id']!)),
      ),
      GoRoute(path: '/parent/downloads', pageBuilder: (c, s) => page(s, const DownloadsScreen())),
      GoRoute(path: '/parent/history', pageBuilder: (c, s) => page(s, const HistoryScreen())),
      GoRoute(path: '/parent/usage', pageBuilder: (c, s) => page(s, const UsageScreen())),
      GoRoute(path: '/parent/privacy', pageBuilder: (c, s) => page(s, const PrivacyScreen())),
      GoRoute(path: '/parent/purchases', pageBuilder: (c, s) => page(s, const PurchasesScreen())),
      GoRoute(path: '/parent/storage', pageBuilder: (c, s) => page(s, const StorageScreen())),
      GoRoute(path: '/parent/notices', pageBuilder: (c, s) => page(s, const NoticesSettingsScreen())),
    ],
  );
}
