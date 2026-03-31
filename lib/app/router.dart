import 'package:fish_tank_tracker/entry_detail/view/entry_detail_page.dart';
import 'package:fish_tank_tracker/gallery/view/gallery_page.dart';
import 'package:fish_tank_tracker/settings/view/settings_page.dart';
import 'package:fish_tank_tracker/water_log/view/water_log_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tank_repository/tank_repository.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app's router configuration.
GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/gallery',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gallery',
                builder: (context, state) => const GalleryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/water',
                builder: (context, state) => const WaterLogPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/gallery/:id',
        builder: (context, state) {
          final entry = state.extra! as TankEntry;
          final isNewEntry = state.uri.queryParameters['new'] == 'true';
          return EntryDetailPage(entry: entry, isNewEntry: isNewEntry);
        },
      ),
    ],
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Water',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
