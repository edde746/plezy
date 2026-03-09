import Foundation
import Network

/// Streams all log output to a TCP socket on the development Mac.
/// Usage: `rlog("message")` anywhere in Watch app code.
/// Listener: `nc -lk 0.0.0.0 8081` on the Mac.
final class RemoteLogger {
    static let shared = RemoteLogger()

    // ── Configure these ──────────────────────────────────────────────
    private let host = "10.0.2.153"
    private let port: UInt16 = 8081
    // ─────────────────────────────────────────────────────────────────

    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "RemoteLogger", qos: .utility)
    private var buffer: [String] = []
    private var isConnected = false
    private let maxBuffer = 500

    private init() {
        connect()
    }

    private func connect() {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )
        let conn = NWConnection(to: endpoint, using: .tcp)
        conn.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.isConnected = true
                self.flushBuffer()
            case .failed, .cancelled:
                self.isConnected = false
                // Retry after 2 seconds
                self.queue.asyncAfter(deadline: .now() + 2) {
                    self.connect()
                }
            default:
                break
            }
        }
        conn.start(queue: queue)
        self.connection = conn
    }

    func log(_ message: String, file: String = #file, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        let ts = Self.timestamp()
        let formatted = "[\(ts)] \(filename):\(line) \(message)\n"

        // Always print locally too
        Swift.print(formatted, terminator: "")

        queue.async { [weak self] in
            guard let self = self else { return }
            if self.isConnected {
                self.send(formatted)
            } else {
                if self.buffer.count < self.maxBuffer {
                    self.buffer.append(formatted)
                }
            }
        }
    }

    private func send(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        connection?.send(content: data, completion: .contentProcessed { error in
            if error != nil {
                self.isConnected = false
            }
        })
    }

    private func flushBuffer() {
        let pending = buffer
        buffer.removeAll()
        for msg in pending {
            send(msg)
        }
    }

    private static func timestamp() -> String {
        let d = Date()
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: d)
    }
}

/// Global convenience function — drop-in replacement for print()
func rlog(_ message: String, file: String = #file, line: Int = #line) {
    RemoteLogger.shared.log(message, file: file, line: line)
}
