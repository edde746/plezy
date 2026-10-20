import 'dart:async';

import 'package:clock/clock.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;

import '../../mpv/mpv.dart';
import '../models/watch_copy.dart';

/// The player screen's own commands, which act on the player without going
/// back through the room: the adapter is how the room drives the player, so
/// none of these may be routed to the party.
class PlayerCommands {
  const PlayerCommands({required this.play, required this.pause, required this.seek, required this.setRate});

  /// Starts playback; throws when the player refuses to (a car that requires
  /// distraction optimization), which the SDK reports as `PlayBlockedEvent`.
  final Future<void> Function() play;
  final Future<void> Function() pause;

  /// The screen's seek, which also opens another file of a stacked item.
  final Future<void> Function(Duration position) seek;
  final Future<void> Function(double rate) setRate;
}

/// Plezy's player behind the Open Watch Party SDK (SDK.md §16.4): one adapter
/// per opened file, attached with the [copy] that file is.
///
/// Reads come from the player's state. Commands finish when the player has
/// done them; a seek first waits until the player takes seeks (mpv refuses a
/// seek while it is still opening the file) and then until it lands. Once
/// [release]d, every command and wait returns at once, so the party's release
/// completes and the screen can dispose of the player.
final class PlezyPlayerAdapter extends owp.PlayerAdapter {
  PlezyPlayerAdapter({required this.player, required this.copy, required this.commands});

  /// The longest a seek waits for the player to take seeks, and then to land.
  static const Duration landingTimeout = Duration(seconds: 10);
  static const Duration _poll = Duration(milliseconds: 50);

  final Player player;
  final WatchCopy copy;
  final PlayerCommands commands;

  final Completer<void> _released = Completer<void>();
  final Set<Future<void>> _holds = {};

  bool get isReleased => _released.isCompleted;

  /// Ends every wait and makes later commands return at once.
  void release() {
    if (!_released.isCompleted) _released.complete();
  }

  /// Holds the room off until [until] completes: the player reads as not
  /// ready, so the room waits, and commands wait for every hold. Used while
  /// the screen still prepares the file or drives the player itself
  /// (start-up, a reload, a display-mode switch).
  void hold(Future<void> until) {
    final held = until.catchError((Object _) {});
    _holds.add(held);
    unawaited(held.whenComplete(() => _holds.remove(held)));
  }

  /// Whether a [hold] is pending.
  bool get isHeld => _holds.isNotEmpty;

  bool get _usable => !isReleased && !player.disposed;

  @override
  int get positionMs => player.currentPosition.inMilliseconds;

  @override
  int? get durationMs {
    final reported = player.state.duration.inMilliseconds;
    if (reported > 0) return reported;
    return copy.durationMs;
  }

  @override
  bool get paused => !player.state.playing;

  @override
  bool get buffering => player.state.buffering;

  @override
  bool get firstFrameShown => _holds.isEmpty && player.state.hasRenderedFrame;

  @override
  bool get canSetRate => !player.audioPassthroughActive;

  @override
  Future<void> play() async {
    if (!await _ready()) return;
    await _orReleased(commands.play());
  }

  @override
  Future<void> pause() async {
    if (!await _ready()) return;
    await _orReleased(commands.pause());
  }

  @override
  Future<void> setRate(double rate) async {
    if (!await _ready()) return;
    await _orReleased(commands.setRate(rate));
  }

  @override
  Future<void> seek(int positionMs) async {
    if (!await _ready()) return;
    // mpv refuses a seek while it opens the file, and the file's own first
    // frame would then pass for the seek's landing.
    if (!await _until(() => player.state.seekable || player.state.hasRenderedFrame)) return;
    final target = Duration(milliseconds: positionMs);
    var restarted = false;
    final restart = player.streams.playbackRestart.listen((_) => restarted = true);
    try {
      await _orReleased(commands.seek(target));
      final issued = clock.stopwatch()..start();
      await _until(
        () =>
            restarted ||
            (issued.elapsedMilliseconds >= 300 &&
                !player.state.buffering &&
                (player.currentPosition - target).inMilliseconds.abs() <= 1000),
      );
    } finally {
      // Cancelling stops the listener at once; its future isn't the command's.
      unawaited(restart.cancel());
    }
  }

  /// [command], or nothing once the adapter is released: the screen's command
  /// may wait on a player that is going away. A refusal still throws.
  Future<void> _orReleased(Future<void> command) => Future.any([command, _released.future]);

  /// Waits out every hold; false when the adapter was released meanwhile.
  Future<bool> _ready() async {
    while (_holds.isNotEmpty && !isReleased) {
      await Future.any([Future.wait(_holds.toList()), _released.future]);
    }
    return _usable;
  }

  /// Polls [done] until it holds, the adapter is released or [landingTimeout]
  /// passes. False only when released.
  Future<bool> _until(bool Function() done) async {
    final watch = clock.stopwatch()..start();
    while (_usable && !done() && watch.elapsed < landingTimeout) {
      await Future.any([Future<void>.delayed(_poll), _released.future]);
    }
    return _usable;
  }
}
