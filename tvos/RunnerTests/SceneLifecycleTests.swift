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

  func testSceneURLRoutingReportsAcceptedURLAndVisitsEveryContext() {
    let urls = [
      URL(string: "https://example.com/first")!,
      URL(string: "plezy://play?content_id=server%3Aitem")!,
      URL(string: "https://example.com/last")!,
    ]
    var visited: [URL] = []

    let handled = SystemShelfPlugin.handleSceneURLs(urls) { url in
      visited.append(url)
      return url.scheme == "plezy"
    }

    XCTAssertTrue(handled)
    XCTAssertEqual(visited, urls)
  }

  func testSceneURLRoutingReturnsFalseWhenNoContextIsAccepted() {
    let urls = [URL(string: "https://example.com/unhandled")!]

    XCTAssertFalse(SystemShelfPlugin.handleSceneURLs(urls) { _ in false })
    XCTAssertFalse(SystemShelfPlugin.handleSceneURLs([]) { _ in true })
  }
}
