import 'dart:async';
import 'dart:collection';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/screens/profile/borrow_connection_screen.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('load failure has retry and remains distinct from successful empty state', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final connections = ConnectionRegistry(db);
    final profileConnections = ProfileConnectionRegistry(db);
    final profiles = ProfileRegistry(db);
    final storage = await StorageService.getInstance();
    final plexHome = _ControlledPlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
    );
    addTearDown(() async {
      await plexHome.dispose();
      await db.close();
    });

    final target = Profile.local(id: 'target', displayName: 'Target', createdAt: DateTime(2026));

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            Provider<ProfileConnectionRegistry>.value(value: profileConnections),
            Provider<ConnectionRegistry>.value(value: connections),
            Provider<ProfileRegistry>.value(value: profiles),
            Provider<PlexHomeService>.value(value: plexHome),
          ],
          child: InputModeTracker(
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: BorrowConnectionScreen(targetProfile: target),
            ),
          ),
        ),
      ),
    );

    expect(plexHome.hydrations, hasLength(1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    plexHome.hydrations.first.completeError(StateError('load failed'));
    await tester.pumpAndSettle();

    expect(find.text(t.profiles.borrowLoadFailed), findsOneWidget);
    expect(find.text(t.common.retry), findsOneWidget);
    expect(find.text(t.profiles.borrowEmpty), findsNothing);

    await tester.tap(find.text(t.common.retry));
    await tester.pump();

    expect(plexHome.hydrations, hasLength(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(t.profiles.borrowLoadFailed), findsNothing);

    plexHome.hydrations.last.complete();
    await tester.pumpAndSettle();

    expect(find.text(t.profiles.borrowEmpty), findsOneWidget);
    expect(find.text(t.profiles.borrowLoadFailed), findsNothing);
  });
}

class _ControlledPlexHomeService extends PlexHomeService {
  _ControlledPlexHomeService({required super.connections, required super.profileConnections, required super.storage});

  /// The picker reads `current` straight after awaiting, so it needs the disk
  /// cache only and deliberately does not start live refresh — gate the same
  /// call the screen makes.
  final Queue<Completer<void>> hydrations = Queue();

  @override
  Future<void> hydrate() {
    final completer = Completer<void>();
    hydrations.add(completer);
    return completer.future;
  }
}
