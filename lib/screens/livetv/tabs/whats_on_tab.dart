import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../models/livetv_channel.dart';
import '../../../models/livetv_hub_result.dart';
import '../../../providers/multi_server_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/settings_service.dart' show LibraryDensity;
import '../../../theme/mono_tokens.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/layout_constants.dart';
import '../../../utils/live_tv_player_navigation.dart';
import '../../../utils/plex_image_helper.dart';
import '../../../utils/provider_extensions.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/horizontal_scroll_with_arrows.dart';
import '../../../widgets/plex_optimized_image.dart';
import '../live_tv_show_schedule_screen.dart';
import '../program_details_sheet.dart';

class WhatsOnTab extends StatefulWidget {
  final List<LiveTvChannel> channels;

  const WhatsOnTab({super.key, required this.channels});

  @override
  State<WhatsOnTab> createState() => _WhatsOnTabState();
}

class _WhatsOnTabState extends State<WhatsOnTab> {
  List<LiveTvHubResult> _hubs = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadHubs();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _loadHubs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHubs() async {
    if (!mounted) return;
    setState(() => _isLoading = _hubs.isEmpty);

    try {
      final multiServer = context.read<MultiServerProvider>();
      final liveTvServers = multiServer.liveTvServers;
      final allHubs = <LiveTvHubResult>[];

      for (final serverInfo in liveTvServers) {
        final client = multiServer.getClientForServer(serverInfo.serverId);
        if (client == null) continue;

        final hubs = await client.getLiveTvHubs();
        allHubs.addAll(hubs);
      }

      if (!mounted) return;
      setState(() {
        _hubs = allHubs;
        _isLoading = false;
      });
    } catch (e) {
      appLogger.e('Failed to load live TV hubs', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Find a channel by its identifier from the channel list.
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

  void _onItemTap(LiveTvHubEntry entry) {
    final channel = _findChannel(entry.program.channelIdentifier);

    if (entry.program.isCurrentlyAiring && channel != null) {
      // Live → play directly
      _tuneChannel(channel);
    } else if (entry.metadata.type.toLowerCase() == 'show') {
      // Show with upcoming episodes → show full schedule
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveTvShowScheduleScreen(
            showTitle: entry.metadata.title,
            serverId: entry.metadata.serverId ?? '',
            channels: widget.channels,
          ),
        ),
      );
    } else {
      // Individual program (episode, movie, etc.) → bottom sheet
      _showProgramDetails(entry, channel);
    }
  }

  void _showProgramDetails(LiveTvHubEntry entry, LiveTvChannel? channel) {
    final program = entry.program;
    final metadata = entry.metadata;

    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(metadata.serverId ?? '');
    final posterImage = metadata.grandparentThumb ?? metadata.thumb;
    String? posterUrl;
    if (posterImage != null && client != null) {
      posterUrl = PlexImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: posterImage,
        maxWidth: 80,
        maxHeight: 120,
        devicePixelRatio: PlexImageHelper.effectiveDevicePixelRatio(context),
        imageType: ImageType.poster,
      );
    }

    showProgramDetailsSheet(
      context,
      program: program,
      channel: channel,
      posterUrl: posterUrl,
      onTuneChannel: channel != null ? () => _tuneChannel(channel) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hubs.isEmpty) {
      return Center(child: Text(t.liveTv.noPrograms));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      clipBehavior: Clip.none,
      itemCount: _hubs.length,
      itemBuilder: (context, index) {
        return _LiveTvHubSection(
          hub: _hubs[index],
          onTap: _onItemTap,
          onLongPress: (entry) => _showProgramDetails(entry, _findChannel(entry.program.channelIdentifier)),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hub section — horizontal scrolling row of poster cards (always 2:3 aspect)
// ---------------------------------------------------------------------------

class _LiveTvHubSection extends StatelessWidget {
  final LiveTvHubResult hub;
  final void Function(LiveTvHubEntry) onTap;
  final void Function(LiveTvHubEntry) onLongPress;

  const _LiveTvHubSection({
    required this.hub,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final densityScale = switch (settings.libraryDensity) {
      LibraryDensity.compact => 0.8,
      LibraryDensity.normal => 1.0,
      LibraryDensity.comfortable => 1.15,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hub header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(Symbols.live_tv_rounded, fill: 1),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  hub.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),

        // Horizontal cards — always poster (2:3) aspect
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final baseCardWidth = (ScreenBreakpoints.isLargeDesktop(screenWidth)
                    ? 220.0
                    : ScreenBreakpoints.isDesktop(screenWidth)
                        ? 200.0
                        : ScreenBreakpoints.isWideTablet(screenWidth)
                            ? 190.0
                            : 160.0) *
                densityScale;

            final cardWidth = baseCardWidth;
            final posterWidth = cardWidth - 16;
            final posterHeight = posterWidth * 1.5; // 2:3 aspect
            final containerHeight = posterHeight + 66;

            return SizedBox(
              height: containerHeight,
              child: HorizontalScrollWithArrows(
                builder: (scrollController) => ListView.builder(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  itemCount: hub.entries.length,
                  itemBuilder: (context, index) {
                    final entry = hub.entries[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _LiveTvPosterCard(
                        entry: entry,
                        width: cardWidth,
                        posterHeight: posterHeight,
                        onTap: () => onTap(entry),
                        onLongPress: () => onLongPress(entry),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Poster card — always 2:3, shows poster image + title + subtitle
// ---------------------------------------------------------------------------

class _LiveTvPosterCard extends StatelessWidget {
  final LiveTvHubEntry entry;
  final double width;
  final double posterHeight;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _LiveTvPosterCard({
    required this.entry,
    required this.width,
    required this.posterHeight,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = entry.metadata;
    // Always use poster image: show poster for episodes, thumb for others
    final posterImage = metadata.grandparentThumb ?? metadata.thumb;

    return SizedBox(
      width: width,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(tokens(context).radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              SizedBox(
                width: double.infinity,
                height: posterHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                  child: PlexOptimizedImage.poster(
                    client: context.getClientWithFallback(metadata.serverId),
                    imagePath: posterImage,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Title
              Text(
                metadata.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.1,
                ),
              ),
              // Subtitle
              if (metadata.displaySubtitle != null)
                Text(
                  metadata.displaySubtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens(context).textMuted,
                        fontSize: 11,
                        height: 1.1,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
