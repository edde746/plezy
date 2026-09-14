import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/music/music_queue_controller.dart';
import '../../test_helpers/media_items.dart';

MediaItem _track(String id) =>
    testMediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.track, title: 'Track $id', serverId: 'srv');

List<String> _ids(List<MediaItem> items) => [for (final i in items) i.id];

void main() {
  final tracks = [for (var i = 0; i < 6; i++) _track('t$i')];

  MusicQueueController controller({int seed = 42}) => MusicQueueController(random: Random(seed));

  group('load', () {
    test('starts at startIndex in canonical order', () {
      final q = controller()..load(tracks, startIndex: 2);
      expect(_ids(q.queue), ['t0', 't1', 't2', 't3', 't4', 't5']);
      expect(q.cursor, 2);
      expect(q.current!.id, 't2');
      expect(q.shuffled, isFalse);
    });

    test('shuffle anchors the start track first', () {
      final q = controller()..load(tracks, startIndex: 3, shuffle: true);
      expect(q.shuffled, isTrue);
      expect(q.cursor, 0);
      expect(q.current!.id, 't3');
      expect(_ids(q.queue).first, 't3');
      expect(_ids(q.queue).toSet(), _ids(tracks).toSet());
    });

    test('shuffle without a start index randomizes the head too (#1811)', () {
      // A shuffle launch has no track that must play first, so the head must
      // be drawn from the whole list. Anchoring the default index 0 made
      // every shuffled playlist open on its first track.
      final heads = <String>{};
      for (var seed = 0; seed < 8; seed++) {
        final q = controller(seed: seed)..load(tracks, shuffle: true);
        expect(q.shuffled, isTrue);
        expect(q.cursor, 0);
        expect(_ids(q.queue).toSet(), _ids(tracks).toSet());
        heads.add(q.current!.id);
      }
      expect(heads.length, greaterThan(1), reason: 'head stayed pinned to one track across seeds');
    });

    test('empty load leaves an idle queue', () {
      final q = controller()..load(const []);
      expect(q.isEmpty, isTrue);
      expect(q.cursor, -1);
      expect(q.current, isNull);
      expect(q.nextIndex(), isNull);
    });
  });

  group('advancement (nextIndex/previousIndex)', () {
    test('repeat off walks forward and ends after the last track', () {
      final q = controller()..load(tracks, startIndex: 4);
      expect(q.nextIndex(), 5);
      q.jumpTo(5);
      expect(q.nextIndex(), isNull);
      expect(q.nextIndex(manual: true), isNull);
    });

    test('repeat all wraps both directions', () {
      final q = controller()..load(tracks, startIndex: 5);
      q.repeatMode = MusicRepeatMode.all;
      expect(q.nextIndex(), 0);
      q.jumpTo(0);
      expect(q.previousIndex(), 5);
    });

    test('repeat one repeats naturally but steps on manual next', () {
      final q = controller()..load(tracks, startIndex: 1);
      q.repeatMode = MusicRepeatMode.one;
      expect(q.nextIndex(), 1);
      expect(q.nextIndex(manual: true), 2);
    });

    test('repeat one on the last track ends on manual next', () {
      final q = controller()..load(tracks, startIndex: 5);
      q.repeatMode = MusicRepeatMode.one;
      expect(q.nextIndex(), 5);
      expect(q.nextIndex(manual: true), isNull);
    });

    test('previousIndex steps back and stops at the head with repeat off', () {
      final q = controller()..load(tracks, startIndex: 1);
      expect(q.previousIndex(), 0);
      q.jumpTo(0);
      expect(q.previousIndex(), isNull);
    });
  });

  group('jumpTo', () {
    test('moves the cursor within bounds only', () {
      final q = controller()..load(tracks);
      q.jumpTo(4);
      expect(q.current!.id, 't4');
      q.jumpTo(99);
      expect(q.cursor, 4);
      q.jumpTo(-1);
      expect(q.cursor, 4);
    });
  });

  group('addNext / addToEnd', () {
    test('addNext inserts directly after the current track', () {
      final q = controller()..load(tracks, startIndex: 2);
      q.addNext([_track('n1'), _track('n2')]);
      expect(_ids(q.queue), ['t0', 't1', 't2', 'n1', 'n2', 't3', 't4', 't5']);
      expect(q.current!.id, 't2');
    });

    test('addToEnd appends after everything', () {
      final q = controller()..load(tracks, startIndex: 2);
      q.addToEnd([_track('e1')]);
      expect(_ids(q.queue).last, 'e1');
      expect(q.current!.id, 't2');
    });

    test('added tracks survive an unshuffle in canonical order', () {
      final q = controller()..load(tracks, startIndex: 0, shuffle: true);
      q.addToEnd([_track('e1')]);
      q.toggleShuffle(); // off — canonical = insertion order
      expect(_ids(q.queue), ['t0', 't1', 't2', 't3', 't4', 't5', 'e1']);
    });
  });

  group('removeAt', () {
    test('before the cursor shifts the cursor back', () {
      final q = controller()..load(tracks, startIndex: 3);
      final wasCurrent = q.removeAt(1);
      expect(wasCurrent, isFalse);
      expect(q.current!.id, 't3');
      expect(q.cursor, 2);
      expect(_ids(q.queue), ['t0', 't2', 't3', 't4', 't5']);
    });

    test('after the cursor leaves the cursor alone', () {
      final q = controller()..load(tracks, startIndex: 3);
      expect(q.removeAt(5), isFalse);
      expect(q.current!.id, 't3');
      expect(q.cursor, 3);
    });

    test('at the cursor keeps the cursor on the following track', () {
      final q = controller()..load(tracks, startIndex: 3);
      expect(q.removeAt(3), isTrue);
      expect(q.cursor, 3);
      expect(q.current!.id, 't4');
    });

    test('at the cursor on the last track clamps back', () {
      final q = controller()..load(tracks, startIndex: 5);
      expect(q.removeAt(5), isTrue);
      expect(q.cursor, 4);
      expect(q.current!.id, 't4');
    });

    test('removing the only track empties the queue', () {
      final q = controller()..load([_track('solo')]);
      expect(q.removeAt(0), isTrue);
      expect(q.isEmpty, isTrue);
      expect(q.cursor, -1);
    });
  });

  group('reorder (move)', () {
    test('moving the current track moves the cursor with it', () {
      final q = controller()..load(tracks, startIndex: 2);
      q.move(2, 4);
      expect(q.cursor, 4);
      expect(q.current!.id, 't2');
      expect(_ids(q.queue), ['t0', 't1', 't3', 't4', 't2', 't5']);
    });

    test('moving an entry across the cursor adjusts it', () {
      final q = controller()..load(tracks, startIndex: 2);
      q.move(0, 5);
      expect(q.cursor, 1);
      expect(q.current!.id, 't2');
      q.move(5, 0);
      expect(q.cursor, 2);
      expect(q.current!.id, 't2');
    });

    test('moving entries on one side keeps the cursor', () {
      final q = controller()..load(tracks, startIndex: 2);
      q.move(3, 5);
      expect(q.cursor, 2);
      expect(q.current!.id, 't2');
    });
  });

  group('toggleShuffle', () {
    test('on: current track anchors first, rest shuffled after', () {
      final q = controller()..load(tracks, startIndex: 2);
      q.toggleShuffle();
      expect(q.shuffled, isTrue);
      expect(q.cursor, 0);
      expect(q.current!.id, 't2');
      expect(_ids(q.queue).toSet(), _ids(tracks).toSet());
    });

    test('off: canonical order restored, cursor follows current', () {
      final q = controller()..load(tracks, startIndex: 2);
      q.toggleShuffle();
      q.jumpTo(3); // some shuffled position
      final current = q.current!.id;
      q.toggleShuffle();
      expect(q.shuffled, isFalse);
      expect(_ids(q.queue), ['t0', 't1', 't2', 't3', 't4', 't5']);
      expect(q.current!.id, current);
    });
  });

  group('clearUpcoming', () {
    test('drops everything after the current track', () {
      final q = controller()..load(tracks, startIndex: 2);
      q.clearUpcoming();
      expect(_ids(q.queue), ['t0', 't1', 't2']);
      expect(q.current!.id, 't2');
      expect(q.nextIndex(), isNull);
    });

    test('while shuffled also drops the canonical items', () {
      final q = controller()..load(tracks, startIndex: 0, shuffle: true);
      final kept = _ids(q.queue.sublist(0, 2));
      q.jumpTo(1);
      q.clearUpcoming();
      expect(_ids(q.queue), kept);
      q.toggleShuffle();
      expect(_ids(q.queue).toSet(), kept.toSet());
      expect(q.current!.id, kept[1]);
    });
  });

  group('captureState/restoreState (#2148)', () {
    test('round-trips the shuffle permutation, cursor, and repeat mode', () {
      final q = controller()..load(tracks, startIndex: 2, shuffle: true);
      q.repeatMode = MusicRepeatMode.all;

      final restored = controller(seed: 7);
      expect(restored.restoreState(q.captureState()), isTrue);

      expect(_ids(restored.queue), _ids(q.queue));
      expect(restored.cursor, q.cursor);
      expect(restored.current!.id, 't2');
      expect(restored.shuffled, isTrue);
      expect(restored.repeatMode, MusicRepeatMode.all);

      // The canonical order survived, so un-shuffling recovers it.
      restored.toggleShuffle();
      expect(_ids(restored.queue), _ids(tracks));
      expect(restored.current!.id, 't2');
    });

    test('captured state is a copy, not a live view of the queue', () {
      final q = controller()..load(tracks);
      final state = q.captureState();
      q.removeAt(0);
      expect(state.items, hasLength(tracks.length));
      expect(state.order, hasLength(tracks.length));
    });

    test('rejects corrupt states without touching the queue', () {
      final q = controller()..load(tracks, startIndex: 1);
      final before = _ids(q.queue);

      MusicQueueState corrupt({List<MediaItem>? items, List<int>? order, int cursor = 0}) => MusicQueueState(
        items: items ?? tracks,
        order: order ?? [for (var i = 0; i < tracks.length; i++) i],
        cursor: cursor,
        shuffled: false,
        repeatMode: MusicRepeatMode.off,
      );

      expect(q.restoreState(corrupt(items: const [])), isFalse);
      expect(q.restoreState(corrupt(order: [0, 1])), isFalse, reason: 'order length mismatch');
      expect(q.restoreState(corrupt(order: [0, 0, 1, 2, 3, 4])), isFalse, reason: 'duplicate order entry');
      expect(q.restoreState(corrupt(order: [0, 1, 2, 3, 4, 6])), isFalse, reason: 'order index out of range');
      expect(q.restoreState(corrupt(cursor: 6)), isFalse, reason: 'cursor out of range');
      expect(q.restoreState(corrupt(cursor: -1)), isFalse);

      expect(_ids(q.queue), before);
      expect(q.cursor, 1);
    });
  });
}
