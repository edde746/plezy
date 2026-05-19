import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../media/media_version.dart';
import 'app_logger.dart';

List<MediaVersion>? _nonEmptyVersions(List<MediaVersion>? versions) {
  return versions == null || versions.isEmpty ? null : versions;
}

/// Resolve media versions for item-level actions without making every browse
/// row carry heavy backend-specific media-source payloads.
Future<List<MediaVersion>> resolveMediaVersions(
  MediaItem metadata,
  MediaServerClient client, {
  List<MediaVersion>? fallbackVersions,
}) async {
  final inlineVersions = _nonEmptyVersions(metadata.mediaVersions);
  if (inlineVersions != null) return inlineVersions;

  final fallback = _nonEmptyVersions(fallbackVersions);
  if (fallback != null) return fallback;

  try {
    final fullMetadata = await client.fetchItem(metadata.id);
    return _nonEmptyVersions(fullMetadata?.mediaVersions) ?? const <MediaVersion>[];
  } catch (e, st) {
    appLogger.w(
      'Failed to resolve media versions for ${metadata.backend.id} item ${metadata.id}',
      error: e,
      stackTrace: st,
    );
    return const <MediaVersion>[];
  }
}
