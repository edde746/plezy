import '../../utils/json_utils.dart';

/// Anime metadata returned by the exact field selections in [AnilistClient].
///
/// This is intentionally hand-written: AniList is GraphQL, so absent fields
/// are expected whenever a query requests a smaller shape (for example the
/// planning-list membership snapshot).
class AnilistMedia {
  final int? id;
  final int? idMal;
  final String? titleEnglish;
  final String? titleRomaji;
  final String? titleUserPreferred;
  final String? format;
  final String? status;
  final int? episodes;
  final int? duration;
  final String? description;
  final int? averageScore;
  final String? season;
  final int? seasonYear;
  final int? startYear;
  final List<String>? genres;
  final bool isAdult;
  final String? coverImageExtraLarge;
  final String? coverImageLarge;
  final String? bannerImage;
  final List<String>? mainStudios;
  final String? trailerId;
  final String? trailerSite;

  const AnilistMedia({
    this.id,
    this.idMal,
    this.titleEnglish,
    this.titleRomaji,
    this.titleUserPreferred,
    this.format,
    this.status,
    this.episodes,
    this.duration,
    this.description,
    this.averageScore,
    this.season,
    this.seasonYear,
    this.startYear,
    this.genres,
    this.isAdult = false,
    this.coverImageExtraLarge,
    this.coverImageLarge,
    this.bannerImage,
    this.mainStudios,
    this.trailerId,
    this.trailerSite,
  });

  factory AnilistMedia.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final coverImage = json['coverImage'];
    final startDate = json['startDate'];
    final studios = json['studios'];
    final trailer = json['trailer'];

    return AnilistMedia(
      id: flexibleInt(json['id']),
      idMal: flexibleInt(json['idMal']),
      titleEnglish: title is Map ? title['english'] as String? : null,
      titleRomaji: title is Map ? title['romaji'] as String? : null,
      titleUserPreferred: title is Map ? title['userPreferred'] as String? : null,
      format: json['format'] as String?,
      status: json['status'] as String?,
      episodes: flexibleInt(json['episodes']),
      duration: flexibleInt(json['duration']),
      description: stripHtml(json['description'] as String?),
      averageScore: flexibleInt(json['averageScore']),
      season: json['season'] as String?,
      seasonYear: flexibleInt(json['seasonYear']),
      startYear: startDate is Map ? flexibleInt(startDate['year']) : null,
      genres: _stringList(json['genres']),
      isAdult: json['isAdult'] == true,
      coverImageExtraLarge: coverImage is Map ? coverImage['extraLarge'] as String? : null,
      coverImageLarge: coverImage is Map ? coverImage['large'] as String? : null,
      bannerImage: json['bannerImage'] as String?,
      mainStudios: studios is Map ? _studioNames(studios['nodes']) : null,
      trailerId: trailer is Map ? trailer['id'] as String? : null,
      trailerSite: trailer is Map ? trailer['site'] as String? : null,
    );
  }

  String get displayTitle => _nonEmpty(titleEnglish) ?? _nonEmpty(titleUserPreferred) ?? _nonEmpty(titleRomaji) ?? '';

  int? get year => seasonYear ?? startYear;

  String? get posterUrl => _nonEmpty(coverImageExtraLarge) ?? _nonEmpty(coverImageLarge);

  String? get backdropUrl => _nonEmpty(bannerImage);

  double? get rating {
    final score = averageScore;
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
    return 'https://www.youtube.com/watch?v=$id';
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

  static String? _nonEmpty(String? value) => value == null || value.isEmpty ? null : value;

  static List<String>? _stringList(Object? value) {
    if (value is! List) return null;
    final strings = [
      for (final item in value)
        if (item is String && item.isNotEmpty) item,
    ];
    return strings.isEmpty ? null : strings;
  }

  static List<String>? _studioNames(Object? value) {
    if (value is! List) return null;
    final names = [
      for (final node in value)
        if (node is Map && node['name'] is String && (node['name'] as String).isNotEmpty) node['name'] as String,
    ];
    return names.isEmpty ? null : names;
  }
}

typedef AnilistPage = ({List<AnilistMedia> items, bool hasMore});
