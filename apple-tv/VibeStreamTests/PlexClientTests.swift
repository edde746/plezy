import XCTest
@testable import VibeStream

final class PlexClientTests: XCTestCase {

    // MARK: - PlexMetadata Decoding

    func testPlexMetadataDecoding() throws {
        let json = """
        {
            "ratingKey": "12345",
            "key": "/library/metadata/12345",
            "type": "movie",
            "title": "Test Movie",
            "year": 2024,
            "duration": 7200000,
            "viewCount": 1,
            "rating": 8.5,
            "contentRating": "PG-13",
            "studio": "Test Studio",
            "summary": "A test movie summary"
        }
        """.data(using: .utf8)!

        let metadata = try JSONDecoder().decode(PlexMetadata.self, from: json)

        XCTAssertEqual(metadata.ratingKey, "12345")
        XCTAssertEqual(metadata.title, "Test Movie")
        XCTAssertEqual(metadata.type, "movie")
        XCTAssertEqual(metadata.year, 2024)
        XCTAssertEqual(metadata.duration, 7200000)
        XCTAssertEqual(metadata.mediaType, .movie)
        XCTAssertTrue(metadata.isWatched)
        XCTAssertEqual(metadata.durationFormatted, "2h 0m")
    }

    func testPlexMetadataEpisodeDisplay() throws {
        let json = """
        {
            "ratingKey": "100",
            "key": "/library/metadata/100",
            "type": "episode",
            "title": "Pilot",
            "grandparentTitle": "Breaking Bad",
            "parentIndex": 1,
            "index": 1
        }
        """.data(using: .utf8)!

        let metadata = try JSONDecoder().decode(PlexMetadata.self, from: json)

        XCTAssertEqual(metadata.displayTitle, "Breaking Bad")
        XCTAssertEqual(metadata.displaySubtitle, "S1E1 - Pilot")
        XCTAssertTrue(metadata.mediaType.isVideo)
        XCTAssertTrue(metadata.mediaType.isShowRelated)
        XCTAssertTrue(metadata.usesWideAspectRatio)
    }

    func testPlexMetadataWatchProgress() throws {
        let json = """
        {
            "ratingKey": "200",
            "key": "/library/metadata/200",
            "type": "movie",
            "title": "In Progress",
            "duration": 7200000,
            "viewOffset": 3600000
        }
        """.data(using: .utf8)!

        let metadata = try JSONDecoder().decode(PlexMetadata.self, from: json)

        XCTAssertEqual(metadata.watchProgress, 0.5)
        XCTAssertFalse(metadata.isWatched)
    }

    func testPlexMetadataGlobalKey() throws {
        let json = """
        {
            "ratingKey": "123",
            "key": "/library/metadata/123",
            "type": "movie",
            "title": "Test"
        }
        """.data(using: .utf8)!

        var metadata = try JSONDecoder().decode(PlexMetadata.self, from: json)
        XCTAssertEqual(metadata.globalKey, "123")

        metadata.serverId = "server1"
        XCTAssertEqual(metadata.globalKey, "server1:123")
    }

    func testPlexMetadataMinimalFields() throws {
        let json = """
        {
            "ratingKey": "1",
            "key": "/library/metadata/1",
            "type": "movie",
            "title": "Minimal"
        }
        """.data(using: .utf8)!

        let metadata = try JSONDecoder().decode(PlexMetadata.self, from: json)

        XCTAssertEqual(metadata.ratingKey, "1")
        XCTAssertNil(metadata.year)
        XCTAssertNil(metadata.duration)
        XCTAssertNil(metadata.viewCount)
        XCTAssertNil(metadata.summary)
        XCTAssertNil(metadata.rating)
        XCTAssertNil(metadata.watchProgress)
        XCTAssertNil(metadata.durationFormatted)
        XCTAssertFalse(metadata.isWatched)
    }

    func testPlexMetadataWatchProgressEdgeCases() throws {
        // viewOffset = 0 should return nil (not started)
        let json1 = """
        {"ratingKey":"1","key":"/library/metadata/1","type":"movie","title":"T","duration":100000,"viewOffset":0}
        """.data(using: .utf8)!
        let m1 = try JSONDecoder().decode(PlexMetadata.self, from: json1)
        XCTAssertNil(m1.watchProgress)

        // viewOffset = duration should return nil (completed)
        let json2 = """
        {"ratingKey":"2","key":"/library/metadata/2","type":"movie","title":"T","duration":100000,"viewOffset":100000}
        """.data(using: .utf8)!
        let m2 = try JSONDecoder().decode(PlexMetadata.self, from: json2)
        XCTAssertNil(m2.watchProgress)

        // No duration should return nil
        let json3 = """
        {"ratingKey":"3","key":"/library/metadata/3","type":"movie","title":"T","viewOffset":50000}
        """.data(using: .utf8)!
        let m3 = try JSONDecoder().decode(PlexMetadata.self, from: json3)
        XCTAssertNil(m3.watchProgress)
    }

    func testPlexMetadataSeasonDisplay() throws {
        let json = """
        {
            "ratingKey": "300",
            "key": "/library/metadata/300",
            "type": "season",
            "title": "Season 2",
            "grandparentTitle": "The Office",
            "parentIndex": 2,
            "leafCount": 22,
            "viewedLeafCount": 10
        }
        """.data(using: .utf8)!

        let metadata = try JSONDecoder().decode(PlexMetadata.self, from: json)

        XCTAssertEqual(metadata.displayTitle, "The Office")
        XCTAssertEqual(metadata.displaySubtitle, "Season 2")
        XCTAssertFalse(metadata.isWatched)
        XCTAssertEqual(metadata.unwatchedCount, 12)
        XCTAssertFalse(metadata.usesWideAspectRatio)
    }

    func testPlexMetadataSeasonFullyWatched() throws {
        let json = """
        {
            "ratingKey": "301",
            "key": "/library/metadata/301",
            "type": "season",
            "title": "Season 1",
            "grandparentTitle": "Friends",
            "leafCount": 24,
            "viewedLeafCount": 24
        }
        """.data(using: .utf8)!

        let metadata = try JSONDecoder().decode(PlexMetadata.self, from: json)
        XCTAssertTrue(metadata.isWatched)
        XCTAssertNil(metadata.unwatchedCount)
    }

    func testPlexMetadataShowIsWatched() throws {
        let json = """
        {
            "ratingKey": "400",
            "key": "/library/metadata/400",
            "type": "show",
            "title": "Completed Show",
            "leafCount": 50,
            "viewedLeafCount": 50
        }
        """.data(using: .utf8)!

        let metadata = try JSONDecoder().decode(PlexMetadata.self, from: json)
        XCTAssertTrue(metadata.isWatched)
        XCTAssertTrue(metadata.mediaType.isShowRelated)
        XCTAssertFalse(metadata.mediaType.isPlayable)
    }

    func testPlexMetadataEpisodeWithoutGrandparent() throws {
        let json = """
        {
            "ratingKey": "101",
            "key": "/library/metadata/101",
            "type": "episode",
            "title": "Orphan Episode"
        }
        """.data(using: .utf8)!

        let metadata = try JSONDecoder().decode(PlexMetadata.self, from: json)
        // Without grandparentTitle, displayTitle falls back to title
        XCTAssertEqual(metadata.displayTitle, "Orphan Episode")
        // Without parentIndex/index, displaySubtitle is just the title
        XCTAssertEqual(metadata.displaySubtitle, "Orphan Episode")
    }

    func testPlexMetadataMovieDisplaySubtitle() throws {
        let json = """
        {
            "ratingKey": "500",
            "key": "/library/metadata/500",
            "type": "movie",
            "title": "Inception"
        }
        """.data(using: .utf8)!

        let metadata = try JSONDecoder().decode(PlexMetadata.self, from: json)
        XCTAssertEqual(metadata.displayTitle, "Inception")
        XCTAssertNil(metadata.displaySubtitle)
    }

    func testPlexMetadataPosterThumbModes() {
        let episode = PlexMetadata(
            ratingKey: "1", key: "/m/1", type: "episode", title: "Ep",
            thumb: "/ep-thumb", grandparentThumb: "/show-thumb"
        )
        XCTAssertEqual(episode.posterThumb(mode: .showPoster), "/show-thumb")
        XCTAssertEqual(episode.posterThumb(mode: .episodeThumb), "/ep-thumb")

        let season = PlexMetadata(
            ratingKey: "2", key: "/m/2", type: "season", title: "S1",
            thumb: "/season-thumb", parentThumb: "/show-thumb"
        )
        XCTAssertEqual(season.posterThumb(), "/season-thumb")

        let seasonNoThumb = PlexMetadata(
            ratingKey: "3", key: "/m/3", type: "season", title: "S1",
            parentThumb: "/show-thumb"
        )
        XCTAssertEqual(seasonNoThumb.posterThumb(), "/show-thumb")

        let movie = PlexMetadata(
            ratingKey: "4", key: "/m/4", type: "movie", title: "Movie",
            thumb: "/movie-thumb"
        )
        XCTAssertEqual(movie.posterThumb(), "/movie-thumb")
    }

    func testPlexMetadataEquality() {
        let m1 = PlexMetadata(ratingKey: "1", key: "/m/1", type: "movie", title: "A", serverId: "s1")
        let m2 = PlexMetadata(ratingKey: "1", key: "/m/1", type: "movie", title: "B", serverId: "s1")
        let m3 = PlexMetadata(ratingKey: "1", key: "/m/1", type: "movie", title: "A", serverId: "s2")
        let m4 = PlexMetadata(ratingKey: "2", key: "/m/2", type: "movie", title: "A", serverId: "s1")

        // Same ratingKey + serverId = equal (title doesn't matter)
        XCTAssertEqual(m1, m2)
        // Different serverId = not equal
        XCTAssertNotEqual(m1, m3)
        // Different ratingKey = not equal
        XCTAssertNotEqual(m1, m4)
    }

    func testExtractTmdbId() {
        let guids: [[String: Any]] = [
            ["id": "imdb://tt1234567"],
            ["id": "tmdb://12345"],
            ["id": "tvdb://67890"]
        ]
        XCTAssertEqual(PlexMetadata.extractTmdbId(from: guids), "12345")

        let noTmdb: [[String: Any]] = [
            ["id": "imdb://tt1234567"]
        ]
        XCTAssertNil(PlexMetadata.extractTmdbId(from: noTmdb))

        XCTAssertNil(PlexMetadata.extractTmdbId(from: []))
    }

    func testPlexMetadataDurationFormatted() {
        let m1 = PlexMetadata(ratingKey: "1", key: "/m/1", type: "movie", title: "T", duration: 7200000)
        XCTAssertEqual(m1.durationFormatted, "2h 0m")

        let m2 = PlexMetadata(ratingKey: "2", key: "/m/2", type: "movie", title: "T", duration: 5400000)
        XCTAssertEqual(m2.durationFormatted, "1h 30m")

        let m3 = PlexMetadata(ratingKey: "3", key: "/m/3", type: "movie", title: "T", duration: 1800000)
        XCTAssertEqual(m3.durationFormatted, "30m")

        let m4 = PlexMetadata(ratingKey: "4", key: "/m/4", type: "movie", title: "T", duration: 60000)
        XCTAssertEqual(m4.durationFormatted, "1m")
    }

    // MARK: - PlexMediaType

    func testPlexMediaType() {
        XCTAssertTrue(PlexMediaType.movie.isVideo)
        XCTAssertTrue(PlexMediaType.episode.isVideo)
        XCTAssertTrue(PlexMediaType.clip.isVideo)
        XCTAssertFalse(PlexMediaType.show.isVideo)
        XCTAssertFalse(PlexMediaType.season.isVideo)
        XCTAssertTrue(PlexMediaType.show.isShowRelated)
        XCTAssertTrue(PlexMediaType.season.isShowRelated)
        XCTAssertTrue(PlexMediaType.episode.isShowRelated)
        XCTAssertFalse(PlexMediaType.movie.isShowRelated)
        XCTAssertTrue(PlexMediaType.artist.isMusic)
        XCTAssertTrue(PlexMediaType.album.isMusic)
        XCTAssertTrue(PlexMediaType.track.isMusic)
        XCTAssertFalse(PlexMediaType.movie.isMusic)
        XCTAssertTrue(PlexMediaType.movie.isPlayable)
        XCTAssertTrue(PlexMediaType.episode.isPlayable)
        XCTAssertTrue(PlexMediaType.track.isPlayable)
        XCTAssertFalse(PlexMediaType.show.isPlayable)
        XCTAssertFalse(PlexMediaType.season.isPlayable)
        XCTAssertFalse(PlexMediaType.collection.isPlayable)
    }

    func testPlexMediaTypeFromString() {
        XCTAssertEqual(PlexMediaType(from: "movie"), .movie)
        XCTAssertEqual(PlexMediaType(from: "episode"), .episode)
        XCTAssertEqual(PlexMediaType(from: "show"), .show)
        XCTAssertEqual(PlexMediaType(from: "season"), .season)
        XCTAssertEqual(PlexMediaType(from: "artist"), .artist)
        XCTAssertEqual(PlexMediaType(from: "garbage"), .unknown)
        XCTAssertEqual(PlexMediaType(from: nil), .unknown)
        XCTAssertEqual(PlexMediaType(from: ""), .unknown)
    }

    // MARK: - PlexLibrary

    func testPlexLibraryDecoding() throws {
        let json = """
        {
            "key": "1",
            "title": "Movies",
            "type": "movie",
            "agent": "tv.plex.agents.movie",
            "scanner": "Plex Movie"
        }
        """.data(using: .utf8)!

        let library = try JSONDecoder().decode(PlexLibrary.self, from: json)

        XCTAssertEqual(library.key, "1")
        XCTAssertEqual(library.title, "Movies")
        XCTAssertEqual(library.type, "movie")
        XCTAssertEqual(library.mediaType, .movie)
    }

    // MARK: - PlexRole

    func testPlexRoleDecoding() throws {
        let json = """
        {
            "tag": "Bryan Cranston",
            "role": "Walter White",
            "thumb": "https://image.tmdb.org/t/p/w200/..."
        }
        """.data(using: .utf8)!

        let role = try JSONDecoder().decode(PlexRole.self, from: json)

        XCTAssertEqual(role.displayName, "Bryan Cranston")
        XCTAssertEqual(role.displayRole, "Walter White")
    }

    // MARK: - PlexServer & PlexConnection

    func testPlexServerBaseURL() {
        let server = PlexServer(
            name: "My Server",
            clientIdentifier: "abc123",
            connections: [
                PlexConnection(uri: "https://local.server:32400", protocol: "https", address: "192.168.1.100", port: 32400, local: true, relay: false)
            ],
            activeConnectionUri: nil,
            owned: true,
            sourceTitle: nil,
            accessToken: "token",
            machineIdentifier: "machine1"
        )
        XCTAssertEqual(server.baseURL, "https://local.server:32400")
        XCTAssertEqual(server.id, "abc123")
    }

    func testPlexServerActiveConnectionOverride() {
        let server = PlexServer(
            name: "My Server",
            clientIdentifier: "abc",
            connections: [
                PlexConnection(uri: "https://local:32400", protocol: "https", address: "192.168.1.1", port: 32400, local: true, relay: false)
            ],
            activeConnectionUri: "https://relay.plex.direct:32400",
            owned: true,
            sourceTitle: nil,
            accessToken: nil,
            machineIdentifier: nil
        )
        XCTAssertEqual(server.baseURL, "https://relay.plex.direct:32400")
    }

    func testPlexServerEmptyConnections() {
        let server = PlexServer(
            name: "Empty",
            clientIdentifier: "xyz",
            connections: [],
            activeConnectionUri: nil,
            owned: nil,
            sourceTitle: nil,
            accessToken: nil,
            machineIdentifier: nil
        )
        XCTAssertEqual(server.baseURL, "")
    }

    func testPlexConnectionIsSecure() {
        let https = PlexConnection(uri: "https://server:32400", protocol: "https", address: nil, port: nil, local: nil, relay: nil)
        XCTAssertTrue(https.isSecure)

        let http = PlexConnection(uri: "http://server:32400", protocol: "http", address: nil, port: nil, local: nil, relay: nil)
        XCTAssertFalse(http.isSecure)

        let httpsUri = PlexConnection(uri: "https://server:32400", protocol: nil, address: nil, port: nil, local: nil, relay: nil)
        XCTAssertTrue(httpsUri.isSecure)
    }

    // MARK: - PlexUser

    func testPlexUserDecoding() throws {
        let json = """
        {
            "id": 42,
            "uuid": "uuid-123",
            "username": "testuser",
            "title": "Test User",
            "email": "test@example.com",
            "admin": true
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(PlexUser.self, from: json)
        XCTAssertEqual(user.id, 42)
        XCTAssertEqual(user.displayName, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
    }

    func testPlexUserDisplayNameFallback() throws {
        let json = """
        {"id": 1, "title": "", "username": "fallback_user"}
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(PlexUser.self, from: json)
        XCTAssertEqual(user.displayName, "fallback_user")
    }

    func testPlexUserNoDisplayName() throws {
        let json = """
        {"id": 1, "title": ""}
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(PlexUser.self, from: json)
        XCTAssertEqual(user.displayName, "User")
    }

    func testPlexHomeUserDecoding() throws {
        let json = """
        {
            "id": 10,
            "uuid": "home-uuid",
            "title": "Kid",
            "username": "kid_user",
            "hasPassword": false,
            "restricted": true,
            "admin": false,
            "protected": false
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(PlexHomeUser.self, from: json)
        XCTAssertEqual(user.displayName, "Kid")
        XCTAssertEqual(user.restricted, true)
        XCTAssertEqual(user.hasPassword, false)
    }

    // MARK: - PlexPlaylist

    func testPlexPlaylistDecoding() throws {
        let json = """
        {
            "ratingKey": "500",
            "key": "/playlists/500",
            "type": "playlist",
            "title": "My Playlist",
            "playlistType": "video",
            "smart": false,
            "leafCount": 10,
            "composite": "/composite-image"
        }
        """.data(using: .utf8)!

        let playlist = try JSONDecoder().decode(PlexPlaylist.self, from: json)
        XCTAssertEqual(playlist.ratingKey, "500")
        XCTAssertEqual(playlist.displayTitle, "My Playlist")
        XCTAssertEqual(playlist.displayImage, "/composite-image")
        XCTAssertTrue(playlist.isEditable)
        XCTAssertEqual(playlist.globalKey, "500")
    }

    func testPlexPlaylistSmartNotEditable() throws {
        let json = """
        {
            "ratingKey": "501",
            "key": "/playlists/501",
            "type": "playlist",
            "title": "Auto Playlist",
            "playlistType": "video",
            "smart": true
        }
        """.data(using: .utf8)!

        let playlist = try JSONDecoder().decode(PlexPlaylist.self, from: json)
        XCTAssertFalse(playlist.isEditable)
    }

    func testPlexPlaylistGlobalKey() throws {
        let json = """
        {
            "ratingKey": "600",
            "key": "/playlists/600",
            "type": "playlist",
            "title": "T",
            "playlistType": "video",
            "smart": false,
            "serverId": "srv1"
        }
        """.data(using: .utf8)!

        let playlist = try JSONDecoder().decode(PlexPlaylist.self, from: json)
        XCTAssertEqual(playlist.globalKey, "srv1:600")
    }

    func testPlexPlaylistDisplayImageFallback() throws {
        let json = """
        {
            "ratingKey": "601",
            "key": "/playlists/601",
            "type": "playlist",
            "title": "T",
            "playlistType": "video",
            "smart": false,
            "thumb": "/thumb-image"
        }
        """.data(using: .utf8)!

        let playlist = try JSONDecoder().decode(PlexPlaylist.self, from: json)
        XCTAssertEqual(playlist.displayImage, "/thumb-image")
    }

    // MARK: - PlexFileInfo

    func testFileInfoResolution() {
        var info = PlexFileInfo()

        info.width = 3840
        XCTAssertTrue(info.is4K)
        XCTAssertFalse(info.isHD)
        XCTAssertFalse(info.isSD)

        info.width = 1920
        XCTAssertFalse(info.is4K)
        XCTAssertTrue(info.isHD)
        XCTAssertFalse(info.isSD)

        info.width = 1280
        XCTAssertFalse(info.is4K)
        XCTAssertTrue(info.isHD)

        info.width = 640
        XCTAssertFalse(info.is4K)
        XCTAssertFalse(info.isHD)
        XCTAssertTrue(info.isSD)
    }

    func testFileInfoResolutionFromString() {
        var info = PlexFileInfo()
        info.videoResolution = "4k"
        XCTAssertTrue(info.is4K)

        info = PlexFileInfo()
        info.videoResolution = "1080"
        XCTAssertTrue(info.isHD)

        info = PlexFileInfo()
        info.videoResolution = "720"
        XCTAssertTrue(info.isHD)
    }

    func testFileInfoHDR() {
        var info = PlexFileInfo()

        info.doviPresent = true
        XCTAssertTrue(info.isDolbyVision)
        XCTAssertFalse(info.isHDR10)
        XCTAssertFalse(info.isHLG)

        info = PlexFileInfo()
        info.colorTrc = "smpte2084"
        XCTAssertFalse(info.isDolbyVision)
        XCTAssertTrue(info.isHDR10)
        XCTAssertFalse(info.isHLG)

        info = PlexFileInfo()
        info.colorTrc = "arib-std-b67"
        XCTAssertFalse(info.isDolbyVision)
        XCTAssertFalse(info.isHDR10)
        XCTAssertTrue(info.isHLG)
    }

    func testFileInfoHDRViaBT2020() {
        var info = PlexFileInfo()
        info.colorSpace = "bt2020nc"
        XCTAssertTrue(info.isHDR10)
    }

    func testFileInfoHDRViaVideoProfile() {
        var info = PlexFileInfo()
        info.videoProfile = "DOVI/bl/el/rpu"
        XCTAssertTrue(info.isDolbyVision)
    }

    func testFileInfoSDR() {
        let info = PlexFileInfo()
        XCTAssertFalse(info.isDolbyVision)
        XCTAssertFalse(info.isHDR10)
        XCTAssertFalse(info.isHLG)
    }

    func testFileInfoAudio() {
        var info = PlexFileInfo()

        info.audioChannels = 8
        XCTAssertTrue(info.is71)
        XCTAssertFalse(info.is51)

        info.audioChannels = 6
        XCTAssertFalse(info.is71)
        XCTAssertTrue(info.is51)

        info.audioChannels = 2
        XCTAssertFalse(info.is71)
        XCTAssertFalse(info.is51)

        info.hasDolbyAtmos = true
        XCTAssertTrue(info.isDolbyAtmos)
    }

    func testFileInfoAtmosViaDisplayTitle() {
        var info = PlexFileInfo()
        info.audioExtendedDisplayTitle = "English (TrueHD 7.1 Atmos)"
        XCTAssertTrue(info.isDolbyAtmos)
    }

    func testFileInfoAtmosViaTrueHDHeuristic() {
        var info = PlexFileInfo()
        info.audioCodec = "truehd"
        info.audioChannels = 8
        info.audioProfile = nil
        XCTAssertTrue(info.isDolbyAtmos, "TrueHD 7.1+ without profile should be detected as Atmos")

        info.audioProfile = ""
        XCTAssertTrue(info.isDolbyAtmos, "TrueHD 7.1+ with empty profile should be detected as Atmos")

        // Heuristic should NOT apply when profile is explicitly set
        info.audioProfile = "truehd"
        XCTAssertFalse(info.isDolbyAtmos, "TrueHD with explicit profile should not trigger Atmos heuristic")
    }

    func testFileInfoAtmosHeuristicDoesNotApplyBelow71() {
        var info = PlexFileInfo()
        info.audioCodec = "truehd"
        info.audioChannels = 6
        info.audioProfile = nil
        XCTAssertFalse(info.isDolbyAtmos, "TrueHD 5.1 should not trigger Atmos heuristic")
    }

    func testFileInfoFormatted() {
        var info = PlexFileInfo()
        info.bitrate = 25000
        XCTAssertEqual(info.bitrateFormatted, "25.0 Mbps")

        info.bitrate = 500
        XCTAssertEqual(info.bitrateFormatted, "500 kbps")

        info.width = 3840
        info.height = 2160
        XCTAssertEqual(info.resolutionFormatted, "3840x2160")

        info.frameRate = 23.976
        XCTAssertEqual(info.frameRateFormatted, "23.976 fps")

        info.duration = 7200000
        XCTAssertEqual(info.durationFormatted, "2:00:00")

        info.duration = 90000
        XCTAssertEqual(info.durationFormatted, "1:30")
    }

    func testFileInfoAudioChannelsFormatted() {
        var info = PlexFileInfo()

        info.audioChannels = 8
        XCTAssertEqual(info.audioChannelsFormatted, "7.1")

        info.audioChannels = 6
        XCTAssertEqual(info.audioChannelsFormatted, "5.1")

        info.audioChannels = 2
        XCTAssertEqual(info.audioChannelsFormatted, "Stereo")

        info.audioChannels = 1
        XCTAssertEqual(info.audioChannelsFormatted, "Mono")

        info.audioChannels = 4
        XCTAssertEqual(info.audioChannelsFormatted, "4 ch")
    }

    func testFileInfoFormattedNils() {
        let info = PlexFileInfo()
        XCTAssertNil(info.bitrateFormatted)
        XCTAssertNil(info.resolutionFormatted)
        XCTAssertNil(info.durationFormatted)
        XCTAssertNil(info.fileSizeFormatted)
        XCTAssertNil(info.audioChannelsFormatted)
    }

    func testFileInfoFrameRateFallback() {
        var info = PlexFileInfo()
        info.videoFrameRate = "24p"
        XCTAssertEqual(info.frameRateFormatted, "24p")

        // Numeric frameRate takes priority
        info.frameRate = 23.976
        XCTAssertEqual(info.frameRateFormatted, "23.976 fps")
    }

    func testFileInfoFromJSON() {
        let json: [String: Any] = [
            "MediaContainer": [
                "Metadata": [[
                    "Media": [[
                        "container": "mkv",
                        "videoCodec": "hevc",
                        "videoResolution": "4k",
                        "width": 3840,
                        "height": 2160,
                        "bitrate": 30000,
                        "duration": 7200000,
                        "audioChannels": 8,
                        "audioCodec": "truehd",
                        "Part": [[
                            "file": "/movies/test.mkv",
                            "size": 50000000000,
                            "Stream": [
                                ["streamType": 1, "colorTrc": "smpte2084", "DOVIPresent": true, "bitDepth": 10],
                                ["streamType": 2, "displayTitle": "English", "extendedDisplayTitle": "English (TrueHD 7.1 Atmos)"],
                                ["streamType": 3, "displayTitle": "English SDH", "codec": "srt"]
                            ]
                        ]]
                    ]]
                ]]
            ]
        ]

        let info = PlexFileInfo.from(json: json)
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.container, "mkv")
        XCTAssertEqual(info?.videoCodec, "hevc")
        XCTAssertTrue(info?.is4K ?? false)
        XCTAssertTrue(info?.isDolbyVision ?? false)
        XCTAssertTrue(info?.isDolbyAtmos ?? false)
        XCTAssertTrue(info?.is71 ?? false)
        XCTAssertTrue(info?.hasSDH ?? false)
        XCTAssertEqual(info?.filePath, "/movies/test.mkv")
        XCTAssertEqual(info?.bitDepth, 10)
    }

    func testFileInfoFromInvalidJSON() {
        let info = PlexFileInfo.from(json: [:])
        XCTAssertNil(info)

        let noMedia = PlexFileInfo.from(json: ["MediaContainer": ["Metadata": [["noMedia": true]]]])
        XCTAssertNil(noMedia)
    }

    // MARK: - PlexSort

    func testPlexSortKey() {
        let sort = PlexSort(key: "titleSort", title: "Title", descKey: "titleSort:desc", defaultDirection: "asc")

        XCTAssertEqual(sort.sortKey(descending: false), "titleSort")
        XCTAssertEqual(sort.sortKey(descending: true), "titleSort:desc")
        XCTAssertFalse(sort.isDefaultDescending)
    }

    func testPlexSortDescDefault() {
        let sort = PlexSort(key: "addedAt", title: "Date Added", descKey: "addedAt:desc", defaultDirection: "desc")
        XCTAssertTrue(sort.isDefaultDescending)
    }

    func testPlexSortNoDescKey() {
        let sort = PlexSort(key: "titleSort", title: "Title", descKey: nil, defaultDirection: "asc")
        XCTAssertEqual(sort.sortKey(descending: false), "titleSort")
        XCTAssertEqual(sort.sortKey(descending: true), "titleSort:desc")
    }

    // MARK: - SyncMessage

    func testSyncMessageEncoding() throws {
        let message = SyncMessage.play(position: 5000, peerId: "test-peer")
        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["t"] as? String, "play")
        XCTAssertEqual(json?["pos"] as? Int, 5000)
        XCTAssertEqual(json?["pid"] as? String, "test-peer")
        XCTAssertNotNil(json?["ts"])
    }

    func testSyncMessageDecoding() throws {
        let json = """
        {"t":"seek","ts":1613046000000,"pos":120000,"pid":"user-123"}
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(SyncMessage.self, from: json)

        XCTAssertEqual(message.type, .seek)
        XCTAssertEqual(message.positionMs, 120000)
        XCTAssertEqual(message.peerId, "user-123")
    }

    func testSyncMessageSessionConfig() throws {
        let message = SyncMessage.sessionConfig(
            peerId: "host",
            position: 60000,
            isPlaying: true,
            playbackRate: 1.0,
            controlMode: .hostOnly
        )

        XCTAssertEqual(message.type, .sessionConfig)
        XCTAssertEqual(message.positionMs, 60000)
        XCTAssertEqual(message.bufferingState, false)
        XCTAssertEqual(message.rate, 1.0)
        XCTAssertEqual(message.controlMode, 0)
    }

    func testSyncMessagePause() throws {
        let message = SyncMessage.pause(peerId: "user1")
        XCTAssertEqual(message.type, .pause)
        XCTAssertEqual(message.peerId, "user1")
        XCTAssertNil(message.positionMs)
    }

    func testSyncMessageSeek() {
        let message = SyncMessage.seek(position: 90000, peerId: "p1")
        XCTAssertEqual(message.type, .seek)
        XCTAssertEqual(message.positionMs, 90000)
    }

    func testSyncMessageBuffering() {
        let message = SyncMessage.buffering(state: true, peerId: "p1")
        XCTAssertEqual(message.type, .buffering)
        XCTAssertEqual(message.bufferingState, true)
    }

    func testSyncMessagePositionSync() {
        let message = SyncMessage.positionSync(position: 45000, isPlaying: true, peerId: "p1")
        XCTAssertEqual(message.type, .positionSync)
        XCTAssertEqual(message.positionMs, 45000)
        XCTAssertEqual(message.isPlaying, true)
    }

    func testSyncMessageJoin() {
        let message = SyncMessage.join(peerId: "peer1", displayName: "Alice", isHost: true)
        XCTAssertEqual(message.type, .join)
        XCTAssertEqual(message.displayName, "Alice")
        XCTAssertEqual(message.isHost, true)
    }

    func testSyncMessageLeave() {
        let message = SyncMessage.leave(peerId: "peer1")
        XCTAssertEqual(message.type, .leave)
        XCTAssertEqual(message.peerId, "peer1")
    }

    func testSyncMessageMediaSwitch() {
        let message = SyncMessage.mediaSwitch(ratingKey: "123", serverId: "srv1", title: "Movie", peerId: "host")
        XCTAssertEqual(message.type, .mediaSwitch)
        XCTAssertEqual(message.ratingKey, "123")
        XCTAssertEqual(message.serverId, "srv1")
        XCTAssertEqual(message.mediaTitle, "Movie")
    }

    func testSyncMessageHostExitedPlayer() {
        let message = SyncMessage.hostExitedPlayer(peerId: "host")
        XCTAssertEqual(message.type, .hostExitedPlayer)
    }

    func testSyncMessagePlayerReady() {
        let message = SyncMessage.playerReady(ready: true, peerId: "p1")
        XCTAssertEqual(message.type, .playerReady)
        XCTAssertEqual(message.bufferingState, true)
    }

    func testSyncMessagePingPong() {
        let ping = SyncMessage.ping(id: 42, peerId: "p1")
        XCTAssertEqual(ping.type, .ping)
        XCTAssertEqual(ping.pingId, 42)

        let pong = SyncMessage.pong(id: 42, peerId: "p1")
        XCTAssertEqual(pong.type, .pong)
        XCTAssertEqual(pong.pingId, 42)
    }

    func testSyncMessageRoundTrip() throws {
        let original = SyncMessage.seek(position: 123456, peerId: "roundtrip-peer")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SyncMessage.self, from: data)

        XCTAssertEqual(decoded.type, .seek)
        XCTAssertEqual(decoded.positionMs, 123456)
        XCTAssertEqual(decoded.peerId, "roundtrip-peer")
        XCTAssertEqual(decoded.timestamp, original.timestamp)
    }

    func testSyncMessageCompactKeys() throws {
        let message = SyncMessage.play(position: 1000, peerId: "peer")
        let data = try JSONEncoder().encode(message)
        let jsonString = String(data: data, encoding: .utf8)!

        // Verify we use compact keys, not full names
        XCTAssertTrue(jsonString.contains("\"t\""))
        XCTAssertTrue(jsonString.contains("\"ts\""))
        XCTAssertTrue(jsonString.contains("\"pos\""))
        XCTAssertTrue(jsonString.contains("\"pid\""))
        XCTAssertFalse(jsonString.contains("\"type\""))
        XCTAssertFalse(jsonString.contains("\"timestamp\""))
        XCTAssertFalse(jsonString.contains("\"positionMs\""))
        XCTAssertFalse(jsonString.contains("\"peerId\""))
    }

    // MARK: - RelayMessage

    func testRelayMessageDecoding() throws {
        let json = """
        {"type":"created","sessionId":"sess-123","peerId":"peer-abc","code":"ABCD1234"}
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(RelayMessage.self, from: json)
        XCTAssertEqual(message.type, .created)
        XCTAssertEqual(message.sessionId, "sess-123")
        XCTAssertEqual(message.peerId, "peer-abc")
        XCTAssertEqual(message.code, "ABCD1234")
    }

    func testRelayMessagePeerJoined() throws {
        let json = """
        {"type":"peerJoined","peerId":"new-peer","sessionId":"sess-1"}
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(RelayMessage.self, from: json)
        XCTAssertEqual(message.type, .peerJoined)
        XCTAssertEqual(message.peerId, "new-peer")
    }

    // MARK: - DownloadItem

    func testDownloadItemProperties() {
        let item = DownloadItem(
            globalKey: "srv1:123",
            ratingKey: "123",
            serverId: "srv1",
            title: "Test Movie",
            type: "movie",
            status: .downloading,
            progress: 0.75,
            downloadedBytes: 750_000_000,
            totalBytes: 1_000_000_000,
            addedAt: Date()
        )

        XCTAssertEqual(item.id, "srv1:123")
        XCTAssertEqual(item.progressPercent, 75.0)
        XCTAssertFalse(item.downloadedFormatted.isEmpty)
        XCTAssertFalse(item.totalFormatted.isEmpty)
    }

    func testDownloadStatusValues() {
        XCTAssertEqual(DownloadStatus(rawValue: "queued"), .queued)
        XCTAssertEqual(DownloadStatus(rawValue: "downloading"), .downloading)
        XCTAssertEqual(DownloadStatus(rawValue: "paused"), .paused)
        XCTAssertEqual(DownloadStatus(rawValue: "completed"), .completed)
        XCTAssertEqual(DownloadStatus(rawValue: "failed"), .failed)
        XCTAssertEqual(DownloadStatus(rawValue: "cancelled"), .cancelled)
        XCTAssertEqual(DownloadStatus(rawValue: "partial"), .partial)
    }

    // MARK: - WatchSession & ControlMode

    func testControlMode() {
        XCTAssertEqual(ControlMode.hostOnly.rawValue, 0)
        XCTAssertEqual(ControlMode.anyone.rawValue, 1)
    }

    func testWatchSessionParticipant() {
        let participant = WatchSession.Participant(peerId: "p1", displayName: "Alice", isHost: true)
        XCTAssertEqual(participant.id, "p1")
        XCTAssertEqual(participant.displayName, "Alice")
        XCTAssertTrue(participant.isHost)
    }

    // MARK: - Duration Formatting (Int Extension)

    func testDurationFormatting() {
        XCTAssertEqual(7200000.shortDurationFormatted, "2h 0m")
        XCTAssertEqual(5400000.shortDurationFormatted, "1h 30m")
        XCTAssertEqual(1800000.shortDurationFormatted, "30m")
        XCTAssertEqual(7200000.durationFormatted, "2:00:00")
        XCTAssertEqual(90000.durationFormatted, "1:30")
    }

    func testDurationFormattingEdgeCases() {
        XCTAssertEqual(0.durationFormatted, "0:00")
        XCTAssertEqual(0.shortDurationFormatted, "0m")
        XCTAssertEqual(1000.durationFormatted, "0:01")
        XCTAssertEqual(59000.durationFormatted, "0:59")
        XCTAssertEqual(60000.durationFormatted, "1:00")
        XCTAssertEqual(3600000.durationFormatted, "1:00:00")
        XCTAssertEqual(3661000.durationFormatted, "1:01:01")
    }

    // MARK: - Date Extensions

    func testPlexTimestamp() {
        let date = Date(plexTimestamp: 1613046000)
        XCTAssertEqual(date.plexTimestamp, 1613046000)
    }

    func testDateMediumFormatted() {
        let date = Date(plexTimestamp: 1613046000)
        let formatted = date.mediumFormatted
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - URL Extensions

    func testURLWithPlexToken() {
        let url = URL(string: "https://server:32400/library/metadata/123")!
        let tokenized = url.withPlexToken("mytoken")
        XCTAssertTrue(tokenized.absoluteString.contains("X-Plex-Token=mytoken"))
    }

    func testURLWithPlexTokenPreservesExistingParams() {
        let url = URL(string: "https://server:32400/path?existing=value")!
        let tokenized = url.withPlexToken("tok")
        XCTAssertTrue(tokenized.absoluteString.contains("existing=value"))
        XCTAssertTrue(tokenized.absoluteString.contains("X-Plex-Token=tok"))
    }

    func testURLWithQueryItems() {
        let url = URL(string: "https://server:32400/path")!
        let result = url.withQueryItems(["key1": "value1", "key2": "value2"])
        let components = URLComponents(url: result, resolvingAgainstBaseURL: false)!
        let items = components.queryItems ?? []
        XCTAssertTrue(items.contains(where: { $0.name == "key1" && $0.value == "value1" }))
        XCTAssertTrue(items.contains(where: { $0.name == "key2" && $0.value == "value2" }))
    }

    func testStringAsPlexImageURL() {
        // Absolute URL — returned as-is
        let absolute = "https://image.tmdb.org/poster.jpg"
        let url1 = absolute.asPlexImageURL(baseURL: "https://server:32400", token: "tok")
        XCTAssertEqual(url1?.absoluteString, "https://image.tmdb.org/poster.jpg")

        // Relative path — prefixed with base URL + token
        let relative = "/library/metadata/123/thumb/1234567890"
        let url2 = relative.asPlexImageURL(baseURL: "https://server:32400", token: "tok")
        XCTAssertEqual(url2?.absoluteString, "https://server:32400/library/metadata/123/thumb/1234567890?X-Plex-Token=tok")
    }

    // MARK: - NavigationCoordinator

    @MainActor
    func testNavigationCoordinatorPlayMedia() {
        let coordinator = NavigationCoordinator()

        XCTAssertFalse(coordinator.isPlayerPresented)

        coordinator.playMedia(ratingKey: "123", resumeOffset: 5000)
        XCTAssertTrue(coordinator.isPlayerPresented)
        XCTAssertEqual(coordinator.playerRatingKey, "123")
        XCTAssertEqual(coordinator.playerResumeOffset, 5000)

        coordinator.dismissPlayer()
        XCTAssertFalse(coordinator.isPlayerPresented)
        XCTAssertNil(coordinator.playerRatingKey)
        XCTAssertNil(coordinator.playerResumeOffset)
    }

    @MainActor
    func testNavigationCoordinatorShowMediaDetail() {
        let coordinator = NavigationCoordinator()

        coordinator.tab = .home
        coordinator.showMediaDetail(ratingKey: "456")
        XCTAssertFalse(coordinator.homePath.isEmpty)
        XCTAssertTrue(coordinator.librariesPath.isEmpty)

        coordinator.tab = .libraries
        coordinator.showMediaDetail(ratingKey: "789")
        XCTAssertFalse(coordinator.librariesPath.isEmpty)

        coordinator.tab = .search
        coordinator.showMediaDetail(ratingKey: "101")
        XCTAssertFalse(coordinator.searchPath.isEmpty)
    }

    @MainActor
    func testNavigationCoordinatorNonNavigableTabs() {
        let coordinator = NavigationCoordinator()

        // Downloads and settings tabs don't push routes
        coordinator.tab = .downloads
        coordinator.showMediaDetail(ratingKey: "999")

        coordinator.tab = .settings
        coordinator.showMediaDetail(ratingKey: "999")
        // No crash, paths remain empty
    }

    // MARK: - PlexClientError

    func testPlexClientErrorDescriptions() {
        XCTAssertEqual(PlexClientError.invalidURL.errorDescription, "Invalid server URL")
        XCTAssertEqual(PlexClientError.httpError(404).errorDescription, "Server error (404)")
        XCTAssertEqual(PlexClientError.parseError.errorDescription, "Failed to parse server response")
        XCTAssertEqual(PlexClientError.notAuthenticated.errorDescription, "Not signed in")
        XCTAssertEqual(PlexClientError.unauthorized.errorDescription, "Session expired. Please sign in again.")
    }

    func testPlexClientErrorIsAuth() {
        XCTAssertTrue(PlexClientError.unauthorized.isAuthError)
        XCTAssertTrue(PlexClientError.notAuthenticated.isAuthError)
        XCTAssertFalse(PlexClientError.invalidURL.isAuthError)
        XCTAssertFalse(PlexClientError.httpError(500).isAuthError)
        XCTAssertFalse(PlexClientError.parseError.isAuthError)
    }

    // MARK: - PlayerViewModel State (No mpv dependency)

    @MainActor
    func testPlayerViewModelInitialState() {
        let vm = PlayerViewModel()
        XCTAssertFalse(vm.isPlaying)
        XCTAssertFalse(vm.isBuffering)
        XCTAssertEqual(vm.currentTime, 0)
        XCTAssertEqual(vm.duration, 0)
        XCTAssertNil(vm.playbackData)
        XCTAssertNil(vm.error)
        XCTAssertNil(vm.selectedAudioStream)
        XCTAssertNil(vm.selectedSubtitleStream)
        XCTAssertTrue(vm.autoPlayNext)
        XCTAssertNil(vm.nextEpisodeRatingKey)
    }

    @MainActor
    func testPlayerViewModelMarkerDetection() {
        let vm = PlayerViewModel()

        // Simulate playback data with markers
        // We can't set playbackData directly (private(set)), so test the marker
        // computed properties with nil data
        XCTAssertNil(vm.currentIntroMarker)
        XCTAssertNil(vm.currentCreditsMarker)
    }

    @MainActor
    func testPlayerViewModelStopCleansUp() {
        let vm = PlayerViewModel()
        vm.stop()
        XCTAssertFalse(vm.isPlaying)
    }
}
