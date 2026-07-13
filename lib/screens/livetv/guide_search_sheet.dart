import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_text_field.dart';
import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../media/ids.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/companion_remote/companion_remote_receiver.dart';
import '../../utils/app_logger.dart';
import '../../utils/formatters.dart';
import '../../utils/live_tv_matching.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/bottom_sheet_header.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/optimized_media_image.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/pill_input_decoration.dart';

/// Search sheet for the Live TV guide: filters channels and the next 24 hours
/// of programs in memory; selecting a result jumps to it in the guide grid.
class GuideSearchSheet extends StatefulWidget {
  final List<LiveTvChannel> channels;
  final void Function(LiveTvChannel channel) onChannelSelected;
  final void Function(LiveTvChannel channel, LiveTvProgram program) onProgramSelected;

  const GuideSearchSheet({
    super.key,
    required this.channels,
    required this.onChannelSelected,
    required this.onProgramSelected,
  });

  @override
  State<GuideSearchSheet> createState() => _GuideSearchSheetState();
}

class _GuideSearchSheetState extends State<GuideSearchSheet> with ControllerDisposerMixin {
  static const _scheduleWindow = Duration(hours: 24);
  static const _maxProgramResults = 30;
  static const _minProgramQueryLength = 2;

  late final _searchController = createTextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'GuideSearch_input');
  final _firstResultFocusNode = FocusNode(debugLabel: 'GuideSearch_firstResult');
  final _tvTextInputController = TvTextInputController();

  List<({LiveTvProgram program, LiveTvChannel channel})> _allPrograms = const [];
  bool _isLoadingPrograms = true;

  String _query = '';
  List<LiveTvChannel> _channelResults = const [];
  List<({LiveTvProgram program, LiveTvChannel channel})> _programResults = const [];

  void Function(String? query)? _savedOnSearchAction;

  @override
  void initState() {
    super.initState();
    _channelResults = widget.channels;

    // While the sheet is open, companion-remote search queries land here
    // instead of the global Search tab (save/restore idiom, see the video
    // player's companion remote overrides).
    final receiver = CompanionRemoteReceiver.instance;
    _savedOnSearchAction = receiver.onSearchAction;
    receiver.onSearchAction = _handleRemoteQuery;

    unawaited(_loadPrograms());
  }

  @override
  void dispose() {
    CompanionRemoteReceiver.instance.onSearchAction = _savedOnSearchAction;
    _savedOnSearchAction = null;
    _searchFocusNode.dispose();
    _firstResultFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    final multiServer = context.read<MultiServerProvider>();
    final now = DateTime.now().toUtc();
    // Jellyfin maps `from` to minStartDate, which would exclude programs that
    // started before the sheet opened; look back an hour to keep the current
    // airing searchable (same idiom as the show-schedule screen).
    final from = now.subtract(const Duration(hours: 1));
    final to = now.add(_scheduleWindow);
    final fetched = <LiveTvProgram>[];
    final queriedServers = <String>{};

    for (final serverInfo in multiServer.liveTvServers) {
      if (!queriedServers.add(serverInfo.serverId)) continue;
      try {
        final client = multiServer.getClientForServer(ServerId(serverInfo.serverId));
        if (client == null) continue;
        fetched.addAll(await client.liveTv.fetchSchedule(from: from, to: to));
      } catch (e) {
        appLogger.e('Guide search: failed to load programs from server ${serverInfo.serverId}', error: e);
      }
    }

    if (!mounted) return;

    // Resolve each program's channel once so per-keystroke filtering never
    // pays the programs × channels matching cost. The lookback window can
    // return programs that already finished — drop those.
    final nowEpoch = now.millisecondsSinceEpoch ~/ 1000;
    final resolved = <({LiveTvProgram program, LiveTvChannel channel})>[];
    for (final program in fetched) {
      final endsAt = program.endsAt;
      if (endsAt != null && endsAt <= nowEpoch) continue;
      for (final channel in widget.channels) {
        if (liveTvProgramMatchesChannel(program, channel)) {
          resolved.add((program: program, channel: channel));
          break;
        }
      }
    }
    resolved.sort((a, b) => (a.program.beginsAt ?? 0).compareTo(b.program.beginsAt ?? 0));

    setState(() {
      _allPrograms = resolved;
      _isLoadingPrograms = false;
      _recomputeResults();
    });
  }

  void _applyFilter(String query) {
    setState(() {
      _query = query.trim();
      _recomputeResults();
    });
  }

  void _recomputeResults() {
    final lower = _query.toLowerCase();
    if (lower.isEmpty) {
      _channelResults = widget.channels;
      _programResults = const [];
      return;
    }

    _channelResults = widget.channels.where((channel) {
      return (channel.title?.toLowerCase().contains(lower) ?? false) ||
          (channel.callSign?.toLowerCase().contains(lower) ?? false) ||
          (channel.number?.toLowerCase().contains(lower) ?? false);
    }).toList();

    _programResults = lower.length < _minProgramQueryLength
        ? const []
        : _allPrograms
              .where(
                (entry) =>
                    entry.program.title.toLowerCase().contains(lower) ||
                    (entry.program.grandparentTitle?.toLowerCase().contains(lower) ?? false),
              )
              .take(_maxProgramResults)
              .toList();
  }

  bool get _hasAnyResult => _channelResults.isNotEmpty || _programResults.isNotEmpty;

  void _focusFirstResult() {
    if (_hasAnyResult) _firstResultFocusNode.requestFocus();
  }

  void _focusFirstResultAfterSubmit() {
    if (!InputModeTracker.isKeyboardMode(context)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusFirstResult();
    });
  }

  /// Apply a complete query submitted from the companion remote: set the text,
  /// dismiss any open on-screen keyboard, and land focus on the results. A
  /// programmatic controller write does not fire onChanged, so filter directly.
  void _handleRemoteQuery(String? query) {
    if (!mounted) return;
    final trimmed = query?.trim() ?? '';
    _searchController.text = trimmed;
    _applyFilter(trimmed);
    _tvTextInputController.closeTextInput();
    if (trimmed.isEmpty) return;
    _tvTextInputController.focusInputWithoutOpening();
    _focusFirstResultAfterSubmit();
  }

  void _selectChannel(LiveTvChannel channel) {
    OverlaySheetController.popAdaptive(context);
    widget.onChannelSelected(channel);
  }

  void _selectProgram(({LiveTvProgram program, LiveTvChannel channel}) entry) {
    OverlaySheetController.popAdaptive(context);
    widget.onProgramSelected(entry.channel, entry.program);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        BottomSheetHeader(title: t.liveTv.searchGuide, icon: Symbols.search_rounded),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FocusableTextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            tvTextInputController: _tvTextInputController,
            textInputAction: TextInputAction.search,
            decoration: pillInputDecoration(
              context,
              hintText: t.liveTv.searchHint,
              prefixIcon: const Icon(Symbols.search_rounded, size: 20),
            ),
            onChanged: _applyFilter,
            onSubmitted: (_) => _focusFirstResultAfterSubmit(),
            onSelect: _focusFirstResultAfterSubmit,
            onNavigateDown: _hasAnyResult ? _focusFirstResult : null,
          ),
        ),
        Expanded(child: _buildResults(context)),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    final showPrograms = _query.length >= _minProgramQueryLength;
    if (!_hasAnyResult && !(showPrograms && _isLoadingPrograms)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t.liveTv.searchNoResults(query: _query)),
        ),
      );
    }

    final children = <Widget>[
      if (_channelResults.isNotEmpty) ...[
        _buildSectionHeader(context, t.liveTv.channelsSection),
        for (var i = 0; i < _channelResults.length; i++) _buildChannelTile(_channelResults[i], firstResult: i == 0),
      ],
      if (showPrograms && (_programResults.isNotEmpty || _isLoadingPrograms)) ...[
        _buildSectionHeader(context, t.liveTv.programsSection),
        if (_isLoadingPrograms)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else
          for (var i = 0; i < _programResults.length; i++)
            _buildProgramTile(_programResults[i], firstResult: _channelResults.isEmpty && i == 0),
      ],
    ];

    return ListView(padding: const EdgeInsets.only(bottom: 8), children: children);
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildChannelTile(LiveTvChannel channel, {required bool firstResult}) {
    final multiServer = context.read<MultiServerProvider>();
    final serverId = serverIdOrNull(channel.serverId);
    final client = serverId == null ? null : multiServer.getClientForServer(serverId);

    return FocusableListTile(
      focusNode: firstResult ? _firstResultFocusNode : null,
      leading: SizedBox(
        width: 40,
        height: 40,
        child: channel.thumb != null && client != null
            ? OptimizedMediaImage.thumb(client: client, imagePath: channel.thumb, width: 40, height: 40, fit: .contain)
            : Center(
                child: AppIcon(Symbols.live_tv_rounded, fill: 1, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
      ),
      title: Text(channel.displayName, maxLines: 1, overflow: .ellipsis),
      subtitle: channel.number != null
          ? Text(t.liveTv.channelNumber(number: channel.number!), maxLines: 1, overflow: .ellipsis)
          : null,
      onTap: () => _selectChannel(channel),
    );
  }

  Widget _buildProgramTile(({LiveTvProgram program, LiveTvChannel channel}) entry, {required bool firstResult}) {
    final start = entry.program.startTime;
    final airTime = start == null
        ? null
        : '${formatRelativeDayLabel(start)} ${formatClockTime(start, is24Hour: MediaQuery.alwaysUse24HourFormatOf(context))}';

    return FocusableListTile(
      focusNode: firstResult ? _firstResultFocusNode : null,
      leading: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: AppIcon(Symbols.schedule_rounded, fill: 1, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      title: Text(entry.program.displayTitle, maxLines: 1, overflow: .ellipsis),
      subtitle: Text(toBulletedString([entry.channel.displayName, ?airTime]), maxLines: 1, overflow: .ellipsis),
      onTap: () => _selectProgram(entry),
    );
  }
}
