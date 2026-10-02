import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:collection/collection.dart';

import '../i18n/strings.g.dart';
import '../media/media_kind.dart';
import '../models/catalog/catalog_item.dart';
import '../providers/catalog_sources_provider.dart';
import '../providers/cli_debrid_account_provider.dart';
import '../services/catalog/catalog_library_matcher.dart';
import '../services/catalog/library_watchlist_candidates.dart';
import '../services/cli_debrid/cli_debrid_client.dart';
import '../utils/catalog_navigation_helper.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import 'app_menu.dart';
import 'cli_debrid_icon.dart';
import 'cli_debrid_request_sheet.dart';

enum _CatalogMenuActionType { viewDetails, toggleWatchlist, openUrl, cliDebridRequest }

class _CatalogMenuAction {
  final _CatalogMenuActionType type;
  final String? url;

  const _CatalogMenuAction(this.type, {this.url});

  static const viewDetails = _CatalogMenuAction(_CatalogMenuActionType.viewDetails);
  static const toggleWatchlist = _CatalogMenuAction(_CatalogMenuActionType.toggleWatchlist);
  static const cliDebridRequest = _CatalogMenuAction(_CatalogMenuActionType.cliDebridRequest);
}

/// Context menu for catalog stand-in cards (Explore tab). Replaces
/// [MediaContextMenu], whose entries are all server-backed and would break on
/// items with no server id.
Future<void> showCatalogItemMenu(BuildContext context, CatalogItem item, {Offset? position}) async {
  final source = Provider.of<CatalogSourcesProvider?>(context, listen: false)?.watchlistSourceFor(item);
  final onWatchlist = source?.isOnWatchlist(item.kind, item.ids);
  if (source != null && onWatchlist == null) {
    // Load in the background so the row is actionable next open.
    unawaited(source.ensureWatchlistLoaded());
  }

  // Request needs a connected cli_debrid, a tmdb id, and confirmation the
  // title isn't already in a connected library — mirrors
  // CatalogItemDetailScreen's _showCliDebridRequest gate. This menu has no
  // persistent detail/match cache to read, so it resolves both itself:
  // the row form of a Plex Discover item carries only its Plex rating key
  // (tmdb/imdb arrive solely via fetchDetail's enrichment, same gap as
  // #1715), and matching needs one pass same as the detail screen's.
  // A failed pass (network error, etc.) errs toward NOT offering the action
  // rather than risking "Request" on something already owned.
  CliDebridClient? cliDebridClient;
  int? tmdbId = item.ids.tmdb;
  if (item.kind == MediaKind.movie || item.kind == MediaKind.show) {
    final cliDebrid = context.read<CliDebridAccountProvider>();
    // No-op once the provider's one-time startup hydrate has completed (see
    // CliDebridAccountProvider.initialLoadComplete) — only meaningfully waits
    // in the brief window right after app launch/profile switch, so a
    // connected user opening this menu that early doesn't see the action
    // hidden just because the disk-read/decrypt hadn't finished yet.
    await cliDebrid.initialLoadComplete;
    if (!context.mounted) return;
    if (cliDebrid.isConnected) {
      try {
        if (tmdbId == null) {
          final source = context.read<CatalogSourcesProvider>().connectedSources.firstWhereOrNull(
            (s) => s.id == item.source,
          );
          if (source != null) {
            final detail = await source.fetchDetail(item, castLimit: 0, relatedLimit: 0);
            tmdbId = detail.item.ids.tmdb;
          }
        }
        if (tmdbId != null && context.mounted) {
          final matches = await context.read<CatalogLibraryMatcher>().match(item);
          if (matches.items.isEmpty) cliDebridClient = cliDebrid.client;
        }
      } catch (e) {
        appLogger.w('Catalog context menu: cli_debrid availability check failed for ${item.identityKey}', error: e);
      }
    }
  }
  if (!context.mounted) return;

  Rect anchorRect;
  if (position != null) {
    anchorRect = position & Size.zero;
  } else {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    anchorRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
  }

  final action = await showAdaptiveAppMenu<_CatalogMenuAction>(
    context,
    title: item.title,
    anchorRect: anchorRect,
    focusFirstItem: position == null,
    entries: [
      AppMenuItem(value: _CatalogMenuAction.viewDetails, label: t.mediaMenu.viewDetails, icon: Symbols.info_rounded),
      if (item.trailerUrl case final trailerUrl? when trailerUrl.isNotEmpty)
        AppMenuItem(
          value: _CatalogMenuAction(_CatalogMenuActionType.openUrl, url: trailerUrl),
          label: t.explore.detail.watchTrailer,
          icon: Symbols.play_circle_rounded,
        ),
      for (final link in item.links ?? const [])
        if (link.label.isNotEmpty && link.url.isNotEmpty)
          AppMenuItem(
            value: _CatalogMenuAction(_CatalogMenuActionType.openUrl, url: link.url),
            label: t.explore.detail.openOn(site: link.label),
            icon: Symbols.open_in_new_rounded,
          ),
      if (onWatchlist != null)
        AppMenuItem(
          value: _CatalogMenuAction.toggleWatchlist,
          label: onWatchlist ? t.explore.removeFromWatchlist : t.explore.addToWatchlist,
          icon: onWatchlist ? Symbols.bookmark_remove_rounded : Symbols.bookmark_add_rounded,
        ),
      if (cliDebridClient != null)
        AppMenuItem(
          value: _CatalogMenuAction.cliDebridRequest,
          label: t.cliDebrid.request,
          leading: const CliDebridIcon(),
        ),
    ],
  );
  if (action == null || !context.mounted) return;

  switch (action.type) {
    case _CatalogMenuActionType.viewDetails:
      await navigateToCatalogItem(context, item);
    case _CatalogMenuActionType.toggleWatchlist:
      // Re-read membership: it can have changed while the menu was open
      // (snapshot load, another surface's toggle).
      final current = source!.isOnWatchlist(item.kind, item.ids) ?? onWatchlist ?? false;
      try {
        // The shared guard keys by source+item so a re-opened menu can't
        // double-fire while one mutation is still in flight.
        await mutateWatchlistMembership(item.kind, (source: source, ids: item.ids), add: !current);
      } catch (_) {
        if (context.mounted) showErrorSnackBar(context, t.explore.watchlistUpdateFailed);
      }
    case _CatalogMenuActionType.openUrl:
      final url = action.url;
      if (url != null) await _launchCatalogUrl(url);
    case _CatalogMenuActionType.cliDebridRequest:
      final client = cliDebridClient;
      if (client != null && tmdbId != null) {
        await showCliDebridRequestSheet(
          context,
          client: client,
          kind: item.kind,
          tmdbId: tmdbId,
          title: item.title,
          year: item.year,
        );
      }
  }
}

Future<void> _launchCatalogUrl(String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    appLogger.w('Catalog context menu ignored an invalid external URL');
    return;
  }
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) appLogger.w('Catalog context menu could not launch an external URL');
  } catch (error, stackTrace) {
    appLogger.w('Catalog context menu failed to launch an external URL', error: error, stackTrace: stackTrace);
  }
}
