import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_icon.dart';

/// Shows a bottom sheet with program details and actions (Record, Watch Channel, Play).
void showProgramDetailsSheet(
  BuildContext context, {
  required LiveTvProgram program,
  required LiveTvChannel? channel,
  required String? posterUrl,
  required VoidCallback? onTuneChannel,
}) {
  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (posterUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      posterUrl,
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
                          Expanded(
                            child: Text(
                              program.displayTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          if (program.isCurrentlyAiring)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.liveTv.live,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
            Row(
              children: [
                if (program.isCurrentlyAiring && onTuneChannel != null)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onTuneChannel();
                    },
                    icon: const AppIcon(Symbols.play_arrow_rounded),
                    label: Text(t.common.play),
                  ),
                if (program.isCurrentlyAiring) const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    // TODO: Record action
                  },
                  icon: const AppIcon(Symbols.fiber_manual_record_rounded),
                  label: Text(t.liveTv.record),
                ),
                if (!program.isCurrentlyAiring && onTuneChannel != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onTuneChannel();
                    },
                    icon: const AppIcon(Symbols.live_tv_rounded),
                    label: Text(t.liveTv.watchChannel),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    },
  );
}
