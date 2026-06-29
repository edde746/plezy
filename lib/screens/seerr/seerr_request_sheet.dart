import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/seerr/seerr_request.dart';
import '../../models/seerr/seerr_tv_details.dart';
import '../../providers/seerr_requests_provider.dart';
import '../../providers/seerr_session_provider.dart';
import '../../services/seerr/seerr_client.dart';
import '../../services/seerr/seerr_constants.dart';
import '../../services/seerr/seerr_exceptions.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/loading_indicator_box.dart';

/// Bottom sheet to submit a request. Movies get a single button; TV shows
/// get a season list with per-season checkboxes ("All seasons" toggles all).
class SeerrRequestSheet extends StatefulWidget {
  /// TMDB id (used as `mediaId` in the request body).
  final int tmdbId;
  final String title;
  final String mediaType;

  /// Poster path (TMDB-relative). Shown alongside the title in the sheet
  /// header so the user can confirm what they're requesting at a glance.
  final String? posterPath;

  /// Plot summary shown above the action button for movies (and TV when
  /// no season list is rendered).
  final String? overview;

  /// Release year (or first-air year) used in the sheet subtitle.
  final String? year;

  /// TV details — when null, this is a movie request.
  final SeerrTvDetails? tv;

  const SeerrRequestSheet.movie({
    super.key,
    required this.tmdbId,
    required this.title,
    this.posterPath,
    this.overview,
    this.year,
  }) : tv = null,
       mediaType = 'movie';

  const SeerrRequestSheet.tv({
    super.key,
    required this.tmdbId,
    required this.title,
    required SeerrTvDetails details,
    this.posterPath,
    this.overview,
    this.year,
  }) : tv = details,
       mediaType = 'tv';

  @override
  State<SeerrRequestSheet> createState() => _SeerrRequestSheetState();

  static Future<void> show(BuildContext context, SeerrRequestSheet sheet) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: sheet,
      ),
    );
  }
}

class _SeerrRequestSheetState extends State<SeerrRequestSheet> {
  final Set<int> _selectedSeasons = {};
  bool _submitting = false;
  String? _error;

  List<SeerrSeason> get _selectableSeasons => widget.tv?.seasons.where((s) => s.seasonNumber > 0).toList() ?? const [];

  bool get _allSelected => _selectableSeasons.isNotEmpty && _selectableSeasons.every((s) => _selectedSeasons.contains(s.seasonNumber));

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selectedSeasons.clear();
      } else {
        _selectedSeasons
          ..clear()
          ..addAll(_selectableSeasons.map((s) => s.seasonNumber));
      }
    });
  }

  Future<void> _submit() async {
    final session = context.read<SeerrSessionProvider>();
    final client = session.client;
    if (client == null) {
      setState(() => _error = t.seerr.request.notConnected);
      return;
    }
    if (widget.tv != null && _selectedSeasons.isEmpty) {
      setState(() => _error = t.seerr.request.pickSeason);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final payload = widget.tv == null
          ? SeerrRequestPayload.movie(widget.tmdbId)
          : SeerrRequestPayload.tv(widget.tmdbId, seasons: _selectedSeasons.toList()..sort());
      final created = await client.createRequest(payload);
      if (!mounted) return;
      // Pre-cache the title/poster so the My Requests row renders correctly
      // without an extra /movie or /tv round-trip.
      final requestsProvider = context.read<SeerrRequestsProvider>();
      requestsProvider.cacheSummary(
        mediaType: widget.mediaType,
        tmdbId: widget.tmdbId,
        summary: SeerrRequestSummary(
          title: widget.title,
          posterPath: widget.posterPath,
          year: widget.year,
        ),
      );
      requestsProvider.prependOptimistic(created);
      showSuccessSnackBar(context, t.seerr.request.submitted(title: widget.title));
      Navigator.of(context).pop();
    } on SeerrRequestException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (e, st) {
      appLogger.e('Seerr request submit failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = t.seerr.request.failedGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTv = widget.tv != null;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _SheetHeader(
                title: widget.title,
                year: widget.year,
                posterPath: widget.posterPath,
                helper: isTv ? t.seerr.request.pickSeasonsHelp : t.seerr.request.movieHelp,
              ),
              if (!isTv && widget.overview != null && widget.overview!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  widget.overview!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              if (isTv) ..._buildSeasonList(theme),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const LoadingIndicatorBox()
                    : const AppIcon(Symbols.send_rounded, fill: 1),
                label: Text(
                  isTv
                      ? t.seerr.request.requestSelectedSeasons(count: _selectedSeasons.length)
                      : t.seerr.request.requestMovie,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSeasonList(ThemeData theme) {
    final seasons = _selectableSeasons;
    if (seasons.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(t.seerr.request.noSeasons, style: theme.textTheme.bodySmall),
        ),
      ];
    }
    return [
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t.seerr.request.allSeasons),
        value: _allSelected,
        tristate: false,
        onChanged: (_) => _toggleAll(),
      ),
      const Divider(),
      for (final s in seasons)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.seerr.request.seasonNumber(number: s.seasonNumber)),
          subtitle: s.episodeCount > 0
              ? Text(t.seerr.request.episodeCount(count: s.episodeCount))
              : null,
          value: _selectedSeasons.contains(s.seasonNumber),
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedSeasons.add(s.seasonNumber);
              } else {
                _selectedSeasons.remove(s.seasonNumber);
              }
            });
          },
        ),
    ];
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final String? year;
  final String? posterPath;
  final String helper;

  const _SheetHeader({required this.title, required this.year, required this.posterPath, required this.helper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final posterUrl = SeerrConstants.posterUrl(posterPath);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (posterUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 72,
              height: 108,
              child: Image.network(
                posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest),
              ),
            ),
          ),
        if (posterUrl != null) const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (year != null && year!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(year!, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              ],
              const SizedBox(height: 8),
              Text(helper, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
            ],
          ),
        ),
      ],
    );
  }
}
