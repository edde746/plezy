import Foundation

/// Debug builds: the UI tests' launch argument `-assistiveTechnology YES`, which the player takes as VoiceOver running
/// (`PlayerScreen`'s `assistiveTechnology`): XCUITest can't turn VoiceOver or Switch Control on.
enum SimulatedAssistiveTechnology {
    static let running = UserDefaults.standard.bool(forKey: "assistiveTechnology")
}
