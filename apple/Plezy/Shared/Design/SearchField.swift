#if !os(tvOS)
import SwiftUI
import PlezyKit

/// The search field of Search and Explore on iPhone, iPad and the Mac: the search symbol, the text, a spinner while
/// `searching`, and Clear once it holds text; a glass capsule as the system's search field is. Its width is the
/// caller's.
///
/// It keeps its own text while the store's follows (`onChange`), and takes the store's `text` only when the store
/// changes it (a refresh clears it): the store's echo of a text the field sent, which a burst of keys outruns, never
/// takes the field back. Return sends the text first (the `onChange` of its last key can run after the submit), then
/// `onSubmit`. A keyboard's Escape empties it, which keeps focus; empty, Escape goes on to the screen. A keyboard's Down
/// asks `onDown`, whose false leaves the key to the field. With `focus`, the field has the screen's focus as `id`;
/// Clear's identifier is `clearId`.
struct SearchField: View {
    let text: String
    let hint: String
    let id: String
    let clearId: String
    let onChange: (String) -> Void
    let onSubmit: () -> Void
    var searching = false
    var focus: FocusState<String?>.Binding?
    var onDown: (() -> Bool)?

    @State private var typed = ""
    /// Texts sent to the store whose echo hasn't come back, oldest first.
    @State private var sent: [String] = []

    var body: some View {
        capsule(line)
            .onAppear { typed = text }
            .onChange(of: typed) { if typed != text { send(typed) } }
            .onChange(of: text) { take(text) }
    }

    private var line: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.onSurfaceVariant)
                .accessibilityHidden(true)
            field
            if searching {
                ProgressView().controlSize(.small)
            }
            if !typed.isEmpty {
                Button(action: clear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.onSurfaceVariant)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(T.shared.common.clear)
                .accessibilityIdentifier(clearId)
            }
        }
    }

    private var field: some View {
        TextField(hint, text: $typed)
            .textFieldStyle(.plain)
            .cardFocus(focus.map { CardFocus(binding: $0, key: id) })
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
            .accessibilitySortPriority(1)
            #endif
            .onSubmit {
                if typed != text { send(typed) }
                onSubmit()
            }
            #if os(macOS)
            // The Mac's field editor takes Escape as its cancel before a key press reaches the view.
            .onExitCommand(perform: typed.isEmpty ? nil : { clear() })
            #endif
            .onKeyPress(keys: [.escape, .downArrow]) { press in
                switch press.key {
                case .escape:
                    guard !typed.isEmpty else { return .ignored }
                    clear()
                    return .handled
                default:
                    return onDown?() == true ? .handled : .ignored
                }
            }
            .accessibilityIdentifier(id)
    }

    private func capsule(_ line: some View) -> some View {
        #if os(macOS)
        line
            .padding(.horizontal, HeaderMetrics.capsuleInset)
            .frame(minHeight: HeaderMetrics.controlHeight)
            .glassCapsule()
        #else
        line
            .padding(.horizontal, 12)
            .frame(minHeight: 38)
            .glassCapsule()
            // A container of its own: alone in a header row the field reported the whole row's frame, so a press at
            // its reported centre missed the pill.
            .accessibilityElement(children: .contain)
        #endif
    }

    /// Empties the field, which keeps focus.
    private func clear() {
        typed = ""
        focus?.wrappedValue = id
        #if os(macOS)
        // Escape's cancel ends the field editor's session after this: the field takes focus back on the next pass.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            focus?.wrappedValue = id
        }
        #endif
    }

    /// The store's text: its echo of one the field sent drops that and older ones; any other replaces the field's.
    private func take(_ value: String) {
        if let echo = sent.firstIndex(of: value) {
            sent.removeFirst(echo + 1)
        } else if value != typed {
            typed = value
        }
    }

    private func send(_ value: String) {
        guard sent.last != value else { return }
        sent.append(value)
        onChange(value)
    }
}
#endif
