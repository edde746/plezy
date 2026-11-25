import SwiftUI
import PlezyKit

/// Debug builds started with `-overlaySample sheet|menu|confirm|toggle|text` (UserDefaults' argument domain; the UI
/// tests' `ShellScreens.testOverlays`): 4 s after the shell shows (once a test has found its screen), one sample of the
/// app's presentations opens over it, for screenshots: an `appSheet` of rows, an item's menu as the shared menus show
/// it (`entriesDialog`), a question (`confirmation`), a question whose confirm can do more (its `toggle`) and a name to
/// type (`textPrompt`). The samples' words are made up: nothing in the shell opens these.
struct OverlaySample: ViewModifier {
    private static let kind = UserDefaults.standard.string(forKey: "overlaySample")

    @State private var sheet = false
    @State private var menu = false
    @State private var confirm: Confirmation?
    @State private var text = false

    func body(content: Content) -> some View {
        if let kind = Self.kind {
            content
                .appSheet(isPresented: $sheet, id: "sample.sheet", size: .panel) {
                    SheetPage(title: "Audio", close: SheetAction(title: T.shared.nav.close, id: "sample.sheet.close") { sheet = false }) {
                        List {
                            ForEach(Array(Self.tracks.enumerated()), id: \.offset) { index, track in
                                Button(track) { sheet = false }
                                    .accessibilityIdentifier("sample.sheet.row.\(index)")
                            }
                        }
                    }
                }
                .entriesDialog("Alpha Archive", isPresented: menu, entries: Self.entries { menu = false }, probe: "sample.menu") {
                    menu = false
                }
                .confirmation(confirm, onConfirm: { confirm = nil }, onToggledConfirm: { confirm = nil }) { confirm = nil }
                .textPrompt(
                    "New playlist",
                    isPresented: text,
                    message: "Name",
                    placeholder: "My playlist",
                    confirmLabel: T.shared.common.save,
                    id: "sample.text",
                    onSubmit: { _ in text = false },
                    onCancel: { text = false }
                )
                .task {
                    try? await Task.sleep(for: .seconds(4))
                    switch kind {
                    case "sheet": sheet = true
                    case "menu": menu = true
                    case "confirm": confirm = Self.question
                    case "toggle": confirm = Self.toggleQuestion
                    case "text": text = true
                    default: break
                    }
                }
        } else {
            content
        }
    }

    private static var question: Confirmation {
        Confirmation(
            title: "End the room?",
            message: "Everyone in the room stops watching together.",
            confirmLabel: "End room",
            cancelLabel: T.shared.common.cancel,
            confirmId: "sample.confirm.ok",
            cancelId: "sample.confirm.cancel"
        )
    }

    private static var toggleQuestion: Confirmation {
        Confirmation(
            title: "Sign out of Alpha?",
            message: "Alpha's profiles leave this device.",
            confirmLabel: "Sign out",
            cancelLabel: T.shared.common.cancel,
            confirmId: "sample.toggle.ok",
            cancelId: "sample.toggle.cancel",
            toggle: ConfirmationToggle(
                label: "Also delete downloads",
                description: "Otherwise they stay on this device and come back when you sign back in.",
                id: "sample.toggle.on"
            )
        )
    }

    private static let tracks = [
        "English · TrueHD Atmos 7.1",
        "English · AC3 5.1",
        "Commentary · AAC Stereo",
        "Français · EAC3 5.1",
    ]

    private static func entries(close: @escaping () -> Void) -> [ItemMenuEntry] {
        [
            ItemMenuEntry(label: "Mark as watched", systemImage: "eye", action: close),
            ItemMenuEntry(label: "Add to playlist", systemImage: "text.badge.plus", action: close),
            ItemMenuEntry(label: "Go to series", systemImage: "tv", action: close),
            ItemMenuEntry(label: "Play with…", systemImage: "play.rectangle.on.rectangle", submenu: [
                ItemMenuEntry(label: "Plezy", action: close),
                ItemMenuEntry(label: "VLC", action: close),
            ]) {},
            ItemMenuEntry(label: "Remove from Continue Watching", systemImage: "trash", destructive: true, action: close),
        ]
    }
}
