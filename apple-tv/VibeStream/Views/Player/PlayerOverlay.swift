import SwiftUI

struct PlayerOverlay: View {
    let currentTime: Double
    let duration: Double
    let isPlaying: Bool
    let title: String?
    var subtitle: String?
    var onPlayPause: () -> Void
    var onSeek: (Double) -> Void

    var body: some View {
        VStack {
            // Top info bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let title {
                        Text(title)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 80)
            .padding(.top, 60)

            Spacer()

            // Bottom transport bar
            VStack(spacing: 12) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.3))
                            .frame(height: 6)

                        Capsule()
                            .fill(.white)
                            .frame(width: duration > 0 ? geo.size.width * (currentTime / duration) : 0, height: 6)
                    }
                }
                .frame(height: 6)
                .accessibilityHidden(true)

                // Time labels
                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption)
                        .monospacedDigit()

                    Spacer()

                    Text("-\(formatTime(max(duration - currentTime, 0)))")
                        .font(.caption)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(formatTime(currentTime)) of \(formatTime(duration))")
            }
            .padding(.horizontal, 80)
            .padding(.bottom, 40)
        }
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .clear, .clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func formatTime(_ seconds: Double) -> String {
        let total = Int(max(seconds, 0))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
