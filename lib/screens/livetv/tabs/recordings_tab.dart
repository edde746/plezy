import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../../exceptions/media_server_exceptions.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../i18n/strings.g.dart';
import '../../../i18n/iptv_copy.dart';
import '../../../iptv/dispatcharr_dvr_client.dart';
import '../../../iptv/iptv_models.dart';
import '../../../iptv/iptv_source_repository.dart';
import '../../../media/media_server_client.dart';
import '../../../models/livetv_program.dart';
import '../../../models/media_grab_operation.dart';
import '../../../models/media_subscription.dart';
import '../../../profiles/active_profile_provider.dart';
import '../../../providers/multi_server_provider.dart';
import '../../../sources/source_models.dart';
import '../../../sources/source_playback.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/dialogs.dart';
import '../../../utils/formatters.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/settings_section.dart';
import '../../sources/source_player_screen.dart';
import '../live_tv_refresh_mixin.dart';
import '../live_tv_server_iteration.dart';
import '../livetv_recording_actions.dart';
import '../livetv_styles.dart';

class RecordingsTab extends StatefulWidget {
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  const RecordingsTab({super.key, this.onNavigateUp, this.onBack});

  @override
  State<RecordingsTab> createState() => RecordingsTabState();
}

class _ServerRecordings {
  final String serverId;
  final MediaServerClient client;
  final List<MediaGrabOperation> grabs;
  final List<MediaSubscription> rules;

  const _ServerRecordings({required this.serverId, required this.client, required this.grabs, required this.rules});
}

class _GrabEntry {
  final _ServerRecordings server;
  final MediaGrabOperation op;

  const _GrabEntry(this.server, this.op);
}

class _RuleEntry {
  final _ServerRecordings server;
  final MediaSubscription rule;

  const _RuleEntry(this.server, this.rule);
}

enum _RuleAction { edit, delete }
enum _DispatcharrAction { play, stop, delete }

class RecordingsTabState extends State<RecordingsTab> with WidgetsBindingObserver, LiveTvRefreshMixin<RecordingsTab> {
  List<_ServerRecordings> _serverRecordings = [];
  List<IptvLocalRecording> _localRecordings = [];
  List<IptvLocalRecordingSchedule> _localSchedules = [];
  List<IptvDispatcharrRecording> _dispatcharrRecordings = [];
  List<IptvDispatcharrRule> _dispatcharrRules = [];
  String? _iptvError;
  bool _isLoading = true;
  bool _adminBlocked = false;
  String? _error;
  bool _pendingFocus = false;
  int _loadGeneration = 0;
  Future<void>? _loadFuture;
  bool _loadPending = false;
  final _firstTileFocusNode = FocusNode(debugLabel: 'recordings_tab_first_tile');

  @override
  Duration get refreshInterval => const Duration(seconds: 30);

  @override
  void onRefreshTick() => unawaited(_load());

  // Same three gates as WhatsOnTab, but re-selecting the tab also reloads: a
  // recording scheduled from the guide has to show up on arrival, not on the
  // next 30s tick.
  @override
  void onRefreshResumed(LiveTvRefreshResumeReason reason) {
    if (reason == LiveTvRefreshResumeReason.tabSelected) unawaited(_load());
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _loadGeneration++;
    _firstTileFocusNode.dispose();
    super.dispose();
  }

  void focusContent() {
    if (_isLoading) {
      _pendingFocus = true;
      return;
    }
    _pendingFocus = false;
    if (_firstTileFocusNode.context != null) {
      _firstTileFocusNode.requestFocus();
    }
  }

  /// Public reload helper for the parent screen's refresh action.
  Future<void> reload() => _load();

  bool _isCurrentLoad(int generation) => mounted && generation == _loadGeneration;

  Future<void> _load() {
    if (!mounted) return Future.value();
    final inFlight = _loadFuture;
    if (inFlight != null) {
      _loadPending = true;
      return inFlight;
    }

    final load = _drainLoads().whenComplete(() => _loadFuture = null);
    _loadFuture = load;
    return load;
  }

  Future<void> _drainLoads() async {
    do {
      _loadPending = false;
      await _loadOnce();
    } while (mounted && _loadPending);
  }

  Future<void> _loadOnce() async {
    if (!mounted) return;
    final loadGeneration = ++_loadGeneration;
    setState(() {
      _isLoading = _serverRecordings.isEmpty &&
          _localRecordings.isEmpty &&
          _localSchedules.isEmpty &&
          _dispatcharrRecordings.isEmpty &&
          _dispatcharrRules.isEmpty;
      _error = null;
    });

    final multiServer = context.read<MultiServerProvider>();
    final results = <_ServerRecordings>[];
    var anyAdminError = false;
    var anyOtherError = false;

    await forEachLiveTvServer(
      multiServer,
      resolveClient: multiServer.getClientForServer,
      isCurrent: () => _isCurrentLoad(loadGeneration),
      body: (client, serverInfo) async {
        final dvr = client.liveTvDvr;
        if (dvr == null) return;
        final grabs = await dvr.fetchScheduledRecordings();
        if (!_isCurrentLoad(loadGeneration)) return;
        final rules = await dvr.fetchRecordingRules();
        if (!_isCurrentLoad(loadGeneration)) return;
        results.add(_ServerRecordings(serverId: serverInfo.serverId, client: client, grabs: grabs, rules: rules));
      },
      onError: (client, serverInfo, error, stackTrace) {
        if (!_isCurrentLoad(loadGeneration)) return;
        appLogger.e('Failed to load recordings for ${serverInfo.serverId}', error: error);
        if (error is MediaServerHttpException && error.statusCode == 403) {
          anyAdminError = true;
        } else {
          anyOtherError = true;
        }
      },
    );

    if (!_isCurrentLoad(loadGeneration)) return;
    final profileId = context.read<ActiveProfileProvider>().activeId;
    var localRecordings = <IptvLocalRecording>[];
    var localSchedules = <IptvLocalRecordingSchedule>[];
    var dispatcharrRecordings = <IptvDispatcharrRecording>[];
    var dispatcharrRules = <IptvDispatcharrRule>[];
    var iptvFailed = false;
    if (profileId != null) {
      final repository = context.read<IptvSourceRepository>();
      try {
        localRecordings = await repository.localRecordings(profileId);
        localSchedules = await repository.localRecordingSchedules(profileId: profileId);
      } on Object catch (error, stackTrace) {
        iptvFailed = true;
        appLogger.e('Failed to load local IPTV recordings', error: error, stackTrace: stackTrace);
      }
      try {
        dispatcharrRecordings = await repository.dispatcharrRecordings(profileId);
        dispatcharrRules = await repository.dispatcharrRules(profileId);
      } on Object catch (error, stackTrace) {
        iptvFailed = true;
        appLogger.e('Failed to load Dispatcharr DVR items', error: error, stackTrace: stackTrace);
      }
    }

    if (!_isCurrentLoad(loadGeneration)) return;
    setState(() {
      _serverRecordings = results;
      _localRecordings = localRecordings;
      _localSchedules = localSchedules;
      _dispatcharrRecordings = dispatcharrRecordings;
      _dispatcharrRules = dispatcharrRules;
      _iptvError = iptvFailed ? t.iptv.recordingLoadFailed : null;
      _isLoading = false;
      final hasIptvItems = localRecordings.isNotEmpty || localSchedules.isNotEmpty || dispatcharrRecordings.isNotEmpty || dispatcharrRules.isNotEmpty;
      _adminBlocked = results.isEmpty && !hasIptvItems && anyAdminError;
      _error = (results.isEmpty && !hasIptvItems && anyOtherError && !anyAdminError) ? t.liveTv.recordingFailed : null;
    });
    if (_pendingFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isCurrentLoad(loadGeneration)) focusContent();
      });
    }
  }

  List<_GrabEntry> get _allGrabs {
    final entries = <_GrabEntry>[
      for (final server in _serverRecordings)
        for (final op in server.grabs) _GrabEntry(server, op),
    ];
    entries.sort((a, b) {
      final aStart = a.op.program?.beginsAt ?? 0;
      final bStart = b.op.program?.beginsAt ?? 0;
      return aStart.compareTo(bStart);
    });
    return entries;
  }

  List<_RuleEntry> get _allRules {
    final entries = <_RuleEntry>[
      for (final server in _serverRecordings)
        for (final rule in server.rules) _RuleEntry(server, rule),
    ];
    entries.sort((a, b) {
      final aType = a.rule.type ?? 0;
      final bType = b.rule.type ?? 0;
      // Series first (type 2), then episodes (type 4)
      final typeCompare = aType.compareTo(bType);
      if (typeCompare != 0) return typeCompare;
      return (a.rule.title ?? '').compareTo(b.rule.title ?? '');
    });
    return entries;
  }

  Future<void> _onCancelGrab(_GrabEntry entry) async {
    final cancelled = await confirmCancelGrab(context, entry.server.client, entry.op);
    if (cancelled) await _load();
  }

  Future<void> _onRuleTap(_RuleEntry entry) async {
    final action = await showOptionPickerDialog<_RuleAction>(
      context,
      title: entry.rule.title ?? '',
      options: [
        (icon: Symbols.edit_rounded, label: t.liveTv.editRuleAction, value: _RuleAction.edit),
        (icon: Symbols.delete_rounded, label: t.common.delete, value: _RuleAction.delete),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case _RuleAction.edit:
        final outcome = await editRecordingRule(context, entry.server.client, entry.rule);
        if (outcome == RecordOutcome.updated) await _load();
      case _RuleAction.delete:
        final deleted = await confirmDeleteRule(context, entry.server.client, entry.rule);
        if (deleted) await _load();
      case null:
        break;
    }
  }

  Future<void> _playLocalRecording(IptvLocalRecording recording) async {
    final file = File(recording.filePath);
    if (!await file.exists()) {
      if (mounted) showErrorSnackBar(context, t.iptv.recordingFileMissing);
      return;
    }
    final fileId = 'iptv-recording:${recording.id}';
    final extension = p.extension(recording.filePath).toLowerCase();
    final mediaFile = PublicationFile(
      id: fileId,
      name: p.basename(recording.filePath),
      mimeType: extension == '.mkv' ? 'video/x-matroska' : 'video/mp2t',
      size: await file.length(),
    );
    final entry = SourceEntry(
      sourceId: 'iptv-recordings:${recording.profileId}',
      id: recording.id,
      title: recording.programmeTitle?.isNotEmpty == true ? recording.programmeTitle! : recording.title,
      description: '${recording.title}\n${recording.startedAt.toLocal()}',
      kind: SourceItemKind.video,
      files: [mediaFile],
    );
    await context.read<SourcePlayback>().start(
      entry,
      [mediaFile],
      playbackMode: PublicationMode.watching,
      localOverrides: {fileId: file.uri},
      persistProgress: false,
    );
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SourcePlayerScreen()));
  }

  Future<void> _deleteLocalRecording(IptvLocalRecording recording) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.iptv.deleteRecording,
      message: t.iptv.deleteRecordingConfirm,
      confirmText: t.common.delete,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final repository = context.read<IptvSourceRepository>();
    try {
      final file = File(recording.filePath);
      if (await file.exists()) await file.delete();
      await repository.deleteLocalRecording(recording.profileId, recording.id);
      if (!mounted) return;
      showSnackBar(context, t.iptv.recordingDeleted);
      await _load();
    } on Object {
      if (mounted) showErrorSnackBar(context, t.iptv.recordingActionFailed);
    }
  }

  Future<void> _cancelLocalSchedule(IptvLocalRecordingSchedule schedule) async {
    final profileId = context.read<ActiveProfileProvider>().activeId;
    if (profileId == null || schedule.state != 'scheduled') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.iptv.cancelLocalRecording),
        content: Text(t.iptv.cancelLocalRecordingConfirm(programme: schedule.programmeTitle ?? schedule.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.common.cancel)),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.iptv.cancelSchedule)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<IptvSourceRepository>().cancelLocalRecordingSchedule(profileId, schedule.id);
      if (mounted) {
        showSnackBar(context, t.iptv.localRecordingCancelled);
        await _load();
      }
    } on Object {
      if (mounted) showErrorSnackBar(context, t.iptv.recordingActionFailed);
    }
  }

  Future<void> _onDispatcharrRecordingTap(IptvDispatcharrRecording recording) async {
    final action = await showOptionPickerDialog<_DispatcharrAction>(
      context,
      title: recording.title,
      options: [
        if (recording.isComplete)
          (icon: Symbols.play_arrow_rounded, label: t.iptv.play, value: _DispatcharrAction.play),
        if (recording.isRecording)
          (icon: Symbols.stop_circle_rounded, label: t.iptv.stopRecording, value: _DispatcharrAction.stop),
        (icon: Symbols.delete_rounded, label: t.common.delete, value: _DispatcharrAction.delete),
      ],
    );
    if (!mounted || action == null) return;
    final profileId = context.read<ActiveProfileProvider>().activeId;
    if (profileId == null) return;
    if (action == _DispatcharrAction.play) {
      await _playDispatcharrRecording(profileId, recording);
      return;
    }
    if (action == _DispatcharrAction.delete) {
      final confirmed = await showConfirmDialog(
        context,
        title: t.iptv.deleteRecording,
        message: t.iptv.deleteDispatcharrRecordingConfirm,
        confirmText: t.common.delete,
        isDestructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    try {
      final repository = context.read<IptvSourceRepository>();
      if (action == _DispatcharrAction.stop) {
        await repository.stopDispatcharrRecording(profileId, recording);
      } else {
        await repository.deleteDispatcharrRecording(profileId, recording);
      }
      if (!mounted) return;
      showSnackBar(context, action == _DispatcharrAction.stop ? t.iptv.recordingStopped : t.iptv.recordingDeleted);
      await _load();
    } on Object {
      if (mounted) showErrorSnackBar(context, t.iptv.recordingActionFailed);
    }
  }

  Future<void> _playDispatcharrRecording(String profileId, IptvDispatcharrRecording recording) async {
    try {
      final repository = context.read<IptvSourceRepository>();
      final playback = await repository.dispatcharrRecordingPlayback(profileId, recording);
      if (!mounted) return;
      final extension = p.extension(recording.filePath ?? '').toLowerCase();
      final mediaExtension = extension.isEmpty ? '.ts' : extension;
      final fileId = 'dispatcharr-recording:${recording.sourceId}:${recording.id}';
      final file = PublicationFile(
        id: fileId,
        name: '${recording.title}$mediaExtension',
        mimeType: mediaExtension == '.mkv' ? 'video/x-matroska' : 'video/mp2t',
        streamOnly: true,
      );
      final entry = SourceEntry(
        sourceId: 'dispatcharr-recordings:${recording.sourceId}',
        id: recording.id,
        title: recording.title,
        description: [recording.channelName, recording.startedAt?.toLocal().toString()].whereType<String>().join('\n'),
        kind: SourceItemKind.video,
        files: [file],
      );
      await context.read<SourcePlayback>().start(
        entry,
        [file],
        playbackMode: PublicationMode.watching,
        localOverrides: {fileId: playback.uri},
        localOverrideHeaders: {fileId: playback.headers},
        persistProgress: false,
      );
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SourcePlayerScreen()));
    } on Object {
      if (mounted) showErrorSnackBar(context, t.iptv.recordingActionFailed);
    }
  }

  Future<void> _onDispatcharrRuleTap(IptvDispatcharrRule rule) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.iptv.deleteRecordingRule,
      message: t.iptv.deleteRecordingRuleConfirm,
      confirmText: t.common.delete,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final profileId = context.read<ActiveProfileProvider>().activeId;
    if (profileId == null) return;
    try {
      await context.read<IptvSourceRepository>().deleteDispatcharrRule(profileId, rule);
      if (!mounted) return;
      showSnackBar(context, t.iptv.recordingDeleted);
      await _load();
    } on Object {
      if (mounted) showErrorSnackBar(context, t.iptv.recordingActionFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final hasIptvItems = _localRecordings.isNotEmpty || _localSchedules.isNotEmpty || _dispatcharrRecordings.isNotEmpty || _dispatcharrRules.isNotEmpty;
    if (_serverRecordings.isEmpty && !hasIptvItems && _adminBlocked) {
      return Center(child: _EmptyMessage(text: t.liveTv.dvrAdminRequired));
    }
    if (_serverRecordings.isEmpty && !hasIptvItems && _error != null) {
      return Center(child: _EmptyMessage(text: _error!));
    }

    final grabs = _allGrabs;
    final rules = _allRules;

    if (grabs.isEmpty && rules.isEmpty && _localSchedules.isEmpty && _localRecordings.isEmpty && _dispatcharrRecordings.isEmpty && _dispatcharrRules.isEmpty) {
      return Center(child: _EmptyMessage(text: _iptvError ?? t.liveTv.noScheduledRecordings));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        if (_iptvError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(_iptvError!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
          ),
        if (_localSchedules.isNotEmpty)
          SettingsGroup(
            title: t.iptv.localRecordingSchedules,
            children: [
              for (var i = 0; i < _localSchedules.length; i++)
                _LocalIptvScheduleTile(
                  schedule: _localSchedules[i],
                  autofocus: i == 0,
                  focusNode: i == 0 ? _firstTileFocusNode : null,
                  onNavigateUp: i == 0 ? widget.onNavigateUp : null,
                  onBack: widget.onBack,
                  onCancel: () => _cancelLocalSchedule(_localSchedules[i]),
                ),
            ],
          ),
        if (_localRecordings.isNotEmpty)
          SettingsGroup(
            title: t.iptv.localRecordings,
            children: [
              for (var i = 0; i < _localRecordings.length; i++)
                _LocalIptvRecordingTile(
                  recording: _localRecordings[i],
                  autofocus: _localSchedules.isEmpty && grabs.isEmpty && rules.isEmpty && i == 0,
                  focusNode: _localSchedules.isEmpty && grabs.isEmpty && rules.isEmpty && i == 0 ? _firstTileFocusNode : null,
                  onPlay: () => _playLocalRecording(_localRecordings[i]),
                  onDelete: () => _deleteLocalRecording(_localRecordings[i]),
                  onNavigateUp: _localSchedules.isEmpty && grabs.isEmpty && rules.isEmpty && i == 0 ? widget.onNavigateUp : null,
                  onBack: widget.onBack,
                ),
            ],
          ),
        if (_dispatcharrRecordings.isNotEmpty)
          SettingsGroup(
            title: t.iptv.dispatcharrRecordings,
            children: [
              for (final recording in _dispatcharrRecordings)
                _DispatcharrRecordingTile(recording: recording, onTap: () => _onDispatcharrRecordingTap(recording)),
            ],
          ),
        if (_dispatcharrRules.isNotEmpty)
          SettingsGroup(
            title: t.iptv.dispatcharrRules,
            children: [
              for (final rule in _dispatcharrRules)
                _DispatcharrRuleTile(rule: rule, onTap: () => _onDispatcharrRuleTap(rule)),
            ],
          ),
        if (grabs.isNotEmpty)
          SettingsGroup(
            title: t.liveTv.scheduledRecordings,
            children: [
              for (var i = 0; i < grabs.length; i++)
                _GrabTile(
                  entry: grabs[i],
                  autofocus: i == 0,
                  focusNode: i == 0 ? _firstTileFocusNode : null,
                  onTap: () => _onCancelGrab(grabs[i]),
                  onNavigateUp: i == 0 ? widget.onNavigateUp : null,
                  onBack: widget.onBack,
                ),
            ],
          ),
        if (rules.isNotEmpty)
          SettingsGroup(
            title: t.liveTv.recordingRules,
            children: [
              for (var i = 0; i < rules.length; i++)
                _RuleTile(
                  entry: rules[i],
                  autofocus: grabs.isEmpty && i == 0,
                  focusNode: grabs.isEmpty && i == 0 ? _firstTileFocusNode : null,
                  onTap: () => _onRuleTap(rules[i]),
                  onNavigateUp: grabs.isEmpty && i == 0 ? widget.onNavigateUp : null,
                  onBack: widget.onBack,
                ),
            ],
          ),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;

  const _EmptyMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: .min,
        children: [
          AppIcon(Symbols.fiber_manual_record_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _LocalIptvScheduleTile extends StatelessWidget {
  const _LocalIptvScheduleTile({
    required this.schedule,
    required this.onCancel,
    required this.autofocus,
    this.focusNode,
    this.onNavigateUp,
    this.onBack,
  });

  final IptvLocalRecordingSchedule schedule;
  final VoidCallback onCancel;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starts = schedule.startsAt.toLocal();
    final ends = schedule.endsAt.toLocal();
    final active = schedule.state == 'recording' || schedule.state == 'starting';
    final failed = schedule.state == 'failed';
    final missed = schedule.state == 'missed';
    final subtitle = [
      formatRelativeDayLabel(starts),
      formatClockTime(starts, is24Hour: MediaQuery.alwaysUse24HourFormatOf(context)),
      formatDurationTextual(ends.difference(starts).inMilliseconds),
      if (failed) _localRecordingFailure(schedule.errorCode),
      if (missed) t.iptv.recordingMissed,
    ].join(' · ');
    final stateLabel = active
        ? t.iptv.recordingInProgressLocal
        : failed
        ? t.iptv.recordingInterrupted
        : missed
        ? t.iptv.recordingMissed
        : t.iptv.scheduledOnThisDevice;
    return FocusableWrapper(
      autofocus: autofocus,
      focusNode: focusNode,
      autoScroll: true,
      useBackgroundFocus: true,
      disableScale: true,
      semanticLabel: '${schedule.programmeTitle ?? schedule.title}, $stateLabel',
      onSelect: schedule.state == 'scheduled' ? onCancel : null,
      onNavigateUp: onNavigateUp,
      onBack: onBack,
      child: InkWell(
        canRequestFocus: false,
        onTap: schedule.state == 'scheduled' ? onCancel : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              AppIcon(
                active ? Symbols.fiber_manual_record_rounded : Symbols.event_rounded,
                color: active ? Colors.red : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.programmeTitle?.isNotEmpty == true ? schedule.programmeTitle! : schedule.title,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: tokens(context).textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              StatusPill(label: stateLabel, color: active ? Colors.red : failed ? theme.colorScheme.error : theme.colorScheme.primary),
              if (schedule.state == 'scheduled')
                IconButton(
                  tooltip: t.iptv.cancelSchedule,
                  onPressed: onCancel,
                  icon: const AppIcon(Symbols.close_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _localRecordingFailure(String? code) => switch (code) {
    'app_interrupted' => t.iptv.recordingAppClosed,
    'storage_low' => t.iptv.recordingStorageLow,
    'recording_encrypted_hls' => t.iptv.recordingEncryptedHls,
    'authentication' => t.iptv.recordingProviderAuthentication,
    'permission' => t.iptv.recordingProviderPermission,
    _ => t.iptv.recordingInterrupted,
  };
}

class _LocalIptvRecordingTile extends StatelessWidget {
  const _LocalIptvRecordingTile({
    required this.recording,
    required this.onPlay,
    required this.onDelete,
    required this.autofocus,
    this.focusNode,
    this.onNavigateUp,
    this.onBack,
  });

  final IptvLocalRecording recording;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecording = recording.isRecording;
    final isFailed = recording.state != 'complete' && !isRecording;
    final canPlay = recording.state == 'complete' || (isFailed && (recording.sizeBytes ?? 0) > 0);
    final started = recording.startedAt.toLocal();
    final subtitle = <String>[
      formatRelativeDayLabel(started),
      formatClockTime(started, is24Hour: MediaQuery.alwaysUse24HourFormatOf(context)),
      if (recording.sizeBytes case final size? when size > 0) ByteFormatter.formatBytes(size),
      if (isFailed) t.iptv.recordingInterrupted,
    ].join(' · ');
    return FocusableWrapper(
      autofocus: autofocus,
      focusNode: focusNode,
      autoScroll: true,
      useBackgroundFocus: true,
      disableScale: true,
      onSelect: canPlay ? onPlay : null,
      onNavigateUp: onNavigateUp,
      onBack: onBack,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            AppIcon(
              isRecording ? Symbols.fiber_manual_record_rounded : Symbols.video_file_rounded,
              color: isRecording ? Colors.red : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recording.programmeTitle?.isNotEmpty == true ? recording.programmeTitle! : recording.title,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: tokens(context).textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isRecording)
              StatusPill(label: t.iptv.recordingInProgressLocal, color: Colors.red)
            else
              IconButton(
                tooltip: t.iptv.play,
                onPressed: canPlay ? onPlay : null,
                icon: const AppIcon(Symbols.play_arrow_rounded),
              ),
            IconButton(
              tooltip: t.iptv.deleteRecording,
              onPressed: isRecording ? null : onDelete,
              icon: const AppIcon(Symbols.delete_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DispatcharrRecordingTile extends StatelessWidget {
  const _DispatcharrRecordingTile({required this.recording, required this.onTap});
  final IptvDispatcharrRecording recording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = recording.startedAt?.toLocal();
    return FocusableWrapper(
      autoScroll: true,
      useBackgroundFocus: true,
      disableScale: true,
      onSelect: onTap,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AppIcon(
                recording.isRecording ? Symbols.fiber_manual_record_rounded : Symbols.video_file_rounded,
                color: recording.isRecording ? Colors.red : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recording.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      [recording.sourceName, if (recording.channelName != null) recording.channelName!, if (when != null) formatClockTime(when, is24Hour: MediaQuery.alwaysUse24HourFormatOf(context)), recording.state],
                      style: theme.textTheme.bodySmall?.copyWith(color: tokens(context).textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: recording.isRecording ? t.iptv.recordingInProgressLocal : recording.state,
                color: recording.isRecording ? Colors.red : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const AppIcon(Symbols.more_horiz_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _DispatcharrRuleTile extends StatelessWidget {
  const _DispatcharrRuleTile({required this.rule, required this.onTap});
  final IptvDispatcharrRule rule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableWrapper(
      autoScroll: true,
      useBackgroundFocus: true,
      disableScale: true,
      onSelect: onTap,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AppIcon(Symbols.event_repeat_rounded, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Text(rule.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(rule.kind, style: theme.textTheme.bodySmall?.copyWith(color: tokens(context).textMuted)),
              const SizedBox(width: 8),
              const AppIcon(Symbols.more_horiz_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrabTile extends StatelessWidget {
  final _GrabEntry entry;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback onTap;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  const _GrabTile({
    required this.entry,
    required this.autofocus,
    this.focusNode,
    required this.onTap,
    this.onNavigateUp,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final program = entry.op.program;
    final status = entry.op.status ?? 'scheduled';
    final isRecording = status == 'grabbing';
    final isError = status == 'error';

    final title = program?.displayTitle ?? entry.op.key ?? '';
    final timeStr = _formatTime(program, MediaQuery.alwaysUse24HourFormatOf(context));
    final subtitle = [
      if (timeStr.isNotEmpty) timeStr,
      if (program?.channelCallSign != null && program!.channelCallSign!.isNotEmpty) program.channelCallSign!,
    ].join(' · ');

    return FocusableWrapper(
      autofocus: autofocus,
      focusNode: focusNode,
      autoScroll: true,
      useBackgroundFocus: true,
      disableScale: true,
      onSelect: onTap,
      onNavigateUp: onNavigateUp,
      onBack: onBack,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        child: Container(
          color: isRecording ? airingFill(context) : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: .w500),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: tokens(context).textMuted),
                        maxLines: 1,
                        overflow: .ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isRecording)
                StatusPill(label: t.liveTv.recordingInProgress, color: Colors.red)
              else if (isError)
                StatusPill(label: t.common.error, color: theme.colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(LiveTvProgram? program, bool is24Hour) {
    if (program == null) return '';
    final start = program.startTime;
    final end = program.endTime;
    if (start == null) return '';
    final clock = formatClockTime(start, is24Hour: is24Hour);
    final dayLabel = formatRelativeDayLabel(start);
    final duration = end != null ? formatDurationTextual(end.difference(start).inMilliseconds) : '';
    return [dayLabel, clock, if (duration.isNotEmpty) duration].join(' · ');
  }
}

class _RuleTile extends StatelessWidget {
  final _RuleEntry entry;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback onTap;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  const _RuleTile({
    required this.entry,
    required this.autofocus,
    this.focusNode,
    required this.onTap,
    this.onNavigateUp,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rule = entry.rule;
    final title = rule.title ?? '';
    final isSeries = rule.type == 2;
    final subtitleParts = <String>[
      if (isSeries) t.liveTv.recordSeries else t.liveTv.recordEpisode,
      if (rule.airingsType != null && rule.airingsType!.isNotEmpty) rule.airingsType!,
      if (rule.grabOperations.isNotEmpty) t.liveTv.recordingsCount(count: rule.grabOperations.length.toString()),
    ];

    return FocusableWrapper(
      autofocus: autofocus,
      focusNode: focusNode,
      autoScroll: true,
      useBackgroundFocus: true,
      disableScale: true,
      onSelect: onTap,
      onNavigateUp: onNavigateUp,
      onBack: onBack,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: .w500),
                maxLines: 1,
                overflow: .ellipsis,
              ),
              if (subtitleParts.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitleParts.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(color: tokens(context).textMuted),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
