import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/discover_provider.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/deletion_notifier.dart';
import 'package:plezy/utils/watch_state_notifier.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

MediaItem _item(
  String id, {
  String? parentId,
  String? grandparentId,
  MediaKind kind = MediaKind.episode,
  String serverId = 'server_1',
}) => testMediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: kind,
  title: id,
  serverId: serverId,
  serverName: 'Server',
  parentId: parentId,
  grandparentId: grandparentId,
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
/// test: a durable watch event must cost exactly one on-deck call and zero hub
/// refetches, progress zero calls, an order change zero calls, and a hidden-set
/// change one full pass.
class _FakeAggregationService extends DataAggregationService {
  _FakeAggregationService(super.serverManager);

  int onDeckCalls = 0;
  int hubCalls = 0;
  Set<String>? lastOnDeckServerIds;
  Set<String>? lastHubsServerIds;
  Set<String>? onDeckSucceededServerIds;
  Set<String>? hubSucceededServerIds;
  Set<String> onDeckCancelledServerIds = const {};
  Set<String> hubCancelledServerIds = const {};
  List<MediaItem> Function() onDeckResult = () => const [];
  List<MediaHub> Function() hubsResult = () => const [];
  Future<void>? onDeckGate;
  Future<void>? hubGate;
  Completer<void>? onDeckStarted;
  Completer<void>? hubStarted;

  @override
  Future<OnDeckAggregationResult> getOnDeckFromAllServers({
    int? limit,
    Set<String>? hiddenLibraryKeys,
    Set<String>? serverIds,
  }) async {
    onDeckCalls++;
    lastOnDeckServerIds = serverIds;
    final started = onDeckStarted;
    if (started != null && !started.isCompleted) started.complete();
    final gate = onDeckGate;
    if (gate != null) await gate;
    final items = onDeckResult();
    return (
      items: limit != null && items.length > limit ? items.sublist(0, limit) : items,
      succeededServerIds: onDeckSucceededServerIds ?? serverIds ?? const {'server_1'},
      cancelledServerIds: onDeckCancelledServerIds,
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
    final started = hubStarted;
    if (started != null && !started.isCompleted) started.complete();
    final gate = hubGate;
    if (gate != null) await gate;
    return (
      hubs: hubsResult(),
      succeededServerIds: hubSucceededServerIds ?? serverIds ?? const {'server_1'},
      cancelledServerIds: hubCancelledServerIds,
    );
  }
}

class _FakeClient implements MediaServerClient {
  final String serverIdValue;
  final String serverNameValue;
  final List<String> fetchedItemIds = [];
  MediaItem? itemResult;

  _FakeClient({this.serverIdValue = 'server_1', this.serverNameValue = 'Server'});

  @override
  ServerId get serverId => ServerId(serverIdValue);

  @override
  String? get serverName => serverNameValue;

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<MediaItem?> fetchItem(String id, {bool useCache = true}) async {
    fetchedItemIds.add(id);
    return itemResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeClient client;
  late MultiServerManager manager;
  late _FakeAggregationService aggregation;
  late MultiServerProvider multiServer;
  late HiddenLibrariesProvider hiddenLibraries;
  late LibrariesProvider libraries;
  late DiscoverProvider provider;
  late List<List<MediaItem>> shelfSyncs;
  bool isBinding = false;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    isBinding = false;
    shelfSyncs = [];

    client = _FakeClient();
    manager = MultiServerManager()..debugRegisterClientForTesting(client);
    aggregation = _FakeAggregationService(manager);
    multiServer = MultiServerProvider(manager, aggregation);
    hiddenLibraries = HiddenLibrariesProvider();
    libraries = LibrariesProvider();
    provider = DiscoverProvider(
      multiServer,
      hiddenLibraries,
      libraries,
      isProfileBinding: () => isBinding,
      syncSystemShelf: (items) async => shelfSyncs.add(List<MediaItem>.of(items)),
    );
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

  test('a failed in-flight pass still runs one coalesced trailing pass', () async {
    final gate = Completer<void>();
    aggregation.onDeckGate = gate.future;
    aggregation.onDeckStarted = Completer<void>();
    aggregation.onDeckResult = () {
      if (aggregation.onDeckCalls == 1) throw Exception('first pass failed');
      return [_item('recovered')];
    };
    aggregation.hubsResult = () => [_hub('hub-1')];

    final first = provider.load();
    await aggregation.onDeckStarted!.future;
    final coalesced = provider.load();
    gate.complete();
    await Future.wait([first, coalesced]);

    expect(aggregation.onDeckCalls, 2);
    expect(aggregation.hubCalls, 2);
    expect(provider.onDeck.map((item) => item.id), ['recovered']);
    expect(provider.errorMessage, isNull);
  });

  test('dispose during an in-flight coalesced load prevents trailing work and commits', () async {
    final scoped = DiscoverProvider(multiServer, hiddenLibraries, libraries, isProfileBinding: () => isBinding);
    final gate = Completer<void>();
    aggregation.onDeckGate = gate.future;
    aggregation.hubGate = gate.future;
    aggregation.onDeckStarted = Completer<void>();
    aggregation.hubStarted = Completer<void>();
    aggregation.onDeckResult = () => [_item('late')];
    aggregation.hubsResult = () => [_hub('late-hub')];

    final first = scoped.load();
    await Future.wait([aggregation.onDeckStarted!.future, aggregation.hubStarted!.future]);
    final coalesced = scoped.load();
    scoped.dispose();
    gate.complete();
    await Future.wait([first, coalesced]);

    expect(aggregation.onDeckCalls, 1);
    expect(aggregation.hubCalls, 1);
    expect(scoped.onDeck, isEmpty);
    expect(scoped.hubs, isEmpty);
    expect(scoped.loadGeneration, 0);

    await scoped.load();
    await scoped.syncToOnlineServers({'server_1'});
    expect(aggregation.onDeckCalls, 1);
    expect(aggregation.hubCalls, 1);
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

  test('watched and unwatched events refresh continue watching only', () async {
    aggregation.onDeckResult = () => [_item('ep-1', parentId: 'season-1')];
    aggregation.hubsResult = () => [_hub('hub-1')];
    await provider.load();
    final onDeckCallsBefore = aggregation.onDeckCalls;
    final hubCallsBefore = aggregation.hubCalls;

    WatchStateNotifier().notifyWatched(item: _item('ep-1', parentId: 'season-1'));
    await pumpEventQueue();

    expect(aggregation.onDeckCalls, onDeckCallsBefore + 1);
    expect(aggregation.hubCalls, hubCallsBefore);

    WatchStateNotifier().notifyWatched(item: _item('ep-1', parentId: 'season-1'), isNowWatched: false);
    await pumpEventQueue();

    expect(aggregation.onDeckCalls, onDeckCallsBefore + 2);
    expect(aggregation.hubCalls, hubCallsBefore);
  });

  test('sub-threshold progress patches the row without refetching', () async {
    final playing = _item('ep-1').copyWith(durationMs: 100000, viewOffsetMs: 10000, viewCount: 0);
    aggregation.onDeckResult = () => [playing, for (var i = 2; i <= 21; i++) _item('ep-$i')];
    aggregation.hubsResult = () => [_hub('hub-1')];
    await provider.load();
    await pumpEventQueue();
    shelfSyncs.clear();
    final onDeckCallsBefore = aggregation.onDeckCalls;
    final hubCallsBefore = aggregation.hubCalls;

    WatchStateNotifier().notifyProgress(item: playing, viewOffset: 30000, duration: 100000);
    await pumpEventQueue();

    expect(provider.onDeck.first.viewOffsetMs, 30000);
    expect(provider.onDeck.first.isWatched, isFalse);
    expect(provider.onDeck, hasLength(DiscoverProvider.continueWatchingPreviewLimit));
    expect(provider.hasMoreContinueWatching, isTrue);
    expect(aggregation.onDeckCalls, onDeckCallsBefore);
    expect(aggregation.hubCalls, hubCallsBefore);
    expect(shelfSyncs, hasLength(1));
    expect(shelfSyncs.single.first.viewOffsetMs, 30000);
  });

  test('watched-threshold progress refreshes continue watching only', () async {
    final playing = _item('ep-1').copyWith(durationMs: 100000, viewOffsetMs: 80000);
    aggregation.onDeckResult = () => [playing];
    aggregation.hubsResult = () => [_hub('hub-1')];
    await provider.load();
    final onDeckCallsBefore = aggregation.onDeckCalls;
    final hubCallsBefore = aggregation.hubCalls;

    WatchStateNotifier().notifyProgress(item: playing, viewOffset: 95000, duration: 100000);
    await pumpEventQueue();

    expect(aggregation.onDeckCalls, onDeckCallsBefore + 1);
    expect(aggregation.hubCalls, hubCallsBefore);
  });

  test('removal event drops the row immediately, then refreshes in background', () async {
    aggregation.onDeckResult = () => [_item('ep-1'), _item('ep-2')];
    await provider.load();
    final onDeckCallsBefore = aggregation.onDeckCalls;
    final hubCallsBefore = aggregation.hubCalls;

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
    expect(aggregation.onDeckCalls, onDeckCallsBefore + 1);
    expect(aggregation.hubCalls, hubCallsBefore);
  });

  test('deletion drops the item from on-deck and hubs, then refreshes continue watching only', () async {
    aggregation.onDeckResult = () => [_item('ep-1'), _item('ep-2')];
    aggregation.hubsResult = () => [
      _hub('hub-1', items: [_item('ep-1'), _item('other')]),
    ];
    await provider.load();
    final onDeckCallsBefore = aggregation.onDeckCalls;
    final hubCallsBefore = aggregation.hubCalls;

    var sawImmediateRemoval = false;
    provider.addListener(() {
      if (provider.onDeck.length == 1 && provider.onDeck.single.id == 'ep-2') {
        sawImmediateRemoval = true;
      }
    });
    aggregation.onDeckResult = () => [_item('ep-2')];

    DeletionNotifier().notifyDeletedItem(item: _item('ep-1'));
    await pumpEventQueue();

    expect(sawImmediateRemoval, isTrue);
    expect(provider.onDeck.map((i) => i.id), ['ep-2']);
    expect(provider.hubs.single.items.map((i) => i.id), ['other']);
    expect(aggregation.onDeckCalls, onDeckCallsBefore + 1);
    expect(aggregation.hubCalls, hubCallsBefore);
  });

  test('deleting an ancestor removes its episodes from continue watching', () async {
    aggregation.onDeckResult = () => [_item('ep-1', grandparentId: 'show-1'), _item('ep-2')];
    await provider.load();
    aggregation.onDeckResult = () => [_item('ep-2')];

    DeletionNotifier().notifyDeletedItem(item: _item('show-1', kind: MediaKind.show));
    await pumpEventQueue();

    expect(provider.onDeck.map((i) => i.id), ['ep-2']);
  });

  test('download-only deletion leaves lists untouched and triggers no refetch', () async {
    aggregation.onDeckResult = () => [_item('ep-1')];
    aggregation.hubsResult = () => [
      _hub('hub-1', items: [_item('ep-1')]),
    ];
    await provider.load();
    final onDeckCallsBefore = aggregation.onDeckCalls;
    final hubCallsBefore = aggregation.hubCalls;

    DeletionNotifier().notifyDeletedItem(item: _item('ep-1'), isDownloadOnly: true);
    await pumpEventQueue();

    expect(provider.onDeck.map((i) => i.id), ['ep-1']);
    expect(provider.hubs.single.items.map((i) => i.id), ['ep-1']);
    expect(aggregation.onDeckCalls, onDeckCallsBefore);
    expect(aggregation.hubCalls, hubCallsBefore);
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

  // A pass in which zero servers succeeded is never authoritative: it must
  // not wipe existing content, and it may only commit "loaded, empty" when
  // the failure is settled (no cancellations, binder not running). The
  // sign-in empty-flash regression: a rebind tore down the client mid-fetch,
  // the aborted pass committed loaded-empty, and the screen flashed
  // "no content available" until the follow-up load landed.

  test('zero-success pass with cancellations stays loading instead of committing empty', () async {
    aggregation.onDeckSucceededServerIds = const {};
    aggregation.hubSucceededServerIds = const {};
    aggregation.onDeckCancelledServerIds = const {'server_1'};
    aggregation.hubCancelledServerIds = const {'server_1'};

    await provider.load();

    expect(provider.isLoading, isTrue);
    expect(provider.areHubsLoading, isTrue);
    expect(provider.errorMessage, isNull);
    expect(provider.loadGeneration, 0);

    // The guaranteed follow-up load lands the real content.
    aggregation.onDeckSucceededServerIds = null;
    aggregation.hubSucceededServerIds = null;
    aggregation.onDeckCancelledServerIds = const {};
    aggregation.hubCancelledServerIds = const {};
    aggregation.onDeckResult = () => [_item('a')];
    aggregation.hubsResult = () => [_hub('hub-1')];
    await provider.load();

    expect(provider.onDeck.map((i) => i.id), ['a']);
    expect(provider.hubs.map((h) => h.id), ['hub-1']);
    expect(provider.isLoading, isFalse);
    expect(provider.areHubsLoading, isFalse);
  });

  test('zero-success pass during profile binding stays loading (no cancellations)', () async {
    // Covers the timeout-during-bind window: every fetch failed while the
    // binder was still wiring servers, with no cancellation marker.
    isBinding = true;
    aggregation.onDeckSucceededServerIds = const {};
    aggregation.hubSucceededServerIds = const {};

    await provider.load();

    expect(provider.isLoading, isTrue);
    expect(provider.areHubsLoading, isTrue);
    expect(provider.errorMessage, isNull);
  });

  test('settled zero-success pass with no prior content commits loaded-empty', () async {
    // Locks the no-eternal-spinner constraint: a genuinely dead server
    // outside any disruption window keeps today's empty state.
    aggregation.onDeckSucceededServerIds = const {};
    aggregation.hubSucceededServerIds = const {};

    await provider.load();

    expect(provider.isLoading, isFalse);
    expect(provider.areHubsLoading, isFalse);
    expect(provider.onDeck, isEmpty);
    expect(provider.hubs, isEmpty);
    expect(provider.errorMessage, isNull);
  });

  test('totally failed refresh keeps previous content instead of wiping it', () async {
    aggregation.onDeckResult = () => [_item('a')];
    aggregation.hubsResult = () => [_hub('hub-1')];
    await provider.load();
    final generationBefore = provider.loadGeneration;

    aggregation.onDeckSucceededServerIds = const {};
    aggregation.hubSucceededServerIds = const {};
    aggregation.onDeckResult = () => const [];
    aggregation.hubsResult = () => const [];
    await provider.load();

    expect(provider.onDeck.map((i) => i.id), ['a']);
    expect(provider.hubs.map((h) => h.id), ['hub-1']);
    expect(provider.isLoading, isFalse);
    expect(provider.areHubsLoading, isFalse);
    // No new data: a failed pass must not reset the hero carousel.
    expect(provider.loadGeneration, generationBefore);

    // The kept content does not count as covering the failed servers — the
    // next status emission refetches them.
    aggregation.onDeckSucceededServerIds = null;
    aggregation.hubSucceededServerIds = null;
    aggregation.onDeckResult = () => [_item('b')];
    final callsBefore = aggregation.onDeckCalls;
    await provider.syncToOnlineServers({'server_1'});
    expect(aggregation.onDeckCalls, greaterThan(callsBefore));
  });

  test('a disrupted half is independent: on-deck commits while hubs stay loading', () async {
    aggregation.onDeckResult = () => [_item('a')];
    aggregation.hubSucceededServerIds = const {};
    aggregation.hubCancelledServerIds = const {'server_1'};

    await provider.load();

    expect(provider.isLoading, isFalse);
    expect(provider.onDeck.map((i) => i.id), ['a']);
    expect(provider.areHubsLoading, isTrue);
    expect(provider.hubs, isEmpty);
  });

  test('updateItem qualifies same bare ids by source server without fan-out', () async {
    final serverOneItem = _item('shared-id', serverId: 'server_1').copyWith(title: 'Server One Original');
    final serverTwoItem = _item('shared-id', serverId: 'server_2').copyWith(title: 'Server Two Original');
    final serverTwoClient = _FakeClient(serverIdValue: 'server_2', serverNameValue: 'Server Two');
    manager.debugRegisterClientForTesting(serverTwoClient);

    aggregation.onDeckResult = () => [serverOneItem, serverTwoItem];
    aggregation.hubsResult = () => [
      _hub('hub-1', serverId: 'server_1', items: [serverOneItem]),
      _hub('hub-2', serverId: 'server_2', items: [serverTwoItem]),
    ];
    await provider.load();
    final onDeckCallsBefore = aggregation.onDeckCalls;
    final hubCallsBefore = aggregation.hubCalls;
    final source = provider.hubs
        .expand((hub) => hub.items)
        .singleWhere((item) => item.globalKey == serverTwoItem.globalKey);
    final updated = serverTwoItem.copyWith(title: 'Server Two Refreshed');
    serverTwoClient.itemResult = updated;

    await provider.updateItem(source);

    // The old bare-id aggregation path fetched every server. The source item
    // must instead select one client and leave both full-list fetch surfaces
    // untouched.
    expect(client.fetchedItemIds, isEmpty);
    expect(serverTwoClient.fetchedItemIds, ['shared-id']);
    expect(aggregation.onDeckCalls, onDeckCallsBefore);
    expect(aggregation.hubCalls, hubCallsBefore);

    final onDeckByKey = {for (final item in provider.onDeck) item.globalKey: item};
    final hubItemsByKey = {for (final item in provider.hubs.expand((hub) => hub.items)) item.globalKey: item};
    expect(onDeckByKey[serverOneItem.globalKey], same(serverOneItem));
    expect(onDeckByKey[serverTwoItem.globalKey], same(updated));
    expect(hubItemsByKey[serverOneItem.globalKey], same(serverOneItem));
    expect(hubItemsByKey[serverTwoItem.globalKey], same(updated));
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

  test('online-server deltas arriving mid-pass are unioned into one trailing pass', () async {
    aggregation.onDeckResult = () => [_item('a')];
    aggregation.hubsResult = () => [_hub('hub-1')];
    await provider.load();
    final onDeckCallsBefore = aggregation.onDeckCalls;
    final hubCallsBefore = aggregation.hubCalls;

    final gate = Completer<void>();
    aggregation.onDeckGate = gate.future;
    aggregation.hubGate = gate.future;
    aggregation.onDeckStarted = Completer<void>();
    aggregation.hubStarted = Completer<void>();
    aggregation.onDeckResult = () => [_item('new', serverId: 'server_2')];
    aggregation.hubsResult = () => [_hub('new-hub', serverId: 'server_2')];

    final firstDelta = provider.syncToOnlineServers({'server_1', 'server_2'});
    await Future.wait([aggregation.onDeckStarted!.future, aggregation.hubStarted!.future]);
    final trailingDelta = provider.syncToOnlineServers({'server_1', 'server_2', 'server_3'});

    gate.complete();
    await Future.wait([firstDelta, trailingDelta]);

    expect(aggregation.onDeckCalls, onDeckCallsBefore + 2);
    expect(aggregation.hubCalls, hubCallsBefore + 2);
    expect(aggregation.lastOnDeckServerIds, {'server_3'});
    expect(aggregation.lastHubsServerIds, {'server_3'});
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
