import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/card_focus_scope.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../models/seerr/seerr_media_info.dart';
import '../../../models/seerr/seerr_search_result.dart';
import '../../../services/seerr/seerr_constants.dart';
import '../../../widgets/app_icon.dart';
import 'seerr_status_badge.dart';

/// Poster card for a Seerr discover/search result. Renders TMDB artwork via
/// the public image CDN and overlays a status badge when the title is
/// already tracked by Seerr.
///
/// TV/d-pad behavior: this card is itself focusable via the wrapping
/// [FocusableWrapper] (`autoScroll: true` keeps it inside the row viewport
/// as focus moves). The focus border is delegated to a [CardFocusBorder]
/// drawn around the poster artwork so the highlight hugs the image rather
/// than the full column.
class SeerrMediaCard extends StatelessWidget {
  final SeerrSearchResult result;
  final VoidCallback? onTap;
  final double width;

  const SeerrMediaCard({
    super.key,
    required this.result,
    required this.onTap,
    this.width = 132,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterPath = switch (result) {
      SeerrMovieResult(:final posterPath) => posterPath,
      SeerrTvResult(:final posterPath) => posterPath,
      SeerrPersonResult(:final profilePath) => profilePath,
    };
    final title = switch (result) {
      SeerrMovieResult(:final title) => title,
      SeerrTvResult(:final name) => name,
      SeerrPersonResult(:final name) => name,
    };
    final subtitle = _subtitle(result);
    final mediaInfo = switch (result) {
      SeerrMovieResult(:final mediaInfo) => mediaInfo,
      SeerrTvResult(:final mediaInfo) => mediaInfo,
      SeerrPersonResult() => null,
    };
    final url = SeerrConstants.posterUrl(posterPath);

    return SizedBox(
      width: width,
      child: FocusableWrapper(
        disableScale: false,
        descendantsAreFocusable: false,
        autoScroll: true,
        // Let the poster draw its own border via [CardFocusBorder] so the
        // highlight hugs the artwork instead of the whole column.
        delegateFocusBorder: true,
        onSelect: onTap,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 2 / 3,
                  child: CardFocusBorder(
                    borderRadius: 8,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: url != null
                              ? Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _posterFallback(theme),
                                )
                              : _posterFallback(theme),
                        ),
                        if (mediaInfo != null && mediaInfo.status != SeerrMediaStatus.unknown)
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: SeerrStatusBadge.media(context, mediaInfo.status),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _posterFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: AppIcon(
          Symbols.image_not_supported_rounded,
          fill: 1,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static String _subtitle(SeerrSearchResult r) {
    return switch (r) {
      SeerrMovieResult(:final releaseDate) => _yearOf(releaseDate),
      SeerrTvResult(:final firstAirDate) => _yearOf(firstAirDate),
      SeerrPersonResult() => '',
    };
  }

  static String _yearOf(String? date) {
    if (date == null || date.length < 4) return '';
    return date.substring(0, 4);
  }
}
