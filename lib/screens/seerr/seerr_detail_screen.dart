import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/seerr/seerr_credits.dart';
import '../../models/seerr/seerr_media_info.dart';
import '../../models/seerr/seerr_movie_details.dart';
import '../../models/seerr/seerr_search_result.dart';
import '../../models/seerr/seerr_tv_details.dart';
import '../../providers/seerr_session_provider.dart';
import '../../services/seerr/seerr_constants.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/loading_indicator_box.dart';
import 'seerr_request_sheet.dart';
import 'widgets/seerr_status_badge.dart';

/// Detail page for a movie or TV show pulled from Seerr's TMDB catalog.
/// Loads `/movie/{id}` or `/tv/{id}` on mount + a parallel
/// recommendations request; tapping "Request" opens [SeerrRequestSheet].
class SeerrDetailScreen extends StatefulWidget {
  final int tmdbId;
  final String mediaType;
  final String? initialTitle;
  final String? initialPosterPath;

  const SeerrDetailScreen({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    this.initialTitle,
    this.initialPosterPath,
  });

  @override
  State<SeerrDetailScreen> createState() => _SeerrDetailScreenState();
}

class _SeerrDetailScreenState extends State<SeerrDetailScreen> {
  bool _loading = true;
  String? _error;
  SeerrMovieDetails? _movie;
  SeerrTvDetails? _tv;
  List<SeerrSearchResult> _recommendations = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = context.read<SeerrSessionProvider>().client;
    if (client == null) {
      setState(() {
        _loading = false;
        _error = t.seerr.detail.notConnected;
      });
      return;
    }
    try {
      if (widget.mediaType == 'tv') {
        final results = await Future.wait([
          client.getTv(widget.tmdbId),
          // Recommendations are best-effort — surface the detail even if
          // recommendations fail.
          client.getTvRecommendations(widget.tmdbId).catchError((_) => null),
        ]);
        if (!mounted) return;
        setState(() {
          _tv = results[0] as SeerrTvDetails;
          final recPage = results[1];
          _recommendations = recPage == null
              ? const []
              : (recPage as dynamic).results.cast<SeerrSearchResult>().toList(growable: false);
          _loading = false;
        });
      } else {
        final results = await Future.wait([
          client.getMovie(widget.tmdbId),
          client.getMovieRecommendations(widget.tmdbId).catchError((_) => null),
        ]);
        if (!mounted) return;
        setState(() {
          _movie = results[0] as SeerrMovieDetails;
          final recPage = results[1];
          _recommendations = recPage == null
              ? const []
              : (recPage as dynamic).results.cast<SeerrSearchResult>().toList(growable: false);
          _loading = false;
        });
      }
    } catch (e, st) {
      appLogger.w('Seerr detail load failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _openRequestSheet() {
    final tv = _tv;
    final movie = _movie;
    if (tv != null) {
      SeerrRequestSheet.show(
        context,
        SeerrRequestSheet.tv(
          tmdbId: widget.tmdbId,
          title: tv.name,
          details: tv,
          posterPath: tv.posterPath ?? widget.initialPosterPath,
          overview: tv.overview,
          year: _yearOf(tv.firstAirDate),
        ),
      );
    } else if (movie != null) {
      SeerrRequestSheet.show(
        context,
        SeerrRequestSheet.movie(
          tmdbId: widget.tmdbId,
          title: movie.title,
          posterPath: movie.posterPath ?? widget.initialPosterPath,
          overview: movie.overview,
          year: _yearOf(movie.releaseDate),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _tv?.name ?? _movie?.title ?? widget.initialTitle ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: LoadingIndicatorBox(size: 32));
    }
    final error = _error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(Symbols.error_rounded, fill: 1, size: 48),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return _DetailBody(
      tv: _tv,
      movie: _movie,
      recommendations: _recommendations,
      onRequest: _openRequestSheet,
      fallbackPosterPath: widget.initialPosterPath,
    );
  }

  static String? _yearOf(String? date) {
    if (date == null || date.length < 4) return null;
    return date.substring(0, 4);
  }
}

class _DetailBody extends StatelessWidget {
  final SeerrTvDetails? tv;
  final SeerrMovieDetails? movie;
  final List<SeerrSearchResult> recommendations;
  final VoidCallback onRequest;
  final String? fallbackPosterPath;

  const _DetailBody({
    required this.tv,
    required this.movie,
    required this.recommendations,
    required this.onRequest,
    this.fallbackPosterPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final posterPath = tv?.posterPath ?? movie?.posterPath ?? fallbackPosterPath;
    final backdropPath = tv?.backdropPath ?? movie?.backdropPath;
    final title = tv?.name ?? movie?.title ?? '';
    final overview = tv?.overview ?? movie?.overview;
    final tagline = tv?.tagline ?? movie?.tagline;
    final mediaInfo = tv?.mediaInfo ?? movie?.mediaInfo;
    final status = mediaInfo?.status ?? SeerrMediaStatus.unknown;
    final canRequest = status != SeerrMediaStatus.available;
    final genres = tv?.genres.map((g) => g.name).toList() ?? movie?.genres.map((g) => g.name).toList() ?? const <String>[];
    final voteAverage = tv?.voteAverage ?? movie?.voteAverage ?? 0;
    final voteCount = tv?.voteCount ?? movie?.voteCount ?? 0;
    final credits = tv?.credits ?? movie?.credits ?? const SeerrCredits();
    final releaseDate = movie?.releaseDate ?? tv?.firstAirDate;
    final lastAirDate = tv?.lastAirDate;
    final runtimeMinutes = movie?.runtime;
    final episodeCount = tv?.numberOfEpisodes;
    final seasonCount = tv?.numberOfSeasons;

    return ListView(
      children: [
        // Backdrop hero — capped at 220 so it doesn't dominate on desktop.
        if (backdropPath != null)
          Stack(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Image.network(
                  SeerrConstants.backdropUrl(backdropPath) ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, theme.scaffoldBackgroundColor.withValues(alpha: 0.85)],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: posterPath != null
                      ? Image.network(
                          SeerrConstants.posterUrl(posterPath) ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest),
                        )
                      : Container(color: theme.colorScheme.surfaceContainerHighest),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.headlineSmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                    if (tagline != null && tagline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tagline,
                        style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (voteAverage > 0)
                          _MetaChip(
                            icon: Symbols.star_rounded,
                            label: '${voteAverage.toStringAsFixed(1)} / 10',
                            sublabel: voteCount > 0 ? '· ${_formatCount(voteCount)} votes' : null,
                          ),
                        if (releaseDate != null && releaseDate.isNotEmpty)
                          _MetaChip(icon: Symbols.calendar_today_rounded, label: _formatDate(releaseDate)),
                        if (runtimeMinutes != null && runtimeMinutes > 0)
                          _MetaChip(icon: Symbols.schedule_rounded, label: _formatRuntime(runtimeMinutes)),
                        if (seasonCount != null && seasonCount > 0)
                          _MetaChip(
                            icon: Symbols.live_tv_rounded,
                            label: t.seerr.detail.seasonsCount(count: seasonCount),
                            sublabel: (episodeCount != null && episodeCount > 0)
                                ? '· ${t.seerr.detail.episodesCount(count: episodeCount)}'
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SeerrStatusBadge.media(context, status),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canRequest ? onRequest : null,
              icon: const AppIcon(Symbols.playlist_add_rounded, fill: 1),
              label: Text(
                canRequest
                    ? (tv != null ? t.seerr.detail.requestShow : t.seerr.detail.requestMovie)
                    : t.seerr.detail.alreadyAvailable,
              ),
            ),
          ),
        ),
        if (genres.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final g in genres)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(g, style: theme.textTheme.labelSmall),
                  ),
              ],
            ),
          ),
        if (overview != null && overview.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(overview, style: theme.textTheme.bodyMedium),
          ),
        if (tv != null && lastAirDate != null && lastAirDate.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              t.seerr.detail.lastAired(date: _formatDate(lastAirDate)),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        if (credits.cast.isNotEmpty) _CastRow(cast: credits.cast),
        if (tv != null) _SeasonsList(tv: tv!),
        if (recommendations.isNotEmpty) _RecommendationsRow(items: recommendations),
        const SizedBox(height: 24),
      ],
    );
  }

  static String _formatRuntime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String _formatDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  static String _formatCount(int count) {
    if (count < 1000) return '$count';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(count >= 10000 ? 0 : 1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  const _MetaChip({required this.icon, required this.label, this.sublabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, fill: 1, size: 16),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        if (sublabel != null) ...[
          const SizedBox(width: 4),
          Text(sublabel!, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ],
      ],
    );
  }
}

class _CastRow extends StatelessWidget {
  final List<SeerrCastMember> cast;
  const _CastRow({required this.cast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final shown = cast.take(20).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(t.seerr.detail.castHeader, style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final member = shown[i];
                final url = SeerrConstants.posterUrl(member.profilePath);
                return SizedBox(
                  width: 84,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 84,
                          height: 100,
                          child: url != null
                              ? Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Center(child: AppIcon(Symbols.person_rounded, fill: 1)),
                                  ),
                                )
                              : Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Center(child: AppIcon(Symbols.person_rounded, fill: 1)),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (member.character != null && member.character!.isNotEmpty)
                        Text(
                          member.character!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(color: muted),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsRow extends StatelessWidget {
  final List<SeerrSearchResult> items;
  const _RecommendationsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = items.take(20).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(t.seerr.detail.moreLikeThis, style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final r = shown[i];
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
                final posterUrl = SeerrConstants.posterUrl(poster);
                return SizedBox(
                  width: 116,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => SeerrDetailScreen(
                            tmdbId: r.id,
                            mediaType: r.mediaType,
                            initialTitle: title,
                            initialPosterPath: poster,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 116,
                              height: 174,
                              child: posterUrl != null
                                  ? Image.network(
                                      posterUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest),
                                    )
                                  : Container(color: theme.colorScheme.surfaceContainerHighest),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonsList extends StatelessWidget {
  final SeerrTvDetails tv;
  const _SeasonsList({required this.tv});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seasons = tv.seasons.where((s) => s.seasonNumber > 0).toList();
    if (seasons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.seerr.detail.seasonsHeader, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final s in seasons)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const AppIcon(Symbols.theaters_rounded, fill: 1),
              title: Text(t.seerr.request.seasonNumber(number: s.seasonNumber)),
              subtitle: s.episodeCount > 0
                  ? Text(t.seerr.request.episodeCount(count: s.episodeCount))
                  : null,
            ),
        ],
      ),
    );
  }
}
