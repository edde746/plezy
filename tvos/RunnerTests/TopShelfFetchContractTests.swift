import Foundation
import XCTest

@testable import Runner

// Contract tests for the Top Shelf live-fetch pipeline. The extension
// sources under test (ShelfSources/ShelfItemMapper/ShelfFetcher) also compile
// into the Runner app target, which this hosted bundle imports testably.
// No network is touched.
final class TopShelfFetchContractTests: XCTestCase {
  private let token = "secret-token-123"
  private let baseUrl = "https://media.example.com:32400"
  private let serverId = "srv-1"

  // MARK: - Plex mapping

  private static let plexContinueWatchingFixture = """
    {
      "MediaContainer": {
        "Metadata": [
          {
            "ratingKey": "101",
            "type": "episode",
            "title": "The Beach",
            "grandparentTitle": "Lost",
            "parentIndex": 2,
            "index": 5,
            "duration": 3600000,
            "viewOffset": 900000,
            "lastViewedAt": 1700000100,
            "parentThumb": "/library/metadata/55/thumb/111",
            "grandparentThumb": "/library/metadata/50/thumb/99",
            "thumb": "/library/metadata/101/thumb/33"
          },
          {
            "ratingKey": "202",
            "type": "movie",
            "title": "Heat",
            "duration": 10200000,
            "viewOffset": 5100000,
            "lastViewedAt": 1700000200,
            "thumb": "/library/metadata/202/thumb/77"
          }
        ]
      }
    }
    """

  func testPlexEpisodeMappingUsesSeriesTitleAndSeasonPoster() throws {
    let items = ShelfItemMapper.plexItems(
      fromResponse: try fixture(Self.plexContinueWatchingFixture),
      serverId: serverId,
      baseUrl: baseUrl,
      token: token
    )
    XCTAssertEqual(items.count, 2)

    let episode = items[0]
    XCTAssertEqual(episode.contentId, "plezy_srv-1_101")
    XCTAssertEqual(episode.title, "Lost")
    XCTAssertEqual(episode.episodeTitle, "The Beach")
    XCTAssertEqual(episode.seasonNumber, 2)
    XCTAssertEqual(episode.episodeNumber, 5)
    XCTAssertEqual(episode.durationMilliseconds, 3_600_000)
    XCTAssertEqual(episode.lastPlaybackPositionMilliseconds, 900_000)
    XCTAssertEqual(try XCTUnwrap(episode.playbackProgress), 0.25, accuracy: 0.0001)
    XCTAssertEqual(episode.recency, 1_700_000_100)
    // Season poster (parentThumb) wins the chain.
    XCTAssertEqual(
      episode.posterUrl,
      "\(baseUrl)/photo/:/transcode?width=600&height=900&minSize=1&upscale=1"
        + "&url=%2Flibrary%2Fmetadata%2F55%2Fthumb%2F111&X-Plex-Token=\(token)"
    )

    let movie = items[1]
    XCTAssertEqual(movie.contentId, "plezy_srv-1_202")
    XCTAssertEqual(movie.title, "Heat")
    XCTAssertNil(movie.episodeTitle)
    XCTAssertNil(movie.seasonNumber)
    XCTAssertNil(movie.episodeNumber)
    XCTAssertEqual(try XCTUnwrap(movie.playbackProgress), 0.5, accuracy: 0.0001)
    XCTAssertEqual(
      movie.posterUrl,
      "\(baseUrl)/photo/:/transcode?width=600&height=900&minSize=1&upscale=1"
        + "&url=%2Flibrary%2Fmetadata%2F202%2Fthumb%2F77&X-Plex-Token=\(token)"
    )
  }

  func testPlexPosterChainFallsBackThroughSeriesThenOwnThumb() {
    let base: [String: Any] = ["ratingKey": "1", "type": "episode", "title": "Ep", "grandparentTitle": "Show"]

    var metadata = base
    metadata["grandparentThumb"] = "/library/metadata/50/thumb/99"
    metadata["thumb"] = "/library/metadata/1/thumb/1"
    let seriesPoster = ShelfItemMapper.plexItem(metadata, serverId: serverId, baseUrl: baseUrl, token: token)
    XCTAssertEqual(
      seriesPoster?.posterUrl?.contains("url=%2Flibrary%2Fmetadata%2F50%2Fthumb%2F99"),
      true
    )

    metadata = base
    metadata["thumb"] = "/library/metadata/1/thumb/1"
    let ownThumb = ShelfItemMapper.plexItem(metadata, serverId: serverId, baseUrl: baseUrl, token: token)
    XCTAssertEqual(ownThumb?.posterUrl?.contains("url=%2Flibrary%2Fmetadata%2F1%2Fthumb%2F1"), true)

    let bare = ShelfItemMapper.plexItem(base, serverId: serverId, baseUrl: baseUrl, token: token)
    XCTAssertNotNil(bare)
    XCTAssertNil(bare?.posterUrl)
  }

  func testPlexHubWrappedResponseIsTolerated() throws {
    let wrapped = """
      {
        "MediaContainer": {
          "Hub": [
            {"Metadata": [{"ratingKey": "7", "type": "movie", "title": "Alien", "thumb": "/library/metadata/7/thumb/1"}]},
            {"Metadata": [{"ratingKey": "8", "type": "movie", "title": "Aliens"}]}
          ]
        }
      }
      """
    let items = ShelfItemMapper.plexItems(
      fromResponse: try fixture(wrapped),
      serverId: serverId,
      baseUrl: baseUrl,
      token: token
    )
    XCTAssertEqual(items.map(\.contentId), ["plezy_srv-1_7", "plezy_srv-1_8"])
  }

  // MARK: - MediaBrowser mapping

  private static let mediaBrowserFixture = """
    {
      "Items": [
        {
          "Id": "ep1",
          "Type": "Episode",
          "Name": "Winter Is Coming",
          "SeriesName": "Game of Thrones",
          "ParentIndexNumber": 1,
          "IndexNumber": 3,
          "RunTimeTicks": 36000000000,
          "SeasonId": "season-9",
          "SeriesId": "series-4",
          "UserData": {
            "PlaybackPositionTicks": 9000000000,
            "LastPlayedDate": "2023-11-14T22:13:20.0000000Z"
          }
        }
      ]
    }
    """

  func testMediaBrowserEpisodeMappingConvertsTicksAndPrefersSeasonPoster() throws {
    let items = ShelfItemMapper.mediaBrowserItems(
      fromResponse: try fixture(Self.mediaBrowserFixture),
      serverId: serverId,
      baseUrl: baseUrl,
      token: token
    )
    let episode = try XCTUnwrap(items.first)
    XCTAssertEqual(episode.contentId, "plezy_srv-1_ep1")
    XCTAssertEqual(episode.title, "Game of Thrones")
    XCTAssertEqual(episode.episodeTitle, "Winter Is Coming")
    XCTAssertEqual(episode.seasonNumber, 1)
    XCTAssertEqual(episode.episodeNumber, 3)
    // RunTimeTicks / PlaybackPositionTicks are 100 ns ticks; divide by 10_000
    // for milliseconds.
    XCTAssertEqual(episode.durationMilliseconds, 3_600_000)
    XCTAssertEqual(episode.lastPlaybackPositionMilliseconds, 900_000)
    XCTAssertEqual(try XCTUnwrap(episode.playbackProgress), 0.25, accuracy: 0.0001)
    XCTAssertEqual(episode.recency, 1_700_000_000)
    XCTAssertEqual(
      episode.posterUrl,
      "\(baseUrl)/Items/season-9/Images/Primary?maxWidth=600&maxHeight=900&api_key=\(token)"
    )
  }

  func testMediaBrowserPosterFallsBackToSeriesThenOwnImage() {
    let base: [String: Any] = ["Id": "ep1", "Type": "Episode", "Name": "Ep", "SeriesName": "Show"]

    var item = base
    item["SeriesId"] = "series-4"
    let seriesPoster = ShelfItemMapper.mediaBrowserItem(item, serverId: serverId, baseUrl: baseUrl, token: token)
    XCTAssertEqual(seriesPoster?.posterUrl?.contains("/Items/series-4/Images/Primary"), true)

    let ownPoster = ShelfItemMapper.mediaBrowserItem(base, serverId: serverId, baseUrl: baseUrl, token: token)
    XCTAssertEqual(ownPoster?.posterUrl?.contains("/Items/ep1/Images/Primary"), true)
  }

  func testMediaBrowserDateParsingToleratesSevenDigitFractions() {
    XCTAssertEqual(ShelfItemMapper.parseMediaBrowserDate("2023-11-14T22:13:20.0000000Z"), 1_700_000_000)
    XCTAssertEqual(ShelfItemMapper.parseMediaBrowserDate("2023-11-14T22:13:20Z"), 1_700_000_000)
    XCTAssertNil(ShelfItemMapper.parseMediaBrowserDate("not a date"))
  }

  // MARK: - Source descriptors

  private static let sourcesFixture = """
    {
      "schemaVersion": 3,
      "ownerId": "profile-a",
      "maxItems": 20,
      "servers": [
        {"serverId": "srv-plex", "kind": "plex", "name": "Den", "baseUrl": "https://plex.example.com"},
        {"serverId": "srv-jelly", "kind": "jellyfin", "name": "Attic", "baseUrl": "https://jf.example.com", "userId": "user-1"}
      ]
    }
    """

  func testSourcesResolveJoinsKeychainTokens() throws {
    let sources = try XCTUnwrap(
      ShelfSourceStore.resolve(
        payloadData: Data(Self.sourcesFixture.utf8),
        tokensByServerId: ["srv-plex": "tok-a", "srv-jelly": "tok-b"]
      )
    )
    XCTAssertEqual(sources.ownerId, "profile-a")
    XCTAssertEqual(sources.maxItems, 20)
    XCTAssertEqual(sources.servers.count, 2)
    XCTAssertEqual(sources.servers[0].descriptor.kind, .plex)
    XCTAssertEqual(sources.servers[0].token, "tok-a")
    XCTAssertEqual(sources.servers[1].descriptor.userId, "user-1")
  }

  func testSourcesResolveRejectsWrongSchemaAndEmptyOwner() {
    let wrongSchema = Self.sourcesFixture.replacingOccurrences(
      of: "\"schemaVersion\": 3",
      with: "\"schemaVersion\": 2"
    )
    XCTAssertNil(
      ShelfSourceStore.resolve(
        payloadData: Data(wrongSchema.utf8),
        tokensByServerId: ["srv-plex": "tok-a"]
      )
    )

    let emptyOwner = Self.sourcesFixture.replacingOccurrences(
      of: "\"ownerId\": \"profile-a\"",
      with: "\"ownerId\": \"\""
    )
    XCTAssertNil(
      ShelfSourceStore.resolve(
        payloadData: Data(emptyOwner.utf8),
        tokensByServerId: ["srv-plex": "tok-a"]
      )
    )
  }

  func testSourcesResolveSkipsServersWithoutTokensAndMalformedSiblings() throws {
    // A server with no keychain token is dropped; all dropped means nil.
    let partial = try XCTUnwrap(
      ShelfSourceStore.resolve(
        payloadData: Data(Self.sourcesFixture.utf8),
        tokensByServerId: ["srv-jelly": "tok-b"]
      )
    )
    XCTAssertEqual(partial.servers.map(\.descriptor.serverId), ["srv-jelly"])
    XCTAssertNil(
      ShelfSourceStore.resolve(payloadData: Data(Self.sourcesFixture.utf8), tokensByServerId: [:])
    )

    // An unknown kind only sinks its own entry, not the whole payload.
    let malformedSibling = Self.sourcesFixture.replacingOccurrences(
      of: "\"kind\": \"plex\"",
      with: "\"kind\": \"unknown\""
    )
    let survivors = try XCTUnwrap(
      ShelfSourceStore.resolve(
        payloadData: Data(malformedSibling.utf8),
        tokensByServerId: ["srv-plex": "tok-a", "srv-jelly": "tok-b"]
      )
    )
    XCTAssertEqual(survivors.servers.map(\.descriptor.serverId), ["srv-jelly"])
  }

  // MARK: - Merge

  func testMergeOrdersByRecencyDescendingDeduplicatesAndCaps() {
    let merged = ShelfItemMapper.merge(
      [
        [makeItem("a", recency: 10), makeItem("b", recency: 5)],
        [makeItem("c", recency: 20), makeItem("a", recency: 99)],
      ],
      maxItems: 2
    )
    // "a" keeps its first (resume-ordered) occurrence, then recency sorts.
    XCTAssertEqual(merged.map(\.contentId), ["c", "a"])
    XCTAssertEqual(merged[1].recency, 10)

    let uncapped = ShelfItemMapper.merge([[makeItem("b", recency: 0), makeItem("a", recency: 0)]], maxItems: 20)
    // Equal recency keeps input order.
    XCTAssertEqual(uncapped.map(\.contentId), ["b", "a"])
  }

  // MARK: - Request construction

  func testPlexContinueWatchingRequestCarriesTokenOnlyAsHeader() throws {
    let request = try XCTUnwrap(
      ShelfFetcher.plexContinueWatchingRequest(baseUrl: baseUrl + "/", token: token, maxItems: 20)
    )
    let url = try XCTUnwrap(request.url?.absoluteString)
    XCTAssertEqual(url, "\(baseUrl)/hubs/continueWatching?count=20&includeGuids=1")
    XCTAssertFalse(url.contains(token))
    let headers = request.allHTTPHeaderFields ?? [:]
    XCTAssertEqual(headers["X-Plex-Token"], token)
    XCTAssertEqual(headers["Accept"], "application/json")
    XCTAssertEqual(headers.values.filter { $0.contains(token) }.count, 1)
  }

  func testMediaBrowserRequestsCarryTokenOnlyAsHeader() throws {
    let resume = try XCTUnwrap(
      ShelfFetcher.mediaBrowserResumeRequest(baseUrl: baseUrl, token: token, userId: "user-1", maxItems: 20)
    )
    XCTAssertEqual(
      resume.url?.absoluteString,
      "\(baseUrl)/UserItems/Resume?userId=user-1&Limit=20&MediaTypes=Video"
        + "&Recursive=true&EnableTotalRecordCount=false"
    )

    let nextUp = try XCTUnwrap(
      ShelfFetcher.mediaBrowserNextUpRequest(baseUrl: baseUrl, token: token, userId: "user-1", maxItems: 20)
    )
    XCTAssertEqual(
      nextUp.url?.absoluteString,
      "\(baseUrl)/Shows/NextUp?userId=user-1&Limit=20"
        + "&EnableResumable=false&EnableTotalRecordCount=false"
    )

    for request in [resume, nextUp] {
      let url = try XCTUnwrap(request.url?.absoluteString)
      XCTAssertFalse(url.contains(token))
      let headers = request.allHTTPHeaderFields ?? [:]
      XCTAssertEqual(headers["X-Emby-Token"], token)
      XCTAssertEqual(headers.values.filter { $0.contains(token) }.count, 1)
    }
  }

  func testPosterUrlsCarryTokenAsQueryParameterExactlyOnce() throws {
    let plex = try XCTUnwrap(
      ShelfItemMapper.plexPosterUrl(path: "/library/metadata/55/thumb/1", baseUrl: baseUrl, token: token)
    )
    XCTAssertEqual(occurrences(of: token, in: plex), 1)
    XCTAssertEqual(occurrences(of: "X-Plex-Token=", in: plex), 1)

    let mediaBrowser = try XCTUnwrap(
      ShelfItemMapper.mediaBrowserPosterUrl(itemId: "season-9", baseUrl: baseUrl, token: token)
    )
    XCTAssertEqual(occurrences(of: token, in: mediaBrowser), 1)
    XCTAssertEqual(occurrences(of: "api_key=", in: mediaBrowser), 1)
  }

  // MARK: - Token redaction

  func testTokenNeverAppearsInDescriptionOrDebugStrings() throws {
    let source = ShelfServerSource(
      descriptor: ShelfServerDescriptor(
        serverId: "srv-plex",
        kind: .plex,
        name: "Den",
        baseUrl: baseUrl,
        userId: nil
      ),
      token: token
    )
    XCTAssertFalse(String(describing: source).contains(token))
    XCTAssertFalse(String(reflecting: source).contains(token))
    XCTAssertFalse(source.description.contains(token))
    XCTAssertFalse(source.debugDescription.contains(token))

    let item = try XCTUnwrap(
      ShelfItemMapper.plexItem(
        ["ratingKey": "1", "title": "Heat", "thumb": "/library/metadata/1/thumb/1"],
        serverId: serverId,
        baseUrl: baseUrl,
        token: token
      )
    )
    XCTAssertEqual(item.posterUrl?.contains(token), true)
    XCTAssertFalse(String(describing: item).contains(token))
    XCTAssertFalse(String(reflecting: item).contains(token))
  }

  // MARK: - Helpers

  private func fixture(_ json: String) throws -> Any {
    try JSONSerialization.jsonObject(with: Data(json.utf8))
  }

  private func makeItem(_ contentId: String, recency: Double) -> ShelfFetchedItem {
    ShelfFetchedItem(
      contentId: contentId,
      title: contentId,
      episodeTitle: nil,
      type: "movie",
      seasonNumber: nil,
      episodeNumber: nil,
      durationMilliseconds: nil,
      lastPlaybackPositionMilliseconds: nil,
      posterUrl: nil,
      recency: recency
    )
  }

  private func occurrences(of needle: String, in haystack: String) -> Int {
    haystack.components(separatedBy: needle).count - 1
  }
}
