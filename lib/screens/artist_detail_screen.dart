import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/plex_client.dart';
import '../models/plex_metadata.dart';
import '../models/plex_library.dart';
import '../focus/key_event_utils.dart';
import '../utils/provider_extensions.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/app_bar_back_button.dart';
import '../widgets/media_context_menu.dart';
import '../widgets/expandable_text.dart';
import '../mixins/item_updatable.dart';
import '../i18n/strings.g.dart';
import '../widgets/media_card.dart';
import 'album_detail_screen.dart';
import '../utils/video_player_navigation.dart' show navigateToAudioPlayer;

class ArtistDetailScreen extends StatefulWidget {
  final PlexMetadata artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen>
    with ItemUpdatable {
  late final PlexClient _client;

  @override
  PlexClient get client => _client;

  List<PlexMetadata> _albums = [];
  bool _isLoadingAlbums = false;
  PlexMetadata? _fullMetadata;
  bool _isLoadingMetadata = true;
  PlexLibrary? _sourceLibrary; // Cache the library this artist belongs to
  final FocusNode _firstAlbumFocusNode = FocusNode(
    debugLabel: 'FirstAlbum',
  );

  /// Get the correct PlexClient for this artist's server
  PlexClient _getClientForArtist(BuildContext context) {
    return context.getClientForServer(widget.artist.serverId!);
  }

  @override
  void initState() {
    super.initState();
    // Initialize the client once in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _client = _getClientForArtist(context);
      _loadFullMetadata();
      _loadAlbums();
    });
  }

  @override
  void dispose() {
    _firstAlbumFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFullMetadata() async {
    setState(() {
      _isLoadingMetadata = true;
    });

    try {
      final metadata = await _client.getMetadataWithImages(
        widget.artist.ratingKey,
      );

      if (metadata != null) {
        final metadataWithServerId = metadata.copyWith(
          serverId: widget.artist.serverId,
          serverName: widget.artist.serverName,
        );

        setState(() {
          _fullMetadata = metadataWithServerId;
          _isLoadingMetadata = false;
        });
      } else {
        setState(() {
          _fullMetadata = widget.artist;
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      setState(() {
        _fullMetadata = widget.artist;
        _isLoadingMetadata = false;
      });
    }
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoadingAlbums = true;
    });

    try {
      // Albums are automatically tagged with server info by PlexClient
      final albums = await _client.getChildren(widget.artist.ratingKey);

      // Load source library for audiobook detection
      await _loadSourceLibrary();

      if (albums.isEmpty) {
        debugPrint('[ArtistDetail] getChildren returned empty for ratingKey=${widget.artist.ratingKey} (${widget.artist.title})');
      }

      setState(() {
        _albums = albums;
        _isLoadingAlbums = false;
      });

      // Focus the first album after loading
      if (albums.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _firstAlbumFocusNode.requestFocus();
        });
      }
    } catch (e) {
      debugPrint('[ArtistDetail] _loadAlbums error: $e');
      setState(() {
        _isLoadingAlbums = false;
      });
    }
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    final index = _albums.indexWhere((item) => item.ratingKey == ratingKey);
    if (index != -1) {
      _albums[index] = updatedMetadata;
    }
  }

  /// Load the source library for this artist if available.
  Future<void> _loadSourceLibrary() async {
    final metadata = _fullMetadata ?? widget.artist;
    if (metadata.librarySectionID == null) return;

    try {
      final libraries = await _client.getLibraries();
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
        if (libraries.isNotEmpty && mounted) {
          setState(() {
            _sourceLibrary = libraries.first;
          });
        }
      }
    } catch (e) {
      // Library lookup failed
    }
  }

  /// Check if this artist is from an audiobook library
  bool get _isAudiobook {
    return _sourceLibrary?.isAudiobookLibrary ?? false;
  }

  bool _isLoadingAllTracks = false;

  Future<void> _playAll({bool shuffle = false}) async {
    if (_albums.isEmpty) return;

    setState(() => _isLoadingAllTracks = true);

    try {
      final allTracks = <PlexMetadata>[];
      for (final album in _albums) {
        final tracks = await _client.getChildren(album.ratingKey);
        allTracks.addAll(tracks);
      }

      if (allTracks.isEmpty || !mounted) return;

      if (shuffle) allTracks.shuffle();

      await navigateToAudioPlayer(
        context,
        metadata: allTracks.first,
        queue: allTracks,
        startIndex: 0,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tracks: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAllTracks = false);
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
                    _loadAlbums(),
                  ]);
                },
                child: CustomScrollView(
                slivers: [
                  DesktopSliverAppBar(
                    pinned: true,
                    leading: AppBarBackButton(
                      style: BackButtonStyle.circular,
                    ),
                    title: Text(_fullMetadata?.title ?? widget.artist.title),
                  ),
                  // Artist header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Artist artwork
                          if (_fullMetadata?.art != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: _client.getThumbnailUrl(_fullMetadata!.art!),
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
                                    Icons.music_note,
                                    size: 64,
                                    color: theme.disabledColor,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          // Artist info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fullMetadata?.title ?? widget.artist.title,
                                  style: theme.textTheme.headlineMedium,
                                ),
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
                  // Play/shuffle buttons for music artists
                  if (!_isAudiobook && !_isLoadingAlbums && _albums.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isLoadingAllTracks ? null : () => _playAll(),
                                icon: _isLoadingAllTracks
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.play_arrow),
                                label: const Text('Play All'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: _isLoadingAllTracks ? null : () => _playAll(shuffle: true),
                                icon: const Icon(Icons.shuffle),
                                label: const Text('Shuffle'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Albums/Books section
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        _isAudiobook 
                            ? t.libraries.groupings.books
                            : t.libraries.groupings.albums,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                  if (_isLoadingAlbums)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (_albums.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            t.messages.noAlbumsFound,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isDesktop ? 300 : 200,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final album = _albums[index];
                            final isFirst = index == 0;
                            return MediaCard(
                              item: album,
                              onRefresh: (ratingKey) {
                                _loadAlbums();
                              },
                            );
                          },
                          childCount: _albums.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

