import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/card_focus_scope.dart';
import '../../focus/focusable_wrapper.dart';
import '../../theme/mono_tokens.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/loading_indicator_box.dart';

/// Synchronizes a map of ID -> FocusNode against the currently discovered servers.
void syncDiscoveredFocusNodes(Map<String, FocusNode> nodes, Iterable<String> validIds, {required String debugPrefix}) {
  final validSet = validIds.toSet();
  nodes.removeWhere((id, node) {
    if (!validSet.contains(id)) {
      node.dispose();
      return true;
    }
    return false;
  });
  for (final id in validSet) {
    nodes.putIfAbsent(id, () => FocusNode(debugLabel: '$debugPrefix:$id'));
  }
}

/// A single discovered media server tile with TV D-pad focus chrome.
class DiscoveredServerTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final BorderRadius borderRadius;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback? onTap;

  const DiscoveredServerTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.borderRadius,
    this.focusNode,
    this.onNavigateUp,
    this.onNavigateDown,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableWrapper(
      focusNode: focusNode,
      disableScale: true,
      delegateFocusBorder: true,
      descendantsAreFocusable: false,
      onSelect: onTap,
      onNavigateUp: onNavigateUp,
      onNavigateDown: onNavigateDown,
      child: CardFocusBorder(
        borderRadii: borderRadius,
        strokeAlign: BorderSide.strokeAlignInside,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
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

/// Section displaying local network discovery status and a list of discovered server tiles.
class DiscoveredServerSection<T> extends StatelessWidget {
  final bool isDiscovering;
  final String discoveringText;
  final String sectionTitle;
  final List<T> servers;
  final String Function(T) idOf;
  final String Function(T) nameOf;
  final String Function(T) addressOf;
  final Widget Function(T) leadingBuilder;
  final Map<String, FocusNode> focusNodes;
  final FocusNode? navigateUpFromFirst;
  final FocusNode? navigateDownFromLast;
  final ValueChanged<T>? onSelect;
  final bool enabled;

  const DiscoveredServerSection({
    super.key,
    required this.isDiscovering,
    required this.discoveringText,
    required this.sectionTitle,
    required this.servers,
    required this.idOf,
    required this.nameOf,
    required this.addressOf,
    required this.leadingBuilder,
    required this.focusNodes,
    this.navigateUpFromFirst,
    this.navigateDownFromLast,
    this.onSelect,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokensRef = tokens(context);

    if (isDiscovering) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          children: [
            const LoadingIndicatorBox(size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                discoveringText,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      );
    }

    if (servers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(sectionTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final (i, server) in servers.indexed) ...[
          if (i > 0) SizedBox(height: tokensRef.groupGap),
          DiscoveredServerTile(
            leading: leadingBuilder(server),
            title: nameOf(server),
            subtitle: addressOf(server),
            borderRadius: groupItemRadii(context, i, servers.length),
            focusNode: focusNodes[idOf(server)],
            onNavigateUp: () {
              if (i == 0) {
                navigateUpFromFirst?.requestFocus();
              } else {
                focusNodes[idOf(servers[i - 1])]?.requestFocus();
              }
            },
            onNavigateDown: () {
              if (i == servers.length - 1) {
                navigateDownFromLast?.requestFocus();
              } else {
                focusNodes[idOf(servers[i + 1])]?.requestFocus();
              }
            },
            onTap: enabled && onSelect != null ? () => onSelect!(server) : null,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
