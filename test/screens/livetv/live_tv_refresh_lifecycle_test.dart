import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/livetv/live_tv_refresh_lifecycle.dart';

void main() {
  test('desktop inactive state leaves Live TV refresh timers running', () {
    expect(liveTvRefreshTransition(AppLifecycleState.inactive), LiveTvRefreshLifecycleTransition.ignore);
    expect(liveTvRefreshTransition(AppLifecycleState.detached), LiveTvRefreshLifecycleTransition.ignore);
  });

  test('only actual background states pause and resumed restarts', () {
    expect(liveTvRefreshTransition(AppLifecycleState.hidden), LiveTvRefreshLifecycleTransition.pause);
    expect(liveTvRefreshTransition(AppLifecycleState.paused), LiveTvRefreshLifecycleTransition.pause);
    expect(liveTvRefreshTransition(AppLifecycleState.resumed), LiveTvRefreshLifecycleTransition.resume);
  });
}
