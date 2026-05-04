import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_action_bar.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../providers/multi_server_provider.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/overlay_sheet.dart';
import 'live_tv_actions_mixin.dart';
import 'livetv_recording_actions.dart';

/// Shows all upcoming airings of a show, matching the Plex "upcoming episodes" view.
class LiveTvShowScheduleScreen extends StatefulWidget {
  /// The show title to filter for (grandparentTitle for episodes, title for movies).
  final String showTitle;

  /// Server ID to scope the EPG query.
  final String serverId;

  /// Full channel list for tuning.
  final List<LiveTvChannel> channels;

  const LiveTvShowScheduleScreen({super.key, required this.showTitle, required this.serverId, required this.channels});

  @override
  State<LiveTvShowScheduleScreen> createState() => _LiveTvShowScheduleScreenState();
}

class _LiveTvShowScheduleScreenState extends State<LiveTvShowScheduleScreen>
    with LiveTvActionsMixin<LiveTvShowScheduleScreen> {
  List<LiveTvProgram> _programs = [];
  bool _isLoading = true;

  @override
  List<LiveTvChannel> get liveTvChannels => widget.channels;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final multiServer = context.read<MultiServerProvider>();
    final genericClient = multiServer.getClientForServer(widget.serverId);
    if (genericClient == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now();
    // Fetch a generous window: 1h ago (to catch currently airing) + 48h ahead
    final beginsAt = now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    final endsAt = now.add(const Duration(hours: 48)).millisecondsSinceEpoch ~/ 1000;

    final fromDt = DateTime.fromMillisecondsSinceEpoch(beginsAt * 1000, isUtc: true);
    final toDt = DateTime.fromMillisecondsSinceEpoch(endsAt * 1000, isUtc: true);
    final programs = await genericClient.liveTv.fetchSchedule(from: fromDt, to: toDt);

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

  /// Resolve the owning client from the [MultiServerProvider]. The show
  /// schedule screen is opened with a single [serverId], so no per-program
  /// lookup is needed.
  bool get _canRecord {
    final client = context.read<MultiServerProvider>().getClientForServer(widget.serverId);
    return client != null && client.capabilities.liveTvDvr;
  }

  Future<void> _onRecordShow() async {
    final client = context.read<MultiServerProvider>().getClientForServer(widget.serverId);
    if (client == null) return;
    // Use the first program with a guid as the seed for `getSubscriptionTemplate`.
    // The template returned by Plex includes both episode-level and series-level
    // entries, so the user can still pick "Record Series" inside the options sheet.
    LiveTvProgram? seed;
    for (final p in _programs) {
      if (p.guid != null && p.guid!.isNotEmpty) {
        seed = p;
        break;
      }
    }
    if (seed == null) return;
    await recordProgram(context, client, seed);
  }

  @override
  Widget build(BuildContext context) {
    final showRecord = _canRecord && _programs.any((p) => p.guid != null && p.guid!.isNotEmpty);
    return OverlaySheetHost(
      child: FocusedScrollScaffold(
        title: Text(widget.showTitle),
        actions: showRecord
            ? [
                FocusableActionBar(
                  actions: [
                    FocusableAction(
                      icon: Symbols.fiber_manual_record_rounded,
                      tooltip: t.liveTv.recordShow,
                      onPressed: _onRecordShow,
                    ),
                  ],
                ),
              ]
            : null,
        slivers: [
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_programs.isEmpty)
            SliverFillRemaining(child: Center(child: Text(t.liveTv.noPrograms)))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final program = _programs[index];
                final channel = findChannel(program.channelIdentifier);
                void onTap() {
                  if (program.isCurrentlyAiring && channel != null) {
                    tuneChannel(channel);
                  } else {
                    showProgramDetails(
                      program: program,
                      channel: channel,
                      posterThumb: program.thumb,
                      posterServerId: widget.serverId,
                    );
                  }
                }

                return FocusableWrapper(
                  autofocus: index == 0,
                  autoScroll: true,
                  useComfortableZone: true,
                  useBackgroundFocus: true,
                  disableScale: true,
                  onSelect: onTap,
                  onBack: () => Navigator.pop(context),
                  child: _ScheduleListTile(program: program, channel: channel, onTap: onTap),
                );
              }, childCount: _programs.length),
            ),
        ],
      ),
    );
  }
}

class _ScheduleListTile extends StatelessWidget {
  final LiveTvProgram program;
  final LiveTvChannel? channel;
  final VoidCallback onTap;

  const _ScheduleListTile({required this.program, required this.channel, required this.onTap});

  String _formatTimeInfo({required bool is24Hour}) {
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
      return _formatAbsoluteTime(start, now, is24Hour: is24Hour);
    } else if (minutesUntil < 90) {
      return 'Starting in ${minutesUntil}min';
    } else {
      return _formatAbsoluteTime(start, now, is24Hour: is24Hour);
    }
  }

  String _formatAbsoluteTime(DateTime start, DateTime now, {required bool is24Hour}) {
    final time = formatClockTime(start, is24Hour: is24Hour);
    return '${formatRelativeDayLabel(start, now: now)} at $time';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = program.isCurrentlyAiring;

    // Title line: S#·E# — Episode Title, or just Title for non-episodes
    final titleText = (program.parentIndex != null && program.index != null)
        ? 'S${program.parentIndex} · E${program.index} — ${program.title}'
        : program.title;

    final timeInfo = _formatTimeInfo(is24Hour: MediaQuery.alwaysUse24HourFormatOf(context));
    final subtitle = [
      timeInfo,
      if (program.summary != null && program.summary!.isNotEmpty) program.summary!,
    ].join(' — ');

    return InkWell(
      canRequestFocus: false,
      onTap: onTap,
      child: Container(
        decoration: isLive
            ? BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
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
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLive) ...[
                  const SizedBox(width: 8),
                  AppIcon(Symbols.play_circle_rounded, size: 20, color: theme.colorScheme.primary),
                ],
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: tokens(context).textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (channel != null) ...[
              const SizedBox(height: 2),
              Text(channel!.displayName, style: theme.textTheme.labelSmall?.copyWith(color: tokens(context).textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}
