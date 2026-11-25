import SwiftUI

extension View {
    /// Presents `item`, a store's state (a sheet, a cover, a panel, a popover), with `present` (`.sheet(item:)`,
    /// `.fullScreenCover(item:)`, …). SwiftUI dismisses a presentation itself (a swipe, Close, Escape, the remote's
    /// Menu) and sets `item` to nil, which tells the store; the store's state, and so `item`, says so a moment later
    /// (`StoreObserver.observe`). Read as still there meanwhile, the presentation came up again and went once the state
    /// followed, and for that second the app took no press: on Apple TV a Menu right after closing the Streams panel
    /// was lost. The binding `present` gets reads nil from SwiftUI's dismissal until `item` changes.
    func statePresentation<Item: Identifiable, Presented: View>(
        _ item: Binding<Item?>,
        @ViewBuilder _ present: @escaping (Self, Binding<Item?>) -> Presented
    ) -> some View {
        DismissalLatch(base: self, item: item, present: present)
    }

    /// `statePresentation(_:_:)` of a presentation shown while `isPresented`.
    func statePresentation<Presented: View>(
        _ isPresented: Binding<Bool>,
        @ViewBuilder _ present: @escaping (Self, Binding<Bool>) -> Presented
    ) -> some View {
        let item = Binding<Presence?>(get: { isPresented.wrappedValue ? Presence() : nil }, set: { isPresented.wrappedValue = $0 != nil })
        return statePresentation(item) { base, item in
            present(base, Binding(get: { item.wrappedValue != nil }, set: { item.wrappedValue = $0 ? Presence() : nil }))
        }
    }
}

/// A presentation that is either up or not.
private struct Presence: Identifiable {
    var id: Int { 0 }
}

private struct DismissalLatch<Base: View, Item: Identifiable, Presented: View>: View {
    let base: Base
    let item: Binding<Item?>
    let present: (Base, Binding<Item?>) -> Presented

    /// The item SwiftUI dismissed, while `item` still holds it.
    @State private var dismissed: Item.ID?

    var body: some View {
        present(base, Binding(
            get: { item.wrappedValue.flatMap { $0.id == dismissed ? nil : $0 } },
            set: { value in
                if value == nil, let shown = item.wrappedValue { dismissed = shown.id }
                item.wrappedValue = value
            }
        ))
        .onChange(of: item.wrappedValue?.id) { dismissed = nil }
    }
}
