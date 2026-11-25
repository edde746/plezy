import Observation
import PlezyKit

/// A shared store's `StateFlow` as SwiftUI state. SKIE exports the flow as an `AsyncSequence` (`SkieSwiftStateFlow`);
/// this one generic wrapper mirrors it into an `@Observable` property, so no screen needs glue of its own. A view reads
/// `state` and runs `observe()` from `.task`:
///
/// ```swift
/// Text(store.state.title)
///     .task { await store.observe() }
/// ```
///
/// SwiftUI cancels that task when the view disappears, which cancels the collection on the Kotlin side, and starts
/// it again when the view reappears. While no view observes, `state` is the flow's value itself, so a view's first
/// frame never renders an empty placeholder, nor what the flow held when a view last observed it (a tab or a retained
/// screen coming back, before its `observe()` starts). A flow of an optional value (SKIE's `SkieSwiftOptionalStateFlow`:
/// a dialog that may be up) mirrors the same way.
@MainActor
@Observable
final class StoreObserver<State> {
    /// The flow's latest value.
    var state: State {
        // Read either way: a view that read the flow's own value still updates once `observe()` mirrors it.
        let mirrored = mirrored
        return observers == 0 ? current() : mirrored
    }

    /// The flow's value as `observe()` last mirrored it.
    private var mirrored: State
    @ObservationIgnored private var observers = 0
    /// The flow's value now.
    @ObservationIgnored private let current: @MainActor () -> State
    /// Collects the flow, handing each value over, until the calling task is cancelled.
    @ObservationIgnored private let collect: @MainActor (_ each: @MainActor (State) -> Void) async -> Void

    init(_ flow: SkieSwiftStateFlow<State>) {
        current = { flow.value }
        collect = { each in
            for await value in flow { each(value) }
        }
        mirrored = flow.value
    }

    /// A flow of a nullable value (SKIE's `SkieSwiftOptionalStateFlow`: a sheet's store while it is up, a focus request).
    init<Value>(_ flow: SkieSwiftOptionalStateFlow<Value>) where State == Value? {
        current = { flow.value }
        collect = { each in
            for await value in flow { each(value) }
        }
        mirrored = flow.value
    }

    /// Mirrors the flow into `state` until the calling task is cancelled. A StateFlow's collector starts with the
    /// current value, so nothing emitted while no view observed is lost.
    func observe() async {
        observers += 1
        defer { observers -= 1 }
        mirror(current())
        await collect { self.mirror($0) }
    }

    /// Sets `mirrored` unless `value` is the object it holds: `State` has no equality to skip on, so writing the same
    /// object again would update every view that reads `state` for nothing.
    private func mirror(_ value: State) {
        if value as AnyObject !== mirrored as AnyObject { mirrored = value }
    }
}

/// A screen's store (`AppSession.home`, `musicAlbum`, `signIn`, …) with its state mirrored for the views. Made once per
/// appearance of the route: the session keeps the store while the route is on a stack, and hands none (so no model)
/// while it has none for the route. `@Observable` so a screen can hand it down through the environment.
@MainActor
@Observable
final class StoreModel<Store, State> {
    let store: Store
    let state: StoreObserver<State>

    init?(_ store: Store?, state: (Store) -> SkieSwiftStateFlow<State>) {
        guard let store else { return nil }
        self.store = store
        self.state = StoreObserver(state(store))
    }

    init?<Value>(_ store: Store?, state: (Store) -> SkieSwiftOptionalStateFlow<Value>) where State == Value? {
        guard let store else { return nil }
        self.store = store
        self.state = StoreObserver(state(store))
    }
}
