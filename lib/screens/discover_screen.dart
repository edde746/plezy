import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../client/plex_client.dart';
import '../config/plex_config.dart';
import '../models/plex_metadata.dart';
import '../models/plex_user_profile.dart';
import '../services/storage_service.dart';
import '../services/plex_auth_service.dart';
import '../widgets/media_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/server_list_tile.dart';
import '../mixins/refreshable.dart';
import '../utils/app_logger.dart';
import 'video_player_screen.dart';
import 'main_screen.dart';
import 'about_screen.dart';

class DiscoverScreen extends StatefulWidget {
  final PlexClient client;
  final PlexUserProfile? userProfile;
  final VoidCallback? onBecameVisible;

  const DiscoverScreen({
    super.key,
    required this.client,
    this.userProfile,
    this.onBecameVisible,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with Refreshable {
  List<PlexMetadata> _onDeck = [];
  List<PlexMetadata> _recentlyAdded = [];
  bool _isLoading = true;
  String? _errorMessage;
  final PageController _heroController = PageController();
  int _currentHeroIndex = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_onDeck.isEmpty || !_heroController.hasClients) return;

      final nextPage = (_currentHeroIndex + 1) % _onDeck.length;
      _heroController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resetAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  Future<void> _loadContent() async {
    appLogger.d('Loading discover content');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      appLogger.d('Fetching onDeck and recentlyAdded from Plex');
      final onDeck = await widget.client.getOnDeck();
      final recentlyAdded = await widget.client.getRecentlyAdded(limit: 20);

      appLogger.d(
        'Received ${onDeck.length} on deck items and ${recentlyAdded.length} recently added items',
      );
      setState(() {
        _onDeck = onDeck;
        _recentlyAdded = recentlyAdded;
        _isLoading = false;
      });
      appLogger.d('Discover content loaded successfully');
    } catch (e) {
      appLogger.e('Failed to load discover content', error: e);
      setState(() {
        _errorMessage = 'Failed to load content: $e';
        _isLoading = false;
      });
    }
  }

  // Public method to refresh content
  @override
  void refresh() {
    appLogger.d('DiscoverScreen.refresh() called');
    _loadContent();
  }

  Future<void> _handleSwitchServer() async {
    final storage = await StorageService.getInstance();
    final plexToken = storage.getPlexToken();

    if (plexToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No Plex token found. Please login again.'),
          ),
        );
      }
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading servers...'),
            ],
          ),
        ),
      );
    }

    try {
      // Fetch available servers
      final authService = await PlexAuthService.create();
      final servers = await authService.fetchServers(plexToken);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (servers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No servers found')));
        }
        return;
      }

      // Show server selection dialog
      if (mounted) {
        final selectedServer = await showDialog<PlexServer>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Switch Server'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: servers.length,
                itemBuilder: (context, index) {
                  final server = servers[index];
                  return ServerListTile(
                    server: server,
                    onTap: () => Navigator.pop(context, server),
                    showTrailingIcon: false,
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );

        if (selectedServer != null) {
          await _connectToServer(selectedServer);
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load servers: $e')));
      }
    }
  }

  Future<void> _connectToServer(PlexServer server) async {
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Testing connections...'),
            ],
          ),
        ),
      );
    }

    // Test connections to find best working one
    final connection = await server.findBestWorkingConnection();

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    if (connection == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No working connections found for this server'),
          ),
        );
      }
      return;
    }

    // Store server information
    final storage = await StorageService.getInstance();
    await storage.saveServerData(server.toJson());
    await storage.saveServerUrl(connection.uri);
    await storage.saveServerAccessToken(server.accessToken);

    // Get client identifier
    final clientId = storage.getClientIdentifier();
    if (clientId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client identifier not found')),
        );
      }
      return;
    }

    // Create new client
    final config = await PlexConfig.create(
      baseUrl: connection.uri,
      token: server.accessToken,
      clientIdentifier: clientId,
    );
    final client = PlexClient(config);

    // Replace current screen with main screen (includes bottom nav)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(client: client)),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final storage = await StorageService.getInstance();
      await storage.clearCredentials();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            DesktopSliverAppBar(
              title: const Text('Discover'),
              floating: true,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              scrolledUnderElevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadContent,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'switch_server') {
                      _handleSwitchServer();
                    } else if (value == 'logout') {
                      _handleLogout();
                    } else if (value == 'about') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'switch_server',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz),
                          SizedBox(width: 8),
                          Text('Switch Server'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'about',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8),
                          Text('About'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
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
                        onPressed: _loadContent,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_isLoading && _errorMessage == null) ...[
              // Hero Section (Continue Watching)
              if (_onDeck.isNotEmpty) _buildHeroSection(),

              // On Deck / Continue Watching
              if (_onDeck.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.play_circle_outline),
                        const SizedBox(width: 8),
                        Text(
                          'Continue Watching',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildHorizontalList(_onDeck, isLarge: false),
              ],

              // Recently Added
              if (_recentlyAdded.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.fiber_new),
                        const SizedBox(width: 8),
                        Text(
                          'Recently Added',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildHorizontalList(_recentlyAdded, isLarge: false),
              ],

              if (_onDeck.isEmpty && _recentlyAdded.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('No content available'),
                        SizedBox(height: 8),
                        Text(
                          'Add some media to your libraries',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 500,
        child: Stack(
          children: [
            PageView.builder(
              controller: _heroController,
              itemCount: _onDeck.length,
              onPageChanged: (index) {
                setState(() {
                  _currentHeroIndex = index;
                });
                _resetAutoScrollTimer();
              },
              itemBuilder: (context, index) {
                return _buildHeroItem(_onDeck[index]);
              },
            ),
            // Page indicators
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onDeck.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentHeroIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentHeroIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroItem(PlexMetadata heroItem) {
    final isEpisode = heroItem.type.toLowerCase() == 'episode';
    final showName = heroItem.grandparentTitle ?? heroItem.title;
    final episodeInfo =
        isEpisode && heroItem.parentIndex != null && heroItem.index != null
        ? 'S${heroItem.parentIndex} · E${heroItem.index} · ${heroItem.title}'
        : null;

    return GestureDetector(
      onTap: () {
        appLogger.d('Navigating to VideoPlayerScreen for: ${heroItem.title}');
        Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              client: widget.client,
              metadata: heroItem,
              userProfile: widget.userProfile,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image - use episode art or grandparent art
              if (heroItem.art != null || heroItem.grandparentArt != null)
                CachedNetworkImage(
                  imageUrl: widget.client.getThumbnailUrl(
                    heroItem.art ?? heroItem.grandparentArt,
                  ),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                )
              else
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 70,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show logo or name/title
                      if (heroItem.clearLogo != null)
                        SizedBox(
                          height: 120,
                          width: 400,
                          child: CachedNetworkImage(
                            imageUrl: widget.client.getThumbnailUrl(
                              heroItem.clearLogo,
                            ),
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            placeholder: (context, url) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                showName,
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              // Fallback to text if logo fails to load
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  showName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Text(
                          showName,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      // Episode info
                      if (episodeInfo != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            episodeInfo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],

                      // Summary
                      if (heroItem.summary != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          heroItem.summary!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Play Button
                      FilledButton.icon(
                        onPressed: () {
                          appLogger.d('Playing: ${heroItem.title}');
                          Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                client: widget.client,
                                metadata: heroItem,
                                userProfile: widget.userProfile,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text('Play'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(
    List<PlexMetadata> items, {
    bool isLarge = false,
  }) {
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive card width based on screen size
          final screenWidth = constraints.maxWidth;
          final cardWidth = screenWidth > 1600
              ? 220.0
              : screenWidth > 1200
              ? 200.0
              : screenWidth > 800
              ? 160.0
              : 130.0;

          // 2:3 poster aspect ratio (height is 1.5x width)
          final cardHeight = cardWidth * 1.5;
          // Container height = poster + padding + spacing + text
          // 8px top padding + cardHeight + 4px spacing + ~26px text + 8px bottom padding
          final containerHeight = cardHeight + 46;

          return SizedBox(
            height: containerHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: MediaCard(
                    client: widget.client,
                    item: item,
                    width: cardWidth,
                    height: cardHeight,
                    onRefresh: _loadContent,
                    userProfile: widget.userProfile,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
