import PlezyKit
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The start failed (`StartupFailedException`, or `RootScreen.Failed`): what failed (`phase · error type`), Retry,
/// which starts again, Copy details (the record's `describe()` block; tvOS has no clipboard), and Upload details, which
/// sends that block to the log relay and shows the Log ID it answers. The record is already kept for the next start.
///
/// When the app's saved data is what failed (`dataFault`) and the launch can reset it (`onReset`), the screen says so
/// and what a reset removes, and offers Reset app data: first, focused, for data it can't read; after Retry for data a
/// newer version wrote, which updating the app opens. The reset runs once the user confirms; `onReset` starts the app
/// again when it's done, and a failure says so here.
struct StartupFailureView: View {
    let failure: StartupFailureRecord
    let onRetry: () -> Void
    var onReset: (() async throws -> Void)?

    private enum Focus { case retry, reset }

    @FocusState private var focus: Focus?
    @State private var uploading = false
    @State private var logId: String?
    @State private var uploadFailed = false
    @State private var confirming: Confirmation?
    @State private var resetting = false
    @State private var resetFailed = false

    /// The saved data's fault, where the launch can reset it.
    private var fault: DataFault? { onReset == nil ? nil : failure.dataFault }

    var body: some View {
        // The whole message shows: taller than the screen, it scrolls (on tvOS with the focus, down to the actions).
        GeometryReader { screen in
            ScrollView {
                content.frame(minHeight: screen.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onAppear { focus = fault == .unreadable ? .reset : .retry }
        .confirmation(confirming, onConfirm: reset, onCancel: { confirming = nil })
    }

    private var content: some View {
        MessageStateView(
            systemImage: "exclamationmark.circle",
            title: title,
            message: message,
            holdsFocus: false,
            maxWidth: Self.maxWidth
        ) {
            if fault == .unreadable { resetButton }
            Button(action: onRetry) {
                Label(T.shared.nav.retry, systemImage: "arrow.clockwise")
            }
            .buttonProminence(fault == .unreadable ? .secondary : .primary)
            .disabled(resetting)
            .accessibilityIdentifier("startup.retry")
            .focused($focus, equals: .retry)
            if fault == .newer { resetButton }
            #if !os(tvOS)
            Button {
                copy(failure.describe())
            } label: {
                Label(T.shared.startup.copyDetails, systemImage: "doc.on.doc")
            }
            .buttonProminence(.secondary)
            .accessibilityIdentifier("startup.copy")
            #endif
            Button {
                upload()
            } label: {
                Label(T.shared.startup.uploadDetails, systemImage: "arrow.up.doc")
            }
            .buttonProminence(.secondary)
            .disabled(uploading)
            .accessibilityIdentifier("startup.upload")
            if resetFailed {
                Text(T.shared.startup.resetFailed)
                    .foregroundStyle(Palette.error)
                    .accessibilityIdentifier("startup.resetFailed")
            }
            if let logId {
                Text("\(T.shared.messages.logsUploaded) · \(T.shared.messages.logId): \(logId)")
                    .font(.body.monospaced().bold())
                    #if !os(tvOS)
                    .textSelection(.enabled)
                    #endif
                    .accessibilityIdentifier("startup.logId")
            } else if uploadFailed {
                Text(T.shared.messages.logsUploadFailed).foregroundStyle(Palette.error)
            }
        }
    }

    /// The column's widest: the reset's explanation takes a few lines, which on Apple TV's larger type want the room.
    #if os(tvOS)
    private static let maxWidth: CGFloat = 1000
    #else
    private static let maxWidth: CGFloat = 560
    #endif

    private var title: String {
        switch fault {
        case .unreadable: T.shared.startup.dataUnreadableTitle
        case .newer: T.shared.startup.dataNewerTitle
        default: T.shared.startup.failedTitle
        }
    }

    private var message: String {
        let step = "\(T.shared.startup.phaseLabel): \(failure.phaseId) · \(failure.errorType)"
        switch fault {
        case .unreadable: return "\(T.shared.startup.dataUnreadableBody)\n\n\(T.shared.startup.resetExplanation)\n\n\(step)"
        case .newer: return "\(T.shared.startup.dataNewerBody)\n\n\(T.shared.startup.resetExplanation)\n\n\(step)"
        default: return "\(T.shared.startup.failedBody)\n\n\(step)"
        }
    }

    private var resetButton: some View {
        Button {
            confirming = Confirmation(
                title: T.shared.startup.resetConfirmTitle,
                message: T.shared.startup.resetExplanation,
                confirmLabel: T.shared.common.reset,
                cancelLabel: T.shared.common.cancel,
                confirmId: "startup.resetConfirm.confirm",
                cancelId: "startup.resetConfirm.cancel"
            )
        } label: {
            Label(T.shared.startup.resetData, systemImage: "trash")
        }
        .buttonProminence(fault == .unreadable ? .primary : .secondary)
        .disabled(resetting)
        .accessibilityIdentifier("startup.reset")
        .focused($focus, equals: .reset)
    }

    /// The confirmed reset: `onReset` starts the app again; a failure is said here.
    private func reset() {
        confirming = nil
        guard let onReset else { return }
        resetting = true
        resetFailed = false
        Task {
            defer { resetting = false }
            do {
                try await onReset()
            } catch {
                resetFailed = true
            }
        }
    }

    /// Sends the `describe()` block to the log relay (`LogUpload`) and shows the Log ID it answers.
    private func upload() {
        uploading = true
        Task {
            defer { uploading = false }
            do {
                logId = try await LogUpload.shared.upload(text: failure.describe(), appVersion: failure.appVersion)
                uploadFailed = false
            } catch {
                uploadFailed = true
            }
        }
    }

    #if !os(tvOS)
    private func copy(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }
    #endif
}
