import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/music/music_queue_controller.dart';
import 'package:plezy/services/music/music_session_store.dart';
import '../../test_helpers/media_items.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  MusicSessionStore store({String profileId = 'p1'}) => MusicSessionStore(database: db, profileId: profileId);

  MediaItem track(String id) =>
      testMediaItem(id: id, kind: MediaKind.track, title: 'Track $id', serverId: 'srv', durationMs: 180000);

  MusicQueueState state({
    required List<MediaItem> items,
    List<int>? order,
    int cursor = 0,
    bool shuffled = false,
    MusicRepeatMode repeatMode = MusicRepeatMode.off,
  }) => MusicQueueState(
    items: items,
    order: order ?? [for (var i = 0; i < items.length; i++) i],
    cursor: cursor,
    shuffled: shuffled,
    repeatMode: repeatMode,
  );

  test('round-trips queue state, provenance, and position', () async {
    final items = [track('a'), track('b'), track('c')];
    await store().save(
      MusicSessionSnapshot(
        queue: state(items: items, order: [2, 0, 1], cursor: 1, shuffled: true, repeatMode: MusicRepeatMode.all),
        playContext: const MusicPlayContext(title: 'Mixtape', kind: MusicPlayContextKind.playlist),
        position: const Duration(seconds: 93),
      ),
    );

    final loaded = await store().load();

    expect(loaded, isNotNull);
    expect([for (final t in loaded!.queue.items) t.id], ['a', 'b', 'c']);
    expect(loaded.queue.order, [2, 0, 1]);
    expect(loaded.queue.cursor, 1);
    expect(loaded.queue.shuffled, isTrue);
    expect(loaded.queue.repeatMode, MusicRepeatMode.all);
    expect(loaded.playContext?.title, 'Mixtape');
    expect(loaded.playContext?.kind, MusicPlayContextKind.playlist);
    expect(loaded.position, const Duration(seconds: 93));
    // The tracks must stay playable after the round trip.
    expect(loaded.queue.items.first.serverId, 'srv');
    expect(loaded.queue.items.first.durationMs, 180000);
  });

  test('a loaded shuffled state un-shuffles back to canonical order through the controller', () async {
    final items = [track('a'), track('b'), track('c')];
    await store().save(
      MusicSessionSnapshot(
        queue: state(items: items, order: [2, 0, 1], cursor: 0, shuffled: true),
        playContext: null,
        position: Duration.zero,
      ),
    );

    final loaded = await store().load();
    final controller = MusicQueueController();
    expect(controller.restoreState(loaded!.queue), isTrue);
    expect([for (final t in controller.queue) t.id], ['c', 'a', 'b']);

    controller.toggleShuffle();
    expect([for (final t in controller.queue) t.id], ['a', 'b', 'c']);
    expect(controller.current!.id, 'c');
  });

  test('updateProgress rewrites cursor and position without touching the queue', () async {
    final items = [track('a'), track('b')];
    await store().save(
      MusicSessionSnapshot(
        queue: state(items: items),
        playContext: null,
        position: Duration.zero,
      ),
    );

    await store().updateProgress(cursor: 1, position: const Duration(seconds: 30));

    final loaded = await store().load();
    expect(loaded!.queue.cursor, 1);
    expect(loaded.position, const Duration(seconds: 30));
    expect([for (final t in loaded.queue.items) t.id], ['a', 'b']);
  });

  test('updateProgress without a snapshot row is a no-op', () async {
    await store().updateProgress(cursor: 3, position: const Duration(seconds: 5));
    expect(await store().load(), isNull);
  });

  test('clear removes the row', () async {
    await store().save(
      MusicSessionSnapshot(
        queue: state(items: [track('a')]),
        playContext: null,
        position: Duration.zero,
      ),
    );
    await store().clear();
    expect(await store().load(), isNull);
  });

  test('profiles are isolated', () async {
    await store().save(
      MusicSessionSnapshot(
        queue: state(items: [track('a')]),
        playContext: null,
        position: Duration.zero,
      ),
    );
    expect(await store(profileId: 'p2').load(), isNull);
    expect(await store().load(), isNotNull);
  });

  test('malformed queue JSON discards the whole snapshot', () async {
    await db.upsertMusicSession(
      MusicSessionRow(
        profileId: 'p1',
        queueJson: 'not json',
        orderJson: '[0]',
        cursor: 0,
        shuffled: false,
        repeatMode: 'off',
        contextTitle: null,
        contextKind: null,
        positionMs: 0,
        updatedAt: 0,
      ),
    );
    expect(await store().load(), isNull);
  });

  test('an unknown repeat-mode id discards the snapshot', () async {
    await db.upsertMusicSession(
      MusicSessionRow(
        profileId: 'p1',
        queueJson: '[]',
        orderJson: '[]',
        cursor: 0,
        shuffled: false,
        repeatMode: 'bogus',
        contextTitle: null,
        contextKind: null,
        positionMs: 0,
        updatedAt: 0,
      ),
    );
    expect(await store().load(), isNull);
  });

  test('oversized queues persist a playback-order window around the cursor', () async {
    final items = [for (var i = 0; i < 1050; i++) track('i$i')];
    await store().save(
      MusicSessionSnapshot(
        queue: state(items: items, cursor: 700),
        playContext: null,
        position: Duration.zero,
      ),
    );

    final loaded = await store().load();
    expect(loaded!.queue.items, hasLength(MusicSessionStore.maxPersistedTracks));
    // Window start = (700 - 250) clamped to [0, 50] = 50; identity permutation.
    expect(loaded.queue.items.first.id, 'i50');
    expect(loaded.queue.items.last.id, 'i1049');
    expect(loaded.queue.cursor, 650);
    expect(loaded.queue.order.first, 0);
    expect(loaded.queue.order.last, MusicSessionStore.maxPersistedTracks - 1);
    // The windowed state must satisfy controller invariants.
    expect(MusicQueueController().restoreState(loaded.queue), isTrue);
  });
}
