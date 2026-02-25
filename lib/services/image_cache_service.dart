import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';

/// Custom cache manager for Plex image transcoding with connection limiting.
///
/// Limits concurrent HTTP connections to 6 per host (matching browser HTTP/1.1
/// behavior) to prevent overwhelming the Plex server's transcode pipeline when
/// many posters are visible simultaneously.
class PlexImageCacheManager extends CacheManager with ImageCacheManager {
  static const _key = 'plexImageCache';

  static final PlexImageCacheManager instance = PlexImageCacheManager._();

  PlexImageCacheManager._()
      : super(
          Config(
            _key,
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 5000,
            fileService: HttpFileService(
              httpClient: IOClient(
                HttpClient()..maxConnectionsPerHost = 6,
              ),
            ),
          ),
        );
}
