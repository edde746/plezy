import 'package:drift/drift.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';

/// Seeds `downloaded_media` rows at an arbitrary [status] so tests can start
/// from completed, downloading, or paused state.
///
/// Production never writes rows this way — it goes through
/// `insertQueuedDownload`, which only ever admits `queued` rows and guards on
/// the existing status. This fixture deliberately keeps neither restriction,
/// which is why it lives in `test/` instead of `lib/`.
extension DownloadFixtures on AppDatabase {
  Future<void> insertDownload({
    required ServerId serverId,
    String? clientScopeId,
    required String ratingKey,
    required String globalKey,
    required String type,
    String? parentRatingKey,
    String? grandparentRatingKey,
    required int status,
    int mediaIndex = 0,
    String? mediaSourceId,
  }) async {
    await customUpdate(
      '''
      INSERT INTO downloaded_media (
        server_id,
        client_scope_id,
        rating_key,
        global_key,
        type,
        parent_rating_key,
        grandparent_rating_key,
        status,
        media_index,
        media_source_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(global_key) DO UPDATE SET
        server_id = excluded.server_id,
        client_scope_id = excluded.client_scope_id,
        rating_key = excluded.rating_key,
        type = excluded.type,
        parent_rating_key = excluded.parent_rating_key,
        grandparent_rating_key = excluded.grandparent_rating_key,
        status = excluded.status,
        progress = 0,
        total_bytes = NULL,
        downloaded_bytes = 0,
        error_message = NULL,
        retry_count = 0,
        media_index = excluded.media_index,
        media_source_id = excluded.media_source_id
      ''',
      variables: [
        Variable<String>(serverId),
        Variable<String>(clientScopeId),
        Variable<String>(ratingKey),
        Variable<String>(globalKey),
        Variable<String>(type),
        Variable<String>(parentRatingKey),
        Variable<String>(grandparentRatingKey),
        Variable<int>(status),
        Variable<int>(mediaIndex),
        Variable<String>(mediaSourceId),
      ],
      updates: {downloadedMedia},
    );
  }
}
