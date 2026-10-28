import '../models/livetv_channel.dart';
import '../models/livetv_program.dart';

/// Profile-owned IPTV inputs. Tunerr and Dispatcharr can be used through
/// standard feeds; Stalker/Ministra uses its optional MAG portal adapter.
enum IptvInputKind { m3u, xtream, tunerr, dispatcharr, stalker }
enum IptvVodKind { movie, series }

extension IptvInputKindVodSupport on IptvInputKind {
  bool get supportsXtreamVod => this == IptvInputKind.xtream || this == IptvInputKind.dispatcharr;
}

String iptvFavoriteSource(String sourceId) => 'iptv:$sourceId';

class IptvSourceConfiguration {
  const IptvSourceConfiguration({
    required this.id,
    required this.profileId,
    required this.displayName,
    required this.kind,
    required this.endpoint,
    this.guideEndpoint = '',
    this.additionalGuideEndpoints = const [],
    this.username = '',
    this.password = '',
    this.macAddress = '',
    this.dispatcharrApiEndpoint = '',
    this.dispatcharrApiKey = '',
    this.localTimeShiftEnabled = true,
    this.allowHttp = false,
  });

  final String id;
  final String profileId;
  final String displayName;
  final IptvInputKind kind;
  final String endpoint;
  final String guideEndpoint;
  final List<String> additionalGuideEndpoints;
  final String username;
  final String password;
  final String macAddress;
  final String dispatcharrApiEndpoint;
  final String dispatcharrApiKey;
  final bool localTimeShiftEnabled;
  final bool allowHttp;

  Map<String, Object?> toJson() => {
    'id': id,
    'profileId': profileId,
    'displayName': displayName,
    'kind': kind.name,
    'endpoint': endpoint,
    'guideEndpoint': guideEndpoint,
    'additionalGuideEndpoints': additionalGuideEndpoints,
    'username': username,
    'password': password,
    'macAddress': macAddress,
    'dispatcharrApiEndpoint': dispatcharrApiEndpoint,
    'dispatcharrApiKey': dispatcharrApiKey,
    'localTimeShiftEnabled': localTimeShiftEnabled,
    'allowHttp': allowHttp,
  };

  factory IptvSourceConfiguration.fromJson(Map<String, dynamic> json) => IptvSourceConfiguration(
    id: json['id'] as String,
    profileId: json['profileId'] as String,
    displayName: json['displayName'] as String,
    kind: IptvInputKind.values.byName(json['kind'] as String),
    endpoint: json['endpoint'] as String,
    guideEndpoint: json['guideEndpoint'] as String? ?? '',
    additionalGuideEndpoints: (json['additionalGuideEndpoints'] as List<dynamic>?)?.whereType<String>().toList() ?? const [],
    username: json['username'] as String? ?? '',
    password: json['password'] as String? ?? '',
    macAddress: json['macAddress'] as String? ?? '',
    dispatcharrApiEndpoint: json['dispatcharrApiEndpoint'] as String? ?? '',
    dispatcharrApiKey: json['dispatcharrApiKey'] as String? ?? '',
    localTimeShiftEnabled: json['localTimeShiftEnabled'] as bool? ?? true,
    allowHttp: json['allowHttp'] as bool? ?? false,
  );

  Uri playlistUri() {
    final endpointUri = Uri.parse(endpoint);
    if (kind != IptvInputKind.xtream &&
        !(kind == IptvInputKind.dispatcharr && username.isNotEmpty && password.isNotEmpty && !_isXtreamEndpointFile(endpointUri))) {
      return endpointUri;
    }
    final base = xtreamBaseUri;
    return base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/+$'), '')}/get.php',
      queryParameters: {
        ...base.queryParameters,
        'username': username,
        'password': password,
        'type': 'm3u_plus',
        'output': 'mpegts',
      },
    );
  }

  Uri? guideUri() {
    final supplied = guideEndpoint.trim();
    if (supplied.isNotEmpty) return Uri.parse(supplied);
    if (!supportsXtreamCatalog) return null;
    final base = xtreamBaseUri;
    return base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/+$'), '')}/xmltv.php',
      queryParameters: {
        ...base.queryParameters,
        'username': username,
        'password': password,
      },
    );
  }

  bool get supportsXtreamCatalog =>
      kind == IptvInputKind.xtream || (kind == IptvInputKind.dispatcharr && username.isNotEmpty && password.isNotEmpty);

  bool get supportsStalkerPortal => kind == IptvInputKind.stalker && macAddress.isNotEmpty;

  bool get supportsDispatcharrDvr =>
      kind == IptvInputKind.dispatcharr &&
      dispatcharrApiEndpoint.trim().isNotEmpty &&
      dispatcharrApiKey.trim().isNotEmpty;

  Uri get xtreamBaseUri {
    final uri = Uri.parse(endpoint);
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    final leaf = path.split('/').last.toLowerCase();
    final normalizedPath = _isXtreamEndpointFile(uri) ? path.substring(0, path.length - leaf.length) : uri.path;
    return uri.replace(path: normalizedPath.replaceFirst(RegExp(r'/+$'), ''), query: null, fragment: null);
  }

  Uri playerApiUri(String action, {Map<String, String> parameters = const {}}) {
    if (!supportsXtreamCatalog) throw StateError('This IPTV source has no Xtream catalogue endpoint');
    final base = xtreamBaseUri;
    return base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/+$'), '')}/player_api.php',
      queryParameters: {
        'username': username,
        'password': password,
        'action': action,
        ...parameters,
      },
    );
  }

  Uri vodStreamUri({required String itemId, required String extension, required bool series}) {
    if (!supportsXtreamCatalog) throw StateError('This IPTV source has no Xtream catalogue endpoint');
    final base = xtreamBaseUri;
    final path = <String>[
      ...base.pathSegments.where((part) => part.isNotEmpty),
      series ? 'series' : 'movie',
      username,
      password,
      '$itemId.${_safeContainerExtension(extension)}',
    ];
    return base.replace(pathSegments: path, query: null, fragment: null);
  }
}

bool _isXtreamEndpointFile(Uri uri) {
  final segments = uri.pathSegments;
  return segments.isNotEmpty && const {'get.php', 'xmltv.php', 'player_api.php'}.contains(segments.last.toLowerCase());
}

String _safeContainerExtension(String value) {
  final normalized = value.trim().toLowerCase().replaceFirst(RegExp(r'^\.'), '');
  if (!RegExp(r'^[a-z0-9]{1,8}$').hasMatch(normalized)) return 'mp4';
  return normalized;
}

class IptvSourceSummary {
  const IptvSourceSummary({
    required this.id,
    required this.profileId,
    required this.displayName,
    required this.kind,
    required this.generation,
    required this.channelCount,
    required this.programmeCount,
    this.lastSuccessAt,
    this.lastErrorCode,
  });

  final String id;
  final String profileId;
  final String displayName;
  final IptvInputKind kind;
  final int generation;
  final int channelCount;
  final int programmeCount;
  final DateTime? lastSuccessAt;
  final String? lastErrorCode;
}

class IptvEditableChannel {
  const IptvEditableChannel({
    required this.id,
    required this.title,
    required this.hidden,
    this.number,
    this.groupTitle,
    this.customTitle,
    this.groupOverride,
    this.tvgId,
    this.guideIdOverride,
    this.logoUrl,
    this.parentalLocked = false,
  });

  final String id;
  final String title;
  final String? number;
  final String? groupTitle;
  final String? customTitle;
  final String? groupOverride;
  final String? tvgId;
  final String? guideIdOverride;
  final String? logoUrl;
  final bool hidden;
  final bool parentalLocked;

  String get displayTitle => customTitle?.trim().isNotEmpty == true ? customTitle!.trim() : title;
  String? get displayGroup => groupOverride?.trim().isNotEmpty == true ? groupOverride!.trim() : groupTitle;
}

class IptvChannelSnapshot {
  const IptvChannelSnapshot({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.favorite,
    required this.favoriteOrder,
    this.tvgId,
    this.number,
    this.groupTitle,
    this.logoUrl,
    this.radio = false,
    this.hasCatchup = false,
    this.catchupDays,
    this.parentalLocked = false,
  });

  final String id;
  final String sourceId;
  final String title;
  final String? tvgId;
  final String? number;
  final String? groupTitle;
  final String? logoUrl;
  final bool radio;
  final bool hasCatchup;
  final int? catchupDays;
  final bool favorite;
  final int favoriteOrder;
  final bool parentalLocked;

  LiveTvChannel toLiveTvChannel(String sourceName) => LiveTvChannel(
    key: '$sourceId:$id',
    identifier: tvgId,
    title: title,
    callSign: title,
    number: number,
    thumb: logoUrl,
    lineup: sourceId,
    liveTvSourceTitle: sourceName,
    favoriteSource: iptvFavoriteSource(sourceId),
    iptvSourceId: sourceId,
    iptvChannelId: id,
    iptvRadio: radio,
    iptvGroupTitle: groupTitle,
    iptvFavorite: favorite,
    iptvCatchupAvailable: hasCatchup,
    iptvCatchupDays: catchupDays,
    iptvParentalLocked: parentalLocked,
  );
}

class IptvProgrammeSnapshot {
  const IptvProgrammeSnapshot({
    required this.channelId,
    required this.beginsAt,
    required this.endsAt,
    required this.title,
    this.summary,
    this.category,
    this.episodeId,
    this.thumb,
  });

  final String channelId;
  final int beginsAt;
  final int endsAt;
  final String title;
  final String? summary;
  final String? category;
  final String? episodeId;
  final String? thumb;

  LiveTvProgram toLiveTvProgram(String sourceId) => LiveTvProgram(
    key: '$sourceId:$channelId:$beginsAt',
    guid: episodeId,
    title: title,
    summary: summary,
    type: category,
    thumb: thumb,
    beginsAt: beginsAt,
    endsAt: endsAt,
    channelIdentifier: '$sourceId:$channelId',
    providerIdentifier: sourceId,
  );
}

class IptvVodCategory {
  const IptvVodCategory({required this.id, required this.name, required this.kind});

  final String id;
  final String name;
  final IptvVodKind kind;
}

class IptvVodItem {
  const IptvVodItem({
    required this.id,
    required this.sourceId,
    required this.kind,
    required this.title,
    this.categoryId,
    this.plot,
    this.year,
    this.durationSeconds,
    this.rating,
    this.posterUrl,
    this.backdropUrl,
    this.containerExtension = 'mp4',
  });

  final String id;
  final String sourceId;
  final IptvVodKind kind;
  final String title;
  final String? categoryId;
  final String? plot;
  final int? year;
  final int? durationSeconds;
  final double? rating;
  final String? posterUrl;
  final String? backdropUrl;
  final String containerExtension;
}

class IptvVodEpisode {
  const IptvVodEpisode({
    required this.id,
    required this.title,
    required this.season,
    required this.episode,
    this.plot,
    this.durationSeconds,
    this.posterUrl,
    this.containerExtension = 'mp4',
  });

  final String id;
  final String title;
  final int season;
  final int episode;
  final String? plot;
  final int? durationSeconds;
  final String? posterUrl;
  final String containerExtension;
}

class IptvVodProgress {
  const IptvVodProgress({
    required this.sourceId,
    required this.kind,
    required this.itemId,
    required this.episodeId,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
    required this.finished,
  });

  final String sourceId;
  final IptvVodKind kind;
  final String itemId;
  final String episodeId;
  final int positionMs;
  final int durationMs;
  final int updatedAt;
  final bool finished;

  double get fraction => durationMs <= 0 ? 0 : (positionMs / durationMs).clamp(0.0, 1.0).toDouble();
}

class IptvVodSeriesDetails {
  const IptvVodSeriesDetails({required this.series, required this.episodes});

  final IptvVodItem series;
  final List<IptvVodEpisode> episodes;
}

class IptvLocalRecording {
  const IptvLocalRecording({
    required this.id,
    required this.profileId,
    required this.title,
    required this.filePath,
    required this.startedAt,
    required this.state,
    this.sourceId,
    this.channelId,
    this.programmeTitle,
    this.completedAt,
    this.durationSeconds,
    this.sizeBytes,
    this.errorCode,
  });

  final String id;
  final String profileId;
  final String? sourceId;
  final String? channelId;
  final String title;
  final String? programmeTitle;
  final String filePath;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationSeconds;
  final int? sizeBytes;
  final String state;
  final String? errorCode;

  bool get isRecording => state == 'recording';
}

class IptvLocalRecordingSchedule {
  const IptvLocalRecordingSchedule({
    required this.id,
    required this.profileId,
    required this.sourceId,
    required this.channelId,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.programmeTitle,
    this.recordingId,
    this.errorCode,
  });

  final String id;
  final String profileId;
  final String sourceId;
  final String channelId;
  final String title;
  final String? programmeTitle;
  final DateTime startsAt;
  final DateTime endsAt;
  final String state;
  final String? recordingId;
  final String? errorCode;
  final DateTime createdAt;
  final DateTime updatedAt;
}
