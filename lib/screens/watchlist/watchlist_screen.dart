import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection_registry.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_item.dart';
import '../../mixins/refreshable.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/plex_watchlist_service.dart';
import '../../services/settings_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/grid_size_calculator.dart';
import '../../utils/media_navigation_helper.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/media_grid_delegate.dart';
import '../../widgets/optimized_media_image.dart';
import '../../widgets/settings_builder.dart';
import '../libraries/state_messages.dart';
import '../main_screen.dart';

/// Read-only Plex Watchlist screen. Lists the account's watchlisted movies and
/// shows as a poster grid. Tapping an item opens its detail page if the title
/// exists on a connected Plex server (matched by GUID); otherwise a brief
/// message is shown. The tab is only registered when a Plex.tv account is
/// connected (see navigation gating in main_screen).
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => WatchlistScreenState();
}

class WatchlistScreenState extends State<WatchlistScreen> with FocusableTab, Refreshable {
  PlexWatchlistService? _service;
  List<MediaItem> _items = const [];
  bool _loading = true;
  String? _error;

  final FocusNode _firstItemFocusNode = FocusNode(debugLabel: 'watchlist_first_item');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstItemFocusNode.dispose();
    _service?.dispose();
    super.dispose();
  }

  @override
  void refresh() => _load();

  @override
  void focusActiveTabIfReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _firstItemFocusNode.requestFocus();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accounts = await context.read<ConnectionRegistry>().listPlexAccounts();
      final account = accounts.firstWhereOrNull((a) => a.accountToken.isNotEmpty);
      if (account == null) {
        if (!mounted) return;
        setState(() {
          _items = const [];
          _loading = false;
        });
        return;
      }

      _service?.dispose();
      final service = PlexWatchlistService(
        accountToken: account.accountToken,
        clientIdentifier: account.clientIdentifier,
      );
      _service = service;

      final items = await service.getWatchlist();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e, st) {
      appLogger.e('WatchlistScreen: failed to load watchlist', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Resolve a watchlist item to a server library item by Plex GUID and open
  /// its detail page; otherwise show a "not on your servers" message.
  Future<void> _openItem(MediaItem item) async {
    final guid = item.guid;
    final messenger = ScaffoldMessenger.of(context);
    if (guid == null || guid.isEmpty) {
      _showNotOnServers(messenger);
      return;
    }

    final manager = context.read<MultiServerProvider>().serverManager;
    MediaItem? match;
    for (final serverId in manager.onlineServerIds) {
      final client = manager.getPlexClient(serverId);
      if (client == null) continue;
      match = await client.findByGuid(guid);
      if (match != null) break;
    }

    if (!mounted) return;
    if (match != null) {
      await navigateToMediaItem(context, match);
    } else {
      _showNotOnServers(messenger);
    }
  }

  void _showNotOnServers(ScaffoldMessengerState messenger) {
    messenger.showSnackBar(SnackBar(content: Text(t.watchlist.notOnServers)));
  }

  void _navigateToSidebar() {
    MainScreenFocusScope.of(context, listen: false)?.focusSidebar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: [
          DesktopSliverAppBar(
            title: Text(t.watchlist.title),
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
          ),
          SliverFillRemaining(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.error_outline_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(t.watchlist.loadFailed),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: Text(t.common.retry)),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return EmptyStateWidget(
        message: t.watchlist.empty,
        subtitle: t.watchlist.emptyDescription,
        icon: Symbols.bookmark_rounded,
        iconSize: 80,
      );
    }

    const effectivePadding = EdgeInsets.only(left: 8, right: 8, top: 8);
    return SettingValueBuilder<int>(
      pref: SettingsService.libraryDensity,
      builder: (context, density, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, density);
            final availableWidth = constraints.maxWidth - effectivePadding.left - effectivePadding.right;
            final columnCount = GridSizeCalculator.getColumnCount(availableWidth, maxExtent);

            return GridView.builder(
              padding: effectivePadding,
              clipBehavior: Clip.none,
              gridDelegate: MediaGridDelegate.createDelegate(context: context, density: density),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isFirst = index == 0;
                final isFirstColumn = GridSizeCalculator.isFirstColumn(index, columnCount);
                return _WatchlistCard(
                  item: item,
                  focusNode: isFirst ? _firstItemFocusNode : null,
                  onSelect: () => _openItem(item),
                  onNavigateLeft: isFirstColumn ? _navigateToSidebar : null,
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Poster cell for the watchlist grid. Mirrors [MediaCard]'s grid layout
/// (poster filling the cell + a title line) but with `client: null` image
/// resolution (the watchlist carries absolute cloud image URLs) and a custom
/// tap handler instead of MediaCard's server-backed navigation.
class _WatchlistCard extends StatelessWidget {
  final MediaItem item;
  final FocusNode? focusNode;
  final VoidCallback onSelect;
  final VoidCallback? onNavigateLeft;

  const _WatchlistCard({required this.item, required this.onSelect, this.focusNode, this.onNavigateLeft});

  @override
  Widget build(BuildContext context) {
    return FocusableWrapper(
      focusNode: focusNode,
      onSelect: onSelect,
      onNavigateLeft: onNavigateLeft,
      child: InkWell(
        canRequestFocus: false,
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 3, 3, 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: OptimizedMediaImage.poster(
                    client: null,
                    imagePath: item.thumbPath,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
