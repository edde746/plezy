import SwiftUI

/// Presents the player via UIKit's modal presentation instead of SwiftUI's fullScreenCover.
/// Uses crossDissolve transition to avoid _UIReplicantView snapshot errors on tvOS.
///
/// IMPORTANT: The dismiss flow is carefully sequenced:
///
/// 1. PlayerView.onExitCommand pauses audio and calls coordinator.requestPlayerDismiss().
///    It does NOT call viewModel.stop() — that would detach the Metal layer during
///    the dismiss animation, causing a black screen.
/// 2. SwiftUI re-evaluates; updateUIViewController sees isDismissing and starts
///    the UIKit dismiss(animated:) on PlayerBridgeController.
/// 3. Only in the dismiss completion handler does PlayerBridgeController call
///    coordinator.dismissPlayer(), which clears playerRatingKey = nil.
/// 4. SwiftUI removes PlayerView → .onDisappear calls viewModel.stop() for cleanup.
/// 5. MpvVideoView.dismantleUIView calls core.dispose() for final mpv destruction.
///
/// Key safety measures:
/// - PlayerPresenter is placed outside the connection-status conditional in MainTabView
///   so it survives connection changes during the dismiss animation.
/// - The dismiss completion uses a strong self capture (not weak) so it always fires,
///   even if SwiftUI tries to recycle the representable during the animation.
/// - The guard in dismissPlayer() always calls onDismissComplete, even on early return,
///   so the coordinator state is never left stuck.
struct PlayerPresenter: UIViewControllerRepresentable {
    let ratingKey: String?
    let resumeOffset: Int?
    let isDismissing: Bool
    let coordinator: NavigationCoordinator
    let appState: AppState

    func makeUIViewController(context: Context) -> PlayerBridgeController {
        let vc = PlayerBridgeController()
        vc.onDismissComplete = { [coordinator] in
            // Only clear SwiftUI state AFTER UIKit dismiss is fully complete.
            // This prevents the race between SwiftUI layout and UIKit animation.
            coordinator.dismissPlayer()
        }
        return vc
    }

    func updateUIViewController(_ controller: PlayerBridgeController, context: Context) {
        if let ratingKey, !controller.isPresenting && !controller.isDismissing {
            // Present the player
            let playerView = PlayerView(ratingKey: ratingKey, resumeOffset: resumeOffset)
                .environment(appState)
                .environmentObject(coordinator)

            let hosting = UIHostingController(rootView: playerView)
            hosting.modalPresentationStyle = .fullScreen
            hosting.modalTransitionStyle = .crossDissolve
            hosting.view.backgroundColor = .black
            // Prevent the system from auto-dismissing on menu button press.
            // All menu/back handling is done by MpvContainerView's gesture
            // recognizer, which routes through the cascade in PlayerView.
            hosting.isModalInPresentation = true

            controller.isPresenting = true
            controller.present(hosting, animated: true)
        } else if isDismissing && controller.isPresenting && !controller.isDismissing {
            // Begin UIKit dismiss — state will be cleared in the completion handler
            controller.dismissPlayer()
        }
    }
}

final class PlayerBridgeController: UIViewController {
    var isPresenting = false
    var isDismissing = false
    var onDismissComplete: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        // Allow interaction pass-through so the TabView underneath stays interactive
        // when the player is not presented.
        view.isUserInteractionEnabled = false
    }

    func dismissPlayer() {
        guard isPresenting, !isDismissing, presentedViewController != nil else {
            // Nothing to dismiss — clean up state and signal completion
            // so the coordinator clears playerRatingKey. Without this,
            // the app gets stuck with stale player state.
            isPresenting = false
            isDismissing = false
            onDismissComplete?()
            return
        }
        isDismissing = true
        // Use strong self capture — UIKit guarantees the completion handler
        // fires, so no retain cycle. A weak capture risks self being deallocated
        // during the animation (e.g. if SwiftUI recreates the representable),
        // which would leave playerRatingKey stuck and cause a black screen.
        dismiss(animated: true) {
            self.isPresenting = false
            self.isDismissing = false
            self.onDismissComplete?()
        }
    }
}
