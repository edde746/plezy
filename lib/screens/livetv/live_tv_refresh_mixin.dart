import 'dart:async';

import 'package:flutter/widgets.dart';

enum LiveTvRefreshLifecycleTransition { pause, resume, ignore }

LiveTvRefreshLifecycleTransition liveTvRefreshTransition(AppLifecycleState state) {
  return switch (state) {
    AppLifecycleState.paused || AppLifecycleState.hidden => LiveTvRefreshLifecycleTransition.pause,
    AppLifecycleState.resumed => LiveTvRefreshLifecycleTransition.resume,
    AppLifecycleState.inactive || AppLifecycleState.detached => LiveTvRefreshLifecycleTransition.ignore,
  };
}

/// What re-opened the refresh gates in [LiveTvRefreshMixin.onRefreshResumed].
enum LiveTvRefreshResumeReason { tabSelected, subtreeShown, appResumed }

/// Refresh gating shared by the Live TV tabs.
///
/// The periodic [onRefreshTick] runs only while all three gates hold:
/// - the tab is selected (the parent screen drives [pauseRefresh]/[resumeRefresh]),
/// - the subtree is visible (TickerMode: main-screen section switch, opaque route push/pop),
/// - the app is foregrounded ([liveTvRefreshTransition] of the [WidgetsBindingObserver] lifecycle stream).
///
/// [onRefreshPaused]/[onRefreshResumed] fire on gate edges so tabs can layer extra work (RecordingsTab
/// reload-on-select, GuideTab drift catch-up) on top of the timer without re-implementing the gating.
mixin LiveTvRefreshMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _refreshRequested = true;
  bool _tickerEnabled = true;
  bool _appRefreshActive = true;

  /// Interval between [onRefreshTick] calls while all gates hold.
  Duration get refreshInterval;

  /// Periodic refresh work.
  void onRefreshTick();

  /// A gate closed: tab deselected, subtree hidden, or app backgrounded.
  void onRefreshPaused() {}

  /// A gate re-opened while every other gate holds, so the refresh timer restarted.
  void onRefreshResumed(LiveTvRefreshResumeReason reason) {}

  /// Whether the surrounding subtree is visible (TickerMode enabled).
  bool get isRefreshSubtreeVisible => _tickerEnabled;

  bool get _gatesOpen => _refreshRequested && _tickerEnabled && _appRefreshActive && mounted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncRefreshTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribes to TickerMode, so this fires whenever the tab is shown or
    // hidden (main-screen IndexedStack section switch, opaque route push/pop).
    final enabled = TickerMode.valuesOf(context).enabled;
    if (enabled == _tickerEnabled) return;
    _tickerEnabled = enabled;
    _syncRefreshTimer();
    enabled ? _notifyResumed(LiveTvRefreshResumeReason.subtreeShown) : onRefreshPaused();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (liveTvRefreshTransition(state)) {
      case LiveTvRefreshLifecycleTransition.pause:
        if (!_appRefreshActive) return;
        _appRefreshActive = false;
        _syncRefreshTimer();
        onRefreshPaused();
      case LiveTvRefreshLifecycleTransition.resume:
        if (_appRefreshActive) return;
        _appRefreshActive = true;
        _syncRefreshTimer();
        _notifyResumed(LiveTvRefreshResumeReason.appResumed);
      case LiveTvRefreshLifecycleTransition.ignore:
        break;
    }
  }

  /// Parent screen deselected this tab.
  void pauseRefresh() {
    _refreshRequested = false;
    _syncRefreshTimer();
    onRefreshPaused();
  }

  /// Parent screen selected this tab.
  void resumeRefresh() {
    _refreshRequested = true;
    _syncRefreshTimer();
    _notifyResumed(LiveTvRefreshResumeReason.tabSelected);
  }

  void _notifyResumed(LiveTvRefreshResumeReason reason) {
    if (_gatesOpen) onRefreshResumed(reason);
  }

  void _syncRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (!_gatesOpen) return;
    _refreshTimer = Timer.periodic(refreshInterval, (_) => onRefreshTick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }
}
