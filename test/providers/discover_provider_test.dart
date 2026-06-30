import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/ids.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_hub.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/media/media_library.dart';
import 'package:vibe_stream/media/media_server_client.dart';
import 'package:vibe_stream/media/server_capabilities.dart';
import 'package:vibe_stream/providers/discover_provider.dart';
import 'package:vibe_stream/providers/hidden_libraries_provider.dart';
import 'package:vibe_stream/providers/libraries_provider.dart';
import 'package:vibe_stream/providers/multi_server_provider.dart';
import 'package:vibe_stream/services/data_aggregation_service.dart';
import 'package:vibe_stream/services/multi_server_manager.dart';
import 'package:vibe_stream/services/settings_service.dart';
import 'package:vibe_stream/utils/watch_state_notifier.dart';

import '../test_helpers/prefs.dart';

MediaItem _item(String id, {String? parentId, String serverId = 'server_1'}) => MediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: id,
  serverId: serverId,
  serverName: 'Server',
  parentId: parentId,
);

MediaHub _hub(
  String id, {
  String? identifier,
  String? libraryId,
  List<MediaItem>? items,
  String serverId = 'server_1',
}) => MediaHub(
  id: id,
  title: id,
  type: 'movie',
  identifier: identifier,
  items: items ?? [_item('$id-item', serverId: serverId)],
  size: 1,
  libraryId: libraryId,
  serverId: serverId,
);

/// Counting fake — the provider's fetch-cost policy is the contract under
/// test: a watch event must cost exactly one on-deck call and zero hub
/// refetches, an order change zero calls, a hidden-set change one full pass.
class _FakeAggregationService extends DataAggregationService {
  _FakeAggregationService(super.serverManager);

  int onDeckCalls = 0;
  int hubCalls = 0;
  Set<String>? lastOnDeckServerIds;
  Set<String>? lastHubsServerIds;
  Set<String>? onDeckSucceededServerIds;
  Set<String>? hubSucceededServerIds;
  List<MediaItem> Function() onDeckResult = () => const [];
  List<MediaHub> Function() hubsResult = () => const [];

  @override
  Future<OnDeckAggregationResult> getOnDeckFromAllServers({
    int? limit,
    Set<String>? hiddenLibraryKeys,
    Set<String>? serverIds,
  }) async {
    onDeckCalls++;
    lastOnDeckServerIds = serverIds;
    final items = onDeckResult();
    return (
      items: limit != null && items.length > limit ? items.sublist(0, limit) : items,
      succeededServerIds: onDeckSucceededServerIds ?? serverIds ?? const {'server_1'},
    );
  }

  @override
  Future<HubAggregationResult> getHubsFromAllServers({
    int? limit,
    Set<String>? hiddenLibraryKeys,
    bool useGlobalHubs = true,
    bool includePlaybackHubs = true,
    Set<String>? serverIds,
  }) async {
    hubCalls++;
    lastHubsServerIds = serverIds;
    return (hubs: hubsResult(), succeededServerIds: hubSucceededServerIds ?? serverIds ?? const {'server_1'});
  }
}

class _FakeClient implements MediaServerClient {
  MediaItem? itemResult;

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<MediaItem?> fetchItem(String id, {bool useCache = true}) async => itemResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeClient client;
  late _FakeAggregationService aggregation;
  late MultiServerProvider multiServer;
  late HiddenLibrariesProvider hiddenLibraries;
  late LibrariesProvider libraries;
  late DiscoverProvider provider;
  bool isBinding = false;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    isBinding = false;

    client = _FakeClient();
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    aggregation = _FakeAggregationService(manager);
    multiServer = MultiServerProvider(manager, aggregation);
    hiddenLibraries = HiddenLibrariesProvider();
    libraries = LibrariesProvider();
    provider = DiscoverProvider(multiServer, hiddenLibraries, libraries, isProfileBinding: () => isBinding);
  });

  tearDown(() {
    provider.dispose();
    libraries.dispose();
    hiddenLibraries.dispose();
    multiServer.dispose();
  });

  test('load publishes on-deck and hubs; concurrent calls coalesce', () async {
    aggregation.onDeckResult = () => [_item('a')];
    aggregation.hubsResult = () => [_hub('hub-1')];

    // Three synchronous calls: one in-flight pass plus at most one trailing
    // pass (a request arriving mid-load must observe its own fresh fetch).
    await Future.wait([provider.load(), provider.load(), provider.load()]);

    expect(provider.onDeck.map((i) => i.id), ['a']);
    expect(provider.hubs.map((h) => h.id), ['hub-1']);
    expect(provider.isLoading, isFalse);
    expect(provider.areHubsLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(aggregation.onDeckCalls, 2);
    expect(aggregation.hubCalls, 2);
  });

  test('limits the preview row and probes for more', () async {
    aggregation.onDeckResult = () => [for (var i = 0; i < 30; i++) _item('item-$i')];

    await provider.load();

    expect(provider.onDeck, hasLength(DiscoverProvider.continueWatchingPreviewLimit));
    expect(provider.hasMoreContinueWatching, isTrue);
  });

  test('filters playback-progress hubs that duplicate the continue watching row', () async {
    aggregation.hubsResult = () => [
      _hub('keep'),
      _hub('cw', identifier: 'home.continue'),
      _hub('od', identifier: 'home.ondeck'),
      _hub('nu', identifier: 'home.nextup'),
    ];

    await provider.load();

    expect(provider.hubs.map((h) => h.id), ['keep']);
  });

  test('watch event refreshes continue watching with one call and zero hub refetches', () async {
    aggregation.onDeckResult = () => [_item('ep-1', parentId: 'season-1')];
    aggregation.hubsResult = () => [_hub('hub-1')];
    await provider.load();
    final onDeckCallsBefore = aggregation.onDeckCalls;
    final hubCallsBefore = aggregation.hubCalls;

    WatchStateNotifier().notifyWatched(item: _item('ep-1', parentId: 'season-1'));
    await pumpEventQueue();

    expect(aggregation.onDeckCalls, onDeckCallsBefore + 1);
    expect(aggregation.hubCalls, hubCallsBefore);
  });

  test('removal event drops the row immediately, then refreshes in background', () async {
    aggregation.onDeckResult = () => [_item('ep-1'), _item('ep-2')];
    await provider.load();

    var sawImmediateRemoval = false;
    provider.addListener(() {
      if (provider.onDeck.length == 1 && provider.onDeck.single.id == 'ep-2') {
        sawImmediateRemoval = true;
      }
    });
    aggregation.onDeckResult = () => [_item('ep-2')];

    WatchStateNotifier().notifyRemovedFromContinueWatching(item: _item('ep-1'));
    await pumpEventQueue();

    expect(sawImmediateRemoval, isTrue);
    expect(provider.onDeck.map((i) => i.id), ['ep-2']);
  });

  test('library order change re-sorts hubs without any refetch', () async {
    aggregation.hubsResult = () => [_hub('hub-lib2', libraryId: 'lib-2'), _hub('hub-lib1', libraryId: 'lib-1')];
    await provider.load();
    expect(provider.hubs.map((h) => h.id), ['hub-lib2', 'hub-lib1']);
    final hubCallsBefore = aggregation.hubCalls;

    MediaLibrary lib(String id) => MediaLibrary(id: id, backend: MediaBackend.plex, title: id, serverId: 'server_1');
    await libraries.updateLibraryOrder([lib('lib-1'), lib('lib-2')]);
    await pumpEventQueue();

    expect(provider.hubs.map((h) => h.id), ['hub-lib1', 'hub-lib2']);
    expect(aggregation.hubCalls, hubCallsBefore);
  });

  test('hidden-library change triggers exactly one full reload', () async {
    await provider.load();
    final onDeckCallsBefore = aggregation.onDeckCalls;
    final hubCallsBefore = aggregation.hubCalls;

    await hiddenLibraries.hideLibrary('server_1:lib-1');
    await pumpEventQueue();

    expect(aggregation.onDeckCalls, onDeckCallsBefore + 1);
    expect(aggregation.hubCalls, hubCallsBefore + 1);
  });

  test('refreshContinueWatching never flips states or surfaces errors', () async {
    aggregation.onDeckResult = () => [_item('a')];
    await provider.load();

    aggregation.onDeckResult = () => throw Exception('server down');
    await provider.refreshContinueWatching();

    expect(provider.onDeck.map((i) => i.id), ['a']);
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('load failure surfaces the error and ends both loading states', () async {
    aggregation.onDeckResult = () => throw Exception('boom');

    await provider.load();

    expect(provider.errorMessage, contains('boom'));
    expect(provider.isLoading, isFalse);
    expect(provider.areHubsLoading, isFalse);
  });

  test('no servers while the profile binder runs stays loading instead of erroring', () async {
    final emptyManager = MultiServerManager();
    final emptyAggregation = _FakeAggregationService(emptyManager);
    final emptyMultiServer = MultiServerProvider(emptyManager, emptyAggregation);
    addTearDown(emptyMultiServer.dispose);
    final binderProvider = DiscoverProvider(
      emptyMultiServer,
      hiddenLibraries,
      libraries,
      isProfileBinding: () => isBinding,
    );
    addTearDown(binderProvider.dispose);

    isBinding = true;
    await binderProvider.load();
    expect(binderProvider.isLoading, isTrue);
    expect(binderProvider.errorMessage, isNull);

    isBinding = false;
    await binderProvider.load();
    expect(binderProvider.isLoading, isFalse);
    expect(binderProvider.errorMessage, isNotNull);
  });

  test('updateItem refetches one item and swaps it in place', () async {
    aggregation.onDeckResult = () => [_item('ep-1')];
    aggregation.hubsResult = () => [
      _hub('hub-1', items: [_item('movie-1')]),
    ];
    await provider.load();

    client.itemResult = _item('movie-1').copyWith(title: 'Updated Title');
    await provider.updateItem('movie-1');

    expect(provider.hubs.single.items.single.title, 'Updated Title');
    expect(provider.onDeck.single.id, 'ep-1');
  });

  test('syncToOnlineServers reloads for mid-session connects only', () async {
    aggregation.onDeckResult = () => [_item('a')];
    await provider.load();
    final onDeckCallsBefore = aggregation.onDeckCalls;

    // Same server set → already covered, no fetch.
    await provider.syncToOnlineServers({'server_1'});
    expect(aggregation.onDeckCalls, onDeckCallsBefore);

    // New server mid-session → one delta fetch scoped to it.
    await provider.syncToOnlineServers({'server_1', 'server_2'});
    expect(aggregation.onDeckCalls, onDeckCallsBefore + 1);

    // During profile binding the startup priming owns loading — waves are
    // ignored so the hub fan-out doesn't run once per wave.
    isBinding = true;
    await provider.syncToOnlineServers({'server_1', 'server_2', 'server_3'});
    expect(aggregation.onDeckCalls, onDeckCallsBefore + 1);
  });

  test('mid-session connect delta-fetches only the new server and merges', () async {
    aggregation.onDeckResult = () => [_item('a')];
    aggregation.hubsResult = () => [_hub('hub-1')];
    await provider.load();
    final generationBefore = provider.loadGeneration;

    aggregation.onDeckResult = () => [_item('b', serverId: 'server_2')];
    aggregation.hubsResult = () => [_hub('hub-2', serverId: 'server_2')];
    await provider.syncToOnlineServers({'server_1', 'server_2'});

    // The fetch fanned out to the new server only…
    expect(aggregation.lastOnDeckServerIds, {'server_2'});
    expect(aggregation.lastHubsServerIds, {'server_2'});
    // …and merged into the loaded state instead of replacing it.
    expect(provider.onDeck.map((i) => i.id), containsAll(['a', 'b']));
    expect(provider.hubs.map((h) => h.id), containsAll(['hub-1', 'hub-2']));
    // A delta behaves like a background refresh: no hero carousel reset.
    expect(provider.loadGeneration, generationBefore);

    // Already merged → the next emission with the same set is a no-op.
    final callsAfterDelta = aggregation.onDeckCalls;
    await provider.syncToOnlineServers({'server_1', 'server_2'});
    expect(aggregation.onDeckCalls, callsAfterDelta);
  });

  test('full load partial hub failure retries hubs without refetching continue watching', () async {
    aggregation.onDeckResult = () => [_item('a')];
    aggregation.hubsResult = () => const [];
    aggregation.hubSucceededServerIds = const {};
    await provider.load();
    final onDeckCallsBefore = aggregation.onDeckCalls;
    final hubCallsBefore = aggregation.hubCalls;

    aggregation.hubsResult = () => [_hub('hub-1')];
    aggregation.hubSucceededServerIds = const {'server_1'};
    await provider.syncToOnlineServers({'server_1'});

    expect(aggregation.onDeckCalls, onDeckCallsBefore);
    expect(aggregation.hubCalls, hubCallsBefore + 1);
    expect(aggregation.lastHubsServerIds, {'server_1'});
    expect(provider.hubs.map((h) => h.id), ['hub-1']);
  });

  test('delta partial hub failure retries only the missing surface', () async {
    aggregation.onDeckResult = () => [_item('a')];
    aggregation.hubsResult = () => [_hub('hub-1')];
    await provider.load();

    aggregation.onDeckResult = () => [_item('b', serverId: 'server_2')];
    aggregation.hubsResult = () => const [];
    aggregation.hubSucceededServerIds = const {};
    await provider.syncToOnlineServers({'server_1', 'server_2'});
    final onDeckCallsAfterPartial = aggregation.onDeckCalls;
    final hubCallsAfterPartial = aggregation.hubCalls;

    aggregation.hubsResult = () => [_hub('hub-2', serverId: 'server_2')];
    aggregation.hubSucceededServerIds = const {'server_2'};
    await provider.syncToOnlineServers({'server_1', 'server_2'});

    expect(aggregation.onDeckCalls, onDeckCallsAfterPartial);
    expect(aggregation.hubCalls, hubCallsAfterPartial + 1);
    expect(aggregation.lastHubsServerIds, {'server_2'});
    expect(provider.onDeck.map((i) => i.id), containsAll(['a', 'b']));
    expect(provider.hubs.map((h) => h.id), containsAll(['hub-1', 'hub-2']));
  });

  test('delta failure keeps the loaded state and retries on the next emission', () async {
    aggregation.onDeckResult = () => [_item('a')];
    aggregation.hubsResult = () => [_hub('hub-1')];
    await provider.load();
    final callsBefore = aggregation.onDeckCalls;

    aggregation.onDeckResult = () => throw Exception('flaky connect');
    await provider.syncToOnlineServers({'server_1', 'server_2'});
    expect(provider.onDeck.map((i) => i.id), ['a']);
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);

    // The failed id was not marked loaded, so the next emission retries it.
    aggregation.onDeckResult = () => [_item('b', serverId: 'server_2')];
    await provider.syncToOnlineServers({'server_1', 'server_2'});
    expect(aggregation.onDeckCalls, callsBefore + 2);
    expect(provider.onDeck.map((i) => i.id), containsAll(['a', 'b']));
  });

  test('dispose unregisters the online-servers listener', () {
    final before = multiServer.onlineServersListenerCount;
    final extra = DiscoverProvider(multiServer, hiddenLibraries, libraries, isProfileBinding: () => isBinding);
    expect(multiServer.onlineServersListenerCount, before + 1);

    extra.dispose();
    expect(multiServer.onlineServersListenerCount, before);
  });

  test('loadGeneration bumps on full loads only', () async {
    aggregation.onDeckResult = () => [_item('a')];
    final initial = provider.loadGeneration;

    await provider.load();
    expect(provider.loadGeneration, initial + 1);

    await provider.refreshContinueWatching();
    expect(provider.loadGeneration, initial + 1);
  });
}
