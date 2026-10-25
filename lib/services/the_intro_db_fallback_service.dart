import 'dart:convert';

import 'package:http/http.dart' as http;

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../media/media_source_info.dart';
import '../utils/external_ids.dart';

/// Reads community intro timings only as a user-enabled fallback when the
/// server has no intro marker. No server credentials or item titles are sent.
class TheIntroDbFallbackService {
  static final Uri _baseUri = Uri.https('api.theintrodb.org', '/v4/media');

  Future<List<MediaMarker>> fetchIntroMarkers(MediaItem item, MediaServerClient client) async {
    if (item.kind != MediaKind.movie && item.kind != MediaKind.episode) return const [];

    var ids = _externalIds(item);
    if (item.kind == MediaKind.episode) {
      final season = item.parentIndex;
      final episode = item.index;
      if (season == null || episode == null) return const [];
      final seriesId = item.grandparentId;
      if (seriesId != null && seriesId.isNotEmpty) {
        final series = await client.fetchItem(seriesId);
        if (series != null) ids = _externalIds(series).fillFrom(ids);
      }
      if (!ids.hasCatalogIds) return const [];
      return _fetch(ids, durationMs: item.durationMs, season: season, episode: episode);
    }

    if (!ids.hasCatalogIds) return const [];
    return _fetch(ids, durationMs: item.durationMs);
  }

  Future<List<MediaMarker>> _fetch(ExternalIds ids, {required int? durationMs, int? season, int? episode}) async {
    final query = <String, String>{
      if (ids.tmdb != null) 'tmdb_id': '${ids.tmdb}',
      if (ids.tmdb == null && ids.tvdb != null) 'tvdb_id': '${ids.tvdb}',
      if (ids.tmdb == null && ids.tvdb == null && ids.imdb != null) 'imdb_id': ids.imdb!,
      if (durationMs != null && durationMs > 0) 'duration_ms': '$durationMs',
      if (season != null) 'season': '$season',
      if (episode != null) 'episode': '$episode',
    };
    if (!query.containsKey('tmdb_id') && !query.containsKey('tvdb_id') && !query.containsKey('imdb_id')) {
      return const [];
    }

    final response = await http.get(_baseUri.replace(queryParameters: query)).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return const [];
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return const [];
    final rawIntros = decoded['intro'];
    if (rawIntros is! List) return const [];

    final markers = <MediaMarker>[];
    for (final entry in rawIntros) {
      if (entry is! Map) continue;
      final start = _number(entry['start_ms']) ?? 0;
      final end = _number(entry['end_ms']);
      if (end == null || end <= start) continue;
      markers.add(
        MediaMarker(
          // Synthetic ids stay well away from typical positive server IDs.
          id: -1000000000 - markers.length,
          type: 'intro',
          startTimeOffset: start,
          endTimeOffset: end,
        ),
      );
    }
    return markers;
  }

  static int? _number(Object? value) => value is num && value.isFinite ? value.toInt() : null;

  static ExternalIds _externalIds(MediaItem item) {
    final raw = _stringMap(item.raw);
    if (item is PlexMediaItem) {
      final guidList = raw?['Guid'];
      return ExternalIds.fromGuids(
        guidList is List ? guidList : const [],
      ).fillFrom(ExternalIds.fromLegacyPlexGuid(item.guid));
    }
    final providerIds = _stringMap(raw?['ProviderIds']);
    return providerIds == null ? const ExternalIds() : ExternalIds.fromJellyfinProviderIds(providerIds);
  }

  static Map<String, Object?>? _stringMap(Object? value) {
    if (value is! Map) return null;
    return {
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }
}
