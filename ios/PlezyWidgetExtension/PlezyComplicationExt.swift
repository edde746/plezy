import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct PlezyTimelineProviderExt: TimelineProvider {
    func placeholder(in context: Context) -> PlezyEntry {
        PlezyEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PlezyEntry) -> Void) {
        completion(PlezyEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlezyEntry>) -> Void) {
        let entry = PlezyEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Entry

struct PlezyEntry: TimelineEntry {
    let date: Date
}

// MARK: - Views

struct PlezyComplicationView: View {
    var entry: PlezyEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "music.note")
                    .font(.title3)
            }
        case .accessoryRectangular:
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.body)
                VStack(alignment: .leading) {
                    Text("Plezy")
                        .font(.headline)
                        .widgetAccentable()
                    Text("Tap to open")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        case .accessoryCorner:
            Image(systemName: "music.note")
                .font(.title3)
                .widgetLabel("Plezy")
        case .accessoryInline:
            Label("Plezy", systemImage: "music.note")
        default:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "music.note")
                    .font(.title3)
            }
        }
    }
}

// MARK: - Widget

struct PlezyComplication: Widget {
    let kind: String = "PlezyComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlezyTimelineProviderExt()) { entry in
            PlezyComplicationView(entry: entry)
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
