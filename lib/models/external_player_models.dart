import 'dart:convert';

import '../utils/platform_helper.dart';
import '../utils/io_helpers.dart';

import 'package:url_launcher/url_launcher.dart';

import '../utils/app_logger.dart';

typedef PlayerLauncher = Future<bool> Function(String url);

enum CustomPlayerType { command, urlScheme }

class ExternalPlayer {
  final String id;
  final String name;
  final String? iconAsset;
  final bool isAvailable;
  final PlayerLauncher launch;
  final bool isCustom;
  final String? customValue; // Only for custom player serialization
  final CustomPlayerType? customType;

  ExternalPlayer({
    required this.id,
    required this.name,
    this.iconAsset,
    this.isAvailable = true,
    required this.launch,
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

  String toJsonString() => json.encode(toJson());

  static ExternalPlayer fromJsonString(String jsonString) =>
      ExternalPlayer.fromJson(json.decode(jsonString) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExternalPlayer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// --- Launch helpers ---

Future<bool> _launchWithUrl(String url) async {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

Future<bool> _launchAndroidIntent(String url, {required String package}) async {
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
    return _launchWithUrl(url);
  }
}

Future<bool> _launchUrlScheme(String scheme, String url) async {
  final playerUrl = scheme.contains('url=') ? '$scheme${Uri.encodeComponent(url)}' : '$scheme$url';
  final uri = Uri.parse(playerUrl);
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

Future<bool> _launchCustom(String value, String url, CustomPlayerType type) async {
  if (type == CustomPlayerType.urlScheme) {
    return _launchUrlScheme(value, url);
  }
  // Command type
  if (AppPlatform.isAndroid) {
    return _launchAndroidIntent(url, package: value);
  } else if (AppPlatform.isMacOS) {
    // Try PATH first (e.g. mpv), fall back to open -a (e.g. VLC)
    if (await _launchCommand(value, url)) return true;
    return _launchMacApp(value, url);
  } else {
    return _launchCommand(value, url);
  }
}

// --- Known Players ---

class KnownPlayers {
  static final systemDefault = ExternalPlayer(id: 'system_default', name: 'System Default', launch: _launchWithUrl);

  static final _allPlayers = <ExternalPlayer>[
    systemDefault,
    ExternalPlayer(
      id: 'vlc',
      name: 'VLC',
      iconAsset: 'assets/player_icons/vlc.svg',
      isAvailable: AppPlatform.isAndroid || AppPlatform.isIOS || AppPlatform.isMacOS || AppPlatform.isLinux || AppPlatform.isWindows,
      launch: (url) async {
        if (AppPlatform.isAndroid) return _launchAndroidIntent(url, package: 'org.videolan.vlc');
        if (AppPlatform.isIOS) return _launchUrlScheme('vlc://', url);
        if (AppPlatform.isMacOS) return _launchMacApp('VLC', url);
        return _launchCommand('vlc', url);
      },
    ),
    ExternalPlayer(
      id: 'mpv',
      name: 'mpv',
      iconAsset: 'assets/player_icons/mpv.svg',
      isAvailable: AppPlatform.isAndroid || AppPlatform.isMacOS || AppPlatform.isLinux || AppPlatform.isWindows,
      launch: (url) async {
        if (AppPlatform.isAndroid) return _launchAndroidIntent(url, package: 'is.xyz.mpv');
        return _launchCommand('mpv', url);
      },
    ),
    ExternalPlayer(
      id: 'iina',
      name: 'IINA',
      iconAsset: 'assets/player_icons/iina.png',
      isAvailable: AppPlatform.isMacOS,
      launch: (url) => _launchUrlScheme('iina://weblink?url=', url),
    ),
    ExternalPlayer(
      id: 'mx_player',
      name: 'MX Player',
      iconAsset: 'assets/player_icons/mx_player.svg',
      isAvailable: AppPlatform.isAndroid,
      launch: (url) => _launchAndroidIntent(url, package: 'com.mxtech.videoplayer.ad'),
    ),
    ExternalPlayer(
      id: 'just_player',
      name: 'Just Player',
      iconAsset: 'assets/player_icons/just_player.png',
      isAvailable: AppPlatform.isAndroid,
      launch: (url) => _launchAndroidIntent(url, package: 'com.brouken.player'),
    ),
    ExternalPlayer(
      id: 'infuse',
      name: 'Infuse',
      iconAsset: 'assets/player_icons/infuse.png',
      isAvailable: AppPlatform.isIOS,
      launch: (url) => _launchUrlScheme('infuse://x-callback-url/play?url=', url),
    ),
    ExternalPlayer(
      id: 'potplayer',
      name: 'PotPlayer',
      iconAsset: 'assets/player_icons/potplayer.png',
      isAvailable: AppPlatform.isWindows,
      launch: (url) async {
        if (await _launchUrlScheme('potplayer://', url)) return true;
        return _launchCommand('PotPlayerMini64', url);
      },
    ),
    ExternalPlayer(
      id: 'celluloid',
      name: 'Celluloid',
      iconAsset: 'assets/player_icons/celluloid.svg',
      isAvailable: AppPlatform.isLinux,
      launch: (url) => _launchCommand('celluloid', url),
    ),
  ];

  /// Get players available on the current platform
  static List<ExternalPlayer> getForCurrentPlatform() {
    return _allPlayers.where((p) => p.isAvailable).toList();
  }

  /// Find a known player by ID
  static ExternalPlayer? findById(String id) {
    try {
      return _allPlayers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
