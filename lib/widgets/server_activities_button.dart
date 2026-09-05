import 'dart:async';
import '../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../exceptions/media_server_exceptions.dart';
import '../focus/back_press.dart';
import '../i18n/strings.g.dart';
import '../theme/mono_tokens.dart';
import 'package:plezy/widgets/app_icon.dart';
import '../models/plex/plex_activity.dart';
import '../providers/multi_server_provider.dart';
import '../utils/media_server_http_client.dart';

class ServerActivitiesButton extends StatefulWidget {
  const ServerActivitiesButton({super.key});

  @override
  State<ServerActivitiesButton> createState() => ServerActivitiesButtonState();
}

enum _FetchState { loading, loaded, error }

class _ServerResult {
  final String serverId;
  final String serverName;
  final List<PlexActivity> activities;

  const _ServerResult({required this.serverId, required this.serverName, required this.activities});
}

class _PanelData {
  final _FetchState fetchState;
  final List<_ServerResult> results;

  const _PanelData({required this.fetchState, required this.results});

  static const loading = _PanelData(fetchState: _FetchState.loading, results: []);
}

class ServerActivitiesButtonState extends State<ServerActivitiesButton> {
  final _buttonKey = GlobalKey();
  final _backGate = BackPressGate();
  OverlayEntry? _overlayEntry;
  final _panelNotifier = ValueNotifier<_PanelData>(_PanelData.loading);
  Timer? _pollTimer;
  AbortController? _activeLoadAbort;
  int _loadGeneration = 0;

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
    _loadGeneration++;
    final activeLoadAbort = _activeLoadAbort;
    _activeLoadAbort = null;
    activeLoadAbort?.abort();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void togglePanel() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final buttonOffset = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final screenSize = MediaQuery.sizeOf(context);

    final right = screenSize.width - (buttonOffset.dx + buttonSize.width);
    final top = buttonOffset.dy + buttonSize.height + 4;

    _panelNotifier.value = _PanelData.loading;
    _overlayEntry = OverlayEntry(
      builder: (_) => _buildOverlay(right: right, top: top),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _startRefresh(silent: false);
  }

  Future<List<_ServerResult>> _loadFromServers(AbortController abort) async {
    final multiServer = Provider.of<MultiServerProvider>(context, listen: false);
    final serverIds = multiServer.onlineServerIds;

    final futures = serverIds.map((serverId) async {
      // Plex-only: `/activities` API is Plex-specific.
      final client = multiServer.getPlexClientForServer(ServerId(serverId));
      if (client == null) return null;
      final activities = await client.getActivities(abort: abort);
      return _ServerResult(serverId: serverId, serverName: client.serverName ?? serverId, activities: activities);
    });

    final rawResults = await Future.wait(futures);
    return rawResults.whereType<_ServerResult>().toList();
  }

  void _startRefresh({required bool silent}) {
    if (!mounted || _overlayEntry == null) return;

    _pollTimer?.cancel();
    _pollTimer = null;
    final generation = ++_loadGeneration;
    final supersededAbort = _activeLoadAbort;
    final abort = AbortController();
    _activeLoadAbort = abort;
    supersededAbort?.abort();

    if (!silent) {
      _panelNotifier.value = _PanelData.loading;
    }
    unawaited(_runRefresh(generation: generation, abort: abort, silent: silent));
  }

  Future<void> _runRefresh({required int generation, required AbortController abort, required bool silent}) async {
    var scheduleNext = false;
    try {
      final results = await _loadFromServers(abort);
      if (!_ownsLoad(generation, abort)) return;
      _panelNotifier.value = _PanelData(fetchState: _FetchState.loaded, results: results);
      scheduleNext = true;
    } on MediaServerHttpException catch (error) {
      if (error.isCancellation || !_ownsLoad(generation, abort)) return;
      if (silent) {
        scheduleNext = true;
      } else {
        _panelNotifier.value = const _PanelData(fetchState: _FetchState.error, results: []);
      }
    } catch (_) {
      if (!_ownsLoad(generation, abort)) return;
      if (silent) {
        scheduleNext = true;
      } else {
        _panelNotifier.value = const _PanelData(fetchState: _FetchState.error, results: []);
      }
    } finally {
      if (identical(_activeLoadAbort, abort)) {
        _activeLoadAbort = null;
        if (scheduleNext && _isCurrentGeneration(generation)) {
          _schedulePoll(generation);
        }
      }
    }
  }

  bool _ownsLoad(int generation, AbortController abort) {
    return _isCurrentGeneration(generation) && identical(_activeLoadAbort, abort);
  }

  bool _isCurrentGeneration(int generation) {
    return mounted && _overlayEntry != null && _loadGeneration == generation;
  }

  void _schedulePoll(int generation) {
    _pollTimer?.cancel();
    if (!_isCurrentGeneration(generation)) return;
    _pollTimer = Timer(const Duration(seconds: 3), () {
      if (!_isCurrentGeneration(generation)) return;
      _pollTimer = null;
      _startRefresh(silent: true);
    });
  }

  Future<void> _cancelActivity(ServerId serverId, String uuid) async {
    final multiServer = Provider.of<MultiServerProvider>(context, listen: false);
    // Plex-only: `/activities` API is Plex-specific.
    final client = multiServer.getPlexClientForServer(serverId);
    if (client == null) return;
    try {
      await client.cancelActivity(uuid);
    } catch (_) {
      return;
    }
    if (!mounted || _overlayEntry == null) return;
    _startRefresh(silent: false);
  }

  Widget _buildOverlay({required double right, required double top}) {
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
            onKeyEvent: (_, event) => _backGate.handle(event, _removeOverlay),
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
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          AppIcon(Symbols.monitor_heart_rounded, size: 18, color: theme.colorScheme.onSurface),
          const SizedBox(width: 8),
          Text(t.serverTasks.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: .bold)),
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
          mainAxisSize: .min,
          children: [
            AppIcon(Symbols.error_outline_rounded, color: theme.colorScheme.error),
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
      crossAxisAlignment: .stretch,
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
                        fontWeight: .bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final activity in result.activities) _buildActivityTile(context, ServerId(result.serverId), activity),
          ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildActivityTile(BuildContext context, ServerId serverId, PlexActivity activity) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  activity.title,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: .w500),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
                if (activity.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    activity.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
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
      onPressed: togglePanel,
      tooltip: t.serverTasks.title,
    );
  }
}
