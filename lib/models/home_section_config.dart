import '../media/media_kind.dart';

/// A source category for a configurable Home row.
enum HomeSectionKind {
  recentlyAdded,
  recentlyReleased,
  movieCollections,
  showCollections;

  String get id => switch (this) {
    HomeSectionKind.recentlyAdded => 'recently_added',
    HomeSectionKind.recentlyReleased => 'recently_released',
    HomeSectionKind.movieCollections => 'movie_collections',
    HomeSectionKind.showCollections => 'show_collections',
  };

  static HomeSectionKind fromId(String? id) => switch (id) {
    'recently_added' => HomeSectionKind.recentlyAdded,
    'recently_released' => HomeSectionKind.recentlyReleased,
    'movie_collections' => HomeSectionKind.movieCollections,
    'show_collections' => HomeSectionKind.showCollections,
    _ => HomeSectionKind.recentlyAdded,
  };

  bool get isCollectionRow => this == HomeSectionKind.movieCollections || this == HomeSectionKind.showCollections;

  MediaKind? get collectionKind => switch (this) {
    HomeSectionKind.movieCollections => MediaKind.movie,
    HomeSectionKind.showCollections => MediaKind.show,
    _ => null,
  };
}

/// One user-defined Home row. Keys are global library/collection keys.
class HomeSectionConfig {
  const HomeSectionConfig({
    required this.id,
    required this.title,
    required this.kind,
    this.libraryKeys = const [],
    this.collectionKeys = const [],
    this.enabled = true,
    this.keepSourceRows = false,
    this.showInLibraryRecommended = true,
    this.showOnHome = true,
    this.showOnFriendsHome = false,
    this.heroStyle = false,
    this.heroTrailerPreview = false,
  });

  final String id;
  final String title;
  final HomeSectionKind kind;
  final List<String> libraryKeys;
  final List<String> collectionKeys;
  final bool enabled;
  final bool keepSourceRows;
  final bool showInLibraryRecommended;
  final bool showOnHome;
  final bool showOnFriendsHome;

  /// Renders this row as a single full-width rotating hero card instead of
  /// a poster shelf. A collection row only supports this when it resolves
  /// to one collection's actual contents (see [supportsHeroStyle]) — with
  /// two or more collections selected the row shows one tile per
  /// collection, and there is no single title to rotate through.
  final bool heroStyle;

  /// Plays a trailer/scene-clip in the hero card's video zone instead of
  /// static backdrop art. Meaningless without [heroStyle] — callers must
  /// force this false whenever heroStyle is false, the same way the
  /// Organizer UI greys the toggle out rather than letting it float
  /// independently true.
  final bool heroTrailerPreview;

  bool get isCollectionRow => kind.isCollectionRow;

  /// Whether hero-card styling (and, in turn, trailer preview) is even an
  /// option for this row's current configuration. False for a collection
  /// row selecting anything other than exactly one collection, since that
  /// case has no single title/queue to render as a hero.
  bool get supportsHeroStyle => !isCollectionRow || collectionKeys.length == 1;

  HomeSectionConfig copyWith({
    String? id,
    String? title,
    HomeSectionKind? kind,
    List<String>? libraryKeys,
    List<String>? collectionKeys,
    bool? enabled,
    bool? keepSourceRows,
    bool? showInLibraryRecommended,
    bool? showOnHome,
    bool? showOnFriendsHome,
    bool? heroStyle,
    bool? heroTrailerPreview,
  }) => HomeSectionConfig(
    id: id ?? this.id,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    libraryKeys: libraryKeys ?? this.libraryKeys,
    collectionKeys: collectionKeys ?? this.collectionKeys,
    enabled: enabled ?? this.enabled,
    keepSourceRows: keepSourceRows ?? this.keepSourceRows,
    showInLibraryRecommended: showInLibraryRecommended ?? this.showInLibraryRecommended,
    showOnHome: showOnHome ?? this.showOnHome,
    showOnFriendsHome: showOnFriendsHome ?? this.showOnFriendsHome,
    heroStyle: heroStyle ?? this.heroStyle,
    heroTrailerPreview: heroTrailerPreview ?? this.heroTrailerPreview,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'kind': kind.id,
    'libraryKeys': libraryKeys,
    'collectionKeys': collectionKeys,
    'enabled': enabled,
    'keepSourceRows': keepSourceRows,
    'showInLibraryRecommended': showInLibraryRecommended,
    'showOnHome': showOnHome,
    'showOnFriendsHome': showOnFriendsHome,
    'heroStyle': heroStyle,
    'heroTrailerPreview': heroTrailerPreview,
  };

  static HomeSectionConfig fromJson(Map<String, dynamic> json) => HomeSectionConfig(
    id: json['id'] as String? ?? 'home_section',
    title: json['title'] as String? ?? 'Home',
    kind: HomeSectionKind.fromId(json['kind'] as String?),
    libraryKeys: (json['libraryKeys'] as List?)?.whereType<String>().toList() ?? const [],
    collectionKeys: (json['collectionKeys'] as List?)?.whereType<String>().toList() ?? const [],
    enabled: json['enabled'] as bool? ?? true,
    keepSourceRows: json['keepSourceRows'] as bool? ?? false,
    showInLibraryRecommended: json['showInLibraryRecommended'] as bool? ?? true,
    showOnHome: json['showOnHome'] as bool? ?? true,
    showOnFriendsHome: json['showOnFriendsHome'] as bool? ?? false,
    heroStyle: json['heroStyle'] as bool? ?? false,
    heroTrailerPreview: json['heroTrailerPreview'] as bool? ?? false,
  );
}
