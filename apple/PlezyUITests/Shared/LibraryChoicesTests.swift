#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import XCTest

/// Choices on Libraries' header and View all's sort, against the server `PLEZY_DEV_SERVER` names: Browse's header
/// controls drawn as a symbol alone draw it in their middle, in one row of equal gaps, heights and centres (iPhone,
/// iPad, the Mac), and give way in order as the row narrows (the Mac's window, iPad's text size); the Filters sheet's
/// Cancel drops its edits, Apply and a swipe down commit them (iPhone, iPad); View
/// all's sort offers Clear, Ascending and Descending once an order is set, and another field keeps the direction.
final class LibraryChoicesTests: PlezyUITestCase {
    private var steps: LibrarySteps { LibrarySteps(test: self) }

    private func launch(_ destination: String) throws {
        launchDev(arguments: ["--dev-server", try steps.libraryServer(), "--dev-open", destination])
    }

    // MARK: - Header icons

    #if !os(tvOS)
    /// Every header control of Browse drawn as a symbol alone (a round button) draws its glyph within 1 pt of its
    /// middle and is as wide as it is tall, all of them one size; the controls of each line (the actions at its end
    /// included) share their height and their vertical centre (0.5 pt: rounding only), the Mac's library title (a text,
    /// no control) their centre, and neighbours stand equal gaps apart (1 pt). Every control reports one frame (the
    /// Mac's menus included); on iOS, where iOS gives a control its container's frame, the button inside it is measured.
    func testHeaderButtonsDrawTheirIconsInTheirMiddle() throws {
        continueAfterFailure = true
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        steps.showLibraryTab("browse")
        require("libraries.grid", timeout: 30, "the Browse grid")
        // Back to the row's start where a phone's filters scroll sideways.
        steps.pressInHeader("libraries.view", "the view menu")
        steps.dismissMenu()
        // Lets the row scroll back to rest before the shot and the frames are read.
        sleep(2)
        shot("browse header")
        let ids = [
            "libraries.library", "libraries.view", "libraries.sort", "libraries.filters", "libraries.grouping",
            "libraries.shuffle", "libraries.more",
        ]
        let window = app.windows.firstMatch.frame
        var controls: [(id: String, frame: CGRect)] = []
        var round: [(id: String, frame: CGRect)] = []
        var report: [String] = []
        for id in ids {
            let control = element(id)
            guard control.exists else { report.append("\(id): absent"); continue }
            var target = control
            #if os(iOS)
            // iOS 27.0 now and then gives an element its container's accessibility frame for a whole launch, VoiceOver's
            // too: the ⋯ the header bar's (1032 × 168 pt on iPad), a card's watched mark the card's. The button inside
            // it keeps the control's own frame there.
            let inner = control.buttons.firstMatch
            if control.frame.height >= 60, inner.exists, inner.frame.height < 60 {
                report.append("\(id): reported as \(control.frame), its button as \(inner.frame)")
                target = inner
            }
            #endif
            let frame = target.frame
            guard window.contains(frame) else { report.append("\(id): \(frame) outside the window"); continue }
            let parts = app.descendants(matching: .any).matching(identifier: id).count
            guard parts == 1 else {
                report.append("\(id): reported as \(parts) parts")
                fail("\(id) reports one frame, not \(parts)")
                continue
            }
            guard frame.height < 60 else {
                report.append("\(id): reported as \(frame)")
                fail("\(id) reports its own frame, not \(frame)")
                continue
            }
            if let overlapped = controls.first(where: { $0.frame.intersection(frame).width > 1 }) {
                report.append("\(id): \(frame) overlaps \(overlapped.id) \(overlapped.frame)")
                fail("\(id) \(frame) overlaps \(overlapped.id) \(overlapped.frame)")
                continue
            }
            controls.append((id, frame))
            guard let glyph = glyphBounds(of: target) else {
                report.append("\(id): \(frame) no glyph found")
                fail("\(id) shows no glyph in its screenshot")
                continue
            }
            // A symbol alone: its marks no wider than the control is tall (a label's text runs wider).
            guard glyph.width <= frame.height else { report.append("\(id): \(frame) labelled (marks \(round2(glyph.width)) pt wide)"); continue }
            round.append((id, frame))
            let offset = CGVector(dx: glyph.midX - frame.width / 2, dy: glyph.midY - frame.height / 2)
            report.append("\(id): \(frame) round, glyph \(round2(glyph.width))×\(round2(glyph.height)) off centre by \(round2(offset.dx)), \(round2(offset.dy)) pt")
            XCTAssertLessThanOrEqual(abs(offset.dx), 1, "\(id)'s glyph centred across: off by \(offset.dx) pt")
            XCTAssertLessThanOrEqual(abs(offset.dy), 1, "\(id)'s glyph centred down: off by \(offset.dy) pt")
            XCTAssertLessThanOrEqual(abs(frame.width - frame.height), 0.5, "\(id) is round: \(frame.size)")
        }
        if let first = round.first {
            for button in round.dropFirst() {
                XCTAssertLessThanOrEqual(
                    abs(button.frame.height - first.frame.height), 0.5,
                    "\(button.id) is \(button.frame.size), the size of \(first.id)'s \(first.frame.size)"
                )
            }
        }
        // The Mac names the library in a title, not a picker: text, which is as tall as its line.
        let titles = Set(controls.map(\.id).filter { app.staticTexts[$0].exists })
        // Lines: controls whose middles lie within 16 pt (a phone's name can stand on a line of its own).
        var lines: [[(id: String, frame: CGRect)]] = []
        for control in controls.sorted(by: { $0.frame.minX < $1.frame.minX }) {
            if let at = lines.firstIndex(where: { abs($0[0].frame.midY - control.frame.midY) < 16 }) {
                lines[at].append(control)
            } else {
                lines.append([control])
            }
        }
        for line in lines where line.count > 1 {
            let names = line.map(\.id).joined(separator: ", ")
            let heights = line.filter { !titles.contains($0.id) }.map(\.frame.height), middles = line.map(\.frame.midY)
            report.append("line [\(names)]: heights \(heights.map(round2)), midY \(middles.map(round2)), spread \(round2(middles.max()! - middles.min()!))")
            if let tallest = heights.max(), let lowest = heights.min() {
                XCTAssertLessThanOrEqual(tallest - lowest, 0.5, "[\(names)] share a height: \(heights)")
            }
            XCTAssertLessThanOrEqual(middles.max()! - middles.min()!, 0.5, "[\(names)] share a centre: \(middles)")
            // Neighbours at most 16 pt apart stand equal gaps apart; a wider gap starts the actions at the line's end.
            var group = [line[0]]
            var gapsOfGroups: [[CGFloat]] = []
            for control in line.dropFirst() {
                let gap = control.frame.minX - group.last!.frame.maxX
                if gap <= 16 { group.append(control) } else { gapsOfGroups.append(gaps(group)); group = [control] }
            }
            gapsOfGroups.append(gaps(group))
            for gaps in gapsOfGroups where gaps.count > 1 {
                XCTAssertLessThanOrEqual(gaps.max()! - gaps.min()!, 1, "[\(names)] stand equal gaps apart: \(gaps)")
            }
        }
        let measured = XCTAttachment(string: report.joined(separator: "\n"))
        measured.name = "header measurements.txt"
        measured.lifetime = .keepAlways
        add(measured)
        print("HEADER MEASUREMENTS\n" + report.joined(separator: "\n"))
    }

    private func gaps(_ group: [(id: String, frame: CGRect)]) -> [CGFloat] {
        zip(group, group.dropFirst()).map { $1.frame.minX - $0.frame.maxX }
    }

    /// The bounds of the marks `control` draws, in points from its top left: the bounding box of its pixels that differ
    /// strongly (a quarter of the luminance range) from the control's dominant fill, inside its round shape inset by
    /// 2.5 pt (clear of the glass rim). Nil where no such pixel is found.
    private func glyphBounds(of control: XCUIElement) -> CGRect? {
        let frame = control.frame
        #if os(macOS)
        guard let image = control.screenshot().image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        #else
        guard let image = control.screenshot().image.cgImage else { return nil }
        #endif
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let scale = CGFloat(width) / frame.width
        let shape = CGPath(
            roundedRect: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)).insetBy(dx: 2.5 * scale, dy: 2.5 * scale),
            cornerWidth: (min(CGFloat(width), CGFloat(height)) / 2 - 2.5 * scale), cornerHeight: (min(CGFloat(width), CGFloat(height)) / 2 - 2.5 * scale),
            transform: nil
        )
        var inside: [Int] = []
        var counts = [Int](repeating: 0, count: 256)
        for y in 0..<height {
            for x in 0..<width where shape.contains(CGPoint(x: CGFloat(x) + 0.5, y: CGFloat(y) + 0.5)) {
                inside.append(y * width + x)
                counts[Int(pixels[y * width + x])] += 1
            }
        }
        let fill = counts.indices.max { counts[$0] < counts[$1] } ?? 0
        var minX = width, maxX = -1, minY = height, maxY = -1
        for index in inside where abs(Int(pixels[index]) - fill) > 64 {
            let x = index % width, y = index / width
            minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        return CGRect(
            x: CGFloat(minX) / scale, y: CGFloat(minY) / scale,
            width: CGFloat(maxX - minX + 1) / scale, height: CGFloat(maxY - minY + 1) / scale
        )
    }

    private func round2(_ value: CGFloat) -> Double { (Double(value) * 100).rounded() / 100 }
    #endif

    #if os(tvOS)
    /// Apple TV's header actions, a round button each (Shuffle, Manage libraries, Refresh): one size whatever each
    /// symbol's shape, round, on one centre line.
    func testHeaderCirclesAreOneSize() throws {
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        let ids = ["libraries.shuffle", "libraries.manage", "libraries.refresh"]
        for id in ids { require(id, timeout: 30, "\(id) in the header") }
        // Lets the header finish laying out before the shot and the frames are read.
        sleep(2)
        shot("header circles")
        let frames = ids.map { element($0).frame }
        let report = zip(ids, frames).map { "\($0): \($1)" }.joined(separator: ", ")
        for (id, frame) in zip(ids, frames) {
            XCTAssertLessThanOrEqual(abs(frame.width - frame.height), 0.5, "\(id) is round: \(report)")
            XCTAssertLessThanOrEqual(abs(frame.height - frames[0].height), 0.5, "\(id) is Shuffle's size: \(report)")
            XCTAssertLessThanOrEqual(abs(frame.midY - frames[0].midY), 0.5, "\(id) shares Shuffle's centre: \(report)")
        }
    }
    #endif

    #if os(macOS)
    /// Q8 b on the Mac: as the window narrows, the header's buttons show their icons alone in order, the secondary ones
    /// first: Shuffle, then the ⋯, then the sort, the view, Filters and the type; the library's name is cut short only
    /// once all of those show their icons. Shot at the first width where only the actions show their icons alone, and
    /// at the narrowest the window goes.
    func testHeaderGivesWayInOrderAsTheWindowNarrows() throws {
        continueAfterFailure = true
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        steps.showLibraryTab("browse")
        require("libraries.grid", timeout: 30, "the Browse grid")
        sleep(2)
        let window = app.windows.firstMatch
        let order = ["libraries.shuffle", "libraries.more", "libraries.sort", "libraries.view", "libraries.filters", "libraries.grouping"]
        let picker = element("libraries.library")
        let name = picker.frame.width
        // An icon alone is under 50 pt wide; the narrowest with its title, the type's symbol and chevron, 59.
        let iconsAlone = { order.map { self.element($0).frame.width < 50 } }
        var shotActions = false
        var width = window.frame.width
        while true {
            let alone = iconsAlone()
            let state = "at \(Int(width)) pt: " + zip(order, alone).map { "\($0) \($1 ? "icon" : "titled")" }.joined(separator: ", ")
            for (index, icon) in alone.enumerated() where icon {
                XCTAssertTrue(alone[..<index].allSatisfy { $0 }, "\(order[index]) shows its icon alone before those ahead of it, \(state)")
            }
            if picker.frame.width < name - 1 {
                XCTAssertTrue(alone.allSatisfy { $0 }, "the name is cut short (\(picker.frame.width) of \(name) pt) while a button keeps its title, \(state)")
            }
            if !shotActions, alone[1], !alone[2] {
                shot("header actions as icons at \(Int(width))")
                shotActions = true
            }
            // The right edge 20 pt left; AppKit stops it at the window's least width. A drag that left the window as it
            // was is tried again lower down the edge (one stopped a run's sweep at 827 pt): the narrowest is where
            // none moves it.
            let narrowed = [0.5, 0.75, 0.9].contains { down in
                let edge = window.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: down)).withOffset(CGVector(dx: 1, dy: 0))
                edge.click(forDuration: 0.3, thenDragTo: edge.withOffset(CGVector(dx: -20, dy: 0)))
                sleep(1)
                return window.frame.width < width - 1
            }
            guard narrowed else { break }
            width = window.frame.width
        }
        shot("header at the narrowest, \(Int(width))")
        XCTAssertTrue(shotActions, "a width where only Shuffle and the ⋯ show their icons alone")
    }
    #endif

    #if os(iOS)
    /// At accessibility text size AX3 a phone's header row gives Shuffle, the sort and the view to the ⋯
    /// menu, which offers them there, and what stays in the row fits it: no control runs past the row's strip, so the
    /// row doesn't scroll.
    func testLargeTextHeaderPutsShuffleSortAndViewInTheMoreMenu() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else { throw XCTSkip("a phone's header row gives way to ⋯") }
        launchDev(arguments: [
            "--dev-server", try steps.libraryServer(), "--dev-open", "libraries",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL",
        ])
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        // A library opens on Browse; the view menu is in the ⋯ menu here.
        require("libraries.grid", timeout: 30, "the Browse grid")
        // Lets the header finish laying out before the shot and the frames are read.
        sleep(2)
        shot("ax3 header")
        let strip = require("header.filters", "the header's filters").frame
        for id in ["libraries.library", "libraries.filters", "libraries.grouping"] {
            let control = element(id)
            guard control.exists else { continue }
            XCTAssertTrue(strip.contains(control.frame), "\(id) \(control.frame) lies inside the row \(strip)")
        }
        let moved = ["libraries.shuffle", "libraries.sort", "libraries.view"]
        for id in moved {
            XCTAssertFalse(element(id).exists, "\(id) has left the row for the ⋯ menu")
        }
        require("libraries.more", "the ⋯ menu").tap()
        for id in moved {
            XCTAssertTrue(element(id).exists(within: 5), "the ⋯ menu offers \(id)")
        }
        shot("ax3 more menu")
        steps.dismissMenu()
    }
    #endif

    #if os(iOS)
    /// iPad's one-line header row at larger text sizes gives way in order, one form at a time: a filter shows its symbol
    /// alone (a circle) only once every one ranked ahead of it does (the sort, the view, Filters, then the type); at the
    /// largest size the sort shows its symbol alone; and the row settles, its controls where they were a second later,
    /// also after another library opens.
    func testIpadHeaderGivesWayInOrderAtLargeText() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPad's one-line header row") }
        let order = ["libraries.sort", "libraries.view", "libraries.filters", "libraries.grouping"]
        let sizes = ["UICTContentSizeCategoryAccessibilityM", "UICTContentSizeCategoryAccessibilityXXXL"]
        for size in sizes {
            launchDev(arguments: [
                "--dev-server", try steps.libraryServer(), "--dev-open", "libraries", "-UIPreferredContentSizeCategoryName", size,
            ])
            continueAfterFailure = true
            require("libraries.screen", timeout: 60, "Libraries")
            for library in ["Codec Samples", "Movies"] {
                steps.pickLibrary(library)
                require("libraries.grid", timeout: 30, "the Browse grid")
                let frames = { (order + ["libraries.library"]).map { self.element($0).frame } }
                let before = frames()
                sleep(1)
                let after = frames()
                shot("header \(library) \(size.dropFirst("UICTContentSizeCategory".count))")
                XCTAssertEqual(before, after, "the row settles on \(library) at \(size)")
                let round = after.prefix(order.count).map { abs($0.width - $0.height) <= 1 }
                let state = zip(order, zip(round, after)).map { "\($0) \($1.0 ? "symbol" : "whole") \(Int($1.1.width))" }
                    .joined(separator: ", ")
                for (index, alone) in round.enumerated() where alone {
                    XCTAssertTrue(round[..<index].allSatisfy { $0 }, "\(order[index]) shows its symbol alone before those ahead of it: \(state)")
                }
                if size == sizes.last {
                    XCTAssertTrue(round[0], "the sort shows its symbol alone at \(size): \(state)")
                }
            }
            app.terminate()
        }
    }
    #endif

    // MARK: - Filters sheet

    #if os(iOS)
    /// The Filters sheet's Cancel drops its staged edits (no count, the grid as it was); Apply commits them (a count of
    /// one, the grid narrowed to the favourites: the test server's Movies hold one, Chapters Movie, played or not); a
    /// swipe down commits as Apply does. Each change is cleared again (Clear all, Apply).
    func testFiltersSheetCancelDropsTheEditsAndApplyCommitsThem() throws {
        executionTimeAllowance = 600
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        steps.showLibraryTab("browse")
        require("libraries.grid", timeout: 30, "the Browse grid")
        _ = waitUntil(5) { !cardTitles().isEmpty }
        let unfiltered = cardTitles()
        XCTAssertFalse(unfiltered.isEmpty, "the grid's cards")

        openFilters()
        // Lets the sheet finish sliding up before the shot.
        sleep(1)
        shot("filters sheet")
        let favorites = stageFavorites()
        shot("filters staged")
        steps.press(require("libraries.filters.cancel", "the sheet's Cancel"))
        XCTAssertTrue(favorites.waitForNonExistence(timeout: 10), "Cancel closes the sheet")
        // Gives a stray commit time to show before checking nothing changed.
        sleep(2)
        XCTAssertFalse(filtersLabel().contains("("), "Cancel drops the edit: \(filtersLabel())")
        XCTAssertEqual(cardTitles(), unfiltered, "the grid as it was after Cancel")
        shot("cancelled")

        openFilters()
        XCTAssertEqual(element("libraries.filter.favorite").value as? String, "Any", "the sheet opens on what is applied")
        stageFavorites()
        steps.press(require("libraries.filters.apply", "the sheet's Apply"))
        XCTAssertTrue(favorites.waitForNonExistence(timeout: 10), "Apply closes the sheet")
        XCTAssertTrue(waitUntil(10) { filtersLabel().contains("(1)") }, "Apply commits the edit: \(filtersLabel())")
        XCTAssertTrue(waitUntil(15) { let titles = cardTitles(); return !titles.isEmpty && titles != unfiltered }, "the grid narrowed: \(cardTitles())")
        // Lets the sheet finish closing before the shot.
        sleep(1)
        shot("applied")
        clearFilters(unfiltered)

        openFilters()
        stageFavorites()
        element("libraries.filters.sheet").swipeDown(velocity: .fast)
        XCTAssertTrue(favorites.waitForNonExistence(timeout: 10), "a swipe down closes the sheet")
        XCTAssertTrue(waitUntil(10) { filtersLabel().contains("(1)") }, "a swipe down commits the edit: \(filtersLabel())")
        // Lets the sheet finish closing before the shot.
        sleep(1)
        shot("swiped")
        clearFilters(unfiltered)
    }

    private func openFilters() {
        steps.pressInHeader("libraries.filters", "the Filters capsule")
        XCTAssertTrue(steps.prefixed("libraries.filter.").exists(within: 10), "the filter editor")
    }

    /// Steps the open sheet's Favorites from Any to Yes.
    @discardableResult
    private func stageFavorites() -> XCUIElement {
        let favorites = require("libraries.filter.favorite", "the Favorites field")
        steps.press(favorites)
        XCTAssertTrue(waitUntil(5) { (favorites.value as? String) == "Yes" }, "a press steps Any to Yes")
        // Paces presses: the next press during the field's change is dropped.
        sleep(1)
        return favorites
    }

    /// Clear all, then Apply: the grid shows `unfiltered` again.
    private func clearFilters(_ unfiltered: [String]) {
        openFilters()
        steps.press(require("libraries.filters.clear", "Clear all"))
        steps.press(require("libraries.filters.apply", "the sheet's Apply"))
        XCTAssertTrue(waitUntil(10) { !filtersLabel().contains("(") }, "Clear all applied: \(filtersLabel())")
        XCTAssertTrue(waitUntil(15) { cardTitles() == unfiltered }, "the grid as it was")
    }

    /// The Filters capsule's label ("Filters (1)" while one is set).
    private func filtersLabel() -> String { element("libraries.filters").label }

    /// The titles of the cards the grid shows, in order.
    private func cardTitles() -> [String] {
        guard let grid = try? element("libraries.grid").snapshot() else { return [] }
        var titles: [String] = []
        func collect(_ node: any XCUIElementSnapshot) {
            if node.identifier.hasPrefix("card."), !node.identifier.hasSuffix(".menu") { titles.append(node.label); return }
            node.children.forEach(collect)
        }
        collect(grid)
        return titles
    }
    #endif

    // MARK: - View all's sort

    /// A hub's View all, its sort as Libraries': the orders alone while the page keeps its own order, none checked;
    /// Title picked (in its own direction, A to Z), Clear, Ascending and Descending lead the menu (Ascending checked);
    /// Descending picked, another field keeps it; Clear puts the page's order back, and Clear and the directions go.
    /// The fields under Sort By keep their identifiers (`<id>.option.<i>`, `.selected` while checked); on the Mac, whose
    /// menu items expose no check, the check is also read from the pixels of its check column.
    func testViewAllSortLeadsWithClearAndTheDirectionsAndAFieldKeepsIt() throws {
        executionTimeAllowance = 900
        let id = "hubDetail.sort"
        try launch("home")
        require("home.screen", timeout: 60, "Home")
        require("home.rail", timeout: 30, "the shelves")
        // Lets the shelves settle (focus on Apple TV) before moving through them.
        sleep(3)
        openViewAll()
        let sort = require(id, "View all's sort")
        // Lets the items' artwork load before the shot; nothing signals it.
        sleep(2)
        shot("view all default")

        openSort(id, "sort menu default")
        XCTAssertFalse(field(id, "Clear").exists, "no Clear while the page keeps its own order")
        XCTAssertFalse(field(id, "Ascending").exists, "no Ascending while the page keeps its own order")
        XCTAssertFalse(field(id, "Descending").exists, "no Descending while the page keeps its own order")
        XCTAssertEqual(name(of: option(id, 0)), "Title", "the orders alone, Title first")
        XCTAssertEqual(option(id, 0).identifier, "\(id).option.0", "no order checked")
        pick(id, "Title")
        XCTAssertTrue(waitUntil(5) { name(of: sort).contains("Title") }, "the chip names Title: \(name(of: sort))")

        openSort(id, "sort menu title ascending")
        XCTAssertEqual(name(of: option(id, 0)), "Clear", "Clear first")
        XCTAssertEqual(name(of: option(id, 1)), "Ascending", "Ascending second")
        XCTAssertEqual(name(of: option(id, 2)), "Descending", "Descending third")
        XCTAssertEqual(option(id, 1).identifier, "\(id).option.1.selected.arrow.up", "Title from the page's own order: its own direction, ascending")
        XCTAssertEqual(option(id, 2).identifier, "\(id).option.2", "Descending unchecked")
        XCTAssertEqual(option(id, 3).identifier, "\(id).option.3.selected", "Title, under Sort By, keeps its identifier, checked")
        XCTAssertEqual(name(of: option(id, 3)), "Title", "Title fourth, the first field")
        XCTAssertTrue(checked(field(id, "Title")), "Title shows its check")
        pick(id, "Descending")

        openSort(id, "sort menu title descending")
        XCTAssertEqual(option(id, 2).identifier, "\(id).option.2.selected.arrow.down", "Descending checked")
        XCTAssertEqual(option(id, 1).identifier, "\(id).option.1", "Ascending unchecked")
        XCTAssertEqual(option(id, 3).identifier, "\(id).option.3.selected", "Title still checked")
        XCTAssertTrue(checked(field(id, "Title")), "Title still shows its check")
        pick(id, "Date Added")
        XCTAssertTrue(waitUntil(5) { name(of: sort).contains("Date Added") }, "the chip names Date Added: \(name(of: sort))")

        openSort(id, "sort menu date added descending")
        XCTAssertEqual(option(id, 2).identifier, "\(id).option.2.selected.arrow.down", "another field keeps Descending")
        XCTAssertEqual(option(id, 5).identifier, "\(id).option.5.selected", "Date Added checked")
        XCTAssertEqual(option(id, 3).identifier, "\(id).option.3", "Title no longer checked")
        XCTAssertTrue(checked(field(id, "Date Added")), "Date Added shows its check")
        pick(id, "Clear")
        XCTAssertTrue(waitUntil(5) { !name(of: sort).contains("Date Added") }, "the chip no longer names a field: \(name(of: sort))")

        openSort(id, "sort menu cleared")
        XCTAssertFalse(field(id, "Clear").exists, "no Clear once cleared")
        XCTAssertFalse(field(id, "Ascending").exists, "no Ascending once cleared")
        XCTAssertEqual(option(id, 0).identifier, "\(id).option.0", "no order checked once cleared")
        steps.dismissMenu()
        // Lets the menu finish closing before the shot.
        sleep(1)
        shot("view all cleared")
    }

    /// The open menu `id`'s entry named `label`, by its name (the Mac gives a menu's items titles, not labels).
    private func field(_ id: String, _ label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(
            format: "(label == %@ OR title == %@) AND elementType != %d AND elementType != %d AND NOT identifier BEGINSWITH 'card.'",
            label, label, XCUIElement.ElementType.staticText.rawValue, XCUIElement.ElementType.image.rawValue
        )).firstMatch
    }

    /// Whether a menu entry shows its check (not its identifier, which says what the app selected): its selected trait
    /// or a check image; on the Mac, whose menu items expose neither, marks drawn in its check column (its leading 20 pt)
    /// where Release Year, never picked here, has none. A mark is a pixel of the column in the ink of the entry's title
    /// (the title's pixel farthest from its backdrop), in which the check is drawn: the menu's material lets what lies
    /// under it show through, so a pixel merely unlike the column's backdrop also counts the shelves behind the menu.
    private func checked(_ entry: XCUIElement) -> Bool {
        guard entry.exists else { return false }
        if entry.isSelected || entry.images["checkmark"].exists { return true }
        #if os(macOS)
        let reference = field("", "Release Year")
        guard reference.exists, let screen = XCUIScreen.main.screenshot().image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }
        let scale = CGFloat(screen.width) / (NSScreen.screens.first?.frame.width ?? CGFloat(screen.width))
        func gray(_ rect: CGRect) -> [Int] {
            let area = CGRect(x: rect.minX * scale, y: rect.minY * scale, width: rect.width * scale, height: rect.height * scale).integral
            guard let crop = screen.cropping(to: area) else { return [] }
            let width = crop.width, height = crop.height
            var pixels = [UInt8](repeating: 0, count: width * height)
            guard let context = CGContext(
                data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return [] }
            context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: height))
            return pixels.map(Int.init)
        }
        func marks(_ item: XCUIElement) -> Int {
            let frame = item.frame
            let title = gray(CGRect(x: frame.minX + 20, y: frame.minY, width: min(60, frame.width - 20), height: frame.height))
            var counts = [Int](repeating: 0, count: 256)
            for pixel in title { counts[pixel] += 1 }
            let fill = counts.indices.max { counts[$0] < counts[$1] } ?? 0
            guard let ink = title.max(by: { abs($0 - fill) < abs($1 - fill) }) else { return 0 }
            return gray(CGRect(x: frame.minX, y: frame.minY, width: 20, height: frame.height)).filter { abs($0 - ink) <= 40 }.count
        }
        let own = marks(entry), none = marks(reference)
        // The direction checked, whose identifier says so: what a drawn check counts.
        let drawn = app.menuItems.matching(NSPredicate(format: "identifier CONTAINS '.selected'")).firstMatch
        let check = drawn.exists ? marks(drawn) : -1
        print("CHECK COLUMN \(entry.title): \(own) marked pixels, Release Year \(none), the checked direction \(check)")
        XCTAssertGreaterThan(check, 3 * none + 5, "the check column's marks are read: the checked direction shows its check")
        return own > 3 * none + 5
        #else
        return false
        #endif
    }

    /// Picks the open menu `id`'s entry `label`.
    private func pick(_ id: String, _ label: String) {
        let entry = field(id, label)
        XCTAssertTrue(entry.exists(within: 10), "\(label) in \(id)'s menu")
        #if os(tvOS)
        steps.tvSelect(entry)
        #else
        steps.pressOption(entry)
        #endif
        _ = entry.waitForNonExistence(timeout: 10)
    }

    private func openSort(_ id: String, _ name: String) {
        steps.openFilterMenu(id)
        // Lets the menu finish opening before the shot.
        sleep(1)
        shotOfMenu(name)
    }

    /// What an option reads: its label, or a Mac menu item's title.
    private func name(of option: XCUIElement) -> String {
        option.label.isEmpty ? option.title : option.label
    }

    /// The open menu `id`'s option at `index`.
    private func option(_ id: String, _ index: Int) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@ OR identifier BEGINSWITH %@", "\(id).option.\(index)", "\(id).option.\(index)."))
            .firstMatch
    }

    /// Opens a hub's View all from Home: on Apple TV the card ending a row, elsewhere a hub's heading link.
    private func openViewAll() {
        #if os(tvOS)
        let viewAllFocused = { self.steps.focused(prefix: "hub.viewAll") }
        for _ in 0..<10 where !viewAllFocused() {
            // Lets focus leave the tab bar before the next press.
            if steps.tabBarFocused { XCUIRemote.shared.press(.down); sleep(1); continue }
            for _ in 0..<30 where !viewAllFocused() && !steps.tabBarFocused {
                XCUIRemote.shared.press(.right)
                // Paces the presses so the focus engine doesn't coalesce them.
                usleep(250_000)
            }
            // Lets focus settle on the next row before pressing along it.
            if !viewAllFocused() { XCUIRemote.shared.press(.down); sleep(1) }
        }
        if !viewAllFocused() { return fail("no row ends in View all") }
        XCUIRemote.shared.press(.select)
        #else
        let viewAll = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'hub.' AND identifier ENDSWITH '.viewAll'")).firstMatch
        // Clear of iPhone's floating tab bar, which a tap there reaches instead.
        let clear = { [self] in steps.onScreen(viewAll) && viewAll.frame.maxY < app.windows.firstMatch.frame.maxY - 140 }
        for _ in 0..<16 where !clear() {
            #if os(macOS)
            element("home.screen").scroll(byDeltaX: 0, deltaY: -120)
            #else
            app.swipeUp()
            #endif
            _ = waitUntil(1) { clear() }
        }
        XCTAssertTrue(clear(), "a hub's heading opens View all")
        steps.press(viewAll)
        #endif
        require("hubDetail", timeout: 20, "the hub's View all")
        XCTAssertTrue(steps.prefixed("card.").exists(within: 30), "View all's items")
    }
}
