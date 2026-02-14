import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_wrapper.dart';
import '../../focus/key_event_utils.dart';
import '../../i18n/strings.g.dart';
import '../../models/livetv_scheduled_recording.dart';
import '../../models/livetv_subscription.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/app_logger.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/desktop_app_bar.dart';

/// Screen for managing DVR recording subscriptions and scheduled recordings
class DvrRecordingsScreen extends StatefulWidget {
  const DvrRecordingsScreen({super.key});

  @override
  State<DvrRecordingsScreen> createState() => _DvrRecordingsScreenState();
}

class _DvrRecordingsScreenState extends State<DvrRecordingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<LiveTvSubscription> _subscriptions = [];
  List<ScheduledRecording> _scheduled = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final multiServer = context.read<MultiServerProvider>();
      final liveTvServers = multiServer.liveTvServers;

      if (liveTvServers.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = t.liveTv.noDvr;
        });
        return;
      }

      final allSubscriptions = <LiveTvSubscription>[];
      final allScheduled = <ScheduledRecording>[];

      for (final serverInfo in liveTvServers) {
        final client = multiServer.getClientForServer(serverInfo.serverId);
        if (client == null) continue;

        final subs = await client.getSubscriptions();
        allSubscriptions.addAll(subs);

        final scheduled = await client.getScheduledRecordings();
        allScheduled.addAll(scheduled);
      }

      // Sort scheduled by start time
      allScheduled.sort((a, b) => (a.beginsAt ?? 0).compareTo(b.beginsAt ?? 0));

      if (!mounted) return;
      setState(() {
        _subscriptions = allSubscriptions;
        _scheduled = allScheduled;
        _isLoading = false;
      });
    } catch (e) {
      appLogger.e('Failed to load DVR data', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _deleteSubscription(LiveTvSubscription subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.liveTv.deleteSubscription),
        content: Text(t.liveTv.deleteSubscriptionConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.common.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.common.delete)),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final multiServer = context.read<MultiServerProvider>();
    final client = subscription.serverId != null ? multiServer.getClientForServer(subscription.serverId!) : null;

    if (client != null) {
      final success = await client.deleteSubscription(subscription.key);
      if (success && mounted) {
        showSnackBar(context, t.liveTv.subscriptionDeleted);
        await _loadData();
      }
    }
  }

  Future<void> _editSubscription(LiveTvSubscription subscription) async {
    // Filter to visible settings only
    final editableSettings = subscription.settings.where((s) => s.hidden != true).toList();

    if (editableSettings.isEmpty) return;

    final prefs = <String, String>{};
    for (final setting in editableSettings) {
      prefs[setting.id] = setting.value ?? setting.defaultValue ?? '';
    }

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) =>
          _SubscriptionEditDialog(subscription: subscription, settings: editableSettings, initialPrefs: prefs),
    );

    if (result == null || !mounted) return;

    final multiServer = context.read<MultiServerProvider>();
    final client = subscription.serverId != null ? multiServer.getClientForServer(subscription.serverId!) : null;

    if (client != null) {
      final success = await client.editSubscription(subscription.key, result);
      if (success) {
        await _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => handleBackKeyNavigation(context, event),
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            CustomAppBar(
              title: Text(t.liveTv.recordings),
              pinned: true,
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: t.liveTv.subscriptions),
                  Tab(text: t.liveTv.scheduled),
                ],
              ),
            ),
          ],
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadData,
                        icon: const AppIcon(Symbols.refresh_rounded),
                        label: Text(t.common.retry),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [_buildSubscriptionsTab(theme), _buildScheduledTab(theme)],
                ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionsTab(ThemeData theme) {
    if (_subscriptions.isEmpty) {
      return Center(child: Text(t.liveTv.noSubscriptions));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _subscriptions.length,
      itemBuilder: (context, index) {
        final sub = _subscriptions[index];
        return FocusableWrapper(
          autofocus: index == 0,
          autoScroll: true,
          useComfortableZone: true,
          onSelect: () => _editSubscription(sub),
          onBack: () => Navigator.pop(context),
          child: _buildSubscriptionCard(sub, theme),
        );
      },
    );
  }

  Widget _buildSubscriptionCard(LiveTvSubscription subscription, ThemeData theme) {
    return ExcludeFocus(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: const AppIcon(Symbols.fiber_dvr_rounded, size: 32),
          title: Text(subscription.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: subscription.type != null
              ? Text(
                  subscription.type!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subscription.settings.isNotEmpty)
                IconButton(
                  icon: const AppIcon(Symbols.settings_rounded),
                  onPressed: () => _editSubscription(subscription),
                ),
              IconButton(
                icon: AppIcon(Symbols.delete_rounded, color: theme.colorScheme.error),
                onPressed: () => _deleteSubscription(subscription),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduledTab(ThemeData theme) {
    if (_scheduled.isEmpty) {
      return Center(child: Text(t.liveTv.noRecordings));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _scheduled.length,
      itemBuilder: (context, index) {
        final recording = _scheduled[index];
        return FocusableWrapper(
          autofocus: index == 0,
          autoScroll: true,
          useComfortableZone: true,
          onBack: () => Navigator.pop(context),
          child: _buildScheduledCard(recording, theme),
        );
      },
    );
  }

  Widget _buildScheduledCard(ScheduledRecording recording, ThemeData theme) {
    final startTime = recording.startTime;
    final timeStr = startTime != null
        ? '${startTime.month}/${startTime.day} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'
        : '';

    return ExcludeFocus(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: const AppIcon(Symbols.fiber_manual_record_rounded, size: 32, color: Colors.red),
          title: Text(recording.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              if (recording.channelCallSign != null) recording.channelCallSign!,
              timeStr,
              if (recording.durationMinutes > 0) formatDurationTextual(recording.durationMinutes * 60000),
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// Dialog for editing subscription settings
class _SubscriptionEditDialog extends StatefulWidget {
  final LiveTvSubscription subscription;
  final List<SubscriptionSetting> settings;
  final Map<String, String> initialPrefs;

  const _SubscriptionEditDialog({required this.subscription, required this.settings, required this.initialPrefs});

  @override
  State<_SubscriptionEditDialog> createState() => _SubscriptionEditDialogState();
}

class _SubscriptionEditDialogState extends State<_SubscriptionEditDialog> {
  late Map<String, String> _prefs;
  final Map<String, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _prefs = Map.from(widget.initialPrefs);
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.subscription.title),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.settings.map((setting) {
              return _buildSettingRow(setting);
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text(t.common.cancel)),
        FilledButton(onPressed: () => Navigator.of(context).pop(_prefs), child: Text(t.common.save)),
      ],
    );
  }

  Widget _buildSettingRow(SubscriptionSetting setting) {
    final value = _prefs[setting.id] ?? setting.defaultValue ?? '';

    if (setting.type == 'bool') {
      return SwitchListTile(
        title: Text(setting.label ?? setting.id),
        subtitle: setting.summary != null ? Text(setting.summary!) : null,
        value: value == '1' || value == 'true',
        onChanged: (newValue) {
          setState(() {
            _prefs[setting.id] = newValue ? '1' : '0';
          });
        },
      );
    }

    if (setting.type == 'enum' && setting.enumValues != null) {
      return ListTile(
        title: Text(setting.label ?? setting.id),
        subtitle: setting.summary != null ? Text(setting.summary!) : null,
        trailing: DropdownButton<String>(
          value: setting.enumValues!.any((e) => e.value == value) ? value : null,
          items: setting.enumValues!.map((option) {
            return DropdownMenuItem(value: option.value, child: Text(option.label));
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _prefs[setting.id] = newValue;
              });
            }
          },
        ),
      );
    }

    // Default: text field
    final controller = _textControllers.putIfAbsent(setting.id, () => TextEditingController(text: value));
    return ListTile(
      title: Text(setting.label ?? setting.id),
      subtitle: TextField(
        controller: controller,
        onChanged: (newValue) {
          _prefs[setting.id] = newValue;
        },
      ),
    );
  }
}
