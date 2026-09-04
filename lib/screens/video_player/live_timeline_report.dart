import '../../media/live_tv_support.dart';

/// Sends one live-TV timeline report and commits what it learned only while
/// the dispatching session and scheduling generation still own the screen.
Future<void> runLiveTimelineReport({
  required LiveTvPlaybackSession requestSession,
  required int requestGeneration,
  required String state,
  required int positionMs,
  required LiveTvPlaybackSession? Function() currentSession,
  required int Function() currentGeneration,
  required bool Function() isMounted,
  required void Function(LiveTimelineUpdate update) commit,
}) async {
  final update = await requestSession.reportTimeline(
    state: state,
    positionMs: positionMs,
    durationMs: requestSession.program.durationMs ?? 0,
  );
  if (update == null ||
      state == 'stopped' ||
      !isMounted() ||
      currentGeneration() != requestGeneration ||
      !identical(currentSession(), requestSession)) {
    return;
  }
  commit(update);
}
