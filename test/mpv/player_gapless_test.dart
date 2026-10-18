import 'dart:convert';

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

  /// The last `prefetch-playlist` write: its call index and value.
  (int, String?) prefetchWrite(_AudioCoreMock core) {
    final index = core.calls.lastIndexWhere(
      (c) => c.method == 'setProperty' && _AudioCoreMock._args(c)['name'] == 'prefetch-playlist',
    );
    if (index == -1) return (-1, null);
    return (index, _AudioCoreMock._args(core.calls[index])['value'] as String?);
  }

  group('setNext content:// conversion', () {
    test('arms fdclose:// and surfaces the ORIGINAL uri on transition', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        expect(core.openedContentUris, ['content://downloads/t2']);
        expect(core.commands('loadfile').last.take(3).toList(), ['loadfile', 'fdclose://7', 'append']);

        player.handlePlayerEvent('file-loaded', null);
        await Future<void>.delayed(Duration.zero);

        // The service matches transitions against the resolver's URL, so the
        // original content:// uri must surface — never the fdclose:// form.
        expect(transitions, ['content://downloads/t2']);
        expect(core.commands('playlist-remove').last, ['playlist-remove', '0']);
        expect(core.closedFds, isEmpty, reason: 'mpv consumed the fd');
      });
    });

    test('advance cleanup failure is contained after the transition', () async {
      final core = _AudioCoreMock()..failPlaylistRemove0 = true;
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('https://example.test/t2.flac'));

        player.handlePlayerEvent('file-loaded', null);
        await Future<void>.delayed(Duration.zero);

        expect(transitions, ['https://example.test/t2.flac']);
        expect(core.commands('playlist-remove').last, ['playlist-remove', '0']);
      });
    });

    test('open() still converts content:// (regression)', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await player.open(Media('content://downloads/t1'));
        // Per-file options ride the tail; this test owns the uri and mode.
        expect(core.commands('loadfile').single.take(3).toList(), ['loadfile', 'fdclose://7', 'replace']);
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
        expect(core.commands('loadfile').last.take(3).toList(), ['loadfile', 'https://example.test/t3.flac', 'append']);
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

  group('setNext prefetch-playlist policy', () {
    // The armed entry's stream must be opened while the current track still
    // plays (mpv prefetch) so the network round-trip never sits on the
    // gapless boundary (#1869) — but never for fd-backed local entries,
    // where an early open would consume the fd while playlist-pos still
    // reads 0 and break the "provably never opened" close proof.
    int appendIndex(_AudioCoreMock core) => core.calls.lastIndexWhere((c) {
      if (c.method != 'command') return false;
      final args = (_AudioCoreMock._args(c)['args'] as List).cast<Object?>();
      return args.length >= 3 && args[0] == 'loadfile' && args[2] == 'append';
    });

    test('a network arm enables prefetch before the entry joins the playlist', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('https://example.test/t2.flac'));

        final (writeIndex, value) = prefetchWrite(core);
        expect(value, 'yes');
        expect(writeIndex, lessThan(appendIndex(core)), reason: 'the option must be live before the append');
      });
    });

    test('an fd-backed arm disables prefetch before the entry joins the playlist', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('https://example.test/t2.flac'));
        await player.setNext(Media('content://downloads/t3'));

        final (writeIndex, value) = prefetchWrite(core);
        expect(value, 'no', reason: 'a prefetch would consume the fd and invite a double close');
        expect(writeIndex, lessThan(appendIndex(core)));
        expect(core.commands('loadfile').last.take(3).toList(), ['loadfile', 'fdclose://7', 'append']);
      });
    });
  });

  group('stream headers across gapless arms (#2511)', () {
    // What each stream request carries is replayed through _MpvHeaderModel,
    // so these assert the headers a server receives, not a command string.
    const plexHeaders = {
      'X-Plex-Product': 'Plezy',
      'X-Plex-Device': 'Mac17,9',
      'X-Plex-Device-Name': r"Eddé's Mac, work\",
      'X-Plex-Token': 'secret',
    };
    final plexItems = [for (final e in plexHeaders.entries) '${e.key}: ${e.value}'];
    const plex1 = 'https://media.example.test/plex/library/parts/1/file.flac';
    const plex2 = 'https://media.example.test/plex/library/parts/2/file.flac';
    const plex3 = 'https://media.example.test/plex/library/parts/3/file.flac';
    // Another server behind the same origin (path-routed reverse proxy).
    const jellyfin1 = 'https://media.example.test/jellyfin/Audio/1/stream?ApiKey=k';
    const jellyfin2 = 'https://media.example.test/jellyfin/Audio/2/stream?ApiKey=k';

    /// mpv rolls from the playing entry into the armed one.
    Future<void> advance(_AudioCoreMock core, PlayerNative player) async {
      core.mpv.advance();
      player.handlePlayerEvent('file-loaded', null);
      await Future<void>.delayed(Duration.zero);
    }

    Future<void> openPlex(_AudioCoreMock core, PlayerNative player, String uri) async {
      await player.open(Media(uri, headers: plexHeaders));
      player.handlePlayerEvent('file-loaded', null);
    }

    test('every armed track of one server is prefetched with all of its headers', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openPlex(core, player, plex1);
        await player.setNext(Media(plex2, headers: plexHeaders));
        await advance(core, player);
        await player.setNext(Media(plex3, headers: plexHeaders));
        await advance(core, player);

        expect(core.mpv.openedHeaders, {plex1: plexItems, plex2: plexItems, plex3: plexItems});
        expect(core.mpv.prefetched, {plex2, plex3}, reason: 'same-server arms keep gapless prefetch');
      });
    });

    test("an arm with other headers never receives the playing track's", () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openPlex(core, player, plex1);
        await player.setNext(Media(jellyfin1));
        await advance(core, player);
        await player.setNext(Media(plex2, headers: plexHeaders));
        await advance(core, player);

        expect(core.mpv.openedHeaders, {plex1: plexItems, jellyfin1: <String>[], plex2: plexItems});
        expect(core.mpv.prefetched, isEmpty, reason: 'a prefetch sends the playing entry headers');
      });
    });

    test('opening after a gapless advance sends only the opened track headers', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openPlex(core, player, plex1);
        await player.setNext(Media(plex2, headers: plexHeaders));
        await advance(core, player);
        await player.open(Media(jellyfin1));

        expect(core.mpv.openedHeaders[jellyfin1], isEmpty);
      });
    });

    test("prefetch follows the playing track's headers across an advance", () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        String? prefetchValue() => prefetchWrite(core).$2;

        await openPlex(core, player, plex1);
        await player.setNext(Media(jellyfin1));
        expect(prefetchValue(), 'no');

        await advance(core, player);
        await player.setNext(Media(jellyfin2));
        expect(prefetchValue(), 'yes', reason: 'the Jellyfin track now plays');
        await player.setNext(Media(plex2, headers: plexHeaders));
        expect(prefetchValue(), 'no');

        await openPlex(core, player, plex3);
        await player.setNext(Media(plex2, headers: plexHeaders));
        expect(prefetchValue(), 'yes');
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
        expect(core.commands('loadfile').last.take(3).toList(), [
          'loadfile',
          'https://example.test/t3.flac',
          'replace',
        ]);
      });
    });

    test('dispose() raw cleanup settles an unconsumed armed fd after admission closes', () async {
      final core = _AudioCoreMock();
      await run(core, (player, transitions) async {
        await openFirst(player);
        await player.setNext(Media('content://downloads/t2'));

        core.playlistPosResponses.addAll(['0', '0']);
        await player.dispose();

        expect(core.closedFds, [7]);
        expect(core.commands('playlist-remove'), [
          ['playlist-remove', '1'],
        ]);
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
        expect(core.commands('loadfile').last.take(3).toList(), ['loadfile', 'fdclose://8', 'append']);

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
  bool failPlaylistRemove0 = false;
  final mpv = _MpvHeaderModel();

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    switch (call.method) {
      case 'setProperty':
        mpv.onCall(call);
        return null;
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
        if (failPlaylistRemove0 && args.length >= 2 && args[0] == 'playlist-remove' && args[1] == '0') {
          throw PlatformException(code: 'error', message: 'playlist-remove failed');
        }
        if (failPlaylistRemove1 && args.length >= 2 && args[0] == 'playlist-remove' && args[1] == '1') {
          throw PlatformException(code: 'error', message: 'playlist-remove failed');
        }
        mpv.onCall(call);
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

/// The HTTP headers mpv (0.41) opens each playlist entry's stream with,
/// replayed from the commands PlayerNative sent the audio core:
/// - `change-list http-header-fields clr|append` edit the list in place.
/// - A `loadfile` options arg is a key/value list (m_option.c
///   parse_keyvalue_list): a value is `%N%` plus N UTF-8 bytes, or runs to
///   the next `,`; a repeated key drops its earlier pair.
/// - When an entry starts, the list is backed up and the entry's pairs apply
///   in order (loadfile.c load_per_file_options); when it ends, the backup is
///   restored over any change made meanwhile (m_config_restore_backups).
///   `-clr` empties the list, `-append` adds its value verbatim, `-add` and
///   the bare key split the value on `,` — a backslash directly before one
///   escapes it and is dropped (get_nextsep) — and the bare key replaces the
///   list, an empty value becoming one empty item (separate_input_param).
/// - With prefetch-playlist on, the armed entry's stream opens while the
///   current entry plays, with the current list; otherwise it opens when the
///   entry starts, with its own pairs applied.
/// Recorded headers drop trailing whitespace, which HTTP strips.
class _MpvHeaderModel {
  List<String> _list = const [];
  List<String>? _backup;
  ({String uri, String options})? _armed;
  bool _prefetch = false;
  final openedHeaders = <String, List<String>>{};
  final prefetched = <String>{};

  void onCall(MethodCall call) {
    final args = Map<Object?, Object?>.from(call.arguments as Map);
    if (call.method == 'setProperty') {
      if (args['name'] == 'prefetch-playlist') _prefetch = args['value'] == 'yes';
      return;
    }
    final command = (args['args'] as List).cast<String>();
    switch (command) {
      case ['change-list', 'http-header-fields', 'clr', _]:
        _list = const [];
      case ['change-list', 'http-header-fields', 'append', final item]:
        _list = [..._list, item];
      case ['loadfile', final uri, 'replace', ...final rest]:
        _armed = null;
        _endCurrent();
        _start(uri, rest.length > 1 ? rest[1] : '');
      case ['loadfile', final uri, 'append', ...final rest]:
        _armed = (uri: uri, options: rest.length > 1 ? rest[1] : '');
      case ['playlist-remove', '1']:
        _armed = null;
    }
  }

  /// mpv rolls from the playing entry into the armed one.
  void advance() {
    final next = _armed ?? (throw StateError('nothing armed'));
    _armed = null;
    if (_prefetch) {
      openedHeaders[next.uri] = _sent(_list);
      prefetched.add(next.uri);
    }
    _endCurrent();
    _start(next.uri, next.options);
  }

  void _endCurrent() {
    _list = _backup ?? _list;
    _backup = null;
  }

  void _start(String uri, String options) {
    _backup = _list;
    for (final (key, value) in _keyValuePairs(options)) {
      if (!key.startsWith('http-header-fields')) continue;
      _list = switch (key) {
        'http-header-fields-clr' => const [],
        'http-header-fields-append' => [..._list, value],
        'http-header-fields-add' => [..._list, ..._splitList(value)],
        'http-header-fields' || 'http-header-fields-set' => _splitList(value),
        _ => throw UnsupportedError('unmodelled list op $key'),
      };
    }
    openedHeaders.putIfAbsent(uri, () => _sent(_list));
  }

  static List<String> _sent(List<String> list) => [for (final item in list) item.trimRight()];

  static List<(String, String)> _keyValuePairs(String options) {
    final bytes = utf8.encode(options);
    var i = 0;
    String read(int terminator) {
      if (i < bytes.length && bytes[i] == 0x25) {
        final lengthEnd = bytes.indexOf(0x25, i + 1);
        final end = lengthEnd + 1 + int.parse(utf8.decode(bytes.sublist(i + 1, lengthEnd)));
        final value = utf8.decode(bytes.sublist(lengthEnd + 1, end));
        i = end;
        return value;
      }
      if (i < bytes.length && (bytes[i] == 0x22 || bytes[i] == 0x5B)) throw UnsupportedError('unmodelled quoting');
      final start = i;
      while (i < bytes.length && bytes[i] != terminator) {
        i++;
      }
      return utf8.decode(bytes.sublist(start, i));
    }

    final pairs = <(String, String)>[];
    while (i < bytes.length) {
      final key = read(0x3D);
      if (i >= bytes.length || bytes[i++] != 0x3D) throw FormatException('expected = after $key', options);
      final value = read(0x2C);
      pairs
        ..removeWhere((pair) => pair.$1 == key)
        ..add((key, value));
      if (i < bytes.length && bytes[i] != 0x2C && bytes[i] != 0x3A) throw FormatException('garbage', options);
      i++;
    }
    return pairs;
  }

  static List<String> _splitList(String value) {
    final items = <String>[];
    var item = '';
    for (final char in value.split('')) {
      if (char == ',' && item.endsWith(r'\')) {
        item = '${item.substring(0, item.length - 1)},';
      } else if (char == ',') {
        items.add(item);
        item = '';
      } else {
        item += char;
      }
    }
    return [...items, item];
  }
}
