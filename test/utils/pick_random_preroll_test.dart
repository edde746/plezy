import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/utils/global_key_utils.dart';
import 'package:plezy/utils/preroll_service.dart';
import 'package:provider/provider.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/prefs.dart';

class _FakePrerollClient implements MediaServerClient {
  _FakePrerollClient({required this.serverId, this.libraries = const [], this.itemsByRatingKey = const {}});

  @override
  final ServerId serverId;
  @override
  final String serverName = 'Server';

  final List<MediaLibrary> libraries;
  final Map<String, MediaItem?> itemsByRatingKey;
  final List<String> fetchedRatingKeys = [];

  @override
  Future<List<MediaLibrary>> fetchLibraries() async => libraries;

  @override
  Future<MediaItem?> fetchItem(String id) async {
    fetchedRatingKeys.add(id);
    if (!itemsByRatingKey.containsKey(id)) return null;
    return itemsByRatingKey[id];
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  testWidgets('returns null when the only selected clip has been deleted', (tester) async {
    final serverId = ServerId('A');
    final library = MediaLibrary(id: '1', backend: MediaBackend.plex, title: 'Movies', kind: MediaKind.movie, serverId: serverId);
    final client = _FakePrerollClient(
      serverId: serverId,
      libraries: [library],
      itemsByRatingKey: {'stale-item': null},
    );
    final multiServer = testMultiServer(clients: [client]);
    final librariesProvider = LibrariesProvider()..initialize(DataAggregationService(multiServer.manager));
    await librariesProvider.loadLibraries();

    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.playPrerollsBeforeMovies, true);
    final storage = await StorageService.getInstance();
    await storage.savePrerollLibraryGlobalKey(library.globalKey);
    await storage.savePrerollSelectedItemKeys({buildGlobalKey(serverId, 'stale-item')});

    late BuildContext capturedContext;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServer.provider),
          ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
        ],
        child: MaterialApp(home: Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox();
        })),
      ),
    );

    final result = await pickRandomPreroll(capturedContext);

    expect(result, isNull);
    expect(client.fetchedRatingKeys, ['stale-item']);
  });

  testWidgets('falls through a stale key to a valid selected clip', (tester) async {
    final serverId = ServerId('A');
    final library = MediaLibrary(id: '1', backend: MediaBackend.plex, title: 'Movies', kind: MediaKind.movie, serverId: serverId);
    final bumper = testMediaItem(id: 'valid-item', kind: MediaKind.clip, title: 'Bumper');
    final client = _FakePrerollClient(
      serverId: serverId,
      libraries: [library],
      itemsByRatingKey: {'stale-item': null, 'valid-item': bumper},
    );
    final multiServer = testMultiServer(clients: [client]);
    final librariesProvider = LibrariesProvider()..initialize(DataAggregationService(multiServer.manager));
    await librariesProvider.loadLibraries();

    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.playPrerollsBeforeMovies, true);
    final storage = await StorageService.getInstance();
    await storage.savePrerollLibraryGlobalKey(library.globalKey);
    await storage.savePrerollSelectedItemKeys({
      buildGlobalKey(serverId, 'stale-item'),
      buildGlobalKey(serverId, 'valid-item'),
    });

    late BuildContext capturedContext;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServer.provider),
          ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
        ],
        child: MaterialApp(home: Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox();
        })),
      ),
    );

    final result = await pickRandomPreroll(capturedContext);

    expect(result?.id, 'valid-item');
  });
}