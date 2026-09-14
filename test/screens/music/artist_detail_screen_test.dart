import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/artist_discography.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/music/artist_detail_screen.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/stub_music_playback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  const artist = MediaItem.plex(
    id: 'artist_1',
    kind: MediaKind.artist,
    title: 'Test Artist',
    serverId: 'server_1',
    serverName: 'Server',
  );

  MediaItem album(String id) => MediaItem.plex(
    id: id,
    kind: MediaKind.album,
    title: id,
    parentId: 'artist_1',
    parentTitle: 'Test Artist',
    serverId: 'server_1',
    serverName: 'Server',
  );

  testWidgets('multiple groups render titled sections in order', (tester) async {
    // Tall viewport so every lazily-built section sliver is inside the
    // cache extent; the default 600px fits only the first two sections.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final harness = await _createHarness([
      ArtistDiscographyGroup(kind: DiscographyGroupKind.albums, items: [album('album-a1')]),
      ArtistDiscographyGroup(kind: DiscographyGroupKind.singlesAndEps, items: [album('album-s1')]),
      ArtistDiscographyGroup(kind: DiscographyGroupKind.live, items: [album('album-l1')]),
      ArtistDiscographyGroup(kind: DiscographyGroupKind.compilations, items: [album('album-c1')]),
    ]);

    await tester.pumpWidget(harness.wrap(const ArtistDetailScreen(artist: artist)));
    await tester.pumpAndSettle();

    expect(find.byType(FocusableMediaCard), findsNWidgets(4));
    final titles = ['Albums', 'Singles & EPs', 'Live', 'Compilations'];
    for (final title in titles) {
      expect(find.text(title), findsOneWidget);
    }
    final dy = [for (final title in titles) tester.getTopLeft(find.text(title)).dy];
    expect(dy, List.of(dy)..sort(), reason: 'sections must render in display order');
  });

  testWidgets('a single group renders the flat grid without section headers', (tester) async {
    final harness = await _createHarness([
      ArtistDiscographyGroup(kind: DiscographyGroupKind.albums, items: [album('album-a1'), album('album-a2')]),
    ]);

    await tester.pumpWidget(harness.wrap(const ArtistDetailScreen(artist: artist)));
    await tester.pumpAndSettle();

    expect(find.byType(FocusableMediaCard), findsNWidgets(2));
    expect(find.text('Albums'), findsNothing);
    expect(find.text('Singles & EPs'), findsNothing);
  });

  testWidgets('d-pad up from a later section enters the previous section grid', (tester) async {
    final harness = await _createHarness([
      ArtistDiscographyGroup(kind: DiscographyGroupKind.albums, items: [album('album-a1')]),
      ArtistDiscographyGroup(kind: DiscographyGroupKind.singlesAndEps, items: [album('album-s1')]),
    ]);

    await tester.pumpWidget(harness.wrap(const ArtistDetailScreen(artist: artist)));
    await tester.pumpAndSettle();

    final cards = find.byType(FocusableMediaCard);
    // Section 2's card: global index 1, its own focus node.
    tester.widget<FocusableMediaCard>(cards.at(1)).focusNode!.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail_grid_item_1');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail_first_item');

    // The first section's first row still exits the grid upward, landing on
    // the header action bar's play button — the flat screen's pre-existing
    // navigateToAppBar contract.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'music_play');
  });
}

Future<_ArtistHarness> _createHarness(List<ArtistDiscographyGroup> groups) async {
  await SettingsService.getInstance();

  final client = _FakeDiscographyClient(groups);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = testMultiServerProvider(manager);

  addTearDown(multiServerProvider.dispose);

  return _ArtistHarness(client: client, multiServerProvider: multiServerProvider);
}

class _ArtistHarness {
  final _FakeDiscographyClient client;
  final MultiServerProvider multiServerProvider;

  const _ArtistHarness({required this.client, required this.multiServerProvider});

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

class _FakeDiscographyClient implements MediaServerClient {
  final List<ArtistDiscographyGroup> groups;
  final List<String> fetchedArtistIds = [];

  _FakeDiscographyClient(this.groups);

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<List<ArtistDiscographyGroup>> fetchArtistDiscography(MediaItem artist) async {
    fetchedArtistIds.add(artist.id);
    return groups;
  }

  @override
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) => '';

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
