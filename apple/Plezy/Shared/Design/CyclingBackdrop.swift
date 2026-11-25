import SwiftUI
import PlezyKit

/// An item's backgrounds (`backdrops`) filling the frame, the next every 10 s
/// (`BackdropRotation.ROTATION_MILLIS`) while they can turn (`BackdropRotation.rotates`): the backdrop in sight,
/// the app in use (`appActive`), neither the reduced effects tier nor Reduce Motion, and two backgrounds usable. Each
/// fades in over the last (280 ms; at once on the reduced tier or under Reduce Motion) once it has loaded: the last stays
/// until then, and one that fails is skipped, the turn moving on at once. A new `key` (the item) or list starts again at
/// its first background, fading in over the last item's. Without any (or once every one has failed), the last fades out.
///
/// Hidden from VoiceOver. Debug builds carry the index of the background shown for the UI tests (`backdrop`, label and
/// value: `0`; `none` before one has drawn).
struct CyclingBackdrop: View {
    var key: String?
    let backdrops: [Artwork]
    var alignment: Alignment = .center

    @State private var rotation: BackdropRotation
    /// The background that has drawn: it stays under the incoming one until that has loaded and faded in, and fades out
    /// when nothing comes in.
    @State private var settled: Artwork?
    /// The incoming background once it has loaded, fading in from then.
    @State private var arrived: Artwork?
    @State private var inSight = false
    @Environment(\.appActive) private var appActive
    @Environment(\.reducedEffects) private var reducedEffects
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(key: String? = nil, backdrops: [Artwork], alignment: Alignment = .center) {
        self.key = key
        self.backdrops = backdrops
        self.alignment = alignment
        _rotation = State(initialValue: Self.start(backdrops))
    }

    var body: some View {
        let target = rotation.current?.intValue
        let incoming = target.flatMap { backdrops.indices.contains($0) ? backdrops[$0] : nil }
        let shown = settled
        let layers = [shown, incoming == shown ? nil : incoming].compactMap { $0 }
        let rotates = BackdropRotation.companion.rotates(
            rotation: rotation, active: inSight, visible: appActive, reducedTier: reducedEffects, reducedMotion: reduceMotion
        )
        ZStack {
            Color.clear
            ForEach(layers, id: \.key) { layer in
                RemoteImage(artwork: layer, alignment: alignment, onResult: { outcome in
                    result(outcome, of: layer, at: target)
                })
                .opacity(layer == shown || layer == arrived ? 1 : 0)
            }
        }
        .accessibilityHidden(true)
        #if DEBUG
        .overlay(alignment: .topLeading) {
            let reading = shown.flatMap { backdrops.firstIndex(of: $0) }.map(String.init) ?? "none"
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityLabel(Text(verbatim: reading))
                .accessibilityValue(reading)
                .accessibilityIdentifier("backdrop")
        }
        #endif
        .onAppear { inSight = true }
        .onDisappear { inSight = false }
        .onChange(of: Item(key: key, backdrops: backdrops)) {
            rotation = Self.start(backdrops)
            arrived = nil
        }
        .onChange(of: incoming == nil) { _, gone in
            guard gone else { return }
            let fade = BackdropRotation.companion.fadeMillis(reducedTier: reducedEffects, reducedMotion: reduceMotion)
            withAnimation(fade > 0 ? .easeInOut(duration: Double(fade) / 1000) : nil) { settled = nil }
        }
        // Restarted by every turn and failure; going out of sight stops it, coming back starts the interval over.
        .task(id: Turn(rotation: rotation, rotates: rotates)) {
            guard rotates else { return }
            try? await Task.sleep(for: .milliseconds(BackdropRotation.companion.ROTATION_MILLIS))
            guard !Task.isCancelled else { return }
            rotation = rotation.advance()
        }
    }

    /// What became of `layer`, the background at `index` when it was asked for: only the incoming one's outcome counts.
    private func result(_ outcome: ArtworkOutcome, of layer: Artwork, at index: Int?) {
        guard let index, rotation.current?.intValue == index, backdrops.indices.contains(index), backdrops[index] == layer,
              layer != settled else { return }
        switch outcome {
        case .loaded:
            let fade = BackdropRotation.companion.fadeMillis(reducedTier: reducedEffects, reducedMotion: reduceMotion)
            guard fade > 0 else {
                arrived = layer
                settled = layer
                return
            }
            withAnimation(.easeInOut(duration: Double(fade) / 1000)) {
                arrived = layer
            } completion: {
                if arrived == layer { settled = layer }
            }
        case .failed:
            rotation = rotation.fail(at: Int32(index))
        case .unresolved:
            break
        }
    }

    private static func start(_ backdrops: [Artwork]) -> BackdropRotation {
        BackdropRotation(count: Int32(backdrops.count), index: 0, failed: [])
    }

    private struct Item: Equatable {
        let key: String?
        let backdrops: [Artwork]
    }

    private struct Turn: Equatable {
        let rotation: BackdropRotation
        let rotates: Bool
    }
}
