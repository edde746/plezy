#if DEBUG
  import SwiftUI

  /// Live instrument log + on-device API diagnostics.
  struct DebugView: View {
    @ObservedObject private var logStore = WatchInstrument.store
    @State private var diagnostics: [String] = []
    @State private var isRunning = false
    @State private var showDiagnostics = false

    var body: some View {
      List {
        Section {
          HStack {
            Button("Live Log") { showDiagnostics = false }
              .buttonStyle(.bordered)
              .tint(showDiagnostics ? nil : .accentColor)
            Button("Diagnostics") { showDiagnostics = true }
              .buttonStyle(.bordered)
              .tint(showDiagnostics ? .accentColor : nil)
          }
        }

        if showDiagnostics {
          diagnosticsSection
        } else {
          liveLogSection
        }
      }
      .navigationTitle("Debug")
      .instrumentScreen("DebugView", detail: { "entries=\(logStore.entries.count)" })
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          if showDiagnostics {
            Button("Run") { runDiagnostics() }
              .disabled(isRunning)
          } else {
            Button("Clear") { logStore.clear() }
          }
        }
      }
    }

    private var liveLogSection: some View {
      Section {
        if logStore.entries.isEmpty {
          Text("No instrument events yet")
            .font(.caption2)
            .foregroundStyle(.secondary)
        } else {
          ForEach(logStore.entries.suffix(80)) { entry in
            Text(entry.formatted)
              .font(.system(size: 8, design: .monospaced))
              .foregroundStyle(color(for: entry))
          }
        }
      } header: {
        Text("Instrument stream (\(logStore.entries.count))")
      } footer: {
        Text("Terminal: /usr/bin/log stream --predicate 'subsystem == \"com.edde746.plezy.watch\"'")
          .font(.system(size: 8))
      }
    }

    private var diagnosticsSection: some View {
      Section {
        ForEach(Array(diagnostics.enumerated()), id: \.offset) { _, log in
          Text(log)
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(
              log.contains("ERR") || log.contains("FAIL") ? .red : log.contains("OK") ? .green : .primary)
        }
        if isRunning {
          ProgressView()
        }
      } header: {
        Text("API diagnostics")
      }
    }

    private func color(for entry: WatchInstrument.Entry) -> Color {
      switch entry.category {
      case .timing: return .orange
      case .ui, .navigation: return .cyan
      case .state: return .yellow
      case .playback: return .green
      case .plex: return .blue
      case .connectivity: return .purple
      case .action, .recent: return .primary
      case .lifecycle: return .secondary
      }
    }

    private func diag(_ msg: String) {
      diagnostics.append(msg)
      WatchInstrument.log(.plex, "diag: \(msg)")
    }

    private func runDiagnostics() {
      diagnostics = []
      isRunning = true
      WatchInstrument.action("runDiagnostics")

      Task {
        let client = PlexWatchClient.shared

        await MainActor.run {
          if let creds = client.credentials {
            diag("OK creds: \(creds.serverUrl)")
            diag("   machineId: \(creds.machineIdentifier ?? "none")")
          } else {
            diag("ERR no credentials stored")
          }
        }

        let span = WatchInstrument.begin("diag.full")
        let libs = await client.getLibraries()
        await MainActor.run { diag(libs.isEmpty ? "ERR getLibraries empty" : "OK \(libs.count) libraries") }

        let machineId = await client.fetchMachineIdentifier()
        await MainActor.run { diag(machineId != nil ? "OK machineId: \(machineId!)" : "ERR machineId failed") }

        let musicLibs = await client.getMusicLibraries()
        if let musicLib = musicLibs.first {
          let artists = await client.getRecentlyPlayedArtists(limit: 3)
          await MainActor.run { diag("OK recent artists: \(artists.map(\.title).joined(separator: ", "))") }
        }

        span.end()
        await MainActor.run { isRunning = false }
      }
    }
  }
#endif
