import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/external_player_models.dart';
import 'package:plezy/services/external_player_service.dart';

/// The POSIX one-liner `_posixCommandExists` hands to `sh`.
const _commandProbe = r'command -v "$1" >/dev/null 2>&1';

void main() {
  setUp(KnownPlayers.resetForTesting);
  tearDown(KnownPlayers.resetForTesting);

  group('detection failures', () {
    test('a probe that throws lists the player instead of hiding it', () async {
      final installed = await _resolveWith(_FakeProbe.everythingInstalled());
      final failed = await _resolveWith(_FakeProbe(failEveryLookup: true));

      expect(failed, installed);
    });

    test('detection runs once per process', () async {
      final probe = _FakeProbe.everythingInstalled();
      KnownPlayers.probe = probe;

      final first = await KnownPlayers.getForCurrentPlatform();
      final runsAfterFirst = probe.runs.length;
      final second = await KnownPlayers.getForCurrentPlatform();

      expect(second, same(first));
      expect(probe.runs, hasLength(runsAfterFirst));
    });

    test('undetected players keep their declared order', () async {
      final all = await _resolveWith(_FakeProbe.everythingInstalled());
      final none = await _resolveWith(_FakeProbe());

      expect(none.first, 'system_default');
      expect(none, all.where(none.contains));
    });
  });

  // Which detectors run is driven by the probe, so every platform's wiring is
  // exercised on whatever host runs the suite.
  group('detector wiring', () {
    test('Linux asks the shell to resolve each command on PATH', () async {
      final probe = _FakeProbe(operatingSystem: 'linux');
      await _resolveWith(probe);

      // Detectors run concurrently, so assert what is probed, not the order.
      expect(
        probe.runs,
        unorderedEquals([
          ['sh', '-c', _commandProbe, 'plezy-command-probe', 'vlc'],
          ['sh', '-c', _commandProbe, 'plezy-command-probe', 'mpv'],
          ['sh', '-c', _commandProbe, 'plezy-command-probe', 'celluloid'],
        ]),
      );
    });

    test('macOS asks Launch Services for bundles and the shell for mpv', () async {
      final probe = _FakeProbe(operatingSystem: 'macos');
      await _resolveWith(probe);

      expect(probe.bundleLookups, unorderedEquals(['org.videolan.vlc', 'com.colliderli.iina']));
      expect(probe.runs, [
        ['sh', '-c', _commandProbe, 'plezy-command-probe', 'mpv'],
      ]);
    });

    test('Windows falls back to where.exe when no install path matches', () async {
      final probe = _FakeProbe(operatingSystem: 'windows');
      await _resolveWith(probe);

      expect(
        probe.runs,
        unorderedEquals([
          ['where.exe', 'vlc'],
          ['where.exe', 'mpv'],
          ['where.exe', 'PotPlayerMini64'],
        ]),
      );
    });

    test('Windows skips where.exe once a concrete VLC install path matches', () async {
      final probe = _FakeProbe(
        operatingSystem: 'windows',
        paths: {r'C:\Program Files\VideoLAN\VLC\vlc.exe'},
        schemes: {'potplayer://'},
      );
      await _resolveWith(probe);

      expect(probe.runs, [
        ['where.exe', 'mpv'],
      ]);
    });

    test('iOS asks the same URL-handler question the launcher gates on', () async {
      final probe = _FakeProbe(operatingSystem: 'ios');
      await _resolveWith(probe);

      expect(probe.schemeLookups, unorderedEquals(['vlc://', 'infuse://', 'outplayer://']));
      expect(probe.runs, isEmpty);
    });

    test('platforms without a detector probe nothing', () async {
      final probe = _FakeProbe(operatingSystem: 'android');
      await _resolveWith(probe);

      expect(probe.runs, isEmpty);
      expect(probe.bundleLookups, isEmpty);
      expect(probe.schemeLookups, isEmpty);
    });
  });

  group('Linux', () {
    test('lists only players whose command resolves on PATH', () async {
      expect(await _resolveWith(_FakeProbe(commands: {'mpv'})), ['system_default', 'mpv']);
      expect(await _resolveWith(_FakeProbe(commands: {'vlc', 'celluloid'})), ['system_default', 'vlc', 'celluloid']);
      expect(await _resolveWith(_FakeProbe()), ['system_default']);
    });
  }, skip: !Platform.isLinux);

  group('macOS', () {
    test('lists only applications Launch Services knows about', () async {
      expect(await _resolveWith(_FakeProbe(bundleIds: {'org.videolan.vlc'})), ['system_default', 'vlc']);
      expect(await _resolveWith(_FakeProbe(bundleIds: {'com.colliderli.iina'})), ['system_default', 'iina']);
      expect(await _resolveWith(_FakeProbe()), ['system_default']);
    });

    test('detects mpv on PATH rather than as a bundle', () async {
      expect(await _resolveWith(_FakeProbe(commands: {'mpv'})), ['system_default', 'mpv']);
    });
  }, skip: !Platform.isMacOS);

  group('Windows', () {
    test('accepts VLC from a concrete install path', () async {
      final probe = _FakeProbe(
        paths: {r'C:\Program Files\VideoLAN\VLC\vlc.exe'},
        environment: {'ProgramFiles': r'C:\Program Files'},
      );

      expect(await _resolveWith(probe), ['system_default', 'vlc']);
    });

    test('falls back to where.exe when no install path matches', () async {
      final probe = _FakeProbe(commands: {'vlc', 'mpv'});

      expect(await _resolveWith(probe), ['system_default', 'vlc', 'mpv']);
      expect(probe.runs, contains(equals(['where.exe', 'vlc'])));
    });

    test('accepts PotPlayer from its registered URL handler', () async {
      final probe = _FakeProbe(schemes: {'potplayer://'});

      expect(await _resolveWith(probe), ['system_default', 'potplayer']);
    });

    test('accepts PotPlayer from PATH when no handler is registered', () async {
      expect(await _resolveWith(_FakeProbe(commands: {'PotPlayerMini64'})), ['system_default', 'potplayer']);
    });
  }, skip: !Platform.isWindows);

  group('Outplayer', () {
    const stream = 'http://10.0.0.2:32400/library/parts/1/file name.mkv?X-Plex-Token=abc&download=1';

    test('play link percent-encodes the stream and carries resume position and return links', () {
      final uri = KnownPlayers.callbackPlayUri(
        'outplayer',
        stream,
        ExternalPlayerLaunchOptions(
          startPosition: const Duration(seconds: 90, milliseconds: 700),
          returnLinks: ExternalPlayerService.returnLinks('s1'),
        ),
      )!;

      expect(uri.toString(), startsWith('outplayer://x-callback-url/play?url=http%3A%2F%2F10.0.0.2'));
      expect(uri.toString(), contains('file%20name.mkv%3FX-Plex-Token%3Dabc%26download%3D1'));
      expect(uri.queryParameters['url'], stream);
      expect(uri.queryParameters['position'], '90');
      expect(uri.queryParameters['x-success'], 'plezy://external-player/success/s1');
      expect(uri.queryParameters['x-cancel'], 'plezy://external-player/cancel/s1');
      expect(uri.queryParameters['x-error'], 'plezy://external-player/error/s1');
    });

    test('play link without return links or a position is just the stream', () {
      final uri = KnownPlayers.callbackPlayUri('outplayer', stream, const ExternalPlayerLaunchOptions())!;

      expect(uri.queryParameters.keys, ['url']);
    });
  });

  test('Infuse play link has no x-cancel: Infuse reports every exit through x-success', () {
    final uri = KnownPlayers.callbackPlayUri(
      'infuse',
      'http://srv/v.mkv',
      ExternalPlayerLaunchOptions(
        startPosition: const Duration(seconds: 42),
        returnLinks: ExternalPlayerService.returnLinks('s2'),
        filename: 'The Office - S02E01 - The Dundies.mkv',
      ),
    )!;

    expect(uri.toString(), startsWith('infuse://x-callback-url/play?url=http%3A%2F%2Fsrv%2Fv.mkv'));
    expect(uri.queryParameters['position'], '42');
    expect(uri.queryParameters['x-success'], 'plezy://external-player/success/s2');
    expect(uri.queryParameters['x-error'], 'plezy://external-player/error/s2');
    expect(uri.queryParameters.containsKey('x-cancel'), isFalse);
    expect(uri.queryParameters['filename'], 'The Office - S02E01 - The Dundies.mkv');
    expect(uri.toString(), contains('filename=The%20Office%20-%20S02E01%20-%20The%20Dundies.mkv'));
  });

  test('Outplayer links leave out the file name it does not document', () {
    final uri = KnownPlayers.callbackPlayUri(
      'outplayer',
      'http://srv/v.mkv',
      const ExternalPlayerLaunchOptions(filename: 'Inception (2010).mkv'),
    )!;

    expect(uri.queryParameters.keys, ['url']);
  });

  test('VLC streams through vlc-x-callback with only the keys it reads', () {
    const stream = 'https://srv.plex.direct:32400/library/parts/1/2/file.mkv?X-Plex-Token=abc';
    final uri = KnownPlayers.callbackPlayUri(
      'vlc',
      stream,
      ExternalPlayerLaunchOptions(
        startPosition: const Duration(seconds: 90),
        returnLinks: ExternalPlayerService.returnLinks('s3'),
        filename: 'Inception (2010).mkv',
      ),
    )!;

    // VLC only decodes `url` when it starts fully encoded (`https%3A%2F%2F`).
    expect(uri.toString(), startsWith('vlc-x-callback://x-callback-url/stream?url=https%3A%2F%2Fsrv.plex.direct'));
    expect(uri.queryParameters['url'], stream);
    expect(uri.queryParameters['x-success'], 'plezy://external-player/success/s3');
    expect(uri.queryParameters['x-error'], 'plezy://external-player/error/s3');
    expect(uri.queryParameters.keys, unorderedEquals(['url', 'x-success', 'x-error']));
    // VLC 3.7.x opens return links without decoding them, so they go raw.
    expect(uri.query, contains('x-success=plezy://external-player/success/s3'));
    expect(uri.query, contains('x-error=plezy://external-player/error/s3'));
  });

  test("VLC 3.7.3's own query parsing recovers usable return links", () {
    final uri = KnownPlayers.callbackPlayUri(
      'vlc',
      'https://srv.plex.direct:32400/library/parts/1/2/file.mkv?X-Plex-Token=abc&download=1',
      ExternalPlayerLaunchOptions(returnLinks: ExternalPlayerService.returnLinks('s3')),
    )!;

    // URLHandler.parseURL at tag 3.7.3: split on `&`, then on `=`, keep
    // `components[1]`, and open x-success/x-error with `URL(string: value)`.
    final parsed = {
      for (final entry in uri.query.split('&'))
        if (entry.split('=').length >= 2) entry.split('=')[0]: entry.split('=')[1],
    };
    for (final (key, path) in [('x-success', '/success/s3'), ('x-error', '/error/s3')]) {
      final link = Uri.parse(parsed[key]!);
      expect(link.scheme, 'plezy');
      expect(link.host, 'external-player');
      expect(link.path, path);
    }
    // `url` must arrive fully encoded for VLC to decode it.
    expect(parsed['url'], startsWith('https%3A%2F%2F'));
  });

  test('players without an x-callback-url play link have no callback URI', () {
    expect(KnownPlayers.callbackPlayUri('mpv', 'http://srv/v.mkv', const ExternalPlayerLaunchOptions()), isNull);
  });
}

Future<List<String>> _resolveWith(PlayerInstallProbe probe) async {
  KnownPlayers.resetForTesting();
  KnownPlayers.probe = probe;
  final players = await KnownPlayers.getForCurrentPlatform();
  return players.map((player) => player.id).toList();
}

/// Answers the host lookups from fixed sets, and records the subprocesses and
/// bundle lookups it is asked for so tests can assert what production issues.
class _FakeProbe extends PlayerInstallProbe {
  _FakeProbe({
    this.commands = const {},
    this.paths = const {},
    this.bundleIds = const {},
    this.schemes = const {},
    this.environment = const {},
    this.failEveryLookup = false,
    String? operatingSystem,
  }) : operatingSystem = operatingSystem ?? Platform.operatingSystem,
       _everything = false;

  _FakeProbe.everythingInstalled()
    : commands = const {},
      paths = const {},
      bundleIds = const {},
      schemes = const {},
      environment = const {},
      failEveryLookup = false,
      operatingSystem = Platform.operatingSystem,
      _everything = true;

  final Set<String> commands;
  final Set<String> paths;
  final Set<String> bundleIds;
  final Set<String> schemes;
  final bool failEveryLookup;
  final bool _everything;
  final List<List<String>> runs = [];
  final List<String> bundleLookups = [];
  final List<String> schemeLookups = [];

  @override
  final Map<String, String> environment;

  @override
  final String operatingSystem;

  @override
  Future<ProcessResult> run(String executable, List<String> arguments) async {
    runs.add([executable, ...arguments]);
    if (failEveryLookup) throw ProcessException(executable, arguments, 'probe unavailable');
    if (_everything) return ProcessResult(0, 0, '', '');

    switch (executable) {
      case 'sh':
        return ProcessResult(0, commands.contains(arguments.last) ? 0 : 1, '', '');
      case 'where.exe':
        return ProcessResult(0, commands.contains(arguments.single) ? 0 : 1, '', '');
      default:
        fail('unexpected probe subprocess: $executable $arguments');
    }
  }

  @override
  Future<bool> applicationInstalled(String bundleId) async {
    bundleLookups.add(bundleId);
    if (failEveryLookup) throw MissingPluginException('no app lookup plugin');
    return _everything || bundleIds.contains(bundleId);
  }

  @override
  Future<bool> fileExists(String path) async => _everything || paths.contains(path);

  @override
  Future<bool> schemeHasHandler(String scheme) async {
    schemeLookups.add(scheme);
    if (failEveryLookup) throw MissingPluginException('no url launcher plugin');
    return _everything || schemes.contains(scheme);
  }
}
