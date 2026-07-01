import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/seerr/seerr_search_result.dart';
import '../../providers/seerr_discover_provider.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/loading_indicator_box.dart';
import 'seerr_detail_screen.dart';
import 'widgets/seerr_media_card.dart';

/// "View all" screen for a single discover hub — paginated poster grid
/// backed by the same [SeerrDiscoverProvider] hub state as the row on the
/// Discover tab. Infinite scrolls as the user nears the bottom.
class SeerrHubDetailScreen extends StatefulWidget {
  final SeerrHubId hubId;
  final String title;
  final IconData icon;

  const SeerrHubDetailScreen({super.key, required this.hubId, required this.title, required this.icon});

  @override
  State<SeerrHubDetailScreen> createState() => _SeerrHubDetailScreenState();
}

class _SeerrHubDetailScreenState extends State<SeerrHubDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SeerrDiscoverProvider>().loadIfNeeded(widget.hubId);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final remaining = _scrollController.position.maxScrollExtent - _scrollController.position.pixels;
    if (remaining < 480) {
      context.read<SeerrDiscoverProvider>().loadMore(widget.hubId);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _openDetail(SeerrSearchResult r) {
    final title = switch (r) {
      SeerrMovieResult(:final title) => title,
      SeerrTvResult(:final name) => name,
      SeerrPersonResult(:final name) => name,
    };
    final poster = switch (r) {
      SeerrMovieResult(:final posterPath) => posterPath,
      SeerrTvResult(:final posterPath) => posterPath,
      SeerrPersonResult(:final profilePath) => profilePath,
    };
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SeerrDetailScreen(tmdbId: r.id, mediaType: r.mediaType, initialTitle: title, initialPosterPath: poster),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SeerrDiscoverProvider>(
      builder: (context, provider, _) {
        final state = provider.hub(widget.hubId);
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [AppIcon(widget.icon, fill: 1, size: 22), const SizedBox(width: 8), Text(widget.title)],
            ),
          ),
          body: CustomScrollView(
            controller: _scrollController,
            // Keep ahead-of-viewport rows built so d-pad nav between grid
            // rows lands on real focus nodes instead of dropping focus.
            cacheExtent: 800,
            slivers: [
              if (state.state == SeerrHubLoadState.loading && state.results.isEmpty)
                const SliverFillRemaining(child: Center(child: LoadingIndicatorBox(size: 32)))
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.52,
                    ),
                    delegate: SliverChildBuilderDelegate((context, i) {
                      if (i >= state.results.length) return null;
                      final r = state.results[i];
                      return SeerrMediaCard(result: r, onTap: () => _openDetail(r), width: 160);
                    }, childCount: state.results.length),
                  ),
                ),
              if (state.loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: LoadingIndicatorBox()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
