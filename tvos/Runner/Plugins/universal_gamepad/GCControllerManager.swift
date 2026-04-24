import GameController

/// Manages GCController connections and input, translating events into the
/// compact wire-format arrays expected by the Dart side.
class GCControllerManager {

    // MARK: - Properties

    private let streamHandler: GamepadStreamHandler

    /// Maps a GCController instance to its stable int gamepad ID.
    private var controllerIds: [ObjectIdentifier: Int] = [:]

    /// Counter for generating unique IDs.
    private var nextId: Int = 0

    /// Notification observers so we can remove them on dispose.
    private var connectObserver: NSObjectProtocol?
    private var disconnectObserver: NSObjectProtocol?

    // MARK: - Init

    init(streamHandler: GamepadStreamHandler) {
        self.streamHandler = streamHandler
    }

    // MARK: - Lifecycle

    /// Begin listening for GCController connect/disconnect notifications and
    /// register input handlers on any controllers that are already connected.
    func startObserving() {
        connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let controller = notification.object as? GCController else { return }
            self.controllerDidConnect(controller)
        }

        disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let controller = notification.object as? GCController else { return }
            self.controllerDidDisconnect(controller)
        }

        // Handle controllers that were already connected before we started
        // observing (e.g. wired controllers).
        for controller in GCController.controllers() {
            controllerDidConnect(controller)
        }
    }

    /// Remove all observers and clear input handlers.
    func stopObserving() {
        if let observer = connectObserver {
            NotificationCenter.default.removeObserver(observer)
            connectObserver = nil
        }
        if let observer = disconnectObserver {
            NotificationCenter.default.removeObserver(observer)
            disconnectObserver = nil
        }

        // Remove value changed handlers from all tracked controllers.
        for controller in GCController.controllers() {
            controller.extendedGamepad?.valueChangedHandler = nil
        }

        controllerIds.removeAll()
    }

    // MARK: - listGamepads

    /// Returns an array of dictionaries describing currently connected
    /// controllers, suitable for returning over a MethodChannel.
    func listGamepads() -> [[String: Any]] {
        var result: [[String: Any]] = []
        for controller in GCController.controllers() {
            let key = ObjectIdentifier(controller)
            guard let gamepadId = controllerIds[key] else { continue }

            var info: [String: Any] = [
                "id": gamepadId,
                "name": controllerName(controller),
            ]

            if let vendorId = vendorId(for: controller) {
                info["vendorId"] = vendorId
            }
            if let productId = productId(for: controller) {
                info["productId"] = productId
            }

            result.append(info)
        }
        return result
    }

    // MARK: - Connection events

    private func controllerDidConnect(_ controller: GCController) {
        let gamepadId = assignId(for: controller)

        // Register input handlers for the extended gamepad profile.
        registerInputHandlers(for: controller, gamepadId: gamepadId)

        // Wire format: [0, gamepadId, timestamp, connected, name, vendorId, productId]
        let event: [Any] = [
            0,
            gamepadId,
            currentTimestamp(),
            true,
            controllerName(controller),
            vendorId(for: controller) as Any,
            productId(for: controller) as Any,
        ]
        streamHandler.send(event: event)
    }

    private func controllerDidDisconnect(_ controller: GCController) {
        let key = ObjectIdentifier(controller)
        guard let gamepadId = controllerIds.removeValue(forKey: key) else { return }

        controller.extendedGamepad?.valueChangedHandler = nil

        // Wire format: [0, gamepadId, timestamp, connected, name, vendorId, productId]
        let event: [Any] = [
            0,
            gamepadId,
            currentTimestamp(),
            false,
            controllerName(controller),
            vendorId(for: controller) as Any,
            productId(for: controller) as Any,
        ]
        streamHandler.send(event: event)
    }

    // MARK: - Input handlers

    private func registerInputHandlers(for controller: GCController, gamepadId: Int) {
        guard let extendedGamepad = controller.extendedGamepad else { return }

        extendedGamepad.valueChangedHandler = { [weak self] (gamepad, element) in
            guard let self = self else { return }
            self.handleValueChanged(gamepad: gamepad, element: element, gamepadId: gamepadId)
        }
    }

    private func handleValueChanged(gamepad: GCExtendedGamepad,
                                    element: GCControllerElement,
                                    gamepadId: Int) {
        let timestamp = currentTimestamp()

        // D-pad fires as a single GCControllerDirectionPad element, not as
        // individual direction buttons. Expand it into 4 button events.
        if element === gamepad.dpad {
            sendButtonEvent(gamepadId: gamepadId, index: 12,
                            pressed: gamepad.dpad.up.isPressed,
                            value: Double(gamepad.dpad.up.value), timestamp: timestamp)
            sendButtonEvent(gamepadId: gamepadId, index: 13,
                            pressed: gamepad.dpad.down.isPressed,
                            value: Double(gamepad.dpad.down.value), timestamp: timestamp)
            sendButtonEvent(gamepadId: gamepadId, index: 14,
                            pressed: gamepad.dpad.left.isPressed,
                            value: Double(gamepad.dpad.left.value), timestamp: timestamp)
            sendButtonEvent(gamepadId: gamepadId, index: 15,
                            pressed: gamepad.dpad.right.isPressed,
                            value: Double(gamepad.dpad.right.value), timestamp: timestamp)
            return
        }

        // Check buttons.
        if let (index, button) = ButtonMapping.buttonIndex(for: element, in: gamepad) {
            sendButtonEvent(gamepadId: gamepadId, index: index,
                            pressed: button.isPressed,
                            value: Double(button.value), timestamp: timestamp)
            return
        }

        // Check axes (may produce multiple events when a full thumbstick fires).
        let axisEvents = ButtonMapping.axisIndices(for: element, in: gamepad)
        for (index, axisValue) in axisEvents {
            // Wire format: [2, gamepadId, timestamp, axisIndex, value]
            streamHandler.send(event: [2, gamepadId, timestamp, index, axisValue])
        }
    }

    private func sendButtonEvent(gamepadId: Int, index: Int,
                                 pressed: Bool, value: Double, timestamp: Int) {
        // Wire format: [1, gamepadId, timestamp, buttonIndex, pressed, value]
        streamHandler.send(event: [1, gamepadId, timestamp, index, pressed, value])
    }

    // MARK: - Helpers

    private func assignId(for controller: GCController) -> Int {
        let key = ObjectIdentifier(controller)
        if let existing = controllerIds[key] {
            return existing
        }
        let id = nextId
        nextId += 1
        controllerIds[key] = id
        return id
    }

    private func controllerName(_ controller: GCController) -> String {
        let category = controller.productCategory
        if !category.isEmpty {
            return category
        }
        return controller.vendorName ?? "Unknown Controller"
    }

    /// Returns the USB vendor ID for the controller, if available.
    ///
    /// GCController does not directly expose numeric vendor/product IDs
    /// through the public API. We attempt to obtain them from the
    /// underlying physical device description on iOS 16+.
    private func vendorId(for controller: GCController) -> Int? {
        // GCController does not publicly expose numeric vendor IDs on iOS.
        // Return nil; the Dart side treats this as optional.
        return nil
    }

    /// Returns the USB product ID for the controller, if available.
    private func productId(for controller: GCController) -> Int? {
        // GCController does not publicly expose numeric product IDs on iOS.
        // Return nil; the Dart side treats this as optional.
        return nil
    }

    /// Returns the current timestamp in milliseconds since epoch.
    private func currentTimestamp() -> Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }
}
