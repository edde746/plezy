import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/strings.g.dart';
import '../models/catalog/catalog_item.dart';
import '../providers/catalog_sources_provider.dart';
import '../utils/catalog_navigation_helper.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import 'app_menu.dart';

enum _CatalogMenuActionType { viewDetails, toggleWatchlist, openUrl }

class _CatalogMenuAction {
  final _CatalogMenuActionType type;
  final String? url;

  const _CatalogMenuAction(this.type, {this.url});

  static const viewDetails = _CatalogMenuAction(_CatalogMenuActionType.viewDetails);
  static const toggleWatchlist = _CatalogMenuAction(_CatalogMenuActionType.toggleWatchlist);
}

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
    case _CatalogMenuActionType.openUrl:
      final url = action.url;
      if (url != null) await _launchCatalogUrl(url);
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
