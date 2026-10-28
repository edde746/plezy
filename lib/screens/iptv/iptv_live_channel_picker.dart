import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_wrapper.dart';
import '../../i18n/iptv_copy.dart';
import '../../i18n/strings.g.dart';
import '../../models/livetv_channel.dart';
import '../../utils/live_tv_grouping.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/bottom_sheet_header.dart';
import '../../widgets/optimized_media_image.dart';
import '../../widgets/overlay_sheet.dart';

/// A compact channel browser shared by remote, touch, and pointer input.
/// Selection returns the channel; the owning live session performs the tune
/// so player lifecycle, time-shift, and recovery remain in one place.
Future<LiveTvChannel?> showIptvLiveChannelPicker(
  BuildContext context, {
  required List<LiveTvChannel> channels,
  required LiveTvChannel? currentChannel,
  Map<String, int> recentChannelOrder = const {},
}) =>
    OverlaySheetController.showAdaptive<LiveTvChannel>(
      context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => IptvLiveChannelPickerSheet(
        channels: channels,
        currentChannelKey: currentChannel?.key,
        recentChannelOrder: recentChannelOrder,
      ),
    );

class IptvLiveChannelPickerSheet extends StatefulWidget {
  const IptvLiveChannelPickerSheet({super.key, required this.channels, this.currentChannelKey, this.recentChannelOrder = const {}});

  final List<LiveTvChannel> channels;
  final String? currentChannelKey;
  final Map<String, int> recentChannelOrder;

  @override
  State<IptvLiveChannelPickerSheet> createState() => _IptvLiveChannelPickerSheetState();
}

class _IptvLiveChannelPickerSheetState extends State<IptvLiveChannelPickerSheet> {
  final _search = TextEditingController();
  String _groupKey = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<({String key, String label})> get _groups {
    final groups = <String, String>{'all': t.iptv.allLiveChannels};
    if (widget.channels.any((channel) => channel.iptvFavorite)) {
      groups['favorites'] = t.liveTv.favorites;
    }
    if (widget.channels.any((channel) => widget.recentChannelOrder.containsKey(channel.key))) {
      groups['recent'] = t.iptv.recentChannels;
    }
    for (final source in groupLiveTvChannelsBySource(widget.channels)) {
      groups['source:${source.key}'] = source.label;
    }
    for (final channel in widget.channels) {
      final group = channel.iptvGroupTitle?.trim();
      if (group != null && group.isNotEmpty) groups.putIfAbsent('group:$group', () => group);
    }
    return [for (final entry in groups.entries) (key: entry.key, label: entry.value)];
  }

  List<LiveTvChannel> get _visibleChannels {
    Iterable<LiveTvChannel> filtered = widget.channels;
    if (_groupKey == 'favorites') {
      filtered = filtered.where((channel) => channel.iptvFavorite);
    } else if (_groupKey == 'recent') {
      filtered = filtered.where((channel) => widget.recentChannelOrder.containsKey(channel.key));
    } else if (_groupKey.startsWith('source:')) {
      final key = _groupKey.substring('source:'.length);
      filtered = filtered.where((channel) => liveTvChannelSourceKey(channel) == key);
    } else if (_groupKey.startsWith('group:')) {
      final group = _groupKey.substring('group:'.length);
      filtered = filtered.where((channel) => channel.iptvGroupTitle?.trim() == group);
    }
    final query = _search.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((channel) {
        final text = [
          channel.displayName,
          channel.number ?? '',
          channel.iptvGroupTitle ?? '',
          channel.liveTvSourceTitle ?? '',
        ].join(' ').toLowerCase();
        return text.contains(query);
      });
    }
    final result = filtered.toList(growable: false);
    if (_groupKey == 'recent') {
      result.sort((a, b) => (widget.recentChannelOrder[b.key] ?? 0).compareTo(widget.recentChannelOrder[a.key] ?? 0));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleChannels;
    final colors = Theme.of(context).colorScheme;
    final groups = _groups;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Column(
          children: [
            BottomSheetHeader(title: t.iptv.liveChannelPicker, icon: Symbols.live_tv_rounded),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: t.iptv.searchLiveChannels,
                      prefixIcon: const AppIcon(Symbols.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: t.common.clear,
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const AppIcon(Symbols.close_rounded),
                            ),
                    ),
                  ),
                  if (groups.length > 1) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _groups.any((group) => group.key == _groupKey) ? _groupKey : 'all',
                      decoration: InputDecoration(
                        labelText: t.iptv.channelGroup,
                        prefixIcon: const AppIcon(Symbols.filter_list_rounded),
                      ),
                      items: [
                        for (final group in groups)
                          DropdownMenuItem(value: group.key, child: Text(group.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (value) => setState(() => _groupKey = value ?? 'all'),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(t.iptv.noLiveChannelResults, textAlign: TextAlign.center),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final channel = visible[index];
                        final selected = channel.key == widget.currentChannelKey;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: FocusableWrapper(
                            borderRadius: 12,
                            semanticLabel: channel.iptvParentalLocked
                                ? '${channel.displayName}, ${t.iptv.parentalLockedLabel}'
                                : channel.displayName,
                            onSelect: () => Navigator.of(context).pop(channel),
                            child: Material(
                              color: selected ? colors.secondaryContainer : colors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                leading: SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: channel.thumb == null
                                      ? Center(child: AppIcon(Symbols.live_tv_rounded, color: colors.onSurfaceVariant))
                                      : OptimizedMediaImage.thumb(
                                          imagePath: channel.thumb,
                                          width: 42,
                                          height: 42,
                                          fit: BoxFit.contain,
                                          fallbackIcon: Symbols.live_tv_rounded,
                                        ),
                                ),
                                title: Text(
                                  [if (channel.number != null) channel.number!, channel.displayName].join('  ·  '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  [
                                    if (channel.iptvGroupTitle?.isNotEmpty == true) channel.iptvGroupTitle!,
                                    if (channel.liveTvSourceTitle?.isNotEmpty == true) channel.liveTvSourceTitle!,
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: selected
                                    ? const AppIcon(Symbols.equalizer_rounded, fill: 1)
                                    : channel.iptvParentalLocked
                                    ? const AppIcon(Symbols.lock_rounded)
                                    : channel.iptvFavorite
                                    ? const AppIcon(Symbols.star_rounded, fill: 1)
                                    : null,
                                onTap: () => Navigator.of(context).pop(channel),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
