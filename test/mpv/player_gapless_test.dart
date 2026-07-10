import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

/// Gapless arming (setNext) on the audio core: content:// → fdclose://
/// conversion and the content-fd ownership rules — Dart closes an armed fd
/// only when the entry provably never played (playlist-pos 0 before and
/// after the remove); every ambiguous outcome leaks rather than risking a
/// close of an fd mpv holds.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    PlayerNative.debugForceContentFdConversion = true;
  });

  tearDown(() {
    PlayerNative.debugForceContentFdConversion = false;
  });

  Future<void> run(_AudioCoreMock core, Future<void> Function(PlayerNative player, List<String> transitions) body) {
    return withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_audio_player',
      eventChannelName: 'com.plezy/mpv_audio_player/events',
      methodHandler: core.handle,
      testBody: () async {
        final player = PlayerNative.audio();
        final transitions = <String>[];
        final sub = player.streams.trackTransition.listen(transitions.add);
        try {
          await body(player, transitions);
        } finally {
          await sub.cancel();
          await player.dispose();
        }
      },
    );
  }

  /// Opens a first track and consumes its own file-loaded so later
  /// file-loaded events read as gapless roll-ins.
  Future<void> openFirst(PlayerNative player, [String uri = 'https://example.test/t1.flac']) async {
    await player.open(Media(uri));
    player.handlePlayerEvent('file-loaded', null);
  }

  group('setNext content:// conversion', () {
    test('arms fdclose:// and surfaces the ORIGINAL uri on transition', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        expect(core.openedContentUris, ['content://downloads/t2']);
        expect(core.commands('loadfile').last, ['loadfile', 'fdclose://7', 'append']);

        player.handlePlayerEvent('file-loaded', null);
        await Future<void>.delayed(Duration.zero);

        // The service matches transitions against the resolver's URL, so the
        // original content:// uri must surface — never the fdclose:// form.
        expect(transitions, ['content://downloads/t2']);
        expect(core.commands('playlist-remove').last, ['playlist-remove', '0']);
        expect(core.closedFds, isEmpty, reason: 'mpv consumed the fd');
      });
    });

    test('open() still converts content:// (regression)', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await player.open(Media('content://downloads/t1'));
        expect(core.commands('loadfile').single, ['loadfile', 'fdclose://7', 'replace']);
        expect(core.closedFds, isEmpty);
      });
    });

    test('non-content arm opens no fd and re-arm still clears entry 1', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('https://example.test/t2.flac'));
        await player.setNext(Media('https://example.test/t3.flac'));

        expect(core.openedContentUris, isEmpty);
        expect(core.closedFds, isEmpty);
        expect(core.commands('playlist-remove'), [
          ['playlist-remove', '1'],
        ]);
        expect(core.commands('loadfile').last, ['loadfile', 'https://example.test/t3.flac', 'append']);
      });
    });

    test('openContentFd failure throws instead of arming a raw content:// uri', () async {
      final core = _AudioCoreMock()..failOpenContentFd = true;
      await run(core, (player, transitions) async {
        await openFirst(player);
        await expectLater(player.setNext(Media('content://downloads/t2')), throwsStateError);
        expect(core.commands('loadfile'), hasLength(1), reason: 'only the open() load');
      });
    });
  });

  group('armed fd ownership', () {
    test('clearing an unconsumed arm closes the fd (pos 0 before and after)', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        core.playlistPosResponses.addAll(['0', '0']);
        await player.setNext(null);

        expect(core.commands('playlist-remove'), [
          ['playlist-remove', '1'],
        ]);
        expect(core.closedFds, [7]);
        expect(transitions, isEmpty);
      });
    });

    test('clear while mpv already rolled in adopts the transition, keeps the fd', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        core.playlistPosResponses.add('1');
        await player.setNext(null);
        await Future<void>.delayed(Duration.zero);

        expect(transitions, ['content://downloads/t2'], reason: 'the pending file-loaded is a no-op now');
        expect(core.commands('playlist-remove'), [
          ['playlist-remove', '0'],
        ], reason: 'rebase only — removing index 1 would kill the playing entry');
        expect(core.closedFds, isEmpty, reason: 'mpv opened the entry and owns the fd');

        // The real file-loaded event arrives late: nothing armed, ignored.
        player.handlePlayerEvent('file-loaded', null);
        await Future<void>.delayed(Duration.zero);
        expect(transitions, hasLength(1));
      });
    });

    test('ambiguous post-remove position leaks on doubt', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        core.playlistPosResponses.addAll(['0', '-1']);
        await player.setNext(null);

        expect(core.commands('playlist-remove'), [
          ['playlist-remove', '1'],
        ]);
        expect(core.closedFds, isEmpty);
      });
    });

    test('playlist-remove failure leaks on doubt', () async {
      final core = _AudioCoreMock()..failPlaylistRemove1 = true;
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        core.playlistPosResponses.add('0');
        await player.setNext(null);

        expect(core.closedFds, isEmpty);
        expect(transitions, isEmpty);
      });
    });

    test('stop() settles an unconsumed armed fd without a transition', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        core.playlistPosResponses.addAll(['0', '0']);
        await player.stop();

        expect(core.closedFds, [7]);
        expect(transitions, isEmpty);
      });
    });

    test('stop() while rolled in emits no transition and keeps the fd', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        core.playlistPosResponses.add('1');
        await player.stop();
        await Future<void>.delayed(Duration.zero);

        expect(transitions, isEmpty, reason: 'playback is ending — nobody listens for that entry');
        expect(core.closedFds, isEmpty);
      });
    });

    test('open() replace settles an unconsumed armed fd', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        core.playlistPosResponses.addAll(['0', '0']);
        await player.open(Media('https://example.test/t3.flac'));

        expect(core.closedFds, [7]);
        expect(transitions, isEmpty);
        expect(core.commands('loadfile').last, ['loadfile', 'https://example.test/t3.flac', 'replace']);
      });
    });

    test('dispose() settles an unconsumed armed fd', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        core.playlistPosResponses.addAll(['0', '0']);
        await player.dispose();

        expect(core.closedFds, [7]);
      });
    });

    test('replacing an unconsumed content arm closes the old fd only', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        core.playlistPosResponses.addAll(['0', '0']);
        await player.setNext(Media('content://downloads/t3'));

        expect(core.openedContentUris, ['content://downloads/t2', 'content://downloads/t3']);
        expect(core.closedFds, [7]);
        expect(core.commands('loadfile').last, ['loadfile', 'fdclose://8', 'append']);

        player.handlePlayerEvent('file-loaded', null);
        await Future<void>.delayed(Duration.zero);
        expect(transitions, ['content://downloads/t3']);
        expect(core.closedFds, [7], reason: 'the consumed fd stays with mpv');
      });
    });
  });
}

/// Scriptable mock of the native audio core: records calls, hands out
/// incrementing content fds, and answers playlist-pos reads from a queue
/// (defaulting to '0').
class _AudioCoreMock {
  final calls = <MethodCall>[];
  final openedContentUris = <String>[];
  final closedFds = <int>[];
  final playlistPosResponses = <String>[];
  int _nextFd = 7;
  bool failOpenContentFd = false;
  bool failPlaylistRemove1 = false;

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    switch (call.method) {
      case 'initialize':
        return true;
      case 'openContentFd':
        if (failOpenContentFd) throw PlatformException(code: 'OPEN_FAILED');
        openedContentUris.add(_args(call)['uri'] as String);
        return _nextFd++;
      case 'closeContentFd':
        closedFds.add(_args(call)['fd'] as int);
        return null;
      case 'getProperty':
        if (_args(call)['name'] == 'playlist-pos') {
          return playlistPosResponses.isEmpty ? '0' : playlistPosResponses.removeAt(0);
        }
        return null;
      case 'command':
        final args = (_args(call)['args'] as List).cast<Object?>();
        if (failPlaylistRemove1 && args.length >= 2 && args[0] == 'playlist-remove' && args[1] == '1') {
          throw PlatformException(code: 'error', message: 'playlist-remove failed');
        }
        return null;
      default:
        return null;
    }
  }

  List<List<Object?>> commands(String first) => calls
      .where((c) => c.method == 'command')
      .map((c) => (_args(c)['args'] as List).cast<Object?>())
      .where((args) => args.isNotEmpty && args.first == first)
      .toList();

  static Map<Object?, Object?> _args(MethodCall call) => Map<Object?, Object?>.from(call.arguments as Map);
}
