import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../providers/multi_server_provider.dart';
import '../widgets/app_icon.dart';
import '../widgets/focused_scroll_scaffold.dart';

/// Statistics for a single library
class LibraryStats {
  final String name;
  final String type;
  final int itemCount;
  final int? episodeCount;

  const LibraryStats({
    required this.name,
    required this.type,
    required this.itemCount,
    this.episodeCount,
  });
}

/// Statistics for a single server
class ServerStats {
  final String serverId;
  final String serverName;
  final List<LibraryStats> libraries;
  final int watchedThisWeek;
  final int watchedThisMonth;
  final bool isLoading;
  final String? error;

  const ServerStats({
    required this.serverId,
    required this.serverName,
    this.libraries = const [],
    this.watchedThisWeek = 0,
    this.watchedThisMonth = 0,
    this.isLoading = true,
    this.error,
  });

  ServerStats copyWith({
    String? serverId,
    String? serverName,
    List<LibraryStats>? libraries,
    int? watchedThisWeek,
    int? watchedThisMonth,
    bool? isLoading,
    String? error,
  }) {
    return ServerStats(
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      libraries: libraries ?? this.libraries,
      watchedThisWeek: watchedThisWeek ?? this.watchedThisWeek,
      watchedThisMonth: watchedThisMonth ?? this.watchedThisMonth,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get totalMovies => libraries
      .where((l) => l.type == 'movie')
      .fold(0, (sum, l) => sum + l.itemCount);

  int get totalShows => libraries
      .where((l) => l.type == 'show')
      .fold(0, (sum, l) => sum + l.itemCount);

  int get totalEpisodes => libraries
      .where((l) => l.type == 'show')
      .fold(0, (sum, l) => sum + (l.episodeCount ?? 0));

  int get totalArtists => libraries
      .where((l) => l.type == 'artist')
      .fold(0, (sum, l) => sum + l.itemCount);

  int get totalAlbums => libraries
      .where((l) => l.type == 'album')
      .fold(0, (sum, l) => sum + l.itemCount);

  int get totalTracks => libraries
      .where((l) => l.type == 'track')
      .fold(0, (sum, l) => sum + l.itemCount);
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final Map<String, ServerStats> _serverStats = {};
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    final multiServerProvider = Provider.of<MultiServerProvider>(
      context,
      listen: false,
    );

    final serverIds = multiServerProvider.onlineServerIds;

    if (serverIds.isEmpty) {
      setState(() {
        _isInitialLoading = false;
      });
      return;
    }

    // Initialize loading state for all servers
    setState(() {
      _isInitialLoading = false;
      for (final serverId in serverIds) {
        final server = multiServerProvider.serverManager.getServer(serverId);
        _serverStats[serverId] = ServerStats(
          serverId: serverId,
          serverName: server?.name ?? t.common.unknown,
          isLoading: true,
        );
      }
    });

    // Fetch stats from all servers in parallel
    await Future.wait(
      serverIds.map((serverId) => _fetchServerStats(serverId)),
    );
  }

  Future<void> _fetchServerStats(String serverId) async {
    final multiServerProvider = Provider.of<MultiServerProvider>(
      context,
      listen: false,
    );

    final client = multiServerProvider.getClientForServer(serverId);
    final server = multiServerProvider.serverManager.getServer(serverId);

    if (client == null) {
      setState(() {
        _serverStats[serverId] = ServerStats(
          serverId: serverId,
          serverName: server?.name ?? t.common.unknown,
          isLoading: false,
          error: 'Client not available',
        );
      });
      return;
    }

    try {
      // Get libraries for this server
      final libraries = await client.getLibraries();
      final libraryStats = <LibraryStats>[];

      // Fetch counts for each library
      for (final library in libraries) {
        final count = await client.getLibraryTotalCount(library.key);

        int? episodeCount;
        if (library.type == 'show') {
          episodeCount = await client.getLibraryEpisodeCount(library.key);
        }

        libraryStats.add(LibraryStats(
          name: library.title,
          type: library.type,
          itemCount: count,
          episodeCount: episodeCount,
        ));
      }

      // Get watch history counts
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final oneMonthAgo = now.subtract(const Duration(days: 30));

      final watchedThisWeek = await client.getWatchHistoryCount(
        since: oneWeekAgo,
      );
      final watchedThisMonth = await client.getWatchHistoryCount(
        since: oneMonthAgo,
      );

      if (mounted) {
        setState(() {
          _serverStats[serverId] = ServerStats(
            serverId: serverId,
            serverName: server?.name ?? t.common.unknown,
            libraries: libraryStats,
            watchedThisWeek: watchedThisWeek,
            watchedThisMonth: watchedThisMonth,
            isLoading: false,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverStats[serverId] = _serverStats[serverId]?.copyWith(
                isLoading: false,
                error: e.toString(),
              ) ??
              ServerStats(
                serverId: serverId,
                serverName: server?.name ?? t.common.unknown,
                isLoading: false,
                error: e.toString(),
              );
        });
      }
    }
  }

  // Calculate totals across all servers
  int get _totalMovies =>
      _serverStats.values.fold(0, (sum, s) => sum + s.totalMovies);

  int get _totalShows =>
      _serverStats.values.fold(0, (sum, s) => sum + s.totalShows);

  int get _totalEpisodes =>
      _serverStats.values.fold(0, (sum, s) => sum + s.totalEpisodes);

  int get _totalArtists =>
      _serverStats.values.fold(0, (sum, s) => sum + s.totalArtists);

  int get _totalWatchedThisWeek =>
      _serverStats.values.fold(0, (sum, s) => sum + s.watchedThisWeek);

  int get _totalWatchedThisMonth =>
      _serverStats.values.fold(0, (sum, s) => sum + s.watchedThisMonth);

  bool get _isAnyLoading => _serverStats.values.any((s) => s.isLoading);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FocusedScrollScaffold(
      title: Text(t.stats.title),
      actions: [
        IconButton(
          icon: _isAnyLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const AppIcon(Symbols.refresh_rounded, fill: 1),
          onPressed: _isAnyLoading ? null : _loadStats,
        ),
      ],
      slivers: [
        if (_isInitialLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_serverStats.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    Symbols.cloud_off_rounded,
                    fill: 1,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.stats.noServers,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSummaryCard(theme),
            ),
          ),

          // Server breakdown header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Servers',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Per-server cards
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final serverStats = _serverStats.values.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildServerCard(theme, serverStats),
                  );
                },
                childCount: _serverStats.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(
                  Symbols.analytics_rounded,
                  fill: 1,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  t.stats.totalSummary,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Media counts row
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildStatItem(
                  theme,
                  Symbols.movie_rounded,
                  t.stats.movies,
                  _formatNumber(_totalMovies),
                ),
                _buildStatItem(
                  theme,
                  Symbols.tv_rounded,
                  t.stats.tvShows,
                  _formatNumber(_totalShows),
                ),
                _buildStatItem(
                  theme,
                  Symbols.videocam_rounded,
                  t.stats.episodes,
                  _formatNumber(_totalEpisodes),
                ),
                if (_totalArtists > 0)
                  _buildStatItem(
                    theme,
                    Symbols.person_rounded,
                    t.stats.artists,
                    _formatNumber(_totalArtists),
                  ),
              ],
            ),

            const Divider(height: 32),

            // Watch history
            Row(
              children: [
                AppIcon(
                  Symbols.history_rounded,
                  fill: 1,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  t.stats.watchHistory,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _buildStatItem(
                  theme,
                  Symbols.calendar_today_rounded,
                  t.stats.watchedThisWeek,
                  _formatNumber(_totalWatchedThisWeek),
                ),
                _buildStatItem(
                  theme,
                  Symbols.calendar_month_rounded,
                  t.stats.watchedThisMonth,
                  _formatNumber(_totalWatchedThisMonth),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard(ThemeData theme, ServerStats stats) {
    if (stats.isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(stats.serverName),
              const Spacer(),
              Text(
                t.stats.loading,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (stats.error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppIcon(
                Symbols.error_rounded,
                fill: 1,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.serverName,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      t.stats.errorLoading,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const AppIcon(Symbols.refresh_rounded, fill: 1),
                onPressed: () => _fetchServerStats(stats.serverId),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(
                  Symbols.dns_rounded,
                  fill: 1,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  stats.serverName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Library breakdown
            ...stats.libraries.map((lib) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      AppIcon(
                        _getLibraryIcon(lib.type),
                        fill: 1,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lib.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Text(
                        lib.type == 'show'
                            ? '${_formatNumber(lib.itemCount)} shows, ${_formatNumber(lib.episodeCount ?? 0)} episodes'
                            : _formatNumber(lib.itemCount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )),

            if (stats.libraries.isNotEmpty) const SizedBox(height: 8),

            // Watch history for this server
            Row(
              children: [
                AppIcon(
                  Symbols.history_rounded,
                  fill: 1,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${t.stats.watchedThisWeek}: ${_formatNumber(stats.watchedThisWeek)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${t.stats.watchedThisMonth}: ${_formatNumber(stats.watchedThisMonth)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          icon,
          fill: 1,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getLibraryIcon(String type) {
    switch (type) {
      case 'movie':
        return Symbols.movie_rounded;
      case 'show':
        return Symbols.tv_rounded;
      case 'artist':
        return Symbols.person_rounded;
      case 'photo':
        return Symbols.photo_library_rounded;
      default:
        return Symbols.folder_rounded;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
