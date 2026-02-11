import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/app_logger.dart';
import '../../utils/plex_url_helper.dart';
import '../../utils/live_tv_player_navigation.dart';
import '../../widgets/app_icon.dart';
import 'epg_guide_screen.dart';
import 'dvr_recordings_screen.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  List<LiveTvChannel> _channels = [];
  Map<String, LiveTvProgram?> _nowPlaying = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final multiServer = context.read<MultiServerProvider>();
      final liveTvServers = multiServer.liveTvServers;

      if (liveTvServers.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = t.liveTv.noDvr;
        });
        return;
      }

      final allChannels = <LiveTvChannel>[];

      for (final serverInfo in liveTvServers) {
        final client = multiServer.getClientForServer(serverInfo.serverId);
        if (client == null) continue;

        final channels = await client.getEpgChannels(lineup: serverInfo.lineup);
        allChannels.addAll(channels);
      }

      // Sort channels by number
      allChannels.sort((a, b) {
        final aNum = double.tryParse(a.number ?? '') ?? 999999;
        final bNum = double.tryParse(b.number ?? '') ?? 999999;
        return aNum.compareTo(bNum);
      });

      if (!mounted) return;

      // Load "now playing" data
      await _loadNowPlaying(allChannels);

      setState(() {
        _channels = allChannels;
        _isLoading = false;
      });
    } catch (e) {
      appLogger.e('Failed to load Live TV channels', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadNowPlaying(List<LiveTvChannel> channels) async {
    final multiServer = context.read<MultiServerProvider>();
    final nowPlaying = <String, LiveTvProgram?>{};

    for (final serverInfo in multiServer.liveTvServers) {
      final client = multiServer.getClientForServer(serverInfo.serverId);
      if (client == null) continue;

      try {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final programs = await client.getEpgGrid(
          lineup: serverInfo.lineup,
          beginsAt: now - 7200, // 2 hours before
          endsAt: now + 7200, // 2 hours after
        );

        for (final program in programs) {
          if (program.isCurrentlyAiring && program.channelIdentifier != null) {
            nowPlaying[program.channelIdentifier!] = program;
          }
        }
      } catch (e) {
        appLogger.d('Failed to load now playing data', error: e);
      }
    }

    if (mounted) {
      setState(() => _nowPlaying = nowPlaying);
    }
  }

  Future<void> _tuneChannel(LiveTvChannel channel) async {
    final multiServer = context.read<MultiServerProvider>();

    // Find the DVR server info matching this channel's serverId
    final serverInfo = multiServer.liveTvServers.where(
      (s) => s.serverId == channel.serverId,
    ).firstOrNull ?? multiServer.liveTvServers.firstOrNull;

    if (serverInfo == null) return;

    final client = multiServer.getClientForServer(serverInfo.serverId);
    if (client == null) return;

    await navigateToLiveTv(
      context,
      client: client,
      dvrKey: serverInfo.dvrKey,
      channel: channel,
      channels: _channels,
    );
  }

  void _openGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EpgGuideScreen()),
    );
  }

  void _openRecordings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DvrRecordingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.liveTv.title),
        actions: [
          IconButton(
            icon: const AppIcon(Symbols.menu_book_rounded),
            tooltip: t.liveTv.guide,
            onPressed: _openGuide,
          ),
          IconButton(
            icon: const AppIcon(Symbols.fiber_dvr_rounded),
            tooltip: t.liveTv.recordings,
            onPressed: _openRecordings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(Symbols.error_rounded, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadChannels,
                        icon: const AppIcon(Symbols.refresh_rounded),
                        label: Text(t.common.retry),
                      ),
                    ],
                  ),
                )
              : _channels.isEmpty
                  ? Center(child: Text(t.liveTv.noChannels))
                  : RefreshIndicator(
                      onRefresh: _loadChannels,
                      child: _buildChannelList(theme),
                    ),
    );
  }

  Widget _buildChannelList(ThemeData theme) {
    // Build "What's On Now" section + channel list
    final currentlyAiring = _channels.where((ch) {
      final id = ch.identifier ?? ch.key;
      return _nowPlaying.containsKey(id) && _nowPlaying[id] != null;
    }).toList();

    return CustomScrollView(
      slivers: [
        // "What's On Now" section
        if (currentlyAiring.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(t.liveTv.whatsOnNow, style: theme.textTheme.titleMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: currentlyAiring.length,
                itemBuilder: (context, index) {
                  final channel = currentlyAiring[index];
                  final id = channel.identifier ?? channel.key;
                  final program = _nowPlaying[id]!;
                  return _buildNowPlayingCard(channel, program, theme);
                },
              ),
            ),
          ),
        ],

        // All channels header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(t.liveTv.allChannels, style: theme.textTheme.titleMedium),
          ),
        ),

        // Channel grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildChannelTile(
                _channels[index],
                theme,
              ),
              childCount: _channels.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildNowPlayingCard(LiveTvChannel channel, LiveTvProgram program, ThemeData theme) {
    final client = context.read<MultiServerProvider>().getClientForServer(channel.serverId ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 280,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _tuneChannel(channel),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (channel.thumb != null && client != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            '${client.config.baseUrl}${channel.thumb}'.withPlexToken(client.config.token),
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const SizedBox(width: 32, height: 32),
                          ),
                        )
                      else
                        const AppIcon(Symbols.live_tv_rounded, size: 32),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel.displayName,
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (channel.number != null)
                              Text(
                                t.liveTv.channelNumber(number: channel.number!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _LiveBadge(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    program.title,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (program.grandparentTitle != null)
                    Text(
                      program.grandparentTitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  // Progress bar
                  LinearProgressIndicator(
                    value: program.progress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelTile(LiveTvChannel channel, ThemeData theme) {
    final id = channel.identifier ?? channel.key;
    final program = _nowPlaying[id];
    final client = context.read<MultiServerProvider>().getClientForServer(channel.serverId ?? '');

    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: channel.thumb != null && client != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  '${client.config.baseUrl}${channel.thumb}'.withPlexToken(client.config.token),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(child: AppIcon(Symbols.live_tv_rounded)),
                ),
              )
            : const Center(child: AppIcon(Symbols.live_tv_rounded)),
      ),
      title: Row(
        children: [
          if (channel.number != null) ...[
            SizedBox(
              width: 48,
              child: Text(
                channel.number!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          Expanded(
            child: Text(
              channel.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (channel.hd)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  t.liveTv.hd,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
      subtitle: program != null
          ? Row(
              children: [
                if (program.isCurrentlyAiring) ...[
                  _LiveBadge(small: true),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    program.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : null,
      onTap: () => _tuneChannel(channel),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  final bool small;
  const _LiveBadge({this.small = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 6,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        t.liveTv.live,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: small ? 8 : 10,
        ),
      ),
    );
  }
}
