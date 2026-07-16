import '../../utils/app_logger.dart';
import 'tracker.dart';
import 'tracker_session.dart';

/// Fetches a username with a short-lived client and keeps [session] unchanged
/// when enrichment fails or the service has no username.
Future<TrackerSession> enrichTrackerSessionUsername<T extends DisposableTrackerClient>({
  required TrackerSession session,
  required String failureMessage,
  required T Function() createClient,
  required Future<String?> Function(T client) fetchUsername,
}) async {
  T? client;
  try {
    client = createClient();
    final username = await fetchUsername(client);
    return username == null ? session : session.copyWith(username: username);
  } catch (error) {
    appLogger.d(failureMessage, error: error);
    return session;
  } finally {
    client?.dispose();
  }
}
