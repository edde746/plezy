import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../focus/focusable_action_bar.dart';
import '../focus/focusable_button.dart';
import '../focus/dpad_navigator.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../focus/locked_hub_controller.dart';
import '../i18n/app_locale_utils.dart';
import '../i18n/strings.g.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../models/catalog/catalog_cast_member.dart';
import '../models/catalog/catalog_item.dart';
import '../models/catalog/catalog_metadata.dart';
import '../providers/catalog_sources_provider.dart';
import '../services/catalog/catalog_library_matcher.dart';
import '../services/catalog/catalog_source.dart';
import '../services/catalog/seerr_catalog_source.dart';
import '../utils/app_logger.dart';
import '../utils/desktop_window_padding.dart';
import '../utils/formatters.dart';
import '../utils/country_codes.dart';
import '../utils/language_codes.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_bar_back_button.dart';
import '../widgets/app_icon.dart';
import '../widgets/backend_badge.dart';
import '../widgets/cast_member_strip.dart';
import '../widgets/horizontal_scroll_with_arrows.dart';
import '../widgets/focusable_list_tile.dart';
import '../widgets/hub_section.dart';
import '../widgets/optimized_media_image.dart';
import '../widgets/overlay_sheet.dart';
import '../widgets/seerr_request_sheet.dart';
import '../widgets/settings_section.dart';
import '../widgets/stat_chip.dart';

/// Detail screen for a catalog item (Explore tab). Renders from provider
/// data — no media server required — and resolves library availability in
/// place: an "In these libraries" list when the item is owned, tappable
/// through to the normal media detail screen.
class CatalogItemDetailScreen extends StatefulWidget {
  final CatalogItem item;

  const CatalogItemDetailScreen({super.key, required this.item});

  @override
  State<CatalogItemDetailScreen> createState() => _CatalogItemDetailScreenState();
}

class _CatalogItemDetailScreenState extends State<CatalogItemDetailScreen> {
  final _actionBarKey = GlobalKey<FocusableActionBarState>();
  final _backButtonFocusNode = FocusNode(debugLabel: 'catalog_detail_back');
  final _castSectionKey = GlobalKey();
  final _castStripKey = GlobalKey<CastMemberStripState>();
  final _relatedSectionKey = GlobalKey<HubSectionState>();
  final _hubFocusMemory = HubFocusMemory();
  final ScrollController _scrollController = ScrollController();
  final _spoilerTagFocusNode = FocusNode(debugLabel: 'catalog_spoiler_tags');
  List<FocusNode> _linkFocusNodes = const [];
  List<GlobalKey<HubSectionState>> _relationSectionKeys = const [];
  List<CatalogTag> _orderedTags = const [];
  List<CatalogLink> _streamingLinks = const [];
  List<CatalogLink> _otherLinks = const [];
  bool _showSpoilerTags = false;
  List<FocusNode> _libraryMatchFocusNodes = const [];
  CatalogSource? _watchlistSource;
  SeerrCatalogSource? _requestSource;
  bool _mutatingWatchlist = false;

  CatalogItem? _detailItem;

  /// Library items matching this catalog item; null while resolving.
  List<MediaItem>? _matches;

  /// Cast/characters from the item's own source; null while loading (the
  /// section only renders once loaded non-empty).
  List<CatalogCastMember>? _cast;

  /// "More like this" from the item's own source; null while loading (the
  /// row only renders once loaded non-empty).
  List<CatalogItem>? _related;

  /// Labelled franchise edges, kept separate from taste-based recommendations.
  List<CatalogRelation> _relations = const [];

  @override
  void initState() {
    super.initState();
    _syncDetailCollections(widget.item);
    unawaited(_resolveMatches());
    unawaited(_loadDetail());
    final sources = context.read<CatalogSourcesProvider>();
    _watchlistSource = sources.watchlistSourceFor(widget.item);
    // Request needs a connected Seerr, the permission for this kind, and a
    // tmdb id (Trakt items carry one natively; MAL items get theirs from the
    // Fribb mapping at row time).
    final seerr = sources.seerrSource;
    if (seerr != null && widget.item.ids.tmdb != null && seerr.canRequest(widget.item.kind)) {
      _requestSource = seerr;
    }
    final source = _watchlistSource;
    if (source != null) {
      source.watchlistChanges.addListener(_onWatchlistChanged);
      if (source.isOnWatchlist(widget.item.kind, widget.item.ids) == null) {
        unawaited(source.ensureWatchlistLoaded());
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _actionBarKey.currentState?.requestFocusOnFirst();
    });
  }

  @override
  void dispose() {
    _backButtonFocusNode.dispose();
    _spoilerTagFocusNode.dispose();
    for (final node in _linkFocusNodes) {
      node.dispose();
    }
    _watchlistSource?.watchlistChanges.removeListener(_onWatchlistChanged);
    for (final node in _libraryMatchFocusNodes) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onWatchlistChanged() {
    // ignore: no-empty-block - membership state lives in the source
    setState(() {});
  }

  Future<void> _resolveMatches() async {
    try {
      _setMatches(await context.read<CatalogLibraryMatcher>().match(widget.item));
    } catch (e) {
      appLogger.w('Catalog library match failed for ${widget.item.identityKey}', error: e);
      _setMatches(const []);
    }
  }

  void _setMatches(List<MediaItem> matches) {
    if (!mounted) return;
    for (final node in _libraryMatchFocusNodes) {
      node.dispose();
    }
    _libraryMatchFocusNodes = [
      for (var index = 0; index < matches.length; index++)
        FocusNode(
          debugLabel: 'catalog_library_match_$index',
          onKeyEvent: (node, event) => _handleLibraryMatchKey(index, event),
        ),
    ];
    setState(() => _matches = matches);
  }

  CatalogSource? get _ownSource =>
      context.read<CatalogSourcesProvider>().connectedSources.firstWhereOrNull((s) => s.id == widget.item.source);

  CatalogItem get _item => _detailItem ?? widget.item;

  void _syncDetailCollections(CatalogItem item) {
    final tags = [
      for (final tag in item.tags ?? const <CatalogTag>[])
        if (tag.name.trim().isNotEmpty) tag,
    ]..sort((a, b) => (b.rank ?? -1).compareTo(a.rank ?? -1));
    final streamingLinks = <CatalogLink>[];
    final otherLinks = <CatalogLink>[];
    for (final link in item.links ?? const <CatalogLink>[]) {
      if (link.label.trim().isEmpty || link.url.trim().isEmpty) continue;
      (link.isStreaming ? streamingLinks : otherLinks).add(link);
    }
    for (final node in _linkFocusNodes) {
      node.dispose();
    }
    _orderedTags = tags;
    _streamingLinks = streamingLinks;
    _otherLinks = otherLinks;
    _linkFocusNodes = [
      for (var index = 0; index < streamingLinks.length + otherLinks.length; index++)
        FocusNode(debugLabel: 'catalog_external_link_$index'),
    ];
  }

  /// One lazy detail load against the item's own source; failures keep the
  /// opening item visible and leave provider-only sections hidden.
  Future<void> _loadDetail() async {
    final source = _ownSource;
    if (source == null) return;
    try {
      final detail = await source.fetchDetail(widget.item);
      if (!mounted) return;
      final relations = [
        for (final relation in detail.relations)
          if (relation.items.isNotEmpty) relation,
      ];
      _syncDetailCollections(detail.item);
      setState(() {
        _detailItem = detail.item;
        _cast = detail.cast;
        _related = detail.related;
        _relations = relations;
        _relationSectionKeys = [for (var index = 0; index < relations.length; index++) GlobalKey<HubSectionState>()];
      });
    } catch (e) {
      appLogger.d('Catalog detail load failed for ${widget.item.identityKey}', error: e);
    }
  }

  bool get _hasTrailer => _item.trailerUrl?.trim().isNotEmpty ?? false;

  bool get _hasActions => _watchlistSource != null || _requestSource != null || _hasTrailer;

  bool get _hasLibraryMatches => _libraryMatchFocusNodes.isNotEmpty;

  bool get _hasSpoilerTags => _orderedTags.any((tag) => tag.isSpoiler);

  bool get _hasSpoilerReveal => _hasSpoilerTags && !_showSpoilerTags;

  bool get _hasDetailActions => _hasSpoilerReveal || _linkFocusNodes.isNotEmpty;

  bool get _hasHubRows => _relations.isNotEmpty || (_related?.isNotEmpty ?? false);

  void _revealFocusNode(FocusNode? node, {double alignment = 0.3}) {
    final focusContext = node?.context;
    if (focusContext == null) return;
    unawaited(
      Scrollable.ensureVisible(
        focusContext,
        alignment: alignment,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ),
    );
  }

  void _requestLibraryMatchFocus(int index) {
    if (index < 0 || index >= _libraryMatchFocusNodes.length) return;
    final node = _libraryMatchFocusNodes[index];
    node.requestFocus();
    _revealFocusNode(node);
  }

  void _requestLinkFocus(int index) {
    if (index < 0 || index >= _linkFocusNodes.length) return;
    final node = _linkFocusNodes[index];
    node.requestFocus();
    _revealFocusNode(node);
  }

  void _requestFirstDetailActionFocus() {
    if (_hasSpoilerReveal) {
      _spoilerTagFocusNode.requestFocus();
      _revealFocusNode(_spoilerTagFocusNode);
    } else {
      _requestLinkFocus(0);
    }
  }

  void _requestLastDetailActionFocus() {
    if (_linkFocusNodes.isNotEmpty) {
      _requestLinkFocus(_linkFocusNodes.length - 1);
    } else if (_hasSpoilerReveal) {
      _spoilerTagFocusNode.requestFocus();
      _revealFocusNode(_spoilerTagFocusNode);
    }
  }

  void _requestCastFocus() {
    if (!(_cast?.isNotEmpty ?? false)) return;
    _castStripKey.currentState?.requestFocus();
    final sectionContext = _castSectionKey.currentContext;
    if (sectionContext == null) return;
    unawaited(
      Scrollable.ensureVisible(
        sectionContext,
        alignment: 0.3,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ),
    );
  }

  void _requestActionBarFocus() {
    _actionBarKey.currentState?.requestFocusOnFirst();
    if (!_scrollController.hasClients) return;
    unawaited(_scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut));
  }

  void _requestRelationFocus(int index) {
    if (index < 0 || index >= _relationSectionKeys.length) return;
    _relationSectionKeys[index].currentState?.requestFocusFromMemory();
  }

  void _requestRelatedFocus() {
    _relatedSectionKey.currentState?.requestFocusFromMemory();
  }

  void _requestFirstHubFocus() {
    if (_relations.isNotEmpty) {
      _requestRelationFocus(0);
    } else {
      _requestRelatedFocus();
    }
  }

  bool _focusSectionBelowLibraryMatches() {
    if (_cast?.isNotEmpty ?? false) {
      _requestCastFocus();
      return true;
    }
    if (_hasHubRows) {
      _requestFirstHubFocus();
      return true;
    }
    return false;
  }

  void _focusSectionBelowDetailActions() {
    if (_hasLibraryMatches) {
      _requestLibraryMatchFocus(0);
    } else if (_cast?.isNotEmpty ?? false) {
      _requestCastFocus();
    } else {
      _requestFirstHubFocus();
    }
  }

  void _focusSectionBelowActions() {
    if (_hasDetailActions) {
      _requestFirstDetailActionFocus();
    } else {
      _focusSectionBelowDetailActions();
    }
  }

  void _focusSectionAboveLibraryMatches() {
    if (_hasDetailActions) {
      _requestLastDetailActionFocus();
    } else {
      _requestActionBarFocus();
    }
  }

  void _focusSectionAboveCast() {
    if (_hasLibraryMatches) {
      _requestLibraryMatchFocus(_libraryMatchFocusNodes.length - 1);
    } else if (_hasDetailActions) {
      _requestLastDetailActionFocus();
    } else {
      _requestActionBarFocus();
    }
  }

  void _focusSectionAboveFirstHub() {
    if (_cast?.isNotEmpty ?? false) {
      _requestCastFocus();
    } else if (_hasLibraryMatches) {
      _requestLibraryMatchFocus(_libraryMatchFocusNodes.length - 1);
    } else if (_hasDetailActions) {
      _requestLastDetailActionFocus();
    } else {
      _requestActionBarFocus();
    }
  }

  void _focusSectionAboveRelated() {
    if (_relations.isNotEmpty) {
      _requestRelationFocus(_relations.length - 1);
    } else {
      _focusSectionAboveFirstHub();
    }
  }

  KeyEventResult _handleLibraryMatchKey(int index, KeyEvent event) {
    if (!event.isActionable) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key.isUpKey) {
      if (index > 0) {
        _requestLibraryMatchFocus(index - 1);
      } else if (_hasDetailActions || _hasActions) {
        _focusSectionAboveLibraryMatches();
      } else {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      if (index + 1 < _libraryMatchFocusNodes.length) {
        _requestLibraryMatchFocus(index + 1);
      } else if (!_focusSectionBelowLibraryMatches()) {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _revealSpoilerTags() {
    if (!_hasSpoilerReveal) return;
    setState(() => _showSpoilerTags = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_linkFocusNodes.isNotEmpty) {
        _requestLinkFocus(0);
      } else {
        _focusSectionBelowDetailActions();
      }
    });
  }

  Future<void> _openExternalUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      appLogger.d('Catalog external URL is invalid: $value');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) appLogger.d('Catalog external URL could not be opened: $value');
    } catch (e) {
      appLogger.d('Catalog external URL failed to open: $value', error: e);
    }
  }

  bool? get _isOnWatchlist => _watchlistSource?.isOnWatchlist(_item.kind, _item.ids);

  Future<void> _toggleWatchlist() async {
    final source = _watchlistSource;
    if (source == null || _mutatingWatchlist) return;
    final current = _isOnWatchlist;
    // Parity with lib/screens/media_detail/action_buttons.dart: the action
    // stays focusable while membership is unknown, and a press kicks the
    // snapshot load rather than toggling a state we haven't read yet.
    if (current == null) {
      unawaited(source.ensureWatchlistLoaded());
      return;
    }
    _mutatingWatchlist = true;
    try {
      if (current) {
        await source.removeFromWatchlist(_item.kind, _item.ids);
      } else {
        await source.addToWatchlist(_item.kind, _item.ids);
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.explore.watchlistUpdateFailed);
    } finally {
      _mutatingWatchlist = false;
    }
  }

  Widget _buildLibraryMatchTile(MediaItem match, int index) {
    return FocusableListTile(
      focusNode: _libraryMatchFocusNodes[index],
      leading: BackendBadge(backend: match.backend, size: 24),
      // Plex matches carry their library title; Jellyfin's search-based
      // lookup doesn't, so fall back to the server name alone.
      title: Text(match.libraryTitle ?? match.serverName ?? match.backend.name),
      subtitle: match.libraryTitle != null && match.serverName != null ? Text(match.serverName!) : null,
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => unawaited(navigateToMediaItemDetails(context, match)),
    );
  }

  /// Library availability, resolved in place: a progress row while the
  /// matcher runs, "Not in your library" when nothing matched, otherwise an
  /// "In these libraries" list whose rows open the normal media detail
  /// screen. Rows are focusable tiles (dpad-safe, background focus effect).
  Widget _buildLibrarySection(ThemeData theme) {
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5));
    final matches = _matches;

    if (matches == null) {
      return Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Text(t.explore.checkingLibrary, style: mutedStyle),
        ],
      );
    }

    if (matches.isEmpty) {
      return Row(
        children: [
          AppIcon(Symbols.info_rounded, fill: 1, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Text(t.explore.notInLibrary, style: mutedStyle),
        ],
      );
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(t.explore.inTheseLibraries, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        // M3E grouped cards, same row anatomy as the settings/trackers hub:
        // server-type logo leading, name, chevron trailing.
        SettingsGroup(
          margin: EdgeInsets.zero,
          children: [
            for (var index = 0; index < matches.length; index++) _buildLibraryMatchTile(matches[index], index),
          ],
        ),
      ],
    );
  }

  String get _metaLine {
    final item = _item;
    final parts = <String>[
      if (item.year != null) '${item.year}',
      if (item.runtimeMinutes != null) formatDurationTextual(Duration(minutes: item.runtimeMinutes!).inMilliseconds),
      if (item.certification?.trim().isNotEmpty ?? false) item.certification!.trim(),
    ];
    return parts.join(' • ');
  }

  static String _statusLabel(CatalogAirStatus status) => switch (status) {
    CatalogAirStatus.airing => t.explore.status.airing,
    CatalogAirStatus.ended => t.explore.status.ended,
    CatalogAirStatus.canceled => t.explore.status.canceled,
    CatalogAirStatus.upcoming => t.explore.status.upcoming,
  };

  static String _seasonName(CatalogSeasonName season) => switch (season) {
    CatalogSeasonName.winter => t.explore.season.winter,
    CatalogSeasonName.spring => t.explore.season.spring,
    CatalogSeasonName.summer => t.explore.season.summer,
    CatalogSeasonName.fall => t.explore.season.fall,
  };

  static String _seasonLabel(CatalogSeasonInfo season) {
    final name = _seasonName(season.name);
    return season.year == null ? name : t.explore.season.withYear(season: name, year: season.year!);
  }

  static String _formatLabel(CatalogFormat format) => switch (format) {
    CatalogFormat.tv => t.explore.format.tv,
    CatalogFormat.tvShort => t.explore.format.tvShort,
    CatalogFormat.movie => t.explore.format.movie,
    CatalogFormat.special => t.explore.format.special,
    CatalogFormat.ova => t.explore.format.ova,
    CatalogFormat.ona => t.explore.format.ona,
    CatalogFormat.music => t.explore.format.music,
    CatalogFormat.other => t.explore.format.other,
  };

  static String _sourceMaterialLabel(CatalogSourceMaterial source) => switch (source) {
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

  static String _creditRoleLabel(CatalogCreditRole role) => switch (role) {
    CatalogCreditRole.director => t.explore.creditRole.director,
    CatalogCreditRole.writer => t.explore.creditRole.writer,
    CatalogCreditRole.producer => t.explore.creditRole.producer,
    CatalogCreditRole.creator => t.explore.creditRole.creator,
    CatalogCreditRole.composer => t.explore.creditRole.composer,
  };

  static String? _ratingSourceLabel(String source) => switch (source) {
    'critic' => t.explore.ratingSource.critic,
    'audience' => t.explore.ratingSource.audience,
    'imdb' => t.explore.ratingSource.imdb,
    'tmdb' => t.explore.ratingSource.tmdb,
    'rottenTomatoes' => t.explore.ratingSource.rottenTomatoes,
    // Plex splits Rotten Tomatoes into its two panels, so both the provenance
    // and the critic/audience distinction survive.
    'rottenTomatoesCritic' => t.explore.ratingSource.rottenTomatoesCritic,
    'rottenTomatoesAudience' => t.explore.ratingSource.rottenTomatoesAudience,
    'simkl' => t.explore.ratingSource.simkl,
    'mal' => t.explore.ratingSource.mal,
    'anilist' => t.explore.ratingSource.anilist,
    'trakt' => t.explore.ratingSource.trakt,
    _ => null,
  };

  static String _relationLabel(CatalogRelationType type) => switch (type) {
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

  static String? _joinValues(Iterable<String>? raw, {String Function(String value)? displayName}) {
    if (raw == null) return null;
    final values = <String>[];
    final seen = <String>{};
    for (final rawValue in raw) {
      final value = rawValue.trim();
      if (value.isEmpty) continue;
      final displayed = displayName?.call(value) ?? value;
      if (displayed.trim().isNotEmpty && seen.add(displayed)) values.add(displayed);
    }
    return values.isEmpty ? null : values.join(' • ');
  }

  static String? _rankLabel(CatalogRank rank) {
    if (!rank.allTime) {
      final season = rank.season;
      final window = switch ((season, rank.year)) {
        (final CatalogSeasonName season, final int year) => t.explore.season.withYear(
          season: _seasonName(season),
          year: year,
        ),
        (final CatalogSeasonName season, null) => _seasonName(season),
        (null, final int year) => '$year',
        _ => null,
      };
      return window == null ? null : t.explore.badge.rankSeasonal(n: rank.rank, season: window);
    }
    return switch (rank.scope) {
      CatalogRankScope.popular => t.explore.badge.rankPopular(n: rank.rank),
      CatalogRankScope.airing => t.explore.badge.rankAiring(n: rank.rank),
      CatalogRankScope.rated => t.explore.badge.rankRated(n: rank.rank),
      CatalogRankScope.favorited => t.explore.badge.rankFavorited(n: rank.rank),
      CatalogRankScope.trending => t.explore.badge.rankTrending(n: rank.rank),
      CatalogRankScope.seasonal => null,
    };
  }

  static String? _availabilityLabel(CatalogAvailability availability, {required bool is4k}) {
    if (is4k) {
      return availability == CatalogAvailability.available ? t.explore.badge.availableIn4k : null;
    }
    return switch (availability) {
      CatalogAvailability.available => t.explore.badge.available,
      CatalogAvailability.partiallyAvailable => t.explore.badge.partiallyAvailable,
      CatalogAvailability.unavailable => null,
    };
  }

  static String _requestStateLabel(CatalogRequestState request, {required bool is4k}) {
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

  /// Headline score, leaderboard context, audience counts, availability and
  /// release-shape facts that fit the established compact chip treatment.
  Widget? _buildStatsChips() {
    final item = _item;
    final locale = LocaleSettings.currentLocale.intlLocaleName;
    final compact = NumberFormat.compact(locale: locale);
    final chips = <Widget>[];
    void add(String? label, {IconData? icon, Color? iconColor}) {
      if (label?.trim().isNotEmpty ?? false) {
        chips.add(StatChip(icon: icon, iconColor: iconColor, label: label!));
      }
    }

    if (item.rating case final rating?) {
      var score = rating.toStringAsFixed(1);
      if (item.votes case final votes?) {
        score = '$score (${t.explore.stats.votes(n: compact.format(votes))})';
      }
      add(score, icon: Symbols.star_rounded, iconColor: Colors.amber);
    }
    if (item.airStatus case final status?) add(_statusLabel(status));
    if (item.episodeCount case final count?) add(t.explore.episodeCount(n: count));
    if (item.unairedEpisodeCount case final count?) add(t.explore.detail.unairedEpisodes(n: count));
    add(item.network);
    if (item.broadcastSeason case final season?) add(_seasonLabel(season));
    if (item.format case final format?) add(_formatLabel(format));
    if (item.sourceMaterial case final source?) add(_sourceMaterialLabel(source));
    if (item.isAdult == true) add(t.explore.badge.adult);
    if (item.addedAt case final addedAt?) {
      add(t.explore.detail.addedOn(date: DateFormat.yMMMd(locale).format(addedAt.toLocal())));
    }
    for (final rank in item.ranks ?? const <CatalogRank>[]) {
      add(_rankLabel(rank));
    }

    final audience = item.audience;
    if (audience != null) {
      if (audience.watchingNow case final count?) add(t.explore.badge.watchingNow(n: compact.format(count)));
      if (audience.listed case final count?) add(t.explore.stats.listed(n: compact.format(count)));
      if (audience.viewers case final count? when audience.viewersPeriod != null) {
        final formatted = compact.format(count);
        add(switch (audience.viewersPeriod!) {
          CatalogAudiencePeriod.day => t.explore.stats.viewersDay(n: formatted),
          CatalogAudiencePeriod.week => t.explore.stats.viewersWeek(n: formatted),
          CatalogAudiencePeriod.month => t.explore.stats.viewersMonth(n: formatted),
          CatalogAudiencePeriod.year => t.explore.stats.viewersYear(n: formatted),
          CatalogAudiencePeriod.allTime => t.explore.stats.viewersAllTime(n: formatted),
        });
      }
      if (audience.planning case final count?) add(t.explore.stats.planning(n: compact.format(count)));
      if (audience.watching case final count?) add(t.explore.stats.watching(n: compact.format(count)));
      if (audience.completed case final count?) add(t.explore.stats.completed(n: compact.format(count)));
      if (audience.onHold case final count?) add(t.explore.stats.onHold(n: compact.format(count)));
      if (audience.dropped case final count?) add(t.explore.stats.dropped(n: compact.format(count)));
      if (audience.favorited case final count?) add(t.explore.stats.favorited(n: compact.format(count)));
      if (audience.dropRate case final rate?) {
        add(t.explore.stats.dropRate(percent: NumberFormat.percentPattern(locale).format(rate)));
      }
      if (audience.comments case final count?) add(t.explore.stats.comments(n: count));
    }

    final server = item.serverState;
    if (server != null) {
      if (server.availability case final availability?) {
        add(_availabilityLabel(availability, is4k: false));
      }
      if (server.availability4k case final availability?) {
        add(_availabilityLabel(availability, is4k: true));
      }
      if (server.request case final request?) add(_requestStateLabel(request, is4k: false));
      if (server.request4k case final request?) add(_requestStateLabel(request, is4k: true));
      if (server.availableSeasons case final available? when server.totalSeasons != null) {
        add(t.explore.badge.seasonsAvailable(available: available, total: server.totalSeasons!));
      }
    }

    if (chips.isEmpty) return null;
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget? _buildRatingsSection(ThemeData theme) {
    final compact = NumberFormat.compact(locale: LocaleSettings.currentLocale.intlLocaleName);
    final chips = <Widget>[];
    for (final rating in _item.ratings ?? const <CatalogRatingSource>[]) {
      final source = _ratingSourceLabel(rating.source);
      if (source == null) continue;
      var label = '$source ${rating.value.toStringAsFixed(1)}';
      if (rating.votes case final votes?) {
        label = '$label (${t.explore.stats.votes(n: compact.format(votes))})';
      }
      chips.add(StatChip(icon: Symbols.star_rounded, iconColor: Colors.amber, label: label));
    }
    if (chips.isEmpty) return null;
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(t.explore.detail.ratings, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget? _buildScheduleSection(ThemeData theme) {
    final item = _item;
    final chips = <Widget>[];
    final locale = LocaleSettings.currentLocale.intlLocaleName;
    final broadcast = item.broadcast;
    if (broadcast?.weekday case final weekday? when weekday >= DateTime.monday && weekday <= DateTime.sunday) {
      final time = broadcast!.time?.trim();
      if (time?.isNotEmpty ?? false) {
        final day = DateFormat.EEEE(locale).format(DateTime.utc(2024, 1, weekday));
        final timezone = broadcast.timezone?.trim();
        chips.add(
          StatChip(
            label: timezone?.isNotEmpty ?? false
                ? t.explore.broadcastWithZone(day: day, time: time!, timezone: timezone!)
                : t.explore.broadcast(day: day, time: time!),
          ),
        );
      }
    }
    if (item.nextEpisode case final next?) {
      final duration = formatDurationTextual(next.timeUntil(DateTime.now()).inMilliseconds);
      chips.add(
        StatChip(
          label: next.episode == null
              ? t.explore.badge.nextAiringIn(duration: duration)
              : t.explore.badge.nextEpisodeIn(episode: next.episode!, duration: duration),
        ),
      );
    }
    if (chips.isEmpty) return null;
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(t.explore.detail.schedule, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _buildFactRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget? _buildFactsSection(ThemeData theme) {
    final item = _item;
    final locale = LocaleSettings.currentLocale.intlLocaleName;
    final dateFormat = DateFormat.yMMMd(locale);
    final currency = NumberFormat.simpleCurrency(locale: locale, name: 'USD', decimalDigits: 0);
    final facts = <({String label, String value})>[];
    void add(String label, String? value) {
      if (value?.trim().isNotEmpty ?? false) facts.add((label: label, value: value!));
    }

    add(t.explore.detail.originalTitle, item.originalTitle);
    add(t.explore.detail.alsoKnownAs, _joinValues(item.altTitles));
    add(t.explore.detail.studios, _joinValues(item.studios));
    add(t.explore.detail.country, _joinValues(item.countries, displayName: CountryCodes.getDisplayName));
    add(t.explore.detail.language, _joinValues(item.languages, displayName: LanguageCodes.getDisplayName));
    if (item.releaseDate case final date?) add(t.explore.detail.released, dateFormat.format(date.toLocal()));
    if (item.physicalReleaseDate case final date?) {
      add(t.explore.detail.physicalRelease, dateFormat.format(date.toLocal()));
    }
    if (item.endDate case final date?) add(t.explore.detail.ended, dateFormat.format(date.toLocal()));
    if (item.userRating case final rating?) add(t.explore.detail.yourRating, rating.toStringAsFixed(1));
    if (item.budget case final budget?) add(t.explore.detail.budget, currency.format(budget));
    if (item.revenue case final revenue?) add(t.explore.detail.revenue, currency.format(revenue));
    add(t.explore.detail.contentAdvisory, item.contentAdvisory);
    if (facts.isEmpty) return null;
    return Column(
      crossAxisAlignment: .start,
      children: [for (final fact in facts) _buildFactRow(theme, fact.label, fact.value)],
    );
  }

  Widget? _buildRecommendersSection(ThemeData theme) {
    final recommenders = _item.recommenders;
    if (recommenders == null || recommenders.isEmpty) return null;
    return Column(
      crossAxisAlignment: .start,
      children: [
        for (var index = 0; index < recommenders.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          Text(switch (recommenders[index].reason) {
            CatalogRecommendationReason.favorited => t.explore.detail.favoritedBy(who: recommenders[index].displayName),
            CatalogRecommendationReason.recommended => t.explore.detail.recommendedBy(
              who: recommenders[index].displayName,
            ),
          }, style: theme.textTheme.titleSmall),
          if (recommenders[index].note?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(recommenders[index].note!.trim(), style: theme.textTheme.bodyMedium),
          ],
        ],
      ],
    );
  }

  Widget? _buildCrewSection(ThemeData theme) {
    final credits = _item.credits;
    if (credits == null || credits.isEmpty) return null;
    final rows = <Widget>[];
    for (final role in CatalogCreditRole.values) {
      final names = _joinValues(credits.where((credit) => credit.role == role).map((credit) => credit.name));
      if (names != null) rows.add(_buildFactRow(theme, _creditRoleLabel(role), names));
    }
    if (rows.isEmpty) return null;
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(t.explore.detail.crew, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  Widget? _buildTagsSection(ThemeData theme) {
    if (_orderedTags.isEmpty) return null;
    final visibleTags = [
      for (final tag in _orderedTags)
        if (!tag.isSpoiler || _showSpoilerTags) tag,
    ];
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(t.explore.detail.tags, style: theme.textTheme.titleMedium),
        if (visibleTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final tag in visibleTags) StatChip(label: tag.name)]),
        ],
        if (_hasSpoilerReveal) ...[
          const SizedBox(height: 8),
          FocusableButton(
            focusNode: _spoilerTagFocusNode,
            onPressed: _revealSpoilerTags,
            onNavigateUp: _hasActions ? _requestActionBarFocus : null,
            onNavigateDown: _linkFocusNodes.isNotEmpty ? () => _requestLinkFocus(0) : _focusSectionBelowDetailActions,
            child: OutlinedButton.icon(
              onPressed: _revealSpoilerTags,
              icon: const AppIcon(Symbols.visibility_rounded, fill: 1),
              label: Text(t.explore.detail.revealSpoilerTags),
            ),
          ),
        ],
      ],
    );
  }

  void _focusAboveLinkGroup(int startIndex) {
    if (startIndex > 0) {
      _requestLinkFocus(startIndex - 1);
    } else if (_hasSpoilerReveal) {
      _spoilerTagFocusNode.requestFocus();
      _revealFocusNode(_spoilerTagFocusNode);
    } else {
      _requestActionBarFocus();
    }
  }

  void _focusBelowLinkGroup(int endIndex) {
    if (endIndex < _linkFocusNodes.length) {
      _requestLinkFocus(endIndex);
    } else {
      _focusSectionBelowDetailActions();
    }
  }

  Widget _buildLinksSection(ThemeData theme, String title, List<CatalogLink> links, int startIndex) {
    final endIndex = startIndex + links.length;
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var localIndex = 0; localIndex < links.length; localIndex++)
              FocusableButton(
                focusNode: _linkFocusNodes[startIndex + localIndex],
                onPressed: () => unawaited(_openExternalUrl(links[localIndex].url)),
                onNavigateLeft: localIndex > 0 ? () => _requestLinkFocus(startIndex + localIndex - 1) : null,
                onNavigateRight: localIndex + 1 < links.length
                    ? () => _requestLinkFocus(startIndex + localIndex + 1)
                    : null,
                onNavigateUp: () => _focusAboveLinkGroup(startIndex),
                onNavigateDown: () => _focusBelowLinkGroup(endIndex),
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(_openExternalUrl(links[localIndex].url)),
                  icon: const AppIcon(Symbols.open_in_new_rounded, fill: 1),
                  label: Text(t.explore.detail.openOn(site: links[localIndex].label)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundSection(ThemeData theme, String background) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(t.explore.detail.background, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(background, style: theme.textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildGallerySection(ThemeData theme, List<String> gallery) {
    final cardWidth = CastMemberStrip.responsiveCardWidth(context);
    final imageHeight = cardWidth * 1.5;
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(t.explore.detail.gallery, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        ExcludeFocus(
          child: SizedBox(
            height: imageHeight + 10,
            child: HorizontalScrollWithArrows(
              builder: (scrollController) => ListView.builder(
                key: const Key('catalog_detail_gallery'),
                addAutomaticKeepAlives: false,
                addSemanticIndexes: false,
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(vertical: 5),
                itemCount: gallery.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: OptimizedMediaImage.poster(imagePath: gallery[index], width: cardWidth, height: imageHeight),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Horizontal cast strip — the same [CastMemberStrip] cards as the media
  /// detail screen. Trakt serves actors with their character; MAL serves
  /// characters with their role, so the section is titled accordingly.
  Widget _buildCastSection(ThemeData theme, List<CatalogCastMember> cast) {
    return Column(
      key: _castSectionKey,
      crossAxisAlignment: .start,
      children: [
        Text(
          const {CatalogSourceId.mal, CatalogSourceId.anilist}.contains(_item.source)
              ? t.explore.characters
              : t.explore.cast,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        CastMemberStrip(
          key: _castStripKey,
          members: [
            for (final member in cast) (name: member.name, secondary: member.secondary, imagePath: member.imageUrl),
          ],
          onNavigateUp: _hasLibraryMatches || _hasDetailActions || _hasActions ? _focusSectionAboveCast : null,
          onNavigateDown: _hasHubRows ? _requestFirstHubFocus : null,
          debugLabel: 'catalog_cast_row',
        ),
      ],
    );
  }

  Widget _buildRelationSection(CatalogRelation relation, int index) {
    return HubSection(
      key: _relationSectionKeys[index],
      hub: MediaHub(
        id: 'catalog-relation:${_item.source.name}:${_item.identityKey}:${relation.type.name}:$index',
        identifier: 'explore.relation.${relation.type.name}',
        title: _relationLabel(relation.type),
        type: 'mixed',
        items: [for (final item in relation.items) item.toMediaItem()],
        size: relation.items.length,
      ),
      focusMemory: _hubFocusMemory,
      icon: Symbols.link_rounded,
      inset: true,
      onNavigateUp: index == 0 ? _focusSectionAboveFirstHub : () => _requestRelationFocus(index - 1),
      onVerticalNavigation: (isUp) {
        if (isUp) {
          if (index == 0) {
            _focusSectionAboveFirstHub();
          } else {
            _requestRelationFocus(index - 1);
          }
          return true;
        }
        if (index + 1 < _relations.length) {
          _requestRelationFocus(index + 1);
          return true;
        }
        if (_related?.isNotEmpty ?? false) {
          _requestRelatedFocus();
          return true;
        }
        return false;
      },
      cardSizing: HubCardSizing.grid,
    );
  }

  /// Taste-based recommendations stay separate from labelled franchise facts.
  Widget _buildRelatedSection(List<CatalogItem> related) {
    return HubSection(
      key: _relatedSectionKey,
      hub: MediaHub(
        id: 'catalog-related:${_item.source.name}:${_item.identityKey}',
        identifier: 'explore.related',
        title: t.discover.moreLikeThis,
        type: 'mixed',
        items: [for (final item in related) item.toMediaItem()],
        size: related.length,
      ),
      focusMemory: _hubFocusMemory,
      icon: Symbols.recommend_rounded,
      inset: true,
      onNavigateUp: _focusSectionAboveRelated,
      cardSizing: HubCardSizing.grid,
    );
  }

  void _handleSystemBack() {
    if (BackKeyCoordinator.consumeIfHandled()) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final theme = Theme.of(context);
    final onWatchlist = _isOnWatchlist;
    final tmdbId = item.ids.tmdb;

    final viewInsets = MediaQuery.paddingOf(context);
    final blockSystemBack = PlatformDetector.isTV() || InputModeTracker.shouldBlockSystemBack(context);
    // Match the established detail-screen back policy: TV/keyboard back is
    // owned by the focus tree, while native mobile back and iOS swipe-back
    // remain route-driven. The overlay host always gets first refusal.
    return OverlaySheetHost(
      canPop: !blockSystemBack,
      onSystemBack: _handleSystemBack,
      child: Builder(
        builder: (hostContext) => Focus(
          onKeyEvent: (_, event) => handleBackKeyNavigation(hostContext, event),
          child: Scaffold(
            body: Stack(
              children: [
                SingleChildScrollView(
                  key: const Key('catalog_detail_scroll'),
                  controller: _scrollController,
                  // The backdrop lives inside the scrollable so it moves with
                  // the content (it extends under the status bar, so the safe
                  // areas are baked into the content padding instead of a
                  // SafeArea around the scroll view).
                  child: Stack(
                    children: [
                      if (item.backdropUrl != null)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 320,
                          child: ShaderMask(
                            shaderCallback: (rect) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black, Colors.black.withValues(alpha: 0.0)],
                              stops: const [0.3, 1.0],
                            ).createShader(rect),
                            blendMode: BlendMode.dstIn,
                            child: OptimizedMediaImage.thumb(
                              imagePath: item.backdropUrl,
                              width: double.infinity,
                              height: 320,
                              fit: BoxFit.cover,
                              fallbackIcon: null,
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, viewInsets.top + 120, 24, viewInsets.bottom + 32),
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Row(
                              crossAxisAlignment: .start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: OptimizedMediaImage.poster(imagePath: item.posterUrl, width: 140, height: 210),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      if (item.tagline?.trim() case final tagline? when tagline.isNotEmpty) ...[
                                        Text(
                                          tagline,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                      Text(
                                        item.title,
                                        style: theme.textTheme.headlineMedium,
                                        maxLines: 3,
                                        overflow: .ellipsis,
                                      ),
                                      if (_metaLine.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _metaLine,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                      if (item.genres?.isNotEmpty ?? false) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          item.genres!.join(' • '),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      if (_hasActions)
                                        FocusableActionBar(
                                          key: _actionBarKey,
                                          onNavigateDown: _focusSectionBelowActions,
                                          actions: [
                                            if (_watchlistSource != null)
                                              FocusableAction(
                                                icon: onWatchlist ?? false
                                                    ? Symbols.bookmark_added_rounded
                                                    : Symbols.bookmark_add_rounded,
                                                tooltip: onWatchlist ?? false
                                                    ? t.explore.removeFromWatchlist
                                                    : t.explore.addToWatchlist,
                                                onPressed: () => unawaited(_toggleWatchlist()),
                                              ),
                                            if (_requestSource case final SeerrCatalogSource seerr when tmdbId != null)
                                              FocusableAction(
                                                icon: Symbols.download_rounded,
                                                tooltip: t.seerr.request,
                                                onPressed: () => unawaited(
                                                  showSeerrRequestSheet(
                                                    hostContext,
                                                    source: seerr,
                                                    kind: item.kind,
                                                    tmdbId: tmdbId,
                                                    title: item.title,
                                                  ),
                                                ),
                                              ),
                                            if (item.trailerUrl?.trim() case final trailer? when trailer.isNotEmpty)
                                              FocusableAction(
                                                icon: Symbols.play_circle_rounded,
                                                tooltip: t.explore.detail.watchTrailer,
                                                onPressed: () => unawaited(_openExternalUrl(trailer)),
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_buildStatsChips() case final Widget chips) ...[const SizedBox(height: 20), chips],
                            if (item.overview?.trim() case final overview? when overview.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(overview, style: theme.textTheme.bodyLarge),
                            ],
                            if (item.background?.trim() case final background? when background.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildBackgroundSection(theme, background),
                            ],
                            if (item.gallery case final List<String> gallery when gallery.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildGallerySection(theme, gallery),
                            ],
                            if (_buildFactsSection(theme) case final Widget facts) ...[
                              const SizedBox(height: 24),
                              facts,
                            ],
                            if (_buildRecommendersSection(theme) case final Widget recommenders) ...[
                              const SizedBox(height: 24),
                              recommenders,
                            ],
                            if (_buildRatingsSection(theme) case final Widget ratings) ...[
                              const SizedBox(height: 24),
                              ratings,
                            ],
                            if (_buildScheduleSection(theme) case final Widget schedule) ...[
                              const SizedBox(height: 24),
                              schedule,
                            ],
                            if (_buildCrewSection(theme) case final Widget crew) ...[const SizedBox(height: 24), crew],
                            if (_buildTagsSection(theme) case final Widget tags) ...[const SizedBox(height: 24), tags],
                            if (_streamingLinks.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildLinksSection(theme, t.explore.detail.watchOn, _streamingLinks, 0),
                            ],
                            if (_otherLinks.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildLinksSection(theme, t.explore.detail.links, _otherLinks, _streamingLinks.length),
                            ],
                            const SizedBox(height: 24),
                            _buildLibrarySection(theme),
                            if (_cast case final List<CatalogCastMember> cast when cast.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _buildCastSection(theme, cast),
                            ],
                            for (var index = 0; index < _relations.length; index++) ...[
                              const SizedBox(height: 20),
                              _buildRelationSection(_relations[index], index),
                            ],
                            if (_related case final List<CatalogItem> related when related.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildRelatedSection(related),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: DesktopAppBarHelper.buildAdjustedLeading(
                    AppBarBackButton(style: BackButtonStyle.circular, focusNode: _backButtonFocusNode),
                    context: hostContext,
                  )!,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
