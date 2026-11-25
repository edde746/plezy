#if !os(tvOS)
import SwiftUI
import PlezyKit

/// The fixed colours of the download states, the same on every theme: queued and partial orange, downloading blue,
/// paused amber or grey, failed red, completed green, a synced item's teal.
enum DownloadColors {
    static let orange = Color(rgb: 0xFF9800)
    static let blue = Color(rgb: 0x2196F3)
    static let amber = Color(rgb: 0xFFC107)
    static let grey = Color(rgb: 0x9E9E9E)
    static let red = Color(rgb: 0xF44336)
    static let green = Color(rgb: 0x4CAF50)
    static let teal = Color(rgb: 0x009688)
}

/// How far a download is, as a ring that fills clockwise from the top over a track of its own colour at 30 %. `value`
/// is 0 to 1.
struct DownloadRing: View {
    let value: Double
    var color: Color = Palette.primary
    var lineWidth: CGFloat = 2.5

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.3), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth))
                .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2)
        .accessibilityHidden(true)
    }
}

/// A download's status as a small symbol in its colour (`size` square): queued an orange clock, downloading a ring
/// in the accent while its `progress` is known (else a blue dotted arrow), paused a grey pause, failed a red warning,
/// cancelled a grey cross, completed a green filled arrow, partial an orange half circle.
struct DownloadStatusIcon: View {
    let status: DownloadedMediaStatus
    var progress: Double?
    var size: CGFloat = 20

    var body: some View {
        Group {
            if status == .downloading, let progress {
                DownloadRing(value: progress, lineWidth: size * 0.1)
            } else {
                Image(systemName: status.systemImage)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(status.color)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

extension DownloadedMediaStatus {
    /// The SF Symbol of the status (`DownloadStatusIcon`).
    var systemImage: String {
        switch self {
        case .queued: "clock"
        case .downloading: "arrow.down.circle.dotted"
        case .partial: "circle.lefthalf.filled"
        case .paused: "pause.circle"
        case .failed: "exclamationmark.triangle"
        case .completed: "arrow.down.circle.fill"
        case .cancelled: "xmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .queued, .partial: DownloadColors.orange
        case .downloading: DownloadColors.blue
        case .paused, .cancelled: DownloadColors.grey
        case .failed: DownloadColors.red
        case .completed: DownloadColors.green
        }
    }
}

extension DownloadButtonTint {
    /// The tint's colour; nil for none (the button's own).
    var color: Color? {
        switch self {
        case .none: nil
        case .amber: DownloadColors.amber
        case .red: DownloadColors.red
        case .grey: DownloadColors.grey
        case .teal: DownloadColors.teal
        case .orange: DownloadColors.orange
        }
    }
}

extension DownloadButtonIcon {
    /// The SF Symbol of a detail download button's state; the spinner and the ring draw themselves.
    var systemImage: String {
        switch self {
        case .queued: "clock"
        case .paused: "pause.fill"
        case .failed: "exclamationmark.triangle"
        case .cancelled: "xmark"
        case .sync: "arrow.triangle.2.circlepath"
        case .syncDisabled: "exclamationmark.arrow.triangle.2.circlepath"
        case .partial: "circle.lefthalf.filled"
        case .downloaded: "arrow.down.circle.fill"
        case .download, .spinner, .progress: "arrow.down"
        }
    }
}

extension DownloadDialogIcon {
    /// The SF Symbol beside a download dialog's row.
    var systemImage: String {
        switch self {
        case .download: "arrow.down.circle"
        case .unwatched: "eye.slash"
        case .next5: "5.circle"
        case .next10: "10.circle"
        case .custom: "slider.horizontal.3"
        case .delete: "trash"
        case .sync: "arrow.triangle.2.circlepath"
        case .specials: "star"
        case .theVersion: "film.stack"
        // The detail screen's Quality menu's symbol.
        case .quality: "slider.horizontal.3"
        }
    }
}

extension DownloadRowAction {
    /// The SF Symbol of a Manage tree row's action.
    var systemImage: String {
        switch self {
        case .pause, .pauseAll: "pause.fill"
        case .resume, .resumeAll: "play.fill"
        case .cancel: "xmark"
        case .retry, .retryAll: "arrow.clockwise"
        case .delete: "trash.fill"
        case .deleteAll: "trash.slash"
        }
    }

    /// Its accessibility identifier's last part: `pause`, `deleteAll`.
    var identifier: String {
        switch self {
        case .pause: "pause"
        case .resume: "resume"
        case .cancel: "cancel"
        case .retry: "retry"
        case .delete: "delete"
        case .pauseAll: "pauseAll"
        case .resumeAll: "resumeAll"
        case .retryAll: "retryAll"
        case .deleteAll: "deleteAll"
        }
    }
}
#endif
