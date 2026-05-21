import SwiftUI

private struct GlassMaterialModifier<S: Shape>: ViewModifier {
    let shape: S
    let effectID: String?
    let namespace: Namespace.ID?

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(tvOS 26.0, *) {
            if let effectID, let namespace {
                content
                    .glassEffect(.regular, in: shape)
                    .glassEffectID(effectID, in: namespace)
            } else {
                content
                    .glassEffect(.regular, in: shape)
            }
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(shape)
        }
    }
}

extension View {
    func glassMaterial<S: Shape>(in shape: S, effectID: String? = nil, namespace: Namespace.ID? = nil) -> some View {
        modifier(GlassMaterialModifier(shape: shape, effectID: effectID, namespace: namespace))
    }
}
