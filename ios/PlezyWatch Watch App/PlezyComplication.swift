import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct PlezyTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlezyComplicationEntry {
        PlezyComplicationEntry(date: Date(), state: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PlezyComplicationEntry) -> Void) {
        let entry = PlezyComplicationEntry(date: Date(), state: currentState())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlezyComplicationEntry>) -> Void) {
        let entry = PlezyComplicationEntry(date: Date(), state: currentState())
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentState() -> ComplicationState {
        let player = WatchAudioPlayer.shared
        if player.hasQueue, let item = player.currentItem {
            return .playing(title: item.title, artist: item.artist, isPlaying: player.isPlaying)
        }
        return .idle
    }
}

// MARK: - Timeline Entry

struct PlezyComplicationEntry: TimelineEntry {
    let date: Date
    let state: ComplicationState
}

enum ComplicationState {
    case placeholder
    case idle
    case playing(title: String, artist: String?, isPlaying: Bool)
}

// MARK: - Complication Views

struct PlezyComplicationEntryView: View {
    var entry: PlezyComplicationEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryCorner:
            cornerView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    // MARK: - Circular

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            switch entry.state {
            case .placeholder:
                Image(systemName: "music.note")
                    .font(.title3)
            case .idle:
                Image(systemName: "music.note")
                    .font(.title3)
            case .playing(_, _, let isPlaying):
                Image(systemName: isPlaying ? "waveform" : "pause.fill")
                    .font(.title3)
            }
        }
    }

    // MARK: - Rectangular

    @ViewBuilder
    private var rectangularView: some View {
        switch entry.state {
        case .placeholder:
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.body)
                VStack(alignment: .leading) {
                    Text("Plezy")
                        .font(.headline)
                        .widgetAccentable()
                    Text("Music")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        case .idle:
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.body)
                VStack(alignment: .leading) {
                    Text("Plezy")
                        .font(.headline)
                        .widgetAccentable()
                    Text("Tap to browse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        case .playing(let title, let artist, let isPlaying):
            HStack(spacing: 6) {
                Image(systemName: isPlaying ? "waveform" : "pause.fill")
                    .font(.body)
                    .widgetAccentable()
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                    if let artist = artist {
                        Text(artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Corner

    @ViewBuilder
    private var cornerView: some View {
        let iconName: String = {
            switch entry.state {
            case .placeholder, .idle: return "music.note"
            case .playing(_, _, let isPlaying): return isPlaying ? "waveform" : "pause.fill"
            }
        }()
        let labelText: String = {
            switch entry.state {
            case .placeholder, .idle: return "Plezy"
            case .playing(let title, _, _): return title
            }
        }()
        Image(systemName: iconName)
            .font(.title3)
            .widgetLabel(labelText)
    }

    // MARK: - Inline

    private var inlineView: some View {
        switch entry.state {
        case .placeholder, .idle:
            Label("Plezy", systemImage: "music.note")
        case .playing(let title, let artist, _):
            if let artist = artist {
                Label("\(title) — \(artist)", systemImage: "music.note")
            } else {
                Label(title, systemImage: "music.note")
            }
        }
    }
}

// MARK: - Widget Definition

struct PlezyComplication: Widget {
    let kind: String = "PlezyComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlezyTimelineProvider()) { entry in
            PlezyComplicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Plezy")
        .description("Quick access to your music library.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline,
        ])
    }
}

// MARK: - Previews

#Preview(as: .accessoryCircular) {
    PlezyComplication()
} timeline: {
    PlezyComplicationEntry(date: Date(), state: .idle)
    PlezyComplicationEntry(date: Date(), state: .playing(title: "Starboy", artist: "The Weeknd", isPlaying: true))
}

#Preview(as: .accessoryRectangular) {
    PlezyComplication()
} timeline: {
    PlezyComplicationEntry(date: Date(), state: .idle)
    PlezyComplicationEntry(date: Date(), state: .playing(title: "Starboy", artist: "The Weeknd", isPlaying: true))
}
