import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_button.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../models/seerr/seerr_media_info.dart';
import '../../models/seerr/seerr_request.dart';
import '../../models/seerr/seerr_service_instance.dart';
import '../../models/seerr/seerr_tv_details.dart';
import '../../providers/seerr_requests_provider.dart';
import '../../providers/seerr_session_provider.dart';
import '../../services/seerr/seerr_client.dart';
import '../../services/seerr/seerr_constants.dart';
import '../../services/seerr/seerr_exceptions.dart';
import '../../services/seerr/seerr_permissions.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/loading_indicator_box.dart';
import '../../widgets/overlay_sheet.dart';
import 'widgets/seerr_status_badge.dart';
import 'widgets/seerr_tv_picker.dart';

/// Bottom sheet to submit a Seerr request. The basic flow is a single
/// "Submit request" button for movies and per-season checkboxes for TV.
///
/// When the active user has the `requestAdvanced` permission, an additional
/// "Advanced options" section reveals server / quality profile / root folder
/// / language profile pickers — mirroring what the Seerr web UI exposes.
/// Users with the `request4k` permission see an additional 4K toggle.
class SeerrRequestSheet extends StatefulWidget {
  final int tmdbId;
  final String title;
  final String mediaType;
  final String? posterPath;
  final String? overview;
  final String? year;
  final SeerrTvDetails? tv;

  /// TV-only. When true, the sheet opens with every season that isn't
  /// already AVAILABLE pre-checked — useful when the user lands on the
  /// sheet from a library-detail screen and wants to fill in what's
  /// missing without manually ticking each season.
  final bool preSelectMissingSeasons;

  /// TV-only. When non-null, the sheet opens with exactly these season
  /// numbers pre-checked (any already-AVAILABLE numbers are silently
  /// dropped). Takes precedence over [preSelectMissingSeasons].
  final List<int>? preSelectedSeasons;

  const SeerrRequestSheet.movie({
    super.key,
    required this.tmdbId,
    required this.title,
    this.posterPath,
    this.overview,
    this.year,
  }) : tv = null,
       mediaType = 'movie',
       preSelectMissingSeasons = false,
       preSelectedSeasons = null;

  const SeerrRequestSheet.tv({
    super.key,
    required this.tmdbId,
    required this.title,
    required SeerrTvDetails details,
    this.posterPath,
    this.overview,
    this.year,
    this.preSelectMissingSeasons = false,
    this.preSelectedSeasons,
  }) : tv = details,
       mediaType = 'tv';

  @override
  State<SeerrRequestSheet> createState() => _SeerrRequestSheetState();

  static Future<void> show(BuildContext context, SeerrRequestSheet sheet) {
    // Use the overlay sheet host when one's in the tree (TV-friendly: focus
    // management + back-key handling + sub-page push). Falls back to the
    // Material modal bottom sheet on screens without a host.
    return OverlaySheetController.showAdaptive<void>(
      context,
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

  @override
  void initState() {
    super.initState();
    if (widget.tv == null) return;
    final explicit = widget.preSelectedSeasons;
    if (explicit != null) {
      // Caller picked specific seasons — honor them but skip ones that are
      // already AVAILABLE (Seerr would reject the request anyway).
      final requestable = _requestableSeasons.map((s) => s.seasonNumber).toSet();
      _selectedSeasons.addAll(explicit.where(requestable.contains));
    } else if (widget.preSelectMissingSeasons) {
      // Pre-tick every season Seerr doesn't already report as available so
      // the user can hit Submit immediately when they came in to fill the
      // gaps. They can still uncheck specific seasons before submitting.
      _selectedSeasons.addAll(_requestableSeasons.map((s) => s.seasonNumber));
    }
  }

  // Advanced-form state — only used when `_canRequestAdvanced` is true.
  bool _is4k = false;
  bool _advancedExpanded = false;
  bool _loadingAdvanced = false;
  String? _advancedError;
  List<SeerrServiceInstance> _allServices = const [];
  int? _selectedServerId;
  SeerrServiceDetail? _selectedDetail;
  int? _selectedProfileId;
  SeerrRootFolder? _selectedRootFolder;
  int? _selectedLanguageProfileId;

  late final SeerrSessionProvider _session = context.read<SeerrSessionProvider>();
  int get _permissions => _session.connection?.permissions ?? 0;

  bool get _canRequest4k => SeerrPermissions.can4kRequest(
    permissions: _permissions,
    forTv: widget.tv != null,
  );

  bool get _canRequestAdvanced => SeerrPermissions.has(_permissions, SeerrPermissions.requestAdvanced);

  List<SeerrSeason> get _selectableSeasons =>
      widget.tv?.seasons.where((s) => s.seasonNumber > 0).toList() ?? const [];

  /// Seasons that are already fully available — pre-marked so the user can't
  /// re-request them (no point) and they read as disabled in the list.
  Set<int> get _availableSeasons {
    final info = widget.tv?.mediaInfo;
    if (info == null) return const {};
    final available = <int>{};
    for (final s in _selectableSeasons) {
      final status = info.seasonStatus(s.seasonNumber, is4k: _is4k);
      if (status == SeerrMediaStatus.available) available.add(s.seasonNumber);
    }
    return available;
  }

  Iterable<SeerrSeason> get _requestableSeasons =>
      _selectableSeasons.where((s) => !_availableSeasons.contains(s.seasonNumber));

  bool get _allRequestableSelected =>
      _requestableSeasons.isNotEmpty &&
      _requestableSeasons.every((s) => _selectedSeasons.contains(s.seasonNumber));

  void _toggleAll() {
    setState(() {
      if (_allRequestableSelected) {
        _selectedSeasons.clear();
      } else {
        _selectedSeasons
          ..clear()
          ..addAll(_requestableSeasons.map((s) => s.seasonNumber));
      }
    });
  }

  Future<void> _expandAdvanced() async {
    setState(() => _advancedExpanded = !_advancedExpanded);
    if (_advancedExpanded && _allServices.isEmpty && !_loadingAdvanced) {
      await _loadServices();
    }
  }

  Future<void> _loadServices() async {
    final client = _session.client;
    if (client == null) return;
    setState(() {
      _loadingAdvanced = true;
      _advancedError = null;
    });
    try {
      final services = widget.tv != null ? await client.getSonarrServices() : await client.getRadarrServices();
      if (!mounted) return;
      setState(() {
        _allServices = services;
        _loadingAdvanced = false;
      });
      _autoPickDefaultServer();
    } catch (e, st) {
      appLogger.w('Seerr: failed to load service list', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingAdvanced = false;
        _advancedError = t.seerr.request.advancedLoadFailed;
      });
    }
  }

  /// Filter the cached service list by the 4K toggle and select the
  /// default-for-tier server, then load its detail.
  Future<void> _autoPickDefaultServer() async {
    final filtered = _allServices.where((s) => s.is4k == _is4k).toList();
    if (filtered.isEmpty) {
      setState(() {
        _selectedServerId = null;
        _selectedDetail = null;
        _selectedProfileId = null;
        _selectedRootFolder = null;
        _selectedLanguageProfileId = null;
      });
      return;
    }
    final pick = filtered.firstWhere((s) => s.isDefault, orElse: () => filtered.first);
    await _selectServer(pick.id);
  }

  Future<void> _selectServer(int serverId) async {
    setState(() {
      _selectedServerId = serverId;
      _selectedDetail = null;
      _selectedProfileId = null;
      _selectedRootFolder = null;
      _selectedLanguageProfileId = null;
      _loadingAdvanced = true;
      _advancedError = null;
    });
    final client = _session.client;
    if (client == null) {
      setState(() => _loadingAdvanced = false);
      return;
    }
    try {
      final detail = widget.tv != null
          ? await client.getSonarrService(serverId)
          : await client.getRadarrService(serverId);
      if (!mounted || _selectedServerId != serverId) return;
      setState(() {
        _selectedDetail = detail;
        _loadingAdvanced = false;
        _selectedProfileId = detail.server.activeProfileId ??
            (detail.profiles.isNotEmpty ? detail.profiles.first.id : null);
        _selectedRootFolder = detail.rootFolders.firstWhere(
          (r) => r.path == detail.server.activeDirectory,
          orElse: () => detail.rootFolders.isNotEmpty ? detail.rootFolders.first : const SeerrRootFolder(id: 0, path: ''),
        );
        if (_selectedRootFolder?.path.isEmpty == true) _selectedRootFolder = null;
        _selectedLanguageProfileId = detail.server.activeLanguageProfileId ??
            (detail.languageProfiles.isNotEmpty ? detail.languageProfiles.first.id : null);
      });
    } catch (e, st) {
      appLogger.w('Seerr: failed to load service detail', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingAdvanced = false;
        _advancedError = t.seerr.request.advancedLoadFailed;
      });
    }
  }

  Future<void> _onToggle4k(bool value) async {
    setState(() {
      _is4k = value;
      // Clear selections — they're tier-specific so resetting prevents
      // submitting a non-4K profile id against a 4K server (or vice versa).
      _selectedSeasons.removeWhere((s) => _availableSeasons.contains(s));
    });
    if (_advancedExpanded && _allServices.isNotEmpty) {
      await _autoPickDefaultServer();
    }
  }

  Future<void> _submit() async {
    final session = _session;
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
      final seasonsList = widget.tv == null ? null : (_selectedSeasons.toList()..sort());
      final payload = SeerrRequestPayload(
        mediaType: widget.mediaType,
        mediaId: widget.tmdbId,
        seasons: seasonsList,
        is4k: _canRequest4k ? _is4k : null,
        serverId: _canRequestAdvanced ? _selectedServerId : null,
        profileId: _canRequestAdvanced ? _selectedProfileId : null,
        rootFolder: _canRequestAdvanced ? _selectedRootFolder?.path : null,
        languageProfileId: _canRequestAdvanced && widget.tv != null ? _selectedLanguageProfileId : null,
      );
      final created = await client.createRequest(payload);
      if (!mounted) return;
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
              if (_canRequest4k) ...[
                const SizedBox(height: 4),
                _FocusableToggleRow(
                  title: t.seerr.request.request4kTitle,
                  subtitle: t.seerr.request.request4kSubtitle,
                  value: _is4k,
                  onChanged: _submitting ? null : (v) => unawaited(_onToggle4k(v)),
                ),
              ],
              if (_canRequestAdvanced) _AdvancedSection(
                expanded: _advancedExpanded,
                onToggle: _submitting ? null : _expandAdvanced,
                loading: _loadingAdvanced,
                error: _advancedError,
                services: _allServices.where((s) => s.is4k == _is4k).toList(),
                detail: _selectedDetail,
                selectedServerId: _selectedServerId,
                selectedProfileId: _selectedProfileId,
                selectedRootFolder: _selectedRootFolder,
                selectedLanguageProfileId: _selectedLanguageProfileId,
                showLanguageProfile: isTv,
                onServerChanged: _submitting
                    ? null
                    : (id) {
                        if (id != null) unawaited(_selectServer(id));
                      },
                onProfileChanged: (id) => setState(() => _selectedProfileId = id),
                onRootFolderChanged: (root) => setState(() => _selectedRootFolder = root),
                onLanguageChanged: (id) => setState(() => _selectedLanguageProfileId = id),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FocusableButton(
                onPressed: _submitting ? null : _submit,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const LoadingIndicatorBox()
                      : const AppIcon(Symbols.send_rounded, fill: 1),
                  label: Text(_submitLabel(isTv)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _submitLabel(bool isTv) {
    if (!isTv) return t.seerr.request.requestMovie;
    return t.seerr.request.requestSelectedSeasons(count: _selectedSeasons.length);
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
      _FocusableCheckRow(
        title: t.seerr.request.allSeasons,
        checked: _allRequestableSelected,
        onChanged: _requestableSeasons.isEmpty ? null : (_) => _toggleAll(),
      ),
      const Divider(height: 1),
      for (final s in seasons) _buildSeasonTile(theme, s),
    ];
  }

  Widget _buildSeasonTile(ThemeData theme, SeerrSeason s) {
    final info = widget.tv?.mediaInfo;
    final status = info?.seasonStatus(s.seasonNumber, is4k: _is4k) ?? SeerrMediaStatus.unknown;
    final alreadyAvailable = status == SeerrMediaStatus.available;
    final episodeText = s.episodeCount > 0 ? t.seerr.request.episodeCount(count: s.episodeCount) : null;
    final checked = _selectedSeasons.contains(s.seasonNumber);

    return _FocusableCheckRow(
      title: t.seerr.request.seasonNumber(number: s.seasonNumber),
      subtitle: episodeText,
      checked: checked,
      trailing: status == SeerrMediaStatus.unknown ? null : SeerrStatusBadge.media(context, status),
      onChanged: alreadyAvailable
          ? null
          : (v) {
              setState(() {
                if (v) {
                  _selectedSeasons.add(s.seasonNumber);
                } else {
                  _selectedSeasons.remove(s.seasonNumber);
                }
              });
            },
    );
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

/// Expandable advanced-options panel for users with `requestAdvanced`. Server
/// / profile / root folder / language pickers all default to the Seerr-side
/// defaults so submitting without touching anything mimics the basic flow.
class _AdvancedSection extends StatelessWidget {
  final bool expanded;
  final Future<void> Function()? onToggle;
  final bool loading;
  final String? error;
  final List<SeerrServiceInstance> services;
  final SeerrServiceDetail? detail;
  final int? selectedServerId;
  final int? selectedProfileId;
  final SeerrRootFolder? selectedRootFolder;
  final int? selectedLanguageProfileId;
  final bool showLanguageProfile;
  final ValueChanged<int?>? onServerChanged;
  final ValueChanged<int?> onProfileChanged;
  final ValueChanged<SeerrRootFolder?> onRootFolderChanged;
  final ValueChanged<int?> onLanguageChanged;

  const _AdvancedSection({
    required this.expanded,
    required this.onToggle,
    required this.loading,
    required this.error,
    required this.services,
    required this.detail,
    required this.selectedServerId,
    required this.selectedProfileId,
    required this.selectedRootFolder,
    required this.selectedLanguageProfileId,
    required this.showLanguageProfile,
    required this.onServerChanged,
    required this.onProfileChanged,
    required this.onRootFolderChanged,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle == null ? null : () => onToggle!(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const AppIcon(Symbols.tune_rounded, fill: 1, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.seerr.request.advancedOptions, style: theme.textTheme.titleSmall)),
                  AppIcon(
                    expanded ? Symbols.expand_less_rounded : Symbols.expand_more_rounded,
                    fill: 1,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) _buildBody(context, theme),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    if (loading && detail == null) {
      return const Padding(padding: EdgeInsets.all(12), child: Center(child: LoadingIndicatorBox()));
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
      );
    }
    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(t.seerr.request.advancedNoServers, style: theme.textTheme.bodySmall),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        SeerrTvPicker<int>(
          label: t.seerr.request.serverLabel,
          value: selectedServerId,
          enabled: onServerChanged != null,
          options: [
            for (final s in services)
              SeerrTvPickerOption(
                value: s.id,
                label: s.name,
                subtitle: s.isDefault ? t.seerr.request.defaultTag : null,
              ),
          ],
          onChanged: (id) => onServerChanged?.call(id),
        ),
        const SizedBox(height: 12),
        if (detail != null) ...[
          SeerrTvPicker<int>(
            label: t.seerr.request.profileLabel,
            value: selectedProfileId,
            options: [
              for (final p in detail!.profiles)
                SeerrTvPickerOption(
                  value: p.id,
                  label: p.name,
                  subtitle: detail!.server.activeProfileId == p.id ? t.seerr.request.defaultTag : null,
                ),
            ],
            onChanged: (id) => onProfileChanged(id),
          ),
          const SizedBox(height: 12),
          SeerrTvPicker<SeerrRootFolder>(
            label: t.seerr.request.rootFolderLabel,
            value: selectedRootFolder,
            options: [
              for (final r in detail!.rootFolders)
                SeerrTvPickerOption(
                  value: r,
                  label: r.path,
                  subtitle: detail!.server.activeDirectory == r.path ? t.seerr.request.defaultTag : null,
                ),
            ],
            onChanged: (root) => onRootFolderChanged(root),
          ),
          if (showLanguageProfile && detail!.languageProfiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            SeerrTvPicker<int>(
              label: t.seerr.request.languageLabel,
              value: selectedLanguageProfileId,
              options: [
                for (final l in detail!.languageProfiles)
                  SeerrTvPickerOption(value: l.id, label: l.name),
              ],
              onChanged: (id) => onLanguageChanged(id),
            ),
          ],
        ],
      ],
    );
  }
}

/// Focusable replacement for [CheckboxListTile]. Toggleable via tap on
/// desktop/mobile and via D-pad SELECT on TV; gets a Plezy focus border.
class _FocusableCheckRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool checked;
  final Widget? trailing;
  final ValueChanged<bool>? onChanged;

  const _FocusableCheckRow({
    required this.title,
    this.subtitle,
    required this.checked,
    this.trailing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onChanged == null;
    final muted = theme.colorScheme.onSurface.withValues(alpha: disabled ? 0.4 : 0.7);
    return FocusableWrapper(
      disableScale: true,
      borderRadius: 6,
      descendantsAreFocusable: false,
      onSelect: disabled ? null : () => onChanged!(!checked),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : () => onChanged!(!checked),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Checkbox(
                  value: checked,
                  onChanged: disabled ? null : (v) => onChanged!(v ?? false),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: disabled ? muted : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Focusable replacement for [SwitchListTile].
class _FocusableToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _FocusableToggleRow({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onChanged == null;
    final muted = theme.colorScheme.onSurface.withValues(alpha: disabled ? 0.4 : 0.7);
    return FocusableWrapper(
      disableScale: true,
      borderRadius: 6,
      descendantsAreFocusable: false,
      onSelect: disabled ? null : () => onChanged!(!value),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : () => onChanged!(!value),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.bodyLarge),
                      if (subtitle != null)
                        Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                    ],
                  ),
                ),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

