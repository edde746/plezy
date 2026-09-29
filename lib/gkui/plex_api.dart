import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'diagnostics.dart';

const String plexProduct = 'Plezy GKUI';
const String plexVersion = '1.2.2';

class PlexPin {
  const PlexPin({required this.id, required this.code});
  final int id;
  final String code;

  String authUrl(String clientIdentifier) {
    final query = <String, String>{
      'clientID': clientIdentifier,
      'code': code,
      'context[device][product]': plexProduct,
    };
    return Uri.https('app.plex.tv', '/auth', query)
        .toString()
        .replaceFirst('?', '#?');
  }
}

class PlexSession {
  const PlexSession({
    required this.accountToken,
    required this.serverToken,
    required this.serverName,
    required this.serverId,
    required this.baseUrl,
  });

  final String accountToken;
  final String serverToken;
  final String serverName;
  final String serverId;
  final String baseUrl;

  Map<String, String> toStorage() => <String, String>{
        'accountToken': accountToken,
        'serverToken': serverToken,
        'serverName': serverName,
        'serverId': serverId,
        'baseUrl': baseUrl,
      };

  static PlexSession? fromStorage(Map<String, String?> values) {
    if (values.values.any((value) => value == null || value.isEmpty))
      return null;
    return PlexSession(
      accountToken: values['accountToken']!,
      serverToken: values['serverToken']!,
      serverName: values['serverName']!,
      serverId: values['serverId']!,
      baseUrl: values['baseUrl']!,
    );
  }
}

class PlexServerResource {
  const PlexServerResource({
    required this.name,
    required this.id,
    required this.token,
    required this.connections,
  });

  final String name;
  final String id;
  final String token;
  final List<PlexConnection> connections;
}

class PlexConnection {
  const PlexConnection(
      {required this.uri, required this.local, required this.relay});
  final String uri;
  final bool local;
  final bool relay;
}

class PlexSection {
  const PlexSection(
      {required this.key, required this.title, required this.type});
  final String key;
  final String title;
  final String type;
}

class PlexHomeUser {
  const PlexHomeUser({
    required this.uuid,
    required this.displayName,
    required this.thumb,
    required this.protected,
    required this.admin,
    required this.guest,
  });

  final String uuid;
  final String displayName;
  final String thumb;
  final bool protected;
  final bool admin;
  final bool guest;

  factory PlexHomeUser.fromJson(Map<String, dynamic> json) => PlexHomeUser(
        uuid: json['uuid']?.toString() ?? '',
        displayName: json['friendlyName']?.toString().isNotEmpty == true
            ? json['friendlyName'].toString()
            : json['title']?.toString() ?? 'Plex user',
        thumb: json['thumb']?.toString() ?? '',
        protected: json['protected'] == true || json['hasPassword'] == true,
        admin: json['admin'] == true,
        guest: json['guest'] == true,
      );
}

class PlexMediaVersion {
  const PlexMediaVersion({
    required this.index,
    required this.partKey,
    this.partId,
    this.resolution,
    this.codec,
    this.container,
    this.bitrateKbps,
    this.width,
    this.height,
    this.sizeBytes,
    this.audioTracks = const <PlexTrack>[],
    this.subtitleTracks = const <PlexTrack>[],
  });

  final int index;
  final String partKey;
  final String? partId;
  final String? resolution;
  final String? codec;
  final String? container;
  final int? bitrateKbps;
  final int? width;
  final int? height;
  final int? sizeBytes;
  final List<PlexTrack> audioTracks;
  final List<PlexTrack> subtitleTracks;

  int get effectiveHeight {
    if (height != null && height! > 0) return height!;
    if ((resolution ?? '').toLowerCase() == '4k') return 2160;
    return int.tryParse((resolution ?? '').replaceAll(RegExp('[^0-9]'), '')) ??
        0;
  }

  String get displayLabel {
    final fields = <String>[
      if (effectiveHeight > 0) '${effectiveHeight}p',
      if (codec?.isNotEmpty == true) codec!.toUpperCase(),
      if (container?.isNotEmpty == true) container!.toUpperCase(),
    ];
    final rate = bitrateKbps == null || bitrateKbps! <= 0
        ? ''
        : ' • ${(bitrateKbps! / 1000).toStringAsFixed(1)} Mbps';
    final size = sizeBytes == null || sizeBytes! <= 0
        ? ''
        : ' • ${(sizeBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    return '${fields.isEmpty ? 'Unknown version' : fields.join(' ')}$rate$size';
  }

  static int preferredIndex(List<PlexMediaVersion> versions) {
    if (versions.isEmpty) return 0;
    final ranked = List<PlexMediaVersion>.from(versions)
      ..sort((a, b) {
        int score(PlexMediaVersion value) {
          final height = value.effectiveHeight;
          final resolutionScore = height == 1080
              ? 100000
              : height > 0 && height < 1080
                  ? 50000 + height
                  : height > 1080
                      ? 1000 - height
                      : 0;
          final codecScore = value.codec?.toLowerCase() == 'h264' ? 10000 : 0;
          return resolutionScore + codecScore + (value.bitrateKbps ?? 0) ~/ 100;
        }

        return score(b).compareTo(score(a));
      });
    return ranked.first.index;
  }
}

class PlexTrack {
  const PlexTrack({
    required this.id,
    required this.type,
    this.languageCode,
    this.language,
    this.title,
    this.codec,
    this.channels,
    this.selected = false,
    this.forced = false,
  });

  final String id;
  final String type;
  final String? languageCode;
  final String? language;
  final String? title;
  final String? codec;
  final int? channels;
  final bool selected;
  final bool forced;

  String get displayLabel {
    final fields = <String>[
      if (language?.isNotEmpty == true) language!,
      if (title?.isNotEmpty == true && title != language) title!,
      if (codec?.isNotEmpty == true) codec!.toUpperCase(),
      if (channels != null && channels! > 0) '${channels}ch',
      if (forced) 'Forced',
    ];
    return fields.isEmpty ? 'Track $id' : fields.join(' • ');
  }
}

class PlexMarker {
  const PlexMarker(
      {required this.type, required this.startMs, required this.endMs});
  final String type;
  final int startMs;
  final int endMs;
}

enum SkipMode { off, button, automatic }

enum SearchMediaFilter { all, movie, show, episode }

class GkuiSettings {
  const GkuiSettings({
    this.audioLanguage = '',
    this.subtitleLanguage = '',
    this.seekBackSeconds = 10,
    this.seekForwardSeconds = 30,
    this.autoPlayNext = true,
    this.skipMode = SkipMode.button,
    this.playNextCountdownSeconds = 5,
    this.showWatchedIndicators = true,
  });

  final String audioLanguage;
  final String subtitleLanguage;
  final int seekBackSeconds;
  final int seekForwardSeconds;
  final bool autoPlayNext;
  final SkipMode skipMode;
  final int playNextCountdownSeconds;
  final bool showWatchedIndicators;

  GkuiSettings copyWith({
    String? audioLanguage,
    String? subtitleLanguage,
    int? seekBackSeconds,
    int? seekForwardSeconds,
    bool? autoPlayNext,
    SkipMode? skipMode,
    int? playNextCountdownSeconds,
    bool? showWatchedIndicators,
  }) =>
      GkuiSettings(
        audioLanguage: audioLanguage ?? this.audioLanguage,
        subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
        seekBackSeconds: seekBackSeconds ?? this.seekBackSeconds,
        seekForwardSeconds: seekForwardSeconds ?? this.seekForwardSeconds,
        autoPlayNext: autoPlayNext ?? this.autoPlayNext,
        skipMode: skipMode ?? this.skipMode,
        playNextCountdownSeconds:
            playNextCountdownSeconds ?? this.playNextCountdownSeconds,
        showWatchedIndicators:
            showWatchedIndicators ?? this.showWatchedIndicators,
      );
}

class PlexPage {
  const PlexPage({
    required this.items,
    required this.start,
    required this.total,
  });
  final List<PlexMedia> items;
  final int start;
  final int total;
  int get nextStart => start + items.length;
  bool get hasMore => items.isNotEmpty && nextStart < total;
}

class PlaybackChoice {
  const PlaybackChoice({
    this.mediaIndex,
    this.audioTrackId,
    this.subtitleTrackId,
  });
  final int? mediaIndex;
  final String? audioTrackId;
  final String? subtitleTrackId;
}

class PlexMedia {
  const PlexMedia({
    required this.ratingKey,
    required this.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.summary,
    this.thumb,
    this.art,
    this.durationMs = 0,
    this.viewOffsetMs = 0,
    this.year,
    this.children = false,
    this.directPartKey,
    this.parentRatingKey,
    this.grandparentRatingKey,
    this.index,
    this.parentIndex,
    this.viewCount = 0,
    this.versions = const <PlexMediaVersion>[],
  });

  final String ratingKey;
  final String key;
  final String type;
  final String title;
  final String? subtitle;
  final String? summary;
  final String? thumb;
  final String? art;
  final int durationMs;
  final int viewOffsetMs;
  final int? year;
  final bool children;
  final String? directPartKey;
  final String? parentRatingKey;
  final String? grandparentRatingKey;
  final int? index;
  final int? parentIndex;
  final int viewCount;
  final List<PlexMediaVersion> versions;

  bool get playable =>
      type == 'movie' || type == 'episode' || directPartKey != null;

  bool get watched => viewCount > 0;

  PlexMedia copyWith({int? viewOffsetMs}) => PlexMedia(
        ratingKey: ratingKey,
        key: key,
        type: type,
        title: title,
        subtitle: subtitle,
        summary: summary,
        thumb: thumb,
        art: art,
        durationMs: durationMs,
        viewOffsetMs: viewOffsetMs ?? this.viewOffsetMs,
        year: year,
        children: children,
        directPartKey: directPartKey,
        parentRatingKey: parentRatingKey,
        grandparentRatingKey: grandparentRatingKey,
        index: index,
        parentIndex: parentIndex,
        viewCount: viewCount,
        versions: versions,
      );
}

class PlexShelf {
  const PlexShelf({required this.title, required this.items});
  final String title;
  final List<PlexMedia> items;
}

class PlaybackRequest {
  const PlaybackRequest({
    required this.url,
    required this.headers,
    required this.sessionId,
    required this.transcoding,
  });
  final String url;
  final Map<String, String> headers;
  final String sessionId;
  final bool transcoding;
}

class PlexApi {
  PlexApi._(this._prefs, this.logs, this.clientIdentifier)
      : _accountDio = Dio(_options()),
        _serverDio = Dio(_options());

  final SharedPreferences _prefs;
  final RedactingLogStore logs;
  final String clientIdentifier;
  final Dio _accountDio;
  final Dio _serverDio;
  final Map<String, List<PlexMarker>> _markerCache =
      <String, List<PlexMarker>>{};
  PlexSession? session;

  String get safeEndpoint {
    final uri = Uri.tryParse(session?.baseUrl ?? '');
    if (uri == null || uri.host.isEmpty) return 'not connected';
    final host = uri.host.endsWith('.plex.direct') ? '….plex.direct' : uri.host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://$host$port';
  }

  static Future<void> installLegacyTrust() async {
    final data = await rootBundle.load('assets/ca/legacy-roots.pem');
    final context = SecurityContext(withTrustedRoots: true);
    context.setTrustedCertificatesBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    HttpOverrides.global = _LegacyTrustOverrides(context);
  }

  static BaseOptions _options() => BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 12),
        responseType: ResponseType.json,
        headers: const <String, String>{'Accept': 'application/json'},
      );

  static Future<PlexApi> create(RedactingLogStore logs) async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('gkui.clientIdentifier');
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString('gkui.clientIdentifier', id);
    }
    final api = PlexApi._(prefs, logs, id);
    api.session = PlexSession.fromStorage(<String, String?>{
      'accountToken': prefs.getString('gkui.accountToken'),
      'serverToken': prefs.getString('gkui.serverToken'),
      'serverName': prefs.getString('gkui.serverName'),
      'serverId': prefs.getString('gkui.serverId'),
      'baseUrl': prefs.getString('gkui.baseUrl'),
    });
    return api;
  }

  GkuiSettings loadSettings() => GkuiSettings(
        audioLanguage: _prefs.getString('gkui.audioLanguage') ?? '',
        subtitleLanguage: _prefs.getString('gkui.subtitleLanguage') ?? '',
        seekBackSeconds: _prefs.getInt('gkui.seekBackSeconds') ?? 10,
        seekForwardSeconds: _prefs.getInt('gkui.seekForwardSeconds') ?? 30,
        autoPlayNext: _prefs.getBool('gkui.autoPlayNext') ?? true,
        skipMode: SkipMode.values.firstWhere(
          (value) => value.name == _prefs.getString('gkui.skipMode'),
          orElse: () => (_prefs.getBool('gkui.showSkipMarkers') ?? true)
              ? SkipMode.button
              : SkipMode.off,
        ),
        playNextCountdownSeconds:
            _prefs.getInt('gkui.playNextCountdownSeconds') ?? 5,
        showWatchedIndicators:
            _prefs.getBool('gkui.showWatchedIndicators') ?? true,
      );

  Future<void> saveSettings(GkuiSettings value) async {
    await Future.wait(<Future<bool>>[
      _prefs.setString('gkui.audioLanguage', value.audioLanguage),
      _prefs.setString('gkui.subtitleLanguage', value.subtitleLanguage),
      _prefs.setInt('gkui.seekBackSeconds', value.seekBackSeconds),
      _prefs.setInt('gkui.seekForwardSeconds', value.seekForwardSeconds),
      _prefs.setBool('gkui.autoPlayNext', value.autoPlayNext),
      _prefs.setString('gkui.skipMode', value.skipMode.name),
      _prefs.setInt(
          'gkui.playNextCountdownSeconds', value.playNextCountdownSeconds),
      _prefs.setBool('gkui.showWatchedIndicators', value.showWatchedIndicators),
    ]);
  }

  String _choiceKey(PlexMedia item) {
    final value = _requireSession();
    final scope = item.type == 'episode'
        ? item.grandparentRatingKey ?? item.ratingKey
        : item.ratingKey;
    return '${value.serverId}:${currentHomeUserUuid ?? 'account'}:$scope';
  }

  PlaybackChoice loadPlaybackChoice(PlexMedia item) {
    final raw = _prefs.getString('gkui.playbackChoices');
    if (raw == null) return const PlaybackChoice();
    try {
      final all = jsonDecode(raw) as Map<String, dynamic>;
      final value = all[_choiceKey(item)] as Map<String, dynamic>?;
      if (value == null) return const PlaybackChoice();
      return PlaybackChoice(
        mediaIndex: (value['mediaIndex'] as num?)?.toInt(),
        audioTrackId: value['audioTrackId']?.toString(),
        subtitleTrackId: value['subtitleTrackId']?.toString(),
      );
    } catch (_) {
      return const PlaybackChoice();
    }
  }

  Future<void> savePlaybackChoice(PlexMedia item, PlaybackChoice choice) async {
    final raw = _prefs.getString('gkui.playbackChoices');
    Map<String, dynamic> all;
    try {
      all = raw == null
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      all = <String, dynamic>{};
    }
    all[_choiceKey(item)] = <String, dynamic>{
      if (choice.mediaIndex != null) 'mediaIndex': choice.mediaIndex,
      if (choice.audioTrackId != null) 'audioTrackId': choice.audioTrackId,
      if (choice.subtitleTrackId != null)
        'subtitleTrackId': choice.subtitleTrackId,
    };
    // Keep preference storage bounded on the low-memory device.
    while (all.length > 200) {
      all.remove(all.keys.first);
    }
    await _prefs.setString('gkui.playbackChoices', jsonEncode(all));
  }

  String? get currentHomeUserUuid =>
      _prefs.getString('gkui.currentHomeUserUuid');
  String? get currentHomeUserName =>
      _prefs.getString('gkui.currentHomeUserName');

  Future<void> saveCurrentHomeUser(PlexHomeUser user) async {
    await Future.wait(<Future<bool>>[
      _prefs.setString('gkui.currentHomeUserUuid', user.uuid),
      _prefs.setString('gkui.currentHomeUserName', user.displayName),
    ]);
  }

  Map<String, String> headers([String? token]) => <String, String>{
        'Accept': 'application/json',
        'X-Plex-Product': plexProduct,
        'X-Plex-Version': plexVersion,
        'X-Plex-Client-Identifier': clientIdentifier,
        'X-Plex-Platform': 'Android',
        'X-Plex-Device': 'GKUI',
        if (token != null) 'X-Plex-Token': token,
      };

  Future<List<PlexHomeUser>> loadHomeUsers() async {
    final value = _requireSession();
    final response = await _accountDio.get<Map<String, dynamic>>(
      'https://clients.plex.tv/api/v2/home/users',
      options: Options(headers: headers(value.accountToken)),
    );
    return (response.data?['users'] as List<dynamic>? ?? const <dynamic>[])
        .map((raw) => PlexHomeUser.fromJson(raw as Map<String, dynamic>))
        .where((user) => user.uuid.isNotEmpty)
        .toList();
  }

  Future<String> switchHomeUser(PlexHomeUser user, {String? pin}) async {
    final value = _requireSession();
    final response = await _accountDio.post<Map<String, dynamic>>(
      'https://clients.plex.tv/api/v2/home/users/${user.uuid}/switch',
      queryParameters: <String, dynamic>{
        'includeSubscriptions': 1,
        'includeProviders': 1,
        'includeSettings': 1,
        'includeSharedSettings': 1,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
      },
      options: Options(headers: headers(value.accountToken)),
    );
    final token = response.data?['authToken']?.toString() ?? '';
    if (token.isEmpty) throw StateError('Plex returned no profile token.');
    return token;
  }

  Future<PlexPin> createPin() async {
    logs.add('Requesting a Plex sign-in PIN.');
    final response = await _accountDio.post<Map<String, dynamic>>(
      'https://plex.tv/api/v2/pins',
      queryParameters: const <String, dynamic>{'strong': true},
      options: Options(headers: headers()),
    );
    final data = response.data!;
    return PlexPin(
        id: (data['id'] as num).toInt(), code: data['code'] as String);
  }

  Future<String?> checkPin(PlexPin pin) async {
    final response = await _accountDio.get<Map<String, dynamic>>(
      'https://plex.tv/api/v2/pins/${pin.id}',
      options: Options(headers: headers()),
    );
    return response.data?['authToken'] as String?;
  }

  Future<List<PlexServerResource>> fetchServers(String accountToken) async {
    logs.add('Loading Plex Media Server resources.');
    final response = await _accountDio.get<List<dynamic>>(
      'https://clients.plex.tv/api/v2/resources',
      queryParameters: const <String, dynamic>{
        'includeHttps': 1,
        'includeRelay': 1,
        'includeIPv6': 0,
      },
      options: Options(headers: headers(accountToken)),
    );
    final servers = <PlexServerResource>[];
    for (final raw in response.data ?? const <dynamic>[]) {
      final map = raw as Map<String, dynamic>;
      if (!(map['provides']?.toString().split(',').contains('server') ?? false))
        continue;
      final connections = <PlexConnection>[];
      for (final value
          in (map['connections'] as List<dynamic>? ?? const <dynamic>[])) {
        final connection = value as Map<String, dynamic>;
        final uri = connection['uri']?.toString() ?? '';
        if (!uri.toLowerCase().startsWith('https://')) continue;
        connections.add(PlexConnection(
          uri: uri.replaceAll(RegExp(r'/+$'), ''),
          local: connection['local'] == true,
          relay: connection['relay'] == true,
        ));
      }
      final token = map['accessToken']?.toString() ?? '';
      final id = map['clientIdentifier']?.toString() ?? '';
      if (token.isNotEmpty && id.isNotEmpty && connections.isNotEmpty) {
        servers.add(PlexServerResource(
          name: map['name']?.toString() ?? 'Plex Server',
          id: id,
          token: token,
          connections: connections,
        ));
      }
    }
    return servers;
  }

  Future<PlexSession> connect(
      String accountToken, PlexServerResource server) async {
    final candidates = List<PlexConnection>.from(server.connections)
      ..sort((a, b) {
        final aScore = (a.local ? 0 : 2) + (a.relay ? 2 : 0);
        final bScore = (b.local ? 0 : 2) + (b.relay ? 2 : 0);
        return aScore.compareTo(bScore);
      });
    Object? lastError;
    for (final candidate in candidates) {
      try {
        logs.add('Testing secure endpoint ${_safeHost(candidate.uri)}.');
        final response = await _serverDio.get<Map<String, dynamic>>(
          '${candidate.uri}/identity',
          options: Options(
            headers: headers(server.token),
            receiveTimeout: const Duration(seconds: 7),
          ),
        );
        final identity = _container(response.data);
        final returnedId = identity['machineIdentifier']?.toString() ??
            response.data?['machineIdentifier']?.toString() ??
            '';
        if (response.statusCode == 200 && returnedId == server.id) {
          // /identity can be public. Verify the profile-specific resource token
          // against a protected endpoint before persisting this route.
          await _serverDio.get<Map<String, dynamic>>(
            '${candidate.uri}/library/sections',
            options: Options(
              headers: headers(server.token),
              receiveTimeout: const Duration(seconds: 7),
            ),
          );
          final connected = PlexSession(
            accountToken: accountToken,
            serverToken: server.token,
            serverName: server.name,
            serverId: server.id,
            baseUrl: candidate.uri,
          );
          await _saveSession(connected);
          session = connected;
          logs.add('Connected securely to ${server.name}.');
          return connected;
        } else if (returnedId.isNotEmpty && returnedId != server.id) {
          logs.add('Rejected endpoint with a different server identity.');
        }
      } catch (error) {
        lastError = error;
        logs.add('Endpoint ${_safeHost(candidate.uri)} did not respond.');
      }
    }
    throw StateError(
        'No secure endpoint reached ${server.name}: ${_briefError(lastError)}');
  }

  Future<void> _saveSession(PlexSession value) async {
    for (final entry in value.toStorage().entries) {
      await _prefs.setString('gkui.${entry.key}', entry.value);
    }
  }

  Future<void> signOut() async {
    for (final key in <String>[
      'accountToken',
      'serverToken',
      'serverName',
      'serverId',
      'baseUrl',
      'currentHomeUserUuid',
      'currentHomeUserName',
      'cache.home',
      'cache.sections',
      'cache.library'
    ]) {
      await _prefs.remove('gkui.$key');
    }
    session = null;
    _markerCache.clear();
    logs.add('Signed out; stored Plex tokens removed.');
  }

  Future<void> clearContentCache() async {
    await Future.wait(<Future<bool>>[
      _prefs.remove('gkui.cache.home'),
      _prefs.remove('gkui.cache.sections'),
      _prefs.remove('gkui.cache.library'),
    ]);
    _markerCache.clear();
  }

  Future<List<PlexShelf>> loadHome() async {
    final value = _requireSession();
    final responses = await Future.wait<Response<Map<String, dynamic>>?>([
      _serverDio.get<Map<String, dynamic>>(
        '${value.baseUrl}/hubs',
        queryParameters: const <String, dynamic>{
          'count': 12,
          'includeGuids': 1,
          'includeMeta': 1,
        },
        options: Options(headers: headers(value.serverToken)),
      ),
      _serverDio
          .get<Map<String, dynamic>>(
            '${value.baseUrl}/library/onDeck',
            queryParameters: const <String, dynamic>{
              'X-Plex-Container-Size': 20,
              'includeGuids': 1,
            },
            options: Options(headers: headers(value.serverToken)),
          )
          .then<Response<Map<String, dynamic>>?>((value) => value)
          .catchError((Object _) => null),
    ]);
    final cache = <String, dynamic>{
      'hubs': responses[0]?.data,
      'onDeck': responses[1]?.data,
    };
    await _prefs.setString('gkui.cache.home', jsonEncode(cache));
    final shelves = _parseHome(cache);
    logs.add('Loaded ${shelves.length} home shelves.');
    return shelves;
  }

  List<PlexShelf> loadCachedHome() {
    final raw = _prefs.getString('gkui.cache.home');
    if (raw == null) return const <PlexShelf>[];
    try {
      return _parseHome(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const <PlexShelf>[];
    }
  }

  List<PlexShelf> _parseHome(Map<String, dynamic> cache) {
    final container = _container(cache['hubs'] as Map<String, dynamic>?);
    final shelves = <PlexShelf>[];
    for (final raw
        in (container['Hub'] as List<dynamic>? ?? const <dynamic>[])) {
      final hub = raw as Map<String, dynamic>;
      final items = _parseItems(hub['Metadata']);
      if (items.isNotEmpty) {
        shelves.add(
            PlexShelf(title: hub['title']?.toString() ?? 'Plex', items: items));
      }
    }
    final onDeck = _parseItems(
        _container(cache['onDeck'] as Map<String, dynamic>?)['Metadata']);
    if (onDeck.isNotEmpty) {
      shelves.removeWhere((shelf) {
        final title = shelf.title.toLowerCase();
        return title.contains('continue') || title.contains('on deck');
      });
      shelves.insert(0, PlexShelf(title: 'Continue Watching', items: onDeck));
    }
    return shelves;
  }

  Future<List<PlexSection>> loadSections() async {
    final value = _requireSession();
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}/library/sections',
      options: Options(headers: headers(value.serverToken)),
    );
    await _prefs.setString('gkui.cache.sections', jsonEncode(response.data));
    return _parseSections(response.data);
  }

  List<PlexSection> loadCachedSections() {
    final raw = _prefs.getString('gkui.cache.sections');
    if (raw == null) return const <PlexSection>[];
    try {
      return _parseSections(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const <PlexSection>[];
    }
  }

  List<PlexSection> _parseSections(Map<String, dynamic>? data) {
    final container = _container(data);
    return (container['Directory'] as List<dynamic>? ?? const <dynamic>[])
        .map((raw) => raw as Map<String, dynamic>)
        .where((map) => map['key'] != null)
        .map((map) => PlexSection(
              key: map['key'].toString(),
              title: map['title']?.toString() ?? 'Library',
              type: map['type']?.toString() ?? '',
            ))
        .toList();
  }

  Future<PlexPage> loadSectionPage(String sectionKey,
      {int start = 0, int size = 60, bool unwatchedOnly = false}) async {
    final value = _requireSession();
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}/library/sections/$sectionKey/all',
      queryParameters: <String, dynamic>{
        'X-Plex-Container-Start': start,
        'X-Plex-Container-Size': size,
        'includeGuids': 1,
        if (unwatchedOnly) 'unwatched': 1,
      },
      options: Options(headers: headers(value.serverToken)),
    );
    if (start == 0 && !unwatchedOnly) {
      await _prefs.setString(
          'gkui.cache.library',
          jsonEncode(<String, dynamic>{
            'sectionKey': sectionKey,
            'data': response.data,
          }));
    }
    final container = _container(response.data);
    final items = _parseItems(container['Metadata']);
    final total = (container['totalSize'] as num?)?.toInt() ??
        (container['size'] as num?)?.toInt() ??
        (start + items.length);
    return PlexPage(items: items, start: start, total: total);
  }

  Future<List<PlexMedia>> loadSection(String sectionKey,
      {int start = 0, bool unwatchedOnly = false}) async {
    final page = await loadSectionPage(sectionKey,
        start: start, unwatchedOnly: unwatchedOnly);
    return page.items;
  }

  List<PlexMedia> loadCachedSection(String sectionKey) {
    final raw = _prefs.getString('gkui.cache.library');
    if (raw == null) return const <PlexMedia>[];
    try {
      final cache = jsonDecode(raw) as Map<String, dynamic>;
      if (cache['sectionKey']?.toString() != sectionKey) {
        return const <PlexMedia>[];
      }
      return _parseItems(
          _container(cache['data'] as Map<String, dynamic>?)['Metadata']);
    } catch (_) {
      return const <PlexMedia>[];
    }
  }

  Future<List<PlexMedia>> loadChildren(PlexMedia item) async {
    final value = _requireSession();
    final path = item.key.endsWith('/children')
        ? item.key
        : item.type == 'collection'
            ? '/library/collections/${item.ratingKey}/children'
            : '/library/metadata/${item.ratingKey}/children';
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}$path',
      options: Options(headers: headers(value.serverToken)),
    );
    final container = _container(response.data);
    return _parseItems(container['Metadata'] ?? container['Directory']);
  }

  Future<PlexMedia> loadMetadata(String ratingKey) async {
    final value = _requireSession();
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}/library/metadata/$ratingKey',
      queryParameters: const <String, dynamic>{'includeGuids': 1},
      options: Options(headers: headers(value.serverToken)),
    );
    final items = _parseItems(_container(response.data)['Metadata']);
    if (items.isEmpty)
      throw StateError('Plex returned no metadata for this title.');
    return items.first;
  }

  Future<List<PlexMedia>> search(String query,
      {int limit = 60,
      SearchMediaFilter filter = SearchMediaFilter.all}) async {
    final value = _requireSession();
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}/hubs/search',
      queryParameters: <String, dynamic>{
        'query': query,
        'limit': limit,
        'includeCollections': 1,
      },
      options: Options(headers: headers(value.serverToken)),
    );
    final results = <PlexMedia>[];
    for (final raw in (_container(response.data)['Hub'] as List<dynamic>? ??
        const <dynamic>[])) {
      final hub = raw as Map<String, dynamic>;
      results.addAll(_parseItems(hub['Metadata'] ?? hub['Directory']));
    }
    final seen = <String>{};
    final normalized = query.trim().toLowerCase();
    final filtered = results
        .where((item) => item.ratingKey.isNotEmpty && seen.add(item.ratingKey))
        .where((item) =>
            filter == SearchMediaFilter.all || item.type == filter.name)
        .toList();
    int score(PlexMedia item) {
      final title = item.title.toLowerCase();
      if (title == normalized) return 400;
      if (title.startsWith(normalized)) return 300;
      final words = title.split(RegExp(r'\s+'));
      if (words.any((word) => word.startsWith(normalized))) return 200;
      if (title.contains(normalized)) return 100;
      return 0;
    }

    filtered.sort((a, b) {
      final byScore = score(b).compareTo(score(a));
      return byScore != 0
          ? byScore
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return filtered;
  }

  Future<List<PlexMedia>> loadCollections(String sectionKey) async {
    final value = _requireSession();
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}/library/sections/$sectionKey/collections',
      options: Options(headers: headers(value.serverToken)),
    );
    return _parseItems(_container(response.data)['Metadata']);
  }

  Future<List<PlexMarker>> loadMarkers(String ratingKey) async {
    final cached = _markerCache[ratingKey];
    if (cached != null) return cached;
    final value = _requireSession();
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}/library/metadata/$ratingKey',
      queryParameters: const <String, dynamic>{'includeMarkers': 1},
      options: Options(headers: headers(value.serverToken)),
    );
    final metadata = (_container(response.data)['Metadata'] as List<dynamic>?)
        ?.firstOrNull as Map<String, dynamic>?;
    final markers = (metadata?['Marker'] as List<dynamic>? ?? const <dynamic>[])
        .map((raw) => raw as Map<String, dynamic>)
        .where((map) =>
            map['startTimeOffset'] != null && map['endTimeOffset'] != null)
        .map((map) => PlexMarker(
              type: map['type']?.toString() ?? 'marker',
              startMs: (map['startTimeOffset'] as num).toInt(),
              endMs: (map['endTimeOffset'] as num).toInt(),
            ))
        .toList();
    _markerCache[ratingKey] = markers;
    return markers;
  }

  List<PlexMarker> cachedMarkers(String ratingKey) =>
      _markerCache[ratingKey] ?? const <PlexMarker>[];

  Future<PlexMedia?> loadNextEpisode(PlexMedia current) async {
    if (current.type != 'episode' || current.grandparentRatingKey == null) {
      return null;
    }
    final value = _requireSession();
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}/library/metadata/${current.grandparentRatingKey}/allLeaves',
      options: Options(headers: headers(value.serverToken)),
    );
    final episodes = _parseItems(_container(response.data)['Metadata'])
      ..sort((a, b) {
        final season = (a.parentIndex ?? 0).compareTo(b.parentIndex ?? 0);
        return season != 0 ? season : (a.index ?? 0).compareTo(b.index ?? 0);
      });
    final currentIndex =
        episodes.indexWhere((item) => item.ratingKey == current.ratingKey);
    return currentIndex >= 0 && currentIndex + 1 < episodes.length
        ? episodes[currentIndex + 1]
        : null;
  }

  List<PlexMedia> _parseItems(dynamic rawList) {
    final items = <PlexMedia>[];
    for (final raw in (rawList as List<dynamic>? ?? const <dynamic>[])) {
      final map = raw as Map<String, dynamic>;
      final media = map['Media'] as List<dynamic>?;
      final versions = <PlexMediaVersion>[];
      for (var mediaIndex = 0;
          mediaIndex < (media?.length ?? 0);
          mediaIndex++) {
        final mediaMap = media![mediaIndex] as Map<String, dynamic>;
        final parts = mediaMap['Part'] as List<dynamic>?;
        final part = parts == null || parts.isEmpty
            ? null
            : parts.first as Map<String, dynamic>;
        final partKey = part?['key']?.toString() ?? '';
        if (partKey.isEmpty) continue;
        final streams = part?['Stream'] as List<dynamic>? ?? const <dynamic>[];
        PlexTrack parseTrack(Map<String, dynamic> stream, String type) =>
            PlexTrack(
              id: stream['id']?.toString() ?? '',
              type: type,
              languageCode: stream['languageCode']?.toString(),
              language: stream['language']?.toString(),
              title: stream['title']?.toString() ??
                  stream['displayTitle']?.toString(),
              codec: stream['codec']?.toString(),
              channels: (stream['channels'] as num?)?.toInt(),
              selected: stream['selected'] == true || stream['selected'] == 1,
              forced: stream['forced'] == true || stream['forced'] == 1,
            );
        final audioTracks = streams
            .map((raw) => raw as Map<String, dynamic>)
            .where((stream) => (stream['streamType'] as num?)?.toInt() == 2)
            .map((stream) => parseTrack(stream, 'audio'))
            .where((track) => track.id.isNotEmpty)
            .toList();
        final subtitleTracks = streams
            .map((raw) => raw as Map<String, dynamic>)
            .where((stream) => (stream['streamType'] as num?)?.toInt() == 3)
            .map((stream) => parseTrack(stream, 'subtitle'))
            .where((track) => track.id.isNotEmpty)
            .toList();
        versions.add(PlexMediaVersion(
          index: mediaIndex,
          partKey: partKey,
          partId: part?['id']?.toString(),
          resolution: mediaMap['videoResolution']?.toString(),
          codec: mediaMap['videoCodec']?.toString(),
          container: mediaMap['container']?.toString(),
          bitrateKbps: (mediaMap['bitrate'] as num?)?.toInt(),
          width: (mediaMap['width'] as num?)?.toInt(),
          height: (mediaMap['height'] as num?)?.toInt(),
          sizeBytes: (part?['size'] as num?)?.toInt(),
          audioTracks: audioTracks,
          subtitleTracks: subtitleTracks,
        ));
      }
      final type = map['type']?.toString() ?? '';
      items.add(PlexMedia(
        ratingKey: map['ratingKey']?.toString() ?? '',
        key: map['key']?.toString() ?? '',
        type: type,
        title: map['title']?.toString() ?? 'Untitled',
        subtitle: map['grandparentTitle']?.toString() ??
            map['parentTitle']?.toString(),
        summary: map['summary']?.toString(),
        thumb: map['thumb']?.toString(),
        art: map['art']?.toString(),
        durationMs: (map['duration'] as num?)?.toInt() ?? 0,
        viewOffsetMs: (map['viewOffset'] as num?)?.toInt() ?? 0,
        year: (map['year'] as num?)?.toInt(),
        children: type == 'show' ||
            type == 'season' ||
            type == 'album' ||
            type == 'collection',
        directPartKey: versions.isEmpty ? null : versions.first.partKey,
        parentRatingKey: map['parentRatingKey']?.toString(),
        grandparentRatingKey: map['grandparentRatingKey']?.toString(),
        index: (map['index'] as num?)?.toInt(),
        parentIndex: (map['parentIndex'] as num?)?.toInt(),
        viewCount: (map['viewCount'] as num?)?.toInt() ?? 0,
        versions: versions,
      ));
    }
    return items;
  }

  String? imageUrl(String? path, {int width = 300, int height = 450}) {
    final value = session;
    if (value == null || path == null || path.isEmpty) return null;
    final uri = Uri.parse('${value.baseUrl}/photo/:/transcode')
        .replace(queryParameters: <String, String>{
      'url': path,
      'width': '$width',
      'height': '$height',
      'minSize': '1',
      'upscale': '1',
    });
    return uri.toString();
  }

  Map<String, String> get imageHeaders {
    final value = _requireSession();
    return headers(value.serverToken);
  }

  PlaybackRequest playback(PlexMedia item,
      {required bool transcode,
      int bitrate = 3000,
      int mediaIndex = 0,
      String? audioTrackId,
      String? subtitleTrackId}) {
    final value = _requireSession();
    final sessionId = const Uuid().v4();
    final selected = item.versions
        .where((version) => version.index == mediaIndex)
        .firstOrNull;
    final directPartKey = selected?.partKey ?? item.directPartKey;
    if (!transcode && directPartKey != null) {
      return PlaybackRequest(
        url: '${value.baseUrl}$directPartKey',
        headers: <String, String>{
          ...headers(value.serverToken),
          'X-Plex-Session-Identifier': sessionId,
        },
        sessionId: sessionId,
        transcoding: false,
      );
    }
    final resolution = bitrate <= 1500 ? '720x480' : '1280x720';
    // Declare one compatible target instead of allowing remux of the source codec.
    final profile = <String>[
      'add-transcode-target(type=videoProfile&context=streaming'
          '&protocol=hls&container=mpegts&videoCodec=h264&audioCodec=aac)',
      'add-limitation(scope=videoCodec&scopeName=*&type=upperBound'
          '&name=video.bitrate&value=$bitrate&replace=true)',
      'add-limitation(scope=audioCodec&scopeName=*&type=upperBound'
          '&name=audio.channels&value=2&replace=true)',
    ].join('+');
    final uri =
        Uri.parse('${value.baseUrl}/video/:/transcode/universal/start.m3u8')
            .replace(
      queryParameters: <String, String>{
        'path': '/library/metadata/${item.ratingKey}',
        'mediaIndex': '$mediaIndex',
        'partIndex': '0',
        'protocol': 'hls',
        'hasMDE': '1',
        'directPlay': '0',
        'directStream': '0',
        'directStreamAudio': '0',
        'maxAudioChannels': '2',
        'X-Plex-Platform': 'Generic',
        'X-Plex-Client-Profile-Extra': profile,
        'videoQuality': bitrate <= 1500 ? '40' : '60',
        'videoResolution': resolution,
        'maxVideoBitrate': '$bitrate',
        'audioBoost': '100',
        'fastSeek': '1',
        'copyts': '1',
        'session': sessionId,
        'X-Plex-Session-Identifier': sessionId,
        'X-Plex-Client-Identifier': clientIdentifier,
        if (audioTrackId != null && audioTrackId.isNotEmpty)
          'audioStreamID': audioTrackId,
        if (subtitleTrackId != null && subtitleTrackId.isNotEmpty)
          'subtitleStreamID': subtitleTrackId,
      },
    );
    return PlaybackRequest(
      url: uri.toString(),
      headers: <String, String>{
        ...headers(value.serverToken),
        'X-Plex-Platform': 'Generic',
        'X-Plex-Session-Identifier': sessionId,
      },
      sessionId: sessionId,
      transcoding: true,
    );
  }

  Future<void> reportProgress(PlexMedia item, int positionMs, String state,
      {String? sessionId}) async {
    final value = _requireSession();
    try {
      await _serverDio.get<dynamic>(
        '${value.baseUrl}/:/timeline',
        queryParameters: <String, dynamic>{
          'ratingKey': item.ratingKey,
          'key': '/library/metadata/${item.ratingKey}',
          'state': state,
          'time': positionMs,
          'duration': item.durationMs,
        },
        options: Options(headers: <String, String>{
          ...headers(value.serverToken),
          if (sessionId != null) 'X-Plex-Session-Identifier': sessionId,
        }),
      );
    } catch (error) {
      logs.add('Progress update failed: ${_briefError(error)}');
    }
  }

  Future<void> stopPlaybackSession(PlaybackRequest request) async {
    if (!request.transcoding) return;
    final value = _requireSession();
    try {
      await _serverDio.get<dynamic>(
        '${value.baseUrl}/video/:/transcode/universal/stop',
        queryParameters: <String, dynamic>{'session': request.sessionId},
        options: Options(headers: <String, String>{
          ...headers(value.serverToken),
          'X-Plex-Session-Identifier': request.sessionId,
        }),
      );
    } catch (error) {
      logs.add('Transcode cleanup failed: ${_briefError(error)}');
    }
  }

  PlexSession _requireSession() {
    final value = session;
    if (value == null) throw StateError('Not signed in to Plex.');
    return value;
  }

  static Map<String, dynamic> _container(Map<String, dynamic>? data) {
    return data?['MediaContainer'] as Map<String, dynamic>? ??
        <String, dynamic>{};
  }

  static String _safeHost(String url) => Uri.tryParse(url)?.host ?? 'endpoint';

  static String _briefError(Object? error) {
    if (error is DioException) {
      if (error.response?.statusCode != null)
        return 'HTTP ${error.response!.statusCode}';
      return error.type.name;
    }
    return error?.runtimeType.toString() ?? 'unknown error';
  }
}

class _LegacyTrustOverrides extends HttpOverrides {
  _LegacyTrustOverrides(this.context);
  final SecurityContext context;

  @override
  HttpClient createHttpClient(SecurityContext? securityContext) =>
      super.createHttpClient(context);
}
