import SwiftUI

enum ErrorType {
    case network
    case auth
    case notFound
    case generic

    var icon: String {
        switch self {
        case .network: return "wifi.exclamationmark"
        case .auth: return "lock.shield"
        case .notFound: return "magnifyingglass"
        case .generic: return "exclamationmark.triangle"
        }
    }

    var helpText: String {
        switch self {
        case .network: return "Check your connection and try again"
        case .auth: return "Your session may have expired"
        case .notFound: return "The content you're looking for could not be found"
        case .generic: return "Something went wrong"
        }
    }
}

struct ErrorStateView: View {
    let message: String
    var icon: String = "exclamationmark.triangle"
    var helpText: String?
    var errorType: ErrorType?
    var retryAction: (() async -> Void)?
    var signOutAction: (() -> Void)?

    private var displayIcon: String {
        errorType?.icon ?? icon
    }

    private var displayHelpText: String? {
        if let helpText = helpText {
            return helpText
        }
        return errorType?.helpText
    }

    private var shouldShowSignOut: Bool {
        if signOutAction != nil {
            return true
        }
        if case .auth = errorType {
            return true
        }
        return false
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: displayIcon)
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(message)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if let displayHelpText {
                    Text(displayHelpText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            HStack(spacing: 16) {
                if let retryAction {
                    Button("Retry") {
                        Task { await retryAction() }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if shouldShowSignOut {
                    Button("Sign Out") {
                        if let signOutAction {
                            signOutAction()
                        }
                    }
                }
            }
        }
        .padding(40)
    }
}
