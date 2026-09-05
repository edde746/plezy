import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_rating.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/models/catalog/catalog_cast_member.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/catalog_item_detail_screen.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/catalog_library_matcher.dart';
import 'package:plezy/services/catalog/seerr_catalog_source.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/hub_section.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/optimized_media_image.dart';
import 'package:provider/provider.dart';

import '../test_helpers/library_lookup.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/prefs.dart';

class _FakeCatalogSource implements CatalogSource {
  final WatchlistChangeNotifier _watchlistChanges = WatchlistChangeNotifier();
  _FakeCatalogSource({
    bool watchlistLoading = false,
    this.supportsWatchlist = true,
    this.detail,
    this.detailError,
    this.detailCompleter,
  }) : _watchlistValue = watchlistLoading ? null : false,
       _watchlistLoad = watchlistLoading ? Completer<void>() : null;

  bool? _watchlistValue;
  final Completer<void>? _watchlistLoad;
  int addToWatchlistCalls = 0;

  final CatalogDetail? detail;
  final Object? detailError;
  final Completer<CatalogDetail>? detailCompleter;
  int fetchDetailCalls = 0;
  @override
  CatalogSourceId get id => CatalogSourceId.trakt;

  @override
  String get displayName => 'Trakt';

  @override
  final bool supportsWatchlist;

  @override
  Listenable get watchlistChanges => _watchlistChanges;

  @override
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20}) async {
    fetchDetailCalls++;
    final completer = detailCompleter;
    if (completer != null) return completer.future;
    final error = detailError;
    if (error != null) throw error;
    return detail ??
        CatalogDetail(
          item: item,
          cast: const [
            CatalogCastMember(name: 'First Actor', secondary: 'Lead'),
            CatalogCastMember(name: 'Second Actor', secondary: 'Support'),
          ],
          related: const [
            CatalogItem(
              source: CatalogSourceId.trakt,
              kind: MediaKind.movie,
              title: 'Related Movie',
              ids: CatalogItemIds(tmdb: 2),
            ),
          ],
        );
  }

  @override
  Future<void> ensureWatchlistLoaded() async {
    final load = _watchlistLoad;
    if (load != null) await load.future;
  }

  void completeWatchlistLoad() {
    _watchlistValue = false;
    _watchlistChanges.notify();
    _watchlistLoad!.complete();
  }

  @override
  Future<void> addToWatchlist(MediaKind kind, CatalogItemIds ids) async {
    addToWatchlistCalls++;
    _watchlistValue = true;
    _watchlistChanges.notify();
  }

  @override
  bool? isOnWatchlist(MediaKind kind, CatalogItemIds ids) => _watchlistValue;

  @override
  void dispose() => _watchlistChanges.dispose();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCatalogSourcesProvider extends CatalogSourcesProvider {
  final CatalogSource source;
  final SeerrCatalogSource? seerr;

  _FakeCatalogSourcesProvider(this.source, {this.seerr});

  @override
  List<CatalogSource> get connectedSources => [source, ?seerr];

  @override
  SeerrCatalogSource? get seerrSource => seerr;
}

/// A real [SeerrCatalogSource]: the Request gate reads the session's
/// permission bitmask through [SeerrCatalogSource.canRequest]. None of these
/// tests open the request sheet, so no Seerr HTTP is expected.
SeerrCatalogSource _seerrSource({int permissions = SeerrPermission.request}) {
  final client = SeerrClient(
    SeerrSession(
      baseUrl: 'https://seerr.example.com',
      method: SeerrAuthMethod.local,
      identifier: 'a@b.c',
      secret: 'pw',
      cookie: 'cookie',
      userId: 1,
      permissions: permissions,
      displayName: 'Alice',
      instanceLabel: 'Seerr',
      createdAt: 0,
    ),
    onSessionInvalidated: () {},
    httpClient: MockClient((request) async => http.Response('unexpected Seerr request', 500)),
  );
  final source = SeerrCatalogSource(client);
  addTearDown(() {
    source.dispose();
    client.dispose();
  });
  return source;
}

class _FakeCatalogLibraryMatcher extends CatalogLibraryMatcher {
  _FakeCatalogLibraryMatcher(super.multiServer, this.matches);

  final List<MediaItem> matches;

  @override
  Future<LibraryLookupResult> match(CatalogItem item) async => libraryLookupResult(matches);
}

/// Matches only items that carry an external id, the way a real lookup for a
/// Plex Discover row does (#1715): the bare rating-key form misses, the
/// detail-enriched form hits.
class _ExternalIdGatedMatcher extends CatalogLibraryMatcher {
  _ExternalIdGatedMatcher(super.multiServer, this.hit);

  final MediaItem hit;
  final List<CatalogItem> calls = [];

  @override
  Future<LibraryLookupResult> match(CatalogItem item) async {
    calls.add(item);
    return libraryLookupResult(item.ids.toExternalIds().hasAny ? [hit] : const []);
  }
}

/// Serves one scripted result per `match` call, so a test can model the bare
/// row lookup and the detail-enriched lookup independently.
class _ScriptedMatcher extends CatalogLibraryMatcher {
  _ScriptedMatcher(super.multiServer, this.passes);

  final List<LibraryLookupResult Function()> passes;
  int calls = 0;

  @override
  Future<LibraryLookupResult> match(CatalogItem item) async {
    final pass = passes[calls < passes.length ? calls : passes.length - 1];
    calls++;
    return pass();
  }
}

/// A Plex Discover row whose bare form carries only its own id; the detail
/// body adds the external ids (#1715), which is what triggers a second pass.
const _bareRow = CatalogItem(
  source: CatalogSourceId.trakt,
  kind: MediaKind.movie,
  title: 'Row-only Movie',
  ids: CatalogItemIds(trakt: 5),
);
const _enrichedRow = CatalogItem(
  source: CatalogSourceId.trakt,
  kind: MediaKind.movie,
  title: 'Row-only Movie',
  ids: CatalogItemIds(trakt: 5, tmdb: 99),
);

MediaItem _libraryCopy({
  required String id,
  String? libraryTitle,
  String? videoResolution,
  String? serverName = 'Living Room',
}) => testMediaItem(
  id: id,
  serverId: 'server-1',
  serverName: serverName,
  libraryId: libraryTitle == null ? null : id,
  libraryTitle: libraryTitle,
  mediaVersions: videoResolution == null
      ? null
      : [MediaVersion(id: '$id-v', videoResolution: videoResolution, videoCodec: 'hevc', container: 'mkv')],
);

const _item = CatalogItem(
  source: CatalogSourceId.trakt,
  kind: MediaKind.movie,
  title: 'Catalog Movie',
  overview: 'Overview',
  ids: CatalogItemIds(tmdb: 1),
);

Future<void> _pumpDetail(
  WidgetTester tester,
  _FakeCatalogSource source, {
  List<MediaItem> matches = const [],
  bool pushedRoute = false,
  CatalogItem item = _item,
  CatalogLibraryMatcher Function(MultiServerProvider multiServer)? matcherBuilder,
  SeerrCatalogSource? seerr,
}) async {
  final sources = _FakeCatalogSourcesProvider(source, seerr: seerr);
  final serverManager = MultiServerManager();
  final multiServer = testMultiServerProvider(serverManager);
  final matcher = matcherBuilder?.call(multiServer) ?? _FakeCatalogLibraryMatcher(multiServer, matches);
  addTearDown(sources.dispose);
  addTearDown(source.dispose);
  addTearDown(serverManager.dispose);
  addTearDown(multiServer.dispose);

  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          Provider<CatalogLibraryMatcher>.value(value: matcher),
          ChangeNotifierProvider<CatalogSourcesProvider>.value(value: sources),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: pushedRoute
              ? Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute<void>(builder: (_) => CatalogItemDetailScreen(item: item))),
                      child: const Text('Open catalog'),
                    ),
                  ),
                )
              : CatalogItemDetailScreen(item: item),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (pushedRoute) {
    await tester.tap(find.text('Open catalog'));
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    // The facts section formats dates; `main.dart` does this at startup.
    await initializeDateFormatting('en');
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    TvDetectionService.debugSetAppleTVOverride(true);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('fetchDetail replaces the opening item with its enriched item once loaded', (tester) async {
    final detailCompleter = Completer<CatalogDetail>();
    final source = _FakeCatalogSource(detailCompleter: detailCompleter);

    await _pumpDetail(tester, source);
    expect(find.text('Catalog Movie'), findsOneWidget);
    expect(find.text('Enriched overview'), findsNothing);

    detailCompleter.complete(
      const CatalogDetail(
        item: CatalogItem(
          source: CatalogSourceId.trakt,
          kind: MediaKind.movie,
          title: 'Enriched Catalog Movie',
          overview: 'Enriched overview',
          ids: CatalogItemIds(tmdb: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(source.fetchDetailCalls, 1);
    expect(find.text('Enriched Catalog Movie'), findsOneWidget);
    expect(find.text('Enriched overview'), findsOneWidget);
    expect(find.text('Catalog Movie'), findsNothing);
  });

  testWidgets('detail enrichment that adds external ids re-resolves library matches', (tester) async {
    // #1715: the row form of a Plex Discover item carries only its rating
    // key and the first lookup misses; the detail body brings the external
    // ids, which must trigger a second lookup instead of leaving the screen
    // on "Not in your library".
    const bare = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Row-only Movie',
      ids: CatalogItemIds(trakt: 5),
    );
    const enriched = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Row-only Movie',
      ids: CatalogItemIds(trakt: 5, tmdb: 99),
    );
    final hit = testMediaItem(id: 'server-match', libraryTitle: 'Movies', serverName: 'Living Room');
    late _ExternalIdGatedMatcher matcher;
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: enriched));

    await _pumpDetail(
      tester,
      source,
      item: bare,
      matcherBuilder: (multiServer) => matcher = _ExternalIdGatedMatcher(multiServer, hit),
    );

    expect(matcher.calls.map((call) => call.ids.tmdb), [null, 99]);
    expect(find.text(t.explore.notInLibrary), findsNothing);
    expect(find.text(t.explore.inTheseLibraries), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
  });

  testWidgets('detail enrichment that adds alternate titles re-resolves library matches', (tester) async {
    // #2098: a Trakt row carries no alternate titles; the detail load brings
    // the romaji alias, and a copy filed under it is reachable only through
    // that title. Same ids, so the id-based trigger alone would not re-ask.
    const bare = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.show,
      title: "Frieren: Beyond Journey's End",
      ids: CatalogItemIds(trakt: 198225, tvdb: 424536),
    );
    const enriched = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.show,
      title: "Frieren: Beyond Journey's End",
      altTitles: ['Sousou no Frieren'],
      ids: CatalogItemIds(trakt: 198225, tvdb: 424536),
    );
    late _ScriptedMatcher matcher;
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: enriched));

    await _pumpDetail(
      tester,
      source,
      item: bare,
      matcherBuilder: (multiServer) => matcher = _ScriptedMatcher(multiServer, [
        () => libraryLookupResult(const [], succeeded: {'server-1'}),
        () => libraryLookupResult([_libraryCopy(id: 'romaji-copy', libraryTitle: 'Anime (romaji)')]),
      ]),
    );

    expect(matcher.calls, 2);
    expect(find.text(t.explore.notInLibrary), findsNothing);
    expect(find.text('Anime (romaji)'), findsOneWidget);
  });

  group('Seerr request action', () {
    testWidgets('appears once the detail load supplies the tmdb id', (tester) async {
      // #1959: Plex Discover's hub/search/related endpoints ignore
      // includeGuids, so a row item carries no tmdb id until fetchDetail
      // brings one. The Request gate must read the enriched item, not the
      // row form the screen opened with.
      final detailCompleter = Completer<CatalogDetail>();
      final source = _FakeCatalogSource(detailCompleter: detailCompleter);

      await _pumpDetail(tester, source, item: _bareRow, seerr: _seerrSource());
      expect(find.byTooltip(t.seerr.request), findsNothing);

      detailCompleter.complete(const CatalogDetail(item: _enrichedRow));
      await tester.pumpAndSettle();

      expect(find.byTooltip(t.seerr.request), findsOneWidget);
    });

    testWidgets('appears immediately when the row item already carries a tmdb id', (tester) async {
      final source = _FakeCatalogSource();

      await _pumpDetail(tester, source, seerr: _seerrSource());

      expect(find.byTooltip(t.seerr.request), findsOneWidget);
    });

    testWidgets('stays hidden without the request permission', (tester) async {
      final source = _FakeCatalogSource();

      await _pumpDetail(tester, source, seerr: _seerrSource(permissions: 0));

      expect(find.byTooltip(t.seerr.request), findsNothing);
    });
  });

  testWidgets('lists every library copy of one title, best quality first', (tester) async {
    // #1754: one movie held by both a 4K library and an HD library on the same
    // server. Library names are user-chosen, so each row also states the
    // resolution the user is actually choosing between.
    final source = _FakeCatalogSource();

    await _pumpDetail(
      tester,
      source,
      matches: [
        _libraryCopy(id: 'hd-copy', libraryTitle: 'Movies', videoResolution: '1080'),
        _libraryCopy(id: 'uhd-copy', libraryTitle: '4K Movies', videoResolution: '4k'),
      ],
    );

    expect(find.text(t.explore.inTheseLibraries), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('4K Movies'), findsOneWidget);

    final subtitles = tester.widgetList<Text>(find.textContaining('Living Room')).map((text) => text.data!).toList();
    expect(subtitles, hasLength(2));
    expect(subtitles.first, contains('4K'), reason: 'the 4K copy sorts above the HD one');
    expect(subtitles.last, contains('1080p'));
  });

  testWidgets('a re-resolve that comes back short keeps the copies already found', (tester) async {
    // The cross-server fan-out logs and skips per-server failures, so a later
    // pass can answer without a server that replied to the first one. Those
    // rows are still valid and must not be wiped.
    late _ScriptedMatcher matcher;
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: _enrichedRow));

    await _pumpDetail(
      tester,
      source,
      item: _bareRow,
      matcherBuilder: (multiServer) => matcher = _ScriptedMatcher(multiServer, [
        () => libraryLookupResult([_libraryCopy(id: 'hd-copy', libraryTitle: 'Movies')]),
        () => libraryLookupResult(const []),
      ]),
    );

    expect(matcher.calls, 2);
    expect(find.text(t.explore.inTheseLibraries), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text(t.explore.notInLibrary), findsNothing);
  });

  testWidgets('a failed re-resolve does not claim the title left the library', (tester) async {
    late _ScriptedMatcher matcher;
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: _enrichedRow));

    await _pumpDetail(
      tester,
      source,
      item: _bareRow,
      matcherBuilder: (multiServer) => matcher = _ScriptedMatcher(multiServer, [
        () => libraryLookupResult([_libraryCopy(id: 'hd-copy', libraryTitle: 'Movies')]),
        () => throw StateError('server unreachable'),
      ]),
    );

    expect(matcher.calls, 2);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text(t.explore.notInLibrary), findsNothing);
  });

  testWidgets('a server that could not be asked is reported instead of counted as a miss', (tester) async {
    // #2098: a slow or unreachable server is no evidence of absence. With no
    // copies found elsewhere, "Not in your library" would be a false claim.
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: _enrichedRow));

    await _pumpDetail(
      tester,
      source,
      item: _bareRow,
      matcherBuilder: (multiServer) => _ScriptedMatcher(multiServer, [
        () => libraryLookupResult(const [], failed: {'server-1'}),
      ]),
    );

    expect(find.text(t.explore.notInLibrary), findsNothing);
    expect(find.text(t.explore.libraryCheckFailed(n: 1)), findsOneWidget);
  });

  testWidgets('an unchecked server is noted under the copies other servers found', (tester) async {
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: _enrichedRow));

    await _pumpDetail(
      tester,
      source,
      item: _bareRow,
      matcherBuilder: (multiServer) => _ScriptedMatcher(multiServer, [
        () => libraryLookupResult(
          [_libraryCopy(id: 'hd-copy', libraryTitle: 'Movies')],
          succeeded: {'server-1'},
          failed: {'server-2', 'server-3'},
        ),
      ]),
    );

    expect(find.text(t.explore.inTheseLibraries), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text(t.explore.libraryCheckFailed(n: 2)), findsOneWidget);
  });

  testWidgets('a server that answers a later pass stops being reported as unchecked', (tester) async {
    // The bare-row pass and the enriched pass race; a server that timed out
    // on one and answered the other has been checked.
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: _enrichedRow));

    await _pumpDetail(
      tester,
      source,
      item: _bareRow,
      matcherBuilder: (multiServer) => _ScriptedMatcher(multiServer, [
        () => libraryLookupResult(const [], failed: {'server-1'}),
        () => libraryLookupResult(const [], succeeded: {'server-1'}),
      ]),
    );

    expect(find.text(t.explore.libraryCheckFailed(n: 1)), findsNothing);
    expect(find.text(t.explore.notInLibrary), findsOneWidget);
  });

  testWidgets('a re-resolve that lost its library stamp keeps the one already shown', (tester) async {
    // Jellyfin stamps a copy's library with a best-effort ancestors lookup
    // that returns the item bare when it fails. A row that fell back to the
    // server name would be indistinguishable from its sibling in the same
    // server's other library.
    late _ScriptedMatcher matcher;
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: _enrichedRow));

    await _pumpDetail(
      tester,
      source,
      item: _bareRow,
      matcherBuilder: (multiServer) => matcher = _ScriptedMatcher(multiServer, [
        () => libraryLookupResult([_libraryCopy(id: 'hd-copy', libraryTitle: 'Movies', videoResolution: '1080')]),
        () => libraryLookupResult([_libraryCopy(id: 'hd-copy', serverName: null)]),
      ]),
    );

    expect(matcher.calls, 2);
    expect(find.text('Movies'), findsOneWidget);
    final subtitles = tester.widgetList<Text>(find.textContaining('Living Room')).map((text) => text.data!);
    expect(subtitles.single, contains('1080p'), reason: 'the quality hint survives an unstamped re-resolve too');
  });

  testWidgets('a re-resolve that finds another library adds it to the list', (tester) async {
    // The exact `plex://` guid only sees libraries on the modern agent; a
    // legacy-agent sibling arrives with the enriched imdb/tmdb pass (#1754).
    // The first pass being non-empty must not suppress the second.
    late _ScriptedMatcher matcher;
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: _enrichedRow));

    await _pumpDetail(
      tester,
      source,
      item: _bareRow,
      matcherBuilder: (multiServer) => matcher = _ScriptedMatcher(multiServer, [
        () => libraryLookupResult([_libraryCopy(id: 'uhd-copy', libraryTitle: '4K Movies', videoResolution: '4k')]),
        () => libraryLookupResult([
          _libraryCopy(id: 'uhd-copy', libraryTitle: '4K Movies', videoResolution: '4k'),
          _libraryCopy(id: 'hd-copy', libraryTitle: 'Movies', videoResolution: '1080'),
        ]),
      ]),
    );

    expect(matcher.calls, 2);
    expect(find.text('4K Movies'), findsOneWidget, reason: 'the copy both passes agree on is not doubled');
    expect(find.text('Movies'), findsOneWidget);
  });

  testWidgets('focus stays on a library copy when a later pass adds one above it', (tester) async {
    // Merging re-sorts, so the rows can move. Focus nodes are keyed by the
    // copy, not by row index, or a dpad user would be thrown to another copy.
    final detailCompleter = Completer<CatalogDetail>();
    final source = _FakeCatalogSource(detailCompleter: detailCompleter);

    await _pumpDetail(
      tester,
      source,
      item: _bareRow,
      matcherBuilder: (multiServer) => _ScriptedMatcher(multiServer, [
        () => libraryLookupResult([_libraryCopy(id: 'hd-copy', libraryTitle: 'Movies', videoResolution: '1080')]),
        () => libraryLookupResult([
          _libraryCopy(id: 'hd-copy', libraryTitle: 'Movies', videoResolution: '1080'),
          _libraryCopy(id: 'uhd-copy', libraryTitle: '4K Movies', videoResolution: '4k'),
        ]),
      ]),
    );

    final tile = tester.widget<FocusableListTile>(
      find.ancestor(of: find.text('Movies'), matching: find.byType(FocusableListTile)),
    );
    tile.focusNode!.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_library_match_server-1:hd-copy');

    detailCompleter.complete(const CatalogDetail(item: _enrichedRow));
    await tester.pumpAndSettle();

    expect(find.text('4K Movies'), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'catalog_library_match_server-1:hd-copy',
      reason: 'the 4K copy sorted above the focused HD copy without stealing focus',
    );
  });

  testWidgets('fetchDetail failure leaves the opening item rendered', (tester) async {
    final source = _FakeCatalogSource(detailError: StateError('detail unavailable'));

    await _pumpDetail(tester, source);

    expect(source.fetchDetailCalls, 1);
    expect(find.text('Catalog Movie'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text(t.explore.cast), findsNothing);
    expect(find.text(t.discover.moreLikeThis), findsNothing);
  });

  testWidgets('spoiler tags stay hidden until the focusable reveal action is pressed', (tester) async {
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Tagged Movie',
      ids: CatalogItemIds(tmdb: 10),
      tags: [
        CatalogTag(name: 'Found family', rank: 80),
        CatalogTag(name: 'Secret identity', rank: 95, isSpoiler: true),
      ],
    );
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: item));

    await _pumpDetail(tester, source, item: item);

    expect(find.text('Found family'), findsOneWidget);
    expect(find.text('Secret identity'), findsNothing);
    expect(find.text(t.explore.detail.revealSpoilerTags), findsOneWidget);

    await tester.tap(find.text(t.explore.detail.revealSpoilerTags));
    await tester.pump();

    expect(find.text('Secret identity'), findsOneWidget);
    expect(find.text(t.explore.detail.revealSpoilerTags), findsNothing);
  });

  testWidgets('ratings row labels every score source without a brand mark', (tester) async {
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Rated Movie',
      ids: CatalogItemIds(tmdb: 11),
      ratings: [
        MediaRatingSource(source: 'simkl', value: 8.1, votes: 11),
        MediaRatingSource(source: 'mal', value: 8.3, votes: 13),
        MediaRatingSource(source: 'critic', value: 7.2, votes: 14),
        MediaRatingSource(source: 'audience', value: 8.8, votes: 15),
      ],
    );
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: item));

    await _pumpDetail(tester, source, item: item);

    expect(find.text(t.explore.detail.ratings), findsOneWidget);
    expect(find.text('Simkl 8.1 (11 votes)'), findsOneWidget);
    expect(find.text('MyAnimeList 8.3 (13 votes)'), findsOneWidget);
    expect(find.text('Critics 7.2 (14 votes)'), findsOneWidget);
    expect(find.text('Audience 8.8 (15 votes)'), findsOneWidget);
  });

  testWidgets('scores whose source owns a logo render the mark and that source scale', (tester) async {
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Attributed Movie',
      ids: CatalogItemIds(tmdb: 21),
      ratings: [
        MediaRatingSource(source: 'rottenTomatoesCritic', value: 8.4),
        MediaRatingSource(source: 'rottenTomatoesAudience', value: 4.1),
        MediaRatingSource(source: 'imdb', value: 7.9, votes: 12),
        MediaRatingSource(source: 'tmdb', value: 7.5),
      ],
    );
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: item));

    await _pumpDetail(tester, source, item: item);

    expect(
      tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .map((picture) => picture.bytesLoader)
          .whereType<SvgAssetLoader>()
          .map((loader) => loader.assetName),
      containsAll(const [
        'assets/rating_icons/rt_fresh.svg',
        'assets/rating_icons/rt_spilled.svg',
        'assets/rating_icons/imdb.svg',
        'assets/rating_icons/tmdb.svg',
      ]),
    );
    // The mark carries the attribution, so the chip keeps only the score, on
    // the scale that source publishes.
    expect(find.text('84%'), findsOneWidget);
    expect(find.text('41%'), findsOneWidget);
    expect(find.text('7.9 (12 votes)'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('${t.common.ratingSource.rottenTomatoesCritic} 8.4'), findsNothing);
  });

  testWidgets('seasonal rank keeps its season window instead of claiming all-time rank', (tester) async {
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.show,
      title: 'Seasonal Show',
      ids: CatalogItemIds(tmdb: 12),
      ranks: [
        CatalogRank(
          rank: 7,
          scope: CatalogRankScope.popular,
          allTime: false,
          year: 2025,
          season: CatalogSeasonName.fall,
        ),
      ],
    );
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: item));

    await _pumpDetail(tester, source, item: item);

    expect(find.text('#7 in Fall 2025'), findsOneWidget);
    expect(find.text('#7 popular'), findsNothing);
  });

  testWidgets('windowed viewers render only when their period is present', (tester) async {
    const missingPeriod = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Missing Period',
      ids: CatalogItemIds(tmdb: 13),
      audience: CatalogAudience(listed: 3, viewers: 42),
    );
    final firstSource = _FakeCatalogSource(detail: const CatalogDetail(item: missingPeriod));
    await _pumpDetail(tester, firstSource, item: missingPeriod);

    expect(find.text('3 listed'), findsOneWidget);
    expect(find.textContaining('42'), findsNothing);

    const weekly = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Weekly Viewers',
      ids: CatalogItemIds(tmdb: 14),
      audience: CatalogAudience(viewers: 42, viewersPeriod: CatalogAudiencePeriod.week),
    );
    // Unmount first: pumping a second detail screen at the same tree position
    // would reuse the existing State, so `initState` would never re-run and
    // the screen would keep the previous item.
    await tester.pumpWidget(const SizedBox.shrink());
    final secondSource = _FakeCatalogSource(detail: const CatalogDetail(item: weekly));
    await _pumpDetail(tester, secondSource, item: weekly);

    expect(find.text('42 watched this week'), findsOneWidget);
  });

  testWidgets('trailer action appears only after an item supplies a trailer URL', (tester) async {
    final detailCompleter = Completer<CatalogDetail>();
    final source = _FakeCatalogSource(detailCompleter: detailCompleter);

    await _pumpDetail(tester, source);
    expect(find.byTooltip(t.explore.detail.watchTrailer), findsNothing);

    detailCompleter.complete(
      const CatalogDetail(
        item: CatalogItem(
          source: CatalogSourceId.trakt,
          kind: MediaKind.movie,
          title: 'Catalog Movie',
          trailerUrl: 'https://example.com/trailer',
          ids: CatalogItemIds(tmdb: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip(t.explore.detail.watchTrailer), findsOneWidget);
  });

  testWidgets('background prose renders as its own section', (tester) async {
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Production Movie',
      ids: CatalogItemIds(tmdb: 15),
      background: 'Filmed over three winters.',
    );
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: item));

    await _pumpDetail(tester, source, item: item);

    expect(find.text(t.explore.detail.background), findsOneWidget);
    expect(find.text('Filmed over three winters.'), findsOneWidget);
  });

  testWidgets('budget and box office pair into columns on a wide window and stack on a narrow one', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Expensive Movie',
      ids: CatalogItemIds(tmdb: 22),
      budget: 165000000,
      revenue: 675000000,
    );
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: item));

    await _pumpDetail(tester, source, item: item);

    final budget = find.text(t.explore.detail.budget);
    final revenue = find.text(t.explore.detail.revenue);
    expect(tester.getTopLeft(revenue).dy, tester.getTopLeft(budget).dy);
    expect(tester.getTopLeft(revenue).dx, greaterThan(tester.getTopLeft(budget).dx));

    tester.view.physicalSize = const Size(420, 900);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(revenue).dy, greaterThan(tester.getTopLeft(budget).dy));
    expect(tester.getTopLeft(revenue).dx, tester.getTopLeft(budget).dx);
  });

  testWidgets('all-null metadata renders without an empty optional section header', (tester) async {
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Bare Movie',
      ids: CatalogItemIds(tmdb: 15),
    );
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: item));

    await _pumpDetail(tester, source, item: item);

    expect(find.text('Bare Movie'), findsOneWidget);
    expect(find.text(t.explore.detail.ratings), findsNothing);
    expect(find.text(t.explore.detail.schedule), findsNothing);
    expect(find.text(t.explore.detail.crew), findsNothing);
    expect(find.text(t.explore.detail.tags), findsNothing);
    expect(find.text(t.explore.detail.links), findsNothing);
    expect(find.text(t.explore.detail.watchOn), findsNothing);
    expect(find.text(t.explore.cast), findsNothing);
    expect(find.text(t.discover.moreLikeThis), findsNothing);
    expect(find.text(t.explore.detail.relatedTitles), findsNothing);
    expect(find.text(t.explore.detail.background), findsNothing);
  });

  testWidgets('single-entry relations share one labelled section instead of a shelf each', (tester) async {
    const sequel = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'The Sequel',
      year: 2019,
      posterUrl: 'https://example.com/sequel.jpg',
      ids: CatalogItemIds(tmdb: 17),
    );
    const spinOff = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'The Spin-off',
      ids: CatalogItemIds(tmdb: 20),
    );
    const recommendation = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'A Similar Movie',
      ids: CatalogItemIds(tmdb: 18),
    );
    final source = _FakeCatalogSource(
      detail: const CatalogDetail(
        item: _item,
        related: [recommendation],
        relations: [
          CatalogRelation(type: CatalogRelationType.sequel, items: [sequel]),
          CatalogRelation(type: CatalogRelationType.spinOff, items: [spinOff]),
        ],
      ),
    );

    await _pumpDetail(tester, source);

    // Recommendations keep their shelf; two one-title relations do not get one
    // each.
    expect(find.byType(HubSection), findsOneWidget);
    expect(find.text(t.discover.moreLikeThis), findsOneWidget);
    expect(find.text('A Similar Movie'), findsOneWidget);

    expect(find.text(t.explore.detail.relatedTitles), findsOneWidget);
    expect(find.text(t.explore.relation.sequel), findsOneWidget);
    expect(find.text(t.explore.relation.spinOff), findsOneWidget);
    expect(find.text('The Sequel • 2019'), findsOneWidget);
    expect(find.text('The Spin-off'), findsOneWidget);
    expect(
      tester.widgetList<OptimizedMediaImage>(find.byType(OptimizedMediaImage)).map((image) => image.imagePath),
      contains('https://example.com/sequel.jpg'),
    );
  });

  testWidgets('a relation row opens the catalog detail screen of that title', (tester) async {
    const sequel = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'The Sequel',
      ids: CatalogItemIds(tmdb: 17),
    );
    final source = _FakeCatalogSource(
      detail: const CatalogDetail(
        item: _item,
        relations: [
          CatalogRelation(type: CatalogRelationType.sequel, items: [sequel]),
        ],
      ),
    );

    await _pumpDetail(tester, source);
    await tester.tap(find.text('The Sequel'));
    await tester.pumpAndSettle();

    expect(find.byType(CatalogItemDetailScreen, skipOffstage: false), findsNWidgets(2));
    expect(find.text('The Sequel'), findsOneWidget);
  });

  testWidgets('D-pad walks the relation rows between the cast strip and recommendations', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const prequel = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'The Prequel',
      ids: CatalogItemIds(tmdb: 16),
    );
    const sequel = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'The Sequel',
      ids: CatalogItemIds(tmdb: 17),
    );
    final source = _FakeCatalogSource(
      detail: const CatalogDetail(
        item: _item,
        cast: [CatalogCastMember(name: 'First Actor', secondary: 'Lead')],
        related: [
          CatalogItem(
            source: CatalogSourceId.trakt,
            kind: MediaKind.movie,
            title: 'Related Movie',
            ids: CatalogItemIds(tmdb: 2),
          ),
        ],
        relations: [
          CatalogRelation(type: CatalogRelationType.prequel, items: [prequel]),
          CatalogRelation(type: CatalogRelationType.sequel, items: [sequel]),
        ],
      ),
    );

    await _pumpDetail(tester, source);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_overview');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_cast_row');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_relation_0');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_relation_1');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, startsWith('hub_catalog-related:'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_relation_1');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_cast_row');
  });

  testWidgets('social recommendation keeps its person, reason, and note', (tester) async {
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Social Movie',
      ids: CatalogItemIds(tmdb: 19),
      recommenders: [
        CatalogRecommender(
          username: 'pat',
          name: 'Pat',
          note: 'A thoughtful recommendation.',
          reason: CatalogRecommendationReason.recommended,
        ),
      ],
    );
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: item));

    await _pumpDetail(tester, source, item: item);

    expect(find.text('Recommended by Pat'), findsOneWidget);
    expect(find.text('A thoughtful recommendation.'), findsOneWidget);
  });

  testWidgets('extended facts render in their labelled sections with localized values', (tester) async {
    final item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.show,
      title: 'Fact-rich Show',
      ids: CatalogItemIds(tmdb: 20),
      broadcastSeason: CatalogSeasonInfo(name: CatalogSeasonName.fall, year: 2025),
      format: CatalogFormat.ova,
      sourceMaterial: CatalogSourceMaterial.lightNovel,
      studios: ['Studio One'],
      countries: ['US'],
      languages: ['ja'],
      credits: [
        CatalogCredit(name: 'A. Director', role: CatalogCreditRole.director),
        CatalogCredit(name: 'W. Writer', role: CatalogCreditRole.writer),
      ],
      broadcast: CatalogBroadcast(weekday: DateTime.tuesday, time: '21:00', timezone: 'Asia/Tokyo'),
      nextEpisode: CatalogNextEpisode(episode: 4, airsAt: DateTime.utc(2100)),
      serverState: CatalogServerState(
        availability: CatalogAvailability.available,
        request: CatalogRequestState.pending,
        availableSeasons: 2,
        totalSeasons: 3,
      ),
      audience: CatalogAudience(dropRate: 0.25),
      releaseDate: DateTime.utc(2024, 1, 2),
      physicalReleaseDate: DateTime.utc(2024, 4, 5),
      endDate: DateTime.utc(2025, 6, 7),
      addedAt: DateTime.utc(2024, 2, 3),
      userRating: 9,
      originalTitle: 'Original Fact Title',
      altTitles: ['Alternate Fact Title'],
      contentAdvisory: 'Suitable for older teens.',
      budget: 1000000,
      revenue: 2500000,
      links: [
        CatalogLink(label: 'StreamCo', url: 'https://example.com/watch', isStreaming: true),
        CatalogLink(label: 'Official Site', url: 'https://example.com'),
      ],
    );
    final source = _FakeCatalogSource(detail: CatalogDetail(item: item));

    await _pumpDetail(tester, source, item: item);

    expect(find.text('Fall 2025'), findsOneWidget);
    expect(find.text('OVA'), findsOneWidget);
    expect(find.text('Light novel'), findsOneWidget);
    expect(find.text('25% dropped it'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Pending approval'), findsOneWidget);
    expect(find.text('2/3 seasons'), findsOneWidget);
    expect(find.text('Airs Tuesday at 21:00 Asia/Tokyo'), findsOneWidget);
    expect(find.textContaining('Ep 4 in'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);
    expect(find.text('Japanese'), findsOneWidget);
    expect(find.text(t.explore.detail.crew), findsOneWidget);
    expect(find.text('A. Director'), findsOneWidget);
    expect(find.text('W. Writer'), findsOneWidget);
    expect(find.text(t.explore.detail.watchOn), findsOneWidget);
    expect(find.text(t.explore.detail.links), findsOneWidget);
    expect(find.text('Open on StreamCo'), findsOneWidget);
    expect(find.text('Open on Official Site'), findsOneWidget);
    expect(find.text('Original Fact Title'), findsOneWidget);
    expect(find.text('Alternate Fact Title'), findsOneWidget);
    expect(find.text('Suitable for older teens.'), findsOneWidget);
    expect(find.textContaining('1,000,000'), findsOneWidget);
    expect(find.textContaining('2,500,000'), findsOneWidget);
  });

  testWidgets('D-pad includes spoiler reveal and outbound links after the main action bar', (tester) async {
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Interactive Movie',
      ids: CatalogItemIds(tmdb: 21),
      trailerUrl: 'https://example.com/trailer',
      tags: [CatalogTag(name: 'Spoiler', isSpoiler: true)],
      links: [
        CatalogLink(label: 'StreamCo', url: 'https://example.com/watch', isStreaming: true),
        CatalogLink(label: 'Official Site', url: 'https://example.com'),
      ],
    );
    final source = _FakeCatalogSource(detail: const CatalogDetail(item: item));

    await _pumpDetail(tester, source, item: item);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_watchlist');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_spoiler_tags');

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_external_link_0');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_external_link_1');
  });

  testWidgets('D-pad traverses from actions through cast and back from recommendations', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpDetail(tester, _FakeCatalogSource());
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_watchlist');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_overview');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_cast_row');
    expect(
      tester.widget<SingleChildScrollView>(find.byKey(const Key('catalog_detail_scroll'))).controller!.offset,
      greaterThan(0),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, startsWith('hub_catalog-related:'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_cast_row');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_overview');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_watchlist');
    expect(tester.widget<SingleChildScrollView>(find.byKey(const Key('catalog_detail_scroll'))).controller!.offset, 0);
  });

  testWidgets('D-pad includes every library match between actions and cast', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    // Copies render best-first, so the 4K one leads whatever order the
    // matcher returned them in.
    final matches = [
      testMediaItem(
        id: 'match_1',
        libraryTitle: 'Movies',
        serverName: 'Living Room',
        mediaVersions: const [MediaVersion(id: 'v1', videoResolution: '4k')],
      ),
      testMediaItem(
        id: 'match_2',
        libraryTitle: 'Favorites',
        serverName: 'Bedroom',
        mediaVersions: const [MediaVersion(id: 'v2', videoResolution: '1080')],
      ),
    ];
    await _pumpDetail(tester, _FakeCatalogSource(), matches: matches);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_overview');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_library_match_match_1');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_library_match_match_2');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_cast_row');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_library_match_match_2');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_library_match_match_1');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_overview');
  });

  testWidgets('D-pad stops on the overview and expands it before moving on to the buttons', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    // #2199: down from the action bar used to be thrown straight to the next
    // button, scrolling long prose past unread.
    final item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Wordy Movie',
      overview: '${'A very long establishing sentence about the movie. ' * 30}Closing line of the overview.',
      ids: const CatalogItemIds(tmdb: 31),
      links: const [CatalogLink(label: 'StreamCo', url: 'https://example.com/watch', isStreaming: true)],
    );
    final source = _FakeCatalogSource(detail: CatalogDetail(item: item));

    await _pumpDetail(tester, source, item: item);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_watchlist');
    expect(find.textContaining('Closing line'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_overview');

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.textContaining('Closing line'), findsOneWidget, reason: 'select expands the collapsed overview');
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_overview');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_external_link_0');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_overview');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_watchlist');
  });

  testWidgets('up from the first library copy reaches the overview when the item has no action bar', (tester) async {
    // No watchlist support, trailer, or Seerr: nothing above the copies is a
    // button, but the overview is still a stop rather than a dead end.
    final source = _FakeCatalogSource(supportsWatchlist: false);
    await _pumpDetail(
      tester,
      source,
      matches: [
        testMediaItem(
          id: 'match_1',
          libraryTitle: 'Movies',
          serverName: 'Living Room',
          mediaVersions: const [MediaVersion(id: 'v1', videoResolution: '4k')],
        ),
      ],
    );
    expect(find.byType(FocusableActionBar), findsNothing);

    final tile = tester.widget<FocusableListTile>(
      find.ancestor(of: find.text('Movies'), matching: find.byType(FocusableListTile)),
    );
    tile.focusNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_overview');
  });

  testWidgets('pending watchlist action keeps initial focus and its press retries the snapshot', (tester) async {
    final source = _FakeCatalogSource(watchlistLoading: true);
    await _pumpDetail(tester, source);

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_watchlist');
    final actionNode = tester
        .widgetList<Focus>(find.descendant(of: find.byType(FocusableActionBar), matching: find.byType(Focus)))
        .map((widget) => widget.focusNode)
        .whereType<FocusNode>()
        .singleWhere((node) => node.debugLabel == 'catalog_watchlist');
    expect(actionNode.canRequestFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(source.addToWatchlistCalls, 0);

    source.completeWatchlistLoad();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(source.addToWatchlistCalls, 1);
  });
  testWidgets('TV Back closes a hosted sheet without popping the catalog route', (tester) async {
    await _pumpDetail(tester, _FakeCatalogSource(), pushedRoute: true);

    final sheetResult = OverlaySheetController.showAdaptive<void>(
      tester.element(find.byType(FocusableActionBar)),
      builder: (_) => const SizedBox(height: 120, child: Center(child: Text('Hosted request sheet'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hosted request sheet'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.gameButtonB);
    // Android TV can dispatch route Back for the same remote press. Deliver
    // that duplicate in the same key sequence, before the coordinator's
    // one-frame ownership marker is cleared.
    await tester.binding.handlePopRoute();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pumpAndSettle();

    expect(find.text('Hosted request sheet'), findsNothing);
    expect(find.byType(CatalogItemDetailScreen), findsOneWidget);
    await expectLater(sheetResult, completion(isNull));

    // A later, independent system Back still pops the catalog route.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CatalogItemDetailScreen), findsNothing);
  });

  testWidgets('recommendation posters use compact grid-equivalent TV sizing', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpDetail(tester, _FakeCatalogSource());

    expect(tester.getSize(find.byType(MediaCard).first).width, lessThan(210));
  });
}
