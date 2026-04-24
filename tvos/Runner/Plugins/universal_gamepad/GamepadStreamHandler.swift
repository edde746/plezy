import Flutter

/// FlutterStreamHandler that forwards native gamepad events to Dart.
///
/// Events are queued if no sink is attached yet; once a listener subscribes
/// all queued events are flushed immediately.
public class GamepadStreamHandler: NSObject, FlutterStreamHandler {

    /// The active event sink provided by Flutter's EventChannel.
    private var eventSink: FlutterEventSink?

    /// Events received before the Dart side starts listening.
    private var pendingEvents: [[Any]] = []

    /// Thread-safety lock for sink / queue access.
    private let lock = NSLock()

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        lock.lock()
        eventSink = events

        // Flush any events that arrived before the listener was attached.
        for event in pendingEvents {
            events(event)
        }
        pendingEvents.removeAll()
        lock.unlock()

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        lock.lock()
        eventSink = nil
        lock.unlock()

        return nil
    }

    // MARK: - Internal API

    /// Sends a gamepad event array to Dart.
    ///
    /// If the sink is not yet available the event is queued.
    func send(event: [Any]) {
        lock.lock()
        if let sink = eventSink {
            lock.unlock()
            // Dispatch on the main thread to satisfy Flutter platform channel
            // requirements.
            DispatchQueue.main.async {
                sink(event)
            }
        } else {
            pendingEvents.append(event)
            lock.unlock()
        }
    }
}
