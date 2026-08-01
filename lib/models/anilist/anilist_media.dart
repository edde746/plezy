import '../../utils/json_utils.dart';
import '../../utils/trailer_urls.dart';

typedef AnilistNextAiringEpisode = ({int? episode, int airingAt, int? timeUntilAiring});

typedef AnilistRanking = ({
  int rank,
  String? type,
  String? format,
  int? year,
  String? season,
  bool allTime,
  String? context,
});

typedef AnilistTag = ({String name, int? rank, bool isMediaSpoiler});

typedef AnilistLink = ({String label, String url, String? thumbnail});

typedef AnilistStaffCredit = ({String name, String role});
typedef AnilistCharacter = ({String name, String? role, String? imageUrl});

/// Anime metadata returned by the exact field selections in [AnilistClient].
///
/// This is intentionally hand-written: AniList is GraphQL, so absent fields
/// are expected whenever a query requests a smaller shape (for example the
/// planning-list membership snapshot).
class AnilistMedia {
  static const int _maxRetainedTags = 20;

  final int? id;
  final int? idMal;
  final String? titleEnglish;
  final String? titleRomaji;
  final String? titleNative;
  final String? titleUserPreferred;
  final List<String>? synonyms;
  final String? format;
  final String? status;
  final int? episodes;
  final int? duration;
  final String? description;
  final int? averageScore;
  final int? meanScore;
  final int? popularity;
  final int? favourites;
  final int? trending;
  final String? season;
  final int? seasonYear;
  final int? startYear;
  final int? startMonth;
  final int? startDay;
  final int? endYear;
  final int? endMonth;
  final int? endDay;
  final List<String>? genres;
  final bool isAdult;
  final String? source;
  final String? countryOfOrigin;
  final String? coverImageExtraLarge;
  final String? coverImageLarge;
  final String? coverImageColor;
  final String? bannerImage;
  final List<String>? mainStudios;
  final String? trailerId;
  final String? trailerSite;
  final AnilistNextAiringEpisode? nextAiringEpisode;
  final List<AnilistRanking>? rankings;
  final List<AnilistTag>? tags;
  final List<AnilistLink>? externalLinks;
  final List<AnilistLink>? streamingEpisodes;
  final List<AnilistStaffCredit>? staffCredits;
  final List<AnilistCharacter>? characters;

  const AnilistMedia({
    this.id,
    this.idMal,
    this.titleEnglish,
    this.titleRomaji,
    this.titleNative,
    this.titleUserPreferred,
    this.synonyms,
    this.format,
    this.status,
    this.episodes,
    this.duration,
    this.description,
    this.averageScore,
    this.meanScore,
    this.popularity,
    this.favourites,
    this.trending,
    this.season,
    this.seasonYear,
    this.startYear,
    this.startMonth,
    this.startDay,
    this.endYear,
    this.endMonth,
    this.endDay,
    this.genres,
    this.isAdult = false,
    this.source,
    this.countryOfOrigin,
    this.coverImageExtraLarge,
    this.coverImageLarge,
    this.coverImageColor,
    this.bannerImage,
    this.mainStudios,
    this.trailerId,
    this.trailerSite,
    this.nextAiringEpisode,
    this.rankings,
    this.tags,
    this.externalLinks,
    this.streamingEpisodes,
    this.staffCredits,
    this.characters,
  });

  factory AnilistMedia.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final coverImage = json['coverImage'];
    final startDate = json['startDate'];
    final endDate = json['endDate'];
    final studios = json['studios'];
    final trailer = json['trailer'];

    return AnilistMedia(
      id: flexibleInt(json['id']),
      idMal: flexibleInt(json['idMal']),
      titleEnglish: title is Map ? title['english'] as String? : null,
      titleRomaji: title is Map ? title['romaji'] as String? : null,
      titleNative: title is Map ? title['native'] as String? : null,
      titleUserPreferred: title is Map ? title['userPreferred'] as String? : null,
      synonyms: _stringList(json['synonyms']),
      format: json['format'] as String?,
      status: json['status'] as String?,
      episodes: flexibleInt(json['episodes']),
      duration: flexibleInt(json['duration']),
      description: stripHtml(json['description'] as String?),
      averageScore: flexibleInt(json['averageScore']),
      meanScore: flexibleInt(json['meanScore']),
      popularity: flexibleInt(json['popularity']),
      favourites: flexibleInt(json['favourites']),
      trending: flexibleInt(json['trending']),
      season: json['season'] as String?,
      seasonYear: flexibleInt(json['seasonYear']),
      startYear: startDate is Map ? flexibleInt(startDate['year']) : null,
      startMonth: startDate is Map ? flexibleInt(startDate['month']) : null,
      startDay: startDate is Map ? flexibleInt(startDate['day']) : null,
      endYear: endDate is Map ? flexibleInt(endDate['year']) : null,
      endMonth: endDate is Map ? flexibleInt(endDate['month']) : null,
      endDay: endDate is Map ? flexibleInt(endDate['day']) : null,
      genres: _stringList(json['genres']),
      isAdult: json['isAdult'] == true,
      source: json['source'] as String?,
      countryOfOrigin: json['countryOfOrigin'] as String?,
      coverImageExtraLarge: coverImage is Map ? coverImage['extraLarge'] as String? : null,
      coverImageLarge: coverImage is Map ? coverImage['large'] as String? : null,
      coverImageColor: coverImage is Map ? coverImage['color'] as String? : null,
      bannerImage: json['bannerImage'] as String?,
      mainStudios: studios is Map ? _studioNames(studios['nodes']) : null,
      trailerId: trailer is Map ? trailer['id'] as String? : null,
      trailerSite: trailer is Map ? trailer['site'] as String? : null,
      nextAiringEpisode: _nextAiringEpisode(json['nextAiringEpisode']),
      rankings: _rankings(json['rankings']),
      tags: _tags(json['tags']),
      externalLinks: _links(json['externalLinks']),
      streamingEpisodes: _links(json['streamingEpisodes'], streaming: true),
      staffCredits: _staffCredits(json['staff']),
      characters: _characters(json['characters']),
    );
  }

  String get displayTitle => _nonEmpty(titleUserPreferred) ?? _nonEmpty(titleEnglish) ?? _nonEmpty(titleRomaji) ?? '';

  List<String>? get alternateTitles {
    final chosen = displayTitle.toLowerCase();
    final values = <String>[];
    for (final candidate in [titleEnglish, titleRomaji, ...?synonyms]) {
      final title = _nonEmpty(candidate);
      if (title == null || title.toLowerCase() == chosen) continue;
      if (values.any((value) => value.toLowerCase() == title.toLowerCase())) continue;
      values.add(title);
    }
    return values.isEmpty ? null : values;
  }

  int? get year => seasonYear ?? startYear;

  DateTime? get releaseDate => _date(startYear, startMonth, startDay);

  DateTime? get finalEpisodeDate => _date(endYear, endMonth, endDay);

  String? get posterUrl => _nonEmpty(coverImageExtraLarge) ?? _nonEmpty(coverImageLarge);

  String? get backdropUrl => _nonEmpty(bannerImage);

  double? get rating {
    final score = averageScore;
    return score == null || score <= 0 ? null : score / 10;
  }

  double? get meanRating {
    final score = meanScore;
    return score == null || score <= 0 ? null : score / 10;
  }

  int? get votes => null;

  int? get runtimeMinutes => duration == null || duration! <= 0 ? null : duration;

  String? get network {
    for (final studio in mainStudios ?? const <String>[]) {
      final name = _nonEmpty(studio);
      if (name != null) return name;
    }
    return null;
  }

  String? get trailerUrl {
    final id = _nonEmpty(trailerId);
    if (id == null || trailerSite?.toLowerCase() != 'youtube') return null;
    return youTubeTrailerUrl(id);
  }

  bool get isMovie => format == 'MOVIE';

  /// Convert AniList's small HTML subset to plain display text.
  static String? stripHtml(String? value) {
    if (value == null || value.isEmpty) return null;
    final plain = value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .trim();
    return plain.isEmpty ? null : plain;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _date(int? year, int? month, int? day) {
    if (year == null || year <= 0 || month == null || day == null) return null;
    final date = DateTime.utc(year, month, day);
    return date.year == year && date.month == month && date.day == day ? date : null;
  }

  static List<String>? _stringList(Object? value) {
    if (value is! List) return null;
    final strings = [
      for (final item in value)
        if (item is String)
          if (_nonEmpty(item) case final String string) string,
    ];
    return strings.isEmpty ? null : strings;
  }

  static List<String>? _studioNames(Object? value) {
    if (value is! List) return null;
    final names = <String>[];
    for (final node in value) {
      if (node is! Map || node['name'] is! String) continue;
      final name = _nonEmpty(node['name'] as String);
      if (name != null && !names.contains(name)) names.add(name);
    }
    return names.isEmpty ? null : names;
  }

  static AnilistNextAiringEpisode? _nextAiringEpisode(Object? value) {
    if (value is! Map) return null;
    final airingAt = flexibleInt(value['airingAt']);
    if (airingAt == null || airingAt <= 0) return null;
    return (
      episode: flexibleInt(value['episode']),
      airingAt: airingAt,
      timeUntilAiring: flexibleInt(value['timeUntilAiring']),
    );
  }

  static List<AnilistRanking>? _rankings(Object? value) {
    if (value is! List) return null;
    final rankings = <AnilistRanking>[];
    for (final raw in value) {
      if (raw is! Map) continue;
      final rank = flexibleInt(raw['rank']);
      if (rank == null || rank <= 0) continue;
      rankings.add((
        rank: rank,
        type: raw['type'] as String?,
        format: raw['format'] as String?,
        year: flexibleInt(raw['year']),
        season: raw['season'] as String?,
        allTime: raw['allTime'] == true,
        context: raw['context'] as String?,
      ));
    }
    return rankings.isEmpty ? null : rankings;
  }

  static List<AnilistTag>? _tags(Object? value) {
    if (value is! List) return null;
    final tags = <AnilistTag>[];
    for (final raw in value) {
      if (raw is! Map || raw['name'] is! String) continue;
      final name = _nonEmpty(raw['name'] as String);
      if (name == null) continue;
      tags.add((name: name, rank: flexibleInt(raw['rank']), isMediaSpoiler: raw['isMediaSpoiler'] == true));
      if (tags.length == _maxRetainedTags) break;
    }
    return tags.isEmpty ? null : tags;
  }

  static List<AnilistLink>? _links(Object? value, {bool streaming = false}) {
    if (value is! List) return null;
    final links = <AnilistLink>[];
    for (final raw in value) {
      if (raw is! Map) continue;
      final url = raw['url'] is String ? _httpUrl(raw['url'] as String) : null;
      final label = _nonEmpty(raw['site'] as String?) ?? (streaming ? _nonEmpty(raw['title'] as String?) : null);
      if (url == null || label == null) continue;
      links.add((
        label: label,
        url: url,
        thumbnail: streaming && raw['thumbnail'] is String ? _nonEmpty(raw['thumbnail'] as String) : null,
      ));
    }
    return links.isEmpty ? null : links;
  }

  static String? _httpUrl(String value) {
    final trimmed = _nonEmpty(value);
    final uri = trimmed == null ? null : Uri.tryParse(trimmed);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') ? trimmed : null;
  }

  static List<AnilistCharacter>? _characters(Object? value) {
    final edges = value is Map ? value['edges'] : null;
    if (edges is! List) return null;
    final characters = <AnilistCharacter>[];
    for (final edge in edges) {
      if (edge is! Map) continue;
      final node = edge['node'];
      final name = node is Map ? node['name'] : null;
      final fullName = name is Map && name['full'] is String ? _nonEmpty(name['full'] as String) : null;
      if (fullName == null) continue;
      final image = node is Map ? node['image'] : null;
      final large = image is Map && image['large'] is String ? _nonEmpty(image['large'] as String) : null;
      final medium = image is Map && image['medium'] is String ? _nonEmpty(image['medium'] as String) : null;
      final role = edge['role'] is String ? _nonEmpty(edge['role'] as String) : null;
      characters.add((name: fullName, role: role, imageUrl: large ?? medium));
    }
    return characters;
  }

  static List<AnilistStaffCredit>? _staffCredits(Object? value) {
    final edges = value is Map ? value['edges'] : null;
    if (edges is! List) return null;
    final credits = <AnilistStaffCredit>[];
    for (final edge in edges) {
      if (edge is! Map || edge['role'] is! String) continue;
      final node = edge['node'];
      final name = node is Map ? node['name'] : null;
      final fullName = name is Map && name['full'] is String ? _nonEmpty(name['full'] as String) : null;
      final role = _nonEmpty(edge['role'] as String);
      if (fullName != null && role != null) credits.add((name: fullName, role: role));
    }
    return credits.isEmpty ? null : credits;
  }
}

typedef AnilistPage = ({List<AnilistMedia> items, bool hasMore});
