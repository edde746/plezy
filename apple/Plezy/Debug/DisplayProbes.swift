import SwiftUI

extension View {
    /// Debug builds: the display runs a launch argument asks for, over the app: the TV's criteria on tvOS
    /// (`-probeDisplayCriteria YES`, `DisplayCriteriaRun`), the refresh-rate switch on the Mac (`-probeDisplayModes YES`,
    /// `DisplayModesRun`), the external screen's scene on iOS (`-probeExternalScreen YES`, `ExternalScreenProbe`). Nothing
    /// without them.
    @ViewBuilder
    func displayProbes() -> some View {
        #if os(tvOS)
        if let run = DisplayCriteriaRun.shared { overlay { DisplayCriteriaProbe(run: run) } } else { self }
        #elseif os(macOS)
        if let run = DisplayModesRun.shared { overlay { DisplayModesRunProbe(run: run) } } else { self }
        #else
        if UserDefaults.standard.bool(forKey: "probeExternalScreen") { overlay { ExternalScreenProbe() } } else { self }
        #endif
    }
}

#if os(iOS)
/// Whether the app holds an external screen's scene (`ExternalDisplay`), as the label of an element the UI tests read
/// (`display.external`): `connected`, else `none`.
private struct ExternalScreenProbe: View {
    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: ExternalDisplay.shared.videoHost == nil ? "none" : "connected"))
            .accessibilityIdentifier("display.external")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}
#endif
