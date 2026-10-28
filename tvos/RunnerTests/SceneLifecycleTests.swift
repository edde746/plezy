import XCTest
@testable import Runner

final class SceneLifecycleTests: XCTestCase {
  func testRunnerDeclaresSingleFlutterSceneLifecycle() throws {
    let manifest = try XCTUnwrap(
      Bundle(for: AppDelegate.self).object(forInfoDictionaryKey: "UIApplicationSceneManifest")
        as? [String: Any]
    )
    XCTAssertEqual(manifest["UIApplicationSupportsMultipleScenes"] as? Bool, false)

    let configurations = try XCTUnwrap(manifest["UISceneConfigurations"] as? [String: Any])
    let applicationScenes = try XCTUnwrap(
      configurations["UIWindowSceneSessionRoleApplication"] as? [[String: Any]]
    )
    let configuration = try XCTUnwrap(applicationScenes.first)
    XCTAssertEqual(applicationScenes.count, 1)
    XCTAssertEqual(configuration["UISceneClassName"] as? String, "UIWindowScene")
    XCTAssertEqual(configuration["UISceneConfigurationName"] as? String, "flutter")
    XCTAssertEqual(configuration["UISceneDelegateClassName"] as? String, "FlutterSceneDelegate")
    XCTAssertEqual(configuration["UISceneStoryboardFile"] as? String, "Main")
  }

  func testEveryPlezyLinkIsForwardedVerbatim() throws {
    let links = [
      "plezy://open",
      "plezy://open?profile=Kids%20Room",
      "plezy://play?content_id=plezy_server_item",
      "plezy://play?server=abc123&id=42&mode=shuffle&profile=p1",
      "plezy://play?type=show&tvdb=81189&mode=next",
      "plezy://live?channel=5.1&server=abc123&start=beginning",
      "plezy://external-player/success/session-1?position=1200",
      "plezy://some-future-host/path?unknown=1",
    ]
    for link in links {
      let url = try XCTUnwrap(URL(string: link))
      XCTAssertEqual(DeepLinkPlugin.forwardedLink(for: url), link)
    }

    let mixedCase = try XCTUnwrap(URL(string: "PLEZY://play?server=abc123&id=42"))
    XCTAssertEqual(DeepLinkPlugin.forwardedLink(for: mixedCase), mixedCase.absoluteString)
  }

  func testOtherSchemesAreNotForwarded() throws {
    let others = [
      "https://example.com/play?content_id=plezy_server_item",
      "plezyx://play?server=abc123&id=42",
      "vlc-x-callback://x-callback-url/stream?url=plezy%3A%2F%2Fplay",
      "file:///tmp/plezy",
    ]
    for other in others {
      let url = try XCTUnwrap(URL(string: other))
      XCTAssertNil(DeepLinkPlugin.forwardedLink(for: url))
    }
  }

  func testSceneURLRoutingReportsAcceptedURLAndVisitsEveryContext() {
    let urls = [
      URL(string: "https://example.com/first")!,
      URL(string: "plezy://play?content_id=plezy_server_item")!,
      URL(string: "https://example.com/last")!,
    ]
    var visited: [URL] = []

    let handled = DeepLinkPlugin.receiveAll(urls) { url in
      visited.append(url)
      return DeepLinkPlugin.forwardedLink(for: url) != nil
    }

    XCTAssertTrue(handled)
    XCTAssertEqual(visited, urls)
  }

  func testSceneURLRoutingReturnsFalseWhenNoContextIsAccepted() {
    let urls = [URL(string: "https://example.com/unhandled")!]

    XCTAssertFalse(DeepLinkPlugin.receiveAll(urls) { _ in false })
    XCTAssertFalse(DeepLinkPlugin.receiveAll([]) { _ in true })
  }
}
