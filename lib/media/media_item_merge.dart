import 'ids.dart';
import 'media_item.dart';

/// Merge freshly fetched metadata with identity and library context already
/// known by the caller. The fetched item owns descriptive fields, while
/// existing context wins when the backend omits it.
MediaItem mergeFetchedMediaItem({required MediaItem fetched, required ServerId fallbackServerId, MediaItem? existing}) {
  return fetched.copyWith(
    serverId: existing?.serverId ?? fetched.serverId ?? fallbackServerId,
    serverName: existing?.serverName ?? fetched.serverName,
    libraryId: fetched.libraryId ?? existing?.libraryId,
    libraryTitle: fetched.libraryTitle ?? existing?.libraryTitle,
  );
}
