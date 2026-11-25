import XCTest

/// The Siri Remote over the app's chrome, the system's top tab bar: Menu from a destination's content goes up to the tab
/// bar, one press moves focus one tab, and Menu on Home's tab leaves the app for the Apple TV's home screen, while Menu
/// anywhere else stays in the app.
final class RemoteNavigationTests: PlezyUITestCase {
    func testOnePressIsOneTabAndMenuOnHomesTabGoesToTheHomeScreen() {
        launchWithServer()
        settle()
        XCUIRemote.shared.press(.menu)
        expectFocus("nav.home", "Menu from Home's content goes to the tab bar, on Home")
        let tabs = tabItems()
        if tabs.count < 2 { fail("the tab bar shows \(tabs)") }
        XCUIRemote.shared.press(.right)
        expectFocus(tabs[1], "one press right is one tab on")
        XCUIRemote.shared.press(.left)
        expectFocus("nav.home", "one press left is one tab back")
        shot("tab bar on home")
        XCUIRemote.shared.press(.menu)
        if !app.wait(for: .runningBackground, timeout: 10) {
            fail("Menu on Home's tab left the app in \(app.state.rawValue), not for the home screen")
        }
    }

    func testMenuOffTheRootStaysInTheApp() {
        launchWithServer()
        settle()
        XCUIRemote.shared.press(.menu)
        expectFocus("nav.home", "the tab bar, on Home")
        XCUIRemote.shared.press(.right)
        expectFocus("nav.libraries", "Libraries' tab")
        require("libraries.screen", "Libraries, shown as its tab takes focus")
        XCUIRemote.shared.press(.down)
        settle()
        // From Libraries' screen up to its tab: the app keeps Menu.
        XCUIRemote.shared.press(.menu)
        expectFocus("nav.libraries", "Menu from Libraries' screen goes to its tab")
        if app.state != .runningForeground { fail("Menu off the root left the app") }
        shot("libraries tab")
    }

    /// A dev session signed into the run's server (`PLEZY_DEV_SERVER`), on Home once its first card holds focus: without
    /// one Home has nothing to focus and the tab bar holds focus from the start.
    private func launchWithServer() {
        let server = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        launchDev(arguments: server.isEmpty ? [] : ["--dev-server", server])
        require("home.screen", timeout: 60, "Home")
        let card = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'card.'")).firstMatch
        if !card.waitForExistence(timeout: 60) { fail("no Home card took focus") }
    }

    /// Lets Home's first focus land before the first press: a press while the screen still appears goes nowhere.
    private func settle() {
        Thread.sleep(forTimeInterval: 3)
    }

    /// The tab bar's destinations (`nav.<name>`), leading to trailing.
    private func tabItems() -> [String] {
        let items = app.tabBars.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'nav.'"))
        let snapshots = (0..<items.count).compactMap { try? items.element(boundBy: $0).snapshot() }
        return snapshots.sorted { $0.frame.minX < $1.frame.minX }.map(\.identifier)
    }

    /// Waits up to 5 s for the element `id` to have focus; fails with `what` and where focus is otherwise.
    private func expectFocus(_ id: String, _ what: String) {
        let target = element(id)
        let focused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasFocus == true"), object: target)
        if XCTWaiter.wait(for: [focused], timeout: 5) != .completed {
            let here = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
            fail("\(what): focus is on \((try? here.snapshot())?.identifier ?? "nothing"), not \(id)")
        }
    }
}
