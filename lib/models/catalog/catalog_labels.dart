/// Pure catalog enum -> i18n label mappings shared by the Explore detail
/// screen and the media-card catalog badges.
///
/// Only the per-value wording lives here. Chip selection, precedence, and
/// badge composition (which badge wins, 4k handling, seasons counts) stay at
/// each call site, and call sites keep their own mapping where they
/// deliberately word the same enum differently.
library;

import '../../i18n/strings.g.dart';
import '../../services/catalog/catalog_source.dart';
import 'catalog_item.dart';
import 'catalog_metadata.dart';

String statusLabel(CatalogAirStatus status) => switch (status) {
  CatalogAirStatus.airing => t.explore.status.airing,
  CatalogAirStatus.ended => t.explore.status.ended,
  CatalogAirStatus.canceled => t.explore.status.canceled,
  CatalogAirStatus.upcoming => t.explore.status.upcoming,
};

String seasonName(CatalogSeasonName season) => switch (season) {
  CatalogSeasonName.winter => t.explore.season.winter,
  CatalogSeasonName.spring => t.explore.season.spring,
  CatalogSeasonName.summer => t.explore.season.summer,
  CatalogSeasonName.fall => t.explore.season.fall,
};

String seasonLabel(CatalogSeasonInfo season) {
  final name = seasonName(season.name);
  return season.year == null ? name : t.explore.season.withYear(season: name, year: season.year!);
}

String formatLabel(CatalogFormat format) => switch (format) {
  CatalogFormat.tv => t.explore.format.tv,
  CatalogFormat.tvShort => t.explore.format.tvShort,
  CatalogFormat.movie => t.explore.format.movie,
  CatalogFormat.special => t.explore.format.special,
  CatalogFormat.ova => t.explore.format.ova,
  CatalogFormat.ona => t.explore.format.ona,
  CatalogFormat.music => t.explore.format.music,
  CatalogFormat.other => t.explore.format.other,
};

String sourceMaterialLabel(CatalogSourceMaterial source) => switch (source) {
  CatalogSourceMaterial.original => t.explore.sourceMaterial.original,
  CatalogSourceMaterial.manga => t.explore.sourceMaterial.manga,
  CatalogSourceMaterial.lightNovel => t.explore.sourceMaterial.lightNovel,
  CatalogSourceMaterial.novel => t.explore.sourceMaterial.novel,
  CatalogSourceMaterial.visualNovel => t.explore.sourceMaterial.visualNovel,
  CatalogSourceMaterial.game => t.explore.sourceMaterial.game,
  CatalogSourceMaterial.webComic => t.explore.sourceMaterial.webComic,
  CatalogSourceMaterial.musicRelease => t.explore.sourceMaterial.musicRelease,
  CatalogSourceMaterial.otherMedia => t.explore.sourceMaterial.otherMedia,
};

String creditRoleLabel(CatalogCreditRole role) => switch (role) {
  CatalogCreditRole.director => t.explore.creditRole.director,
  CatalogCreditRole.writer => t.explore.creditRole.writer,
  CatalogCreditRole.producer => t.explore.creditRole.producer,
  CatalogCreditRole.creator => t.explore.creditRole.creator,
  CatalogCreditRole.composer => t.explore.creditRole.composer,
};

String relationLabel(CatalogRelationType type) => switch (type) {
  CatalogRelationType.prequel => t.explore.relation.prequel,
  CatalogRelationType.sequel => t.explore.relation.sequel,
  CatalogRelationType.sideStory => t.explore.relation.sideStory,
  CatalogRelationType.spinOff => t.explore.relation.spinOff,
  CatalogRelationType.alternativeVersion => t.explore.relation.alternativeVersion,
  CatalogRelationType.summary => t.explore.relation.summary,
  CatalogRelationType.parentStory => t.explore.relation.parentStory,
  CatalogRelationType.adaptation => t.explore.relation.adaptation,
  CatalogRelationType.other => t.explore.relation.other,
};

String? rankLabel(CatalogRank rank) {
  if (!rank.allTime) {
    final season = rank.season;
    final window = switch ((season, rank.year)) {
      (final CatalogSeasonName season, final int year) => t.explore.season.withYear(
        season: seasonName(season),
        year: year,
      ),
      (final CatalogSeasonName season, null) => seasonName(season),
      (null, final int year) => '$year',
      _ => null,
    };
    return window == null ? null : t.explore.badge.rankSeasonal(n: rank.rank, season: window);
  }
  return switch (rank.scope) {
    CatalogRankScope.popular => t.explore.badge.rankPopular(n: rank.rank),
    CatalogRankScope.airing => t.explore.badge.rankAiring(n: rank.rank),
    CatalogRankScope.rated => t.explore.badge.rankRated(n: rank.rank),
    CatalogRankScope.trending => t.explore.badge.rankTrending(n: rank.rank),
  };
}

String? availabilityLabel(CatalogAvailability availability, {required bool is4k}) {
  if (is4k) {
    return availability == CatalogAvailability.available ? t.explore.badge.availableIn4k : null;
  }
  return switch (availability) {
    CatalogAvailability.available => t.explore.badge.available,
    CatalogAvailability.partiallyAvailable => t.explore.badge.partiallyAvailable,
    CatalogAvailability.unavailable => null,
  };
}

String requestStateLabel(CatalogRequestState request, {required bool is4k}) {
  if (is4k &&
      {CatalogRequestState.pending, CatalogRequestState.approved, CatalogRequestState.processing}.contains(request)) {
    return t.explore.badge.requested4k;
  }
  return switch (request) {
    CatalogRequestState.pending => t.explore.badge.pendingApproval,
    CatalogRequestState.approved => t.explore.badge.requested,
    CatalogRequestState.processing => t.explore.badge.processing,
    CatalogRequestState.declined => t.explore.badge.declined,
    CatalogRequestState.failed => t.explore.badge.requestFailed,
  };
}
