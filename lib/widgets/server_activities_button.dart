import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../focus/key_event_utils.dart';
import '../i18n/strings.g.dart';
import '../theme/mono_tokens.dart';
import 'package:plezy/widgets/app_icon.dart';
import '../models/plex_activity.dart';
import '../providers/multi_server_provider.dart';

class ServerActivitiesButton extends StatefulWidget {
  const ServerActivitiesButton({super.key});

  @override
  State<ServerActivitiesButton> createState() => _ServerActivitiesButtonState();
}

enum _FetchState { loading, loaded, error }

class _ServerResult {
  final String serverId;
  final String serverName;
  final List<PlexActivity> activities;

  _ServerResult({required this.serverId, required this.serverName, required this.activities});
}

class _PanelData {
  final _FetchState fetchState;
  final List<_ServerResult> results;

  const _PanelData({required this.fetchState, required this.results});

  static const loading = _PanelData(fetchState: _FetchState.loading, results: []);
}

class _ServerActivitiesButtonState extends State<ServerActivitiesButton> {
  final _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  final _panelNotifier = ValueNotifier<_PanelData>(_PanelData.loading);
  Timer? _pollTimer;

  @override
  void deactivate() {
    _removeOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _removeOverlay();
    _panelNotifier.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _togglePanel() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final buttonOffset = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    final right = screenSize.width - (buttonOffset.dx + buttonSize.width);
    final top = buttonOffset.dy + buttonSize.height + 4;

    _panelNotifier.value = _PanelData.loading;
    _overlayEntry = OverlayEntry(
      builder: (ctx) => _buildOverlay(ctx, right: right, top: top),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _fetchActivities();
  }

  Future<List<_ServerResult>> _loadFromServers() async {
    final multiServer = Provider.of<MultiServerProvider>(context, listen: false);
    final serverIds = multiServer.onlineServerIds;

    final futures = serverIds.map((serverId) async {
      final client = multiServer.getClientForServer(serverId);
      if (client == null) return null;
      final activities = await client.getActivities();
      return _ServerResult(serverId: serverId, serverName: client.serverName ?? serverId, activities: activities);
    });

    final rawResults = await Future.wait(futures);
    return rawResults.whereType<_ServerResult>().toList();
  }

  Future<void> _fetchActivities() async {
    try {
      final results = await _loadFromServers();
      if (!mounted) return;
      _panelNotifier.value = _PanelData(fetchState: _FetchState.loaded, results: results);
      _startPolling();
    } catch (_) {
      if (!mounted) return;
      _panelNotifier.value = const _PanelData(fetchState: _FetchState.error, results: []);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (mounted && _overlayEntry != null) {
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _silentRefresh());
    }
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final results = await _loadFromServers();
      if (!mounted) return;
      _panelNotifier.value = _PanelData(fetchState: _FetchState.loaded, results: results);
    } catch (_) {
      // silently ignore poll errors
    }
  }

  Future<void> _cancelActivity(String serverId, String uuid) async {
    final multiServer = Provider.of<MultiServerProvider>(context, listen: false);
    final client = multiServer.getClientForServer(serverId);
    if (client == null) return;
    try {
      await client.cancelActivity(uuid);
    } catch (_) {
      return;
    }
    _pollTimer?.cancel();
    _pollTimer = null;
    _panelNotifier.value = _PanelData.loading;
    _fetchActivities();
  }

  Widget _buildOverlay(BuildContext overlayContext, {required double right, required double top}) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(onTap: _removeOverlay, behavior: HitTestBehavior.opaque),
        ),
        Positioned(
          right: right,
          top: top,
          child: Focus(
            autofocus: true,
            onKeyEvent: (_, event) => handleBackKeyAction(event, _removeOverlay),
            child: ValueListenableBuilder<_PanelData>(
              valueListenable: _panelNotifier,
              builder: (context, data, _) => _buildPanel(context, data),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(BuildContext context, _PanelData data) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPanelHeader(context),
            Divider(height: 1, color: theme.dividerColor),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(child: _buildPanelBody(context, data)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          AppIcon(Symbols.monitor_heart_rounded, size: 18, color: theme.colorScheme.onSurface),
          const SizedBox(width: 8),
          Text(t.serverTasks.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPanelBody(BuildContext context, _PanelData data) {
    final theme = Theme.of(context);

    if (data.fetchState == _FetchState.loading) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            t.common.loading,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
          ),
        ),
      );
    }

    if (data.fetchState == _FetchState.error) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(t.serverTasks.failedToLoad, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    final hasAnyActivities = data.results.any((r) => r.activities.isNotEmpty);
    if (!hasAnyActivities) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            t.serverTasks.noTasks,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final result in data.results)
          if (result.activities.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    result.serverName.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: tokens(context).text, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '${result.activities.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tokens(context).bg,
                        letterSpacing: 0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final activity in result.activities) _buildActivityTile(context, result.serverId, activity),
          ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildActivityTile(BuildContext context, String serverId, PlexActivity activity) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (activity.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    activity.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: activity.progress / 100.0,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 4,
                ),
              ],
            ),
          ),
          if (activity.cancellable)
            IconButton(
              icon: AppIcon(Symbols.close_rounded, size: 16, color: theme.colorScheme.onSurface),
              onPressed: () => _cancelActivity(serverId, activity.uuid),
              visualDensity: VisualDensity.compact,
              tooltip: t.common.cancel,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: _buttonKey,
      icon: const AppIcon(Symbols.monitor_heart_rounded, color: Colors.white),
      onPressed: _togglePanel,
      tooltip: t.serverTasks.title,
    );
  }
}
