import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../media/media_kind.dart';
import '../services/catalog/library_watchlist_candidates.dart';
import 'app_icon.dart';
import 'app_menu.dart';
import 'catalog_source_logo.dart';

/// Anchored chooser for an item that resolves in several watchlist-capable
/// sources: one entry per source, subtitled with what selecting it would do
/// given that source's current membership. Returns the picked candidate, or
/// null on dismiss.
Future<WatchlistCandidate?> showWatchlistSourceChooser(
  BuildContext context, {
  required MediaKind kind,
  required List<WatchlistCandidate> candidates,
  Rect? anchorRect,
  Offset? position,
  bool focusFirstItem = false,
}) {
  return showAppMenu<WatchlistCandidate>(
    context,
    anchorRect: anchorRect,
    position: position,
    focusFirstItem: focusFirstItem,
    entries: [
      for (final candidate in candidates)
        AppMenuItem(
          value: candidate,
          leading: CatalogSourceLogo(candidate.source.id),
          label: candidate.source.displayName,
          subtitle: (candidate.source.isOnWatchlist(kind, candidate.ids) ?? false)
              ? t.explore.removeFromWatchlist
              : t.explore.addToWatchlist,
          trailing: (candidate.source.isOnWatchlist(kind, candidate.ids) ?? false)
              ? const AppIcon(Symbols.bookmark_added_rounded, fill: 1)
              : const AppIcon(Symbols.bookmark_add_rounded),
        ),
    ],
  );
}
