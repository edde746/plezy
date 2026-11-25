import SwiftUI
import PlezyKit

/// Logs: the device block, then the app's log, newest first, each entry's time, level and tag over its message and
/// error; Refresh, Copy, Upload and Clear in the toolbar (the last three while there is a log; on Apple TV, whose
/// bar has no buttons, a row of them over the log). Each entry takes focus, so a remote scrolls through them.
/// Harness names: `settings.logs.<refresh|copy|upload|clear|entry.i>`.
struct LogsScreen: View {
    let app: AppModel

    @State private var model: SettingsStoreModel<any LogsStore, LogsUiState>?

    init(app: AppModel, route: any Route) {
        self.app = app
        _model = State(initialValue: .retained(
            app: app, route: route, key: "settings.logs",
            create: { app.session.settings.logs() },
            flow: { $0.state },
            release: { $0.release() }
        ))
    }

    var body: some View {
        if let model {
            LogsContent(app: app, model: model)
        }
    }
}

private struct LogsContent: View {
    let app: AppModel
    let model: SettingsStoreModel<any LogsStore, LogsUiState>

    var body: some View {
        let state = model.state.state
        let store = model.store
        SettingsPageFrame(title: T.shared.screens.logs, id: SettingsPageId.logs.probe) {
            Form {
                #if os(tvOS)
                Section {
                    actions(state, store)
                }
                #endif
                if !state.hasLogs {
                    Section {
                        Label(T.shared.messages.noLogsAvailable, systemImage: SettingIcon.article.systemImage)
                            .mutedForeground()
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("settings.logs.empty")
                    }
                    .listRowBackground(Color.clear)
                } else {
                    if !state.header.isEmpty {
                        Section {
                            Text(state.header)
                                .font(.footnote.monospaced())
                                .mutedForeground()
                        }
                        .listRowBackground(Color.clear)
                    }
                    Section {
                        ForEach(Array(state.entries.enumerated()), id: \.offset) { index, entry in
                            LogEntryRow(entry: entry)
                                .accessibilityIdentifier("settings.logs.entry.\(index)")
                        }
                    }
                }
            }
            .settingsForm()
        }
        #if !os(tvOS)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                actions(state, store)
            }
        }
        #endif
        .modifier(SettingsEvents(app: app, events: store.events, store: nil))
        .task { await model.state.observe() }
        .onAppear {
            if model.appeared { store.refresh() }
            model.appeared = true
        }
    }

    @ViewBuilder
    private func actions(_ state: LogsUiState, _ store: any LogsStore) -> some View {
        let logs = T.shared.logs
        Button { store.refresh() } label: { Label(T.shared.common.refresh, systemImage: "arrow.clockwise") }
            #if !os(tvOS)
            .keyboardShortcut("r", modifiers: .command)
            #endif
            .accessibilityIdentifier("settings.logs.refresh")
        #if !os(tvOS)
        Button { store.doCopy() } label: { Label(logs.copyLogs, systemImage: "doc.on.doc") }
            .disabled(!state.hasLogs)
            .accessibilityIdentifier("settings.logs.copy")
        #endif
        if state.uploading {
            ProgressView()
        } else {
            Button { store.upload() } label: { Label(logs.uploadLogs, systemImage: SettingIcon.upload.systemImage) }
                .disabled(!state.hasLogs)
                .accessibilityIdentifier("settings.logs.upload")
        }
        Button(role: .destructive) { store.clear() } label: { Label(logs.clearLogs, systemImage: "trash").destructiveLabel() }
            .disabled(!state.hasLogs)
            .accessibilityIdentifier("settings.logs.clear")
    }
}

/// One log entry: time, level (in its colour) and tag, then the message and the error, monospace. On Apple TV it takes
/// focus.
private struct LogEntryRow: View {
    let entry: LogEntryUi

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(ClockTimeKt.logClockTime(epochMillis: entry.epochMillis, use24HourClock: LiveTvClock.uses24Hour)).mutedForeground()
                Text(entry.level).bold().foregroundStyle(levelColor)
                Text(entry.tag).mutedForeground()
            }
            .font(.caption.monospaced())
            Text(entry.message).font(.footnote.monospaced())
            if let error = entry.error {
                Text(error).font(.footnote.monospaced()).foregroundStyle(Palette.error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        #if !os(tvOS)
        .textSelection(.enabled)
        #endif
        #if os(tvOS)
        .focusable()
        #endif
    }

    /// Errors red, warnings amber, the rest muted.
    private var levelColor: Color {
        switch entry.level.uppercased() {
        case "ERROR", "FATAL", "E": Palette.error
        case "WARNING", "WARN", "W": SettingsColors.warning
        default: Palette.onSurfaceVariant
        }
    }
}
