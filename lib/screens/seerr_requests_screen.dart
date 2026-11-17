import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../focus/focusable_action_bar.dart';
import '../i18n/strings.g.dart';
import '../media/media_kind.dart';
import '../providers/catalog_sources_provider.dart';
import '../providers/explore_provider.dart';
import '../providers/seerr_account_provider.dart';
import '../services/catalog/seerr_catalog_source.dart';
import '../services/catalog/seerr_requests.dart';
import '../utils/app_logger.dart';
import '../utils/catalog_navigation_helper.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../widgets/app_icon.dart';
import '../widgets/app_menu.dart';
import '../widgets/focusable_list_tile.dart';
import '../widgets/focused_scroll_scaffold.dart';
import '../widgets/loading_indicator_box.dart';
import '../widgets/optimized_media_image.dart';
import '../widgets/overlay_sheet.dart';
import '../widgets/seerr_request_actions.dart';
import '../widgets/stat_chip.dart';
import 'libraries/state_messages.dart';

/// Shelf icon for the "My requests" Explore hub, or null for any other hub.
IconData? seerrRequestsHubIcon(String? providerHubId) =>
    providerHubId == SeerrRequests.hubId ? Symbols.move_to_inbox_rounded : null;

/// Explore shelves with "My requests" moved to the front: provider hubs
/// otherwise trail the fixed discover rows, which would bury the one shelf
/// that is the user's own.
List<ExploreRowHub> seerrRequestsHubFirst(List<ExploreRowHub> rowHubs) {
  final index = rowHubs.indexWhere((rowHub) => rowHub.providerHubId == SeerrRequests.hubId);
  if (index <= 0) return rowHubs;
  return [rowHubs[index], ...rowHubs.take(index), ...rowHubs.skip(index + 1)];
}

/// The View All destination for an Explore hub: the full requests list for
/// "My requests", or null — the generic View All grid — for any other hub.
VoidCallback? seerrRequestsViewAll(BuildContext context, String? providerHubId) {
  if (providerHubId != SeerrRequests.hubId) return null;
  return () {
    final source = Provider.of<CatalogSourcesProvider?>(context, listen: false)?.seerrSource;
    if (source == null) return;
    unawaited(Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SeerrRequestsScreen(source: source))));
  };
}

/// The signed-in Seerr user's requests, newest first: paged, filterable by
/// status, refreshable. A row opens the title's catalog detail page; a
/// long-press (hold SELECT, or the menu key) offers the delete actions the
/// user's permissions allow.
class SeerrRequestsScreen extends StatefulWidget {
  final SeerrCatalogSource source;

  const SeerrRequestsScreen({super.key, required this.source});

  @override
  State<SeerrRequestsScreen> createState() => _SeerrRequestsScreenState();
}

class _SeerrRequestsScreenState extends State<SeerrRequestsScreen> {
  static const int _pageSize = 20;

  SeerrRequestFilter _filter = SeerrRequestFilter.all;
  List<SeerrRequestEntry> _entries = const [];

  /// Requests Seerr has returned so far — the next page's offset. Not
  /// [_entries.length]: a request without a usable title reference is
  /// dropped from the list but still occupies its place in Seerr's paging.
  int _offset = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadFailed = false;
  bool _loadingMore = false;
  bool _moreFailed = false;
  bool _leaving = false;

  /// Bumped by every reload so a slower, older page cannot land on top of
  /// a newer list (filter switched, refresh, mutation).
  int _generation = 0;

  SeerrRequests get _requests => widget.source.requests;

  @override
  void initState() {
    super.initState();
    _requests.addListener(_onRequestsChanged);
    unawaited(_loadFirstPage(++_generation));
  }

  @override
  void dispose() {
    _requests.removeListener(_onRequestsChanged);
    super.dispose();
  }

  /// A request was deleted or a title removed, here or on a detail page
  /// opened from here: re-read rather than patch the list locally.
  void _onRequestsChanged() => unawaited(_reload());

  /// Load the first page. The current rows stay up while it runs unless
  /// [clear] says they no longer apply (another filter).
  Future<void> _reload({bool clear = false}) {
    final generation = ++_generation;
    setState(() {
      if (clear) _entries = const [];
      _loading = true;
      _loadFailed = false;
      _loadingMore = false;
      _moreFailed = false;
    });
    return _loadFirstPage(generation);
  }

  Future<void> _loadFirstPage(int generation) async {
    try {
      final page = await _requests.fetchMine(take: _pageSize, filter: _filter);
      if (!mounted || generation != _generation) return;
      setState(() {
        _entries = page.entries;
        _offset = page.fetched;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      appLogger.w('Seerr: requests list load failed', error: e);
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loading || _loadingMore) return;
    final generation = _generation;
    setState(() {
      _loadingMore = true;
      _moreFailed = false;
    });
    try {
      final page = await _requests.fetchMine(skip: _offset, take: _pageSize, filter: _filter);
      if (!mounted || generation != _generation) return;
      setState(() {
        _entries = [..._entries, ...page.entries];
        _offset += page.fetched;
        // An empty page that still claims more would page forever.
        _hasMore = page.hasMore && page.fetched > 0;
        _loadingMore = false;
      });
    } catch (e) {
      appLogger.w('Seerr: requests list page load failed', error: e);
      if (!mounted || generation != _generation) return;
      setState(() {
        _loadingMore = false;
        _moreFailed = true;
      });
    }
  }

  static String _filterLabel(SeerrRequestFilter filter) => switch (filter) {
    SeerrRequestFilter.all => t.seerr.requests.filterAll,
    SeerrRequestFilter.pending => t.seerr.requests.filterPending,
    SeerrRequestFilter.approved => t.seerr.requests.filterApproved,
    SeerrRequestFilter.processing => t.seerr.requests.filterProcessing,
    SeerrRequestFilter.available => t.seerr.requests.filterAvailable,
    SeerrRequestFilter.failed => t.seerr.requests.filterFailed,
  };

  Future<void> _pickFilter() async {
    final picked = await showOptionPickerDialog<SeerrRequestFilter>(
      context,
      title: t.seerr.requests.filter,
      options: [
        for (final filter in SeerrRequestFilter.values)
          (icon: filter == _filter ? Symbols.check_rounded : null, label: _filterLabel(filter), value: filter),
      ],
    );
    if (picked == null || picked == _filter || !mounted) return;
    setState(() => _filter = picked);
    unawaited(_reload(clear: true));
  }

  String _titleOf(SeerrRequestEntry entry) => entry.item?.title ?? t.seerr.requests.unknownTitle(id: entry.tmdbId);

  void _open(SeerrRequestEntry entry) {
    final item = entry.item;
    if (item == null) return;
    unawaited(navigateToCatalogItem(context, item));
  }

  /// The row menu. Built from the entry itself rather than a fresh read: the
  /// list response already carries everything the gates need (requester,
  /// status, variant, Seerr's own `canRemove`), and Seerr re-checks anyway.
  Future<void> _showMenu(BuildContext hostContext, BuildContext rowContext, SeerrRequestEntry entry) async {
    final actions = seerrRequestActions(widget.source, entry.title, entry.kind);
    if (entry.item == null && actions.isEmpty) return;
    final renderBox = rowContext.findRenderObject();
    final anchorRect = renderBox is RenderBox && renderBox.hasSize
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : Rect.zero;
    final title = _titleOf(entry);
    final picked = await showAdaptiveAppMenu<Object>(
      hostContext,
      title: title,
      anchorRect: anchorRect,
      focusFirstItem: true,
      entries: [
        if (entry.item != null)
          AppMenuItem<Object>(value: _openDetails, label: t.mediaMenu.viewDetails, icon: Symbols.info_rounded),
        for (final action in actions)
          AppMenuItem<Object>(
            value: action,
            label: action.label,
            subtitle: action is SeerrRemoveCompletelyAction ? action.subtitle : null,
            icon: action.icon,
            destructive: true,
          ),
      ],
    );
    if (picked == null || !mounted || !hostContext.mounted) return;
    if (picked == _openDetails) {
      _open(entry);
    } else if (picked is SeerrRequestAction) {
      await runSeerrRequestAction(hostContext, source: widget.source, action: picked, title: title);
    }
  }

  static const Object _openDetails = Object();

  /// The screen belongs to the session that opened it: leave once Seerr is
  /// disconnected or rebound to another account's client.
  void _leaveIfUnbound(SeerrCatalogSource? current) {
    if (_leaving || identical(current, widget.source)) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sources = context.watch<CatalogSourcesProvider?>();
    if (sources != null) _leaveIfUnbound(sources.seerrSource);
    // The gates read the client's live permission mask; the account provider
    // is what announces a grant or revocation adopted in place.
    context.select<SeerrAccountProvider?, int?>((account) => account?.permissions);

    final filterLabel = _filterLabel(_filter);
    return OverlaySheetHost(
      canPop: true,
      child: Builder(
        builder: (hostContext) => RefreshIndicator(
          onRefresh: _reload,
          // Without this a short list never overscrolls on Android and the
          // pull gesture has nothing to grab.
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(physics: const AlwaysScrollableScrollPhysics()),
            child: FocusedScrollScaffold(
              title: Text(t.seerr.requests.myRequests),
              focusableAppBarActions: true,
              actions: [
                FocusableActionBar(
                  actions: [
                    FocusableAction(
                      debugLabel: 'seerr_requests_filter',
                      icon: Symbols.filter_list_rounded,
                      iconFill: _filter == SeerrRequestFilter.all ? 0 : 1,
                      tooltip: '${t.seerr.requests.filter}: $filterLabel',
                      onPressed: () => unawaited(_pickFilter()),
                    ),
                    FocusableAction(
                      debugLabel: 'seerr_requests_refresh',
                      icon: Symbols.refresh_rounded,
                      tooltip: t.common.refresh,
                      onPressed: () => unawaited(_reload()),
                    ),
                  ],
                ),
              ],
              slivers: _buildSlivers(hostContext, filterLabel),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(BuildContext hostContext, String filterLabel) {
    if (_entries.isEmpty && _loading) return const [LoadingIndicatorBox.sliver];
    if (_entries.isEmpty && _loadFailed) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorStateWidget(
            message: t.seerr.requests.loadFailed,
            icon: Symbols.error_outline_rounded,
            actionAutofocus: true,
            onRetry: () => unawaited(_reload()),
          ),
        ),
      ];
    }
    if (_entries.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            message: _filter == SeerrRequestFilter.all ? t.seerr.requests.empty : t.seerr.requests.emptyFiltered,
            subtitle: _filter == SeerrRequestFilter.all ? null : filterLabel,
            icon: Symbols.move_to_inbox_rounded,
          ),
        ),
      ];
    }

    final hasFooter = _hasMore || _loadingMore || _moreFailed;
    return [
      if (_filter != SeerrRequestFilter.all)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatChip(icon: Symbols.filter_list_rounded, label: filterLabel),
            ),
          ),
        ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == _entries.length) return _buildFooter();
            // Building one of the last rows means the user is near the end,
            // by scroll or by D-pad alike.
            if (index >= _entries.length - 3) _scheduleLoadMore();
            return _buildRow(hostContext, index);
          },
          childCount: _entries.length + (hasFooter ? 1 : 0),
          addAutomaticKeepAlives: false,
        ),
      ),
    ];
  }

  void _scheduleLoadMore() {
    if (!_hasMore || _loading || _loadingMore || _moreFailed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadMore());
    });
  }

  Widget _buildFooter() {
    if (_moreFailed || !_loadingMore) {
      // Auto-paging failed (or has not fired yet): an explicit, focusable way
      // to ask for the next page.
      return FocusableListTile(
        key: const ValueKey('seerr_requests_load_more'),
        leading: const AppIcon(Symbols.expand_more_rounded, fill: 1),
        title: Text(_moreFailed ? t.seerr.requests.loadFailed : t.seerr.requests.loadMore),
        subtitle: _moreFailed ? Text(t.common.retry) : null,
        onTap: () => unawaited(_loadMore()),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: LoadingIndicatorBox(size: 24)),
    );
  }

  Widget _buildRow(BuildContext hostContext, int index) {
    final entry = _entries[index];
    final theme = Theme.of(context);
    final item = entry.item;
    final details = [
      entry.kind == MediaKind.movie ? t.common.mediaKind.movie : t.common.mediaKind.show,
      if (item?.year case final int year) '$year',
      if (entry.is4k) '4K',
      if (entry.seasonNumbers.isNotEmpty) t.seerr.requests.seasonsList(seasons: entry.seasonNumbers.join(', ')),
    ].join(' · ');
    final requestedAt = entry.requestedAt?.toLocal();
    return Builder(
      key: ValueKey('seerr_request_${entry.request.id}'),
      builder: (rowContext) => FocusableListTile(
        autofocus: index == 0,
        dense: false,
        visualDensity: VisualDensity.standard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: OptimizedMediaImage.poster(imagePath: item?.posterFor(92), width: 44, height: 66),
        ),
        title: Text(_titleOf(entry), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            details,
            if (requestedAt != null)
              t.seerr.requests.requestedOn(date: formatAbbreviatedDate(requestedAt.toIso8601String().substring(0, 10))),
          ].join('\n'),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        trailing: _RequestBadgeChip(entry.badge),
        onTap: item == null ? null : () => _open(entry),
        onLongPress: () => unawaited(_showMenu(hostContext, rowContext, entry)),
      ),
    );
  }
}

/// The request's status as a tinted pill.
class _RequestBadgeChip extends StatelessWidget {
  final SeerrRequestBadge badge;

  const _RequestBadgeChip(this.badge);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (badge) {
      SeerrRequestBadge.pending => (Symbols.hourglass_top_rounded, scheme.tertiary),
      SeerrRequestBadge.approved => (Symbols.thumb_up_rounded, scheme.primary),
      SeerrRequestBadge.processing => (Symbols.downloading_rounded, scheme.primary),
      SeerrRequestBadge.partiallyAvailable => (Symbols.check_circle_rounded, scheme.primary),
      SeerrRequestBadge.available => (Symbols.check_circle_rounded, Colors.green),
      SeerrRequestBadge.declined => (Symbols.block_rounded, scheme.error),
      SeerrRequestBadge.failed => (Symbols.error_rounded, scheme.error),
    };
    return StatChip(icon: icon, iconColor: color, label: seerrRequestBadgeLabel(badge));
  }
}
