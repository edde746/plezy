typedef LiveStreamRecovery<Session> = Future<Session?> Function();
typedef LiveStreamUrlLookup<Session> = Future<String?> Function(Session session);

enum LiveStreamRetryResult { succeeded, failed, stale }

/// Runs one live-stream recovery attempt while the caller remains current.
///
/// Every asynchronous stage is followed by a current-attempt check. Failures
/// from stale attempts are intentionally ignored because a newer operation
/// owns the player and its error UI.
Future<LiveStreamRetryResult> runLiveStreamRetry<Session>({
  required LiveStreamRecovery<Session> recover,
  required LiveStreamUrlLookup<Session> lookupStreamUrl,
  required Future<void> Function() applyPlayerOptions,
  required Future<void> Function(String streamUrl) open,
  required bool Function() isCurrent,
  required void Function(Session session) adoptSession,
  required void Function(Object error, StackTrace stackTrace) reportFailure,
  required void Function(Session session) discardSession,
  required void Function() onFinished,
}) async {
  Session? recovered;
  var adopted = false;
  try {
    recovered = await recover();
    if (!isCurrent()) return LiveStreamRetryResult.stale;
    if (recovered == null) throw StateError('Live stream recovery returned no session');

    final streamUrl = await lookupStreamUrl(recovered);
    if (!isCurrent()) return LiveStreamRetryResult.stale;
    if (streamUrl == null) throw StateError('Live stream recovery returned no URL');

    await applyPlayerOptions();
    if (!isCurrent()) return LiveStreamRetryResult.stale;

    await open(streamUrl);
    if (!isCurrent()) return LiveStreamRetryResult.stale;

    adoptSession(recovered);
    adopted = true;
    return LiveStreamRetryResult.succeeded;
  } catch (error, stackTrace) {
    if (!isCurrent()) return LiveStreamRetryResult.stale;
    reportFailure(error, stackTrace);
    return LiveStreamRetryResult.failed;
  } finally {
    if (recovered != null && !adopted) discardSession(recovered);
    onFinished();
  }
}
