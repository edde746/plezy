import XCTest

/// The product's start, as after a fresh install (the harness starts each run without the app's data): the
/// sign-in screen with its server choices, once the splash has gone.
final class LaunchTests: PlezyUITestCase {
    func testFreshLaunchShowsSignIn() {
        launchProduct()
        require("signin.screen", timeout: 60, "after the launch")
        require("signin.jellyfin", "the sign-in's Connect to Jellyfin")
        shot("sign-in")
    }
}
