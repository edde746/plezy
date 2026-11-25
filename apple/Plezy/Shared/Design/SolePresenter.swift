import SwiftUI

/// Which of the live copies of one screen presents a store's sheet. Apple TV builds a pushed screen twice and more
/// (`RouteView` hides the tab bar over it): the copies are all the top of the stack and all would present, and the
/// system dismisses the sheet of a copy it lets go, which reads as the user closing it (a Trakt sign-in cancelled a
/// second after its code showed). Each copy claims the store as it appears (`claim`) and gives it up as it goes
/// (`release`); the copy that appeared last of those still there presents (`holds`). Elsewhere a screen has one copy,
/// which holds its store while it shows.
@MainActor
@Observable
final class SolePresenter {
    static let shared = SolePresenter()

    /// Each store's live copies, in the order they appeared.
    private var copies: [ObjectIdentifier: [UUID]] = [:]

    func claim(_ store: AnyObject, by copy: UUID) {
        let key = ObjectIdentifier(store)
        copies[key, default: []].removeAll { $0 == copy }
        copies[key, default: []].append(copy)
    }

    func release(_ store: AnyObject, by copy: UUID) {
        let key = ObjectIdentifier(store)
        copies[key]?.removeAll { $0 == copy }
        if copies[key]?.isEmpty == true { copies[key] = nil }
    }

    func holds(_ store: AnyObject, _ copy: UUID) -> Bool {
        copies[ObjectIdentifier(store)]?.last == copy
    }
}
