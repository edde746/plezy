import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../media/media_kind.dart';
import '../models/seerr/seerr_details.dart';
import '../models/seerr/seerr_media.dart';
import '../models/seerr/seerr_public_settings.dart';
import '../models/seerr/seerr_request.dart';
import '../models/seerr/seerr_session.dart';
import '../models/seerr/seerr_service.dart';
import '../providers/seerr_account_provider.dart';
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

/// Why the sheet closed itself; a caller surfaces it on its own scaffold
/// since the sheet is unmounting.
enum SeerrRequestSheetClose {
  /// The signed-in user lost the permission to request this kind (or the
  /// account disconnected) while the sheet was open.
  permissionRevoked,
}

/// Open the Seerr request sheet for a title. Pops with a success snackbar
/// once the request is submitted, or an error snackbar when the sheet had to
/// close because the user's request permission went away.
Future<void> showSeerrRequestSheet(
  BuildContext context, {
  required SeerrCatalogSource source,
  required MediaKind kind,
  required int tmdbId,
  required String title,
}) async {
  final close = await OverlaySheetController.showAdaptive<SeerrRequestSheetClose>(
    context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SeerrRequestSheet(source: source, kind: kind, tmdbId: tmdbId, title: title),
  );
  if (close == SeerrRequestSheetClose.permissionRevoked && context.mounted) {
    showErrorSnackBar(context, t.seerr.permissionRevoked);
  }
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

  /// TV only: the TMDB anime keyword is present, so Seerr routes the series
  /// to the Sonarr instance's anime defaults (profile, folder, language,
  /// tags) and the sheet must seed its overrides from those.
  bool _isAnime = false;

  /// Advanced options (REQUEST_ADVANCED): all configured instances of the
  /// matching service; the pickers filter by the 4K toggle.
  List<SeerrServiceInstance> _allServers = const [];
  SeerrServiceInstance? _server;
  SeerrServiceDetail? _serverDetail;
  bool _serverDetailLoading = false;

  /// Bumped on every destination adoption (including null and the 4K
  /// round-trip). A detail load that lands for an older generation is
  /// dropped outright: an id-only check would let A→B→A or 4K on→off apply
  /// the first A response over the second's in-flight load.
  int _serverSelectionGeneration = 0;
  int? _profileId;
  String? _rootFolder;
  int? _languageProfileId;

  /// Null until the service detail reports the instance's default tags; a
  /// null is omitted from the payload so Seerr applies its own defaults.
  List<int>? _tags;
  bool _tagsExpanded = false;

  bool _submitting = false;
  String? _errorText;

  /// Whether the account provider (when one scopes the sheet) still holds a
  /// session; a disconnect leaves [widget.source] wrapping a disposed client.
  bool _connected = true;

  /// The permission mask the sheet's state was last reconciled against, so
  /// a grant or revocation while open is applied as a transition (servers
  /// loaded, 4K/destination reset) rather than re-derived from scratch.
  int? _reconciledPermissions;
  bool _closing = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The client's session is updated in place (bind-time refresh, silent
    // re-auth, a denied request's /auth/me probe); the provider's notify is
    // what tells the sheet to look again. Nullable: hosts without the
    // profile session scope (tests) still reconcile after a denied submit.
    final account = context.watch<SeerrAccountProvider?>();
    _connected = account?.isConnected ?? true;
    _reconcileAuthority();
  }

  /// Apply a permission change that landed while the sheet is open. Skipped
  /// mid-submit — [_submit] reconciles once the server has answered, so a
  /// denial's freshly adopted mask closes or trims the sheet consistently —
  /// and mid-load, where [_load] reconciles against the mask it started
  /// under.
  void _reconcileAuthority() {
    if (_submitting || _loading) return;
    if (!_connected || !widget.source.canRequest(widget.kind)) {
      _closeForRevokedPermission();
      return;
    }
    final permissions = _permissions;
    final previous = _reconciledPermissions;
    _reconciledPermissions = permissions;
    if (previous == null || previous == permissions) return;
    final hadAdvanced = seerrHasPermission(previous, [SeerrPermission.requestAdvanced]);
    if (_advancedAllowed && !hadAdvanced && !_loadFailed) {
      unawaited(_loadServers());
    } else if (!_advancedAllowed && hadAdvanced) {
      setState(() => _allServers = const []);
      _adoptServer(null);
    }
    if (_is4k && !_can4k) _toggle4k(false);
  }

  void _closeForRevokedPermission() {
    if (_closing) return;
    _closing = true;
    // Reached from didChangeDependencies (build phase) or a submit
    // continuation; either way the host's close animates from a settled
    // frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) OverlaySheetController.closeAdaptive(context, SeerrRequestSheetClose.permissionRevoked);
    });
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
    // The advanced gate is read once here; a grant landing mid-load is
    // applied by the reconcile below as a transition from this mask.
    _reconciledPermissions = _permissions;
    try {
      final (settings, servers) = await (
        client.getPublicSettings(),
        _advancedAllowed
            ? (_isMovie ? client.getRadarrServices() : client.getSonarrServices())
            : Future.value(const <SeerrServiceInstance>[]),
      ).wait;

      SeerrMediaInfo? mediaInfo;
      var seasons = const <SeerrSeason>[];
      var isAnime = false;
      if (_isMovie) {
        mediaInfo = (await client.getMovie(widget.tmdbId)).mediaInfo;
      } else {
        final tv = await client.getTv(widget.tmdbId);
        mediaInfo = tv.mediaInfo;
        seasons = [
          for (final season in tv.seasons ?? const <SeerrSeason>[])
            if (season.seasonNumber > 0 && (season.episodeCount ?? 0) > 0) season,
        ];
        isAnime = tv.keywords?.any((k) => k.id == SeerrConstants.animeKeywordId) ?? false;
      }
      if (!mounted) return;
      _replaceSeasonFocusNodes(seasons);
      setState(() {
        _settings = settings;
        _mediaInfo = mediaInfo;
        _seasons = seasons;
        _isAnime = isAnime;
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
    _reconcileAuthority();
  }

  /// Servers-only reload for an advanced grant that landed after [_load]
  /// skipped them; degrades like a failed detail load (defaults apply).
  Future<void> _loadServers() async {
    final client = widget.source.client;
    final List<SeerrServiceInstance> servers;
    try {
      servers = _isMovie ? await client.getRadarrServices() : await client.getSonarrServices();
    } catch (e) {
      appLogger.w('Seerr: service list load failed', error: e);
      return;
    }
    if (!mounted || !_advancedAllowed) return;
    setState(() => _allServers = servers);
    _selectDefaultServer();
  }

  void _selectDefaultServer() {
    final candidates = _serversForVariant;
    final next = candidates.firstWhereOrNull((s) => s.isDefault) ?? candidates.firstOrNull;
    _adoptServer(next);
  }

  /// The instance default the web requester preselects: the anime value when
  /// the series is an anime and the instance configures one, else the
  /// standard value.
  int? _defaultProfileId(SeerrServiceInstance? server) =>
      (_isAnime ? server?.activeAnimeProfileId : null) ?? server?.activeProfileId;

  String? _defaultRootFolder(SeerrServiceInstance? server) =>
      (_isAnime ? server?.activeAnimeDirectory : null) ?? server?.activeDirectory;

  int? _defaultLanguageProfileId(SeerrServiceInstance? server) =>
      (_isAnime ? server?.activeAnimeLanguageProfileId : null) ?? server?.activeLanguageProfileId;

  List<int>? _defaultTags(SeerrServiceInstance? server) => _isAnime ? server?.activeAnimeTags : server?.activeTags;

  void _adoptServer(SeerrServiceInstance? server) {
    final generation = ++_serverSelectionGeneration;
    final loadsDetail = server != null && _advancedAllowed;
    setState(() {
      _server = server;
      _serverDetail = null;
      _serverDetailLoading = loadsDetail;
      _profileId = _defaultProfileId(server);
      _rootFolder = _defaultRootFolder(server);
      _languageProfileId = _defaultLanguageProfileId(server);
      // The list endpoint reports no usable tags; wait for the detail.
      _tags = null;
    });
    if (loadsDetail) unawaited(_loadServerDetail(server, generation));
  }

  Future<void> _loadServerDetail(SeerrServiceInstance server, int generation) async {
    final client = widget.source.client;
    final SeerrServiceDetail detail;
    try {
      detail = _isMovie ? await client.getRadarrService(server.id) : await client.getSonarrService(server.id);
    } catch (e) {
      // Advanced pickers degrade to server defaults; the request still works.
      appLogger.w('Seerr: service detail load failed', error: e);
      if (!mounted || generation != _serverSelectionGeneration) return;
      setState(() => _serverDetailLoading = false);
      return;
    }
    if (!mounted || generation != _serverSelectionGeneration) return;
    // Runs once per accepted generation (adoption reset every default), so
    // `??=` only fills what the list endpoint left null and an explicit
    // `activeTags: []` hydrates to `[]`; user edits made afterwards are the
    // last write.
    setState(() {
      _serverDetail = detail;
      _serverDetailLoading = false;
      _profileId ??= _defaultProfileId(detail.server);
      _rootFolder ??= _defaultRootFolder(detail.server);
      _languageProfileId ??= _defaultLanguageProfileId(detail.server);
      if (detail.tags != null) _tags = [...?_defaultTags(detail.server)];
    });
  }

  void _toggle4k(bool value) {
    setState(() {
      _is4k = value;
      _selectedSeasons.removeWhere(_seasonBlocked);
    });
    _selectDefaultServer();
  }

  // ---------- Availability ----------

  /// Requests that still hold a claim on the title, matching the current 4K
  /// variant: waiting for approval or approved and in the pipeline. Declined,
  /// failed, and completed requests must not block re-requesting.
  Iterable<SeerrRequest> get _activeRequests => (_mediaInfo?.requests ?? const <SeerrRequest>[]).where(
    (r) =>
        (r.is4k ?? false) == _is4k &&
        (r.status == SeerrRequestStatus.pending || r.status == SeerrRequestStatus.approved),
  );

  /// Failed requests for the current 4K variant. A failed arr push can leave
  /// the media status Processing/Pending upstream while the request itself is
  /// Failed, so a scope whose only claim is a failed request must stay
  /// re-requestable (mirrors `SeerrCatalogSource._requestState` precedence).
  Iterable<SeerrRequest> get _failedRequests => (_mediaInfo?.requests ?? const <SeerrRequest>[]).where(
    (r) => (r.is4k ?? false) == _is4k && r.status == SeerrRequestStatus.failed,
  );

  static bool _coversSeason(SeerrRequest request, int seasonNumber) =>
      request.seasons?.any((s) => s.seasonNumber == seasonNumber) ?? false;

  /// Read live: `_load`'s getPublicSettings call refreshes the session's
  /// product before any status renders.
  SeerrProduct get _product => widget.source.client.session.product;

  SeerrMediaStatus _variantStatus(int? statusCode, int? status4kCode) =>
      SeerrMediaStatus.resolve(_is4k ? status4kCode : statusCode, _product);

  /// Why this title/season can't be requested, or null when it can.
  String? _blockedLabel(SeerrMediaStatus status, {required bool coveredByRequest, required bool coveredByFailed}) {
    return switch (status) {
      SeerrMediaStatus.available => t.seerr.statusAvailable,
      SeerrMediaStatus.partiallyAvailable => t.seerr.statusPartiallyAvailable,
      // Processing/Pending with no live request backing it is a stale
      // pipeline status left behind by a failed arr push — re-requestable.
      SeerrMediaStatus.processing || SeerrMediaStatus.pending when coveredByFailed && !coveredByRequest => null,
      SeerrMediaStatus.processing => t.seerr.statusProcessing,
      SeerrMediaStatus.pending => t.seerr.statusRequested,
      // Blocklisted titles cannot be requested at all; deleted ones may be
      // re-requested, so they fall through like unknown.
      SeerrMediaStatus.blocklisted => t.seerr.statusBlocklisted,
      SeerrMediaStatus.unknown || SeerrMediaStatus.deleted when coveredByRequest => t.seerr.statusRequested,
      SeerrMediaStatus.unknown || SeerrMediaStatus.deleted => null,
    };
  }

  /// Movies block at the title level; shows block per season.
  String? get _movieBlockedLabel {
    final info = _mediaInfo;
    if (info == null) return null;
    return _blockedLabel(
      _variantStatus(info.statusCode, info.status4kCode),
      coveredByRequest: _activeRequests.isNotEmpty,
      coveredByFailed: _failedRequests.isNotEmpty,
    );
  }

  String? _seasonBlockedLabel(int seasonNumber) {
    final info = _mediaInfo;
    if (info == null) return null;
    final season = info.seasons?.firstWhereOrNull((s) => s.seasonNumber == seasonNumber);
    final covered = _activeRequests.any((r) => _coversSeason(r, seasonNumber));
    return _blockedLabel(
      _variantStatus(season?.statusCode, season?.status4kCode),
      coveredByRequest: covered,
      coveredByFailed: _failedRequests.any((r) => _coversSeason(r, seasonNumber)),
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
    // The gates were derived when the sheet was built; the mask may have
    // moved since (a refresh landing between build and press). Seerr would
    // refuse anyway — fail locally, localized, without the round-trip.
    if (!_connected || !widget.source.canRequest(widget.kind) || (_is4k && !_can4k)) {
      setState(() => _errorText = t.seerr.permissionRevoked);
      _reconcileAuthority();
      return;
    }
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
      tags: advanced ? _tags : null,
    );
    String? errorText;
    try {
      await widget.source.client.createRequest(payload);
      if (!mounted) return;
      // The sheet may be hosted by an OverlaySheetHost (no route of its own),
      // so a bare Navigator.pop would pop the screen underneath instead.
      OverlaySheetController.closeAdaptive(context);
      showSuccessSnackBar(context, t.seerr.requestSubmitted);
      return;
    } on SeerrApiException catch (e) {
      errorText = e.message;
    } on SeerrPermissionException catch (e) {
      // The client adopted the probe's mask before throwing; the reconcile
      // below closes the sheet (request permission gone) or trims it (4K or
      // advanced gone) from that authority.
      errorText = e.display;
    } on SeerrProxyException catch (e) {
      errorText = e.display;
    } catch (e) {
      appLogger.w('Seerr: request submit failed', error: e);
      errorText = t.seerr.requestFailed(error: '$e');
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _errorText = errorText;
    });
    _reconcileAuthority();
  }

  bool get _hasVisibleAdvancedControls {
    if (!_advancedAllowed || _serversForVariant.isEmpty) return false;
    final detail = _serverDetail;
    return _serversForVariant.length > 1 ||
        (detail?.profiles?.isNotEmpty ?? false) ||
        (detail?.rootFolders?.isNotEmpty ?? false) ||
        (detail?.languageProfiles?.isNotEmpty ?? false) ||
        (detail?.tags?.isNotEmpty ?? false);
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

  /// Option label, marking the instance default the way the web requester
  /// does (`Anime (Default)`).
  String _describeOption(String name, {required bool isDefault}) =>
      isDefault ? t.seerr.defaultOption(name: name) : name;

  String _tagsSummary(List<SeerrServiceTag> tags) {
    final selected = _tags ?? const <int>[];
    final labels = [
      for (final tag in tags)
        if (selected.contains(tag.id)) tag.label ?? '#${tag.id}',
    ];
    return labels.isEmpty ? t.seerr.noTags : labels.join(', ');
  }

  void _toggleTag(List<SeerrServiceTag> tags, int id, bool checked) {
    final selected = {...?_tags};
    if (checked) {
      selected.add(id);
    } else {
      selected.remove(id);
    }
    // Keep the arr's tag order so the payload is stable across toggles.
    setState(() {
      _tags = [
        for (final tag in tags)
          if (selected.contains(tag.id)) tag.id,
      ];
    });
  }

  List<Widget> _buildAdvancedSection(ThemeData theme) {
    final servers = _serversForVariant;
    final server = _serverDetail?.server ?? _server;
    final detail = _serverDetail;
    final profiles = detail?.profiles ?? const <SeerrServiceProfile>[];
    final folders = detail?.rootFolders ?? const <SeerrRootFolder>[];
    final languages = detail?.languageProfiles ?? const <SeerrServiceProfile>[];
    final tags = detail?.tags ?? const <SeerrServiceTag>[];
    final defaultProfileId = _defaultProfileId(server);
    final defaultRootFolder = _defaultRootFolder(server);
    final defaultLanguageProfileId = _defaultLanguageProfileId(server);
    String describeProfile(SeerrServiceProfile p) =>
        _describeOption(p.name ?? '#${p.id}', isDefault: p.id == defaultProfileId);
    String describeFolder(SeerrRootFolder f) =>
        _describeOption(f.path ?? '#${f.id}', isDefault: f.path == defaultRootFolder);
    String describeLanguage(SeerrServiceProfile p) =>
        _describeOption(p.name ?? '#${p.id}', isDefault: p.id == defaultLanguageProfileId);
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
          value: profiles.where((p) => p.id == _profileId).map(describeProfile).firstOrNull ?? '',
          options: profiles,
          describe: describeProfile,
          isSelected: (p) => p.id == _profileId,
          enabled: !_submitting,
          onSelected: (p) => setState(() => _profileId = p.id),
        ),
      if (folders.isNotEmpty)
        _PickerTile<SeerrRootFolder>(
          icon: Symbols.folder_rounded,
          label: t.seerr.rootFolder,
          value: folders.where((f) => f.path == _rootFolder).map(describeFolder).firstOrNull ?? _rootFolder ?? '',
          options: folders,
          describe: describeFolder,
          isSelected: (f) => f.path == _rootFolder,
          enabled: !_submitting,
          onSelected: (f) => setState(() => _rootFolder = f.path),
        ),
      if (languages.isNotEmpty)
        _PickerTile<SeerrServiceProfile>(
          icon: Symbols.language_rounded,
          label: t.seerr.languageProfile,
          value: languages.where((p) => p.id == _languageProfileId).map(describeLanguage).firstOrNull ?? '',
          options: languages,
          describe: describeLanguage,
          isSelected: (p) => p.id == _languageProfileId,
          enabled: !_submitting,
          onSelected: (p) => setState(() => _languageProfileId = p.id),
        ),
      // Tags stay inline rather than on a nested sheet page: the host builds
      // only the top page, so pushing one would dispose this state and drop
      // the season/4K/picker selections on the way back.
      if (tags.isNotEmpty) ...[
        FocusableListTile(
          leading: const AppIcon(Symbols.label_rounded, fill: 1),
          title: Text(t.seerr.tags),
          subtitle: Text(_tagsSummary(tags), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: AppIcon(_tagsExpanded ? Symbols.expand_less_rounded : Symbols.expand_more_rounded, fill: 1),
          contentPadding: EdgeInsets.zero,
          enabled: !_submitting,
          onTap: () => setState(() => _tagsExpanded = !_tagsExpanded),
        ),
        if (_tagsExpanded)
          for (final tag in tags)
            FocusableCheckboxListTile(
              value: _tags?.contains(tag.id) ?? false,
              onChanged: _submitting ? null : (checked) => _toggleTag(tags, tag.id, checked ?? false),
              title: Text(tag.label ?? '#${tag.id}'),
              contentPadding: const EdgeInsetsDirectional.only(start: 40),
              controlAffinity: ListTileControlAffinity.leading,
            ),
      ],
      if (_isAnime) ...[
        const SizedBox(height: 8),
        Text(
          t.seerr.animeNote,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
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
