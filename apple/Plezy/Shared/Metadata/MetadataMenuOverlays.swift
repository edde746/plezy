import SwiftUI
import PlezyKit

extension View {
    /// An item menu's Quick Tag and Unmatch confirmation (`MetadataEditing.quickTag`, `.unmatchPrompt`), over the screen
    /// the menu opened on.
    func metadataMenuOverlays(_ metadata: MetadataEditing) -> some View {
        modifier(MetadataMenuOverlays(metadata: metadata))
    }
}

private struct MetadataMenuOverlays: ViewModifier {
    let metadata: MetadataEditing
    @State private var quickTag: StoreObserver<QuickTagStore?>
    @State private var unmatch: StoreObserver<MediaItem?>

    init(metadata: MetadataEditing) {
        self.metadata = metadata
        _quickTag = State(initialValue: StoreObserver(metadata.quickTag))
        _unmatch = State(initialValue: StoreObserver(metadata.unmatchPrompt))
    }

    func body(content: Content) -> some View {
        let prompt = unmatch.state
        content
            .overlay {
                if let store = quickTag.state {
                    QuickTagView(store: store, onDone: metadata.quickTagDone).id(ObjectIdentifier(store))
                }
            }
            .confirmation(
                prompt.map { _ in
                    Confirmation(
                        title: UnmatchConfirm.shared.title, message: UnmatchConfirm.shared.message,
                        confirmLabel: UnmatchConfirm.shared.confirm, cancelLabel: UnmatchConfirm.shared.cancel,
                        confirmId: "metadata.unmatch.confirm", cancelId: "metadata.unmatch.cancel"
                    )
                },
                onConfirm: {
                    if let prompt { metadata.unmatch(item: prompt) }
                    metadata.dismissUnmatch()
                },
                onCancel: metadata.dismissUnmatch
            )
            .task { await quickTag.observe() }
            .task { await unmatch.observe() }
    }
}
