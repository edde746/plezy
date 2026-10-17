import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../media/ids.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../media/library_query.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_person.dart';
import '../media/media_server_client.dart';
import '../mixins/paginated_item_loader.dart';
import '../mixins/standard_paginated_view.dart';
import '../utils/app_logger.dart';
import '../utils/error_message_utils.dart';
import '../utils/media_server_http_client.dart';
import '../utils/provider_extensions.dart';
import '../widgets/collapsible_text.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/optimized_media_image.dart';
import '../utils/media_image_helper.dart';
import '../i18n/app_locale_utils.dart';
import '../i18n/strings.g.dart';
import 'base_media_list_detail_screen.dart';
import 'focusable_detail_screen_mixin.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../focus/focusable_action_bar.dart';

/// Screen to browse all media featuring a specific actor.
class ActorMediaScreen extends StatefulWidget {
  final String actorName;
  final String personId;
  final String? actorThumb;
  final String? characterName;
  final String serverId;
  final String? serverName;
  final MediaBackend backend;

  const ActorMediaScreen({
    super.key,
    required this.actorName,
    required this.personId,
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

  /// Keeps a long biography to a readable line length on wide layouts.
  static const double _biographyMaxWidth = 800;

  final AbortController _detailsAbort = AbortController();
  late final FocusNode _biographyFocusNode = FocusNode(debugLabel: 'person_biography');
  MediaPersonDetails _details = MediaPersonDetails.empty;

  /// Whether the biography is truncated, so D-pad focus has a reason to stop
  /// on it (SELECT expands it) between the grid and the app bar.
  bool _biographyExpandable = false;

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
    unawaited(_loadDetails());
  }

  @override
  void dispose() {
    _detailsAbort.abort();
    _biographyFocusNode.dispose();
    disposePagination();
    disposeFocusResources();
    super.dispose();
  }

  MediaServerClient get _mediaClient => context.getMediaClientForServer(ServerId(widget.serverId));

  /// The server may be offline (a cast tap from an offline detail): the header
  /// then shows the fallback avatar and the load reports the failure, instead
  /// of the lookup throwing during build.
  MediaServerClient? get _mediaClientOrNull => context.tryGetMediaClientForServer(ServerId(widget.serverId));

  /// Best-effort: the filmography is the page. A server that cannot describe
  /// the person, or a failed lookup, leaves the header as name and photo.
  Future<void> _loadDetails() async {
    final client = _mediaClientOrNull;
    if (client == null) return;
    try {
      final details = await client.fetchPersonDetails(widget.personId, abort: _detailsAbort);
      if (!mounted || details.isEmpty) return;
      setState(() => _details = details);
    } catch (error, stackTrace) {
      if (_detailsAbort.isAborted) return;
      appLogger.w('Person details unavailable for ${widget.actorName}', error: error, stackTrace: stackTrace);
    }
  }

  /// Born, died, and birthplace rows; the age goes with the death date for
  /// someone who has died, and with the birth date otherwise.
  List<({String label, String value})> _personFacts() {
    final details = _details;
    final locale = LocaleSettings.currentLocale.intlLocaleName;
    String format(DateTime date) => DateFormat.yMMMMd(locale).format(date);
    final age = details.ageOn(DateTime.now());
    final strings = t.discover.person;
    return [
      if (details.birthDate case final born?)
        (
          label: strings.born,
          value: age != null && details.deathDate == null
              ? strings.dateWithAge(date: format(born), age: age)
              : format(born),
        ),
      if (details.deathDate case final died?)
        (
          label: strings.died,
          value: age != null ? strings.dateWithAgeAtDeath(date: format(died), age: age) : format(died),
        ),
      if (details.birthPlace case final place?) (label: strings.birthplace, value: place),
    ];
  }

  void _focusBiography() => _biographyFocusNode.requestFocus();

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

  Widget _buildActorHeader() {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final facts = _personFacts();
    final biography = _details.biography;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: OptimizedMediaImage(
                    client: _mediaClientOrNull,
                    imagePath: widget.actorThumb,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    imageType: ImageType.avatar,
                    fallbackIcon: Symbols.person_rounded,
                  ),
                ),
                const SizedBox(width: 16),
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
                          style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
                          maxLines: 1,
                          overflow: .ellipsis,
                        ),
                      ],
                      if (totalSize > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          t.discover.titleCount(n: totalSize),
                          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
                        ),
                      ],
                      if (facts.isNotEmpty) const SizedBox(height: 4),
                      for (final fact in facts)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${fact.label}  ',
                                  style: TextStyle(color: mutedColor),
                                ),
                                TextSpan(text: fact.value),
                              ],
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (biography != null) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _biographyMaxWidth),
                child: CollapsibleText(
                  text: biography,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  focusNode: _biographyFocusNode,
                  onOverflowChanged: (overflows) => setState(() => _biographyExpandable = overflows),
                  onNavigateUp: navigateToAppBar,
                  onNavigateDown: navigateToGrid,
                  onNavigateLeft: () {},
                  onNavigateRight: () {},
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildDetailScaffold(
      slivers: [
        CustomAppBar(
          title: Text(widget.actorName),
          pinned: true,
          actions: buildFocusableAppBarActions(),
          onBackPressed: popFromAppBar,
        ),
        _buildActorHeader(),
        ...buildStateSlivers(),
        if (hasItems)
          buildSparseFocusableGrid(
            totalItems: totalSize,
            itemAt: (index) => loadedItems[index],
            onRefresh: updateItem,
            onSkeletonVisible: (index) => ensureIndexLoaded(index, pageSize: _pageSize),
            onFirstRowNavigateUp: _biographyExpandable ? _focusBiography : null,
          ),
      ],
    );
  }
}
