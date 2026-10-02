import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../media/media_kind.dart';
import '../services/cli_debrid/cli_debrid_client.dart';
import '../services/cli_debrid/cli_debrid_exceptions.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'loading_indicator_box.dart';
import 'overlay_sheet.dart';

/// Open the cli_debrid request sheet for a catalog title that isn't in any
/// connected library yet. Pops with a success snackbar once submitted.
///
/// Mirrors [showSeerrRequestSheet]'s shape but much simpler: cli_debrid's
/// `/content/request` has no per-season availability status to render (no
/// concept of "already requested"/"partially available" — a title is either
/// trackable in cli_debrid's Wanted queue or it isn't), so this is a season
/// checklist (shows only) plus a version picker, not a full status-aware form.
Future<void> showCliDebridRequestSheet(
  BuildContext context, {
  required CliDebridClient client,
  required MediaKind kind,
  required int tmdbId,
  required String title,
  int? year,
}) {
  return OverlaySheetController.showAdaptive<void>(
    context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CliDebridRequestSheet(client: client, kind: kind, tmdbId: tmdbId, title: title, year: year),
  );
}

class CliDebridRequestSheet extends StatefulWidget {
  final CliDebridClient client;
  final MediaKind kind;
  final int tmdbId;
  final String title;
  final int? year;

  const CliDebridRequestSheet({
    super.key,
    required this.client,
    required this.kind,
    required this.tmdbId,
    required this.title,
    this.year,
  });

  @override
  State<CliDebridRequestSheet> createState() => _CliDebridRequestSheetState();
}

class _CliDebridRequestSheetState extends State<CliDebridRequestSheet> {
  bool _loading = true;
  bool _loadFailed = false;

  List<int> _seasons = const [];
  final Set<int> _selectedSeasons = {};

  List<String> _versions = const [];
  final Set<String> _selectedVersions = {};

  bool _submitting = false;
  String? _errorText;

  bool get _isMovie => widget.kind == MediaKind.movie;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final (seasons, versions) = await (
        _isMovie ? Future.value(const <int>[]) : widget.client.showSeasons(tmdbId: '${widget.tmdbId}'),
        widget.client.availableVersions(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _seasons = seasons;
        _versions = versions;
        _loading = false;
      });
    } catch (e) {
      appLogger.w('cli_debrid: request sheet load failed for tmdb ${widget.tmdbId}', error: e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  bool get _canSubmit => !_submitting && !_loading && !_loadFailed;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      await widget.client.requestContent(
        id: '${widget.tmdbId}',
        mediaType: _isMovie ? 'movie' : 'tv',
        title: widget.title,
        year: widget.year,
        versions: _selectedVersions.isEmpty ? null : _selectedVersions.toList(),
        // Empty selection on a show means "every season" — cli_debrid's own
        // semantics for an omitted/empty seasons list (see /content/request).
        seasons: _isMovie || _selectedSeasons.isEmpty ? null : (_selectedSeasons.toList()..sort()),
      );
      if (!mounted) return;
      OverlaySheetController.closeAdaptive(context);
      showSuccessSnackBar(context, t.cliDebrid.requestSubmitted);
    } on CliDebridApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = e.message;
      });
    } catch (e) {
      appLogger.w('cli_debrid: request submit failed', error: e);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = t.cliDebrid.requestFailed(error: '$e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.cliDebrid.request, style: theme.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            widget.title,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: LoadingIndicatorBox()),
            )
          else if (_loadFailed)
            _buildLoadError(theme)
          else ...[
            if (!_isMovie && _seasons.isNotEmpty) ..._buildSeasonSection(theme),
            if (_versions.isNotEmpty) ..._buildVersionSection(theme),
            if (_errorText case final String error) ...[
              const SizedBox(height: 8),
              Text(error, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FocusableButton(
              useBackgroundFocus: true,
              onPressed: _canSubmit ? _submit : null,
              child: FilledButton.icon(
                onPressed: _canSubmit ? _submit : null,
                icon: _submitting ? const LoadingIndicatorBox() : const AppIcon(Symbols.download_rounded, fill: 1),
                label: Text(t.cliDebrid.request),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadError(ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        Text(t.seerr.requestsLoadFailed, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        FocusableButton(
          autofocus: true,
          onPressed: () => unawaited(_load()),
          child: OutlinedButton(onPressed: () => unawaited(_load()), child: Text(t.common.retry)),
        ),
      ],
    ),
  );

  List<Widget> _buildSeasonSection(ThemeData theme) {
    final allSelected = _seasons.every(_selectedSeasons.contains);
    return [
      Text(t.seerr.seasons, style: theme.textTheme.titleSmall),
      CheckboxListTile(
        value: allSelected,
        onChanged: _submitting
            ? null
            : (checked) => setState(() {
                if (checked ?? false) {
                  _selectedSeasons.addAll(_seasons);
                } else {
                  _selectedSeasons.clear();
                }
              }),
        title: Text(t.seerr.allSeasons),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
      for (final season in _seasons)
        CheckboxListTile(
          value: _selectedSeasons.contains(season),
          onChanged: _submitting
              ? null
              : (checked) => setState(() {
                  if (checked ?? false) {
                    _selectedSeasons.add(season);
                  } else {
                    _selectedSeasons.remove(season);
                  }
                }),
          title: Text(t.common.seasonNumber(number: season)),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildVersionSection(ThemeData theme) {
    return [
      Text(t.cliDebrid.versions, style: theme.textTheme.titleSmall),
      for (final version in _versions)
        CheckboxListTile(
          value: _selectedVersions.contains(version),
          onChanged: _submitting
              ? null
              : (checked) => setState(() {
                  if (checked ?? false) {
                    _selectedVersions.add(version);
                  } else {
                    _selectedVersions.remove(version);
                  }
                }),
          title: Text(version),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      const SizedBox(height: 8),
    ];
  }
}
