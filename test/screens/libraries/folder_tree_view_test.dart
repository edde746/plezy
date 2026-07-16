import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/libraries/folder_tree_view.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/backend_client_fixtures.dart';
import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  testWidgets('Jellyfin music artists and albums expand through direct children', (tester) async {
    final client = JellyfinClient.forTesting(
      connection: testJellyfinConnection(machineId: 'music-server'),
      httpClient: MockClient((request) async {
        final parentId = request.url.queryParameters['ParentId'];
        final foldersOnly = request.url.queryParameters['IncludeItemTypes'] == 'Folder,CollectionFolder';
        final items = foldersOnly
            ? const <Map<String, Object?>>[]
            : switch (parentId) {
                'music-library' => const [
                  {'Id': 'artist-1', 'Name': 'Artist One', 'Type': 'MusicArtist', 'IsFolder': true},
                ],
                'artist-1' => const [
                  {
                    'Id': 'album-1',
                    'Name': 'Album One',
                    'Type': 'MusicAlbum',
                    'IsFolder': true,
                    'AlbumArtists': [
                      {'Id': 'artist-1', 'Name': 'Artist One'},
                    ],
                  },
                ],
                'album-1' => const [
                  {'Id': 'track-1', 'Name': 'Track One', 'Type': 'Audio', 'AlbumId': 'album-1', 'Album': 'Album One'},
                ],
                _ => const <Map<String, Object?>>[],
              };
        return http.Response(
          jsonEncode({'Items': items, 'TotalRecordCount': items.length}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final provider = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(() {
      provider.dispose();
      manager.dispose();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>.value(
        value: provider,
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: CustomScrollView(
                slivers: const [
                  FolderTreeView(libraryKey: 'music-library', serverId: 'music-server', libraryKind: MediaKind.artist),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Artist One'), findsOneWidget);
    expect(find.text('Album One'), findsNothing);

    await tester.tap(find.text('Artist One'));
    await tester.pumpAndSettle();
    expect(find.text('Album One'), findsOneWidget);
    expect(find.text('Track One'), findsNothing);

    await tester.tap(find.text('Album One'));
    await tester.pumpAndSettle();
    expect(find.text('Track One'), findsOneWidget);
  });
}
