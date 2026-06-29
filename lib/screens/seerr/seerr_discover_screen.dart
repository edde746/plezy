import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/seerr/seerr_search_result.dart';
import '../../providers/seerr_discover_provider.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/loading_indicator_box.dart';
import 'seerr_detail_screen.dart';
import 'widgets/seerr_media_card.dart';

/// Three horizontal "hub" rows: Trending, Popular Movies, Popular TV. Each
/// hub lazy-loads on first build and renders a horizontally scrollable row
/// of [SeerrMediaCard]s.
class SeerrDiscoverScreen extends StatefulWidget {
  const SeerrDiscoverScreen({super.key});

  @override
  State<SeerrDiscoverScreen> createState() => _SeerrDiscoverScreenState();
}

class _SeerrDiscoverScreenState extends State<SeerrDiscoverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SeerrDiscoverProvider>();
      for (final id in SeerrHubId.values) {
        provider.loadIfNeeded(id);
      }
    });
  }

  Future<void> _refresh() async {
    final provider = context.read<SeerrDiscoverProvider>();
    for (final id in SeerrHubId.values) {
      await provider.retry(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _Hub(id: SeerrHubId.trending, title: t.seerr.discover.trending, icon: Symbols.local_fire_department_rounded),
          _Hub(id: SeerrHubId.popularMovies, title: t.seerr.discover.popularMovies, icon: Symbols.movie_rounded),
          _Hub(id: SeerrHubId.popularTv, title: t.seerr.discover.popularTv, icon: Symbols.live_tv_rounded),
        ],
      ),
    );
  }
}

class _Hub extends StatelessWidget {
  final SeerrHubId id;
  final String title;
  final IconData icon;

  const _Hub({required this.id, required this.title, required this.icon});

  void _openDetail(BuildContext context, SeerrSearchResult r) {
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
        builder: (_) => SeerrDetailScreen(
          tmdbId: r.id,
          mediaType: r.mediaType,
          initialTitle: title,
          initialPosterPath: poster,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<SeerrDiscoverProvider>(
      builder: (context, provider, _) {
        final state = provider.hub(id);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    AppIcon(icon, fill: 1, size: 20),
                    const SizedBox(width: 8),
                    Text(title, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: _hubBody(context, theme, state, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hubBody(BuildContext context, ThemeData theme, SeerrHubState state, SeerrDiscoverProvider provider) {
    if (state.state == SeerrHubLoadState.loading && state.results.isEmpty) {
      return const Center(child: LoadingIndicatorBox(size: 24));
    }
    if (state.state == SeerrHubLoadState.error && state.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.seerr.discover.failed,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                icon: const AppIcon(Symbols.refresh_rounded, fill: 1, size: 16),
                onPressed: () => provider.retry(id),
                label: Text(t.seerr.discover.retry),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.results.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        if (i >= state.results.length) {
          provider.loadMore(id);
          return const SizedBox(width: 132, child: Center(child: LoadingIndicatorBox()));
        }
        final r = state.results[i];
        return SeerrMediaCard(result: r, onTap: () => _openDetail(context, r));
      },
    );
  }
}
