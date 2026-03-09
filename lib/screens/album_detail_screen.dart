import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/plex_client.dart';
import '../models/plex_metadata.dart';
import '../models/plex_library.dart';
import '../focus/key_event_utils.dart';
import '../utils/provider_extensions.dart';
import '../utils/formatters.dart' show formatDurationTimestamp;
import '../widgets/desktop_app_bar.dart';
import '../widgets/app_bar_back_button.dart';
import '../widgets/media_context_menu.dart';
import '../widgets/expandable_text.dart';
import '../mixins/item_updatable.dart';
import '../i18n/strings.g.dart';
import '../utils/video_player_navigation.dart' show navigateToAudioPlayer;

class AlbumDetailScreen extends StatefulWidget {
  final PlexMetadata album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen>
    with ItemUpdatable {
  late final PlexClient _client;

  @override
  PlexClient get client => _client;

  List<PlexMetadata> _tracks = [];
  bool _isLoadingTracks = false;
  PlexMetadata? _fullMetadata;
  bool _isLoadingMetadata = true;
  PlexLibrary? _sourceLibrary; // Cache the library this album belongs to
  final FocusNode _firstTrackFocusNode = FocusNode(
    debugLabel: 'FirstTrack',
  );

  /// Get the correct PlexClient for this album's server
  PlexClient _getClientForAlbum(BuildContext context) {
    return context.getClientForServer(widget.album.serverId!);
  }

  @override
  void initState() {
    super.initState();
    // Initialize the client once in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _client = _getClientForAlbum(context);
      _loadFullMetadata();
      _loadTracks();
    });
  }

  @override
  void dispose() {
    _firstTrackFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFullMetadata() async {
    setState(() {
      _isLoadingMetadata = true;
    });

    try {
      final metadata = await _client.getMetadataWithImages(
        widget.album.ratingKey,
      );

      if (metadata != null) {
        final metadataWithServerId = metadata.copyWith(
          serverId: widget.album.serverId,
          serverName: widget.album.serverName,
        );

        setState(() {
          _fullMetadata = metadataWithServerId;
          _isLoadingMetadata = false;
        });
      } else {
        setState(() {
          _fullMetadata = widget.album;
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      setState(() {
        _fullMetadata = widget.album;
        _isLoadingMetadata = false;
      });
    }
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoadingTracks = true;
    });

    try {
      // Tracks are automatically tagged with server info by PlexClient
      final tracks = await _client.getChildren(widget.album.ratingKey);

      // Load source library for audiobook detection
      await _loadSourceLibrary();

      setState(() {
        _tracks = tracks;
        _isLoadingTracks = false;
      });

      // Focus the first track after loading
      if (tracks.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _firstTrackFocusNode.requestFocus();
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingTracks = false;
      });
    }
  }

  @override
  Future<void> updateItem(String ratingKey) async {
    await super.updateItem(ratingKey);
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    final index = _tracks.indexWhere((item) => item.ratingKey == ratingKey);
    if (index != -1) {
      _tracks[index] = updatedMetadata;
    }
  }

  /// Load the source library for this album if available.
  /// This enables accurate audiobook detection based on library metadata.
  Future<void> _loadSourceLibrary() async {
    final metadata = _fullMetadata ?? widget.album;
    if (metadata.librarySectionID == null) return;

    try {
      // Get libraries from the same server as this metadata
      final libraries = await _client.getLibraries();
      
      // Find library matching the section ID (key matches librarySectionID)
      try {
        final library = libraries.firstWhere(
          (lib) => lib.key == metadata.librarySectionID.toString(),
        );
        if (mounted) {
          setState(() {
            _sourceLibrary = library;
          });
        }
      } catch (e) {
        // Library not found by key, try to find any library from same server
        if (libraries.isNotEmpty) {
          if (mounted) {
            setState(() {
              _sourceLibrary = libraries.first;
            });
          }
        }
      }
    } catch (e) {
      // Library lookup failed, will fall back to other detection methods
    }
  }

  /// Check if this album is from an audiobook library
  bool get _isAudiobook {
    if (_sourceLibrary != null) {
      return _sourceLibrary!.isAudiobookLibrary;
    }
    // Fallback: check if album has multiple tracks (typical for audiobooks)
    // and if any track has a viewOffset (indicating playback has started)
    return _tracks.length > 1 && 
           _tracks.any((track) => track.viewOffset != null && track.viewOffset! > 0);
  }

  /// Find the track with the highest viewOffset (last played track)
  PlexMetadata? _getResumeTrack() {
    if (_tracks.isEmpty) return null;
    
    // Find track with highest viewOffset that's not completed
    PlexMetadata? resumeTrack;
    int maxViewOffset = 0;
    
    for (final track in _tracks) {
      if (track.viewOffset != null && 
          track.viewOffset! > maxViewOffset &&
          track.viewOffset! < (track.duration ?? 0)) {
        maxViewOffset = track.viewOffset!;
        resumeTrack = track;
      }
    }
    
    return resumeTrack;
  }

  /// Resume playback from the last position
  Future<void> _resumePlayback() async {
    final resumeTrack = _getResumeTrack();
    if (resumeTrack != null) {
      final startIndex = _tracks.indexOf(resumeTrack);
      await navigateToAudioPlayer(
        context,
        metadata: resumeTrack,
        queue: _tracks,
        startIndex: startIndex >= 0 ? startIndex : 0,
      );
      // Refresh tracks when returning from audio player
      _loadTracks();
    } else if (_tracks.isNotEmpty) {
      // No resume position, start from first track
      await navigateToAudioPlayer(
        context,
        metadata: _tracks.first,
        queue: _tracks,
        startIndex: 0,
      );
      _loadTracks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          return handleBackKeyNavigation(context, event);
        },
        child: _isLoadingMetadata
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _loadFullMetadata(),
                    _loadTracks(),
                  ]);
                },
                child: CustomScrollView(
                slivers: [
                  DesktopSliverAppBar(
                    pinned: true,
                    leading: AppBarBackButton(
                      style: BackButtonStyle.circular,
                    ),
                    title: Text(_fullMetadata?.title ?? widget.album.title),
                  ),
                  // Album header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Album artwork
                          if (_fullMetadata?.thumb != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: _client.getThumbnailUrl(_fullMetadata!.thumb!),
                                width: isDesktop ? 300.0 : 200.0,
                                height: isDesktop ? 300.0 : 200.0,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: isDesktop ? 300 : 200,
                                  height: isDesktop ? 300 : 200,
                                  color: theme.cardColor,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: isDesktop ? 300 : 200,
                                  height: isDesktop ? 300 : 200,
                                  color: theme.cardColor,
                                  child: Icon(
                                    Icons.album,
                                    size: 64,
                                    color: theme.disabledColor,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          // Album info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fullMetadata?.title ?? widget.album.title,
                                  style: theme.textTheme.headlineMedium,
                                ),
                                if (_fullMetadata?.parentTitle != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _fullMetadata!.parentTitle!,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.disabledColor,
                                    ),
                                  ),
                                ],
                                if (_fullMetadata?.year != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _fullMetadata!.year.toString(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.disabledColor,
                                    ),
                                  ),
                                ],
                                if (_fullMetadata?.summary != null) ...[
                                  const SizedBox(height: 8),
                                  ExpandableText(
                                    text: _fullMetadata!.summary!,
                                    maxLines: 10,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Play/shuffle buttons
                  if (_tracks.length > 1 && !_isLoadingTracks)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: _isAudiobook
                            ? _buildResumeButton(theme)
                            : _buildPlayButtons(theme),
                      ),
                    ),
                  // Tracks/Chapters section
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        _isAudiobook
                            ? t.libraries.groupings.chapters
                            : t.libraries.groupings.tracks,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                  if (_isLoadingTracks)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (_tracks.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            t.messages.noTracksFound,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = _tracks[index];
                          final isFirst = index == 0;
                          return _TrackCard(
                            track: track,
                            client: _client,
                            focusNode: isFirst ? _firstTrackFocusNode : null,
                            onTap: () async {
                              await navigateToAudioPlayer(
                                context,
                                metadata: track,
                                queue: _tracks,
                                startIndex: index,
                              );
                              // Refresh tracks when returning from audio player
                              _loadTracks();
                            },
                            onRefresh: updateItem,
                          );
                        },
                        childCount: _tracks.length,
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _playAll({bool shuffle = false}) async {
    if (_tracks.isEmpty) return;
    final tracks = List<PlexMetadata>.from(_tracks);
    if (shuffle) tracks.shuffle();
    await navigateToAudioPlayer(
      context,
      metadata: tracks.first,
      queue: tracks,
      startIndex: 0,
    );
    _loadTracks();
  }

  Widget _buildPlayButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _playAll(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => _playAll(shuffle: true),
            icon: const Icon(Icons.shuffle),
            label: const Text('Shuffle'),
          ),
        ),
      ],
    );
  }

  /// Build the resume play button for audiobooks
  Widget _buildResumeButton(ThemeData theme) {
    final resumeTrack = _getResumeTrack();
    final hasResumePosition = resumeTrack != null;
    
    // Calculate progress percentage if resuming
    String? progressText;
    if (hasResumePosition && resumeTrack.duration != null && resumeTrack.duration! > 0) {
      final progress = (resumeTrack.viewOffset! / resumeTrack.duration!) * 100;
      progressText = '${progress.toStringAsFixed(0)}% complete';
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _resumePlayback,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasResumePosition ? Icons.play_circle_filled : Icons.play_arrow,
                  size: 32,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasResumePosition 
                            ? 'Resume ${resumeTrack.title}'
                            : 'Play Audiobook',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (progressText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          progressText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Focusable track card widget
class _TrackCard extends StatefulWidget {
  final PlexMetadata track;
  final PlexClient client;
  final VoidCallback onTap;
  final Future<void> Function(String) onRefresh;
  final FocusNode? focusNode;

  const _TrackCard({
    required this.track,
    required this.client,
    required this.onTap,
    required this.onRefresh,
    this.focusNode,
  });

  @override
  State<_TrackCard> createState() => _TrackCardState();
}

class _TrackCardState extends State<_TrackCard> {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  bool _isFocused = false;
  final _contextMenuKey = GlobalKey<MediaContextMenuState>();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_focusNode.hasFocus) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final theme = Theme.of(context);

    return MediaContextMenu(
      key: _contextMenuKey,
      item: track,
      onRefresh: widget.onRefresh,
      onTap: widget.onTap,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          return handleBackKeyNavigation(context, event);
        },
        child: Container(
            decoration: _isFocused ? BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(8),
            ) : null,
            child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
            leading: track.index != null
                ? SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        track.index.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: 40),
            title: Text(
              track.title,
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: track.duration != null
                ? Text(
                    formatDurationTimestamp(Duration(milliseconds: track.duration!)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  )
                : null,
            trailing: Icon(
              Icons.play_arrow,
              color: theme.iconTheme.color,
            ),
            onTap: widget.onTap,
            ),
          ),
        ),
      ),
    );
  }
}

