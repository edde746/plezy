import XCTest
#if os(iOS)
import UIKit
#endif

/// Libraries' behaviour against the server `PLEZY_DEV_SERVER` names (the default seeded Jellyfin or Emby, as `maestro`,
/// its administrator): swiping between tabs that keep their scroll position and Browse kept in place as the window's
/// width changes under a pushed screen (iPhone, iPad), pull to refresh, the sort menu's direction, the grid's gutter
/// following the grid spacing setting live, the filter editor committing its edits however it closes (Apple TV: the
/// filters' menu applying each pick), the alphabet index's drag and keys, a folder's Play/Shuffle menu, Manage
/// libraries' admin menu (a scan asked first; none for a user who isn't an administrator), and on Apple TV Up from the
/// first row of Collections, Genres and the folder tree to the header row and Down from the header row to Browse's
/// Retry.
final class LibraryOptionsTests: PlezyUITestCase {
    // MARK: - Tabs

    #if os(iOS)
    /// A swipe moves from Browse to the next tab and back, and Browse is still where it was scrolled to.
    func testTabsSwipeAndKeepTheirScroll() throws {
        try launch()
        steps.pickLibrary("Movies")
        let grid = require("libraries.grid", timeout: 30, "the Browse grid")
        let alpha = steps.card(prefix: "Alpha Archive")
        XCTAssertTrue(alpha.exists(within: 30), "the first title")
        _ = waitUntil(5) { grid.isHittable }
        grid.swipeUp(velocity: .slow)
        _ = waitUntil(5) { !visible(alpha) }
        XCTAssertFalse(visible(alpha), "the grid scrolled")
        swipe(from: 0.9, to: 0.1)
        XCTAssertTrue(waitUntil(10) { viewShown("Collections") }, "a swipe moves to the next tab")
        // Lets the page finish sliding in before the shot.
        sleep(2)
        shot("swiped to collections")
        swipe(from: 0.1, to: 0.9)
        XCTAssertTrue(waitUntil(10) { viewShown("Browse") }, "a swipe back moves to Browse")
        // Gives a stray scroll reset time to show before checking Browse kept its place.
        sleep(2)
        XCTAssertFalse(visible(alpha), "Browse kept its scroll position")
        shot("back on browse")
    }

    /// A card's menu that opens over the header row (a card at the foot of Browse) runs the entry where it covers the
    /// row's glass, which doesn't take the tap while a menu is open (`OpenItemMenu`); the mark is undone after. Where no
    /// entry reaches the row the test skips: iPhone's and iPad's one-line rows sit above the menus' entries, a menu's
    /// title alone over them.
    func testCardMenuEntryOverTheHeaderRowRuns() throws {
        try launch()
        steps.pickLibrary("Movies")
        require("libraries.grid", timeout: 30, "the Browse grid")
        XCTAssertTrue(steps.card(prefix: "Alpha Archive").exists(within: 30), "the first title")
        // Lets the grid finish laying out before the cards' frames are read.
        sleep(2)
        let header = ["libraries.library", "libraries.view", "libraries.grouping", "libraries.sort", "libraries.filters", "libraries.shuffle", "libraries.more"]
        guard let entry = menuEntryOverGlass(header, pressing: NSPredicate(format: "identifier BEGINSWITH 'card.'")) else {
            throw XCTSkip("no card's menu opens over the header row")
        }
        shot("\(entry.id) over \(entry.glass)")
        tap(at: entry.point)
        if !element(entry.id).waitForNonExistence(timeout: 5) {
            fail("\(entry.id) over \(entry.glass) doesn't run: the menu stays open")
        }
        shot("after \(entry.id)")
        // The mark undone, its other entry tapped clear of the glass.
        let undo = ["menu.watch": "menu.unwatch", "menu.unwatch": "menu.watch"][entry.id]
        if let undo {
            require("menu.message", timeout: 15, "the mark's message")
            element(entry.target).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 1.0)
            require(undo, timeout: 10, "the reopened menu offering \(undo)").coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            require("menu.message", timeout: 15, "the undone mark's message")
        }
    }

    /// The window's width changing under a pushed screen (turned either way; iPad's sidebar hidden is the same
    /// change) leaves Browse in place when the screen pops: its first card starts at the chip row's leading edge.
    func testBrowseKeepsItsPlaceAcrossAWidthChange() throws {
        try launch()
        steps.pickLibrary("Movies")
        require("libraries.grid", timeout: 30, "the Browse grid")
        let alpha = steps.card(prefix: "Alpha Archive")
        XCTAssertTrue(alpha.exists(within: 30), "the first title")
        _ = waitUntil(5) { alpha.isHittable }
        defer { XCUIDevice.shared.orientation = .portrait }
        var widths: Set<CGFloat> = []
        for (orientation, name) in [(UIDeviceOrientation.landscapeLeft, "landscape"), (.portrait, "portrait")] {
            steps.press(alpha)
            require("detail.screen", timeout: 20, "Alpha Archive's detail")
            XCUIDevice.shared.orientation = orientation
            // Lets the rotation finish before the window's width is read; nothing signals its end.
            sleep(2)
            widths.insert(app.windows.firstMatch.frame.width)
            backButton.tap()
            XCTAssertTrue(alpha.exists(within: 10), "back on Browse")
            _ = waitUntil(5) { abs(alpha.frame.minX - element("libraries.library").frame.minX) < 1 }
            shot("browse turned to \(name)")
            XCTAssertEqual(alpha.frame.minX, element("libraries.library").frame.minX, accuracy: 1, "\(name): the first card starts under the first chip")
        }
        if widths.count < 2 { throw XCTSkip("the window keeps its width (\(widths)) as the device turns: no width change here") }
    }

    /// A pull reloads Recommended (Recently Added scrolled along shows its first card again) and the folder
    /// tree's root (an expanded folder comes back collapsed).
    func testPullToRefresh() throws {
        try launch()
        steps.pickLibrary("Movies")
        steps.showLibraryTab("recommended")
        let rows = require("libraries.recommended", timeout: 30, "Recommended's rows")
        // Recently Added: a row long enough to scroll whatever else (Continue Watching) the server lists first.
        let recent = rows.descendants(matching: .any).matching(NSPredicate(format: "identifier ENDSWITH '.recent'")).firstMatch
        XCTAssertTrue(recent.exists(within: 30), "Recommended's Recently Added")
        let card = recent.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        XCTAssertTrue(card.exists(within: 30), "Recently Added's first card")
        // That card itself, not whichever comes first once the row scrolls.
        let first = recent.descendants(matching: .any).matching(identifier: card.identifier).firstMatch
        _ = waitUntil(5) { first.isHittable }
        first.swipeLeft(velocity: .fast)
        _ = waitUntil(5) { !visible(first) }
        XCTAssertFalse(visible(first), "the hub row scrolled along")
        pull(rows)
        XCTAssertTrue(waitUntil(30) { visible(first) }, "the pull reloads Recommended")
        shot("recommended refreshed")

        steps.pickLibrary("Home Videos")
        steps.showLibraryTab("browse")
        let folders = require("libraries.folders", timeout: 30, "the folder tree")
        steps.press(require("libraries.folder.Holiday 2026", timeout: 30, "the Holiday 2026 folder"))
        let child = require("libraries.folder.Beach Day", timeout: 20, "the folder's items")
        // Lets the folder finish expanding before the pull.
        sleep(1)
        pull(folders)
        XCTAssertTrue(child.waitForNonExistence(timeout: 30), "the pull reloads the tree's root")
        require("libraries.folder.Holiday 2026", timeout: 30, "the tree back after the pull")
        shot("folders refreshed")
    }

    /// In each kind of library (films, shows, music, home videos) every type and every view keeps the header
    /// row's library menu, view menu, type (on Browse) and ⋯, and the first type and Browse come back from the others.
    /// The type shows one symbol whatever the type, never one the library menu or the view menu shows; on a phone the
    /// view menu, its symbol alone, shows one symbol whatever the view; the library menu shows its symbol in every type
    /// and view of a library or in none.
    func testHeaderKeepsItsControlsThroughEveryTypeAndView() throws {
        executionTimeAllowance = 900
        try launch()
        var types: Set<[String]> = []
        var views: Set<[String]> = []
        for library in ["Movies", "Shows", "Music", "Home Videos"] {
            var forms: Set<Bool> = []
            steps.pickLibrary(library)
            steps.showLibraryTab("browse")
            requireHeader("\(library) on Browse", type: true)
            forms.insert(!symbols(of: "libraries.library").isEmpty)
            let count = optionCount("libraries.grouping")
            XCTAssertGreaterThan(count, 1, "\(library) offers types")
            for index in Array(1..<count) + [0] {
                pickOption("libraries.grouping", index)
                let label = element("libraries.grouping").label
                requireHeader("\(library) as \(label)", type: true)
                shot("\(library) as \(label)")
                let type = symbols(of: "libraries.grouping")
                XCTAssertFalse(type.isEmpty, "\(library) as \(label): the type shows a symbol")
                XCTAssertTrue(Set(type).isDisjoint(with: symbols(of: "libraries.library")), "\(library) as \(label): the type's symbol \(type) isn't the library menu's")
                types.insert(type)
                forms.insert(!symbols(of: "libraries.library").isEmpty)
            }
            XCTAssertTrue(waitUntil(30) { element("libraries.grid").exists }, "\(library): the first type shows the grid again")
            let labels = viewLabels()
            for (index, label) in labels.enumerated() where label != "Downloads" {
                pickOption("libraries.view", index)
                XCTAssertTrue(waitUntil(10) { viewShown(label) }, "\(library): the view menu shows \(label)")
                requireHeader("\(library) on \(label)", type: label == "Browse")
                let view = symbols(of: "libraries.view")
                if !view.isEmpty {
                    XCTAssertTrue(Set(view).isDisjoint(with: types.first ?? []), "\(library) on \(label): the view menu's symbol \(view) isn't the type's")
                    views.insert(view)
                }
                forms.insert(!symbols(of: "libraries.library").isEmpty)
            }
            steps.showLibraryTab("browse")
            requireHeader("\(library) back on Browse", type: true)
            XCTAssertEqual(forms.count, 1, "\(library): the library menu shows its symbol in some types and views only")
        }
        XCTAssertEqual(types.count, 1, "one symbol for every type: \(types)")
        XCTAssertLessThanOrEqual(views.count, 1, "one symbol for every view: \(views)")
    }

    /// The header row's library menu, view menu and ⋯ (and on Browse the type), each drawn where it can be pressed.
    private func requireHeader(_ when: String, type: Bool) {
        for id in ["libraries.library", "libraries.view", "libraries.more"] + (type ? ["libraries.grouping"] : []) {
            let control = element(id)
            XCTAssertTrue(waitUntil(20) { control.exists && control.isHittable }, "\(when): \(id) in the header row")
        }
    }

    /// How many options the filter menu `id` offers: opened, counted, closed.
    private func optionCount(_ id: String) -> Int {
        steps.openFilterMenu(id)
        let count = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "\(id).option.")).count
        steps.dismissMenu()
        return count
    }

    /// The view menu's options' labels, in order.
    private func viewLabels() -> [String] {
        steps.openFilterMenu("libraries.view")
        let options = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'libraries.view.option.'"))
        let labels = (0..<options.count).map { steps.prefixed("libraries.view.option.\($0)").label }
        steps.dismissMenu()
        return labels
    }

    /// Picks the filter menu `id`'s option `index`, then lets the tab load.
    private func pickOption(_ id: String, _ index: Int) {
        steps.openFilterMenu(id)
        let entry = steps.prefixed("\(id).option.\(index)")
        steps.pressOption(entry)
        XCTAssertTrue(entry.waitForNonExistence(timeout: 10), "\(id)'s menu closes on option \(index)")
        // Lets the tab's content load before the callers' shots; nothing signals it.
        sleep(2)
    }

    /// The symbols a header control draws (its chevron aside), by their identifiers and labels.
    private func symbols(of id: String) -> [String] {
        element(id).images.allElementsBoundByIndex
            .filter { !$0.identifier.contains("chevron") }
            .map { "\($0.identifier)|\($0.label)" }.sorted()
    }
    #endif

    // MARK: - Sort

    #if !os(macOS)
    /// Ascending and Descending turn the field shown round; another field keeps the direction.
    func testSortDirection() throws {
        // Five picks, each reached by the remote on Apple TV.
        executionTimeAllowance = 600
        try launch()
        steps.pickLibrary("Movies")
        require("libraries.grid", timeout: 30, "the Browse grid")
        steps.openFilterMenu("libraries.sort")
        // Lets the menu finish opening before the shot.
        sleep(1)
        shot("sort menu default")
        steps.pickOption("libraries.sort", label: "Descending")
        XCTAssertTrue(firstCard(is: "Zulu"), "the server's order, Title, turned round")
        shot("title descending")

        steps.openFilterMenu("libraries.sort")
        steps.pickOption("libraries.sort", label: "Date Added")
        steps.openFilterMenu("libraries.sort")
        steps.pickOption("libraries.sort", label: "Title")
        XCTAssertTrue(firstCard(is: "Zulu"), "Title keeps Descending through another field")

        steps.openFilterMenu("libraries.sort")
        steps.pickOption("libraries.sort", label: "Ascending")
        XCTAssertTrue(firstCard(is: "Alpha Archive"), "Title ascending")
        shot("title ascending")
        steps.openFilterMenu("libraries.sort")
        steps.pickOption("libraries.sort", label: "Clear")
    }
    #endif

    /// The sort's options are Clear (while a sort is picked), Ascending and Descending, then
    /// under Sort By the fields; the field and the direction in effect are marked, the others not. With no sort picked,
    /// the server's own order (title ascending) is the one marked, and a field picked takes its own direction (Date Added
    /// newest first). The marks are read from the options' identifiers (`<id>.option.<i>.selected`, a direction's
    /// `.arrow.up` or `.arrow.down` after it), as a menu's checks can't be.
    func testSortMenuMarksActiveSortAndDirection() throws {
        let id = "libraries.sort"
        // Four picks, each reached by the remote on Apple TV.
        executionTimeAllowance = 600
        try launch()
        steps.pickLibrary("Movies")
        require("libraries.grid", timeout: 30, "the Browse grid")
        steps.openFilterMenu(id)
        let title = steps.option(id, label: "Title")
        _ = waitUntil(10) { title.exists }
        // Lets the menu finish opening before the shot.
        sleep(1)
        shot("sort menu default")
        XCTAssertFalse(steps.option(id, label: "Clear").exists, "no Clear with no sort picked")
        XCTAssertTrue(steps.option(id, label: "Ascending").identifier.hasPrefix("\(id).option.0."), "Ascending first")
        XCTAssertTrue(waitUntil(10) { steps.option(id, label: "Ascending").identifier.hasSuffix(".selected.arrow.up") }, "with no sort picked, ascending marked")
        XCTAssertTrue(waitUntil(10) { title.identifier.hasSuffix(".selected") }, "with no sort picked, Title marked: \(title.identifier)")
        XCTAssertFalse(steps.option(id, label: "Date Added").identifier.contains(".selected"), "Date Added unmarked")
        steps.pickOption(id, label: "Date Added")

        steps.openFilterMenu(id)
        let dateAdded = steps.option(id, label: "Date Added")
        XCTAssertTrue(steps.option(id, label: "Clear").identifier.hasPrefix("\(id).option.0"), "Clear first once a sort is picked")
        XCTAssertEqual(steps.option(id, label: "Ascending").identifier, "\(id).option.1", "Ascending after Clear, unmarked")
        XCTAssertTrue(waitUntil(10) { dateAdded.identifier.hasSuffix(".selected") }, "Date Added marked: \(dateAdded.identifier)")
        XCTAssertTrue(steps.option(id, label: "Descending").identifier.hasSuffix(".selected.arrow.down"), "Date Added from the unsorted state: its own direction, newest first")
        XCTAssertFalse(steps.option(id, label: "Title").identifier.contains(".selected"), "Title unmarked")
        // Lets the menu finish opening before the shot.
        sleep(1)
        shot("sort menu descending")
        steps.pickOption(id, label: "Ascending")

        steps.openFilterMenu(id)
        XCTAssertTrue(waitUntil(10) { steps.option(id, label: "Ascending").identifier.hasSuffix(".selected.arrow.up") }, "Ascending marked")
        XCTAssertFalse(steps.option(id, label: "Descending").identifier.contains(".selected"), "Descending unmarked")
        XCTAssertTrue(dateAdded.identifier.hasSuffix(".selected"), "Date Added still marked")
        // Lets the menu finish opening before the shot.
        sleep(1)
        shot("sort menu ascending")
        steps.pickOption(id, label: "Clear")
    }

    #if !os(tvOS)
    /// Every option of Browse's sort is in reach however many the type has (Shows › Seasons on Jellyfin: 14, Random
    /// last, after Clear and the directions), on iPad in portrait and landscape too, where a system menu cut off the last
    /// two (iPhone and iPad: a popover list, which scrolls; the Mac: its menu); the first, Clear, clears the sort.
    func testEverySortOptionIsInReach() throws {
        try launch()
        steps.pickLibrary("Shows")
        require("libraries.grid", timeout: 30, "the Browse grid")
        steps.openFilterMenu("libraries.grouping")
        steps.pickOption("libraries.grouping", label: "Seasons")
        steps.openFilterMenu("libraries.sort")
        steps.pickOption("libraries.sort", label: "Date Added")
        #if os(iOS)
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .portrait
        // Lets the rotation finish; nothing signals its end.
        sleep(2)
        reachEverySort("portrait", then: false)
        XCUIDevice.shared.orientation = .landscapeLeft
        // Lets the rotation finish; nothing signals its end.
        sleep(2)
        reachEverySort("landscape", then: true)
        #else
        reachEverySort("window", then: true)
        #endif
        XCTAssertTrue(waitUntil(10) { !element("libraries.sort").isSelected }, "Clear cleared the sort")
        shot("sort cleared")
    }

    /// Opens the sort, finds its first option, Clear, in reach, then brings its last, Random, into reach (iPhone and
    /// iPad: scrolling its list); then picks Clear (scrolled back to it) where `clears`, else closes it.
    private func reachEverySort(_ name: String, then clears: Bool) {
        steps.openFilterMenu("libraries.sort")
        // Lets the menu finish opening before the shot and the reach checks.
        sleep(1)
        shot("sort options \(name)")
        let random = steps.option("libraries.sort", label: "Random")
        let clear = steps.option("libraries.sort", label: "Clear")
        XCTAssertTrue(clear.exists && clear.isHittable, "Clear is in reach, first (\(name))")
        #if os(iOS)
        let list = app.popovers.firstMatch
        for _ in 0..<4 where !(random.exists && random.isHittable) { list.swipeUp(velocity: .slow) }
        #endif
        XCTAssertTrue(random.exists && random.isHittable, "Random is in reach (\(name))")
        shot("sort options end \(name)")
        if clears {
            #if os(iOS)
            for _ in 0..<4 where !(clear.exists && clear.isHittable) { list.swipeDown(velocity: .slow) }
            #endif
            steps.pickOption("libraries.sort", label: "Clear")
        } else {
            steps.dismissMenu()
        }
    }
    #endif

    // MARK: - Grid spacing

    #if !os(tvOS)
    /// The gutter between Browse's cards follows Settings › Appearance › Grid spacing, the grid laid out again
    /// as the setting changes: tight (the default off TV) 6 apart, spacious 12 more.
    func testGridSpacingFollowsTheSetting() throws {
        try launch()
        steps.pickLibrary("Movies")
        steps.showLibraryTab("browse")
        require("libraries.grid", timeout: 30, "the Browse grid")
        // Lets the grid finish laying out before the gap is measured.
        sleep(2)
        let tight = cardGap()
        shot("grid spacing tight")
        XCTAssertEqual(tight, 6, accuracy: 1, "tight cards stand 6 apart")
        changeDevSetting("grid_spacing=spacious")
        if !waitUntil(10, { abs(cardGap() - tight - 12) < 1 }) {
            fail("spacious cards stand \(cardGap()) apart, tight ones \(tight)")
        }
        shot("grid spacing spacious")
    }

    /// The gap between the grid's first card and the one beside it.
    private func cardGap() -> CGFloat {
        let cards = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND NOT identifier ENDSWITH '.menu'"))
        let first = cards.element(boundBy: 0).frame
        for index in 1..<min(cards.count, 12) {
            let next = cards.element(boundBy: index).frame
            if abs(next.minY - first.minY) < 1, next.minX > first.maxX { return next.minX - first.maxX }
        }
        fail("no card beside the first")
        return 0
    }
    #endif

    // MARK: - Filters

    #if os(tvOS)
    /// On Apple TV the filters' menu applies each pick at once: a yes/no field's submenu picks Yes, a value
    /// list's submenu stays open while a value is toggled, Clear all clears them both.
    func testFilterMenuAppliesEachPick() throws {
        try launch()
        steps.pickLibrary("Movies")
        require("libraries.grid", timeout: 30, "the Browse grid")

        openFilters()
        // Lets the menu finish opening before the shot.
        sleep(1)
        shot("filters menu")
        steps.tvSelect(require("libraries.filter.unwatched", "the Unwatched field"))
        XCTAssertTrue(steps.option("libraries.filter.unwatched").exists(within: 10), "the Unwatched submenu")
        // Lets the submenu finish opening before the shot.
        sleep(1)
        shot("unwatched submenu")
        steps.pickOption("libraries.filter.unwatched", label: "Yes")
        XCTAssertTrue(waitUntil(10) { filtersLabel().contains("(1)") }, "Yes applied at once: \(filtersLabel())")

        openFilters()
        steps.tvSelect(require("libraries.filter.genre", "the Genre field"))
        let test = steps.option("libraries.filter.genre", label: "Test")
        XCTAssertTrue(test.exists(within: 10), "the Genre submenu's Test")
        steps.tvSelect(test)
        XCTAssertTrue(waitUntil(10) { filtersLabel().contains("(2)") }, "Test applied at once: \(filtersLabel())")
        XCTAssertTrue(waitUntil(5) { test.exists && test.identifier.contains(".selected") }, "the submenu stays open, Test checked")
        // Lets the toggle's check draw before the shot.
        sleep(1)
        shot("genre toggled")
        XCUIRemote.shared.press(.menu)
        // Paces the two Menu presses: the second is dropped while the submenu closes.
        sleep(1)
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(test.waitForNonExistence(timeout: 10), "Menu closes the menus")

        openFilters()
        steps.tvSelect(require("libraries.filters.clear", "Clear all"))
        XCTAssertTrue(waitUntil(10) { !filtersLabel().contains("(") }, "Clear all applied: \(filtersLabel())")
        shot("filters cleared")
    }
    #else
    /// A filter edit commits when the editor closes by a swipe, Apply or Escape; a yes/no
    /// field steps Any, Yes, No (the Mac: a menu). Mac: a field's page opens in the popover and Back returns to the
    /// fields, its pick staged with the others.
    func testFilterEditsCommitOnDismissal() throws {
        try launch()
        steps.pickLibrary("Movies")
        require("libraries.grid", timeout: 30, "the Browse grid")

        openFilters()
        let unwatched = require("libraries.filter.unwatched", "the Unwatched field")
        #if os(macOS)
        steps.press(unwatched)
        let yes = app.menuItems["Yes"]
        XCTAssertTrue(yes.exists(within: 5), "the Unwatched menu's Yes")
        yes.click()
        XCTAssertTrue(waitUntil(5) { (unwatched.value as? String) == "Yes" }, "the menu picks Yes")
        #else
        steps.press(unwatched)
        XCTAssertTrue(waitUntil(5) { (unwatched.value as? String) == "Yes" }, "a press steps Any to Yes")
        #endif
        // Lets the field's change draw before the shot.
        sleep(1)
        shot("filter staged")
        #if os(macOS)
        steps.press(require("libraries.filter.genre", "the Genre field"))
        steps.press(require("libraries.value.Test", "the Genre page's Test"))
        sleep(1)
        shot("filter genre page")
        steps.press(require("libraries.filters.back", "the page's Back"))
        XCTAssertTrue(unwatched.exists(within: 5), "Back returns to the fields")
        let committed = "(2)"
        #else
        let committed = "(1)"
        #endif
        closeEditor(unwatched, swipe: true)
        XCTAssertTrue(waitUntil(10) { filtersLabel().contains(committed) }, "the edits committed as the editor closed")
        shot("filter committed")

        openFilters()
        let clear = require("libraries.filters.clear", "Clear all")
        steps.press(clear)
        closeEditor(unwatched, swipe: false)
        XCTAssertTrue(waitUntil(10) { !filtersLabel().contains("(") }, "clearing committed as the editor closed")
    }
    #endif

    // MARK: - Alphabet

    /// The alphabet index. iPhone, iPad, Apple TV: it sits in the grid's trailing margin, taking no
    /// lane: the cards run to the screen's side (Apple TV: its safe area) and never under the index. The Mac: it sits a
    /// whole side (24 pt) in from the window's edge and its bottom, clear of the rounded corner, the cards a side before
    /// it. iPhone and iPad: a drag down it ends on the letter under the finger. Mac: Down after a letter moves to the
    /// next one. Apple TV: Back from the index goes to the grid. iPhone, iPad and the Mac: a letter no title starts with
    /// (Jellyfin) leaves a message naming it beside the index, the letter marked, and picked again it clears.
    func testAlphabetIndex() throws {
        try launch()
        steps.pickLibrary("Movies")
        require("libraries.grid", timeout: 30, "the Browse grid")
        let z = require("libraries.alpha.Z", timeout: 20, "the index's Z")
        let zulu = steps.card(prefix: "Zulu")
        let index = element("libraries.alpha").frame
        let window = app.windows.firstMatch.frame
        let rowEnd = firstRowEnd()
        XCTAssertGreaterThanOrEqual(index.minX, rowEnd - 1, "the index clears the first row's last card")
        #if os(macOS)
        XCTAssertGreaterThanOrEqual(window.maxX - index.maxX, 23, "the index a side in from the window's edge")
        XCTAssertGreaterThanOrEqual(window.maxY - index.maxY, 23, "the index a side above the window's bottom")
        XCTAssertGreaterThanOrEqual(index.minX - rowEnd, 23, "the cards a side before the index")
        #else
        #if os(tvOS)
        let margin: CGFloat = 80
        #else
        let margin: CGFloat = 24
        #endif
        XCTAssertLessThanOrEqual(window.maxX - rowEnd, margin + 2, "the cards run to the screen's side")
        #endif
        shot("alphabet index in the margin")
        #if os(iOS)
        let m = require("libraries.alpha.M", "the index's M")
        m.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.1, thenDragTo: z.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertTrue(zulu.exists(within: 15), "the drag ends on Z")
        shot("alphabet dragged to Z")
        #elseif os(macOS)
        require("libraries.alpha.Y", "the index's Y").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        sleep(2)
        app.typeKey(.downArrow, modifierFlags: [])
        XCTAssertTrue(zulu.exists(within: 15), "Down moves from Y to Z")
        shot("alphabet key down to Z")
        #else
        steps.tvFocus([(.down, 2), (.right, 12)]) { steps.focused(prefix: "libraries.alpha.") }
        steps.tvFocus([(.down, 30)]) { z.hasFocus }
        XCTAssertTrue(zulu.exists(within: 15), "the Z titles")
        // The focus engine drops a press made while the grid still reloads under Z.
        sleep(2)
        XCUIRemote.shared.press(.menu)
        XCTAssertNotNil(steps.focusedCard(within: 5), "Back from the index goes to the grid")
        XCTAssertTrue(element("libraries.screen").exists, "Back stays in Libraries")
        shot("back from the index")
        #endif
        #if !os(tvOS)
        let hash = require("libraries.alpha.#", "the index's #")
        #if os(macOS)
        hash.click()
        #else
        hash.tap()
        #endif
        XCTAssertTrue(app.staticTexts["No titles start with #"].exists(within: 15), "the message names the letter")
        XCTAssertTrue(element("libraries.alpha").exists, "the index stays")
        XCTAssertTrue(hash.isSelected, "# is marked")
        let named = require("libraries.letterFilter", timeout: 10, "'Starting with # · Clear' over the grid")
        XCTAssertTrue(named.label.hasPrefix("Starting with #"), "it names the letter: \(named.label)")
        shot("alphabet letter with no titles")
        #if os(macOS)
        hash.click()
        #else
        hash.tap()
        #endif
        XCTAssertTrue(steps.card(prefix: "Alpha Archive").exists(within: 30), "# picked again clears it")
        shot("alphabet letter cleared")
        XCTAssertTrue(element("libraries.letterFilter").waitForNonExistence(timeout: 10), "no letter control once cleared")
        #if os(macOS)
        hash.click()
        #else
        hash.tap()
        #endif
        let clear = require("libraries.letterFilter", timeout: 15, "'Starting with # · Clear' again")
        #if os(macOS)
        clear.click()
        #else
        clear.tap()
        #endif
        XCTAssertTrue(steps.card(prefix: "Alpha Archive").exists(within: 30), "its Clear lists everything again")
        XCTAssertFalse(hash.isSelected, "# no longer marked")
        shot("alphabet letter cleared by its control")
        #endif
    }

    #if os(iOS)
    /// An index too short for a 20 pt row per letter (a landscape phone) draws some letters and a dot for each
    /// run between them, every row at least 20 pt; a drag ending in a run's row on one of its letters picks it, the row
    /// showing it marked, no row moved; a tap on that row picks it again and clears it.
    func testAShortIndexReachesTheLettersItDoesNotDraw() throws {
        try launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
        steps.pickLibrary("Movies")
        require("libraries.grid", timeout: 30, "the Browse grid")
        require("libraries.alpha.Z", timeout: 20, "the index's Z")
        // Lets the index lay out again after the rotation before its rows' frames are read.
        sleep(2)
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'libraries.alpha.'")).allElementsBoundByIndex
        guard let run = rows.first(where: { $0.identifier.contains("-") }) else {
            throw XCTSkip("the index has a row for every letter here")
        }
        shot("short index")
        // A row's element is its letter's frame; the rows' pitch is their height.
        let middles = rows.map(\.frame.midY)
        let frames = rows.map { "\($0.identifier) \($0.frame)" }.joined(separator: "; ")
        for (above, below) in zip(middles, middles.dropFirst()) {
            XCTAssertGreaterThanOrEqual(below - above, 19.5, "rows at least 20 pt apart: \(frames)")
        }
        let alphabet = ["#"] + (UnicodeScalar("A").value...UnicodeScalar("Z").value).map { String(UnicodeScalar($0)!) }
        let ends = run.identifier.dropFirst("libraries.alpha.".count).split(separator: "-").map(String.init)
        let letters = Array(alphabet[alphabet.firstIndex(of: ends[0])!...alphabet.firstIndex(of: ends[1])!])
        let target = letters.count / 2
        let pitch = middles[1] - middles[0]
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = origin.withOffset(CGVector(dx: rows[0].frame.midX, dy: middles[0]))
        let y = run.frame.midY - pitch / 2 + (CGFloat(target) + 0.5) / CGFloat(letters.count) * pitch
        let end = origin.withOffset(CGVector(dx: run.frame.midX, dy: y))
        start.press(forDuration: 0.1, thenDragTo: end)
        XCTAssertTrue(waitUntil(15) { run.isSelected }, "\(letters[target]) marked in its run's row")
        let after = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'libraries.alpha.'")).allElementsBoundByIndex
        XCTAssertEqual(after.map(\.identifier), rows.map(\.identifier), "no row moved")
        shot("short index letter picked")
        run.tap()
        XCTAssertTrue(steps.card(prefix: "Alpha Archive").exists(within: 30), "\(letters[target]) picked again clears it")
        shot("short index letter cleared")
    }
    #endif

    // MARK: - Folders

    /// A plain folder's menu (a long press, a right click; Apple TV: a held Select) offers Play and Shuffle.
    func testFolderMenu() throws {
        try launch()
        steps.pickLibrary("Home Videos")
        require("libraries.folders", timeout: 30, "the folder tree")
        let row = require("libraries.folder.Holiday 2026", timeout: 20, "a folder row")
        // Lets the rows finish drawing before the shot.
        sleep(1)
        shot("folder rows")
        #if os(macOS)
        row.rightClick()
        #elseif os(iOS)
        row.press(forDuration: 1.0)
        #else
        steps.tvFocus([(.down, 3)]) { row.hasFocus }
        XCUIRemote.shared.press(.select, forDuration: 1.2)
        #endif
        require("libraries.folder.menu.play", timeout: 10, "the folder menu's Play")
        require("libraries.folder.menu.shuffle", "the folder menu's Shuffle")
        shot("folder menu")
        steps.dismissMenu()
        XCTAssertTrue(element("libraries.folder.menu.play").waitForNonExistence(timeout: 10), "the menu closes")
    }

    /// Browse grouped by folders keeps the header row's view menu and type, a folder opened too; from there the
    /// type groups the films again and the view menu still switches views.
    func testFoldersKeepTheViewMenuAndType() throws {
        executionTimeAllowance = 600
        try launch()
        steps.pickLibrary("Movies")
        require("libraries.grid", timeout: 30, "the Browse grid")
        // Lets the grid's artwork load before the shot; nothing signals it.
        sleep(2)
        shot("movies browse")
        steps.openFilterMenu("libraries.grouping")
        steps.pickOption("libraries.grouping", label: "Folders")
        require("libraries.folders", timeout: 30, "Movies' folder tree")
        // Lets the tree finish drawing before the shot.
        sleep(2)
        shot("movies by folders")
        requireViewMenuAndType("Movies by folders")
        steps.openFilterMenu("libraries.grouping")
        steps.pickOption("libraries.grouping", label: "Movies")
        XCTAssertTrue(steps.card(prefix: "Alpha Archive").exists(within: 30), "the type groups the films again")
        shot("movies by movies")

        steps.pickLibrary("Home Videos")
        steps.showLibraryTab("browse")
        let folder = require("libraries.folder.Holiday 2026", timeout: 30, "the Holiday 2026 folder")
        #if os(tvOS)
        steps.tvFocus([(.down, 3)]) { folder.hasFocus }
        XCUIRemote.shared.press(.select)
        #else
        steps.press(folder)
        #endif
        require("libraries.folder.Beach Day", timeout: 20, "the folder's subfolder")
        // Lets the folder finish expanding before the shot.
        sleep(1)
        shot("a folder open")
        requireViewMenuAndType("a folder open")
        steps.showLibraryTab("collections")
        XCTAssertTrue(waitUntil(20) { viewMenuNames("Collections") }, "the view menu shows Collections")
        XCTAssertTrue(element("libraries.grouping").waitForNonExistence(timeout: 20), "the type leaves with Browse")
        shot("collections from folders")
        steps.showLibraryTab("browse")
        XCTAssertTrue(waitUntil(20) { viewMenuNames("Browse") }, "the view menu shows Browse again")
        requireViewMenuAndType("back on Browse")
        require("libraries.folder.Holiday 2026", timeout: 30, "the folders again")
        shot("back on browse")
    }

    /// The view menu names `view` (iOS and Apple TV in its label, the Mac in its title).
    private func viewMenuNames(_ view: String) -> Bool {
        let menu = element("libraries.view")
        return menu.label.contains(view) || menu.title.contains(view)
    }

    /// The header row holds the view menu and the type, each drawn (but on Apple TV, where focus reaches them) where it
    /// can be pressed.
    private func requireViewMenuAndType(_ when: String) {
        for id in ["libraries.view", "libraries.grouping"] {
            let control = element(id)
            #if os(tvOS)
            let shown = { control.exists && !control.frame.isEmpty }
            #else
            let shown = { control.exists && control.isHittable }
            #endif
            XCTAssertTrue(waitUntil(10, shown), "\(when): \(id) in the header row")
        }
    }

    // MARK: - Manage libraries

    /// Manage libraries (Libraries' ⋯; Apple TV: the header row's button): an administrator's library menu
    /// offers its admin actions; Scan asks first, then runs.
    func testAdminScanAsksFirst() throws {
        try launch()
        steps.openManageLibraries()
        let row = libraryRow("Movies")
        XCTAssertTrue(row.exists(within: 20), "Movies' row")
        shot("manage libraries admin")
        openRowMenu(row)
        let scan = require("\(row.identifier).scan", timeout: 10, "Scan library files")
        shot("admin menu")
        #if os(tvOS)
        steps.tvFocus { steps.hasFocus(scan) }
        XCUIRemote.shared.press(.select)
        #else
        steps.press(scan)
        #endif
        let confirm = require("libraries.admin.confirm", timeout: 10, "the scan's confirmation")
        shot("admin confirm")
        #if os(tvOS)
        steps.tvFocus { steps.hasFocus(confirm) }
        XCUIRemote.shared.press(.select)
        #else
        steps.press(confirm)
        #endif
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 10), "confirming closes the question")
        // Lets the question finish closing before the shot.
        sleep(1)
        shot("scan started")
    }

    /// A user who doesn't administer the server gets no admin actions.
    func testNoAdminMenuForAGuest() throws {
        try launch(server: try steps.libraryServer().replacingOccurrences(of: "maestro:maestro@", with: "guest:guest@"))
        steps.openManageLibraries()
        let row = libraryRow("Guest Movies")
        XCTAssertTrue(row.exists(within: 20), "the guest's library")
        openRowMenu(row)
        // Gives admin entries time to show before checking there are none.
        sleep(1)
        shot("manage libraries guest")
        XCTAssertFalse(element("\(row.identifier).scan").exists, "no admin actions")
        steps.dismissMenu()
    }

    #if os(macOS) || os(tvOS)
    /// A collection's page names itself in its heading; the window's toolbar (Apple TV's bar) shows no second title.
    func testCollectionTitleOnce() throws {
        try launch()
        steps.pickLibrary("Movies")
        steps.showLibraryTab("collections")
        let picks = steps.card(prefix: "Plezy Picks")
        XCTAssertTrue(picks.exists(within: 30), "the collection Plezy Picks")
        steps.press(picks)
        require("collection.screen", timeout: 30, "Plezy Picks' screen")
        XCTAssertTrue(app.staticTexts["Plezy Picks"].exists(within: 30), "the page's heading")
        // Gives a toolbar title time to show before counting titles; the shot waits for artwork too.
        sleep(3)
        shot("collection top")
        let titles = app.descendants(matching: .any).matching(NSPredicate(format: "label == 'Plezy Picks' OR value == 'Plezy Picks'"))
        XCTAssertEqual(titles.count, 1, "the heading alone names the page, no title in the toolbar")
    }
    #endif

    #if os(tvOS)
    /// Up from the first row of Collections, Genres and the folder tree goes to the header row.
    func testUpFromTheFirstRowToTheHeader() throws {
        try launch()
        steps.pickLibrary("Movies")
        steps.showLibraryTab("collections")
        let picks = steps.card(prefix: "Plezy Picks")
        XCTAssertTrue(picks.exists(within: 30), "the collection Plezy Picks")
        steps.tvFocus([(.down, 2)]) { picks.hasFocus }
        XCUIRemote.shared.press(.up)
        XCTAssertTrue(waitUntil(5) { steps.headerFocused }, "Up from Collections' first row reaches the header row")
        shot("collections up to the header")

        steps.showLibraryTab("genres")
        let genre = steps.prefixed("libraries.genre.")
        XCTAssertTrue(genre.exists(within: 30), "a genre tile")
        steps.tvFocus([(.down, 2)]) { steps.focused(prefix: "libraries.genre.") }
        XCUIRemote.shared.press(.up)
        XCTAssertTrue(waitUntil(5) { steps.headerFocused }, "Up from Genres' first row reaches the header row")
        shot("genres up to the header")

        steps.pickLibrary("Home Videos")
        steps.showLibraryTab("browse")
        let folder = require("libraries.folder.Holiday 2026", timeout: 30, "the folder tree's first row")
        steps.tvFocus([(.down, 3)]) { folder.hasFocus }
        XCUIRemote.shared.press(.up)
        XCTAssertTrue(waitUntil(5) { steps.headerFocused }, "Up from the folder tree's first row reaches the header row")
        shot("folders up to the header")
    }

    /// Down from the row above a short last row lands on its last card, and Down from a last row stays
    /// on it: Browse (Codec Samples' 16 films, a last row shorter than the others), Genres' one row, the folder tree.
    func testDownFromAShortLastRow() throws {
        try launch()
        steps.pickLibrary("Codec Samples")
        XCTAssertTrue(steps.card(prefix: "Codec ASS Subtitles").exists(within: 30), "the first film")
        // Opened on Browse, no tab switch moves focus into the grid: from the header, Down enters it.
        steps.tvFocus([(.down, 2)]) { focusedCard()?.hasPrefix("Codec ASS Subtitles") == true }
        XCTAssertTrue(waitUntil(15) { focusedCard()?.hasPrefix("Codec ASS Subtitles") == true }, "focus on the first film")
        var columns = 1
        while columns < 12, move(.right) { columns += 1 }
        XCTAssertNotEqual(16 % columns, 0, "the last row is short (\(columns) columns)")
        var rows = 1
        while rows < 8, move(.down) { rows += 1 }
        XCTAssertEqual(rows, (16 + columns - 1) / columns, "Down goes row by row to the last")
        XCTAssertEqual(focusedCard()?.hasPrefix("Codec TrueHD"), true, "Down from the last column lands on the short last row's last card")
        shot("down to the short last row")
        XCUIRemote.shared.press(.down)
        // Gives a stray focus move time to show before checking focus stayed.
        sleep(1)
        XCTAssertEqual(focusedCard()?.hasPrefix("Codec TrueHD"), true, "Down from the last row stays on it")

        steps.pickLibrary("Movies")
        steps.showLibraryTab("genres")
        XCTAssertTrue(steps.prefixed("libraries.genre.").exists(within: 30), "a genre tile")
        steps.tvFocus([(.down, 2)]) { steps.focused(prefix: "libraries.genre.") }
        XCUIRemote.shared.press(.down)
        // Gives a stray focus move time to show before checking focus stayed.
        sleep(1)
        XCTAssertTrue(steps.focused(prefix: "libraries.genre."), "Down from Genres' only row stays on its tiles")
        shot("genres down from the last row")

        steps.pickLibrary("Home Videos")
        steps.showLibraryTab("browse")
        let folder = require("libraries.folder.Holiday 2026", timeout: 30, "the folder tree's first row")
        steps.tvFocus([(.down, 3)]) { folder.hasFocus }
        for _ in 0..<4 {
            XCUIRemote.shared.press(.down)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(500_000)
        }
        XCTAssertTrue(steps.focused(prefix: "libraries.folder."), "Down from the folder tree's last row stays on its rows")
        shot("folders down from the last row")
    }

    /// A live refetch that moves the focused card's item keeps focus on the item. The test server sorts an
    /// earlier film last (its sort title put back after); its push reaches the app about 30 s later, and the refetch
    /// moves every later film one place back, the focused one with them. The server holds its pushes while a library
    /// refreshes (another test's scan), so the test starts once none does.
    func testFocusFollowsItsItemAcrossALiveRefetch() throws {
        let server = try ServerAdmin(devServer: steps.libraryServer())
        XCTAssertTrue(server.idle(within: 300), "the test server's libraries done refreshing")
        let moved = try XCTUnwrap(server.itemId(named: "Codec AV1 HDR10"), "the test server's Codec AV1 HDR10")
        XCTAssertTrue(server.setSortTitle(moved, "Codec AV1 HDR10"), "its sort title as seeded")
        addTeardownBlock { _ = server.setSortTitle(moved, "Codec AV1 HDR10") }
        try launch()
        steps.pickLibrary("Codec Samples")
        let second = steps.card(prefix: "Codec AV1 HDR10")
        let third = steps.card(prefix: "Codec Dolby Vision P5")
        XCTAssertTrue(third.exists(within: 30), "the films")
        // Opened on Browse, no tab switch moves focus into the grid: from the header, Down enters it.
        steps.tvFocus([(.down, 2)]) { focusedCard()?.hasPrefix("Codec ASS Subtitles") == true }
        XCTAssertTrue(waitUntil(15) { focusedCard()?.hasPrefix("Codec ASS Subtitles") == true }, "focus on the first film")
        XCTAssertTrue(move(.down) && move(.right), "focus moves into the second row")
        XCTAssertEqual(focusedCard()?.hasPrefix("Codec H264 SDR"), true, "focus on Codec H264 SDR")
        let secondX = second.frame.minX
        XCTAssertTrue(server.setSortTitle(moved, "zzz Codec AV1 HDR10"), "the server sorts Codec AV1 HDR10 last")
        // The server pushes the change about 30 s later; the tab refetches at most every 2 minutes, counted from its load.
        XCTAssertTrue(waitUntil(210) { abs(third.frame.minX - secondX) < 2 }, "the live refetch moves the films after it back")
        // Gives a stray focus jump after the refetch time to show before checking focus stayed.
        sleep(2)
        XCTAssertEqual(focusedCard()?.hasPrefix("Codec H264 SDR"), true, "focus stays on Codec H264 SDR, now a place earlier")
        shot("focus after the live refetch")
    }

    /// Down from the header row, from either end, reaches Browse's error state's Retry, and Retry loads the items again:
    /// a proxy answers the items 404 until the error shows.
    func testDownFromTheHeaderReachesBrowsesRetry() throws {
        let spec = try steps.libraryServer()
        guard let upstream = ServerProxy.upstream(of: spec), let proxy = ServerProxy(upstream: upstream) else {
            return fail("no proxy on the loopback in front of \(spec)")
        }
        addTeardownBlock { proxy.stop() }
        proxy.respondNotFound(pathContaining: "/Items")
        try launch(server: proxy.server(for: spec))
        steps.pickLibrary("Movies")
        let retry = require("state.retry", timeout: 30, "Browse's error state")
        proxy.clearRules()
        for (id, what) in [("libraries.library", "the library menu"), ("libraries.refresh", "Refresh")] {
            steps.tvFocusHeader(require(id, what))
            shot("browse error, focus on \(id)")
            XCUIRemote.shared.press(.down)
            XCTAssertTrue(waitUntil(5) { retry.hasFocus }, "Down from \(what) reaches Retry")
            shot("down from \(id)")
        }
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(steps.card(prefix: "Alpha Archive").exists(within: 30), "Retry loads the films")
        XCTAssertFalse(retry.exists, "the error state gone")
        shot("browse after retry")
    }

    /// The label of the card holding focus.
    private func focusedCard() -> String? {
        let card = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'card.'")).firstMatch
        return card.exists ? card.label : nil
    }

    /// Presses `button`; whether focus moved to another card.
    private func move(_ button: XCUIRemote.Button) -> Bool {
        let before = focusedCard()
        XCUIRemote.shared.press(button)
        return waitUntil(2) { focusedCard().map { $0 != before } ?? false }
    }
    #endif

    // MARK: - Steps

    private var steps: LibrarySteps { LibrarySteps(test: self) }

    private func launch(server: String? = nil) throws {
        launchDev(arguments: ["--dev-server", try server ?? steps.libraryServer(), "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
    }

    private func openFilters() {
        steps.pressInHeader("libraries.filters", "the Filters capsule")
        XCTAssertTrue(steps.prefixed("libraries.filter.").exists(within: 10), "the filter editor")
    }

    #if !os(tvOS)
    /// Closes the filter editor: a swipe down or its Apply (iPhone, iPad), Escape (the Mac).
    private func closeEditor(_ inside: XCUIElement, swipe: Bool) {
        #if os(iOS)
        if swipe {
            element("libraries.filters.sheet").swipeDown(velocity: .fast)
        } else {
            steps.press(require("libraries.filters.apply", "the sheet's Apply"))
        }
        #else
        app.typeKey(.escape, modifierFlags: [])
        #endif
        XCTAssertTrue(inside.waitForNonExistence(timeout: 10), "the editor closed")
        // Lets the editor finish closing; a press during it is dropped.
        sleep(1)
    }
    #endif

    /// The Filters capsule's label ("Filters: Filters (1)").
    private func filtersLabel() -> String {
        element("libraries.filters").label
    }

    /// Whether the card first in the grid is `title`'s.
    private func firstCard(is title: String) -> Bool {
        waitUntil(30) {
            let first = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
            return first.exists && first.label.hasPrefix(title)
        }
    }

    /// Where the grid's first row ends: its last card's trailing edge, once the cards have loaded.
    private func firstRowEnd() -> CGFloat {
        let cards = element("libraries.grid").descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'"))
        XCTAssertTrue(cards.firstMatch.exists(within: 30), "the grid's cards")
        // Lets the first row fill in before its frames are read; no count marks it full.
        sleep(1)
        let first = cards.firstMatch.frame
        return cards.allElementsBoundByIndex.map(\.frame).filter { abs($0.midY - first.midY) < first.height / 2 }.map(\.maxX).max() ?? first.maxX
    }

    /// Manage libraries' row of `library`.
    private func libraryRow(_ library: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'settings.libraries.row.' AND NOT (identifier CONTAINS '.up') AND label BEGINSWITH %@", library))
            .firstMatch
    }

    /// The row's context menu: a long press, a right click, a held Select.
    private func openRowMenu(_ row: XCUIElement) {
        #if os(macOS)
        row.rightClick()
        #elseif os(iOS)
        row.press(forDuration: 1.0)
        #else
        steps.tvFocus([(.down, 12), (.up, 12)]) { steps.hasFocus(row) }
        XCUIRemote.shared.press(.select, forDuration: 1.2)
        #endif
    }

    #if os(iOS)
    /// The view menu names `label` as the view shown.
    private func viewShown(_ label: String) -> Bool {
        element("libraries.view").label.hasSuffix(label)
    }

    private func visible(_ element: XCUIElement) -> Bool {
        steps.onScreen(element) && element.isHittable
    }

    /// A horizontal swipe across the content, from and to those fractions of its width.
    private func swipe(from start: CGFloat, to end: CGFloat) {
        let screen = element("libraries.screen")
        screen.coordinate(withNormalizedOffset: CGVector(dx: start, dy: 0.6))
            .press(forDuration: 0.05, thenDragTo: screen.coordinate(withNormalizedOffset: CGVector(dx: end, dy: 0.6)))
    }

    /// A pull down from the content, far past the refresh threshold, let go at once.
    private func pull(_ element: XCUIElement) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 600)), withVelocity: XCUIGestureVelocity(1200), thenHoldForDuration: 0.3)
    }
    #endif
}

/// The test server's API as the development session's account (`--dev-server`'s `<kind>=<user>:<password>@<url>`):
/// a film's sort title set and put back. Jellyfin and Emby take the same calls.
private struct ServerAdmin: Sendable {
    let base: String
    let token: String
    let user: String

    init(devServer: String) throws {
        let spec = devServer.split(separator: "=", maxSplits: 1).last.map(String.init) ?? devServer
        let at = try XCTUnwrap(spec.lastIndex(of: "@"), "an account in \(devServer)")
        let account = spec[..<at].split(separator: ":", maxSplits: 1).map(String.init)
        base = String(spec[spec.index(after: at)...])
        let auth = try XCTUnwrap(
            Self.call(base, nil, "POST", "/Users/AuthenticateByName", ["Username": account.first ?? "", "Pw": account.last ?? ""]),
            "a sign-in to \(base)"
        )
        token = try XCTUnwrap(auth["AccessToken"] as? String, "a token")
        user = try XCTUnwrap((auth["User"] as? [String: Any])?["Id"] as? String, "a user id")
    }

    /// Whether every library is done refreshing within `seconds`, looked at every 5 seconds.
    func idle(within seconds: Int) -> Bool {
        for _ in 0..<(seconds / 5) {
            let folders = Self.call(base, token, "GET", "/Library/VirtualFolders", nil)?["list"] as? [[String: Any]] ?? []
            if !folders.isEmpty, folders.allSatisfy({ ($0["RefreshStatus"] as? String ?? "Idle") == "Idle" && $0["RefreshProgress"] == nil }) {
                return true
            }
            // Polls the server's API, off the main actor, at its own pace.
            Thread.sleep(forTimeInterval: 5)
        }
        return false
    }

    /// The film titled `name`.
    func itemId(named name: String) -> String? {
        let term = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let found = Self.call(base, token, "GET", "/Users/\(user)/Items?Recursive=true&IncludeItemTypes=Movie&SearchTerm=\(term)", nil)
        return (found?["Items"] as? [[String: Any]])?.first { $0["Name"] as? String == name }?["Id"] as? String
    }

    /// Sets the item's sort title (the server's push of the change follows); whether the server took it.
    func setSortTitle(_ id: String, _ title: String) -> Bool {
        guard let item = Self.call(base, token, "GET", "/Users/\(user)/Items/\(id)?Fields=Genres,Tags,People,Studios,ProviderIds,LockedFields,Taglines", nil) else {
            return false
        }
        var body: [String: Any] = ["Id": id, "ForcedSortName": title]
        for key in ["Name", "Overview", "ProductionYear", "PremiereDate", "OfficialRating"] { body[key] = item[key] }
        for key in ["Genres", "Tags", "People", "Studios", "LockedFields", "Taglines"] { body[key] = item[key] ?? [Any]() }
        body["ProviderIds"] = item["ProviderIds"] ?? [String: Any]()
        return Self.call(base, token, "POST", "/Items/\(id)", body) != nil
    }

    /// `method` `path` waited for: its JSON answer (empty for none; an array as `list`), nil when it failed.
    private static func call(_ base: String, _ token: String?, _ method: String, _ path: String, _ body: [String: Any]?) -> [String: Any]? {
        var request = URLRequest(url: URL(string: base + path)!, timeoutInterval: 15)
        request.httpMethod = method
        request.setValue("MediaBrowser Client=\"Plezy UI tests\", Device=\"ui-tests\", DeviceId=\"plezy-ui-tests-libraries\", Version=\"1\"", forHTTPHeaderField: "X-Emby-Authorization")
        if let token { request.setValue(token, forHTTPHeaderField: "X-Emby-Token") }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        let done = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var answer: [String: Any]?
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) {
                let json = data.flatMap { try? JSONSerialization.jsonObject(with: $0) }
                answer = (json as? [Any]).map { ["list": $0] } ?? json as? [String: Any] ?? [:]
            }
            done.signal()
        }.resume()
        done.wait()
        return answer
    }
}
