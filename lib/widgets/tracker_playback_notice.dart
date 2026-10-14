import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../providers/trackers_provider.dart';
import '../screens/settings/tracker_service_info.dart';
import '../services/trackers/tracker_constants.dart';
import 'video_controls/widgets/player_toast_indicator.dart';

/// A brief, non-interactive notice for newly lost logins during playback.
/// Existing warnings remain in the main banner; entering a video must not
/// replay them. The notice never pauses playback or takes keyboard/remote focus.
class TrackerPlaybackNotice extends StatefulWidget {
  const TrackerPlaybackNotice({super.key});

  @override
  State<TrackerPlaybackNotice> createState() => _TrackerPlaybackNoticeState();
}

class _TrackerPlaybackNoticeState extends State<TrackerPlaybackNotice> {
  final _toast = PlayerToastController();
  TrackersProvider? _provider;
  Set<TrackerService> _seen = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<TrackersProvider>();
    if (identical(provider, _provider)) return;
    _provider?.removeListener(_onChanged);
    _provider = provider;
    _seen = provider.reconnectRequiredServices.toSet();
    provider.addListener(_onChanged);
  }

  void _onChanged() {
    final current = _provider!.reconnectRequiredServices.toSet();
    final added = current.difference(_seen);
    _seen = current;
    if (added.isEmpty) return;
    // Provider hydration can notify during a frame. Defer UI work, and drop
    // a warning if the user already recovered before that frame completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final remaining = added.intersection(_provider!.reconnectRequiredServices.toSet());
      if (remaining.isEmpty) return;
      final text = remaining.length == 1
          ? t.services.reconnectWarning(
              service: TrackerServiceInfo.all.firstWhere((info) => info.service == remaining.single).displayName,
            )
          : t.services.reconnectWarningMany(count: remaining.length);
      _toast.show(Symbols.warning_rounded, text, duration: const Duration(seconds: 8));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _provider?.removeListener(_onChanged);
    _toast.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ListenableBuilder(
      listenable: _toast,
      builder: (context, _) {
        final notice = _toast.current;
        return notice == null
            ? const SizedBox.shrink()
            : SafeArea(
                child: PlayerToastIndicator(icon: notice.icon, text: notice.text),
              );
      },
    ),
  );
}
