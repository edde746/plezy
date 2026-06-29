import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/seerr/seerr_media_info.dart';
import '../../models/seerr/seerr_movie_details.dart';
import '../../models/seerr/seerr_tv_details.dart';
import '../../providers/seerr_session_provider.dart';
import '../../services/seerr/seerr_constants.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/loading_indicator_box.dart';
import 'seerr_request_sheet.dart';
import 'widgets/seerr_status_badge.dart';

/// Detail page for a movie or TV show pulled from Seerr's TMDB catalog.
/// Loads `/movie/{id}` or `/tv/{id}` on mount; tapping "Request" opens
/// [SeerrRequestSheet].
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
        final tv = await client.getTv(widget.tmdbId);
        if (!mounted) return;
        setState(() {
          _tv = tv;
          _loading = false;
        });
      } else {
        final movie = await client.getMovie(widget.tmdbId);
        if (!mounted) return;
        setState(() {
          _movie = movie;
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
          year: (tv.firstAirDate != null && tv.firstAirDate!.length >= 4) ? tv.firstAirDate!.substring(0, 4) : null,
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
          year: (movie.releaseDate != null && movie.releaseDate!.length >= 4)
              ? movie.releaseDate!.substring(0, 4)
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _tv?.name ?? _movie?.title ?? widget.initialTitle ?? '';
    return FocusedScrollScaffold(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      slivers: [
        SliverToBoxAdapter(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(40), child: Center(child: LoadingIndicatorBox(size: 32)));
    }
    final error = _error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const AppIcon(Symbols.error_rounded, fill: 1, size: 48),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return _DetailBody(
      tv: _tv,
      movie: _movie,
      onRequest: _openRequestSheet,
      fallbackPosterPath: widget.initialPosterPath,
    );
  }
}

class _DetailBody extends StatelessWidget {
  final SeerrTvDetails? tv;
  final SeerrMovieDetails? movie;
  final VoidCallback onRequest;
  final String? fallbackPosterPath;

  const _DetailBody({required this.tv, required this.movie, required this.onRequest, this.fallbackPosterPath});

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
    final meta = _metaLine(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (backdropPath != null)
          // Cap backdrop height — at full window width on desktop a 16:9
          // backdrop would consume the entire viewport before any details
          // show up.
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Image.network(
              SeerrConstants.backdropUrl(backdropPath) ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                height: 165,
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
                    Text(title, style: theme.textTheme.titleLarge, maxLines: 3, overflow: TextOverflow.ellipsis),
                    if (tagline != null && tagline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tagline,
                        style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(meta, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SeerrStatusBadge.media(context, status),
                      ],
                    ),
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
        if (tv != null) _SeasonsList(tv: tv!),
      ],
    );
  }

  String _metaLine(ThemeData theme) {
    final parts = <String>[];
    final date = tv?.firstAirDate ?? movie?.releaseDate;
    if (date != null && date.length >= 4) parts.add(date.substring(0, 4));
    final runtime = movie?.runtime;
    if (runtime != null && runtime > 0) parts.add('${runtime}m');
    final seasons = tv?.numberOfSeasons;
    if (seasons != null && seasons > 0) {
      parts.add(t.seerr.detail.seasonsCount(count: seasons));
    }
    return parts.join(' · ');
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
