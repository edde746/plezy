/// Test fixtures for Plex API responses
/// These match the structure of real Plex API responses

class TestFixtures {
  /// Sample Plex server identity response
  static Map<String, dynamic> get serverIdentity => {
    'MediaContainer': {
      'size': 0,
      'machineIdentifier': 'abc123def456',
      'version': '1.32.0.6918',
    },
  };

  /// Sample library sections response
  static Map<String, dynamic> get librarySections => {
    'MediaContainer': {
      'size': 2,
      'Directory': [
        {
          'key': '1',
          'title': 'Movies',
          'type': 'movie',
          'agent': 'tv.plex.agents.movie',
          'scanner': 'Plex Movie',
          'language': 'en-US',
          'uuid': 'lib-uuid-1',
          'updatedAt': 1700000000,
          'scannedAt': 1700000000,
          'thumb': '/library/sections/1/composite/1700000000',
        },
        {
          'key': '2',
          'title': 'TV Shows',
          'type': 'show',
          'agent': 'tv.plex.agents.series',
          'scanner': 'Plex TV Series',
          'language': 'en-US',
          'uuid': 'lib-uuid-2',
          'updatedAt': 1700000000,
          'scannedAt': 1700000000,
          'thumb': '/library/sections/2/composite/1700000000',
        },
      ],
    },
  };

  /// Sample movie metadata response
  static Map<String, dynamic> get movieMetadata => {
    'MediaContainer': {
      'size': 1,
      'Metadata': [
        {
          'ratingKey': '12345',
          'key': '/library/metadata/12345',
          'guid': 'plex://movie/abc123',
          'type': 'movie',
          'title': 'Test Movie',
          'year': 2024,
          'summary': 'A test movie for unit testing.',
          'rating': 8.5,
          'audienceRating': 9.0,
          'duration': 7200000, // 2 hours in ms
          'addedAt': 1700000000,
          'updatedAt': 1700000000,
          'thumb': '/library/metadata/12345/thumb/1700000000',
          'art': '/library/metadata/12345/art/1700000000',
          'Media': [
            {
              'id': 1,
              'duration': 7200000,
              'bitrate': 8000,
              'width': 1920,
              'height': 1080,
              'aspectRatio': 1.78,
              'videoCodec': 'h264',
              'audioCodec': 'aac',
              'container': 'mkv',
              'Part': [
                {
                  'id': 1,
                  'key': '/library/parts/1/file.mkv',
                  'duration': 7200000,
                  'file': '/movies/Test Movie (2024)/Test Movie.mkv',
                  'size': 8000000000,
                  'container': 'mkv',
                },
              ],
            },
          ],
        },
      ],
    },
  };

  /// Sample TV show metadata response
  static Map<String, dynamic> get showMetadata => {
    'MediaContainer': {
      'size': 1,
      'Metadata': [
        {
          'ratingKey': '67890',
          'key': '/library/metadata/67890',
          'guid': 'plex://show/def456',
          'type': 'show',
          'title': 'Test Show',
          'year': 2023,
          'summary': 'A test TV show for unit testing.',
          'rating': 8.0,
          'leafCount': 10,
          'viewedLeafCount': 5,
          'childCount': 1,
          'addedAt': 1700000000,
          'updatedAt': 1700000000,
          'thumb': '/library/metadata/67890/thumb/1700000000',
          'art': '/library/metadata/67890/art/1700000000',
        },
      ],
    },
  };

  /// Sample episode metadata response
  static Map<String, dynamic> get episodeMetadata => {
    'MediaContainer': {
      'size': 1,
      'Metadata': [
        {
          'ratingKey': '11111',
          'key': '/library/metadata/11111',
          'guid': 'plex://episode/ghi789',
          'type': 'episode',
          'title': 'Pilot',
          'parentTitle': 'Season 1',
          'grandparentTitle': 'Test Show',
          'index': 1,
          'parentIndex': 1,
          'year': 2023,
          'summary': 'The first episode.',
          'duration': 2700000, // 45 min
          'addedAt': 1700000000,
          'updatedAt': 1700000000,
          'thumb': '/library/metadata/11111/thumb/1700000000',
          'Media': [
            {
              'id': 2,
              'duration': 2700000,
              'bitrate': 5000,
              'width': 1920,
              'height': 1080,
              'videoCodec': 'h264',
              'audioCodec': 'aac',
              'container': 'mkv',
              'Part': [
                {
                  'id': 2,
                  'key': '/library/parts/2/file.mkv',
                  'duration': 2700000,
                  'file': '/tv/Test Show/Season 1/S01E01.mkv',
                  'size': 2000000000,
                  'container': 'mkv',
                },
              ],
            },
          ],
        },
      ],
    },
  };

  /// Sample hub response (continue watching, recently added, etc.)
  static Map<String, dynamic> get hubsResponse => {
    'MediaContainer': {
      'size': 2,
      'Hub': [
        {
          'key': '/hubs/continueWatching',
          'title': 'Continue Watching',
          'type': 'mixed',
          'hubIdentifier': 'home.continue',
          'size': 1,
          'Metadata': [
            {
              'ratingKey': '12345',
              'type': 'movie',
              'title': 'Test Movie',
              'viewOffset': 3600000, // 1 hour watched
            },
          ],
        },
        {
          'key': '/hubs/recentlyAdded',
          'title': 'Recently Added',
          'type': 'mixed',
          'hubIdentifier': 'home.recentlyAdded',
          'size': 1,
          'Metadata': [
            {
              'ratingKey': '67890',
              'type': 'show',
              'title': 'Test Show',
            },
          ],
        },
      ],
    },
  };

  /// Sample PIN creation response
  static Map<String, dynamic> get pinResponse => {
    'id': 123456,
    'code': 'ABCD',
    'expiresAt': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
    'authToken': null,
    'clientIdentifier': 'test-client-id',
  };

  /// Sample PIN claimed response
  static Map<String, dynamic> get pinClaimedResponse => {
    'id': 123456,
    'code': 'ABCD',
    'authToken': 'test-auth-token-12345',
    'clientIdentifier': 'test-client-id',
  };

  /// Sample user info response
  static Map<String, dynamic> get userInfo => {
    'id': 12345678,
    'uuid': 'user-uuid-12345',
    'username': 'testuser',
    'email': 'test@example.com',
    'title': 'Test User',
    'thumb': 'https://plex.tv/users/testuser/avatar',
    'hasPassword': true,
    'authToken': 'test-auth-token-12345',
    'subscription': {
      'active': true,
      'status': 'Active',
      'plan': 'lifetime',
    },
  };

  /// Sample servers response
  static List<Map<String, dynamic>> get serversResponse => [
    {
      'name': 'Test Server',
      'product': 'Plex Media Server',
      'productVersion': '1.32.0.6918',
      'platform': 'Linux',
      'platformVersion': '6.1.0',
      'device': 'PC',
      'clientIdentifier': 'server-client-id',
      'createdAt': '2023-01-01T00:00:00Z',
      'lastSeenAt': '2024-01-01T00:00:00Z',
      'provides': 'server',
      'owned': true,
      'accessToken': 'server-access-token',
      'publicAddress': '192.168.1.100',
      'httpsRequired': false,
      'synced': false,
      'relay': false,
      'dnsRebindingProtection': false,
      'natLoopbackSupported': false,
      'publicAddressMatches': true,
      'presence': true,
      'Connection': [
        {
          'protocol': 'https',
          'address': '192.168.1.100',
          'port': 32400,
          'uri': 'https://192.168.1.100:32400',
          'local': true,
          'relay': false,
        },
        {
          'protocol': 'https',
          'address': 'server.plex.direct',
          'port': 32400,
          'uri': 'https://server.plex.direct:32400',
          'local': false,
          'relay': false,
        },
      ],
    },
  ];

  /// Sample Plex Home users response
  static Map<String, dynamic> get homeUsersResponse => {
    'id': 1,
    'name': 'Test Home',
    'guestUserID': 0,
    'guestUserUUID': '',
    'guestEnabled': false,
    'subscription': true,
    'users': [
      {
        'id': 12345678,
        'uuid': 'user-uuid-12345',
        'title': 'Test User',
        'username': 'testuser',
        'email': 'test@example.com',
        'thumb': 'https://plex.tv/users/testuser/avatar',
        'admin': true,
        'guest': false,
        'restricted': false,
        'protected': false,
        'home': true,
      },
      {
        'id': 87654321,
        'uuid': 'user-uuid-67890',
        'title': 'Family Member',
        'username': 'family',
        'email': 'family@example.com',
        'thumb': 'https://plex.tv/users/family/avatar',
        'admin': false,
        'guest': false,
        'restricted': false,
        'protected': true,
        'home': true,
      },
    ],
  };

  /// Sample user switch response
  static Map<String, dynamic> get userSwitchResponse => {
    'id': 87654321,
    'uuid': 'user-uuid-67890',
    'title': 'Family Member',
    'username': 'family',
    'authToken': 'switched-user-token-67890',
    'thumb': 'https://plex.tv/users/family/avatar',
  };

  /// Sample playlist response
  static Map<String, dynamic> get playlistResponse => {
    'MediaContainer': {
      'size': 1,
      'Metadata': [
        {
          'ratingKey': '99999',
          'key': '/playlists/99999/items',
          'guid': 'com.plexapp.agents.none://99999',
          'type': 'playlist',
          'title': 'My Playlist',
          'summary': 'A test playlist',
          'smart': false,
          'playlistType': 'video',
          'leafCount': 5,
          'addedAt': 1700000000,
          'updatedAt': 1700000000,
          'duration': 36000000, // 10 hours
        },
      ],
    },
  };

  /// Sample search results response
  static Map<String, dynamic> get searchResults => {
    'MediaContainer': {
      'size': 2,
      'Metadata': [
        {
          'ratingKey': '12345',
          'type': 'movie',
          'title': 'Test Movie',
          'year': 2024,
          'thumb': '/library/metadata/12345/thumb/1700000000',
        },
        {
          'ratingKey': '67890',
          'type': 'show',
          'title': 'Test Show',
          'year': 2023,
          'thumb': '/library/metadata/67890/thumb/1700000000',
        },
      ],
    },
  };

  /// Sample play queue response
  static Map<String, dynamic> get playQueueResponse => {
    'MediaContainer': {
      'size': 1,
      'playQueueID': 12345,
      'playQueueSelectedItemID': 12345,
      'playQueueSelectedItemOffset': 0,
      'playQueueSelectedMetadataItemID': '12345',
      'playQueueShuffled': false,
      'playQueueTotalCount': 1,
      'playQueueVersion': 1,
      'Metadata': [
        {
          'ratingKey': '12345',
          'key': '/library/metadata/12345',
          'type': 'movie',
          'title': 'Test Movie',
          'playQueueItemID': 12345,
        },
      ],
    },
  };
}
