/// Value objects for the richer catalog facts providers already return on the
/// requests the Explore tab makes today.
///
/// These live beside [CatalogItem] rather than inside it so the item stays
/// readable: every type here is a small, provider-neutral shape that more than
/// one backend can fill. Serialization matches [CatalogItem]'s hand-written
/// style — no `json_serializable` — because catalog objects only ever
/// round-trip through `MediaItem.raw` inside a single session.
library;

/// What a leaderboard position is a position *in*.
///
/// MAL returns one rank per ranking endpoint, AniList returns a `rankings`
/// array tagged by type, Simkl returns a trending rank. Normalizing the scope
/// lets one badge render `#3 airing` or `#12 most popular` from any of them.
enum CatalogRankScope { popular, airing, rated, favorited, trending, seasonal }

/// A leaderboard position within [scope], over either all time or one
/// season/year window.
///
/// Providers return several at once — AniList's `rankings` array tags each
/// entry with type, format, year, season and an `allTime` flag — so an item
/// holds a list of these, not one. Dropping the window would turn "#3 most
/// popular this season" into a false all-time claim.
class CatalogRank {
  final int rank;
  final CatalogRankScope scope;

  /// True for an all-time chart; false when [year]/[season] bound it.
  final bool allTime;
  final int? year;
  final CatalogSeasonName? season;

  const CatalogRank({required this.rank, required this.scope, this.allTime = true, this.year, this.season});

  Map<String, Object?> toJson() => {
    'rank': rank,
    'scope': scope.name,
    if (!allTime) 'allTime': false,
    if (year != null) 'year': year,
    if (season != null) 'season': season!.name,
  };

  static CatalogRank? fromJson(Map<String, Object?> json) {
    final rank = json['rank'] as int?;
    final scope = CatalogRankScope.values.asNameMap()[json['scope']];
    if (rank == null || scope == null) return null;
    return CatalogRank(
      rank: rank,
      scope: scope,
      allTime: json['allTime'] != false,
      year: json['year'] as int?,
      season: CatalogSeasonName.values.asNameMap()[json['season']],
    );
  }
}

/// The window a windowed counter covers. Providers report popularity over a
/// period, and rendering such a number without its period is a false claim.
enum CatalogAudiencePeriod { day, week, month, year, allTime }

/// Community-size counters. Every field is optional because no provider
/// returns all of them: Trakt has live watchers and comments, MAL/AniList have
/// list membership and favourites, Simkl has windowed viewers, planning and a
/// drop rate.
class CatalogAudience {
  /// Users watching *right now* (Trakt trending `watchers`).
  final int? watchingNow;

  /// Users with the title on any list (MAL `num_list_users`, AniList
  /// `popularity`).
  final int? listed;

  /// Viewers within [viewersPeriod] (Simkl `watched`). This is *not* a
  /// completion count: Simkl's trending rows count viewers in the row's
  /// timeframe and its Best rows count viewers this month. Never render it
  /// without the period label.
  final int? viewers;
  final CatalogAudiencePeriod? viewersPeriod;

  /// Users who plan to watch it (Simkl `plan_to_watch`).
  final int? planning;

  /// Users with it in progress on their list (MAL
  /// `statistics.status.watching`). A list-status count, not the live
  /// concurrent-viewer figure in [watchingNow] — do not conflate them.
  final int? watching;

  /// Users who finished it (MAL `statistics.status.completed`). Unlike
  /// [viewers] this is a genuine lifetime status count, not a window.
  final int? completed;

  /// Users who paused it (MAL `statistics.status.on_hold`).
  final int? onHold;

  /// Users who abandoned it (MAL `statistics.status.dropped`). A count, where
  /// [dropRate] is a share.
  final int? dropped;

  /// Recent-activity score (AniList `trending`): how much the community is
  /// talking about it right now. A momentum signal, not a rank and not a
  /// headcount — it has no unit and must be rendered comparatively or not at
  /// all.
  final int? trendingActivity;

  /// Users who favourited it (AniList `favourites`).
  final int? favorited;

  /// Share of users who dropped it, 0-1 (Simkl `drop_rate`, sent as a
  /// percentage and normalized by the mapper).
  final double? dropRate;

  /// Provider comment count (Trakt `comment_count`).
  final int? comments;

  const CatalogAudience({
    this.watchingNow,
    this.listed,
    this.viewers,
    this.viewersPeriod,
    this.planning,
    this.watching,
    this.completed,
    this.onHold,
    this.dropped,
    this.trendingActivity,
    this.favorited,
    this.dropRate,
    this.comments,
  });

  bool get isEmpty =>
      watchingNow == null &&
      listed == null &&
      viewers == null &&
      planning == null &&
      watching == null &&
      completed == null &&
      onHold == null &&
      dropped == null &&
      trendingActivity == null &&
      favorited == null &&
      dropRate == null &&
      comments == null;

  Map<String, Object?> toJson() => {
    if (watchingNow != null) 'watchingNow': watchingNow,
    if (listed != null) 'listed': listed,
    if (viewers != null) 'viewers': viewers,
    if (viewersPeriod != null) 'viewersPeriod': viewersPeriod!.name,
    if (planning != null) 'planning': planning,
    if (watching != null) 'watching': watching,
    if (completed != null) 'completed': completed,
    if (onHold != null) 'onHold': onHold,
    if (dropped != null) 'dropped': dropped,
    if (trendingActivity != null) 'trendingActivity': trendingActivity,
    if (favorited != null) 'favorited': favorited,
    if (dropRate != null) 'dropRate': dropRate,
    if (comments != null) 'comments': comments,
  };

  /// Field-wise union, preferring [other]'s values.
  ///
  /// Counters genuinely arrive from different responses: a Simkl trending row
  /// supplies windowed [viewers] and [planning] that its detail body does not
  /// return, while the detail body supplies [dropRate] and MAL's status
  /// counts. Replacing the whole object would silently drop whichever side
  /// spoke first. [viewersPeriod] travels with [viewers] so a count is never
  /// relabelled with someone else's window.
  CatalogAudience mergedWith(CatalogAudience other) => CatalogAudience(
    watchingNow: other.watchingNow ?? watchingNow,
    listed: other.listed ?? listed,
    viewers: other.viewers ?? viewers,
    viewersPeriod: other.viewers != null ? other.viewersPeriod : viewersPeriod,
    planning: other.planning ?? planning,
    watching: other.watching ?? watching,
    completed: other.completed ?? completed,
    onHold: other.onHold ?? onHold,
    dropped: other.dropped ?? dropped,
    trendingActivity: other.trendingActivity ?? trendingActivity,
    favorited: other.favorited ?? favorited,
    dropRate: other.dropRate ?? dropRate,
    comments: other.comments ?? comments,
  );

  factory CatalogAudience.fromJson(Map<String, Object?> json) => CatalogAudience(
    watchingNow: json['watchingNow'] as int?,
    listed: json['listed'] as int?,
    viewers: json['viewers'] as int?,
    viewersPeriod: CatalogAudiencePeriod.values.asNameMap()[json['viewersPeriod']],
    planning: json['planning'] as int?,
    watching: json['watching'] as int?,
    completed: json['completed'] as int?,
    onHold: json['onHold'] as int?,
    dropped: json['dropped'] as int?,
    trendingActivity: json['trendingActivity'] as int?,
    favorited: json['favorited'] as int?,
    dropRate: (json['dropRate'] as num?)?.toDouble(),
    comments: json['comments'] as int?,
  );
}

/// A recurring weekly broadcast slot (Trakt `airs`, MAL `broadcast`).
///
/// This is a schedule, not a date: it says "Tuesdays at 21:00" and must never
/// be rendered as the next episode's air date. Use [CatalogNextEpisode] for
/// that.
class CatalogBroadcast {
  /// ISO-8601 weekday, Monday = 1 through Sunday = 7.
  final int? weekday;

  /// Local broadcast time as `HH:mm` in [timezone].
  final String? time;

  /// IANA zone name, e.g. `America/New_York` or `Asia/Tokyo`.
  final String? timezone;

  const CatalogBroadcast({this.weekday, this.time, this.timezone});

  bool get isEmpty => weekday == null && time == null;

  Map<String, Object?> toJson() => {
    if (weekday != null) 'weekday': weekday,
    if (time != null) 'time': time,
    if (timezone != null) 'timezone': timezone,
  };

  factory CatalogBroadcast.fromJson(Map<String, Object?> json) => CatalogBroadcast(
    weekday: json['weekday'] as int?,
    time: json['time'] as String?,
    timezone: json['timezone'] as String?,
  );
}

/// The next episode's actual air time (AniList `nextAiringEpisode`).
class CatalogNextEpisode {
  final int? episode;
  final DateTime airsAt;

  const CatalogNextEpisode({required this.airsAt, this.episode});

  /// Remaining time from [now], clamped at zero once the slot has passed.
  Duration timeUntil(DateTime now) {
    final delta = airsAt.difference(now);
    return delta.isNegative ? Duration.zero : delta;
  }

  Map<String, Object?> toJson() => {
    'airsAt': airsAt.toUtc().toIso8601String(),
    if (episode != null) 'episode': episode,
  };

  static CatalogNextEpisode? fromJson(Map<String, Object?> json) {
    final airsAt = DateTime.tryParse(json['airsAt'] as String? ?? '');
    if (airsAt == null) return null;
    return CatalogNextEpisode(airsAt: airsAt, episode: json['episode'] as int?);
  }
}

/// Whether the title exists on the user's own media servers, per quality tier.
enum CatalogAvailability { unavailable, partiallyAvailable, available }

/// Where a request for the title stands in the approval/download pipeline.
enum CatalogRequestState { pending, approved, processing, declined, failed }

/// Seerr's server-side knowledge about a discovery result.
///
/// Availability and request state are deliberately independent: a show can be
/// fully available in HD while a 4K request for it is still pending approval,
/// and collapsing both into one ladder would lose that.
class CatalogServerState {
  final CatalogAvailability? availability;
  final CatalogAvailability? availability4k;
  final CatalogRequestState? request;
  final CatalogRequestState? request4k;

  /// Seasons already on the server, when the provider breaks it down.
  final int? availableSeasons;
  final int? totalSeasons;

  const CatalogServerState({
    this.availability,
    this.availability4k,
    this.request,
    this.request4k,
    this.availableSeasons,
    this.totalSeasons,
  });

  bool get isEmpty =>
      availability == null &&
      availability4k == null &&
      request == null &&
      request4k == null &&
      availableSeasons == null &&
      totalSeasons == null;

  Map<String, Object?> toJson() => {
    if (availability != null) 'availability': availability!.name,
    if (availability4k != null) 'availability4k': availability4k!.name,
    if (request != null) 'request': request!.name,
    if (request4k != null) 'request4k': request4k!.name,
    if (availableSeasons != null) 'availableSeasons': availableSeasons,
    if (totalSeasons != null) 'totalSeasons': totalSeasons,
  };

  factory CatalogServerState.fromJson(Map<String, Object?> json) => CatalogServerState(
    availability: CatalogAvailability.values.asNameMap()[json['availability']],
    availability4k: CatalogAvailability.values.asNameMap()[json['availability4k']],
    request: CatalogRequestState.values.asNameMap()[json['request']],
    request4k: CatalogRequestState.values.asNameMap()[json['request4k']],
    availableSeasons: json['availableSeasons'] as int?,
    totalSeasons: json['totalSeasons'] as int?,
  );
}

/// Anime broadcast season (AniList `season`/`seasonYear`, MAL `start_season`).
enum CatalogSeasonName { winter, spring, summer, fall }

class CatalogSeasonInfo {
  final CatalogSeasonName name;
  final int? year;

  const CatalogSeasonInfo({required this.name, this.year});

  Map<String, Object?> toJson() => {'name': name.name, if (year != null) 'year': year};

  static CatalogSeasonInfo? fromJson(Map<String, Object?> json) {
    final name = CatalogSeasonName.values.asNameMap()[json['name']];
    if (name == null) return null;
    return CatalogSeasonInfo(name: name, year: json['year'] as int?);
  }

  /// Accepts AniList's `FALL`/`SUMMER` and MAL's `fall`/`summer` alike.
  static CatalogSeasonName? parseName(String? raw) =>
      raw == null ? null : CatalogSeasonName.values.asNameMap()[raw.toLowerCase()];
}

/// Release format, finer-grained than [MediaKind] (AniList `format`, MAL
/// `media_type`). Kept separate so `MediaKind.show` can still be an OVA.
enum CatalogFormat { tv, tvShort, movie, special, ova, ona, music, other }

/// What the title was adapted from (AniList/MAL `source`).
enum CatalogSourceMaterial { original, manga, lightNovel, novel, visualNovel, game, webComic, musicRelease, otherMedia }

/// A non-cast credit: director, writer, producer or creator.
enum CatalogCreditRole { director, writer, producer, creator, composer }

class CatalogCredit {
  final String name;
  final CatalogCreditRole role;

  const CatalogCredit({required this.name, required this.role});

  Map<String, Object?> toJson() => {'name': name, 'role': role.name};

  static CatalogCredit? fromJson(Map<String, Object?> json) {
    final name = json['name'] as String?;
    final role = CatalogCreditRole.values.asNameMap()[json['role']];
    if (name == null || role == null) return null;
    return CatalogCredit(name: name, role: role);
  }
}

/// A ranked descriptive tag (AniList `tags`). Distinct from genres: there are
/// many, they are user-ranked, and some spoil the plot.
class CatalogTag {
  final String name;

  /// 0-100 community relevance, when the provider ranks them.
  final int? rank;
  final bool isSpoiler;

  const CatalogTag({required this.name, this.rank, this.isSpoiler = false});

  Map<String, Object?> toJson() => {'name': name, if (rank != null) 'rank': rank, if (isSpoiler) 'isSpoiler': true};

  static CatalogTag? fromJson(Map<String, Object?> json) {
    final name = json['name'] as String?;
    if (name == null) return null;
    return CatalogTag(name: name, rank: json['rank'] as int?, isSpoiler: json['isSpoiler'] == true);
  }
}

/// An outbound link the provider supplies (AniList `externalLinks` and
/// `streamingEpisodes`, Simkl's canonical `url`).
class CatalogLink {
  /// Site name as the provider gives it — a proper noun, never translated.
  final String label;
  final String url;

  /// Marks a link that plays the title rather than describing it, so the UI
  /// can group "watch on" separately from "read about".
  final bool isStreaming;

  const CatalogLink({required this.label, required this.url, this.isStreaming = false});

  Map<String, Object?> toJson() => {'label': label, 'url': url, if (isStreaming) 'isStreaming': true};

  static CatalogLink? fromJson(Map<String, Object?> json) {
    final label = json['label'] as String?;
    final url = json['url'] as String?;
    if (label == null || url == null) return null;
    return CatalogLink(label: label, url: url, isStreaming: json['isStreaming'] == true);
  }
}

/// Play state the catalog provider itself knows about (Plex Discover
/// `includeUserState=1`). Independent of any connected media server's state.
class CatalogPlayState {
  final int? viewCount;
  final int? viewOffsetMs;
  final int? viewedLeafCount;

  const CatalogPlayState({this.viewCount, this.viewOffsetMs, this.viewedLeafCount});

  bool get isEmpty => viewCount == null && viewOffsetMs == null && viewedLeafCount == null;

  Map<String, Object?> toJson() => {
    if (viewCount != null) 'viewCount': viewCount,
    if (viewOffsetMs != null) 'viewOffsetMs': viewOffsetMs,
    if (viewedLeafCount != null) 'viewedLeafCount': viewedLeafCount,
  };

  factory CatalogPlayState.fromJson(Map<String, Object?> json) => CatalogPlayState(
    viewCount: json['viewCount'] as int?,
    viewOffsetMs: json['viewOffsetMs'] as int?,
    viewedLeafCount: json['viewedLeafCount'] as int?,
  );
}

/// Decodes a JSON list of objects into value objects, dropping malformed
/// siblings rather than failing the whole item — catalog payloads are
/// best-effort API data, not a strict persisted discriminator.
List<T>? decodeCatalogList<T>(Object? raw, T? Function(Map<String, Object?>) decode) {
  if (raw is! List) return null;
  final out = <T>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final decoded = decode(entry.cast<String, Object?>());
    if (decoded != null) out.add(decoded);
  }
  return out.isEmpty ? null : out;
}

/// Why a person appears against a recommended title.
enum CatalogRecommendationReason { favorited, recommended }

/// A user whose activity produced a recommendation (Trakt `favorited_by` and
/// `recommended_by` on personalised recommendation rows).
///
/// Counting these arrays would misstate the contract: the provenance — who,
/// and what they said about it — is the entire value of a social
/// recommendation.
class CatalogRecommender {
  final String username;
  final String? name;

  /// Free-text note the user attached to the recommendation.
  final String? note;
  final CatalogRecommendationReason reason;

  const CatalogRecommender({required this.username, required this.reason, this.name, this.note});

  /// Display name when the user set one, otherwise the handle.
  String get displayName => name?.isNotEmpty == true ? name! : username;

  Map<String, Object?> toJson() => {
    'username': username,
    'reason': reason.name,
    if (name != null) 'name': name,
    if (note != null) 'note': note,
  };

  static CatalogRecommender? fromJson(Map<String, Object?> json) {
    final username = json['username'] as String?;
    final reason = CatalogRecommendationReason.values.asNameMap()[json['reason']];
    if (username == null || reason == null) return null;
    return CatalogRecommender(
      username: username,
      reason: reason,
      name: json['name'] as String?,
      note: json['note'] as String?,
    );
  }
}
