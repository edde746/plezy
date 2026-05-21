import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/connection/connection.dart';
import 'package:vibe_stream/connection/connection_registry.dart';
import 'package:vibe_stream/database/app_database.dart';
import 'package:vibe_stream/focus/input_mode_tracker.dart';
import 'package:vibe_stream/i18n/strings.g.dart';
import 'package:vibe_stream/profiles/plex_home_service.dart';
import 'package:vibe_stream/profiles/profile.dart';
import 'package:vibe_stream/profiles/profile_connection.dart';
import 'package:vibe_stream/profiles/profile_connection_registry.dart';
import 'package:vibe_stream/profiles/profile_registry.dart';
import 'package:vibe_stream/screens/profile/profile_detail_screen.dart';
import 'package:vibe_stream/services/storage_service.dart';
import 'package:vibe_stream/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    TvDetectionService.debugSetAppleTVOverride(null);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('remote back pops the manage profile page', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final profile = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
    final profiles = ProfileRegistry(db);
    final connections = _FakeConnectionRegistry(db);
    final profileConnections = _FakeProfileConnectionRegistry(db);
    final storage = await StorageService.getInstance();
    final plexHome = PlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
      plexHomeUserFetcher: (_) async => const [],
    );
    addTearDown(() async {
      await plexHome.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            Provider<ProfileRegistry>.value(value: profiles),
            Provider<ProfileConnectionRegistry>.value(value: profileConnections),
            Provider<ConnectionRegistry>.value(value: connections),
            Provider<PlexHomeService>.value(value: plexHome),
          ],
          child: InputModeTracker(
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: profile)));
                      },
                      child: const Text('Open profile'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();
    expect(find.text(t.profiles.connectionsLabel), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pumpAndSettle();

    expect(find.text('Open profile'), findsOneWidget);
    expect(find.text(t.profiles.connectionsLabel), findsNothing);
  });
}

class _FakeConnectionRegistry extends ConnectionRegistry {
  _FakeConnectionRegistry(super.db);

  @override
  Future<List<Connection>> list() async => const [];
}

class _FakeProfileConnectionRegistry extends ProfileConnectionRegistry {
  _FakeProfileConnectionRegistry(super.db);

  @override
  Stream<List<ProfileConnection>> watchForProfile(String profileId) => Stream.value(const []);
}
