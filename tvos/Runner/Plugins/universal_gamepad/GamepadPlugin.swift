import Flutter
import UIKit

/// Entry point for the gamepad iOS plugin.
///
/// Registers a MethodChannel (`dev.universal_gamepad/methods`) and an
/// EventChannel (`dev.universal_gamepad/events`) with the Flutter engine.
public class GamepadPlugin: NSObject, FlutterPlugin {

    private let controllerManager: GCControllerManager
    private let streamHandler: GamepadStreamHandler

    init(controllerManager: GCControllerManager, streamHandler: GamepadStreamHandler) {
        self.controllerManager = controllerManager
        self.streamHandler = streamHandler
        super.init()
    }

    // MARK: - FlutterPlugin

    public static func register(with registrar: FlutterPluginRegistrar) {
        let streamHandler = GamepadStreamHandler()
        let controllerManager = GCControllerManager(streamHandler: streamHandler)

        let methodChannel = FlutterMethodChannel(
            name: "dev.universal_gamepad/methods",
            binaryMessenger: registrar.messenger()
        )

        let eventChannel = FlutterEventChannel(
            name: "dev.universal_gamepad/events",
            binaryMessenger: registrar.messenger()
        )

        let instance = GamepadPlugin(
            controllerManager: controllerManager,
            streamHandler: streamHandler
        )

        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(streamHandler)

        // Start observing controllers immediately so we capture connections
        // that happen before the Dart side listens.
        controllerManager.startObserving()
    }

    // MARK: - MethodChannel

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "listGamepads":
            result(controllerManager.listGamepads())
        case "dispose":
            controllerManager.stopObserving()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
