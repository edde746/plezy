import Foundation
import Network

/// A test server behind a proxy of the test's own on the loopback, for what the real server won't do on cue: hold a
/// request until the test lets it through (`hold`, `release`), answer a request 404 (`respondNotFound`) or 204 without
/// passing it on (`respondNoContent`: a deletion that deletes nothing), send a request
/// to another path (`redirect`) or change what its JSON answers say (`rewriteJSON`). The app under test signs in through
/// `url` (`--dev-server <kind>=<user>:<password>@<url>`, `server(for:)`): the simulator's apps and the Mac's share the
/// test runner's loopback, and so does the system's background download daemon.
///
/// Each request gets a connection of its own: its `Connection` header becomes `Connection: close`, so one request is one
/// connection, only its head is read and the rest goes through as it is. `log` keeps each request's method and path
/// (no query: it carries the token).
final class ServerProxy: @unchecked Sendable {
    private enum Action { case hold, notFound, noContent }

    private struct Rule {
        var fragment: String
        let action: Action
        /// The rule holds on to the first path it matches: from then on only that path.
        var narrows: Bool
        /// The rule matches the path that is `fragment` alone, not every path containing it.
        var exact = false
        /// The rule matches only requests of this method.
        var method: String?
    }

    /// `http://127.0.0.1:<port>`, the proxy's address (set once it listens).
    private(set) var url = ""
    private let upstreamHost: NWEndpoint.Host
    private let upstreamPort: NWEndpoint.Port
    private let listener: NWListener
    /// Confines everything below.
    private let queue = DispatchQueue(label: "ServerProxy")
    private var rules: [Rule] = []
    private var held: [(path: String, resume: () -> Void)] = []
    private var requests: [String] = []
    private var redirects: [(fragment: String, replacement: String)] = []
    private var rewrites: [(pattern: NSRegularExpression, template: String)] = []

    /// Starts a proxy in front of `upstream` (`http://<host>:<port>`); nil when the loopback refuses a listener.
    init?(upstream: URL) {
        guard let host = upstream.host, let port = NWEndpoint.Port(rawValue: UInt16(upstream.port ?? 80)) else { return nil }
        upstreamHost = NWEndpoint.Host(host)
        upstreamPort = port
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
        guard let listener = try? NWListener(using: parameters) else { return nil }
        self.listener = listener
        // The listener's first settled state: ready, or a refusal (the Mac runner's sandbox without network.server).
        let settled = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var listening = false
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                listening = true
                settled.signal()
            case .waiting, .failed, .cancelled:
                settled.signal()
            default:
                break
            }
        }
        listener.newConnectionHandler = { [unowned self] client in accept(client) }
        listener.start(queue: queue)
        let ready = settled.wait(timeout: .now() + 10) == .success && queue.sync { listening }
        guard ready, let bound = listener.port, bound.rawValue != 0 else {
            listener.cancel()
            return nil
        }
        listener.stateUpdateHandler = nil
        url = "http://127.0.0.1:\(bound.rawValue)"
    }

    /// A `--dev-server` spec, `<kind>=<user>:<password>@<url>`, of the server this proxy stands in front of with the
    /// proxy's address in place of the server's.
    func server(for spec: String) -> String {
        guard let at = spec.lastIndex(of: "@") else { return spec }
        return String(spec[...at]) + url
    }

    /// The upstream URL of a `--dev-server` spec, the part after its last `@`.
    static func upstream(of spec: String) -> URL? {
        spec.lastIndex(of: "@").flatMap { URL(string: String(spec[spec.index(after: $0)...])) }
    }

    /// Holds the first request whose path contains `fragment`, and every later request of that same path, until
    /// `release`.
    func hold(firstPathContaining fragment: String) {
        queue.sync { rules.append(Rule(fragment: fragment, action: .hold, narrows: true)) }
    }

    /// Holds every request whose path contains `fragment`, until `release`.
    func hold(everyPathContaining fragment: String) {
        queue.sync { rules.append(Rule(fragment: fragment, action: .hold, narrows: false)) }
    }

    /// Holds every request whose path is `path` (no query), until `release`.
    func hold(path: String) {
        queue.sync { rules.append(Rule(fragment: path, action: .hold, narrows: false, exact: true)) }
    }

    /// Answers every request whose path contains `fragment` with a 404, from now until `clearRules`.
    func respondNotFound(pathContaining fragment: String) {
        queue.sync { rules.append(Rule(fragment: fragment, action: .notFound, narrows: false)) }
    }

    /// Answers every request whose path is `path` (no query) with a 404, from now until `clearRules`. A hold of the same
    /// path added before it takes the requests first.
    func respondNotFound(path: String) {
        queue.sync { rules.append(Rule(fragment: path, action: .notFound, narrows: false, exact: true)) }
    }

    /// Answers every `method` request whose path contains `fragment` with a 204, passing none of them on, from now until
    /// `clearRules`.
    func respondNoContent(method: String, pathContaining fragment: String) {
        queue.sync { rules.append(Rule(fragment: fragment, action: .noContent, narrows: false, method: method)) }
    }

    /// Sends every request whose path contains `fragment` to the server with `replacement` in its place, from now until
    /// `clearRules`.
    func redirect(pathContaining fragment: String, to replacement: String) {
        queue.sync { redirects.append((fragment, replacement)) }
    }

    /// Replaces each match of `pattern` in every JSON answer's body with `template` (`NSRegularExpression`'s: `$1` its
    /// first group), from now until `clearRules`. Requests go as HTTP/1.0 without compression meanwhile, so each answer
    /// comes plain and whole, ended by the server closing its connection.
    func rewriteJSON(_ pattern: String, with template: String) throws {
        let expression = try NSRegularExpression(pattern: pattern)
        queue.sync { rewrites.append((expression, template)) }
    }

    /// Lets the held requests through, and the later ones the holds would have taken.
    func release() {
        queue.sync {
            rules.removeAll { $0.action == .hold }
            resumeHeld()
        }
    }

    /// Lets the held requests of `path` (`hold(path:)`) through, and the later ones its hold would have taken; the other
    /// holds stay.
    func release(path: String) {
        queue.sync {
            rules.removeAll { $0.action == .hold && $0.exact && $0.fragment == path }
            let waiting = held.filter { $0.path == path }
            held.removeAll { $0.path == path }
            for request in waiting { request.resume() }
        }
    }

    /// Ends every rule: requests go through as they come.
    func clearRules() {
        queue.sync {
            rules.removeAll()
            redirects.removeAll()
            rewrites.removeAll()
            resumeHeld()
        }
    }

    /// The path of the first request held, once one is, waiting at most `timeout` seconds.
    func heldPath(within timeout: TimeInterval) -> String? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let path = queue.sync(execute: { held.first?.path }) { return path }
            // Already a condition wait: this class isn't on the main actor, where waitUntil runs.
            Thread.sleep(forTimeInterval: 0.1)
        }
        return nil
    }

    /// The requests so far, a line each: method and path.
    var log: String {
        queue.sync { requests.joined(separator: "\n") }
    }

    func stop() {
        queue.sync {
            rules.removeAll()
            resumeHeld()
            listener.cancel()
        }
    }

    // MARK: On `queue`

    private func resumeHeld() {
        let waiting = held
        held = []
        for request in waiting { request.resume() }
    }

    /// The action of the first rule that matches `method` and `path`; a narrowing rule keeps to the path from its first
    /// match.
    private func action(for path: String, method: String) -> Action? {
        guard let index = rules.firstIndex(where: { rule in
            (rule.method == nil || rule.method == method) && (rule.exact ? path == rule.fragment : path.contains(rule.fragment))
        }) else { return nil }
        if rules[index].narrows {
            rules[index].fragment = path
            rules[index].narrows = false
        }
        return rules[index].action
    }

    private func accept(_ client: NWConnection) {
        client.start(queue: queue)
        readHead(of: client, Data())
    }

    /// Reads `client`'s request up to the end of its head.
    private func readHead(of client: NWConnection, _ buffer: Data) {
        client.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [self] data, _, isComplete, error in
            var buffer = buffer
            if let data { buffer.append(data) }
            if let end = buffer.range(of: Data("\r\n\r\n".utf8)) {
                handle(client, head: buffer[..<end.lowerBound], rest: buffer[end.upperBound...])
            } else if isComplete || error != nil || buffer.count > 1 << 20 {
                client.cancel()
            } else {
                readHead(of: client, buffer)
            }
        }
    }

    private func handle(_ client: NWConnection, head: Data, rest: Data) {
        let lines = String(decoding: head, as: UTF8.self).components(separatedBy: "\r\n")
        let start = lines[0].split(separator: " ")
        guard start.count >= 3 else { return client.cancel() }
        let path = String(start[1].prefix { $0 != "?" })
        requests.append("\(start[0]) \(path)")
        var target = String(start[1])
        if let redirect = redirects.first(where: { path.contains($0.fragment) }), let range = target.range(of: redirect.fragment) {
            target.replaceSubrange(range, with: redirect.replacement)
        }
        let rewriting = !rewrites.isEmpty
        let dropped = ["connection", "keep-alive", "proxy-connection"] + (rewriting ? ["accept-encoding"] : [])
        let headers = lines.dropFirst().filter { line in !dropped.contains(line.prefix { $0 != ":" }.lowercased()) }
        let requestLine = "\(start[0]) \(target) \(rewriting ? "HTTP/1.0" : start[2])"
        let request = Data(([requestLine] + headers + ["Connection: close", "", ""]).joined(separator: "\r\n").utf8) + rest
        let matched = action(for: path, method: String(start[0]))
        switch matched {
        case .notFound, .noContent:
            let status = matched == .notFound ? "404 Not Found" : "204 No Content"
            let answer = "HTTP/1.1 \(status)\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            client.send(content: Data(answer.utf8), contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in
                client.cancel()
            })
        case .hold:
            held.append((path, { [self] in forward(client, request, rewriting: rewriting) }))
        case nil:
            forward(client, request, rewriting: rewriting)
        }
    }

    /// Sends `request` to the server and pipes both ways until either side ends; `rewriting`, the server's answer is
    /// read whole and rewritten first (`rewriteJSON`).
    private func forward(_ client: NWConnection, _ request: Data, rewriting: Bool) {
        let server = NWConnection(host: upstreamHost, port: upstreamPort, using: .tcp)
        server.stateUpdateHandler = { state in
            if case .failed = state { client.cancel() }
        }
        server.start(queue: queue)
        server.send(content: request, completion: .contentProcessed { _ in })
        pipe(from: client, to: server)
        if rewriting {
            collect(from: server, to: client, Data())
        } else {
            pipe(from: server, to: client)
        }
    }

    /// Reads the server's whole answer, ended by its close, and sends it to `client` rewritten.
    private func collect(from server: NWConnection, to client: NWConnection, _ buffer: Data) {
        server.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [self] data, _, isComplete, error in
            var buffer = buffer
            if let data { buffer.append(data) }
            guard isComplete || error != nil else { return collect(from: server, to: client, buffer) }
            client.send(content: rewritten(buffer), completion: .contentProcessed { [self] _ in close(server, client) })
        }
    }

    /// `answer` with its body rewritten (`rewriteJSON`) and its length set again where it is JSON; else as it is.
    private func rewritten(_ answer: Data) -> Data {
        guard let end = answer.range(of: Data("\r\n\r\n".utf8)) else { return answer }
        var lines = String(decoding: answer[..<end.lowerBound], as: UTF8.self).components(separatedBy: "\r\n")
        let json = lines.contains { $0.lowercased().hasPrefix("content-type:") && $0.lowercased().contains("json") }
        guard json, var body = String(data: answer[end.upperBound...], encoding: .utf8) else { return answer }
        for rewrite in rewrites {
            body = rewrite.pattern.stringByReplacingMatches(in: body, range: NSRange(body.startIndex..., in: body), withTemplate: rewrite.template)
        }
        let bytes = Data(body.utf8)
        lines.removeAll { $0.lowercased().hasPrefix("content-length:") }
        lines.append("Content-Length: \(bytes.count)")
        return Data((lines.joined(separator: "\r\n") + "\r\n\r\n").utf8) + bytes
    }

    private func pipe(from source: NWConnection, to target: NWConnection) {
        source.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [self] data, _, isComplete, error in
            let ended = isComplete || error != nil
            guard let data, !data.isEmpty else {
                if ended { close(source, target) }
                return
            }
            target.send(content: data, completion: .contentProcessed { [self] sendError in
                if sendError != nil || ended {
                    close(source, target)
                } else {
                    pipe(from: source, to: target)
                }
            })
        }
    }

    /// Ends both connections once what was sent to `target` is out.
    private func close(_ source: NWConnection, _ target: NWConnection) {
        source.cancel()
        target.send(content: nil, contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in
            target.cancel()
        })
    }
}
