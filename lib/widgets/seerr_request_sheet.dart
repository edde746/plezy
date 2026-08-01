import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../media/media_kind.dart';
import '../models/seerr/seerr_details.dart';
import '../models/seerr/seerr_media.dart';
import '../models/seerr/seerr_public_settings.dart';
import '../models/seerr/seerr_request.dart';
import '../models/seerr/seerr_service.dart';
import '../services/catalog/seerr_catalog_source.dart';
import '../services/seerr/seerr_constants.dart';
import '../services/seerr/seerr_exceptions.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'app_menu.dart';
import 'loading_indicator_box.dart';
import 'focusable_list_tile.dart';
import 'overlay_sheet.dart';
import 'stat_chip.dart';

/// Open the Seerr request sheet for a title. Pops with a success snackbar
/// once the request is submitted.
Future<void> showSeerrRequestSheet(
  BuildContext context, {
  required SeerrCatalogSource source,
  required MediaKind kind,
  required int tmdbId,
  required String title,
}) {
  return OverlaySheetController.showAdaptive<void>(
    context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SeerrRequestSheet(source: source, kind: kind, tmdbId: tmdbId, title: title),
  );
}

/// The full Seerr request flow, mirroring the web UI: per-season selection
/// with availability states, a 4K toggle, and the advanced destination
/// pickers — every section gated by the same instance settings and user
/// permissions Seerr itself checks.
class SeerrRequestSheet extends StatefulWidget {
  final SeerrCatalogSource source;
  final MediaKind kind;
  final int tmdbId;
  final String title;

  const SeerrRequestSheet({
    super.key,
    required this.source,
    required this.kind,
    required this.tmdbId,
    required this.title,
  });

  @override
  State<SeerrRequestSheet> createState() => _SeerrRequestSheetState();
}

class _SeerrRequestSheetState extends State<SeerrRequestSheet> {
  bool _loading = true;
  bool _loadFailed = false;

  SeerrPublicSettings? _settings;
  SeerrMediaInfo? _mediaInfo;

  /// TV only: requestable seasons (specials and empty seasons dropped).
  List<SeerrSeason> _seasons = const [];
  final Set<int> _selectedSeasons = {};
  List<FocusNode> _seasonFocusNodes = const [];
  late final FocusNode _requestButtonFocusNode;

  bool _is4k = false;

  /// Advanced options (REQUEST_ADVANCED): all configured instances of the
  /// matching service; the pickers filter by the 4K toggle.
  List<SeerrServiceInstance> _allServers = const [];
  SeerrServiceInstance? _server;
  SeerrServiceDetail? _serverDetail;
  bool _serverDetailLoading = false;
  int? _profileId;
  String? _rootFolder;
  int? _languageProfileId;

  bool _submitting = false;
  String? _errorText;

  bool get _isMovie => widget.kind == MediaKind.movie;

  int get _permissions => widget.source.client.session.permissions;

  bool get _advancedAllowed => seerrHasPermission(_permissions, [SeerrPermission.requestAdvanced]);

  bool get _can4k {
    final settings = _settings;
    if (settings == null) return false;
    final enabled = _isMovie ? settings.movie4kEnabled : settings.series4kEnabled;
    return enabled &&
        seerrHasPermission(_permissions, [
          SeerrPermission.request4k,
          _isMovie ? SeerrPermission.request4kMovie : SeerrPermission.request4kTv,
        ]);
  }

  bool get _partialSeasons => _settings?.partialRequestsEnabled ?? true;

  List<SeerrServiceInstance> get _serversForVariant => [..._allServers.where((s) => s.is4k == _is4k)];

  @override
  void initState() {
    super.initState();
    _requestButtonFocusNode = FocusNode(debugLabel: 'seerr_request_submit');
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final node in _seasonFocusNodes) {
      node.dispose();
    }
    _requestButtonFocusNode.dispose();
    super.dispose();
  }

  void _replaceSeasonFocusNodes(List<SeerrSeason> seasons) {
    for (final node in _seasonFocusNodes) {
      node.dispose();
    }
    _seasonFocusNodes = [
      for (final season in seasons)
        FocusNode(
          debugLabel: 'seerr_season_${season.seasonNumber}',
          onKeyEvent: (node, event) => _handleSeasonKey(season.seasonNumber, event),
        ),
    ];
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final client = widget.source.client;
    try {
      final (settings, servers) = await (
        client.getPublicSettings(),
        _advancedAllowed
            ? (_isMovie ? client.getRadarrServices() : client.getSonarrServices())
            : Future.value(const <SeerrServiceInstance>[]),
      ).wait;

      SeerrMediaInfo? mediaInfo;
      var seasons = const <SeerrSeason>[];
      if (_isMovie) {
        mediaInfo = (await client.getMovie(widget.tmdbId)).mediaInfo;
      } else {
        final tv = await client.getTv(widget.tmdbId);
        mediaInfo = tv.mediaInfo;
        seasons = [
          for (final season in tv.seasons ?? const <SeerrSeason>[])
            if (season.seasonNumber > 0 && (season.episodeCount ?? 0) > 0) season,
        ];
      }
      if (!mounted) return;
      _replaceSeasonFocusNodes(seasons);
      setState(() {
        _settings = settings;
        _mediaInfo = mediaInfo;
        _seasons = seasons;
        _allServers = servers;
        _loading = false;
      });
      _selectDefaultServer();
    } catch (e) {
      appLogger.w('Seerr: request sheet load failed for tmdb ${widget.tmdbId}', error: e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _selectDefaultServer() {
    final candidates = _serversForVariant;
    final next = candidates.firstWhereOrNull((s) => s.isDefault) ?? candidates.firstOrNull;
    _adoptServer(next);
  }

  void _adoptServer(SeerrServiceInstance? server) {
    setState(() {
      _server = server;
      _serverDetail = null;
      _profileId = server?.activeProfileId;
      _rootFolder = server?.activeDirectory;
      _languageProfileId = server?.activeLanguageProfileId;
    });
    if (server != null && _advancedAllowed) unawaited(_loadServerDetail(server));
  }

  Future<void> _loadServerDetail(SeerrServiceInstance server) async {
    setState(() => _serverDetailLoading = true);
    final client = widget.source.client;
    try {
      final detail = _isMovie ? await client.getRadarrService(server.id) : await client.getSonarrService(server.id);
      if (!mounted || _server?.id != server.id) return;
      setState(() {
        _serverDetail = detail;
        _serverDetailLoading = false;
        _profileId ??= detail.server?.activeProfileId;
        _rootFolder ??= detail.server?.activeDirectory;
        _languageProfileId ??= detail.server?.activeLanguageProfileId;
      });
    } catch (e) {
      // Advanced pickers degrade to server defaults; the request still works.
      appLogger.w('Seerr: service detail load failed', error: e);
      if (!mounted || _server?.id != server.id) return;
      setState(() => _serverDetailLoading = false);
    }
  }

  void _toggle4k(bool value) {
    setState(() {
      _is4k = value;
      _selectedSeasons.removeWhere(_seasonBlocked);
    });
    _selectDefaultServer();
  }

  // ---------- Availability ----------

  /// Non-declined requests matching the current 4K variant.
  Iterable<SeerrRequest> get _activeRequests => (_mediaInfo?.requests ?? const <SeerrRequest>[]).where(
    (r) => (r.is4k ?? false) == _is4k && r.status != SeerrRequestStatus.declined,
  );

  SeerrMediaStatus _variantStatus(SeerrMediaStatus status, SeerrMediaStatus status4k) => _is4k ? status4k : status;

  /// Why this title/season can't be requested, or null when it can.
  String? _blockedLabel(SeerrMediaStatus status, {required bool coveredByRequest}) {
    return switch (status) {
      SeerrMediaStatus.available => t.seerr.statusAvailable,
      SeerrMediaStatus.partiallyAvailable => t.seerr.statusPartiallyAvailable,
      SeerrMediaStatus.processing => t.seerr.statusProcessing,
      SeerrMediaStatus.pending => t.seerr.statusRequested,
      SeerrMediaStatus.unknown || SeerrMediaStatus.deleted when coveredByRequest => t.seerr.statusRequested,
      SeerrMediaStatus.unknown || SeerrMediaStatus.deleted => null,
    };
  }

  /// Movies block at the title level; shows block per season.
  String? get _movieBlockedLabel {
    final info = _mediaInfo;
    if (info == null) return null;
    return _blockedLabel(_variantStatus(info.status, info.status4k), coveredByRequest: _activeRequests.isNotEmpty);
  }

  String? _seasonBlockedLabel(int seasonNumber) {
    final info = _mediaInfo;
    if (info == null) return null;
    final season = info.seasons?.firstWhereOrNull((s) => s.seasonNumber == seasonNumber);
    final covered = _activeRequests.any((r) => r.seasons?.any((s) => s.seasonNumber == seasonNumber) ?? false);
    return _blockedLabel(
      _variantStatus(season?.status ?? SeerrMediaStatus.unknown, season?.status4k ?? SeerrMediaStatus.unknown),
      coveredByRequest: covered,
    );
  }

  bool _seasonBlocked(int seasonNumber) => _seasonBlockedLabel(seasonNumber) != null;

  List<int> get _requestableSeasons => [
    for (final season in _seasons)
      if (!_seasonBlocked(season.seasonNumber)) season.seasonNumber,
  ];

  bool get _nothingToRequest => _isMovie ? _movieBlockedLabel != null : _requestableSeasons.isEmpty;

  bool get _canSubmit {
    if (_submitting || _loading || _loadFailed || _nothingToRequest) return false;
    if (!_isMovie && _partialSeasons && _selectedSeasons.isEmpty) return false;
    return true;
  }

  // ---------- Submit ----------

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final advanced = _advancedAllowed && _server != null;
    final payload = SeerrRequestPayload(
      mediaType: _isMovie ? 'movie' : 'tv',
      mediaId: widget.tmdbId,
      seasons: _isMovie ? null : (_partialSeasons ? (_selectedSeasons.toList()..sort()) : null),
      is4k: _is4k,
      serverId: advanced ? _server?.id : null,
      profileId: advanced ? _profileId : null,
      rootFolder: advanced ? _rootFolder : null,
      languageProfileId: advanced ? _languageProfileId : null,
    );
    try {
      await widget.source.client.createRequest(payload);
      if (!mounted) return;
      // The sheet may be hosted by an OverlaySheetHost (no route of its own),
      // so a bare Navigator.pop would pop the screen underneath instead.
      OverlaySheetController.closeAdaptive(context);
      showSuccessSnackBar(context, t.seerr.requestSubmitted);
    } on SeerrApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = e.message;
      });
    } catch (e) {
      appLogger.w('Seerr: request submit failed', error: e);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = t.seerr.requestFailed(error: '$e');
      });
    }
  }

  bool get _hasVisibleAdvancedControls {
    if (!_advancedAllowed || _serversForVariant.isEmpty) return false;
    final detail = _serverDetail;
    return _serversForVariant.length > 1 ||
        (detail?.profiles?.isNotEmpty ?? false) ||
        (detail?.rootFolders?.isNotEmpty ?? false) ||
        (detail?.languageProfiles?.isNotEmpty ?? false);
  }

  void _focusRequestButton() {
    _requestButtonFocusNode.requestFocus();
    final buttonContext = _requestButtonFocusNode.context;
    if (buttonContext == null) return;
    unawaited(
      Scrollable.ensureVisible(
        buttonContext,
        alignment: 0.9,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ),
    );
  }

  KeyEventResult _handleSeasonKey(int seasonNumber, KeyEvent event) {
    if (!event.isActionable || !event.logicalKey.isDownKey) {
      return KeyEventResult.ignored;
    }
    if (_requestableSeasons.lastOrNull != seasonNumber || _can4k || _hasVisibleAdvancedControls || !_canSubmit) {
      return KeyEventResult.ignored;
    }
    _focusRequestButton();
    return KeyEventResult.handled;
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.seerr.request, style: theme.textTheme.titleLarge),
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
            if (_nothingToRequest)
              _buildNothingToRequest(theme)
            else ...[
              if (!_isMovie && _partialSeasons) ..._buildSeasonSection(theme),
              if (_can4k)
                FocusableSwitchListTile(
                  value: _is4k,
                  onChanged: _submitting ? null : _toggle4k,
                  title: Text(t.seerr.request4k),
                  secondary: const AppIcon(Symbols.four_k_rounded, fill: 1),
                  contentPadding: EdgeInsets.zero,
                ),
              if (_advancedAllowed && _serversForVariant.isNotEmpty) ..._buildAdvancedSection(theme),
              if (_errorText case final String error) ...[
                const SizedBox(height: 8),
                Text(error, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FocusableButton(
                focusNode: _requestButtonFocusNode,
                useBackgroundFocus: true,
                onPressed: _canSubmit ? _submit : null,
                child: FilledButton.icon(
                  onPressed: _canSubmit ? _submit : null,
                  icon: _submitting ? const LoadingIndicatorBox() : const AppIcon(Symbols.download_rounded, fill: 1),
                  label: Text(t.seerr.request),
                ),
              ),
            ],
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

  Widget _buildNothingToRequest(ThemeData theme) {
    final label = _isMovie ? _movieBlockedLabel : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          AppIcon(Symbols.check_circle_rounded, fill: 1, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label ?? t.seerr.nothingToRequest, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  List<Widget> _buildSeasonSection(ThemeData theme) {
    final requestable = _requestableSeasons;
    final allSelected = requestable.isNotEmpty && requestable.every(_selectedSeasons.contains);
    return [
      Text(t.seerr.seasons, style: theme.textTheme.titleSmall),
      CheckboxListTile(
        value: allSelected,
        onChanged: _submitting
            ? null
            : (checked) => setState(() {
                if (checked ?? false) {
                  _selectedSeasons.addAll(requestable);
                } else {
                  _selectedSeasons.clear();
                }
              }),
        title: Text(t.seerr.allSeasons),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
      for (var index = 0; index < _seasons.length; index++) _buildSeasonTile(theme, _seasons[index], index),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildSeasonTile(ThemeData theme, SeerrSeason season, int index) {
    final number = season.seasonNumber;
    final blockedLabel = _seasonBlockedLabel(number);
    final episodeCount = season.episodeCount;
    return FocusableCheckboxListTile(
      focusNode: _seasonFocusNodes[index],
      value: blockedLabel != null || _selectedSeasons.contains(number),
      onChanged: blockedLabel != null || _submitting
          ? null
          : (checked) => setState(() {
              if (checked ?? false) {
                _selectedSeasons.add(number);
              } else {
                _selectedSeasons.remove(number);
              }
            }),
      title: Text(season.name ?? t.common.seasonNumber(number: number)),
      subtitle: episodeCount == null ? null : Text(t.explore.episodeCount(n: episodeCount)),
      secondary: blockedLabel == null ? null : StatChip(label: blockedLabel),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  List<Widget> _buildAdvancedSection(ThemeData theme) {
    final servers = _serversForVariant;
    final detail = _serverDetail;
    final profiles = detail?.profiles ?? const <SeerrServiceProfile>[];
    final folders = detail?.rootFolders ?? const <SeerrRootFolder>[];
    final languages = detail?.languageProfiles ?? const <SeerrServiceProfile>[];
    return [
      const SizedBox(height: 8),
      Row(
        children: [
          Text(t.seerr.advancedOptions, style: theme.textTheme.titleSmall),
          if (_serverDetailLoading) ...[const SizedBox(width: 10), const LoadingIndicatorBox(size: 14)],
        ],
      ),
      if (servers.length > 1)
        _PickerTile<SeerrServiceInstance>(
          icon: Symbols.dns_rounded,
          label: t.seerr.destinationServer,
          value: _server?.name ?? '',
          options: servers,
          describe: (s) => s.name ?? '#${s.id}',
          isSelected: (s) => s.id == _server?.id,
          enabled: !_submitting,
          onSelected: _adoptServer,
        ),
      if (profiles.isNotEmpty)
        _PickerTile<SeerrServiceProfile>(
          icon: Symbols.high_quality_rounded,
          label: t.seerr.qualityProfile,
          value: profiles.firstWhereOrNull((p) => p.id == _profileId)?.name ?? '',
          options: profiles,
          describe: (p) => p.name ?? '#${p.id}',
          isSelected: (p) => p.id == _profileId,
          enabled: !_submitting,
          onSelected: (p) => setState(() => _profileId = p.id),
        ),
      if (folders.isNotEmpty)
        _PickerTile<SeerrRootFolder>(
          icon: Symbols.folder_rounded,
          label: t.seerr.rootFolder,
          value: _rootFolder ?? '',
          options: folders,
          describe: (f) => f.path ?? '#${f.id}',
          isSelected: (f) => f.path == _rootFolder,
          enabled: !_submitting,
          onSelected: (f) => setState(() => _rootFolder = f.path),
        ),
      if (languages.isNotEmpty)
        _PickerTile<SeerrServiceProfile>(
          icon: Symbols.language_rounded,
          label: t.seerr.languageProfile,
          value: languages.firstWhereOrNull((p) => p.id == _languageProfileId)?.name ?? '',
          options: languages,
          describe: (p) => p.name ?? '#${p.id}',
          isSelected: (p) => p.id == _languageProfileId,
          enabled: !_submitting,
          onSelected: (p) => setState(() => _languageProfileId = p.id),
        ),
    ];
  }
}

/// A "current value" row that opens an [showAppMenu] of options, anchored to
/// itself — the same dpad-safe pattern as the watchlist source chooser.
class _PickerTile<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<T> options;
  final String Function(T) describe;
  final bool Function(T) isSelected;
  final bool enabled;
  final ValueChanged<T> onSelected;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.describe,
    required this.isSelected,
    required this.enabled,
    required this.onSelected,
  });

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final anchorRect = box.localToGlobal(Offset.zero) & box.size;
    final picked = await showAppMenu<T>(
      context,
      anchorRect: anchorRect,
      focusFirstItem: true,
      entries: [
        for (final option in options)
          AppMenuItem<T>(value: option, label: describe(option), selected: isSelected(option)),
      ],
    );
    if (!context.mounted) return;
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FocusableListTile(
      leading: AppIcon(icon, fill: 1),
      title: Text(label),
      subtitle: value.isEmpty ? null : Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const AppIcon(Symbols.unfold_more_rounded, fill: 1),
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      onTap: () => unawaited(_open(context)),
    );
  }
}
