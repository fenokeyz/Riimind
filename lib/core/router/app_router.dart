import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/parser/models/parsed_event.dart';
import '../../features/parser/presentation/preview_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

/// App router with bottom navigation (StatefulShellRoute) for Home + Settings.
///
/// StatefulShellRoute preserves each tab's navigation state when switching
/// between them. This is the right shape for a bottom-nav app: the back stack
/// for Home and Settings is independent.
class AppRouter {
  AppRouter._();

  static const String homeRoute = '/';
  static const String settingsRoute = '/settings';
  static const String previewRoute = '/preview';

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'home');
  static final GlobalKey<NavigatorState> _settingsNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'settings');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: homeRoute,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RootScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: homeRoute,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: settingsRoute,
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Full-screen routes that overlay the bottom-nav shell.
      // Lives on the root navigator so it pushes above the shell.
      GoRoute(
        path: previewRoute,
        name: 'preview',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final event = state.extra as ParsedEvent?;
          return PreviewScreen(event: event);
        },
      ),
    ],
  );
}

/// Root scaffold that holds the bottom navigation and the current branch's
/// navigator. Each branch keeps its own back stack.
class RootScaffold extends StatelessWidget {
  const RootScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // When tapping the currently active tab, pop that branch to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
