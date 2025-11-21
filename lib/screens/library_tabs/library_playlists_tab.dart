import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../client/plex_client.dart';
import '../../models/plex_library.dart';
import '../../models/plex_playlist.dart';
import '../../providers/plex_client_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_logger.dart';
import '../../utils/library_refresh_notifier.dart';
import '../../services/settings_service.dart' show ViewMode;
import '../../utils/grid_size_calculator.dart';
import '../../widgets/media_card.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/refreshable.dart';
import '../../widgets/content_state_builder.dart';

/// Playlists tab for library screen
/// Shows playlists that contain items from the current library
class LibraryPlaylistsTab extends StatefulWidget {
  final PlexLibrary library;
  final String? viewMode;
  final String? density;

  const LibraryPlaylistsTab({
    super.key,
    required this.library,
    this.viewMode,
    this.density,
  });

  @override
  State<LibraryPlaylistsTab> createState() => _LibraryPlaylistsTabState();
}

class _LibraryPlaylistsTabState extends State<LibraryPlaylistsTab>
    with AutomaticKeepAliveClientMixin, Refreshable {
  @override
  bool get wantKeepAlive => true;

  @override
  void refresh() {
    _loadPlaylists();
  }

  /// Get the correct PlexClient for this library's server
  PlexClient? _getClientForLibrary(BuildContext context) {
    final serverId = widget.library.serverId;
    if (serverId == null) {
      // Fallback to legacy client if no serverId
      appLogger.w('Library ${widget.library.title} has no serverId, using legacy client');
      return context.read<PlexClientProvider>().client;
    }

    final multiServerProvider = context.read<MultiServerProvider>();
    final client = multiServerProvider.getClientForServer(serverId);

    if (client == null) {
      appLogger.w('No client found for server $serverId, using legacy client');
      return context.read<PlexClientProvider>().client;
    }

    return client;
  }

  List<PlexPlaylist> _playlists = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();

    // Listen for refresh notifications
    _refreshSubscription = LibraryRefreshNotifier().playlistsStream.listen((_) {
      if (mounted) {
        _loadPlaylists();
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(LibraryPlaylistsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if library changed
    if (oldWidget.library.globalKey != widget.library.globalKey) {
      _loadPlaylists();
    }
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use server-specific client for this library
      final client = _getClientForLibrary(context);
      if (client == null) {
        throw Exception(t.errors.noClientAvailable);
      }

      // Get playlists for this library
      final playlists = await client.getLibraryPlaylists(
        sectionId: widget.library.key,
        playlistType: 'video',
      );

      if (!mounted) return;

      final taggedPlaylists = playlists
          .map(
            (playlist) => playlist.copyWith(
              serverId: widget.library.serverId,
              serverName: widget.library.serverName,
            ),
          )
          .toList();

      setState(() {
        _playlists = taggedPlaylists;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      appLogger.e('Error loading playlists', error: e);
      setState(() {
        _errorMessage = t.errors.failedToLoad(
          context: t.playlists.title,
          error: e.toString(),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return ContentStateBuilder<PlexPlaylist>(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      items: _playlists,
      emptyIcon: Icons.playlist_play,
      emptyMessage: t.playlists.noPlaylists,
      onRetry: _loadPlaylists,
      builder: (items) => RefreshIndicator(
        onRefresh: _loadPlaylists,
        child: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            if (settingsProvider.viewMode == ViewMode.list) {
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final playlist = items[index];
                  return MediaCard(
                    key: Key(playlist.ratingKey),
                    item: playlist,
                    onListRefresh: _loadPlaylists,
                  );
                },
              );
            } else {
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: GridSizeCalculator.getMaxCrossAxisExtent(
                    context,
                    settingsProvider.libraryDensity,
                  ),
                  childAspectRatio: 2 / 3.3,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final playlist = items[index];
                  return MediaCard(
                    key: Key(playlist.ratingKey),
                    item: playlist,
                    onListRefresh: _loadPlaylists,
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
