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
import 'package:plezy/utils/watch_state_notifier.dart';

import '../test_helpers/prefs.dart';

MediaItem _item(String id, {String? parentId}) => MediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: id,
  serverId: 'server_1',
  serverName: 'Server',
  parentId: parentId,
);

MediaHub _hub(String id, {String? identifier, String? libraryId, List<MediaItem>? items}) => MediaHub(
  id: id,
  title: id,
  type: 'movie',
  identifier: identifier,
  items: items ?? [_item('$id-item')],
  size: 1,
  libraryId: libraryId,
  serverId: 'server_1',
);

/// Counting fake — the provider's fetch-cost policy is the contract under
/// test: a watch event must cost exactly one on-deck call and zero hub
/// refetches, an order change zero calls, a hidden-set change one full pass.
class _FakeAggregationService extends DataAggregationService {
  _FakeAggregationService(super.serverManager);

  int onDeckCalls = 0;
  int hubCalls = 0;
  List<MediaItem> Function() onDeckResult = () => const [];
  List<MediaHub> Function() hubsResult = () => const [];

  @override
  Future<List<MediaItem>> getOnDeckFromAllServers({int? limit, Set<String>? hiddenLibraryKeys}) async {
    onDeckCalls++;
    final items = onDeckResult();
    return limit != null && items.length > limit ? items.sublist(0, limit) : items;
  }

  @override
  Future<List<MediaHub>> getHubsFromAllServers({
    int? limit,
    Set<String>? hiddenLibraryKeys,
    bool useGlobalHubs = true,
    bool includePlaybackHubs = true,
  }) async {
    hubCalls++;
    return hubsResult();
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
    aggregation.hubsResult = () => [
      _hub('hub-lib2', libraryId: 'lib-2'),
      _hub('hub-lib1', libraryId: 'lib-1'),
    ];
    await provider.load();
    expect(provider.hubs.map((h) => h.id), ['hub-lib2', 'hub-lib1']);
    final hubCallsBefore = aggregation.hubCalls;

    MediaLibrary lib(String id) =>
        MediaLibrary(id: id, backend: MediaBackend.plex, title: id, serverId: 'server_1');
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

    // New server mid-session → full reload.
    await provider.syncToOnlineServers({'server_1', 'server_2'});
    expect(aggregation.onDeckCalls, onDeckCallsBefore + 1);

    // During profile binding the startup priming owns loading — waves are
    // ignored so the hub fan-out doesn't run once per wave.
    isBinding = true;
    await provider.syncToOnlineServers({'server_1', 'server_2', 'server_3'});
    expect(aggregation.onDeckCalls, onDeckCallsBefore + 1);
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
