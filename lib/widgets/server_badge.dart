import 'package:flutter/material.dart';

/// A small badge widget that indicates which server content is from
/// Shows server name or first letter with optional tooltip
class ServerBadge extends StatelessWidget {
  final String? serverName;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;
  final bool showFullName;

  const ServerBadge({
    super.key,
    required this.serverName,
    this.backgroundColor,
    this.textColor,
    this.size = 20,
    this.showFullName = false,
  });

  @override
  Widget build(BuildContext context) {
    if (serverName == null || serverName!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final bgColor = backgroundColor ??
        theme.colorScheme.primaryContainer.withOpacity(0.8);
    final fgColor = textColor ?? theme.colorScheme.onPrimaryContainer;

    final displayText = showFullName
        ? serverName!
        : serverName!.substring(0, 1).toUpperCase();

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: showFullName ? 6 : 4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: fgColor,
          fontSize: showFullName ? 10 : 11,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );

    // If showing full name, no need for tooltip
    if (showFullName) {
      return badge;
    }

    // Show tooltip with full server name on hover/long press
    return Tooltip(
      message: serverName!,
      child: badge,
    );
  }
}

/// Server section header for grouping content by server
class ServerSectionHeader extends StatelessWidget {
  final String serverName;
  final bool isOnline;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ServerSectionHeader({
    super.key,
    required this.serverName,
    this.isOnline = true,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        child: Row(
          children: [
            // Server status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Server name
            Expanded(
              child: Text(
                serverName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            // Optional trailing widget
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
