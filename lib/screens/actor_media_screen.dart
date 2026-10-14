import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../media/ids.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../media/library_query.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../media/person_details.dart';
import '../mixins/paginated_item_loader.dart';
import '../mixins/standard_paginated_view.dart';
import '../providers/catalog_sources_provider.dart';
import '../utils/app_logger.dart';
import '../utils/error_message_utils.dart';
import '../utils/formatters.dart';
import '../utils/media_server_http_client.dart';
import '../utils/provider_extensions.dart';
import '../widgets/collapsible_text.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/optimized_media_image.dart';
import '../utils/media_image_helper.dart';
import '../i18n/strings.g.dart';
import 'base_media_list_detail_screen.dart';
import 'focusable_detail_screen_mixin.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../focus/focusable_action_bar.dart';

/// Screen to browse all media featuring a specific actor.
class ActorMediaScreen extends StatefulWidget {
  final String actorName;
  final String personId;
  final String? personTagKey;
  final String? actorThumb;
  final String? characterName;
  final String serverId;
  final String? serverName;
  final MediaBackend backend;

  const ActorMediaScreen({
    super.key,
    required this.actorName,
    required this.personId,
    this.personTagKey,
    this.actorThumb,
    this.characterName,
    required this.serverId,
    this.serverName,
    required this.backend,
  });

  @override
  State<ActorMediaScreen> createState() => _ActorMediaScreenState();
}

class _ActorMediaScreenState extends BaseMediaListDetailScreen<ActorMediaScreen>
    with
        GridFocusNodeMixin<ActorMediaScreen>,
        FocusableDetailScreenMixin<ActorMediaScreen>,
        PaginatedItemLoader<MediaItem, ActorMediaScreen>,
        PaginatedItemUpdatable<ActorMediaScreen>,
        StandardPaginatedView<MediaItem, ActorMediaScreen> {
  static const int _pageSize = 200;

  final FocusNode _overviewFocusNode = FocusNode(debugLabel: 'actor_overview');
  PersonDetails? _personDetails;

  @override
  MediaItem get mediaItem => MediaItem(
    id: '',
    backend: widget.backend,
    kind: MediaKind.unknown,
    serverId: widget.serverId,
    serverName: widget.serverName,
  );

  @override
  String get title => widget.actorName;

  @override
  String get emptyMessage => t.discover.noContentAvailable;

  @override
  bool get hasItems => totalSize > 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPersonDetails());
  }

  @override
  void dispose() {
    _overviewFocusNode.dispose();
    disposePagination();
    disposeFocusResources();
    super.dispose();
  }

  MediaServerClient get _mediaClient => context.getMediaClientForServer(ServerId(widget.serverId));

  /// The server may be offline (a cast tap from an offline detail): the header
  /// then shows the fallback avatar and the load reports the failure, instead
  /// of the lookup throwing during build.
  MediaServerClient? get _mediaClientOrNull => context.tryGetMediaClientForServer(ServerId(widget.serverId));

  Future<void> _loadPersonDetails() async {
    try {
      final details = await _fetchPersonDetails();
      if (!mounted || details == null) return;
      setState(() => _personDetails = details);
    } catch (error, stackTrace) {
      appLogger.w('Failed to load person details for ${widget.actorName}', error: error, stackTrace: stackTrace);
    }
  }

  Future<PersonDetails?> _fetchPersonDetails() async {
    if (widget.backend == MediaBackend.plex) {
      final tagKey = widget.personTagKey;
      if (tagKey == null) return null;
      final plexSource = Provider.of<CatalogSourcesProvider?>(context, listen: false)?.plexSource;
      return plexSource?.fetchPersonDetails(tagKey);
    }
    final client = _mediaClientOrNull;
    if (client is! PersonDetailsClient) return null;
    return (client as PersonDetailsClient).fetchPersonDetails(widget.personId);
  }

  @override
  void navigateToAppBar() {
    if (_personDetails?.overview == null || _overviewFocusNode.hasFocus) {
      super.navigateToAppBar();
      return;
    }
    _overviewFocusNode.requestFocus();
    scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _navigateUpFromOverview() {
    if (getAppBarActions().isNotEmpty) {
      super.navigateToAppBar();
      return;
    }
    scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  List<({String label, String value})> _personFacts(PersonDetails details) {
    final facts = <({String label, String value})>[];
    final birthDate = details.birthDate;
    final birthPlace = details.birthPlace;
    final born = [if (birthDate != null) formatFullDate(birthDate), ?birthPlace].join(' · ');
    if (born.isNotEmpty) facts.add((label: t.discover.personBornLabel, value: born));
    final deathDate = details.deathDate;
    if (deathDate != null) {
      final age = birthDate == null ? null : _ageAt(birthDate, deathDate);
      final died = formatFullDate(deathDate);
      facts.add((
        label: t.discover.personDiedLabel,
        value: age == null ? died : t.discover.personAgeAtDeath(date: died, age: age),
      ));
    }
    return facts;
  }

  static int? _ageAt(String birthDate, String deathDate) {
    final birth = DateTime.tryParse(birthDate);
    final death = DateTime.tryParse(deathDate);
    if (birth == null || death == null || death.isBefore(birth)) return null;
    final hadBirthday = death.month > birth.month || (death.month == birth.month && death.day >= birth.day);
    return death.year - birth.year - (hadBirthday ? 0 : 1);
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPage(int start, int size, AbortController? abort) {
    return _mediaClient.fetchPersonMediaPage(widget.personId, start: start, size: size, abort: abort);
  }

  @override
  Future<void> loadItems() {
    return loadStandardPaginatedItems(
      pageSize: _pageSize,
      errorMessageFor: (error, stackTrace) => localizedLoadErrorMessage(error, stackTrace, context: widget.actorName),
      onLoaded: (loadedCount, totalCount) {
        appLogger.d('Loaded $loadedCount of $totalCount items for actor: ${widget.actorName}');
        autoFocusFirstItemAfterLoad();
      },
    );
  }

  @override
  List<FocusableAction> getAppBarActions() {
    return [];
  }

  static const double _avatarSize = 80;
  static const double _avatarGap = 16;
  static const double _overviewMaxWidth = 900;
  static const double _overviewIndentMinWidth = 600;

  Widget _buildPersonFacts(List<({String label, String value})> facts, ThemeData theme) {
    final style = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        for (final fact in facts)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 12),
                child: Text(fact.label, style: style?.copyWith(fontWeight: .w600)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(fact.value, style: style, maxLines: 2, overflow: .ellipsis),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildOverview(String overview, ThemeData theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _overviewMaxWidth),
      child: CollapsibleText(
        text: overview,
        maxLines: 4,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        focusNode: _overviewFocusNode,
        skipTraversal: false,
        onNavigateUp: _navigateUpFromOverview,
        onNavigateDown: navigateToGrid,
        onNavigateLeft: () {},
        onNavigateRight: () {},
      ),
    );
  }

  Widget _buildActorHeader() {
    final theme = Theme.of(context);
    final details = _personDetails;
    final facts = details == null ? const <({String label, String value})>[] : _personFacts(details);
    final overview = details?.overview;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final indentOverview = constraints.maxWidth >= _overviewIndentMinWidth;
            return Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  crossAxisAlignment: overview != null && indentOverview ? .start : .center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(_avatarSize / 2),
                      child: OptimizedMediaImage(
                        client: _mediaClientOrNull,
                        imagePath: widget.actorThumb,
                        width: _avatarSize,
                        height: _avatarSize,
                        fit: BoxFit.cover,
                        imageType: ImageType.avatar,
                        fallbackIcon: Symbols.person_rounded,
                      ),
                    ),
                    const SizedBox(width: _avatarGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            widget.actorName,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: .bold),
                            maxLines: 2,
                            overflow: .ellipsis,
                          ),
                          if (widget.characterName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.characterName!,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                          ],
                          if (facts.isNotEmpty) _buildPersonFacts(facts, theme),
                          if (totalSize > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              t.discover.titleCount(n: totalSize),
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                          if (overview != null && indentOverview) ...[
                            const SizedBox(height: 12),
                            _buildOverview(overview, theme),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (overview != null && !indentOverview) ...[
                  const SizedBox(height: 12),
                  _buildOverview(overview, theme),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildDetailScaffold(
      slivers: [
        CustomAppBar(title: Text(widget.actorName), pinned: true, actions: buildFocusableAppBarActions()),
        _buildActorHeader(),
        ...buildStateSlivers(),
        if (hasItems)
          buildSparseFocusableGrid(
            totalItems: totalSize,
            itemAt: (index) => loadedItems[index],
            onRefresh: updateItem,
            onSkeletonVisible: (index) => ensureIndexLoaded(index, pageSize: _pageSize),
          ),
      ],
    );
  }
}
