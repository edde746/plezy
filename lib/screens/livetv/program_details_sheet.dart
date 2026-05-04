import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_server_client.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../models/media_subscription.dart';
import '../../services/image_cache_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/optimized_media_image.dart' show blurArtwork;
import 'livetv_recording_actions.dart';

/// Shows a bottom sheet with program details and actions (Play / Watch Channel /
/// Record / Manage recording).
///
/// [client] is the resolved [MediaServerClient] for the program's owning server.
/// Recording affordances appear only when the client supports DVR
/// (`capabilities.liveTvDvr`) and the program has a recordable guid.
void showProgramDetailsSheet(
  BuildContext context, {
  required LiveTvProgram program,
  required LiveTvChannel? channel,
  required String? posterUrl,
  required VoidCallback? onTuneChannel,
  MediaServerClient? client,
}) {
  OverlaySheetController.showAdaptive(
    context,
    builder: (sheetContext) {
      return _ProgramDetailsSheetContent(
        program: program,
        channel: channel,
        posterUrl: posterUrl,
        onTuneChannel: onTuneChannel,
        client: client,
      );
    },
  );
}

enum _ActionStyle { filled, outlined }

class _SheetAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final _ActionStyle style;

  const _SheetAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.style = _ActionStyle.outlined,
  });
}

class _ProgramDetailsSheetContent extends StatefulWidget {
  final LiveTvProgram program;
  final LiveTvChannel? channel;
  final String? posterUrl;
  final VoidCallback? onTuneChannel;
  final MediaServerClient? client;

  const _ProgramDetailsSheetContent({
    required this.program,
    required this.channel,
    required this.posterUrl,
    required this.onTuneChannel,
    required this.client,
  });

  @override
  State<_ProgramDetailsSheetContent> createState() => _ProgramDetailsSheetContentState();
}

class _ProgramDetailsSheetContentState extends State<_ProgramDetailsSheetContent> {
  final List<FocusNode> _focusNodes = [];
  MediaSubscription? _existingSubscription;
  bool _checkedMapping = false;

  bool get _canRecord {
    final client = widget.client;
    if (client == null) return false;
    if (!client.capabilities.liveTvDvr) return false;
    final guid = widget.program.guid;
    return guid != null && guid.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (_canRecord) {
      _loadMapping();
    } else {
      _checkedMapping = true;
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMapping() async {
    final client = widget.client;
    final providerId = widget.program.providerIdentifier;
    final ratingKey = widget.program.ratingKey;
    if (client == null || providerId == null || providerId.isEmpty || ratingKey == null || ratingKey.isEmpty) {
      if (mounted) setState(() => _checkedMapping = true);
      return;
    }
    try {
      final mapped = await client.liveTv.fetchSubscriptionMapping(providerId: providerId, ratingKeys: [ratingKey]);
      final match = mapped.where((s) => s.key.isNotEmpty).firstOrNull;
      if (!mounted) return;
      setState(() {
        _existingSubscription = match;
        _checkedMapping = true;
      });
    } catch (e) {
      // 403 (no DVR access) or transient — treat as unscheduled.
      appLogger.d('Subscription mapping check failed: $e');
      if (mounted) setState(() => _checkedMapping = true);
    }
  }

  void _ensureFocusNodes(int needed) {
    while (_focusNodes.length < needed) {
      _focusNodes.add(FocusNode(debugLabel: 'program_sheet_btn_${_focusNodes.length}'));
    }
    while (_focusNodes.length > needed) {
      _focusNodes.removeLast().dispose();
    }
  }

  void _focusButton(int index) {
    if (index >= 0 && index < _focusNodes.length) {
      _focusNodes[index].requestFocus();
    }
  }

  void _closeSheet() => OverlaySheetController.closeAdaptive(context);

  List<_SheetAction> _buildActions() {
    final program = widget.program;
    final client = widget.client;
    final actions = <_SheetAction>[];

    if (widget.onTuneChannel != null) {
      final isLive = program.isCurrentlyAiring;
      actions.add(
        _SheetAction(
          label: isLive ? t.common.play : t.liveTv.watchChannel,
          icon: isLive ? Symbols.play_arrow_rounded : Symbols.live_tv_rounded,
          style: isLive ? _ActionStyle.filled : _ActionStyle.outlined,
          onPressed: () {
            _closeSheet();
            widget.onTuneChannel!();
          },
        ),
      );
    }

    if (_canRecord && client != null && _checkedMapping) {
      final existing = _existingSubscription;
      if (existing != null) {
        actions.add(
          _SheetAction(
            label: t.liveTv.manageRecording,
            icon: Symbols.fiber_manual_record_rounded,
            style: _ActionStyle.filled,
            onPressed: () async {
              final deleted = await confirmDeleteRule(context, client, existing);
              if (deleted && mounted) _closeSheet();
            },
          ),
        );
      } else {
        actions.add(
          _SheetAction(
            label: t.liveTv.record,
            icon: Symbols.fiber_manual_record_rounded,
            style: _ActionStyle.filled,
            onPressed: () async {
              final outcome = await recordProgram(context, client, program);
              if (!mounted) return;
              if (outcome == RecordOutcome.scheduled || outcome == RecordOutcome.alreadyScheduled) {
                _closeSheet();
              }
            },
          ),
        );
      }
    }

    return actions;
  }

  Widget _buildButton(_SheetAction action, int index, int total) {
    final node = _focusNodes[index];
    final child = action.style == _ActionStyle.filled
        ? FilledButton.icon(
            style: FilledButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: action.onPressed,
            icon: AppIcon(action.icon),
            label: Text(action.label),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: action.onPressed,
            icon: AppIcon(action.icon),
            label: Text(action.label),
          );

    return FocusableButton(
      focusNode: node,
      onPressed: action.onPressed,
      onNavigateLeft: index > 0 ? () => _focusButton(index - 1) : null,
      onNavigateRight: index < total - 1 ? () => _focusButton(index + 1) : null,
      onBack: _closeSheet,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final program = widget.program;
    final channel = widget.channel;
    final actions = _buildActions();
    _ensureFocusNodes(actions.length);

    final buttons = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0) buttons.add(const SizedBox(width: 8));
      buttons.add(_buildButton(actions[i], i, actions.length));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.posterUrl != null) ...[
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  child: blurArtwork(
                    CachedNetworkImage(
                      imageUrl: widget.posterUrl!,
                      cacheManager: PlexImageCacheManager.instance,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      memCacheHeight: (120 * MediaQuery.devicePixelRatioOf(context)).round(),
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(program.displayTitle, style: theme.textTheme.titleMedium)),
                        if (program.isCurrentlyAiring)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                            ),
                            child: Text(
                              t.liveTv.live,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (channel != null) channel.displayName,
                        if (program.startTime != null && program.endTime != null)
                          '${formatClockTime(program.startTime!, is24Hour: MediaQuery.alwaysUse24HourFormatOf(context))} - ${formatClockTime(program.endTime!, is24Hour: MediaQuery.alwaysUse24HourFormatOf(context))}',
                        if (program.durationMinutes > 0) formatDurationTextual(program.durationMinutes * 60000),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    if (program.summary != null && program.summary!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        program.summary!,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (buttons.isNotEmpty) Row(children: buttons),
        ],
      ),
    );
  }
}
