import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../models/catalog/catalog_item.dart';
import '../providers/catalog_sources_provider.dart';
import '../services/catalog/library_watchlist_candidates.dart';
import '../utils/catalog_navigation_helper.dart';
import '../utils/app_logger.dart';
import '../utils/external_url.dart';
import '../utils/snackbar_helper.dart';
import '../utils/trailer_urls.dart';
import 'app_menu.dart';

enum _CatalogMenuActionType { viewDetails, toggleWatchlist, openTrailer, openLink }

class _CatalogMenuAction {
  final _CatalogMenuActionType type;
  final Uri? uri;

  const _CatalogMenuAction(this.type, {this.uri});

  static const viewDetails = _CatalogMenuAction(_CatalogMenuActionType.viewDetails);
  static const toggleWatchlist = _CatalogMenuAction(_CatalogMenuActionType.toggleWatchlist);
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

  Rect anchorRect;
  if (position != null) {
    anchorRect = position & Size.zero;
  } else {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    anchorRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
  }

  final trailerUri = await _trailerUri(item.trailerUrl);
  if (!context.mounted) return;

  final action = await showAdaptiveAppMenu<_CatalogMenuAction>(
    context,
    title: item.title,
    anchorRect: anchorRect,
    focusFirstItem: position == null,
    entries: [
      AppMenuItem(value: _CatalogMenuAction.viewDetails, label: t.mediaMenu.viewDetails, icon: Symbols.info_rounded),
      if (trailerUri != null)
        AppMenuItem(
          value: _CatalogMenuAction(_CatalogMenuActionType.openTrailer, uri: trailerUri),
          label: t.explore.detail.watchTrailer,
          icon: Symbols.play_circle_rounded,
        ),
      // tvOS has no browser to open a provider's site in (#2877).
      if (!isTvosRunner)
        for (final link in item.links ?? const [])
          if (_webUri(link.url) case final uri? when link.label.isNotEmpty)
            AppMenuItem(
              value: _CatalogMenuAction(_CatalogMenuActionType.openLink, uri: uri),
              label: t.explore.detail.openOn(site: link.label),
              icon: Symbols.open_in_new_rounded,
            ),
      if (onWatchlist != null)
        AppMenuItem(
          value: _CatalogMenuAction.toggleWatchlist,
          label: onWatchlist ? t.explore.removeFromWatchlist : t.explore.addToWatchlist,
          icon: onWatchlist ? Symbols.bookmark_remove_rounded : Symbols.bookmark_add_rounded,
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
    case _CatalogMenuActionType.openTrailer || _CatalogMenuActionType.openLink:
      if (await openExternalUrl(action.uri!)) return;
      appLogger.w('Catalog context menu could not open an external URL');
      if (!context.mounted) return;
      showErrorSnackBar(
        context,
        action.type == _CatalogMenuActionType.openTrailer
            ? t.explore.detail.trailerUnavailable
            : t.explore.detail.linkUnavailable,
      );
  }
}

/// The trailer link this device can open. tvOS has no browser, so there it is
/// a YouTube trailer handed to the YouTube app, and only when that is
/// installed (#2877).
Future<Uri?> _trailerUri(String? trailerUrl) async {
  if (!isTvosRunner) return _webUri(trailerUrl);
  final appUrl = youTubeAppUrl(trailerUrl);
  if (appUrl == null) return null;
  try {
    return await tvosCanOpenUrl(Uri.parse('youtube://')) ? appUrl : null;
  } catch (error) {
    appLogger.d('Catalog context menu YouTube app check failed', error: error);
    return null;
  }
}

Uri? _webUri(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') ? uri : null;
}
