import SwiftUI
import PlezyKit

/// What Play's tracks will be (`TrackStatusUi`), one line at `fontSize` semibold at the default text size, growing and
/// shrinking with Dynamic Type as the footnote does: the picture labels ("4K", "HEVC"),
/// the speaker with the audio track ("English · EAC3 5.1"), the captions symbol with the subtitle or "Off", "  •  "
/// between them, the symbols 1.15 times the text. It sheds what doesn't fit, in order: the subtitle's detail, the
/// audio's, the picture labels from the last, the audio track; given no room it draws nothing. Read-only: VoiceOver
/// reads it as one line ("Audio & Subtitles: 4K, English · EAC3 5.1, Off"). Accessibility identifier: `detail.tracks`.
/// Without `tracks` (still probed) the line's room, empty.
struct TrackStatusLine: View {
    let tracks: TrackStatusUi?
    let fontSize: CGFloat

    @ScaledMetric(relativeTo: .footnote) private var scale: CGFloat = 1

    var body: some View {
        if let tracks {
            let video = tracks.video
            ViewThatFits(in: .horizontal) {
                line(tracks, video: video, audio: true, audioDetail: true, subtitleDetail: true)
                line(tracks, video: video, audio: true, audioDetail: true, subtitleDetail: false)
                line(tracks, video: video, audio: true, audioDetail: false, subtitleDetail: false)
                ForEach(Array(stride(from: video.count - 1, through: 0, by: -1)), id: \.self) { kept in
                    line(tracks, video: Array(video.prefix(kept)), audio: true, audioDetail: false, subtitleDetail: false)
                }
                line(tracks, video: [], audio: false, audioDetail: false, subtitleDetail: false)
                Color.clear.frame(width: 0, height: 0)
            }
        } else {
            part("captions.bubble.fill", " ", detail: nil)
                .font(.system(size: fontSize * scale, weight: .semibold))
                .hidden()
                .accessibilityHidden(true)
        }
    }

    private func line(_ tracks: TrackStatusUi, video: [String], audio: Bool, audioDetail: Bool, subtitleDetail: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(video.enumerated()), id: \.offset) { index, label in
                if index > 0 { separator }
                Text(label)
            }
            if audio, let primary = tracks.audio {
                if !video.isEmpty { separator }
                part("speaker.wave.2.fill", primary, detail: audioDetail ? tracks.audioDetail : nil)
            }
            if !video.isEmpty || (audio && tracks.audio != nil) { separator }
            part("captions.bubble.fill", tracks.subtitle, detail: subtitleDetail ? tracks.subtitleDetail : nil)
        }
        .font(.system(size: fontSize * scale, weight: .semibold))
        .foregroundStyle(Palette.onBackground)
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tracks.semanticLabel)
        .accessibilityIdentifier("detail.tracks")
    }

    private var separator: some View {
        Text("  •  ")
    }

    private func part(_ symbol: String, _ text: String, detail: String?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: fontSize * scale * 1.15))
            Text(detail.map { "\(text) · \($0)" } ?? text)
        }
    }
}
