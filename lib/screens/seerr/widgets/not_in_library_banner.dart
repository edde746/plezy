import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_wrapper.dart';
import '../../../i18n/strings.g.dart';
import '../../../widgets/app_icon.dart';

/// Surfaced on the main Search screen when a search returns zero results AND
/// the active profile has a Seerr server configured. Taps route to the Seerr
/// search screen with the same query pre-populated.
class NotInLibraryBanner extends StatelessWidget {
  final String query;
  final VoidCallback onTap;

  const NotInLibraryBanner({super.key, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: FocusableWrapper(
        disableScale: true,
        borderRadius: 12,
        descendantsAreFocusable: false,
        onSelect: onTap,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const AppIcon(Symbols.playlist_add_check_rounded, fill: 1, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.seerr.search.notInLibraryTitle, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          t.seerr.search.notInLibrarySubtitle(query: query),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
