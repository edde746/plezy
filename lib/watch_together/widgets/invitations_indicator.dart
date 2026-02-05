import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/watch_together_provider.dart';

/// Widget that displays a badge with the number of pending invitations
/// Use this to wrap icons in the navigation to show invitation count
class InvitationsIndicator extends StatelessWidget {
  final Widget child;
  final bool showZero;

  const InvitationsIndicator({
    super.key,
    required this.child,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchTogetherProvider>(
      builder: (context, watchTogetherProvider, _) {
        final count = watchTogetherProvider.pendingInvitationsCount;

        if (count == 0 && !showZero) {
          return child;
        }

        return Badge(
          label: Text(count > 99 ? '99+' : '$count'),
          isLabelVisible: count > 0,
          child: child,
        );
      },
    );
  }
}

/// Standalone badge for pending invitations count
class PendingInvitationsBadge extends StatelessWidget {
  const PendingInvitationsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<WatchTogetherProvider>(
      builder: (context, watchTogetherProvider, _) {
        final count = watchTogetherProvider.pendingInvitationsCount;

        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onError,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
