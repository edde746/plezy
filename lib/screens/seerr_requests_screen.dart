import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../focus/focusable_action_bar.dart';
import '../i18n/strings.g.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../mixins/refreshable.dart';
import '../providers/catalog_sources_provider.dart';
import '../providers/explore_provider.dart';
import '../services/catalog/seerr_catalog_source.dart';
import '../services/catalog/seerr_requests.dart';
import '../utils/dialogs.dart';
import 'hub_detail_screen.dart';

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

/// The View All destination for an Explore hub: [SeerrRequestsScreen] for
/// "My requests", or null — the plain View All grid — for any other hub.
VoidCallback? seerrRequestsViewAll(BuildContext context, ExploreRowHub? rowHub) {
  if (rowHub == null || rowHub.providerHubId != SeerrRequests.hubId) return null;
  return () {
    final source = Provider.of<CatalogSourcesProvider?>(context, listen: false)?.seerrSource;
    if (source == null) return;
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SeerrRequestsScreen(source: source, hub: rowHub.hub),
        ),
      ),
    );
  };
}

/// View All for the "My requests" shelf: the same [HubDetailScreen] grid every
/// other shelf opens, fed with the signed-in user's requests. On top of it
/// sit a status filter in the app bar and a reload whenever a request is
/// deleted or a title removed (card menus, detail pages opened from here).
class SeerrRequestsScreen extends StatefulWidget {
  final SeerrCatalogSource source;

  /// The shelf this was opened from: its cards show until the full list is in.
  final MediaHub hub;

  const SeerrRequestsScreen({super.key, required this.source, required this.hub});

  @override
  State<SeerrRequestsScreen> createState() => _SeerrRequestsScreenState();
}

class _SeerrRequestsScreenState extends State<SeerrRequestsScreen> {
  final GlobalKey<State<HubDetailScreen>> _gridKey = GlobalKey();

  SeerrRequestFilter _filter = SeerrRequestFilter.all;

  /// Bumped whenever the grid has to re-read Seerr. The grid ignores a reload
  /// asked for while one is running, so a running load checks this and reads
  /// again instead of handing over what is by then outdated.
  int _generation = 0;
  bool _leaving = false;

  SeerrRequests get _requests => widget.source.requests;

  @override
  void initState() {
    super.initState();
    _requests.addListener(_reloadGrid);
  }

  @override
  void dispose() {
    _requests.removeListener(_reloadGrid);
    super.dispose();
  }

  void _reloadGrid() {
    _generation++;
    if (_gridKey.currentState case final Refreshable grid) grid.refresh();
  }

  /// The grid's loader: as many requests as the other Explore View All grids
  /// load titles.
  Future<List<MediaItem>> _loadItems() async {
    while (true) {
      final generation = _generation;
      final titles = await _requests.fetchAllTitles(
        filter: _filter,
        pageSize: ExploreProvider.viewAllPageLimit,
        maxPages: ExploreProvider.viewAllMaxPages,
      );
      if (generation == _generation || !mounted) return [for (final title in titles) title.toMediaItem()];
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
    _reloadGrid();
  }

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

    return HubDetailScreen(
      key: _gridKey,
      hub: widget.hub,
      loadItems: _loadItems,
      extraActions: [
        FocusableAction(
          debugLabel: 'seerr_requests_filter',
          icon: Symbols.filter_list_rounded,
          iconFill: _filter == SeerrRequestFilter.all ? 0 : 1,
          tooltip: '${t.seerr.requests.filter}: ${_filterLabel(_filter)}',
          onPressed: () => unawaited(_pickFilter()),
        ),
      ],
    );
  }
}
