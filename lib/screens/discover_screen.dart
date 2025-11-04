import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../providers/plex_client_provider.dart';
import '../services/storage_service.dart';
import '../services/plex_auth_service.dart';
import '../widgets/media_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/user_avatar_widget.dart';
import '../widgets/horizontal_scroll_with_arrows.dart';
import 'profile_switch_screen.dart';
import 'server_selection_screen.dart';
import '../providers/user_profile_provider.dart';
import '../mixins/refreshable.dart';
import '../mixins/item_updatable.dart';
import '../utils/app_logger.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import 'auth_screen.dart';

class DiscoverScreen extends StatefulWidget {
  final VoidCallback? onBecameVisible;

  const DiscoverScreen({super.key, this.onBecameVisible});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with Refreshable, ItemUpdatable, SingleTickerProviderStateMixin {
  static const Duration _heroAutoScrollDuration = Duration(seconds: 8);

  @override
  PlexClient get client => context.clientSafe;

  List<PlexMetadata> _onDeck = [];
  List<PlexMetadata> _recentlyAdded = [];
  bool _isLoading = true;
  String? _errorMessage;
  final PageController _heroController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentHeroIndex = 0;
  Timer? _autoScrollTimer;
  late AnimationController _indicatorAnimationController;
  bool _isAutoScrollPaused = false;

  @override
  void initState() {
    super.initState();
    _indicatorAnimationController = AnimationController(
      vsync: this,
      duration: _heroAutoScrollDuration,
    );
    _loadContent();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _heroController.dispose();
    _scrollController.dispose();
    _indicatorAnimationController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (_isAutoScrollPaused) return;

    _indicatorAnimationController.forward(from: 0.0);
    _autoScrollTimer = Timer.periodic(_heroAutoScrollDuration, (timer) {
      if (_onDeck.isEmpty || !_heroController.hasClients || _isAutoScrollPaused)
        return;

      final nextPage = (_currentHeroIndex + 1) % _onDeck.length;
      _heroController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      // Wait for page transition to complete before resetting progress
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isAutoScrollPaused) {
          _indicatorAnimationController.forward(from: 0.0);
        }
      });
    });
  }

  void _resetAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  void _pauseAutoScroll() {
    setState(() {
      _isAutoScrollPaused = true;
    });
    _autoScrollTimer?.cancel();
    _indicatorAnimationController.stop();
  }

  void _resumeAutoScroll() {
    setState(() {
      _isAutoScrollPaused = false;
    });
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
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      final onDeck = await client.getOnDeck();
      final recentlyAdded = await client.getRecentlyAdded(limit: 20);

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

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    // Check and update in _onDeck list
    final onDeckIndex = _onDeck.indexWhere(
      (item) => item.ratingKey == ratingKey,
    );
    if (onDeckIndex != -1) {
      _onDeck[onDeckIndex] = updatedMetadata;
    }

    // Check and update in _recentlyAdded list
    final recentlyAddedIndex = _recentlyAdded.indexWhere(
      (item) => item.ratingKey == ratingKey,
    );
    if (recentlyAddedIndex != -1) {
      _recentlyAdded[recentlyAddedIndex] = updatedMetadata;
    }
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

    try {
      final authService = await PlexAuthService.create();

      // Navigate to server selection screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServerSelectionScreen(
              authService: authService,
              plexToken: plexToken,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize server selection: $e')),
        );
      }
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
      // Use comprehensive logout through UserProfileProvider
      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );
      final plexClientProvider = Provider.of<PlexClientProvider>(
        context,
        listen: false,
      );

      // Clear all user data and provider states
      await userProfileProvider.logout();
      plexClientProvider.clearClient();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  void _handleSwitchProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSwitchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
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
                Consumer<UserProfileProvider>(
                  builder: (context, userProvider, child) {
                    return PopupMenuButton<String>(
                      icon: userProvider.currentUser?.thumb != null
                          ? UserAvatarWidget(
                              user: userProvider.currentUser!,
                              size: 32,
                              showIndicators: false,
                            )
                          : const Icon(Icons.account_circle, size: 32),
                      onSelected: (value) {
                        if (value == 'switch_profile') {
                          _handleSwitchProfile(context);
                        } else if (value == 'switch_server') {
                          _handleSwitchServer();
                        } else if (value == 'logout') {
                          _handleLogout();
                        }
                      },
                      itemBuilder: (context) => [
                        // Only show Switch Profile if multiple users available
                        if (userProvider.hasMultipleUsers)
                          const PopupMenuItem(
                            value: 'switch_profile',
                            child: Row(
                              children: [
                                Icon(Icons.people),
                                SizedBox(width: 8),
                                Text('Switch Profile'),
                              ],
                            ),
                          ),
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
                    );
                  },
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
            // Page indicators with animated progress and pause/play button
            Positioned(
              bottom: 16,
              left: -26,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pause/Play button
                  GestureDetector(
                    onTap: () {
                      if (_isAutoScrollPaused) {
                        _resumeAutoScroll();
                      } else {
                        _pauseAutoScroll();
                      }
                    },
                    child: Icon(
                      _isAutoScrollPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 18,
                      semanticLabel:
                          '${_isAutoScrollPaused ? 'Play' : 'Pause'} auto-scroll',
                    ),
                  ),
                  // Spacer to separate indicators from button
                  const SizedBox(width: 8),
                  // Page indicators
                  ...List.generate(_onDeck.length, (index) {
                    final isActive = _currentHeroIndex == index;
                    if (isActive) {
                      // Animated progress indicator for active page
                      return AnimatedBuilder(
                        animation: _indicatorAnimationController,
                        builder: (context, child) {
                          // Fill width animates from 8px to 24px
                          final fillWidth =
                              8.0 +
                              (16.0 * _indicatorAnimationController.value);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 24,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: fillWidth,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      // Static indicator for inactive pages
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }
                  }),
                ],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;

    // Determine content type label for chip
    final contentTypeLabel = heroItem.type.toLowerCase() == 'movie'
        ? 'Movie'
        : 'TV Show';

    return Semantics(
      label: "media-hero-${heroItem.ratingKey}",
      identifier: "media-hero-${heroItem.ratingKey}",
      button: true,
      hint: "Tap to play ${heroItem.title}",
      child: GestureDetector(
        onTap: () {
          final clientProvider = context.plexClient;
          final client = clientProvider.client;
          if (client == null) return;

          appLogger.d('Navigating to VideoPlayerScreen for: ${heroItem.title}');
          navigateToVideoPlayer(context, metadata: heroItem);
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
                // Background Image with fade/zoom animation and parallax
                if (heroItem.art != null || heroItem.grandparentArt != null)
                  AnimatedBuilder(
                    animation: _scrollController,
                    builder: (context, child) {
                      final scrollOffset = _scrollController.hasClients
                          ? _scrollController.offset
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(0, scrollOffset * 0.3),
                        child: child,
                      );
                    },
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 1.0 + (0.1 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Consumer<PlexClientProvider>(
                        builder: (context, clientProvider, child) {
                          final client = clientProvider.client;
                          if (client == null) {
                            return Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            );
                          }
                          return CachedNetworkImage(
                            imageUrl: client.getThumbnailUrl(
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
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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

                // Content with responsive alignment
                Positioned(
                  bottom: isLargeScreen ? 80 : 50,
                  left: 0,
                  right: isLargeScreen ? 200 : 0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 40 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: isLargeScreen
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show logo or name/title
                        if (heroItem.clearLogo != null)
                          SizedBox(
                            height: 120,
                            width: 400,
                            child: Consumer<PlexClientProvider>(
                              builder: (context, clientProvider, child) {
                                final client = clientProvider.client;
                                if (client == null) {
                                  return Container();
                                }
                                return CachedNetworkImage(
                                  imageUrl: client.getThumbnailUrl(
                                    heroItem.clearLogo,
                                  ),
                                  filterQuality: FilterQuality.medium,
                                  fit: BoxFit.contain,
                                  alignment: isLargeScreen
                                      ? Alignment.bottomLeft
                                      : Alignment.bottomCenter,
                                  placeholder: (context, url) => Align(
                                    alignment: isLargeScreen
                                        ? Alignment.centerLeft
                                        : Alignment.center,
                                    child: Text(
                                      showName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
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
                                      textAlign: isLargeScreen
                                          ? TextAlign.left
                                          : TextAlign.center,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    // Fallback to text if logo fails to load
                                    return Align(
                                      alignment: isLargeScreen
                                          ? Alignment.centerLeft
                                          : Alignment.center,
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
                                                  color: Colors.black
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: isLargeScreen
                                            ? TextAlign.left
                                            : TextAlign.center,
                                      ),
                                    );
                                  },
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
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: isLargeScreen
                                ? TextAlign.left
                                : TextAlign.center,
                          ),

                        // Metadata as dot-separated text with content type
                        if (heroItem.year != null ||
                            heroItem.contentRating != null ||
                            heroItem.rating != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            [
                              contentTypeLabel,
                              if (heroItem.rating != null)
                                '★ ${(heroItem.rating! / 10).toStringAsFixed(1)}',
                              if (heroItem.contentRating != null)
                                heroItem.contentRating!,
                              if (heroItem.year != null)
                                heroItem.year.toString(),
                            ].join(' • '),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: isLargeScreen
                                ? TextAlign.left
                                : TextAlign.center,
                          ),
                        ],

                        // On small screens: show button before summary
                        if (!isLargeScreen) ...[
                          const SizedBox(height: 20),
                          _buildSmartPlayButton(heroItem),
                        ],

                        // Summary with episode info (Apple TV style)
                        if (heroItem.summary != null) ...[
                          const SizedBox(height: 12),
                          RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: isLargeScreen
                                ? TextAlign.left
                                : TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                              children: [
                                if (isEpisode &&
                                    heroItem.parentIndex != null &&
                                    heroItem.index != null)
                                  TextSpan(
                                    text:
                                        'S${heroItem.parentIndex}, E${heroItem.index}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                TextSpan(
                                  text: heroItem.summary?.isNotEmpty == true
                                      ? heroItem.summary!
                                      : 'No description available',
                                ),
                              ],
                            ),
                          ),
                        ],

                        // On large screens: show button after summary
                        if (isLargeScreen) ...[
                          const SizedBox(height: 20),
                          _buildSmartPlayButton(heroItem),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartPlayButton(PlexMetadata heroItem) {
    final hasProgress =
        heroItem.viewOffset != null &&
        heroItem.duration != null &&
        heroItem.viewOffset! > 0 &&
        heroItem.duration! > 0;

    final minutesLeft = hasProgress
        ? ((heroItem.duration! - heroItem.viewOffset!) / 60000).round()
        : 0;

    final progress = hasProgress
        ? heroItem.viewOffset! / heroItem.duration!
        : 0.0;

    return InkWell(
      onTap: () {
        final clientProvider = context.plexClient;
        final client = clientProvider.client;
        if (client == null) return;

        appLogger.d('Playing: ${heroItem.title}');
        navigateToVideoPlayer(context, metadata: heroItem);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow, size: 20, color: Colors.black),
            const SizedBox(width: 8),
            if (hasProgress) ...[
              // Progress bar
              Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$minutesLeft min left',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else
              const Text(
                'Play',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
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
            child: HorizontalScrollWithArrows(
              builder: (scrollController) => ListView.builder(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: MediaCard(
                      key: Key(item.ratingKey),
                      item: item,
                      width: cardWidth,
                      height: cardHeight,
                      onRefresh: updateItem,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
