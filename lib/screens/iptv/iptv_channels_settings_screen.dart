import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/iptv_copy.dart';
import '../../i18n/strings.g.dart';
import '../../iptv/iptv_models.dart';
import '../../iptv/iptv_source_repository.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_activation.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/optimized_media_image.dart';

class IptvChannelsSettingsScreen extends StatefulWidget {
  const IptvChannelsSettingsScreen({super.key, required this.profileId, required this.sourceId});

  final String? profileId;
  final String sourceId;

  @override
  State<IptvChannelsSettingsScreen> createState() => _IptvChannelsSettingsScreenState();
}

class _IptvChannelsSettingsScreenState extends State<IptvChannelsSettingsScreen> {
  final _search = TextEditingController();
  List<IptvEditableChannel> _channels = const [];
  Set<String> _lockedGroups = const {};
  bool _loading = true;
  String? _savingChannelId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final profileId = widget.profileId;
    if (profileId == null) {
      setState(() {
        _channels = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final repository = context.read<IptvSourceRepository>();
      final channels = await repository.editableChannels(profileId, widget.sourceId);
      final lockedGroups = await repository.lockedGroups(profileId, widget.sourceId);
      if (mounted) setState(() {
        _channels = channels;
        _lockedGroups = lockedGroups;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        showErrorSnackBar(context, t.iptv.providerUnavailable);
      }
    }
  }

  List<IptvEditableChannel> get _filteredChannels {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _channels;
    return [
      for (final channel in _channels)
        if ('${channel.displayTitle} ${channel.displayGroup ?? ''} ${channel.number ?? ''}'.toLowerCase().contains(query))
          channel,
    ];
  }

  Future<void> _save(
    IptvEditableChannel channel, {
    required bool hidden,
    required String? title,
    required String? group,
    required String? guideId,
    required bool parentalLocked,
    bool? groupLocked,
    String? groupLockTitle,
  }) async {
    final profileId = widget.profileId;
    if (profileId == null || _savingChannelId != null) return;
    setState(() => _savingChannelId = channel.id);
    try {
      final repository = context.read<IptvSourceRepository>();
      await repository.saveChannelPresentation(
        profileId: profileId,
        sourceId: widget.sourceId,
        channelId: channel.id,
        hidden: hidden,
        customTitle: title,
        groupOverride: group,
        guideIdOverride: guideId,
        parentalLocked: parentalLocked,
      );
      final groupTitle = groupLockTitle?.trim();
      if (groupLocked != null && groupTitle != null && groupTitle.isNotEmpty) {
        await repository.saveGroupLock(
          profileId: profileId,
          sourceId: widget.sourceId,
          groupTitle: groupTitle,
          locked: groupLocked,
        );
      }
      final oldGuideId = channel.guideIdOverride?.trim() ?? '';
      final newGuideId = guideId?.trim() ?? '';
      if (oldGuideId != newGuideId) {
        try {
          await repository.refresh(profileId, widget.sourceId);
        } on Object {
          if (mounted) showErrorSnackBar(context, t.iptv.guideMappingRefreshFailed);
        }
      }
      await _load();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, t.iptv.sourceInvalid);
    } finally {
      if (mounted) setState(() => _savingChannelId = null);
    }
  }

  Future<void> _edit(IptvEditableChannel channel) async {
    final title = TextEditingController(text: channel.customTitle ?? '');
    final group = TextEditingController(text: channel.groupOverride ?? '');
    final guideId = TextEditingController(text: channel.guideIdOverride ?? '');
    var hidden = channel.hidden;
    var parentalLocked = channel.parentalLocked;
    String? effectiveGroupTitle() {
      final custom = group.text.trim();
      final title = custom.isNotEmpty ? custom : channel.groupTitle?.trim();
      return title == null || title.isEmpty ? null : title;
    }
    var groupLocked = _lockedGroups.contains(iptvGroupLockKey(effectiveGroupTitle()));
    final activeProfile = context.read<ActiveProfileProvider>().active;
    final canUseParentalControls = activeProfile is LocalProfile &&
        activeProfile.id == widget.profileId &&
        activeProfile.isPinProtected;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(channel.displayTitle),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: InputDecoration(labelText: t.iptv.customChannelName, helperText: t.iptv.useProviderName),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: group,
                  onChanged: (_) => setDialogState(
                    () => groupLocked = _lockedGroups.contains(iptvGroupLockKey(effectiveGroupTitle())),
                  ),
                  decoration: InputDecoration(labelText: t.iptv.customGroupName, helperText: t.iptv.useProviderName),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: guideId,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: t.iptv.epgChannelId,
                    hintText: channel.tvgId,
                    helperText: t.iptv.epgChannelIdHelp,
                    prefixIcon: const AppIcon(Symbols.link_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.iptv.hideFromGuide),
                  value: hidden,
                  onChanged: (value) => setDialogState(() => hidden = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: const AppIcon(Symbols.lock_rounded),
                  title: Text(t.iptv.lockChannel),
                  value: parentalLocked,
                  onChanged: !canUseParentalControls && !parentalLocked
                      ? null
                      : (value) async {
                          if (value && !canUseParentalControls) return;
                          if (canUseParentalControls &&
                              !await requestActiveProfileActionPin(context)) return;
                          if (!context.mounted) return;
                          setDialogState(() => parentalLocked = value);
                        },
                ),
                if (effectiveGroupTitle() != null)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: const AppIcon(Symbols.folder_rounded),
                    title: Text(t.iptv.lockChannelGroup),
                    subtitle: Text(effectiveGroupTitle()!),
                    value: groupLocked,
                    onChanged: !canUseParentalControls && !groupLocked
                        ? null
                        : (value) async {
                            if (value && !canUseParentalControls) return;
                            if (canUseParentalControls &&
                                !await requestActiveProfileActionPin(context)) return;
                            if (!context.mounted) return;
                            setDialogState(() => groupLocked = value);
                          },
                  ),
                if (!canUseParentalControls)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(t.iptv.parentalPinRequired, style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.common.cancel)),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.common.save)),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      await _save(
        channel,
        hidden: hidden,
        title: title.text,
        group: group.text,
        guideId: guideId.text,
        parentalLocked: parentalLocked,
        groupLocked: effectiveGroupTitle() == null ? null : groupLocked,
        groupLockTitle: effectiveGroupTitle(),
      );
    }
    title.dispose();
    group.dispose();
    guideId.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final channels = _filteredChannels;
    return FocusedScrollScaffold(
      title: Text(t.iptv.manageChannels),
      actions: [
        IconButton(
          tooltip: t.iptv.refresh,
          onPressed: _loading ? null : _load,
          icon: const AppIcon(Symbols.refresh_rounded, fill: 1),
        ),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: t.iptv.searchChannels,
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
          ),
        ),
        if (_loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_channels.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(t.iptv.noChannels, textAlign: TextAlign.center),
              ),
            ),
          )
        else if (channels.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(t.search.tryDifferentTerm)),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final channel = channels[index];
                final trailing = index + 1 < channels.length ? tokens(context).groupGap : 0.0;
                return Padding(
                  padding: EdgeInsets.only(bottom: trailing),
                  child: Material(
                    color: tokens(context).surface,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: groupItemRadii(context, index, channels.length)),
                    child: ListTileTheme.merge(
                      visualDensity: PlatformDetector.isAutomotive() ? VisualDensity.standard : const VisualDensity(vertical: -3),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text(channel.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            if (channel.parentalLocked || _lockedGroups.contains(iptvGroupLockKey(channel.displayGroup)))
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: AppIcon(Symbols.lock_rounded, size: 16, color: colors.onSurfaceVariant),
                              ),
                          ],
                        ),
                        leading: SizedBox(
                          width: 40,
                          height: 40,
                          child: channel.logoUrl == null
                              ? Center(child: AppIcon(Symbols.live_tv_rounded, fill: 1, color: colors.onSurfaceVariant))
                              : OptimizedMediaImage.thumb(
                                  imagePath: channel.logoUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                  fallbackIcon: Symbols.live_tv_rounded,
                                ),
                        ),
                        subtitle: Text(
                          [if (channel.number != null) channel.number!, if (channel.displayGroup != null) channel.displayGroup!].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: _savingChannelId == null ? () => _edit(channel) : null,
                        trailing: Switch.adaptive(
                          value: !channel.hidden,
                          onChanged: _savingChannelId == channel.id
                              ? null
                              : (visible) => _save(
                                  channel,
                                  hidden: !visible,
                                  title: channel.customTitle,
                                  group: channel.groupOverride,
                                  guideId: channel.guideIdOverride,
                                  parentalLocked: channel.parentalLocked,
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: channels.length),
            ),
          ),
      ],
    );
  }
}
