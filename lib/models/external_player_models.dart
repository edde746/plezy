import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_logger.dart';

typedef PlayerLauncher = Future<bool> Function(String url);
typedef PlayerOptionsLauncher = Future<bool> Function(String url, ExternalPlayerLaunchOptions options);

/// Extras for players whose URL scheme can carry more than the stream URL.
class ExternalPlayerLaunchOptions {
  const ExternalPlayerLaunchOptions({this.startPosition, this.returnLinks, this.filename});

  final Duration? startPosition;

  /// A descriptive file name (`Show - S01E02 - Title.mkv`) for players that
  /// identify media by name; stream URLs usually end in `file.mkv`.
  final String? filename;

  /// Where the player hands control back to Plezy; null asks for no return
  /// links.
  final ExternalPlayerReturnLinks? returnLinks;
}

/// The x-callback-url links a player opens to hand control back to Plezy,
/// one per way playback can end.
class ExternalPlayerReturnLinks {
  const ExternalPlayerReturnLinks({required this.success, required this.cancel, required this.error});

  final Uri success;
  final Uri cancel;
  final Uri error;
}

/// A player launched through `<scheme>://x-callback-url/<action>`, and which
/// of the optional parameters it understands.
class XCallbackPlayer {
  const XCallbackPlayer({
    required this.scheme,
    this.action = 'play',
    this.supportsCancel = false,
    this.supportsFilename = false,
    this.supportsStartPosition = true,
    this.successMeansFinished = true,
    this.decodesCallbackUrls = true,
  });

  final String scheme;
  final String action;
  final bool supportsCancel;
  final bool supportsFilename;

  /// Accepts `position`, the start time in seconds.
  final bool supportsStartPosition;

  /// Whether `x-success` without a position means the video played to the
  /// end, rather than that playback stopped somewhere unknown.
  final bool successMeansFinished;

  /// Whether the player percent-decodes `x-success`/`x-cancel`/`x-error`
  /// before opening them. Players that don't get the return links unencoded;
  /// they hold no `&` or `=`, so they survive a naive query split.
  final bool decodesCallbackUrls;

  /// Values are percent-encoded by hand because [Uri.queryParameters] writes
  /// spaces as `+`.
  Uri playUri(String url, ExternalPlayerLaunchOptions options) {
    final startSeconds = supportsStartPosition ? options.startPosition?.inSeconds ?? 0 : 0;
    final returnLinks = options.returnLinks;
    final filename = supportsFilename ? options.filename : null;
    String returnLink(Uri link) {
      final value = link.toString();
      return decodesCallbackUrls ? Uri.encodeComponent(value) : value;
    }

    final query = <String>[
      'url=${Uri.encodeComponent(url)}',
      if (filename != null) 'filename=${Uri.encodeComponent(filename)}',
      if (startSeconds > 0) 'position=$startSeconds',
      if (returnLinks != null) ...[
        'x-success=${returnLink(returnLinks.success)}',
        if (supportsCancel) 'x-cancel=${returnLink(returnLinks.cancel)}',
        'x-error=${returnLink(returnLinks.error)}',
      ],
    ].join('&');
    return Uri.parse('$scheme://x-callback-url/$action?$query');
  }
}

enum CustomPlayerType { command, urlScheme }

/// Host lookups behind [KnownPlayers.getForCurrentPlatform], split out so tests
/// can answer them without touching the real machine.
class PlayerInstallProbe {
  const PlayerInstallProbe();

  /// Drives which detectors run. Values match [Platform.operatingSystem].
  String get operatingSystem => Platform.operatingSystem;

  Map<String, String> get environment => Platform.environment;

  Future<ProcessResult> run(String executable, List<String> arguments) => Process.run(executable, arguments);

  Future<bool> fileExists(String path) => File(path).exists();

  /// macOS Launch Services lookup — the database `open -a` resolves through.
  /// Spotlight is deliberately not consulted: an empty `mdfind` result also
  /// means indexing is off or incomplete, which would hide installed players.
  Future<bool> applicationInstalled(String bundleId) async {
    const channel = MethodChannel('com.plezy/app_lookup');
    return await channel.invokeMethod<bool>('isApplicationInstalled', {'bundleId': bundleId}) ?? false;
  }

  Future<bool> schemeHasHandler(String scheme) => _canOpenAppUrl(Uri.parse(scheme));
}

class ExternalPlayer {
  final String id;
  final String name;
  final String? iconAsset;
  final bool isAvailable;
  final PlayerLauncher launch;

  /// Set for players that accept a start position and return links.
  final PlayerOptionsLauncher? launchWithOptions;
  final bool isCustom;
  final String? customValue; // Only for custom player serialization
  final CustomPlayerType? customType;

  ExternalPlayer({
    required this.id,
    required this.name,
    this.iconAsset,
    this.isAvailable = true,
    required this.launch,
    this.launchWithOptions,
    this.isCustom = false,
    this.customValue,
    this.customType,
  });

  factory ExternalPlayer.custom({
    required String id,
    required String name,
    required String value,
    required CustomPlayerType type,
  }) {
    return ExternalPlayer(
      id: id,
      name: name,
      isCustom: true,
      customValue: value,
      customType: type,
      launch: (url) => _launchCustom(value, url, type),
    );
  }

  factory ExternalPlayer.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final known = KnownPlayers.findById(id);
    if (known != null) return known;
    return ExternalPlayer.custom(
      id: id,
      name: json['name'] as String,
      value: json['customValue'] as String? ?? '',
      type: json['customType'] == 'urlScheme' ? CustomPlayerType.urlScheme : CustomPlayerType.command,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (isCustom) 'isCustom': true,
    if (customValue != null) 'customValue': customValue,
    if (customType != null) 'customType': customType == CustomPlayerType.urlScheme ? 'urlScheme' : 'command',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExternalPlayer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const _tvosBuild = bool.fromEnvironment('TVOS_BUILD');

/// The tvOS Runner has no url_launcher implementation; it answers the two
/// handoff questions itself on this channel (Android's `openVideo` shares it).
const _tvosHandoffChannel = MethodChannel('com.plezy/external_player');

Future<bool> _canOpenAppUrl(Uri uri) async {
  if (!_tvosBuild) return canLaunchUrl(uri);
  return await _tvosHandoffChannel.invokeMethod<bool>('canOpenUrl', {'url': uri.toString()}) ?? false;
}

Future<bool> _launchWithUrl(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

Future<bool> _launchAndroidIntent(String url, {required String package, bool fallbackToUrl = true}) async {
  final intentUri = Uri.parse(
    'intent:$url#Intent;'
    'action=android.intent.action.VIEW;'
    'type=video/*;'
    'package=$package;'
    'end',
  );
  try {
    return await launchUrl(intentUri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return fallbackToUrl ? _launchWithUrl(url) : false;
  }
}

Future<bool> _launchAndroidIntentCandidates(String url, Iterable<String> packages) async {
  for (final package in packages) {
    if (await _launchAndroidIntent(url, package: package, fallbackToUrl: false)) return true;
  }
  return _launchWithUrl(url);
}

Future<bool> _launchUrlScheme(String scheme, String url) {
  final playerUrl = scheme.contains('url=') ? '$scheme${Uri.encodeComponent(url)}' : '$scheme$url';
  return _openPlayerUri(Uri.parse(playerUrl));
}

Future<bool> _openPlayerUri(Uri uri) async {
  // Apple platforms skip the canOpenURL gate: it answers false for any scheme
  // missing from LSApplicationQueriesSchemes, which is every custom player.
  // The open call reports a missing handler itself.
  if (_tvosBuild) {
    return await _tvosHandoffChannel.invokeMethod<bool>('openUrl', {'url': uri.toString()}) ?? false;
  }
  if (Platform.isIOS) return launchUrl(uri, mode: LaunchMode.externalApplication);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

Future<bool> _launchMacApp(String appName, String url) async {
  try {
    await Process.start('open', ['-a', appName, url], mode: ProcessStartMode.detached);
    return true;
  } catch (e) {
    appLogger.w('Failed to launch $appName via open -a', error: e);
    return false;
  }
}

Future<bool> _launchCommand(String command, String url) async {
  try {
    final result = await Process.start(command, [url], mode: ProcessStartMode.detached);
    appLogger.d('Launched $command with PID: ${result.pid}');
    return true;
  } catch (e) {
    appLogger.w('Failed to launch $command', error: e);
    return false;
  }
}

Future<bool> _launchCommandCandidates(Iterable<String> commands, String url) async {
  final commandList = commands.toList(growable: false);
  Object? lastError;
  for (final command in commandList) {
    try {
      final result = await Process.start(command, [url], mode: ProcessStartMode.detached);
      appLogger.d('Launched $command with PID: ${result.pid}');
      return true;
    } catch (e) {
      lastError = e;
      appLogger.d('Failed to launch $command', error: e);
    }
  }

  appLogger.w('Failed to launch any of: ${commandList.join(', ')}', error: lastError);
  return false;
}

List<String> _windowsVlcCommandCandidates(Map<String, String> environment) {
  final candidates = <String>['vlc'];

  void addInstallPath(String? programFilesDir) {
    final trimmed = programFilesDir?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    final root = trimmed.replaceFirst(RegExp(r'[\\/]+$'), '');
    candidates.add('$root\\VideoLAN\\VLC\\vlc.exe');
  }

  addInstallPath(environment['ProgramW6432']);
  addInstallPath(environment['ProgramFiles']);
  addInstallPath(environment['ProgramFiles(x86)']);
  addInstallPath(r'C:\Program Files');
  addInstallPath(r'C:\Program Files (x86)');

  final seen = <String>{};
  return [
    for (final candidate in candidates)
      if (seen.add(candidate.toLowerCase())) candidate,
  ];
}

Future<bool> _launchWindowsVlc(String url) {
  return _launchCommandCandidates(_windowsVlcCommandCandidates(Platform.environment), url);
}

Future<bool> _launchCustom(String value, String url, CustomPlayerType type) async {
  if (type == CustomPlayerType.urlScheme) {
    return _launchUrlScheme(value, url);
  }
  // Command type
  if (Platform.isAndroid) {
    return _launchAndroidIntent(url, package: value);
  } else if (Platform.isMacOS) {
    // Try PATH first (e.g. mpv), fall back to open -a (e.g. VLC)
    if (await _launchCommand(value, url)) return true;
    return _launchMacApp(value, url);
  } else {
    return _launchCommand(value, url);
  }
}

class KnownPlayers {
  /// Hands the stream URL to whatever the OS opens it with. tvOS has no
  /// browser or default handler for http(s), so there is nothing to hand to.
  static final systemDefault = ExternalPlayer(
    id: 'system_default',
    name: 'System Default',
    isAvailable: !_tvosBuild,
    launch: _launchWithUrl,
  );

  static const _androidPackageMap = <String, List<String>>{
    'vlc': ['org.videolan.vlc'],
    'mpv': ['is.xyz.mpv'],
    'mx_player': ['com.mxtech.videoplayer.ad', 'com.mxtech.videoplayer.pro'],
    'just_player': ['com.brouken.player'],
  };

  static List<String> _androidPackageCandidatesForId(String id) {
    return _androidPackageMap[id] ?? const [];
  }

  static List<String> androidPackageCandidates(ExternalPlayer player) {
    final knownPackages = _androidPackageCandidatesForId(player.id);
    if (knownPackages.isNotEmpty) return knownPackages;
    if (player.isCustom && player.customType == CustomPlayerType.command) {
      final package = player.customValue?.trim();
      return package == null || package.isEmpty ? const [] : [package];
    }
    return const [];
  }

  static final _allPlayers = <ExternalPlayer>[
    systemDefault,
    ExternalPlayer(
      id: 'vlc',
      name: 'VLC',
      iconAsset: 'assets/player_icons/vlc.svg',
      isAvailable: Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux || Platform.isWindows,
      launch: (url) {
        if (Platform.isAndroid) return _launchAndroidIntentCandidates(url, _androidPackageCandidatesForId('vlc'));
        if (Platform.isIOS) return _launchUrlScheme('vlc://', url);
        if (Platform.isMacOS) return _launchMacApp('VLC', url);
        if (Platform.isWindows) return _launchWindowsVlc(url);
        return _launchCommand('vlc', url);
      },
      // iOS only: tvOS has no handler for the return links.
      launchWithOptions: Platform.isIOS && !_tvosBuild
          ? (url, options) => _openPlayerUri(callbackPlayUri('vlc', url, options)!)
          : null,
    ),
    ExternalPlayer(
      id: 'mpv',
      name: 'mpv',
      iconAsset: 'assets/player_icons/mpv.svg',
      isAvailable: Platform.isAndroid || Platform.isMacOS || Platform.isLinux || Platform.isWindows,
      launch: (url) {
        if (Platform.isAndroid) return _launchAndroidIntentCandidates(url, _androidPackageCandidatesForId('mpv'));
        return _launchCommand('mpv', url);
      },
    ),
    ExternalPlayer(
      id: 'iina',
      name: 'IINA',
      iconAsset: 'assets/player_icons/iina.png',
      isAvailable: Platform.isMacOS,
      launch: (url) => _launchUrlScheme('iina://weblink?url=', url),
    ),
    ExternalPlayer(
      id: 'mx_player',
      name: 'MX Player',
      iconAsset: 'assets/player_icons/mx_player.svg',
      isAvailable: Platform.isAndroid,
      launch: (url) => _launchAndroidIntentCandidates(url, _androidPackageCandidatesForId('mx_player')),
    ),
    ExternalPlayer(
      id: 'just_player',
      name: 'Just Player',
      iconAsset: 'assets/player_icons/just_player.png',
      isAvailable: Platform.isAndroid,
      launch: (url) => _launchAndroidIntentCandidates(url, _androidPackageCandidatesForId('just_player')),
    ),
    ExternalPlayer(
      id: 'infuse',
      name: 'Infuse',
      iconAsset: 'assets/player_icons/infuse.png',
      isAvailable: Platform.isIOS,
      launch: (url) => _launchUrlScheme('infuse://x-callback-url/play?url=', url),
      // tvOS has no handler for the return links.
      launchWithOptions: _tvosBuild ? null : (url, options) => _openPlayerUri(callbackPlayUri('infuse', url, options)!),
    ),
    ExternalPlayer(
      id: 'outplayer',
      name: 'Outplayer',
      iconAsset: 'assets/player_icons/outplayer.png',
      isAvailable: Platform.isIOS && !_tvosBuild,
      launch: (url) => _openPlayerUri(callbackPlayUri('outplayer', url, const ExternalPlayerLaunchOptions())!),
      launchWithOptions: (url, options) => _openPlayerUri(callbackPlayUri('outplayer', url, options)!),
    ),
    ExternalPlayer(
      id: 'potplayer',
      name: 'PotPlayer',
      iconAsset: 'assets/player_icons/potplayer.png',
      isAvailable: Platform.isWindows,
      launch: (url) async {
        if (await _launchUrlScheme('potplayer://', url)) return true;
        return _launchCommand('PotPlayerMini64', url);
      },
    ),
    ExternalPlayer(
      id: 'celluloid',
      name: 'Celluloid',
      iconAsset: 'assets/player_icons/celluloid.svg',
      isAvailable: Platform.isLinux,
      launch: (url) => _launchCommand('celluloid', url),
    ),
  ];

  static const _xCallbackPlayers = <String, XCallbackPlayer>{
    'outplayer': XCallbackPlayer(scheme: 'outplayer', supportsCancel: true),
    // No x-cancel: Infuse calls x-success with the position once playback
    // ends. It matches metadata from `filename`.
    'infuse': XCallbackPlayer(scheme: 'infuse', supportsFilename: true),
    // VLC calls x-success on every stop, finished or not, and appends nothing:
    // no position comes back, and it takes no start position either. VLC 3.7.x
    // opens the return links as `URL(string: value)` without decoding them.
    'vlc': XCallbackPlayer(
      scheme: 'vlc-x-callback',
      action: 'stream',
      supportsStartPosition: false,
      successMeansFinished: false,
      decodesCallbackUrls: false,
    ),
  };

  /// How [playerId] is launched through x-callback-url, or null for players
  /// that are not launched that way.
  static XCallbackPlayer? xCallbackPlayer(String playerId) => _xCallbackPlayers[playerId];

  /// The x-callback-url play link for [playerId], or null for players that
  /// are not launched that way.
  static Uri? callbackPlayUri(String playerId, String url, ExternalPlayerLaunchOptions options) {
    return _xCallbackPlayers[playerId]?.playUri(url, options);
  }

  /// Host lookups used to decide whether a supported player is actually
  /// installed. Overridden in tests; production talks to the real process,
  /// filesystem and URL-handler APIs.
  @visibleForTesting
  static PlayerInstallProbe probe = const PlayerInstallProbe();

  static Future<List<ExternalPlayer>>? _installedPlayers;

  /// Players supported on this platform, minus the ones we can positively tell
  /// are not installed.
  ///
  /// Detection forks `sh` or `where.exe` and calls out over platform channels,
  /// so it is asynchronous and memoised: it runs once per process and a player
  /// installed while Plezy is running only appears after a restart. Android is
  /// the one platform left unprobed — where there is no reliable check the
  /// player stays listed, because hiding a working player is worse than
  /// listing a missing one.
  static Future<List<ExternalPlayer>> getForCurrentPlatform() {
    return _installedPlayers ??= _resolveForCurrentPlatform();
  }

  @visibleForTesting
  static void resetForTesting() {
    probe = const PlayerInstallProbe();
    _installedPlayers = null;
  }

  static Future<List<ExternalPlayer>> _resolveForCurrentPlatform() async {
    final supported = [
      for (final player in _allPlayers)
        if (player.isAvailable) player,
    ];

    // Each detector must answer the same question its launcher asks, so a
    // listed player is one we can actually start.
    final detectors = <String, Future<bool> Function()>{};
    switch (probe.operatingSystem) {
      case 'linux':
        detectors['vlc'] = () => _posixCommandExists('vlc');
        detectors['mpv'] = () => _posixCommandExists('mpv');
        detectors['celluloid'] = () => _posixCommandExists('celluloid');
      case 'macos':
        detectors['vlc'] = () => probe.applicationInstalled('org.videolan.vlc');
        detectors['iina'] = () => probe.applicationInstalled('com.colliderli.iina');
        detectors['mpv'] = () => _posixCommandExists('mpv');
      case 'windows':
        detectors['vlc'] = _windowsVlcExists;
        detectors['mpv'] = () => _windowsCommandExists('mpv');
        detectors['potplayer'] = _windowsPotPlayerExists;
      case 'ios':
        // iOS and tvOS. These schemes are declared in the Runners'
        // LSApplicationQueriesSchemes, so the handler check is truthful and
        // detection can never hide a player the handoff would have reached.
        detectors['vlc'] = () => probe.schemeHasHandler('vlc://');
        detectors['infuse'] = () => probe.schemeHasHandler('infuse://');
        if (!_tvosBuild) detectors['outplayer'] = () => probe.schemeHasHandler('outplayer://');
    }
    if (detectors.isEmpty) return supported;

    final ids = detectors.keys.toList(growable: false);
    final found = await Future.wait(ids.map((id) => _detect(id, detectors[id]!)));
    final missing = <String>{
      for (var i = 0; i < ids.length; i++)
        if (!found[i]) ids[i],
    };
    if (missing.isEmpty) return supported;

    return [
      for (final player in supported)
        if (!missing.contains(player.id)) player,
    ];
  }

  /// Runs one detector, failing open: a probe that blows up must not hide a
  /// player the user may well have installed.
  static Future<bool> _detect(String id, Future<bool> Function() detector) async {
    try {
      return await detector();
    } catch (e, stackTrace) {
      appLogger.w('External player detection failed for $id; listing it anyway', error: e, stackTrace: stackTrace);
      return true;
    }
  }

  /// True when [command] resolves on `PATH`. The shell defers to the kernel, so
  /// permission classes, ACLs and `noexec` mounts are honoured exactly as they
  /// will be when [Process.start] execs the command.
  static Future<bool> _posixCommandExists(String command) async {
    final result = await probe.run('sh', ['-c', r'command -v "$1" >/dev/null 2>&1', 'plezy-command-probe', command]);
    return result.exitCode == 0;
  }

  static Future<bool> _windowsCommandExists(String command) async {
    final result = await probe.run('where.exe', [command]);
    return result.exitCode == 0;
  }

  /// Mirrors [_launchWindowsVlc]: any of the concrete install paths, or `vlc`
  /// on `PATH`.
  static Future<bool> _windowsVlcExists() async {
    for (final candidate in _windowsVlcCommandCandidates(probe.environment)) {
      if (candidate.contains(r'\') && await probe.fileExists(candidate)) return true;
    }
    return _windowsCommandExists('vlc');
  }

  /// Mirrors the PotPlayer launcher: the registered `potplayer://` handler, or
  /// the executable on `PATH`.
  static Future<bool> _windowsPotPlayerExists() async {
    if (await probe.schemeHasHandler('potplayer://')) return true;
    return _windowsCommandExists('PotPlayerMini64');
  }

  static ExternalPlayer? findById(String id) {
    try {
      return _allPlayers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
