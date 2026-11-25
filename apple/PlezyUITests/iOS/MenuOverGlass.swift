import XCTest

/// An entry of an open context menu that lies over a glass control under the menu: its identifier, the control's, where
/// to tap so the touch lands on the glass too (the middle of their overlap), and what the menu opened from.
struct EntryOverGlass {
    let id: String
    let target: String
    let glass: String
    let point: CGPoint
}

/// Steps for the menus that open over glass on iPhone and iPad. Glass that follows touches takes a tap meant for a menu
/// entry above it, so the entry never runs and the menu stays open (`OpenItemMenu`): a test opens a menu over a
/// screen's glass and taps the entry where it covers the glass.
extension PlezyUITestCase {
    /// Long-presses the elements whose identifier `targets` matches (those whose top is below `below`), the lowest on
    /// screen first (a menu opens upwards from the foot of the screen), up to six, until one's context menu has an entry
    /// (`menu.*`, not its title; one of `allowed` where given) over one of the controls `glass` names; that entry, over
    /// the control it covers most, its menu left open. Nil, every menu closed again, when none does; fails where no
    /// target is on screen or no press opens a menu, so a caller's skip on nil only ever means the menus open elsewhere.
    func menuEntryOverGlass(
        _ glass: [String], pressing targets: NSPredicate, below: CGFloat = 0, allowed: Set<String>? = nil
    ) -> EntryOverGlass? {
        let window = app.windows.firstMatch.frame
        let controls = glass.map { element($0) }.filter(\.exists).map { ($0.identifier, $0.frame) }.filter { !$0.1.isEmpty }
        var pressable: [(id: String, frame: CGRect)] = []
        func collect(_ node: any XCUIElementSnapshot) {
            if targets.evaluate(with: ["identifier": node.identifier]), !node.frame.isEmpty, node.frame.minY > below,
               window.insetBy(dx: 0, dy: 60).contains(node.frame), !pressable.contains(where: { $0.frame == node.frame }) {
                pressable.append((node.identifier, node.frame))
            }
            node.children.forEach(collect)
        }
        if let root = try? app.snapshot() { collect(root) }
        let entries = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'menu.' AND identifier != 'menu.title'"))
        var opened = false
        for target in pressable.sorted(by: { $0.frame.midY > $1.frame.midY }).prefix(6) {
            tap(at: CGPoint(x: target.frame.midX, y: target.frame.midY), pressing: 1.0)
            guard entries.firstMatch.exists(within: 10) else { continue }
            opened = true
            // The menu's opening animation ends before its entries' frames are read.
            sleep(1)
            var best: (EntryOverGlass, CGFloat)?
            for entry in entries.allElementsBoundByIndex where entry.exists && allowed?.contains(entry.identifier) != false {
                for (id, frame) in controls {
                    let overlap = entry.frame.intersection(frame)
                    let area = overlap.isNull ? 0 : overlap.width * overlap.height
                    // A sliver along an edge is no place to tap.
                    if area > max(best?.1 ?? 0, 100) {
                        best = (EntryOverGlass(id: entry.identifier, target: target.id, glass: id, point: CGPoint(x: overlap.midX, y: overlap.midY)), area)
                    }
                }
            }
            if let best { return best.0 }
            closeContextMenu()
        }
        if pressable.isEmpty {
            fail("no element matching \(targets.predicateFormat) on screen to press")
        } else if !opened {
            fail("no menu opened on \(pressable.prefix(6).map(\.id))")
        }
        return nil
    }

    /// A tap at `point` in the app's coordinates, held `pressing` seconds where given.
    func tap(at point: CGPoint, pressing: TimeInterval? = nil) {
        let there = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: point.x, dy: point.y))
        if let pressing { there.press(forDuration: pressing) } else { there.tap() }
    }

    /// Closes an open context menu: a tap beside it, which keeps clear of the screen's edges.
    func closeContextMenu() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).tap()
        _ = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'menu.'")).firstMatch
            .waitForNonExistence(timeout: 5)
    }
}
