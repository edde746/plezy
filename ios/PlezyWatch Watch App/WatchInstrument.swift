import Foundation
import os
import SwiftUI

/// Structured, timestamped instrumentation for Plezy Watch.
/// Stream with: log stream --predicate 'subsystem == "com.edde746.plezy.watch"' --style compact
enum WatchInstrument {
  static let subsystem = "com.edde746.plezy.watch"
  private static let bootTime = CFAbsoluteTimeGetCurrent()
  private static let maxEntries = 600
  private static let tokenInUrl = try! NSRegularExpression(
    pattern: "(x-plex-token(?:=|%3d))[^&\\s\"'<>]+",
    options: [.caseInsensitive]
  )
  private static let secretsLock = NSLock()
  private static var secrets = Set<String>()

  enum Category: String, CaseIterable {
    case lifecycle
    case ui
    case navigation
    case state
    case action
    case playback
    case plex
    case connectivity
    case recent
    case timing

    var osLog: OSLog {
      OSLog(subsystem: subsystem, category: rawValue)
    }
  }

  struct Entry: Identifiable, Equatable {
    let id: UUID
    let uptimeMs: Int
    let category: Category
    let message: String

    var formatted: String {
      String(format: "+%06dms [%-12@] %@", uptimeMs, category.rawValue as NSString, message)
    }
  }

  // MARK: - Redaction

  /// Every message passes through here on its way to the log, because this
  /// log is public in release builds and a URLError's description quotes the
  /// URL it failed on. Call sites should still not log tokens; this is what
  /// catches the ones nobody thought of.
  static func redact(_ message: String) -> String {
    let range = NSRange(message.startIndex..., in: message)
    var redacted = tokenInUrl.stringByReplacingMatches(
      in: message,
      range: range,
      withTemplate: "$1<redacted>"
    )
    secretsLock.lock()
    let known = secrets
    secretsLock.unlock()
    for secret in known {
      redacted = redacted.replacingOccurrences(of: secret, with: "<redacted>")
    }
    return redacted
  }

  /// Have [redact] also catch this exact value wherever it appears.
  static func registerSecret(_ secret: String) {
    guard !secret.isEmpty else { return }
    secretsLock.lock()
    secrets.insert(secret)
    secretsLock.unlock()
  }

  // MARK: - Public logging API

  static func log(
    _ category: Category,
    _ message: String,
    file: String = #fileID,
    line: Int = #line
  ) {
    let entry = makeEntry(category: category, message: message)
    emit(entry, file: file, line: line)
  }

  static func uiAppear(_ screen: String, detail: String? = nil) {
    let msg = detail.map { "\(screen) appear — \($0)" } ?? "\(screen) appear"
    log(.ui, msg)
  }

  static func uiDisappear(_ screen: String) {
    log(.ui, "\(screen) disappear")
  }

  static func uiSnapshot(screen: String, fields: [String: CustomStringConvertible]) {
    let body =
      fields
      .sorted { $0.key < $1.key }
      .map { "\($0.key)=\($0.value)" }
      .joined(separator: " ")
    log(.ui, "\(screen) visible {\(body)}")
  }

  static func state(screen: String, _ name: String, from old: String, to new: String) {
    guard old != new else { return }
    log(.state, "\(screen).\(name): \(old) → \(new)")
  }

  static func action(_ label: String, detail: String? = nil) {
    let msg = detail.map { "\(label) — \($0)" } ?? label
    log(.action, msg)
  }

  static func timing(_ label: String, durationMs: Int, detail: String? = nil) {
    let msg = detail.map { "\(label) took \(durationMs)ms (\($0))" } ?? "\(label) took \(durationMs)ms"
    log(.timing, msg)
  }

  static func begin(_ label: String, detail: String? = nil) -> TimingSpan {
    TimingSpan(label: label, detail: detail)
  }

  static func playback(_ message: String) { log(.playback, message) }
  static func plex(_ message: String) { log(.plex, message) }
  static func connectivity(_ message: String) { log(.connectivity, message) }
  static func recent(_ message: String) { log(.recent, message) }

  // MARK: - Ring buffer (DebugView)

  #if DEBUG
    @MainActor
    static let store = LogStore()

    @MainActor
    final class LogStore: ObservableObject {
      @Published private(set) var entries: [Entry] = []

      fileprivate func append(_ entry: Entry) {
        entries.append(entry)
        if entries.count > maxEntries {
          entries.removeFirst(entries.count - maxEntries)
        }
      }

      func clear() {
        entries.removeAll()
      }
    }
  #endif

  // MARK: - Timing span

  final class TimingSpan {
    private let label: String
    private let detail: String?
    private let started = CFAbsoluteTimeGetCurrent()
    private var ended = false

    init(label: String, detail: String?) {
      self.label = label
      self.detail = detail
      let detailSuffix = detail.map { " (\($0))" } ?? ""
      WatchInstrument.log(.timing, "▶ \(label)\(detailSuffix)")
    }

    func end(extra: String? = nil) {
      guard !ended else { return }
      ended = true
      let ms = Int((CFAbsoluteTimeGetCurrent() - started) * 1000)
      let combined = [detail, extra].compactMap { $0 }.joined(separator: " · ")
      WatchInstrument.timing(label, durationMs: ms, detail: combined.isEmpty ? nil : combined)
    }

    deinit {
      if !ended {
        let ms = Int((CFAbsoluteTimeGetCurrent() - started) * 1000)
        WatchInstrument.log(.timing, "⚠ \(label) span not ended (+\(ms)ms)")
      }
    }
  }

  // MARK: - Internals

  private static func uptimeMs() -> Int {
    Int((CFAbsoluteTimeGetCurrent() - bootTime) * 1000)
  }

  private static func makeEntry(category: Category, message: String) -> Entry {
    Entry(
      id: UUID(),
      uptimeMs: uptimeMs(),
      category: category,
      message: redact(message)
    )
  }

  private static func emit(_ entry: Entry, file: String, line: Int) {
    let formatted = entry.formatted
    // os_log for Console.app / log stream
    os_log("%{public}@", log: entry.category.osLog, type: .default, formatted)
    // stderr for xcodebuild / simctl launch console capture
    fputs(formatted + "\n", stderr)

    #if DEBUG
      Task { @MainActor in
        store.append(entry)
      }
    #endif
  }
}

// MARK: - View instrumentation

extension View {
  /// Log when this screen appears/disappears.
  func instrumentScreen(_ name: String, detail: (() -> String)? = nil) -> some View {
    modifier(ScreenInstrumentModifier(name: name, detail: detail))
  }

  /// Log whenever an Equatable value changes while this view is mounted.
  func instrumentState<V: Equatable>(_ name: String, in screen: String, value: V) -> some View {
    modifier(StateInstrumentModifier(name: name, screen: screen, value: value))
  }
}

private struct ScreenInstrumentModifier: ViewModifier {
  let name: String
  let detail: (() -> String)?

  func body(content: Content) -> some View {
    content
      .onAppear { WatchInstrument.uiAppear(name, detail: detail?()) }
      .onDisappear { WatchInstrument.uiDisappear(name) }
  }
}

private struct StateInstrumentModifier<V: Equatable>: ViewModifier {
  let name: String
  let screen: String
  @State private var lastValue: V?

  let value: V

  func body(content: Content) -> some View {
    content
      .onAppear { lastValue = value }
      .onChange(of: value) { old, new in
        WatchInstrument.state(
          screen: screen,
          name,
          from: String(describing: old),
          to: String(describing: new)
        )
        lastValue = new
      }
  }
}
