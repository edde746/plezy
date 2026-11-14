import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/card_focus_scope.dart';
import '../../focus/focusable_wrapper.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/loading_indicator_box.dart';

/// The "servers found on this network" half of an add-server form.
///
/// Jellyfin answers a UDP broadcast and Music Assistant advertises over mDNS,
/// but from the form's point of view the two are the same screen: run a bounded
/// search once on open, keep a focus node per result so a D-pad can walk them,
/// and drop the whole thing if the user leaves mid-search. Both screens had
/// their own copy of that — the same five methods and the same tile, differing
/// only in the model type and which strings they read.
///
/// [S] is the backend's discovered-server record. Nothing is assumed about it
/// beyond what [discoveredServerId] and the builder's callbacks extract, so a
/// third backend needs no changes here.
mixin LocalServerDiscoveryMixin<S, W extends StatefulWidget> on State<W> {
  List<S> localServers = const [];
  bool isDiscoveringLocalServers = true;

  final Map<String, FocusNode> discoveredServerFocusNodes = {};

  /// Bumped on every new search and on dispose, so a slow answer from a search
  /// the user has already walked away from cannot land.
  int _attemptId = 0;

  /// Runs the backend's own discovery. Kept on the screen because both screens
  /// take a test-only factory override on the widget.
  Future<List<S>> discoverLocalServers();

  /// Stable identity of [server] — the focus-node key, and what makes a
  /// discovered server matchable against a stored connection.
  String discoveredServerId(S server);

  /// Prefix for focus-node debug labels, e.g. `AddJellyfin`.
  String get discoveryDebugLabel;

  /// Call from `initState`.
  void startLocalDiscovery() => unawaited(_runDiscovery());

  /// Search again, from a control the user pressed.
  ///
  /// Distinct from [startLocalDiscovery] because it has to put the searching
  /// state *back*: a retry that leaves "nothing found" on screen for the two
  /// and a half seconds of the browse looks like a button that does nothing,
  /// which is the reading a user already suspects when the first search
  /// missed.
  void restartLocalDiscovery() {
    if (isDiscoveringLocalServers) return;
    setState(() => isDiscoveringLocalServers = true);
    unawaited(_runDiscovery());
  }

  /// Call from `dispose`, before `super.dispose()`.
  void disposeLocalDiscovery() {
    _attemptId++;
    for (final node in discoveredServerFocusNodes.values) {
      node.dispose();
    }
    discoveredServerFocusNodes.clear();
  }

  Future<void> _runDiscovery() async {
    final attemptId = ++_attemptId;
    try {
      final servers = await discoverLocalServers();
      if (!mounted || attemptId != _attemptId) return;
      setState(() {
        localServers = servers;
        isDiscoveringLocalServers = false;
        _syncFocusNodes(servers);
      });
    } catch (e, st) {
      // Discovery is a convenience: the URL field still works, so a failure
      // here ends the search rather than failing the form.
      appLogger.w('$discoveryDebugLabel local discovery failed', error: e, stackTrace: st);
      if (!mounted || attemptId != _attemptId) return;
      setState(() => isDiscoveringLocalServers = false);
    }
  }

  void _syncFocusNodes(List<S> servers) {
    final ids = {for (final server in servers) discoveredServerId(server)};
    final removed = discoveredServerFocusNodes.keys.where((id) => !ids.contains(id)).toList(growable: false);
    for (final id in removed) {
      discoveredServerFocusNodes.remove(id)?.dispose();
    }
    for (final server in servers) {
      final id = discoveredServerId(server);
      discoveredServerFocusNodes.putIfAbsent(id, () => FocusNode(debugLabel: '$discoveryDebugLabel:Discovered:$id'));
    }
  }

  /// Move focus into the results, or to [fallback] when there are none.
  void focusFirstDiscoveredServerOr(FocusNode fallback) {
    if (localServers.isEmpty) {
      fallback.requestFocus();
      return;
    }
    discoveredServerFocusNodes[discoveredServerId(localServers.first)]?.requestFocus();
  }

  void focusLastDiscoveredServerOr(FocusNode fallback) {
    if (localServers.isEmpty) {
      fallback.requestFocus();
      return;
    }
    discoveredServerFocusNodes[discoveredServerId(localServers.last)]?.requestFocus();
  }

  /// The section as form children: a progress line while searching, nothing at
  /// all when the search found nothing, and otherwise a labelled group of tiles.
  ///
  /// [focusAbove] and [focusBelow] are what the first and last tile hand focus
  /// to, which is why they are required rather than optional — a group of tiles
  /// a D-pad can enter and not leave is worse than no group.
  List<Widget> buildLocalDiscoverySection(
    ThemeData theme, {
    required String searchingLabel,
    required String sectionLabel,
    required FocusNode focusAbove,
    required FocusNode focusBelow,
    required String Function(S server) titleOf,
    required String Function(S server) addressOf,
    required void Function(S server)? onSelected,
    String? Function(S server)? statusOf,
    bool Function(S server)? busyOf,
    bool Function(S server)? enabledOf,
  }) {
    if (isDiscoveringLocalServers) {
      return [
        const SizedBox(height: 16),
        Row(
          children: [
            const LoadingIndicatorBox(size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                searchingLabel,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ];
    }

    if (localServers.isEmpty) return const [];
    final tokensRef = tokens(context);
    return [
      const SizedBox(height: 16),
      Text(sectionLabel, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      for (final (i, server) in localServers.indexed) ...[
        if (i > 0) SizedBox(height: tokensRef.groupGap),
        DiscoveredServerTile(
          title: titleOf(server),
          address: addressOf(server),
          status: statusOf?.call(server),
          busy: busyOf?.call(server) ?? false,
          enabled: enabledOf?.call(server) ?? true,
          borderRadius: groupItemRadii(context, i, localServers.length),
          focusNode: discoveredServerFocusNodes[discoveredServerId(server)],
          onNavigateUp: () =>
              (i <= 0 ? focusAbove : discoveredServerFocusNodes[discoveredServerId(localServers[i - 1])] ?? focusAbove)
                  .requestFocus(),
          onNavigateDown: () =>
              (i >= localServers.length - 1
                      ? focusBelow
                      : discoveredServerFocusNodes[discoveredServerId(localServers[i + 1])] ?? focusBelow)
                  .requestFocus(),
          onTap: onSelected == null ? null : () => onSelected(server),
        ),
      ],
      const SizedBox(height: 8),
    ];
  }
}

/// One row in the "found on this network" list.
///
/// [title] rather than a server object: Jellyfin advertises a name and Music
/// Assistant advertises a version, and neither belongs in a shared widget.
class DiscoveredServerTile extends StatelessWidget {
  final String title;
  final String address;
  final BorderRadius borderRadius;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback? onTap;

  /// Replaces the chevron when set — "Already added", say. A row that can be
  /// tapped and a row that has nothing left to do must not look identical.
  final String? status;

  /// Shows a spinner in place of the chevron while this row's own work runs.
  final bool busy;

  /// False dims the row and drops its tap target, without removing it: a
  /// server that is already added is still worth showing, because its absence
  /// would read as a discovery failure.
  final bool enabled;

  const DiscoveredServerTile({
    super.key,
    required this.title,
    required this.address,
    required this.borderRadius,
    required this.focusNode,
    required this.onNavigateUp,
    required this.onNavigateDown,
    required this.onTap,
    this.status,
    this.busy = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onTapWhenEnabled = enabled && !busy ? onTap : null;
    final dim = theme.colorScheme.onSurface.withValues(alpha: enabled ? 0.7 : 0.4);
    return FocusableWrapper(
      focusNode: focusNode,
      disableScale: true,
      // Border drawn by CardFocusBorder so it paints over the opaque Material.
      delegateFocusBorder: true,
      descendantsAreFocusable: false,
      onSelect: onTapWhenEnabled,
      onNavigateUp: onNavigateUp,
      onNavigateDown: onNavigateDown,
      child: CardFocusBorder(
        borderRadii: borderRadius,
        strokeAlign: BorderSide.strokeAlignInside,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onTapWhenEnabled,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  AppIcon(
                    Symbols.dns_rounded,
                    fill: 1,
                    color: enabled ? null : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      mainAxisSize: .min,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: enabled ? null : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          address,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: dim),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (busy)
                    const LoadingIndicatorBox(size: 16)
                  else if (status != null)
                    Text(status!, style: theme.textTheme.bodySmall?.copyWith(color: dim))
                  else
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
