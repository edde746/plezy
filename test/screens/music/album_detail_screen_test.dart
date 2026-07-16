import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/music/album_detail_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/music/track_row.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';
import '../../test_helpers/media_items.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('renders header and track rows with disc headers for a multi-disc album', (tester) async {
    final harness = await _createHarness(_multiDiscTracks());

    await tester.pumpWidget(harness.wrap(const AlbumDetailScreen(album: _album)));
    await tester.pumpAndSettle();

    // Header: album title (app bar + header), tappable artist line, metadata.
    expect(find.text('Test Album'), findsWidgets);
    expect(find.text('Test Artist'), findsOneWidget);
    expect(find.textContaining('2001'), findsOneWidget);
    expect(find.textContaining(t.music.trackCount(n: 3)), findsOneWidget);

    // Track rows, grouped under per-disc headers.
    expect(find.byType(TrackRow), findsNWidgets(3));
    expect(find.text(t.music.discNumber(n: 1)), findsOneWidget);
    expect(find.text(t.music.discNumber(n: 2)), findsOneWidget);
    expect(find.text('Track One'), findsOneWidget);
    expect(find.text('Track Two'), findsOneWidget);
    expect(find.text('Track Three'), findsOneWidget);

    // Track numbers restart per disc.
    expect(find.text('1'), findsNWidgets(2));
  });

  testWidgets('tapping a track on the stub service shows the not-supported notice', (tester) async {
    final harness = await _createHarness(_multiDiscTracks());

    await tester.pumpWidget(harness.wrap(const AlbumDetailScreen(album: _album)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Track One'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(t.messages.musicNotSupported), findsOneWidget);
  });
}

const _album = MediaItem.plex(
  id: 'album_1',
  kind: MediaKind.album,
  title: 'Test Album',
  parentId: 'artist_1',
  parentTitle: 'Test Artist',
  year: 2001,
  serverId: 'server_1',
  serverName: 'Server',
);

List<MediaItem> _multiDiscTracks() {
  MediaItem track({required String id, required String title, required int disc, required int number}) {
    return testMediaItem(
      id: id,
      backend: MediaBackend.plex,
      kind: MediaKind.track,
      title: title,
      parentId: 'album_1',
      parentTitle: 'Test Album',
      grandparentId: 'artist_1',
      grandparentTitle: 'Test Artist',
      parentIndex: disc,
      index: number,
      durationMs: 200000,
      serverId: 'server_1',
      serverName: 'Server',
    );
  }

  return [
    track(id: 'track_1', title: 'Track One', disc: 1, number: 1),
    track(id: 'track_2', title: 'Track Two', disc: 1, number: 2),
    track(id: 'track_3', title: 'Track Three', disc: 2, number: 1),
  ];
}

Future<_AlbumHarness> _createHarness(List<MediaItem> tracks) async {
  await SettingsService.getInstance();

  final client = _FakeMusicClient(tracks);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));

  addTearDown(multiServerProvider.dispose);

  return _AlbumHarness(client: client, multiServerProvider: multiServerProvider);
}

class _AlbumHarness {
  final _FakeMusicClient client;
  final MultiServerProvider multiServerProvider;

  const _AlbumHarness({required this.client, required this.multiServerProvider});

  Widget wrap(Widget child) {
    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<MusicPlaybackService>(create: (_) => StubMusicPlaybackService()),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: SizedBox(width: 1280, height: 720, child: child),
        ),
      ),
    );
  }
}

class _FakeMusicClient implements MediaServerClient {
  final List<MediaItem> tracks;
  final List<String> fetchedAlbumIds = [];

  _FakeMusicClient(this.tracks);

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<List<MediaItem>> fetchAlbumTracks(String albumId) async {
    fetchedAlbumIds.add(albumId);
    return tracks;
  }

  @override
  String thumbnailUrl(String? path, {int? width, int? height}) => '';

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
