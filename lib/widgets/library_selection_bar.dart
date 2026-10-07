import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import 'app_icon.dart';
import 'app_menu.dart';

/// A stable, responsive action row shared by library grid and list views.
class LibrarySelectionBar extends StatelessWidget {
  final bool selecting;
  final bool busy;
  final int count;
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final ValueChanged<bool> onMarkWatched;

  const LibrarySelectionBar({
    super.key,
    required this.selecting,
    required this.busy,
    required this.count,
    required this.onStart,
    required this.onCancel,
    required this.onMarkWatched,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: kMinInteractiveDimension,
        child: Row(
          children: [
            if (!selecting)
              TextButton.icon(
                onPressed: onStart,
                icon: const AppIcon(Symbols.checklist_rounded),
                label: Text(t.libraries.selection.selectItems),
              )
            else ...[
              IconButton(
                tooltip: t.common.cancel,
                onPressed: busy ? null : onCancel,
                icon: const AppIcon(Symbols.close_rounded),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    t.libraries.selection.selectedCount(count: count),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              AppMenuButton<bool>(
                adaptiveSheet: true,
                enabled: !busy && count > 0,
                tooltip: t.libraries.selection.actions,
                icon: const AppIcon(Symbols.more_horiz_rounded),
                entriesBuilder: (_) => [
                  AppMenuItem(
                    value: true,
                    label: t.mediaMenu.markAsWatched,
                    icon: Symbols.check_circle_outline_rounded,
                  ),
                  AppMenuItem(
                    value: false,
                    label: t.mediaMenu.markAsUnwatched,
                    icon: Symbols.remove_circle_outline_rounded,
                  ),
                ],
                onSelected: onMarkWatched,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
