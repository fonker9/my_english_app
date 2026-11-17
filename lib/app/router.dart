import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/features/auth/cubit/auth_cubit.dart';
import 'package:my_english_app/features/auth/cubit/auth_state.dart';
import 'package:my_english_app/features/auth/ui/login_screen.dart';
import 'package:my_english_app/features/auth/ui/register_screen.dart';
import 'package:my_english_app/features/dictionary/ui/dictionary_level_screen.dart';
import 'package:my_english_app/features/dictionary/ui/dictionary_main_screen.dart';
import 'package:my_english_app/features/learning/ui/swipe_screen.dart';
import 'package:my_english_app/features/main_tabs_screen.dart';
import 'package:my_english_app/features/profile/ui/profile_screen.dart';
import 'package:my_english_app/features/profile/ui/settings_screen.dart';

/// Адаптер потока состояний Cubit в [ChangeNotifier] для обновления [GoRouter].
class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Создаёт конфигурацию маршрутов приложения на базе [GoRouter].
GoRouter createAppRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: _GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final isLoggedIn = authCubit.state is AuthSuccess;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // --- Auth ---
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),

      // --- Main (Shell with Bottom Nav) ---
      ShellRoute(
        builder: (_, _, child) => MainTabsScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            // В Фазе 3 здесь будет подключён HomeScreen.
            builder: (_, _) => const SwipeScreen(),
          ),
          GoRoute(
            path: '/dictionary',
            builder: (_, _) => const DictionaryMainScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, _) => const ProfileScreen(),
          ),
        ],
      ),

      // --- Dictionary detail ---
      GoRoute(
        path: '/dictionary/:level',
        builder: (_, state) => DictionaryLevelScreen(
          level: Uri.decodeComponent(state.pathParameters['level']!),
        ),
      ),

      // --- Learning ---
      GoRoute(
        path: '/learning/swipe',
        builder: (_, _) => const SwipeScreen(),
      ),

      // --- Settings ---
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
  );
}
