import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plex_metadata.dart';
import '../client/plex_client.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../widgets/media_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../mixins/item_updatable.dart';

/// Screen showing books by a specific author
///
/// Similar to SeasonDetailScreen but for audiobook authors.
/// Displays all books (albums) by the selected author.
class AuthorBooksScreen extends StatefulWidget {
  final PlexMetadata author;

  const AuthorBooksScreen({
    super.key,
    required this.author,
  });

  @override
  State<AuthorBooksScreen> createState() => _AuthorBooksScreenState();
}

class _AuthorBooksScreenState extends State<AuthorBooksScreen>
    with ItemUpdatable {
  @override
  PlexClient get client => context.clientSafe;

  List<PlexMetadata> _books = [];
  bool _isLoadingBooks = false;
  bool _watchStateChanged = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoadingBooks = true;
    });

    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      final books = await client.getChildren(widget.author.ratingKey);
      setState(() {
        _books = books;
        _isLoadingBooks = false;
      });
    } catch (e) {
      appLogger.e('Failed to load books', error: e);
      setState(() {
        _isLoadingBooks = false;
      });
    }
  }

  @override
  Future<void> updateItem(String ratingKey) async {
    _watchStateChanged = true;
    await super.updateItem(ratingKey);
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    final index = _books.indexWhere((item) => item.ratingKey == ratingKey);
    if (index != -1) {
      _books[index] = updatedMetadata;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.author.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            pinned: true,
            onBackPressed: () => Navigator.pop(context, _watchStateChanged),
          ),
          // Artist bio/summary section
          if (widget.author.summary != null && widget.author.summary!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.author.summary!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoadingBooks)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_books.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No books found'),
                  ],
                ),
              ),
            )
          else
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                if (settingsProvider.viewMode == ViewMode.list) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final book = _books[index];
                        return MediaCard(
                          key: Key(book.ratingKey),
                          item: book,
                          onRefresh: updateItem,
                        );
                      }, childCount: _books.length),
                    ),
                  );
                } else {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: _getMaxCrossAxisExtent(
                          context,
                          settingsProvider.libraryDensity,
                        ),
                        childAspectRatio: 1.0,  // Square aspect ratio for audiobook covers
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final book = _books[index];
                        return MediaCard(
                          key: Key(book.ratingKey),
                          item: book,
                          onRefresh: updateItem,
                        );
                      }, childCount: _books.length),
                    ),
                  );
                }
              },
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

      return (availableWidth / divisor).clamp(0, maxItemWidth);
    } else if (screenWidth >= 600) {
      int targetItemCount = switch (density) {
        LibraryDensity.comfortable => 4,
        LibraryDensity.normal => 5,
        LibraryDensity.compact => 6,
      };
      return availableWidth / targetItemCount;
    } else {
      int targetItemCount = switch (density) {
        LibraryDensity.comfortable => 2,
        LibraryDensity.normal => 3,
        LibraryDensity.compact => 4,
      };
      return availableWidth / targetItemCount;
    }
  }
}
