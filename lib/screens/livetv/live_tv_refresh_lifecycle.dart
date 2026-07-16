import 'package:flutter/widgets.dart';

enum LiveTvRefreshLifecycleTransition { pause, resume, ignore }

LiveTvRefreshLifecycleTransition liveTvRefreshTransition(AppLifecycleState state) {
  return switch (state) {
    AppLifecycleState.paused || AppLifecycleState.hidden => LiveTvRefreshLifecycleTransition.pause,
    AppLifecycleState.resumed => LiveTvRefreshLifecycleTransition.resume,
    AppLifecycleState.inactive || AppLifecycleState.detached => LiveTvRefreshLifecycleTransition.ignore,
  };
}
