import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../providers/multi_server_provider.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/formatters.dart';
import '../../utils/live_tv_player_navigation.dart';
import '../../utils/plex_image_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';

/// Shows all upcoming airings of a show, matching the Plex "upcoming episodes" view.
class LiveTvShowScheduleScreen extends StatefulWidget {
  /// The show title to filter for (grandparentTitle for episodes, title for movies).
  final String showTitle;

  /// Server ID to scope the EPG query.
  final String serverId;

  /// Full channel list for tuning.
  final List<LiveTvChannel> channels;

  const LiveTvShowScheduleScreen({
    super.key,
    required this.showTitle,
    required this.serverId,
    required this.channels,
  });

  @override
  State<LiveTvShowScheduleScreen> createState() => _LiveTvShowScheduleScreenState();
}

class _LiveTvShowScheduleScreenState extends State<LiveTvShowScheduleScreen> {
  List<LiveTvProgram> _programs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(widget.serverId);
    if (client == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now();
    // Fetch a generous window: 1h ago (to catch currently airing) + 48h ahead
    final beginsAt = now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    final endsAt = now.add(const Duration(hours: 48)).millisecondsSinceEpoch ~/ 1000;

    final programs = await client.getEpgGrid(beginsAt: beginsAt, endsAt: endsAt);

    // Filter for this show
    final filtered = programs.where((p) {
      if (p.grandparentTitle == widget.showTitle) return true;
      if (p.grandparentTitle == null && p.title == widget.showTitle) return true;
      return false;
    }).toList();

    // Sort by start time
    filtered.sort((a, b) => (a.beginsAt ?? 0).compareTo(b.beginsAt ?? 0));

    if (mounted) {
      setState(() {
        _programs = filtered;
        _isLoading = false;
      });
    }
  }

  LiveTvChannel? _findChannel(String? channelIdentifier) {
    if (channelIdentifier == null) return null;
    return widget.channels.where((ch) {
      return ch.identifier == channelIdentifier || ch.key == channelIdentifier;
    }).firstOrNull;
  }

  Future<void> _tuneChannel(LiveTvChannel channel) async {
    final multiServer = context.read<MultiServerProvider>();
    final serverInfo = multiServer.liveTvServers
            .where((s) => s.serverId == channel.serverId)
            .firstOrNull ??
        multiServer.liveTvServers.firstOrNull;
    if (serverInfo == null) return;

    final client = multiServer.getClientForServer(serverInfo.serverId);
    if (client == null) return;

    await navigateToLiveTv(
      context,
      client: client,
      dvrKey: serverInfo.dvrKey,
      channel: channel,
      channels: widget.channels,
    );
  }

  void _showProgramDetails(LiveTvProgram program, LiveTvChannel? channel) {
    final theme = Theme.of(context);

    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(widget.serverId);
    String? posterUrl;
    if (program.thumb != null && client != null) {
      posterUrl = PlexImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: program.thumb,
        maxWidth: 80,
        maxHeight: 120,
        devicePixelRatio: PlexImageHelper.effectiveDevicePixelRatio(context),
        imageType: ImageType.poster,
      );
    }

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
                  if (program.isCurrentlyAiring && channel != null)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _tuneChannel(channel);
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
                  if (!program.isCurrentlyAiring && channel != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _tuneChannel(channel);
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

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Text(widget.showTitle),
      slivers: [
        if (_isLoading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (_programs.isEmpty)
          SliverFillRemaining(child: Center(child: Text(t.liveTv.noPrograms)))
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final program = _programs[index];
                final channel = _findChannel(program.channelIdentifier);
                return _ScheduleListTile(
                  program: program,
                  channel: channel,
                  onTap: () {
                    if (program.isCurrentlyAiring && channel != null) {
                      _tuneChannel(channel);
                    } else {
                      _showProgramDetails(program, channel);
                    }
                  },
                );
              },
              childCount: _programs.length,
            ),
          ),
      ],
    );
  }
}

class _ScheduleListTile extends StatelessWidget {
  final LiveTvProgram program;
  final LiveTvChannel? channel;
  final VoidCallback onTap;

  const _ScheduleListTile({
    required this.program,
    required this.channel,
    required this.onTap,
  });

  String _formatTimeInfo() {
    final now = DateTime.now();
    final start = program.startTime;
    final end = program.endTime;
    if (start == null) return '';

    if (program.isCurrentlyAiring && end != null) {
      final minutesLeft = end.difference(now).inMinutes;
      return '${minutesLeft}min left';
    }

    final minutesUntil = start.difference(now).inMinutes;
    if (minutesUntil <= 0) {
      // Just started
      return _formatAbsoluteTime(start, now);
    } else if (minutesUntil < 90) {
      return 'Starting in ${minutesUntil}min';
    } else {
      return _formatAbsoluteTime(start, now);
    }
  }

  String _formatAbsoluteTime(DateTime start, DateTime now) {
    final time = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final diff = startDay.difference(today).inDays;

    if (diff == 0) return 'Today at $time';
    if (diff == 1) return 'Tomorrow at $time';
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][start.weekday - 1];
    return '$weekday at $time';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = program.isCurrentlyAiring;

    // Title line: S#·E# — Episode Title, or just Title for non-episodes
    String titleText;
    if (program.parentIndex != null && program.index != null) {
      titleText = 'S${program.parentIndex} · E${program.index} — ${program.title}';
    } else {
      titleText = program.title;
    }

    final timeInfo = _formatTimeInfo();
    final subtitle = [
      timeInfo,
      if (program.summary != null && program.summary!.isNotEmpty) program.summary!,
    ].join(' — ');

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: isLive
            ? BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                border: Border(
                  left: BorderSide(color: theme.colorScheme.primary, width: 3),
                ),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titleText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLive) ...[
                  const SizedBox(width: 8),
                  AppIcon(Symbols.play_circle_rounded,
                      size: 20, color: theme.colorScheme.primary),
                ],
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens(context).textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (channel != null) ...[
              const SizedBox(height: 2),
              Text(
                channel!.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens(context).textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
