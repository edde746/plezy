import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/navigation/profile_navigation_scope.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/providers/seerr_session_provider.dart';
import 'package:provider/provider.dart';

Widget withProfileNavigationScope({required Widget child}) {
  // Production always mounts a SeerrSessionProvider above content screens (see
  // ProfileSessionScreen). MediaDetailScreen consumes it via
  // Consumer<SeerrSessionProvider>, so tests must supply one. A disconnected
  // instance backed by an in-memory database is enough: it never queries the
  // DB unless a profile is bound, and reports isConnected == false.
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  return ProfileNavigationScope(
    navigatorKey: GlobalKey<NavigatorState>(),
    routeObserver: RouteObserver<PageRoute<dynamic>>(),
    mainScaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
    child: ChangeNotifierProvider<SeerrSessionProvider>(
      create: (_) => SeerrSessionProvider(
        connectionRegistry: ConnectionRegistry(db),
        profileConnectionRegistry: ProfileConnectionRegistry(db),
      ),
      child: child,
    ),
  );
}
