import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/theme_song_controller.dart';

class _Gate {
  final entered = Completer<void>();
  final _released = Completer<void>();

  Future<void> wait() {
    if (!entered.isCompleted) entered.complete();
    return _released.future;
  }

  void release() {
    if (!_released.isCompleted) _released.complete();
  }
}

class _FakePlayer implements Player {
  _FakePlayer(this.events, this.name);

  final List<String> events;
  final String name;
  final volumes = <double>[];
  final opened = <String>[];
  final openPlayFlags = <bool>[];
  final volumeGate = _Gate();
  final openGate = _Gate();
  final disposeGate = _Gate();
  int plays = 0;
  int focusRequests = 0;
  int disposals = 0;

  @override
  Future<void> setVolume(double volume) async {
    events.add('$name.volume');
    volumes.add(volume);
    await volumeGate.wait();
  }

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
    Duration timelineOffset = Duration.zero,
  }) async {
    events.add('$name.open');
    opened.add(media.uri);
    openPlayFlags.add(play);
    await openGate.wait();
  }

  @override
  Future<bool> requestAudioFocus() async {
    events.add('$name.focus');
    focusRequests++;
    return true;
  }

  @override
  Future<void> play() async {
    events.add('$name.play');
    plays++;
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    events.add('$name.dispose');
    disposals++;
    await disposeGate.wait();
    events.add('$name.disposed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _drain() => Future<void>.delayed(Duration.zero);

void main() {
  final coordinator = PlaybackCoordinator.instance;
  late List<String> events;
  late List<_FakePlayer> players;
  late List<ThemeSongController> controllers;

  _FakePlayer player(String name, {bool holdVolume = false, bool holdOpen = false, bool holdDispose = false}) {
    final result = _FakePlayer(events, name);
    players.add(result);
    if (!holdVolume) result.volumeGate.release();
    if (!holdOpen) result.openGate.release();
    if (!holdDispose) result.disposeGate.release();
    return result;
  }

  ThemeSongController controller(
    Player Function() factory, {
    Duration grace = const Duration(milliseconds: 20),
    Duration fadeIn = Duration.zero,
    Duration fadeOut = Duration.zero,
  }) {
    final result = ThemeSongController(
      playerFactory: factory,
      coordinator: coordinator,
      releaseGrace: grace,
      fadeIn: fadeIn,
      fadeOut: fadeOut,
    );
    controllers.add(result);
    return result;
  }

  Player Function() sequence(List<_FakePlayer> list) {
    var created = 0;
    return () => list[created++];
  }

  setUp(() {
    events = [];
    players = [];
    controllers = [];
  });

  tearDown(() async {
    for (final player in players) {
      player.volumeGate.release();
      player.openGate.release();
      player.disposeGate.release();
    }
    for (final controller in controllers) {
      await controller.stop();
    }
  });

  final ownerA = Object();
  final ownerB = Object();

  test('awaits volume before opening and opens paused before play without audio focus', () async {
    final audio = player('theme', holdVolume: true);
    final theme = controller(() => audio);
    final start = theme.request(ownerA, resolveUrl: () async => 'https://example.com/theme.mp3', volume: 17);
    await audio.volumeGate.entered.future;
    expect(audio.volumes, [17]);
    expect(audio.opened, isEmpty);
    expect(audio.plays, 0);
    audio.volumeGate.release();
    await start;
    expect(audio.opened, ['https://example.com/theme.mp3']);
    expect(audio.openPlayFlags, [false]);
    expect(events, ['theme.volume', 'theme.open', 'theme.play']);
    expect(audio.focusRequests, 0);
  });

  for (final cancel in ['stop', 'release']) {
    test('late URL after $cancel never creates a player', () async {
      final url = Completer<String?>();
      final resolving = Completer<void>();
      var created = 0;
      final theme = controller(() {
        created++;
        return player('late');
      });
      final start = theme.request(
        ownerA,
        resolveUrl: () {
          resolving.complete();
          return url.future;
        },
        volume: 30,
      );
      await resolving.future;
      if (cancel == 'stop') {
        await theme.stop();
      } else {
        theme.release(ownerA);
      }
      url.complete('https://example.com/late.mp3');
      await start;
      expect(created, 0);
      expect(events, isEmpty);
    });
  }

  test('a new owner with the same theme keeps it playing', () async {
    final audio = player('theme');
    var created = 0;
    final theme = controller(() {
      created++;
      return audio;
    });
    await theme.request(ownerA, resolveUrl: () async => 'show-theme', volume: 30);
    theme.release(ownerA);
    await theme.request(ownerB, resolveUrl: () async => 'show-theme', volume: 30);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(created, 1);
    expect(audio.opened, ['show-theme']);
    expect(audio.plays, 1);
    expect(audio.disposals, 0);
  });

  test('a release with no new request stops after the grace period', () async {
    final audio = player('theme');
    final theme = controller(() => audio);
    await theme.request(ownerA, resolveUrl: () async => 'theme', volume: 30);
    theme.release(ownerA);
    expect(audio.disposals, 0);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(audio.disposals, 1);
  });

  test('an immediate release stops without waiting', () async {
    final audio = player('theme');
    final theme = controller(() => audio, grace: const Duration(hours: 1));
    await theme.request(ownerA, resolveUrl: () async => 'theme', volume: 30);
    theme.release(ownerA, immediate: true);
    await _drain();
    expect(audio.disposals, 1);
  });

  test('a stale release from a previous owner leaves the current theme alone', () async {
    final first = player('first');
    final second = player('second');
    final theme = controller(sequence([first, second]));
    await theme.request(ownerA, resolveUrl: () async => 'first', volume: 30);
    await theme.request(ownerB, resolveUrl: () async => 'second', volume: 30);
    theme.release(ownerA, immediate: true);
    await _drain();
    expect(first.disposals, 1);
    expect(second.disposals, 0);
    expect(second.plays, 1);
  });

  test('a different theme waits for the prior native disposal', () async {
    final first = player('first', holdDispose: true);
    final second = player('second');
    final theme = controller(sequence([first, second]));
    await theme.request(ownerA, resolveUrl: () async => 'first', volume: 20);
    theme.release(ownerA);
    final replacement = theme.request(ownerB, resolveUrl: () async => 'second', volume: 40);
    await first.disposeGate.entered.future;
    expect(second.volumes, isEmpty);
    first.disposeGate.release();
    await replacement;
    expect(second.opened, ['second']);
    expect(second.volumes, [40]);
    expect(events.indexOf('first.disposed'), lessThan(events.indexOf('second.volume')));
  });

  test('a page without a theme stops the previous page theme', () async {
    final audio = player('theme');
    final theme = controller(() => audio, grace: const Duration(hours: 1));
    await theme.request(ownerA, resolveUrl: () async => 'theme', volume: 30);
    theme.release(ownerA);
    await theme.request(ownerB, resolveUrl: () async => null, volume: 30);
    expect(audio.disposals, 1);
  });

  test('concurrent requests play only the last one', () async {
    final audio = player('latest');
    var created = 0;
    final theme = controller(() {
      created++;
      return audio;
    });
    await Future.wait([
      theme.request(ownerA, resolveUrl: () async => 'first', volume: 10),
      theme.request(ownerB, resolveUrl: () async => 'middle', volume: 20),
      theme.request(ownerA, resolveUrl: () async => 'latest', volume: 45),
    ]);
    expect(created, 1);
    expect(audio.opened, ['latest']);
    expect(audio.volumes, [45]);
    expect(audio.plays, 1);
  });

  test('fades in from silence after play', () async {
    final audio = player('theme');
    final theme = controller(() => audio, fadeIn: const Duration(milliseconds: 200));
    await theme.request(ownerA, resolveUrl: () async => 'theme', volume: 40);
    expect(audio.volumes, [0, 10, 20, 30, 40]);
    expect(events.take(3), ['theme.volume', 'theme.open', 'theme.play']);
  });

  test('fades out before disposing on stop', () async {
    final audio = player('theme');
    final theme = controller(() => audio, fadeOut: const Duration(milliseconds: 200));
    await theme.request(ownerA, resolveUrl: () async => 'theme', volume: 40);
    await theme.stop();
    expect(audio.volumes, [40, 30, 20, 10, 0]);
    expect(events.last, 'theme.disposed');
  });

  test('a different theme fades the old one out and the new one in', () async {
    final first = player('first');
    final second = player('second');
    final theme = controller(
      sequence([first, second]),
      fadeIn: const Duration(milliseconds: 100),
      fadeOut: const Duration(milliseconds: 100),
    );
    await theme.request(ownerA, resolveUrl: () async => 'first', volume: 40);
    await theme.request(ownerB, resolveUrl: () async => 'second', volume: 40);
    expect(first.volumes, [0, 20, 40, 20, 0]);
    expect(second.volumes, [0, 20, 40]);
    expect(events.indexOf('first.disposed'), lessThan(events.indexOf('second.open')));
  });

  test('the same theme on a new page fades back in after an interrupted fade-in', () async {
    final audio = player('theme');
    var created = 0;
    final theme = controller(() {
      created++;
      return audio;
    }, fadeIn: const Duration(milliseconds: 200));
    final start = theme.request(ownerA, resolveUrl: () async => 'theme', volume: 40);
    await Future<void>.delayed(const Duration(milliseconds: 70));
    theme.release(ownerA);
    await theme.request(ownerB, resolveUrl: () async => 'theme', volume: 40);
    await start;
    expect(created, 1);
    expect(audio.volumes.last, 40);
    expect(audio.disposals, 0);
  });

  test('the same theme requested after the grace period takes back the fade-out', () async {
    final audio = player('theme');
    var created = 0;
    final theme = controller(() {
      created++;
      return audio;
    }, fadeOut: const Duration(milliseconds: 400));
    await theme.request(ownerA, resolveUrl: () async => 'theme', volume: 40);
    theme.release(ownerA);
    // Past the 20 ms grace and partway down the fade-out.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(audio.volumes.last, lessThan(40));
    await theme.request(ownerB, resolveUrl: () async => 'theme', volume: 40);
    expect(created, 1);
    expect(audio.disposals, 0);
    expect(audio.plays, 1);
    expect(audio.volumes.last, 40);
  });

  test('a volume change mid-fade is ramped to, not jumped to', () async {
    final audio = player('theme');
    final theme = controller(() => audio, fadeIn: const Duration(milliseconds: 200));
    final start = theme.request(ownerA, resolveUrl: () async => 'theme', volume: 40);
    while (audio.volumes.length < 3) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    // At 20 with two steps left; 40 more spreads as 40 then 60.
    await theme.setVolume(60);
    await start;
    expect(audio.volumes.take(5), [0, 10, 20, 40, 60]);
    expect(audio.volumes.last, 60);
  });

  for (final claim in ['music', 'video']) {
    Future<void> claimSession() => claim == 'music' ? coordinator.claimMusic() : coordinator.claimVideo();

    test('claim $claim cuts a fade-out short', () async {
      final audio = player('theme');
      final theme = controller(() => audio, fadeOut: const Duration(hours: 1));
      await theme.request(ownerA, resolveUrl: () async => 'theme', volume: 40);
      final fading = theme.stop();
      await claimSession().timeout(const Duration(seconds: 1));
      await fading;
      expect(audio.disposals, 1);
    });

    test('claim $claim stops without fading', () async {
      final audio = player('theme');
      final theme = controller(() => audio, fadeOut: const Duration(hours: 1));
      await theme.request(ownerA, resolveUrl: () async => 'theme', volume: 40);
      await claimSession().timeout(const Duration(seconds: 1));
      expect(audio.volumes, [40]);
      expect(audio.disposals, 1);
    });

    test('claim $claim during URL lookup prevents late theme construction', () async {
      final url = Completer<String?>();
      final resolving = Completer<void>();
      var created = 0;
      final theme = controller(() {
        created++;
        return player('late');
      });
      final start = theme.request(
        ownerA,
        resolveUrl: () {
          resolving.complete();
          return url.future;
        },
        volume: 30,
      );
      await resolving.future;
      await claimSession();
      url.complete('late');
      await start;
      expect(created, 0);
    });

    test('claim $claim during open waits for disposal and prevents play', () async {
      final audio = player('theme', holdOpen: true, holdDispose: true);
      final theme = controller(() => audio);
      final start = theme.request(ownerA, resolveUrl: () async => 'theme', volume: 30);
      await audio.openGate.entered.future;
      var claimed = false;
      final claiming = claimSession().then((_) => claimed = true);
      await _drain();
      expect(claimed, isFalse);
      expect(audio.disposals, 0);
      audio.openGate.release();
      await audio.disposeGate.entered.future;
      expect(claimed, isFalse);
      expect(audio.focusRequests, 0);
      expect(audio.plays, 0);
      audio.disposeGate.release();
      await Future.wait([start, claiming]);
      expect(claimed, isTrue);
      expect(audio.disposals, 1);
      expect(audio.focusRequests, 0);
      expect(audio.plays, 0);
    });
  }
}
