import GameController

/// Maps GCController elements to W3C Standard Gamepad indices.
///
/// W3C Standard Gamepad button mapping:
///   0  = A (South)          8  = Back/View
///   1  = B (East)           9  = Start/Menu
///   2  = X (West)           10 = Left Stick Button
///   3  = Y (North)          11 = Right Stick Button
///   4  = Left Shoulder      12 = D-pad Up
///   5  = Right Shoulder     13 = D-pad Down
///   6  = Left Trigger       14 = D-pad Left
///   7  = Right Trigger      15 = D-pad Right
///                           16 = Guide/Home
///
/// W3C Standard Gamepad axis mapping:
///   0 = Left Stick X    (-1 left, +1 right)
///   1 = Left Stick Y    (-1 up,   +1 down)
///   2 = Right Stick X   (-1 left, +1 right)
///   3 = Right Stick Y   (-1 up,   +1 down)
///
/// Note: GCController reports Y-axis with up = +1, which is the opposite of
/// the W3C convention (up = -1). The axis mapping inverts Y values.
enum ButtonMapping {

    /// Returns the W3C button index and the corresponding `GCControllerButtonInput`
    /// if `element` matches a known button in `gamepad`.
    static func buttonIndex(for element: GCControllerElement,
                            in gamepad: GCExtendedGamepad) -> (Int, GCControllerButtonInput)? {
        // Face buttons
        if element == gamepad.buttonA {
            return (0, gamepad.buttonA)
        }
        if element == gamepad.buttonB {
            return (1, gamepad.buttonB)
        }
        if element == gamepad.buttonX {
            return (2, gamepad.buttonX)
        }
        if element == gamepad.buttonY {
            return (3, gamepad.buttonY)
        }

        // Shoulders
        if element == gamepad.leftShoulder {
            return (4, gamepad.leftShoulder)
        }
        if element == gamepad.rightShoulder {
            return (5, gamepad.rightShoulder)
        }

        // Triggers
        if element == gamepad.leftTrigger {
            return (6, gamepad.leftTrigger)
        }
        if element == gamepad.rightTrigger {
            return (7, gamepad.rightTrigger)
        }

        // Menu buttons
        if let buttonOptions = gamepad.buttonOptions, element == buttonOptions {
            return (8, buttonOptions)
        }
        if element == gamepad.buttonMenu {
            return (9, gamepad.buttonMenu)
        }

        // Thumbstick buttons
        if let leftThumbstickButton = gamepad.leftThumbstickButton, element == leftThumbstickButton {
            return (10, leftThumbstickButton)
        }
        if let rightThumbstickButton = gamepad.rightThumbstickButton, element == rightThumbstickButton {
            return (11, rightThumbstickButton)
        }

        // D-pad individual buttons
        if element == gamepad.dpad.up {
            return (12, gamepad.dpad.up)
        }
        if element == gamepad.dpad.down {
            return (13, gamepad.dpad.down)
        }
        if element == gamepad.dpad.left {
            return (14, gamepad.dpad.left)
        }
        if element == gamepad.dpad.right {
            return (15, gamepad.dpad.right)
        }

        // Guide / Home button
        if let buttonHome = gamepad.buttonHome, element == buttonHome {
            return (16, buttonHome)
        }

        return nil
    }

    /// Returns all W3C axis events for the given `element`.
    ///
    /// The `valueChangedHandler` on `GCExtendedGamepad` may fire with the
    /// entire `GCControllerDirectionPad` (thumbstick) as the element, or with
    /// an individual axis sub-element. When the full thumbstick fires we
    /// return both X and Y axis entries. When a single axis fires we return
    /// one entry.
    ///
    /// Y-axis values are inverted: GCController uses +1 for up, but the W3C
    /// standard uses -1 for up.
    static func axisIndices(for element: GCControllerElement,
                            in gamepad: GCExtendedGamepad) -> [(Int, Double)] {
        // Left stick (full thumbstick element)
        if element == gamepad.leftThumbstick {
            return [
                (0, Double(gamepad.leftThumbstick.xAxis.value)),
                (1, Double(-gamepad.leftThumbstick.yAxis.value)),
            ]
        }

        // Left stick individual axes
        if element == gamepad.leftThumbstick.xAxis {
            return [(0, Double(gamepad.leftThumbstick.xAxis.value))]
        }
        if element == gamepad.leftThumbstick.yAxis {
            // Invert Y: GC up is +1, W3C up is -1
            return [(1, Double(-gamepad.leftThumbstick.yAxis.value))]
        }

        // Right stick (full thumbstick element)
        if element == gamepad.rightThumbstick {
            return [
                (2, Double(gamepad.rightThumbstick.xAxis.value)),
                (3, Double(-gamepad.rightThumbstick.yAxis.value)),
            ]
        }

        // Right stick individual axes
        if element == gamepad.rightThumbstick.xAxis {
            return [(2, Double(gamepad.rightThumbstick.xAxis.value))]
        }
        if element == gamepad.rightThumbstick.yAxis {
            // Invert Y: GC up is +1, W3C up is -1
            return [(3, Double(-gamepad.rightThumbstick.yAxis.value))]
        }

        return []
    }
}
