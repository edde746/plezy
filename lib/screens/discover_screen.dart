import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../models/plex_hub.dart';
import '../providers/plex_client_provider.dart';
import '../services/storage_service.dart';
import '../services/plex_auth_service.dart';
import '../widgets/media_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/user_avatar_widget.dart';
import '../widgets/horizontal_scroll_with_arrows.dart';
import 'profile_switch_screen.dart';
import 'server_selection_screen.dart';
import 'hub_detail_screen.dart';
import '../providers/user_profile_provider.dart';
import '../providers/settings_provider.dart';
import '../mixins/refreshable.dart';
import '../i18n/strings.g.dart';
import '../mixins/item_updatable.dart';
import '../utils/app_logger.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../utils/content_rating_formatter.dart';
import '../utils/platform_detector.dart';
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
  List<PlexHub> _hubs = [];
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
      if (_onDeck.isEmpty ||
          !_heroController.hasClients ||
          _isAutoScrollPaused) {
        return;
      }

      // Validate current index is within bounds before calculating next page
      if (_currentHeroIndex >= _onDeck.length) {
        _currentHeroIndex = 0;
      }

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

  // Helper method to calculate visible dot range (max 5 dots)
  ({int start, int end}) _getVisibleDotRange() {
    final totalDots = _onDeck.length;
    if (totalDots <= 5) {
      return (start: 0, end: totalDots - 1);
    }

    // Center the active dot when possible
    final center = _currentHeroIndex;
    int start = (center - 2).clamp(0, totalDots - 5);
    int end = start + 4; // 5 dots total (0-4 inclusive)

    return (start: start, end: end);
  }

  // Helper method to determine dot size based on position
  double _getDotSize(int dotIndex, int start, int end) {
    final totalDots = _onDeck.length;

    // If we have 5 or fewer dots, all are full size (8px)
    if (totalDots <= 5) {
      return 8.0;
    }

    // First and last visible dots are smaller if there are more items beyond them
    final isFirstVisible = dotIndex == start && start > 0;
    final isLastVisible = dotIndex == end && end < totalDots - 1;

    if (isFirstVisible || isLastVisible) {
      return 5.0; // Smaller edge dots
    }

    return 8.0; // Normal size
  }

  Future<void> _loadContent() async {
    appLogger.d('Loading discover content');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      appLogger.d('Fetching onDeck and hubs from Plex');
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      final onDeck = await client.getOnDeck();

      // Load hubs from all libraries
      final libraries = await client.getLibraries();
      final allHubs = <PlexHub>[];

      for (final library in libraries) {
        // Skip libraries that are not movie/show or are hidden
        if (library.type != 'movie' && library.type != 'show') continue;
        if (library.hidden != 0) continue;

        try {
          final libraryHubs = await client.getLibraryHubs(
            library.key,
            limit: 12,
          );
          // Filter out duplicate hubs that we already fetch separately
          final filteredHubs = libraryHubs.where((hub) {
            final hubId = hub.hubIdentifier?.toLowerCase() ?? '';
            final title = hub.title.toLowerCase();
            // Skip "Continue Watching" and "On Deck" hubs (we handle these separately)
            return !hubId.contains('ondeck') &&
                !hubId.contains('continue') &&
                !title.contains('continue watching') &&
                !title.contains('on deck');
          }).toList();
          allHubs.addAll(filteredHubs);
        } catch (e) {
          appLogger.w(
            'Failed to load hubs for library ${library.title}',
            error: e,
          );
        }
      }

      appLogger.d(
        'Received ${onDeck.length} on deck items and ${allHubs.length} hubs',
      );

      // On TV, prioritize specific hubs for better UX
      final hubsToDisplay = PlatformDetector.isTVSync()
          ? _selectTVHubs(allHubs)
          : allHubs;

      setState(() {
        _onDeck = onDeck;
        _hubs = hubsToDisplay;
        _isLoading = false;

        // Reset hero index to avoid sync issues
        _currentHeroIndex = 0;
      });

      // Sync PageController to first page after data loads
      if (_heroController.hasClients && onDeck.isNotEmpty) {
        _heroController.jumpToPage(0);
      }

      appLogger.d('Discover content loaded successfully');
    } catch (e) {
      appLogger.e('Failed to load discover content', error: e);
      setState(() {
        _errorMessage = 'Failed to load content: $e';
        _isLoading = false;
      });
    }
  }

  /// Refresh only the Continue Watching section in the background
  /// This is called when returning to the home screen to avoid blocking UI
  Future<void> _refreshContinueWatching() async {
    appLogger.d('Refreshing Continue Watching in background');

    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        appLogger.w('No client available for background refresh');
        return;
      }

      final onDeck = await client.getOnDeck();

      if (mounted) {
        setState(() {
          _onDeck = onDeck;
          // Reset hero index if needed
          if (_currentHeroIndex >= onDeck.length) {
            _currentHeroIndex = 0;
            if (_heroController.hasClients && onDeck.isNotEmpty) {
              _heroController.jumpToPage(0);
            }
          }
        });
        appLogger.d('Continue Watching refreshed successfully');
      }
    } catch (e) {
      appLogger.w('Failed to refresh Continue Watching', error: e);
      // Silently fail - don't show error to user for background refresh
    }
  }

  // Public method to refresh content (for normal navigation)
  @override
  void refresh() {
    appLogger.d('DiscoverScreen.refresh() called');
    // Only refresh Continue Watching in background, not full screen reload
    _refreshContinueWatching();
  }

  // Public method to fully reload all content (for profile switches)
  void fullRefresh() {
    appLogger.d('DiscoverScreen.fullRefresh() called - reloading all content');
    // Reload all content including On Deck and content hubs
    _loadContent();
  }

  /// Select and prioritize hubs for TV display
  /// Prioritizes: Recently Released Movies, Recently Added Movies,
  /// Recently Released Shows, Recently Added Shows
  List<PlexHub> _selectTVHubs(List<PlexHub> allHubs) {
    final selectedHubs = <PlexHub>[];

    // Helper function to check if hub matches criteria
    bool matchesHub(PlexHub h, String action, List<String> types) {
      final title = h.title.toLowerCase();
      return title.contains(action) &&
          types.any((type) => title.contains(type));
    }

    // Priority checks for TV (in order of preference)
    final priorities = [
      (PlexHub h) => matchesHub(h, 'recently released', ['movie', 'film']),
      (PlexHub h) => matchesHub(h, 'recently added', ['movie', 'film']),
      (PlexHub h) =>
          matchesHub(h, 'recently released', ['show', 'tv', 'series']),
      (PlexHub h) => matchesHub(h, 'recently added', ['show', 'tv', 'series']),
    ];

    // Try to find hubs matching priorities
    for (final priorityCheck in priorities) {
      if (selectedHubs.length >= 4) break;

      try {
        final hub = allHubs.firstWhere(priorityCheck);

        // Only add if hub has items and wasn't already added
        if (hub.items.isNotEmpty &&
            !selectedHubs.any((h) => h.hubKey == hub.hubKey)) {
          selectedHubs.add(hub);
        }
      } catch (e) {
        // Hub not found, continue to next priority
      }
    }

    // If we don't have 4 hubs, fill with other non-empty hubs
    if (selectedHubs.length < 4) {
      for (final hub in allHubs) {
        if (selectedHubs.length >= 4) break;
        if (hub.items.isNotEmpty &&
            !selectedHubs.any((h) => h.hubKey == hub.hubKey)) {
          selectedHubs.add(hub);
        }
      }
    }

    return selectedHubs;
  }

  /// Get icon for hub based on its title
  IconData _getHubIcon(String title) {
    final lowerTitle = title.toLowerCase();

    // Trending/Popular content
    if (lowerTitle.contains('trending')) {
      return Icons.trending_up;
    }
    if (lowerTitle.contains('popular') || lowerTitle.contains('imdb')) {
      return Icons.whatshot;
    }

    // Seasonal/Time-based
    if (lowerTitle.contains('seasonal')) {
      return Icons.calendar_month;
    }
    if (lowerTitle.contains('newly') || lowerTitle.contains('new release')) {
      return Icons.new_releases;
    }
    if (lowerTitle.contains('recently released') ||
        lowerTitle.contains('recent')) {
      return Icons.schedule;
    }

    // Top/Rated content
    if (lowerTitle.contains('top rated') ||
        lowerTitle.contains('highest rated')) {
      return Icons.star;
    }
    if (lowerTitle.contains('top ')) {
      return Icons.military_tech;
    }

    // Genre-specific
    if (lowerTitle.contains('thriller')) {
      return Icons.warning_amber_rounded;
    }
    if (lowerTitle.contains('comedy') || lowerTitle.contains('comedier')) {
      return Icons.mood;
    }
    if (lowerTitle.contains('action')) {
      return Icons.flash_on;
    }
    if (lowerTitle.contains('drama')) {
      return Icons.theater_comedy;
    }
    if (lowerTitle.contains('fantasy')) {
      return Icons.auto_fix_high;
    }
    if (lowerTitle.contains('science') || lowerTitle.contains('sci-fi')) {
      return Icons.rocket_launch;
    }
    if (lowerTitle.contains('horror') || lowerTitle.contains('skräck')) {
      return Icons.nights_stay;
    }
    if (lowerTitle.contains('romance') || lowerTitle.contains('romantic')) {
      return Icons.favorite_border;
    }
    if (lowerTitle.contains('adventure') || lowerTitle.contains('äventyr')) {
      return Icons.explore;
    }

    // Watchlist/Playlists
    if (lowerTitle.contains('playlist') || lowerTitle.contains('watchlist')) {
      return Icons.playlist_play;
    }
    if (lowerTitle.contains('unwatched') || lowerTitle.contains('unplayed')) {
      return Icons.visibility_off;
    }
    if (lowerTitle.contains('watched') || lowerTitle.contains('played')) {
      return Icons.visibility;
    }

    // Network/Studio
    if (lowerTitle.contains('network') || lowerTitle.contains('more from')) {
      return Icons.tv;
    }

    // Actor/Director
    if (lowerTitle.contains('actor') || lowerTitle.contains('director')) {
      return Icons.person;
    }

    // Year-based (80s, 90s, etc.)
    if (lowerTitle.contains('80') ||
        lowerTitle.contains('90') ||
        lowerTitle.contains('00')) {
      return Icons.history;
    }

    // Rediscover/Start Watching
    if (lowerTitle.contains('rediscover') ||
        lowerTitle.contains('start watching')) {
      return Icons.play_arrow;
    }

    // Default icon for other hubs
    return Icons.auto_awesome;
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

    // Check and update in hub items
    for (final hub in _hubs) {
      final itemIndex = hub.items.indexWhere(
        (item) => item.ratingKey == ratingKey,
      );
      if (itemIndex != -1) {
        hub.items[itemIndex] = updatedMetadata;
      }
    }
  }

  Future<void> _handleSwitchServer() async {
    final storage = await StorageService.getInstance();
    final plexToken = storage.getPlexToken();

    if (plexToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.messages.noPlexToken)));
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
          SnackBar(content: Text(t.messages.errorLoading(error: e.toString()))),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.common.logout),
        content: Text(t.messages.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.common.logout),
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
              title: Text(t.discover.title),
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
                          PopupMenuItem(
                            value: 'switch_profile',
                            child: Row(
                              children: [
                                Icon(Icons.people),
                                SizedBox(width: 8),
                                Text(t.discover.switchProfile),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'switch_server',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz),
                              SizedBox(width: 8),
                              Text(t.discover.switchServer),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: 8),
                              Text(t.discover.logout),
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
                        child: Text(t.common.retry),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_isLoading && _errorMessage == null) ...[
              // Hero Section (Continue Watching) - Hidden on TV for now
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, child) {
                  final isTV = PlatformDetector.isTVSync();
                  if (_onDeck.isNotEmpty &&
                      settingsProvider.showHeroSection &&
                      !isTV) {
                    return _buildHeroSection();
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),

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
                          t.discover.continueWatching,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildHorizontalList(
                  _onDeck,
                  isLarge: false,
                  isInContinueWatching: true,
                ),
              ],

              // Recommendation Hubs (Trending, Top in Genre, etc.)
              // On TV, hubs are pre-filtered by _selectTVHubs to show relevant content
              for (final hub in _hubs) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HubDetailScreen(hub: hub),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(_getHubIcon(hub.title)),
                            const SizedBox(width: 8),
                            Text(
                              hub.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildHorizontalList(hub.items, isLarge: false),
              ],

              if (_onDeck.isEmpty && _hubs.isEmpty)
                SliverFillRemaining(
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
                        Text(t.discover.noContentAvailable),
                        SizedBox(height: 8),
                        Text(
                          t.discover.addMediaToLibraries,
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
    final isTV = PlatformDetector.isTVSync();

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 500,
        child: Stack(
          children: [
            PageView.builder(
              controller: _heroController,
              itemCount: _onDeck.length,
              onPageChanged: (index) {
                // Validate index is within bounds before updating
                if (index >= 0 && index < _onDeck.length) {
                  setState(() {
                    _currentHeroIndex = index;
                  });
                  _resetAutoScrollTimer();
                }
              },
              itemBuilder: (context, index) {
                return _buildHeroItem(_onDeck[index]);
              },
            ),
            // Navigation arrows for TV (non-focusable, visual only)
            if (isTV && _onDeck.length > 1) ...[
              // Left arrow
              if (_currentHeroIndex > 0)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 80,
                  child: Center(
                    child: Focus(
                      canRequestFocus: false,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, size: 48),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          if (_currentHeroIndex > 0) {
                            _heroController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              // Right arrow
              if (_currentHeroIndex < _onDeck.length - 1)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 80,
                  child: Center(
                    child: Focus(
                      canRequestFocus: false,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, size: 48),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          if (_currentHeroIndex < _onDeck.length - 1) {
                            _heroController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
            ],
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
                          '${_isAutoScrollPaused ? t.discover.play : t.discover.pause} auto-scroll',
                    ),
                  ),
                  // Spacer to separate indicators from button
                  const SizedBox(width: 8),
                  // Page indicators (limited to 5 dots)
                  ...() {
                    final range = _getVisibleDotRange();
                    return List.generate(range.end - range.start + 1, (i) {
                      final index = range.start + i;
                      final isActive = _currentHeroIndex == index;
                      final dotSize = _getDotSize(
                        index,
                        range.start,
                        range.end,
                      );

                      if (isActive) {
                        // Animated progress indicator for active page
                        return AnimatedBuilder(
                          animation: _indicatorAnimationController,
                          builder: (context, child) {
                            // Fill width animates based on dot size
                            final maxWidth =
                                dotSize * 3; // 24px for normal, 15px for small
                            final fillWidth =
                                dotSize +
                                ((maxWidth - dotSize) *
                                    _indicatorAnimationController.value);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: maxWidth,
                              height: dotSize,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(
                                  dotSize / 2,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: fillWidth,
                                  height: dotSize,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      dotSize / 2,
                                    ),
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
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(dotSize / 2),
                          ),
                        );
                      }
                    });
                  }(),
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
    final isTV = PlatformDetector.isTVSync();

    // Determine content type label for chip
    final contentTypeLabel = heroItem.type.toLowerCase() == 'movie'
        ? t.discover.movie
        : t.discover.tvShow;

    return Focus(
      onKeyEvent: isTV
          ? (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  if (_currentHeroIndex > 0) {
                    _heroController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    return KeyEventResult.handled;
                  }
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  if (_currentHeroIndex < _onDeck.length - 1) {
                    _heroController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    return KeyEventResult.handled;
                  }
                }
              }
              return KeyEventResult.ignored;
            }
          : null,
      child: Semantics(
        label: "media-hero-${heroItem.ratingKey}",
        identifier: "media-hero-${heroItem.ratingKey}",
        button: true,
        hint: "Tap to play ${heroItem.title}",
        child: GestureDetector(
          onTap: () {
            final clientProvider = context.plexClient;
            final client = clientProvider.client;
            if (client == null) return;

            appLogger.d(
              'Navigating to VideoPlayerScreen for: ${heroItem.title}',
            );
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
                                  '★ ${heroItem.rating!.toStringAsFixed(1)}',
                                if (heroItem.contentRating != null)
                                  formatContentRating(heroItem.contentRating!),
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
                t.discover.minutesLeft(minutes: minutesLeft),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else
              Text(
                t.discover.play,
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
    bool isInContinueWatching = false,
  }) {
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive card width based on screen size
          // Match Libraries screen sizing (190px baseline)
          final screenWidth = constraints.maxWidth;
          final cardWidth = screenWidth > 1600
              ? 220.0
              : screenWidth > 1200
              ? 200.0
              : screenWidth > 800
              ? 190.0
              : 160.0;

          // MediaCard has 8px padding on all sides (16px total horizontally)
          // So actual poster width is cardWidth - 16
          final posterWidth = cardWidth - 16;
          // 2:3 poster aspect ratio (height is 1.5x width)
          final posterHeight = posterWidth * 1.5;
          // Container height = poster + padding + spacing + text
          // 8px top padding + posterHeight + 4px spacing + ~26px text + 8px bottom padding
          final containerHeight = posterHeight + 46;

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
                      height: posterHeight,
                      onRefresh: updateItem,
                      onRemoveFromContinueWatching: isInContinueWatching
                          ? _refreshContinueWatching
                          : null,
                      forceGridMode: true,
                      isInContinueWatching: isInContinueWatching,
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
