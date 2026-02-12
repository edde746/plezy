import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_bottom_sheet.dart';

/// Shows a bottom sheet with program details and actions (Record, Watch Channel, Play).
void showProgramDetailsSheet(
  BuildContext context, {
  required LiveTvProgram program,
  required LiveTvChannel? channel,
  required String? posterUrl,
  required VoidCallback? onTuneChannel,
}) {
  showModalBottomSheet(
    context: context,
    builder: (sheetContext) {
      return _ProgramDetailsSheetContent(
        program: program,
        channel: channel,
        posterUrl: posterUrl,
        onTuneChannel: onTuneChannel,
      );
    },
  );
}

class _ProgramDetailsSheetContent extends StatefulWidget {
  final LiveTvProgram program;
  final LiveTvChannel? channel;
  final String? posterUrl;
  final VoidCallback? onTuneChannel;

  const _ProgramDetailsSheetContent({
    required this.program,
    required this.channel,
    required this.posterUrl,
    required this.onTuneChannel,
  });

  @override
  State<_ProgramDetailsSheetContent> createState() => _ProgramDetailsSheetContentState();
}

class _ProgramDetailsSheetContentState extends State<_ProgramDetailsSheetContent> {
  final List<FocusNode> _buttonFocusNodes = [];

  FocusNode get _initialFocusNode => _buttonFocusNodes.isNotEmpty ? _buttonFocusNodes.first : FocusNode();

  @override
  void initState() {
    super.initState();
    _buildButtonFocusNodes();
  }

  @override
  void dispose() {
    for (final node in _buttonFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _buildButtonFocusNodes() {
    int count = 0;
    if (widget.program.isCurrentlyAiring && widget.onTuneChannel != null) count++;
    // TODO: Implement recording
    // count++; // Record button
    if (!widget.program.isCurrentlyAiring && widget.onTuneChannel != null) count++;

    for (int i = 0; i < count; i++) {
      _buttonFocusNodes.add(FocusNode(debugLabel: 'program_sheet_btn_$i'));
    }
  }

  void _focusButton(int index) {
    if (index >= 0 && index < _buttonFocusNodes.length) {
      _buttonFocusNodes[index].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final program = widget.program;
    final channel = widget.channel;

    // Build the list of action buttons with their focus wrappers
    final buttons = <Widget>[];
    int buttonIndex = 0;

    if (program.isCurrentlyAiring && widget.onTuneChannel != null) {
      final idx = buttonIndex;
      buttons.add(
        FocusableWrapper(
          focusNode: _buttonFocusNodes[idx],
          onSelect: () {
            Navigator.of(context).pop();
            widget.onTuneChannel!();
          },
          onNavigateLeft: idx > 0 ? () => _focusButton(idx - 1) : null,
          onNavigateRight: idx < _buttonFocusNodes.length - 1 ? () => _focusButton(idx + 1) : null,
          onBack: () => Navigator.of(context).pop(),
          borderRadius: 100,
          useBackgroundFocus: true,
          disableScale: true,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onTuneChannel!();
            },
            icon: const AppIcon(Symbols.play_arrow_rounded),
            label: Text(t.common.play),
          ),
        ),
      );
      buttonIndex++;
    }

    // TODO: Implement recording
    // if (program.isCurrentlyAiring && widget.onTuneChannel != null) {
    //   buttons.add(const SizedBox(width: 8));
    // }
    // // Record button
    // {
    //   final idx = buttonIndex;
    //   buttons.add(
    //     FocusableWrapper(
    //       focusNode: _buttonFocusNodes[idx],
    //       onSelect: () {
    //         Navigator.of(context).pop();
    //       },
    //       onNavigateLeft: idx > 0 ? () => _focusButton(idx - 1) : null,
    //       onNavigateRight: idx < _buttonFocusNodes.length - 1 ? () => _focusButton(idx + 1) : null,
    //       onBack: () => Navigator.of(context).pop(),
    //       borderRadius: 100,
    //       useBackgroundFocus: true,
    //       disableScale: true,
    //       child: OutlinedButton.icon(
    //         style: OutlinedButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    //         onPressed: () {
    //           Navigator.of(context).pop();
    //         },
    //         icon: const AppIcon(Symbols.fiber_manual_record_rounded),
    //         label: Text(t.liveTv.record),
    //       ),
    //     ),
    //   );
    //   buttonIndex++;
    // }

    if (!program.isCurrentlyAiring && widget.onTuneChannel != null) {
      buttons.add(const SizedBox(width: 8));
      final idx = buttonIndex;
      buttons.add(
        FocusableWrapper(
          focusNode: _buttonFocusNodes[idx],
          onSelect: () {
            Navigator.of(context).pop();
            widget.onTuneChannel!();
          },
          onNavigateLeft: idx > 0 ? () => _focusButton(idx - 1) : null,
          onNavigateRight: idx < _buttonFocusNodes.length - 1 ? () => _focusButton(idx + 1) : null,
          onBack: () => Navigator.of(context).pop(),
          borderRadius: 100,
          useBackgroundFocus: true,
          disableScale: true,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onTuneChannel!();
            },
            icon: const AppIcon(Symbols.live_tv_rounded),
            label: Text(t.liveTv.watchChannel),
          ),
        ),
      );
      buttonIndex++;
    }

    return FocusableBottomSheet(
      initialFocusNode: _initialFocusNode,
      child: Padding(
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
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      widget.posterUrl!,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
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
                            '${program.startTime!.hour.toString().padLeft(2, '0')}:${program.startTime!.minute.toString().padLeft(2, '0')} - ${program.endTime!.hour.toString().padLeft(2, '0')}:${program.endTime!.minute.toString().padLeft(2, '0')}',
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
            Row(children: buttons),
          ],
        ),
      ),
    );
  }
}
