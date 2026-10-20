import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/watch_together/models/watch_copy.dart';
import 'package:plezy/watch_together/services/player_adapter.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/player_streams.dart';
import '../test_helpers/watch_together_fakes.dart';

/// [FakeSyncPlayer] whose playback-restart subscriptions cancel inside the
/// fake zone. A broadcast subscription's `cancel()` future belongs to the root
/// zone, which `fakeAsync` never runs, and the adapter's seek awaits it.
class _Player extends FakeSyncPlayer {
  _Player({super.position, super.seekable, super.hasRenderedFrame});

  @override
  PlayerStreams get streams => emptyPlayerStreams(
    playbackRestart: Stream<void>.multi((controller) {
      final subscription = super.streams.playbackRestart.listen(controller.addSync);
      controller.onCancel = () {
        unawaited(subscription.cancel());
        return Future<void>.value();
      };
    }, isBroadcast: true),
  );
}

WatchCopy _copy({int? durationMs = 7020000, List<MediaVersion>? versions}) {
  final item = testMediaItem(
    id: 'movie-1',
    title: 'Alien',
    serverId: 'nas',
    durationMs: durationMs,
    mediaVersions: versions,
  );
  return WatchCopy.of(item, versions?.first);
}

({PlezyPlayerAdapter adapter, FakeSyncPlayer player, List<String> commands}) _adapter({
  FakeSyncPlayer? player,
  WatchCopy? copy,
}) {
  final fake = player ?? _Player(hasRenderedFrame: true);
  final commands = <String>[];
  final adapter = PlezyPlayerAdapter(
    player: fake,
    copy: copy ?? _copy(),
    commands: PlayerCommands(
      play: () {
        commands.add('play');
        return fake.play();
      },
      pause: () {
        commands.add('pause');
        return fake.pause();
      },
      seek: (position) {
        commands.add('seek:${position.inMilliseconds}');
        return fake.seek(position);
      },
      setRate: (rate) {
        commands.add('rate:$rate');
        return fake.setRate(rate);
      },
    ),
  );
  return (adapter: adapter, player: fake, commands: commands);
}

void main() {
  group('reads', () {
    test('position, pause and buffering come from the player', () {
      final (:adapter, :player, commands: _) = _adapter(
        player: FakeSyncPlayer(position: const Duration(seconds: 42), playing: true, buffering: true),
      );

      expect(adapter.positionMs, 42000);
      expect(adapter.paused, isFalse);
      expect(adapter.buffering, isTrue);

      player
        ..emitPlaying(false)
        ..emitBuffering(false)
        ..setPosition(const Duration(milliseconds: 43210));
      expect(adapter.paused, isTrue);
      expect(adapter.buffering, isFalse);
      expect(adapter.positionMs, 43210);
    });

    test('the player length wins; before it knows one the copy length stands in', () {
      final (:adapter, :player, commands: _) = _adapter(player: FakeSyncPlayer(duration: Duration.zero));
      expect(adapter.durationMs, 7020000);

      player.emitDuration(const Duration(milliseconds: 7021500));
      expect(adapter.durationMs, 7021500);

      final unknown = _adapter(
        player: FakeSyncPlayer(duration: Duration.zero),
        copy: _copy(durationMs: null),
      );
      expect(unknown.adapter.durationMs, isNull);

      final versioned = _adapter(
        player: FakeSyncPlayer(duration: Duration.zero),
        copy: _copy(
          versions: [
            const MediaVersion(
              id: 'cut',
              parts: [MediaPart(id: 'p', durationMs: 7380000)],
            ),
            const MediaVersion(id: 'other'),
          ],
        ),
      );
      expect(versioned.adapter.durationMs, 7380000, reason: "the copy's own version, not the item");
    });

    test('the first frame counts only once a hold is over', () {
      fakeAsync((async) {
        final (:adapter, :player, commands: _) = _adapter(player: FakeSyncPlayer());
        expect(adapter.firstFrameShown, isFalse);
        player.emitPlaybackRestart();
        expect(adapter.firstFrameShown, isTrue);

        final first = Completer<void>();
        final second = Completer<void>();
        adapter.hold(first.future);
        expect(adapter.firstFrameShown, isFalse);
        adapter.hold(second.future);
        first.complete();
        async.flushMicrotasks();
        expect(adapter.firstFrameShown, isFalse, reason: 'a replaced hold ending does not end the newer one');

        second.completeError(StateError('display mode switch failed'));
        async.flushMicrotasks();
        expect(adapter.firstFrameShown, isTrue, reason: 'a failed hold still ends');
      });
    });

    test('rate changes are offered unless audio passes through', () {
      final (:adapter, :player, commands: _) = _adapter();
      expect(adapter.canSetRate, isTrue);
      player.audioPassthroughActive = true;
      expect(adapter.canSetRate, isFalse);
    });

    test("seeks land exactly; a file that shows frames but can't seek is followed by rate only", () {
      expect(_adapter(player: _Player(seekable: true, hasRenderedFrame: true)).adapter.seekAccuracyMs, 0);
      // Still opening: not known yet, so the room may seek once it can.
      expect(_adapter(player: _Player(seekable: false)).adapter.seekAccuracyMs, 0);
      expect(
        _adapter(player: _Player(seekable: false, hasRenderedFrame: true)).adapter.seekAccuracyMs,
        PlezyPlayerAdapter.cannotSeekAccuracyMs,
      );
    });
  });

  group('commands', () {
    test('play, pause and rate go to the screen commands', () {
      fakeAsync((async) {
        final (:adapter, :player, :commands) = _adapter();
        unawaited(adapter.play());
        async.flushMicrotasks();
        expect(player.state.playing, isTrue);
        unawaited(adapter.setRate(1.5));
        unawaited(adapter.pause());
        async.flushMicrotasks();
        expect(commands, ['play', 'rate:1.5', 'pause']);
        expect(player.state.playing, isFalse);
      });
    });

    test('a refused play throws to the SDK', () async {
      final (:adapter, :player, commands: _) = _adapter();
      player.nextCommandError = StateError('distraction optimization');
      await expectLater(adapter.play(), throwsStateError);
    });

    test('commands wait for a hold', () {
      fakeAsync((async) {
        final (:adapter, player: _, :commands) = _adapter();
        final hold = Completer<void>();
        adapter.hold(hold.future);

        var done = false;
        unawaited(adapter.play().then((_) => done = true));
        async.elapse(const Duration(seconds: 5));
        expect(commands, isEmpty);
        expect(done, isFalse);

        hold.complete();
        async.flushMicrotasks();
        expect(commands, ['play']);
        expect(done, isTrue);
      });
    });

    test('a released adapter returns at once and commands nothing, also from inside a hold', () {
      fakeAsync((async) {
        final (:adapter, player: _, :commands) = _adapter();
        adapter.hold(Completer<void>().future);
        var held = false;
        unawaited(adapter.play().then((_) => held = true));
        async.flushMicrotasks();
        expect(held, isFalse);

        adapter.release();
        async.flushMicrotasks();
        expect(held, isTrue);
        expect(adapter.isReleased, isTrue);

        final done = <String>[];
        unawaited(adapter.pause().then((_) => done.add('pause')));
        unawaited(adapter.seek(1000).then((_) => done.add('seek')));
        unawaited(adapter.setRate(2).then((_) => done.add('rate')));
        async.flushMicrotasks();
        expect(done, ['pause', 'seek', 'rate']);
        expect(commands, isEmpty);
      });
    });

    test('a disposed player is not commanded', () {
      fakeAsync((async) {
        final (:adapter, :player, :commands) = _adapter();
        unawaited(player.dispose());
        async.flushMicrotasks();
        var done = false;
        unawaited(adapter.seek(1000).then((_) => done = true));
        unawaited(adapter.play());
        async.flushMicrotasks();
        expect(done, isTrue);
        expect(commands, isEmpty);
      });
    });
  });

  group('seek', () {
    test('lands on the playback restart', () {
      fakeAsync((async) {
        final (:adapter, :player, :commands) = _adapter();
        var landed = false;
        unawaited(adapter.seek(60000).then((_) => landed = true));
        async.flushMicrotasks();

        expect(commands, ['seek:60000']);
        expect(landed, isTrue);
        expect(player.currentPosition, const Duration(minutes: 1));
      });
    });

    test('waits until the player takes seeks before issuing one', () {
      fakeAsync((async) {
        final (:adapter, :player, :commands) = _adapter(player: _Player(seekable: false));
        var landed = false;
        unawaited(adapter.seek(60000).then((_) => landed = true));
        async.elapse(const Duration(seconds: 2));
        expect(commands, isEmpty, reason: 'mpv refuses a seek while it opens the file');

        player.emitPlaybackRestart();
        async.elapse(const Duration(milliseconds: 100));
        expect(commands, ['seek:60000']);
        expect(landed, isTrue);
      });
    });

    test('without a restart, lands once the position is there and the player is not buffering', () {
      fakeAsync((async) {
        final player = _Player(hasRenderedFrame: true)..emitRestartOnSeek = false;
        final (:adapter, player: _, :commands) = _adapter(player: player);
        var landed = false;
        unawaited(adapter.seek(60000).then((_) => landed = true));
        player.emitBuffering(true);
        async.elapse(const Duration(seconds: 1));
        expect(commands, ['seek:60000']);
        expect(landed, isFalse, reason: 'still buffering at the target');

        player.emitBuffering(false);
        async.elapse(const Duration(milliseconds: 100));
        expect(landed, isTrue);
      });
    });

    test('does not count the old position as landed in its first 300 ms', () {
      fakeAsync((async) {
        final player = _Player(hasRenderedFrame: true, position: const Duration(seconds: 60))
          ..emitRestartOnSeek = false;
        final (:adapter, player: _, commands: _) = _adapter(player: player);
        var landed = false;
        unawaited(adapter.seek(60500).then((_) => landed = true));
        async.elapse(const Duration(milliseconds: 200));
        expect(landed, isFalse);
        async.elapse(const Duration(milliseconds: 200));
        expect(landed, isTrue);
      });
    });

    test('gives up at the landing timeout', () {
      fakeAsync((async) {
        final player = _Player(hasRenderedFrame: true)..emitRestartOnSeek = false;
        final (:adapter, player: _, commands: _) = _adapter(player: player);
        var landed = false;
        unawaited(
          adapter.seek(60000).then((_) {
            landed = true;
          }),
        );
        async.flushMicrotasks();
        player.setPosition(Duration.zero);
        async.elapse(PlezyPlayerAdapter.landingTimeout - const Duration(milliseconds: 100));
        expect(landed, isFalse);
        async.elapse(const Duration(milliseconds: 200));
        expect(landed, isTrue);
      });
    });

    test('a release ends the wait for the landing', () {
      fakeAsync((async) {
        final player = _Player(hasRenderedFrame: true)..emitRestartOnSeek = false;
        final (:adapter, player: _, commands: _) = _adapter(player: player);
        var landed = false;
        unawaited(adapter.seek(60000).then((_) => landed = true));
        async.flushMicrotasks();
        player.setPosition(Duration.zero);
        async.elapse(const Duration(seconds: 1));
        expect(landed, isFalse);

        adapter.release();
        async.flushMicrotasks();
        expect(landed, isTrue);
      });
    });

    test('a failed seek throws to the SDK', () async {
      final (:adapter, :player, commands: _) = _adapter();
      player.nextCommandError = StateError('seek refused');
      await expectLater(adapter.seek(1000), throwsStateError);
    });
  });
}
