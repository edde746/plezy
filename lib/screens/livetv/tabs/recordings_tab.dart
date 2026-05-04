import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../exceptions/media_server_exceptions.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/media_server_client.dart';
import '../../../models/livetv_program.dart';
import '../../../models/media_grab_operation.dart';
import '../../../models/media_subscription.dart';
import '../../../providers/multi_server_provider.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/dialogs.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/overlay_sheet.dart';
import '../livetv_recording_actions.dart';

class RecordingsTab extends StatefulWidget {
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  const RecordingsTab({super.key, this.onNavigateUp, this.onBack});

  @override
  State<RecordingsTab> createState() => RecordingsTabState();
}

class _ServerRecordings {
  final String serverId;
  final MediaServerClient client;
  final List<MediaGrabOperation> grabs;
  final List<MediaSubscription> rules;

  const _ServerRecordings({required this.serverId, required this.client, required this.grabs, required this.rules});
}

class _GrabEntry {
  final _ServerRecordings server;
  final MediaGrabOperation op;

  const _GrabEntry(this.server, this.op);
}

class _RuleEntry {
  final _ServerRecordings server;
  final MediaSubscription rule;

  const _RuleEntry(this.server, this.rule);
}

enum _RuleAction { edit, delete }

class RecordingsTabState extends State<RecordingsTab> {
  List<_ServerRecordings> _serverRecordings = [];
  bool _isLoading = true;
  bool _adminBlocked = false;
  String? _error;
  Timer? _refreshTimer;
  bool _pendingFocus = false;
  final _firstTileFocusNode = FocusNode(debugLabel: 'recordings_tab_first_tile');

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _firstTileFocusNode.dispose();
    super.dispose();
  }

  void focusContent() {
    if (_isLoading) {
      _pendingFocus = true;
      return;
    }
    _pendingFocus = false;
    if (_firstTileFocusNode.context != null) {
      _firstTileFocusNode.requestFocus();
    }
  }

  void pauseRefresh() => _refreshTimer?.cancel();

  void resumeRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _load();
    });
    _load();
  }

  /// Public reload helper for the parent screen's refresh action.
  Future<void> reload() => _load();

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = _serverRecordings.isEmpty;
      _error = null;
    });

    final multiServer = context.read<MultiServerProvider>();
    final results = <_ServerRecordings>[];
    var anyAdminError = false;
    var anyOtherError = false;
    final seenServers = <String>{};

    for (final serverInfo in multiServer.liveTvServers) {
      if (!seenServers.add(serverInfo.serverId)) continue;
      final client = multiServer.getClientForServer(serverInfo.serverId);
      if (client == null) continue;
      if (!client.capabilities.liveTvDvr) continue;
      try {
        final grabs = await client.liveTv.fetchScheduledRecordings();
        final rules = await client.liveTv.fetchRecordingRules();
        results.add(_ServerRecordings(serverId: serverInfo.serverId, client: client, grabs: grabs, rules: rules));
      } catch (e) {
        appLogger.e('Failed to load recordings for ${serverInfo.serverId}', error: e);
        if (e is MediaServerHttpException && e.statusCode == 403) {
          anyAdminError = true;
        } else {
          anyOtherError = true;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _serverRecordings = results;
      _isLoading = false;
      _adminBlocked = results.isEmpty && anyAdminError;
      _error = (results.isEmpty && anyOtherError && !anyAdminError) ? t.liveTv.recordingFailed : null;
    });
    if (_pendingFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focusContent();
      });
    }
  }

  List<_GrabEntry> get _allGrabs {
    final entries = <_GrabEntry>[
      for (final server in _serverRecordings)
        for (final op in server.grabs) _GrabEntry(server, op),
    ];
    entries.sort((a, b) {
      final aStart = a.op.program?.beginsAt ?? 0;
      final bStart = b.op.program?.beginsAt ?? 0;
      return aStart.compareTo(bStart);
    });
    return entries;
  }

  List<_RuleEntry> get _allRules {
    final entries = <_RuleEntry>[
      for (final server in _serverRecordings)
        for (final rule in server.rules) _RuleEntry(server, rule),
    ];
    entries.sort((a, b) {
      final aType = a.rule.type ?? 0;
      final bType = b.rule.type ?? 0;
      // Series first (type 2), then episodes (type 4)
      final typeCompare = aType.compareTo(bType);
      if (typeCompare != 0) return typeCompare;
      return (a.rule.title ?? '').compareTo(b.rule.title ?? '');
    });
    return entries;
  }

  Future<void> _onCancelGrab(_GrabEntry entry) async {
    final cancelled = await confirmCancelGrab(context, entry.server.client, entry.op);
    if (cancelled) await _load();
  }

  Future<void> _onRuleTap(_RuleEntry entry) async {
    final action = await showOptionPickerDialog<_RuleAction>(
      context,
      title: entry.rule.title ?? '',
      options: [
        (icon: Symbols.edit_rounded, label: t.liveTv.editRuleAction, value: _RuleAction.edit),
        (icon: Symbols.delete_rounded, label: t.common.delete, value: _RuleAction.delete),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case _RuleAction.edit:
        final outcome = await editRecordingRule(context, entry.server.client, entry.rule);
        if (outcome == RecordOutcome.updated) await _load();
      case _RuleAction.delete:
        final deleted = await confirmDeleteRule(context, entry.server.client, entry.rule);
        if (deleted) await _load();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_serverRecordings.isEmpty && _adminBlocked) {
      return Center(child: _EmptyMessage(text: t.liveTv.dvrAdminRequired));
    }
    if (_serverRecordings.isEmpty && _error != null) {
      return Center(child: _EmptyMessage(text: _error!));
    }

    final grabs = _allGrabs;
    final rules = _allRules;

    if (grabs.isEmpty && rules.isEmpty) {
      return Center(child: _EmptyMessage(text: t.liveTv.noScheduledRecordings));
    }

    return OverlaySheetHost(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (grabs.isNotEmpty) ...[
            _SectionHeader(t.liveTv.scheduledRecordings),
            for (var i = 0; i < grabs.length; i++)
              _GrabTile(
                entry: grabs[i],
                autofocus: i == 0,
                focusNode: i == 0 ? _firstTileFocusNode : null,
                onTap: () => _onCancelGrab(grabs[i]),
                onNavigateUp: i == 0 ? widget.onNavigateUp : null,
                onBack: widget.onBack,
              ),
          ],
          if (rules.isNotEmpty) ...[
            _SectionHeader(t.liveTv.recordingRules),
            for (var i = 0; i < rules.length; i++)
              _RuleTile(
                entry: rules[i],
                autofocus: grabs.isEmpty && i == 0,
                focusNode: grabs.isEmpty && i == 0 ? _firstTileFocusNode : null,
                onTap: () => _onRuleTap(rules[i]),
                onNavigateUp: grabs.isEmpty && i == 0 ? widget.onNavigateUp : null,
                onBack: widget.onBack,
              ),
          ],
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;

  const _EmptyMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(Symbols.fiber_manual_record_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _GrabTile extends StatelessWidget {
  final _GrabEntry entry;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback onTap;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  const _GrabTile({
    required this.entry,
    required this.autofocus,
    this.focusNode,
    required this.onTap,
    this.onNavigateUp,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final program = entry.op.program;
    final status = entry.op.status ?? 'scheduled';
    final isRecording = status == 'grabbing';
    final isError = status == 'error';

    final title = program?.displayTitle ?? entry.op.key ?? '';
    final timeStr = _formatTime(program, MediaQuery.alwaysUse24HourFormatOf(context));
    final subtitle = [
      if (timeStr.isNotEmpty) timeStr,
      if (program?.channelCallSign != null && program!.channelCallSign!.isNotEmpty) program.channelCallSign!,
    ].join(' · ');

    return FocusableWrapper(
      autofocus: autofocus,
      focusNode: focusNode,
      autoScroll: true,
      useBackgroundFocus: true,
      disableScale: true,
      onSelect: onTap,
      onNavigateUp: onNavigateUp,
      onBack: onBack,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        child: Container(
          decoration: isRecording
              ? BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: tokens(context).textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isRecording)
                _StatusBadge(label: t.liveTv.recordingInProgress, color: theme.colorScheme.primary)
              else if (isError)
                _StatusBadge(label: t.common.error, color: theme.colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(LiveTvProgram? program, bool is24Hour) {
    if (program == null) return '';
    final start = program.startTime;
    final end = program.endTime;
    if (start == null) return '';
    final clock = formatClockTime(start, is24Hour: is24Hour);
    final dayLabel = formatRelativeDayLabel(start);
    final duration = end != null ? formatDurationTextual(end.difference(start).inMilliseconds) : '';
    return [dayLabel, clock, if (duration.isNotEmpty) duration].join(' · ');
  }
}

class _RuleTile extends StatelessWidget {
  final _RuleEntry entry;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback onTap;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  const _RuleTile({
    required this.entry,
    required this.autofocus,
    this.focusNode,
    required this.onTap,
    this.onNavigateUp,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rule = entry.rule;
    final title = rule.title ?? '';
    final isSeries = rule.type == 2;
    final subtitleParts = <String>[
      if (isSeries) t.liveTv.recordSeries else t.liveTv.recordEpisode,
      if (rule.airingsType != null && rule.airingsType!.isNotEmpty) rule.airingsType!,
      if (rule.grabOperations.isNotEmpty) t.liveTv.recordingsCount(count: rule.grabOperations.length.toString()),
    ];

    return FocusableWrapper(
      autofocus: autofocus,
      focusNode: focusNode,
      autoScroll: true,
      useBackgroundFocus: true,
      disableScale: true,
      onSelect: onTap,
      onNavigateUp: onNavigateUp,
      onBack: onBack,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitleParts.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitleParts.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(color: tokens(context).textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.all(Radius.circular(4))),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
