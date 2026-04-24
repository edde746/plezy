import '../../utils/app_logger.dart';

/// Shared "authorize → enrich → save → assign" pipeline.
///
/// Callers manage the in-flight flag + `notifyListeners` around this call;
/// this helper only owns the inner steps so `TrackersProvider` and
/// `TraktAccountProvider` can't drift. Returns `true` only on a fully applied
/// session — null-from-authorize (cancel/denied/expired) and any exception
/// both surface as `false`.
Future<bool> runConnectPipeline<T>({
  required String logLabel,
  required Future<T?> Function() authorize,
  required Future<T> Function(T raw) enrich,
  required Future<void> Function(T enriched) save,
  required void Function(T enriched) assign,
}) async {
  try {
    final raw = await authorize();
    if (raw == null) return false;
    final enriched = await enrich(raw);
    await save(enriched);
    assign(enriched);
    return true;
  } catch (e) {
    appLogger.w('$logLabel connect failed', error: e);
    return false;
  }
}
