#if !os(tvOS)
import SwiftUI
import PlezyKit

/// A detail screen's download button as `spec` draws it (`MediaDetailUiState.download`), a round glass control as
/// Detail's other round buttons, its symbol in their square (`roundGlassLabel`): a spinner while the download is
/// being queued, a clock while queued, a ring around a down arrow while downloading (none of which takes a press), else
/// the state's symbol in its tint (paused amber, failed red, cancelled grey, partial or downloaded orange, synced teal).
/// Its spoken label and the Mac's tooltip are the state's ("Download", "Downloading…", "Keep 5 unwatched"), the
/// spinner's value "Loading". A press is `onPress` (`MediaDetailStore.pressDownload`: it resumes, retries, asks what to
/// download or whether to delete; the store reports the outcome).
///
/// The detail screen shows it only while the store gives a spec (never offline); Apple TV has no downloads.
/// Accessibility identifier: `detail.download`.
struct DetailDownloadButton: View {
    let spec: DownloadButtonSpec
    let onPress: () -> Void

    var body: some View {
        let label = spec.tooltip ?? T.shared.downloads.downloadNow
        let tint = spec.tint.color ?? Palette.onBackground
        Button {
            if spec.interactive { onPress() }
        } label: {
            Group {
                switch spec.icon {
                case .spinner:
                    ProgressView().controlSize(.small).tint(tint)
                case .progress:
                    DownloadRing(value: Double(truncating: spec.progress ?? 0), color: tint, lineWidth: 2)
                        .overlay {
                            Image(systemName: "arrow.down").font(.caption2.weight(.bold)).foregroundStyle(tint)
                        }
                default:
                    Image(systemName: spec.icon.systemImage)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(tint)
                }
            }
            .frame(width: 18, height: 18)
            .roundGlassLabel()
        }
        .roundGlassControl()
        .accessibilityLabel(label)
        // The spinner's state has no words of its own (no tooltip): VoiceOver hears it's on its way.
        .accessibilityValue(spec.icon == .spinner ? T.shared.common.loading : "")
        #if os(macOS)
        .tooltip(label)
        #endif
        .accessibilityIdentifier("detail.download")
    }
}
#endif
