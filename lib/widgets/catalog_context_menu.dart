import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../models/catalog/catalog_item.dart';
import '../providers/catalog_sources_provider.dart';
import '../utils/catalog_navigation_helper.dart';
import '../utils/snackbar_helper.dart';
import 'app_menu.dart';

enum _CatalogMenuAction { viewDetails, toggleWatchlist }

/// Watchlist mutations keyed by source+item so a re-opened menu can't
/// double-fire while one is still in flight (the detail screens keep their
/// own per-screen guards).
final Set<String> _watchlistMutationsInFlight = {};

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

  final action = await showAdaptiveAppMenu<_CatalogMenuAction>(
    context,
    title: item.title,
    anchorRect: anchorRect,
    focusFirstItem: position == null,
    entries: [
      AppMenuItem(value: _CatalogMenuAction.viewDetails, label: t.mediaMenu.viewDetails, icon: Symbols.info_rounded),
      if (onWatchlist != null)
        AppMenuItem(
          value: _CatalogMenuAction.toggleWatchlist,
          label: onWatchlist ? t.explore.removeFromWatchlist : t.explore.addToWatchlist,
          icon: onWatchlist ? Symbols.bookmark_remove_rounded : Symbols.bookmark_add_rounded,
        ),
    ],
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _CatalogMenuAction.viewDetails:
      await navigateToCatalogItem(context, item);
    case _CatalogMenuAction.toggleWatchlist:
      // Re-read membership: it can have changed while the menu was open
      // (snapshot load, another surface's toggle).
      final current = source!.isOnWatchlist(item.kind, item.ids) ?? onWatchlist ?? false;
      final mutationKey = '${source.id.name}/${item.kind.id}/${item.ids.canonicalKey ?? item.title}';
      if (!_watchlistMutationsInFlight.add(mutationKey)) return;
      try {
        if (current) {
          await source.removeFromWatchlist(item.kind, item.ids);
        } else {
          await source.addToWatchlist(item.kind, item.ids);
        }
      } catch (_) {
        if (context.mounted) showErrorSnackBar(context, t.explore.watchlistUpdateFailed);
      } finally {
        _watchlistMutationsInFlight.remove(mutationKey);
      }
  }
}
