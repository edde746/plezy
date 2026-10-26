import 'dart:convert';

import 'package:path/path.dart' as p;

import '../models/trakt/trakt_catalog_entry.dart';
import '../models/trakt/trakt_images.dart';
import '../sources/source_models.dart';
import '../sources/source_transport.dart';
import 'trackers/trakt/trakt_constants.dart';

class StandaloneVideoMetadata {
  const StandaloneVideoMetadata({
    required this.title,
    required this.provider,
    this.overview,
    this.year,
    this.rating,
    this.genres = const [],
    this.identifiers = const {},
    this.posterUrl,
    this.trailerUrl,
    this.cast = const [],
  });

  final String title;
  final String provider;
  final String? overview;
  final int? year;
  final double? rating;
  final List<String> genres;
  final Map<String, String> identifiers;
  final String? posterUrl;
  final String? trailerUrl;
  final List<String> cast;
}

/// Public Trakt lookup. Only the filename stem and optional year are queried;
/// file bytes and source credentials are never sent.
class StandaloneVideoMetadataClient {
  StandaloneVideoMetadataClient({SourceTransport? transport}) : _transport = transport ?? SourceTransport();

  final SourceTransport _transport;
  bool _closed = false;

  Future<StandaloneVideoMetadata?> identify(SourceEntry entry) async {
    if (_closed || entry.kind != SourceItemKind.video) return null;
    final filename = entry.files.firstOrNull?.name ?? entry.title;
    final query = _parseQuery(filename);
    if (query.title.isEmpty) return null;

    final candidates = <_Candidate>[];
    final ids = entry.identifiers;
    final idType = ids.containsKey('tmdb')
        ? 'tmdb'
        : ids.containsKey('imdb')
        ? 'imdb'
        : ids.containsKey('tvdb')
        ? 'tvdb'
        : null;
    final idValue = idType == null ? null : ids[idType];
    if (idType != null && idValue?.isNotEmpty == true) {
      try {
        candidates.addAll(
          (await _searchById(
            idType,
            idValue!,
            query.season == null ? null : 'show',
          )).map((entry) => _Candidate(entry, 1)),
        );
      } on Object {
        // A stale or unavailable external-ID lookup can still fall back to title.
      }
    }
    if (candidates.isEmpty) {
      for (final entry in await _search(query)) {
        final media = entry.media;
        final isShow = entry.show != null || entry.type == 'show';
        if (media == null || (query.season != null && !isShow)) continue;
        final score = _similarity(query.title, media.title ?? '');
        if (score < .90) continue;
        if (!isShow && query.year != null && media.year != null && (query.year! - media.year!).abs() > 1) continue;
        candidates.add(_Candidate(entry, score));
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final best = candidates.first;
    if (candidates.length > 1 && best.score - candidates[1].score < .035) return null;

    final media = best.entry.media;
    final traktId = media?.ids.trakt;
    if (media == null || traktId == null) return null;
    final isShow = best.entry.show != null || best.entry.type == 'show';
    final type = isShow ? 'shows' : 'movies';
    var overview = media.overview;
    var year = media.year;
    var rating = media.rating;
    var poster = media.images?.primaryPoster;
    var title = media.title?.trim() ?? query.title;
    final identifiers = <String, String>{
      'trakt': traktId.toString(),
      if (media.ids.tmdb != null) 'tmdb': media.ids.tmdb.toString(),
      if (media.ids.imdb != null) 'imdb': media.ids.imdb!,
      if (media.ids.tvdb != null) 'tvdb': media.ids.tvdb.toString(),
    };

    if (isShow && query.season != null && query.episode != null) {
      final episode = await _episode(traktId, query.season!, query.episode!);
      final episodeCode = 'S${query.season!.toString().padLeft(2, '0')}E${query.episode!.toString().padLeft(2, '0')}';
      if (episode != null) {
        final episodeTitle = _string(episode['title']).trim();
        title = '$title — $episodeCode${episodeTitle.isEmpty ? '' : ' · $episodeTitle'}';
        final episodeOverview = _string(episode['overview']).trim();
        if (episodeOverview.isNotEmpty) overview = episodeOverview;
        final firstAired = _string(episode['first_aired']);
        year = int.tryParse(firstAired.length >= 4 ? firstAired.substring(0, 4) : '') ?? year;
        rating = _double(episode['rating']) ?? rating;
        final imageMap = sourceMap(episode['images']);
        if (imageMap.isNotEmpty) poster = TraktImages.fromJson(imageMap).primaryPoster ?? poster;
        final episodeIds = sourceMap(episode['ids']);
        if (episodeIds['trakt'] != null) identifiers['episode_trakt'] = episodeIds['trakt'].toString();
        if (episodeIds['tmdb'] != null) identifiers['episode_tmdb'] = episodeIds['tmdb'].toString();
      } else {
        title = '$title — $episodeCode';
      }
    }

    return StandaloneVideoMetadata(
      title: title,
      provider: 'trakt',
      overview: overview,
      year: year,
      rating: rating,
      genres: media.genres ?? const [],
      identifiers: identifiers,
      posterUrl: poster,
      trailerUrl: media.trailer,
      cast: await _cast(type, traktId),
    );
  }

  Future<List<TraktCatalogEntry>> _search(_VideoQuery query) async {
    final uri = Uri.https(TraktConstants.apiBase.replaceFirst('https://', ''), '/search/movie,show', {
      'query': query.title,
      'extended': 'full,images',
      'limit': '30',
      if (query.year != null) 'year': query.year.toString(),
    });
    final response = jsonDecode(
      await _transport.text('GET', uri, headers: TraktConstants.headers()).timeout(const Duration(seconds: 12)),
    );
    if (response is! List) return const [];
    return [for (final row in response.whereType<Map<String, dynamic>>()) TraktCatalogEntry.fromJson(row)];
  }

  Future<List<TraktCatalogEntry>> _searchById(String type, String id, String? expectedType) async {
    if (id.length > 80 || id.contains('/') || id.contains('?') || id.contains('#')) return const [];
    final uri = Uri.https(
      TraktConstants.apiBase.replaceFirst('https://', ''),
      '/search/$type/${Uri.encodeComponent(id)}',
      {'extended': 'full,images', 'type': ?expectedType, 'limit': '10'},
    );
    final response = jsonDecode(
      await _transport.text('GET', uri, headers: TraktConstants.headers()).timeout(const Duration(seconds: 12)),
    );
    if (response is! List) return const [];
    return [for (final row in response.whereType<Map<String, dynamic>>()) TraktCatalogEntry.fromJson(row)];
  }

  Future<Map<String, dynamic>?> _episode(int showId, int season, int episode) async {
    final uri = Uri.https(
      TraktConstants.apiBase.replaceFirst('https://', ''),
      '/shows/$showId/seasons/$season/episodes/$episode',
      {'extended': 'full,images'},
    );
    try {
      return await _transport.json('GET', uri, headers: TraktConstants.headers()).timeout(const Duration(seconds: 12));
    } on Object {
      return null;
    }
  }

  Future<List<String>> _cast(String type, int traktId) async {
    final uri = Uri.https(TraktConstants.apiBase.replaceFirst('https://', ''), '/$type/$traktId/people', {
      'extended': 'full,images,guest_stars',
    });
    try {
      final response = await _transport
          .json('GET', uri, headers: TraktConstants.headers())
          .timeout(const Duration(seconds: 12));
      final raw = sourceList(sourceMap(response)['cast']);
      final output = <String>[];
      for (final row in raw.whereType<Map>()) {
        final person = sourceMap(row['person']);
        final name = _string(person['name']).trim();
        if (name.isEmpty) continue;
        final characters = sourceList(row['characters']).whereType<String>();
        final character = characters.isEmpty ? '' : characters.first.trim();
        output.add(character.isEmpty ? name : '$name — $character');
        if (output.length >= 12) break;
      }
      return output;
    } on Object {
      return const [];
    }
  }

  static _VideoQuery _parseQuery(String filename) {
    var stem = p.basenameWithoutExtension(filename).trim();
    final episode = RegExp(r's(\d{1,2})e(\d{1,3})', caseSensitive: false).firstMatch(stem);
    if (episode != null) {
      final prefix = stem.substring(0, episode.start).replaceAll(RegExp(r'[\s._-]+$'), '').trim();
      final fallback = prefix.isEmpty ? stem.substring(episode.end) : prefix;
      final clean = _cleanTitle(fallback);
      return _VideoQuery(
        clean.isEmpty ? _cleanTitle(stem) : clean,
        null,
        int.tryParse(episode[1]!),
        int.tryParse(episode[2]!),
      );
    }

    final years = RegExp(r'(?<!\d)(19\d{2}|20\d{2})(?!\d)').allMatches(stem).toList();
    int? year;
    if (years.isNotEmpty) {
      final match = years.last;
      final before = stem.substring(0, match.start).replaceAll(RegExp(r'[\s._-]+$'), '').trim();
      if (before.isNotEmpty) {
        year = int.tryParse(match[1]!);
        stem = before;
      }
    }
    return _VideoQuery(_cleanTitle(stem), year, null, null);
  }

  static String _cleanTitle(String value) {
    var result = value.replaceAll(RegExp(r'\[[^\]]*\]|\([^)]*\)'), ' ');
    result = result.replaceAll(
      RegExp(
        r'\b(2160p|1080p|720p|480p|4k|8k|uhd|hdr10\+?|dv|web[- .]?dl|webrip|bluray|blu[- .]?ray|brrip|hdtv|remux|x26[45]|h26[45]|hevc|av1|aac|dts|proper|repack)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    return result.replaceAll(RegExp(r'[\s._-]+'), ' ').trim();
  }

  static double _similarity(String left, String right) {
    final a = _normalize(left), b = _normalize(right);
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    if (a.length > 200 || b.length > 200) return 0;
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        current[j + 1] = [current[j] + 1, previous[j + 1] + 1, previous[j] + cost].reduce((x, y) => x < y ? x : y);
      }
      previous = current;
    }
    final maxLength = a.length > b.length ? a.length : b.length;
    final edit = 1 - previous[b.length] / maxLength;
    final leftTokens = a.split(' ').where((part) => part.length > 1).toSet();
    final rightTokens = b.split(' ').where((part) => part.length > 1).toSet();
    final union = {...leftTokens, ...rightTokens}.length;
    if (union == 0) return edit;
    final intersection = leftTokens.intersection(rightTokens).length / union;
    return edit > intersection ? edit : intersection;
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s._\-:;,!?()\[\]{}]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _string(Object? value) => value == null ? '' : '$value';
  static double? _double(Object? value) => value is num ? value.toDouble() : double.tryParse('$value');

  void close() {
    if (_closed) return;
    _closed = true;
    _transport.close();
  }
}

class _VideoQuery {
  const _VideoQuery(this.title, this.year, this.season, this.episode);
  final String title;
  final int? year;
  final int? season;
  final int? episode;
}

class _Candidate {
  const _Candidate(this.entry, this.score);
  final TraktCatalogEntry entry;
  final double score;
}
