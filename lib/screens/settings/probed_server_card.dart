import 'package:flutter/material.dart';

import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import '../../theme/mono_tokens.dart';

/// Card displaying the server name and version of a probed media server,
/// with a "Change" button to reset the probe.
class ProbedServerCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? statusNotice;
  final FocusNode changeFocusNode;
  final VoidCallback? onChange;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final bool enabled;

  const ProbedServerCard({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.statusNotice,
    required this.changeFocusNode,
    required this.onChange,
    this.onNavigateUp,
    this.onNavigateDown,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens(context).radiusMd),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                if (statusNotice != null) ...[const SizedBox(height: 4), statusNotice!],
              ],
            ),
          ),
          FocusableButton(
            focusNode: changeFocusNode,
            useBackgroundFocus: true,
            onNavigateUp: onNavigateUp,
            onNavigateDown: onNavigateDown,
            onPressed: enabled ? onChange : null,
            child: TextButton(onPressed: enabled ? onChange : null, child: Text(t.addServer.change)),
          ),
        ],
      ),
    );
  }
}
