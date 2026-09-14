import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/watch_state_store.dart';
import 'package:plezy/services/watch_state_resolver.dart';
import 'package:plezy/utils/active_client_scope.dart';
import 'package:plezy/utils/watch_state_notifier.dart';
import '../test_helpers/media_items.dart';

Future<void> _emit(WatchStateEvent event) async {
  WatchStateNotifier().notify(event);
  await Future<void>.delayed(Duration.zero);
}

WatchStateEvent _event({
  required WatchStateChangeType changeType,
  required bool? isNowWatched,
  String serverId = 'jf-machine',
  String itemId = 'item-1',
  String? cacheServerId,
  int? viewOffset,
  List<String> parentChain = const [],
  bool serverAcknowledged = false,
}) {
  return WatchStateEvent(
    itemId: itemId,
    serverId: ServerId(serverId),
    cacheServerId: cacheServerId,
    changeType: changeType,
    parentChain: parentChain,
    isNowWatched: isNowWatched,
    viewOffset: viewOffset,
    serverAcknowledged: serverAcknowledged,
    patchId: WatchPatchId.session(++_testSequence),
  );
}

var _testSequence = 0;

final _episode = testMediaItem(
  id: 'episode-1',
  backend: MediaBackend.jellyfin,
  kind: MediaKind.episode,
  parentId: 'season-1',
  grandparentId: 'show-1',
  serverId: 'jf-machine',
);

void main() {
  test('removed from continue watching does not replace an existing watched patch', () async {
    final provider = WatchStateStore();
    addTearDown(provider.dispose);

    await _emit(_event(changeType: WatchStateChangeType.watched, isNowWatched: true));
    await _emit(_event(changeType: WatchStateChangeType.removedFromContinueWatching, isNowWatched: null));

    final patch = provider.patchForGlobalKey('jf-machine:item-1');
    expect(patch?.isWatched, isTrue);
    expect(patch?.viewOffsetMs, 0);
  });

  test('known active scope resolves a newer legacy bare event into that scope', () async {
    final provider = WatchStateStore();
    addTearDown(provider.dispose);
    provider.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});

    await _emit(
      _event(changeType: WatchStateChangeType.watched, isNowWatched: true, cacheServerId: 'jf-machine/user-a'),
    );
    await _emit(_event(changeType: WatchStateChangeType.unwatched, isNowWatched: false));

    expect(provider.patchForGlobalKey('jf-machine:item-1')?.isWatched, isFalse);
  });

  test('unscoped patch remains visible when the active client scope arrives later', () async {
    final provider = WatchStateStore();
    addTearDown(provider.dispose);

    await _emit(_event(changeType: WatchStateChangeType.watched, isNowWatched: true));
    provider.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});

    expect(provider.patchForGlobalKey('jf-machine:item-1')?.isWatched, isTrue);
  });

  test('newer active scoped patch wins over older unscoped patch', () async {
    final provider = WatchStateStore();
    addTearDown(provider.dispose);
    provider.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});

    await _emit(_event(changeType: WatchStateChangeType.unwatched, isNowWatched: false));
    await _emit(
      _event(changeType: WatchStateChangeType.watched, isNowWatched: true, cacheServerId: 'jf-machine/user-a'),
    );

    expect(provider.patchForGlobalKey('jf-machine:item-1')?.isWatched, isTrue);
  });

  test('explicit foreign scope is ignored when resolving the active scope', () async {
    final provider = WatchStateStore();
    addTearDown(provider.dispose);
    provider.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});

    await _emit(
      _event(changeType: WatchStateChangeType.watched, isNowWatched: true, cacheServerId: 'jf-machine/user-a'),
    );
    await _emit(
      _event(changeType: WatchStateChangeType.unwatched, isNowWatched: false, cacheServerId: 'jf-machine/user-b'),
    );

    expect(provider.patchForGlobalKey('jf-machine:item-1')?.isWatched, isTrue);
  });

  test('an ancestor patch reaches descendants through parentChain', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);

    await _emit(_event(changeType: WatchStateChangeType.watched, isNowWatched: true, itemId: 'show-1'));

    expect(store.patchForItem(_episode)?.isWatched, isTrue);
    expect(store.apply(_episode).isWatched, isTrue);
    // The episode's own key still has no patch — only resolution sees the ancestor.
    expect(store.patchForGlobalKey(_episode.globalKey), isNull);
  });

  test('newer container mark overrides an older per-item patch', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);

    await _emit(_event(changeType: WatchStateChangeType.unwatched, isNowWatched: false, itemId: 'episode-1'));
    await _emit(
      _event(changeType: WatchStateChangeType.watched, isNowWatched: true, itemId: 'season-1', parentChain: ['show-1']),
    );

    expect(store.patchForItem(_episode)?.isWatched, isTrue);
  });

  test('newer per-item patch overrides an older container mark', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);

    await _emit(_event(changeType: WatchStateChangeType.watched, isNowWatched: true, itemId: 'show-1'));
    await _emit(_event(changeType: WatchStateChangeType.unwatched, isNowWatched: false, itemId: 'episode-1'));

    expect(store.patchForItem(_episode)?.isWatched, isFalse);
  });

  test('ancestor patches resolve through the active client scope', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    store.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});

    await _emit(
      _event(
        changeType: WatchStateChangeType.watched,
        isNowWatched: true,
        itemId: 'show-1',
        cacheServerId: 'jf-machine/user-a',
      ),
    );

    expect(store.patchForItem(_episode)?.isWatched, isTrue);
  });

  test('applying a watched patch to a container also patches leaf counts', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);

    await _emit(_event(changeType: WatchStateChangeType.watched, isNowWatched: true, itemId: 'season-1'));

    final season = testMediaItem(
      id: 'season-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      parentId: 'show-1',
      serverId: 'jf-machine',
      leafCount: 10,
      viewedLeafCount: 3,
    );
    final resolved = store.apply(season);
    expect(resolved.viewedLeafCount, 10);
    expect(resolved.isWatched, isTrue);
  });

  test('hydrated parent and item patches retain persisted freshness', () {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    store.setHydratedPatches(const [
      HydratedWatchStatePatch(
        globalKey: 'jf-machine:show-1',
        patch: WatchStateSnapshot(isWatched: true, hasViewOffsetMs: true, viewOffsetMs: 0),
        updatedAt: 100,
        order: 1,
      ),
      HydratedWatchStatePatch(
        globalKey: 'jf-machine:episode-1',
        patch: WatchStateSnapshot(isWatched: false, hasViewOffsetMs: true, viewOffsetMs: 0),
        updatedAt: 200,
        order: 2,
      ),
    ]);

    final resolved = store.apply(_episode.copyWith(viewOffsetMs: 30000));
    expect(resolved.isWatched, isFalse);
    expect(resolved.viewOffsetMs, 0);
  });

  test('hydrated patches are isolated to the active client scope', () {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    store.setHydratedPatches(const [
      HydratedWatchStatePatch(
        globalKey: 'jf-machine/user-a:show-1',
        patch: WatchStateSnapshot(isWatched: true),
        updatedAt: 100,
        order: 1,
      ),
      HydratedWatchStatePatch(
        globalKey: 'jf-machine/user-b:show-1',
        patch: WatchStateSnapshot(isWatched: false),
        updatedAt: 100,
        order: 2,
      ),
    ]);

    store.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});
    expect(store.apply(_episode).isWatched, isTrue);
    store.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-b'});
    expect(store.apply(_episode).isWatched, isFalse);
  });

  group('authoritative observations supersede acknowledged patches (#1829)', () {
    /// The reporter's sequence: the Mac pauses an episode, another device
    /// advances the server, and a refresh must render the server's position
    /// rather than the Mac's.
    test('a fetch that started after the patch renders the server offset', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);

      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          itemId: 'episode-1',
          viewOffset: 1800000,
          serverAcknowledged: true,
        ),
      );
      final fresh = _episode.copyWith(viewOffsetMs: 2700000, durationMs: 3600000);
      expect(store.apply(fresh).viewOffsetMs, 1800000, reason: 'precondition: the stale patch still wins');

      store.recordObservations(
        [(item: fresh, clientScope: null)],
        watermark: store.observationWatermark,
        epoch: store.observationEpoch,
      );

      expect(store.apply(fresh).viewOffsetMs, 2700000);
      expect(store.patchForItem(fresh), isNull);
    });

    test('a patch recorded during the fetch survives its observation', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);

      // Watermark captured before the request, patch emitted while it is in
      // flight: the response is older than the local action and must lose.
      final watermark = store.observationWatermark;
      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          itemId: 'episode-1',
          viewOffset: 1800000,
          serverAcknowledged: true,
        ),
      );
      final fresh = _episode.copyWith(viewOffsetMs: 2700000, durationMs: 3600000);

      store.recordObservations([(item: fresh, clientScope: null)], watermark: watermark, epoch: store.observationEpoch);

      expect(store.apply(fresh).viewOffsetMs, 1800000);
    });

    test('an unacknowledged patch is never superseded by a read', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);

      // An offline write still owed to the server must outlive any fetch.
      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          itemId: 'episode-1',
          viewOffset: 1800000,
        ),
      );
      final fresh = _episode.copyWith(viewOffsetMs: 2700000, durationMs: 3600000);

      store.recordObservations(
        [(item: fresh, clientScope: null)],
        watermark: store.observationWatermark,
        epoch: store.observationEpoch,
      );

      expect(store.apply(fresh).viewOffsetMs, 1800000);
    });

    test('an observation from another store epoch is rejected', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);

      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          itemId: 'episode-1',
          viewOffset: 1800000,
          serverAcknowledged: true,
        ),
      );
      final fresh = _episode.copyWith(viewOffsetMs: 2700000, durationMs: 3600000);

      // A request issued before a profile switch, landing after it: its
      // watermark belongs to a store that no longer exists.
      store.recordObservations(
        [(item: fresh, clientScope: null)],
        watermark: store.observationWatermark,
        epoch: Object(),
      );

      expect(store.apply(fresh).viewOffsetMs, 1800000);
    });

    test('an older response cannot lower an observation already recorded', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);

      final stale = store.observationWatermark;
      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          itemId: 'episode-1',
          viewOffset: 1800000,
          serverAcknowledged: true,
        ),
      );
      final fresh = _episode.copyWith(viewOffsetMs: 2700000, durationMs: 3600000);

      store.recordObservations(
        [(item: fresh, clientScope: null)],
        watermark: store.observationWatermark,
        epoch: store.observationEpoch,
      );
      // A concurrent request that started earlier completes last.
      store.recordObservations([(item: fresh, clientScope: null)], watermark: stale, epoch: store.observationEpoch);

      expect(store.apply(fresh).viewOffsetMs, 2700000, reason: 'max() per key, so response order cannot matter');
    });

    test('suppressing an item does not expose an older ancestor patch', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);

      // Season marked unwatched first, then the episode played: without the
      // ancestor barrier, suppressing the episode entry would let the older
      // season patch win and render unwatched/0 — worse than either value.
      await _emit(
        _event(
          changeType: WatchStateChangeType.unwatched,
          isNowWatched: false,
          itemId: 'season-1',
          serverAcknowledged: true,
        ),
      );
      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          itemId: 'episode-1',
          viewOffset: 1800000,
          serverAcknowledged: true,
        ),
      );
      final fresh = _episode.copyWith(viewOffsetMs: 2700000, durationMs: 3600000, viewCount: 0);

      store.recordObservations(
        [(item: fresh, clientScope: null)],
        watermark: store.observationWatermark,
        epoch: store.observationEpoch,
      );

      expect(store.patchForItem(fresh), isNull);
      expect(store.apply(fresh).viewOffsetMs, 2700000);
    });

    test('an ancestor mark newer than the observation still reaches descendants', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);

      final fresh = _episode.copyWith(viewOffsetMs: 2700000, durationMs: 3600000);
      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          itemId: 'episode-1',
          viewOffset: 1800000,
          serverAcknowledged: true,
        ),
      );
      store.recordObservations(
        [(item: fresh, clientScope: null)],
        watermark: store.observationWatermark,
        epoch: store.observationEpoch,
      );
      // The container action happens after the fetch, so it must survive.
      await _emit(
        _event(
          changeType: WatchStateChangeType.watched,
          isNowWatched: true,
          itemId: 'season-1',
          serverAcknowledged: true,
        ),
      );

      expect(store.apply(fresh).isWatched, isTrue);
    });

    test('an unobserved sibling still sees the container mark', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);

      await _emit(
        _event(
          changeType: WatchStateChangeType.watched,
          isNowWatched: true,
          itemId: 'season-1',
          serverAcknowledged: true,
        ),
      );
      final observed = _episode.copyWith(viewCount: 0);
      final sibling = testMediaItem(
        id: 'episode-2',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.episode,
        parentId: 'season-1',
        grandparentId: 'show-1',
        serverId: 'jf-machine',
      );

      store.recordObservations(
        [(item: observed, clientScope: null)],
        watermark: store.observationWatermark,
        epoch: store.observationEpoch,
      );

      expect(store.apply(observed).isWatched, isFalse, reason: 'the observed child yields to the server');
      expect(store.apply(sibling).isWatched, isTrue, reason: 'the unobserved sibling keeps the container mark');
    });

    test('an observation under one client scope cannot suppress another scope', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);
      store.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-b'});

      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          itemId: 'episode-1',
          viewOffset: 1800000,
          cacheServerId: 'jf-machine/user-b',
          serverAcknowledged: true,
        ),
      );
      final fresh = _episode.copyWith(viewOffsetMs: 2700000, durationMs: 3600000);

      // User A's request returning after the switch back to B: the public
      // server id is shared, so keying by it would suppress B's watch state.
      store.recordObservations(
        [(item: fresh, clientScope: 'jf-machine/user-a')],
        watermark: store.observationWatermark,
        epoch: store.observationEpoch,
      );

      expect(store.apply(fresh).viewOffsetMs, 1800000);
    });

    test('a profile switch clears observations along with patches', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);

      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          itemId: 'episode-1',
          viewOffset: 1800000,
          serverAcknowledged: true,
        ),
      );
      final fresh = _episode.copyWith(viewOffsetMs: 2700000, durationMs: 3600000);
      store.recordObservations(
        [(item: fresh, clientScope: null)],
        watermark: store.observationWatermark,
        epoch: store.observationEpoch,
      );
      store.setActiveProfileId('profile-2');

      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          itemId: 'episode-1',
          viewOffset: 900000,
          serverAcknowledged: true,
        ),
      );

      expect(store.apply(fresh).viewOffsetMs, 900000, reason: 'a stale observation must not suppress the new patch');
    });
  });

  group('promotion settles an owed write (#1829)', () {
    test('a promoted patch becomes suppressible', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);

      final patchId = WatchStateNotifier().notifyProgress(item: _episode, viewOffset: 1800000, duration: 3600000);
      await Future<void>.delayed(Duration.zero);
      final fresh = _episode.copyWith(viewOffsetMs: 2700000, durationMs: 3600000);

      store.recordObservations(
        [(item: fresh, clientScope: null)],
        watermark: store.observationWatermark,
        epoch: store.observationEpoch,
      );
      expect(store.apply(fresh).viewOffsetMs, 1800000, reason: 'unacknowledged, so the read must not retire it');

      WatchPatchPromotionNotifier().promote(patchId!);
      await Future<void>.delayed(Duration.zero);

      // Promotion assigns a fresh sequence, so the observation that preceded
      // the write cannot suppress it; a later one can.
      expect(store.apply(fresh).viewOffsetMs, 1800000);
      store.recordObservations(
        [(item: fresh, clientScope: null)],
        watermark: store.observationWatermark,
        epoch: store.observationEpoch,
      );
      expect(store.apply(fresh).viewOffsetMs, 2700000);
    });

    test('promoting an unknown id is a no-op', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);

      await _emit(_event(changeType: WatchStateChangeType.progressUpdate, isNowWatched: false, viewOffset: 1800000));
      WatchPatchPromotionNotifier().promote(WatchPatchId.session(999999));
      await Future<void>.delayed(Duration.zero);

      expect(store.patchForGlobalKey('jf-machine:item-1')?.viewOffsetMs, 1800000);
    });
  });

  // The reporter's setup: Plex on macOS, where the client's cache scope is a
  // profile scope that differs from the public server id. The observation and
  // the patch must land on the same key or suppression silently never fires.
  group("the reporter's Plex handoff (#1829)", () {
    final plexScope = buildPlexProfileScopeId(serverId: ServerId('plex-machine'), profileId: 'profile-a');
    final plexEpisode = testMediaItem(
      id: 'episode-1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      serverId: 'plex-machine',
      durationMs: 3600000,
    );

    test('a refreshed row overrides the offset the Mac paused at', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);
      // Exactly how ProfileSessionScreen wires the map: serverId -> the
      // client's own cacheServerId.
      store.setActiveClientScopesByServer({'plex-machine': plexScope});

      // The Mac pauses with 30 minutes left. Plex persists position on every
      // timeline report, so the tracker acknowledges it.
      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          serverId: 'plex-machine',
          itemId: 'episode-1',
          cacheServerId: plexScope,
          viewOffset: 1800000,
          serverAcknowledged: true,
        ),
      );

      // Precondition: without an observation the local patch pins the row.
      // This is the bug as reported.
      final serverRow = plexEpisode.copyWith(viewOffsetMs: 2700000);
      expect(store.apply(serverRow).viewOffsetMs, 1800000);

      // The iPad advances the server to 15 minutes left; Refresh reads it back.
      final watermark = store.observationWatermark;
      store.recordObservations(
        [(item: serverRow, clientScope: plexScope)],
        watermark: watermark,
        epoch: store.observationEpoch,
      );

      expect(store.apply(serverRow).viewOffsetMs, 2700000);
    });

    test('a pre-refresh pause still pins, so a later local action is not lost', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);
      store.setActiveClientScopesByServer({'plex-machine': plexScope});

      final serverRow = plexEpisode.copyWith(viewOffsetMs: 2700000);
      final watermark = store.observationWatermark;
      store.recordObservations(
        [(item: serverRow, clientScope: plexScope)],
        watermark: watermark,
        epoch: store.observationEpoch,
      );

      // Paused after that read: newer than the watermark, so it must survive.
      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          serverId: 'plex-machine',
          itemId: 'episode-1',
          cacheServerId: plexScope,
          viewOffset: 3000000,
          serverAcknowledged: true,
        ),
      );

      expect(store.apply(serverRow).viewOffsetMs, 3000000);
    });

    test('an unscoped store neither pins nor mis-suppresses', () async {
      final store = WatchStateStore();
      addTearDown(store.dispose);
      // DownloadMetadataStore replaces the scope map with only the servers it
      // has downloads for, so a Plex server without downloads can end up
      // unscoped. The patch keys off the event's own cacheServerId, so both
      // sides miss together rather than leaving a stale pin behind.
      store.setActiveClientScopesByServer(const {});

      await _emit(
        _event(
          changeType: WatchStateChangeType.progressUpdate,
          isNowWatched: false,
          serverId: 'plex-machine',
          itemId: 'episode-1',
          cacheServerId: plexScope,
          viewOffset: 1800000,
          serverAcknowledged: true,
        ),
      );

      final serverRow = plexEpisode.copyWith(viewOffsetMs: 2700000);
      expect(store.apply(serverRow).viewOffsetMs, 2700000);
    });
  });
}
