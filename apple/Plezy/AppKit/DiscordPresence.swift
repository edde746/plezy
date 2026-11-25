import Foundation
import OSLog
import PlezyKit

private let log = Logger(subsystem: "com.edde746.plezy", category: "discord")

/// Discord's Rich Presence on the Mac (`DiscordPresenceHost`), as the desktop app has it on Windows and Linux: the
/// connection to the Discord app runs on a thread of its own, started at the first activity, so nothing the main thread
/// or the player does waits for Discord. Only the newest activity counts: while one is being sent, later ones replace
/// each other.
///
/// While there is an activity to show, the thread stays connected: when Discord isn't running (no endpoint answers) it
/// tries again every `retry`, and when Discord quits it notices within `poll` and connects again, sending the activity
/// anew. Without one it takes the activity down and disconnects. Each kind of failure is logged once until the next
/// connection, so Discord missing for hours writes one line. When the app quits, the connection closes with the
/// process and Discord takes the activity down itself.
///
/// Discord listens on the Unix sockets `discord-ipc-0` to `-9` in the user's temporary folder, `TMPDIR`, which the app
/// shares with it, not being sandboxed; `DiscordRpc` has the frames' opcodes and JSON. Each handshake names the Discord
/// application `applicationId`, which Discord shows the activity as.
final class MacDiscordPresence: DiscordPresenceHost, @unchecked Sendable {
    private let applicationId: String
    private let endpoints = MacDiscordPresence.endpoints()
    private let pid = Int64(ProcessInfo.processInfo.processIdentifier)
    /// Guards `wanted`, `woken` and `started`, and wakes the thread.
    private let condition = NSCondition()
    private var wanted: DiscordActivity?
    /// `publish` was called since the thread last waited: a wake it hasn't taken yet.
    private var woken = false
    private var started = false

    init(applicationId: String) {
        self.applicationId = applicationId
    }

    func publish(activity: DiscordActivity?) {
        condition.lock()
        defer { condition.unlock() }
        wanted = activity
        woken = true
        condition.signal()
        guard !started, activity != nil else { return }
        started = true
        let thread = Thread { [self] in run() }
        thread.name = "Discord presence"
        thread.start()
    }

    private func run() {
        var connection: DiscordConnection?
        var logged: String?
        func note(_ problem: String) {
            if problem != logged { log.notice("\(problem, privacy: .public)") }
            logged = problem
        }
        while true {
            guard let target = currentActivity() else {
                connection?.end()
                connection = nil
                awaitWake(timeout: nil)
                continue
            }
            let live: DiscordConnection
            if let connection {
                live = connection
            } else {
                switch connect() {
                case .success(let opened):
                    if logged != nil { log.notice("connected to Discord") }
                    logged = nil
                    connection = opened
                    live = opened
                case .failure(let failure):
                    note(failure.description)
                    awaitWake(timeout: Self.retry)
                    continue
                }
            }
            do {
                if live.shown != target { try live.show(target) }
                awaitWake(timeout: Self.poll)
                try live.drain()
            } catch {
                note("the connection to Discord ended: \(error)")
                live.close()
                connection = nil
            }
        }
    }

    /// The activity to show now.
    private func currentActivity() -> DiscordActivity? {
        condition.lock()
        defer { condition.unlock() }
        return wanted
    }

    /// Waits for `publish`, at most `timeout` (nil: however long it takes); at once when it was called since the last
    /// wait.
    private func awaitWake(timeout: TimeInterval?) {
        condition.lock()
        defer { condition.unlock() }
        let deadline = timeout.map { Date(timeIntervalSinceNow: $0) }
        while !woken {
            if let deadline {
                if !condition.wait(until: deadline) { break }
            } else {
                condition.wait()
            }
        }
        woken = false
    }

    /// A socket to Discord, after its handshake: READY within `answerTimeout`, or a failure saying why not.
    private func connect() -> Result<DiscordConnection, DiscordIpcFailure> {
        // One endpoint at a time, each opened once: a lazy compactMap's `first` opens the one it finds twice.
        var opened: Int32?
        for path in endpoints where opened == nil { opened = Self.open(path) }
        guard let socket = opened else {
            return .failure(DiscordIpcFailure("Discord isn't running (no IPC endpoint answers)"))
        }
        let connection = DiscordConnection(socket: socket, pid: pid)
        do {
            try connection.write(DiscordRpc.shared.OP_HANDSHAKE, DiscordRpc.shared.handshake(applicationId: applicationId))
            let deadline = Date(timeIntervalSinceNow: Self.answerTimeout)
            while try !connection.awaitReady() {
                if Date() > deadline {
                    throw DiscordIpcFailure("Discord didn't answer the handshake within \(Int(Self.answerTimeout)) s")
                }
                Thread.sleep(forTimeInterval: 0.02)
            }
            return .success(connection)
        } catch {
            connection.close()
            return .failure(DiscordIpcFailure("Discord refused the connection: \(error)"))
        }
    }

    private static let retry: TimeInterval = 30
    private static let poll: TimeInterval = 1
    private static let answerTimeout: TimeInterval = 5

    /// Where Discord listens: `discord-ipc-0` to `-9` in `TMPDIR`, else in `NSTemporaryDirectory()`.
    private static func endpoints() -> [String] {
        var folder = ProcessInfo.processInfo.environment["TMPDIR"].flatMap { $0.isEmpty ? nil : $0 } ?? NSTemporaryDirectory()
        while folder.hasSuffix("/") { folder.removeLast() }
        return (0..<10).map { "\(folder)/discord-ipc-\($0)" }
    }

    /// The socket at `path`, connected and set not to block, or nil when nothing listens there.
    private static func open(_ path: String) -> Int32? {
        var address = sockaddr_un()
        let bytes = Array(path.utf8CString)
        guard bytes.count <= MemoryLayout.size(ofValue: address.sun_path) else { return nil }
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        address.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutableBytes(of: &address.sun_path) { $0.copyBytes(from: bytes.map { UInt8(bitPattern: $0) }) }
        let socket = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard socket >= 0 else { return nil }
        var on: Int32 = 1
        setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
        let connected = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(socket, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) == 0
            }
        }
        guard connected, fcntl(socket, F_SETFL, fcntl(socket, F_GETFL) | O_NONBLOCK) == 0 else {
            Darwin.close(socket)
            return nil
        }
        return socket
    }
}

/// One connection to Discord and what it shows of this app, on the presence's thread alone. Its reads and writes
/// don't block: a read takes what has arrived, and a write waits at most 5 s for Discord to make room.
private final class DiscordConnection {
    private let socket: Int32
    private let pid: Int64
    private var reader = DiscordFrameReader()
    private var buffer = [UInt8](repeating: 0, count: 8192)
    private var nonce = 0
    private var ready = false

    /// The activity Discord was last sent, or nil.
    private(set) var shown: DiscordActivity?

    init(socket: Int32, pid: Int64) {
        self.socket = socket
        self.pid = pid
    }

    func show(_ activity: DiscordActivity?) throws {
        nonce += 1
        try write(DiscordRpc.shared.OP_FRAME, DiscordRpc.shared.setActivity(activity: activity, pid: pid, nonce: String(nonce)))
        shown = activity
    }

    /// Reads what Discord sent: true once its READY has come.
    func awaitReady() throws -> Bool {
        try drain()
        return ready
    }

    /// Handles what Discord sent: answers its pings, logs its errors; throws once it has closed.
    func drain() throws {
        while true {
            let count = Darwin.read(socket, &buffer, buffer.count)
            if count < 0 {
                if errno == EINTR { continue }
                if errno == EAGAIN { return }
                throw DiscordIpcFailure(String(cString: strerror(errno)))
            }
            if count == 0 { throw DiscordIpcFailure("Discord closed the socket") }
            for frame in try reader.add(buffer[..<count]) {
                switch frame.op {
                case DiscordRpc.shared.OP_PING:
                    try write(DiscordRpc.shared.OP_PONG, frame.json)
                case DiscordRpc.shared.OP_CLOSE:
                    throw DiscordIpcFailure(DiscordRpc.shared.errorOf(payload: frame.json) ?? "Discord closed it")
                case DiscordRpc.shared.OP_FRAME:
                    if DiscordRpc.shared.isReady(payload: frame.json) {
                        ready = true
                    } else if let error = DiscordRpc.shared.errorOf(payload: frame.json) {
                        log.warning("Discord refused an update: \(error, privacy: .public)")
                    }
                default:
                    break
                }
            }
        }
    }

    /// Sends the frame of `op` and `json`: the opcode and the JSON's length, each a little-endian 32-bit number, then
    /// the UTF-8 JSON. Throws once Discord is gone, or after 5 s of a full socket.
    func write(_ op: Int32, _ json: String) throws {
        let payload = Array(json.utf8)
        var bytes = [UInt8]()
        bytes.reserveCapacity(Int(DiscordRpc.shared.HEADER_BYTES) + payload.count)
        for value in [UInt32(bitPattern: op), UInt32(payload.count)] {
            withUnsafeBytes(of: value.littleEndian) { bytes.append(contentsOf: $0) }
        }
        bytes.append(contentsOf: payload)
        let deadline = Date(timeIntervalSinceNow: 5)
        var sent = 0
        while sent < bytes.count {
            let count = bytes[sent...].withUnsafeBytes { Darwin.write(socket, $0.baseAddress, $0.count) }
            if count > 0 {
                sent += count
                continue
            }
            if count < 0, errno == EINTR { continue }
            guard count < 0, errno == EAGAIN else { throw DiscordIpcFailure(String(cString: strerror(errno))) }
            // Discord has left its socket's buffer full: give it a moment, then give up on it.
            if Date() > deadline { throw DiscordIpcFailure("Discord isn't reading its socket") }
            Thread.sleep(forTimeInterval: 0.01)
        }
    }

    /// Takes the activity down, then disconnects; a Discord already gone takes it down itself.
    func end() {
        if shown != nil {
            do {
                try show(nil)
            } catch {
                log.debug("Discord had gone before the activity was taken down: \(String(describing: error), privacy: .public)")
            }
        }
        close()
    }

    func close() {
        Darwin.close(socket)
    }
}

/// Turns the bytes Discord sends, as they arrive (a frame split over reads, or several in one), into its frames' opcodes
/// and JSON. A length past `DiscordRpc.MAX_PAYLOAD_BYTES` means the stream can't be followed: `add` throws, and the
/// connection is dropped.
private struct DiscordFrameReader {
    private var pending: [UInt8] = []

    mutating func add(_ bytes: ArraySlice<UInt8>) throws -> [(op: Int32, json: String)] {
        pending.append(contentsOf: bytes)
        let header = Int(DiscordRpc.shared.HEADER_BYTES)
        var frames: [(op: Int32, json: String)] = []
        var offset = 0
        while pending.count - offset >= header {
            let op = Int32(bitPattern: littleEndian(at: offset))
            let length = littleEndian(at: offset + 4)
            guard length <= UInt32(DiscordRpc.shared.MAX_PAYLOAD_BYTES) else {
                throw DiscordIpcFailure("a Discord frame of \(length) bytes")
            }
            let end = offset + header + Int(length)
            if pending.count < end { break }
            frames.append((op, String(decoding: pending[(offset + header)..<end], as: UTF8.self)))
            offset = end
        }
        pending.removeFirst(offset)
        return frames
    }

    /// The little-endian 32-bit number at `index` of `pending`.
    private func littleEndian(at index: Int) -> UInt32 {
        pending[index..<(index + 4)].reversed().reduce(0) { $0 << 8 | UInt32($1) }
    }
}

/// Why a connection to Discord failed or ended, as the log says it.
private struct DiscordIpcFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
