import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/plex_library.dart';
import '../../models/plex_metadata.dart';
import '../../providers/plex_client_provider.dart';
import '../../utils/app_logger.dart';
import '../../utils/library_refresh_notifier.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/refreshable.dart';
import '../../widgets/content_state_builder.dart';
import '../../widgets/adaptive_media_grid.dart';

/// Collections tab for library screen
/// Shows collections for the current library
class LibraryCollectionsTab extends StatefulWidget {
  final PlexLibrary library;
  final String? viewMode;
  final String? density;

  const LibraryCollectionsTab({
    super.key,
    required this.library,
    this.viewMode,
    this.density,
  });

  @override
  State<LibraryCollectionsTab> createState() => _LibraryCollectionsTabState();
}

class _LibraryCollectionsTabState extends State<LibraryCollectionsTab>
    with AutomaticKeepAliveClientMixin, Refreshable {
  @override
  bool get wantKeepAlive => true;

  @override
  void refresh() {
    _loadCollections();
  }

  List<PlexMetadata> _collections = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _loadCollections();

    // Listen for refresh notifications
    _refreshSubscription = LibraryRefreshNotifier().collectionsStream.listen((
      _,
    ) {
      if (mounted) {
        _loadCollections();
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(LibraryCollectionsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if library changed
    if (oldWidget.library.key != widget.library.key) {
      _loadCollections();
    }
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = context.read<PlexClientProvider>().client;
      if (client == null) {
        throw Exception(t.errors.noClientAvailable);
      }

      final collections = await client.getLibraryCollections(
        widget.library.key,
      );

      if (!mounted) return;

      setState(() {
        _collections = collections;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      appLogger.e('Error loading collections', error: e);
      setState(() {
        _errorMessage = t.errors.failedToLoad(
          context: t.collections.title,
          error: e.toString(),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return ContentStateBuilder<PlexMetadata>(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      items: _collections,
      emptyIcon: Icons.collections,
      emptyMessage: t.libraries.noCollections,
      onRetry: _loadCollections,
      builder: (items) => RefreshIndicator(
        onRefresh: _loadCollections,
        child: AdaptiveMediaGrid(items: items, onRefresh: _loadCollections),
      ),
    );
  }
}
