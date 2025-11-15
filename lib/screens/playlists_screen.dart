import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../client/plex_client.dart';
import '../models/plex_playlist.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../widgets/desktop_app_bar.dart';
import '../mixins/refreshable.dart';
import '../i18n/strings.g.dart';
import 'playlist_detail_screen.dart';

/// Screen to display all video playlists
class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> with Refreshable {
  PlexClient get client => context.clientSafe;

  List<PlexPlaylist> _playlists = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool? _filterSmart;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      final playlists = await client.getPlaylists(
        playlistType: 'video',
        smart: _filterSmart,
      );

      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });

      appLogger.d('Loaded ${playlists.length} playlists');
    } catch (e) {
      appLogger.e('Failed to load playlists', error: e);
      setState(() {
        _errorMessage = 'Failed to load playlists: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _toggleSmartFilter() {
    setState(() {
      if (_filterSmart == null) {
        _filterSmart = true; // Show only smart
      } else if (_filterSmart == true) {
        _filterSmart = false; // Show only regular
      } else {
        _filterSmart = null; // Show all
      }
    });
    _loadPlaylists();
  }

  String _getFilterLabel() {
    if (_filterSmart == null) return 'All';
    if (_filterSmart == true) return 'Smart';
    return 'Regular';
  }

  @override
  void refresh() {
    _loadPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: Text(t.playlists.title),
            pinned: true,
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.filter_list),
                label: Text(_getFilterLabel()),
                onPressed: _toggleSmartFilter,
              ),
            ],
          ),
          if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(_errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPlaylists,
                      child: Text(t.common.retry),
                    ),
                  ],
                ),
              ),
            )
          else if (_playlists.isEmpty && _isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_playlists.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text(t.playlists.noPlaylists)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _getMaxCrossAxisExtent(
                    context,
                    context.watch<SettingsProvider>().libraryDensity,
                  ),
                  childAspectRatio: 2 / 3.3,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _PlaylistCard(
                    playlist: _playlists[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlaylistDetailScreen(playlist: _playlists[index]),
                        ),
                      ).then((_) => _loadPlaylists()); // Refresh on return
                    },
                    onDeleted: _loadPlaylists,
                  );
                }, childCount: _playlists.length),
              ),
            ),
        ],
      ),
    );
  }

  double _getMaxCrossAxisExtent(BuildContext context, LibraryDensity density) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 16.0;
    final availableWidth = screenWidth - padding;

    if (screenWidth >= 900) {
      double divisor;
      double maxItemWidth;

      switch (density) {
        case LibraryDensity.comfortable:
          divisor = 6.5;
          maxItemWidth = 280;
          break;
        case LibraryDensity.normal:
          divisor = 8.0;
          maxItemWidth = 200;
          break;
        case LibraryDensity.compact:
          divisor = 10.0;
          maxItemWidth = 160;
          break;
      }

      return (availableWidth / divisor).clamp(120, maxItemWidth);
    } else if (screenWidth >= 600) {
      double divisor;
      double maxItemWidth;

      switch (density) {
        case LibraryDensity.comfortable:
          divisor = 4.5;
          maxItemWidth = 220;
          break;
        case LibraryDensity.normal:
          divisor = 5.5;
          maxItemWidth = 180;
          break;
        case LibraryDensity.compact:
          divisor = 7.0;
          maxItemWidth = 140;
          break;
      }

      return (availableWidth / divisor).clamp(100, maxItemWidth);
    } else {
      double divisor;

      switch (density) {
        case LibraryDensity.comfortable:
          divisor = 2.2;
          break;
        case LibraryDensity.normal:
          divisor = 2.8;
          break;
        case LibraryDensity.compact:
          divisor = 3.5;
          break;
      }

      return availableWidth / divisor;
    }
  }
}

/// Widget to display a single playlist card
class _PlaylistCard extends StatelessWidget {
  final PlexPlaylist playlist;
  final VoidCallback onTap;
  final VoidCallback onDeleted;

  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
    required this.onDeleted,
  });

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.playlists.deleteConfirm),
        content: Text(t.playlists.deleteMessage(name: playlist.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.playlists.delete),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final client = context.clientSafe;
      final success = await client.deletePlaylist(playlist.ratingKey);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.playlists.deleted)));
          onDeleted();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.playlists.errorDeleting)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = context.clientSafe;
    final imageUrl = playlist.displayImage != null
        ? client.getThumbnailUrl(playlist.displayImage!)
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showDeleteDialog(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Playlist image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder();
                      },
                    )
                  else
                    _buildPlaceholder(),
                  // Smart playlist indicator
                  if (playlist.smart)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Playlist info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.playlist_play,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        playlist.leafCount != null && playlist.leafCount! > 0
                            ? (playlist.leafCount == 1
                                  ? t.playlists.oneItem
                                  : t.playlists.itemCount(
                                      count: playlist.leafCount!,
                                    ))
                            : t.playlists.emptyPlaylist,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[850],
      child: const Center(
        child: Icon(Icons.playlist_play, size: 48, color: Colors.grey),
      ),
    );
  }
}
