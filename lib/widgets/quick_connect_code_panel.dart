import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import 'app_icon.dart';
import 'loading_indicator_box.dart';

/// The Quick Connect waiting panel: the code to type into Jellyfin, a
/// "waiting for approval" line, and a cancel affordance.
///
/// Shared by the MediaBrowser add-server flow and the Seerr connect flow —
/// the same panel for the same interaction, only the server polling the code
/// differs. Callers place it in a filling slot (`SliverFillRemaining` + a
/// centering `Padding`) and own the poll itself.
class QuickConnectCodePanel extends StatelessWidget {
  /// Code the user types into Jellyfin's Quick Connect screen.
  final String code;

  /// Focused after the panel appears so a remote can dismiss it.
  final FocusNode? cancelFocusNode;

  final VoidCallback onCancel;

  /// Inline failure text under the cancel button, styled like
  /// `AsyncFormStateMixin.buildInlineError`.
  final String? errorText;

  const QuickConnectCodePanel({
    super.key,
    required this.code,
    required this.onCancel,
    this.cancelFocusNode,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: .min,
        children: [
          Text(
            t.auth.quickConnectInstructions,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: muted),
          ),
          const SizedBox(height: 32),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              // letterSpacing adds a trailing gap after the last glyph;
              // matching left padding keeps the code optically centered.
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                code,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: .bold,
                  letterSpacing: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: .min,
            children: [
              const LoadingIndicatorBox(size: 16),
              const SizedBox(width: 10),
              Text(t.auth.quickConnectWaiting, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
            ],
          ),
          const SizedBox(height: 32),
          FocusableButton(
            focusNode: cancelFocusNode,
            useBackgroundFocus: true,
            onPressed: onCancel,
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const AppIcon(Symbols.close_rounded, fill: 1),
              label: Text(t.auth.quickConnectCancel),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 16),
            Text(
              errorText!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
