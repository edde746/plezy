import SwiftUI

struct TrackSelectionView: View {
    let audioStreams: [PlexClient.MediaStream]
    let subtitleStreams: [PlexClient.MediaStream]
    var selectedAudioId: Int?
    var selectedSubtitleId: Int?
    var onAudioSelected: (PlexClient.MediaStream) -> Void
    var onSubtitleSelected: (PlexClient.MediaStream?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Audio tracks
                Section("Audio") {
                    ForEach(audioStreams, id: \.id) { stream in
                        Button {
                            onAudioSelected(stream)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(stream.displayTitle ?? "Audio Track")
                                        .font(.body)
                                    if let language = stream.language {
                                        Text(language)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if stream.id == selectedAudioId {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .accessibilityAddTraits(stream.id == selectedAudioId ? .isSelected : [])
                    }
                }

                // Subtitle tracks
                Section("Subtitles") {
                    // None option
                    Button {
                        onSubtitleSelected(nil)
                    } label: {
                        HStack {
                            Text("Off")
                            Spacer()
                            if selectedSubtitleId == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .accessibilityAddTraits(selectedSubtitleId == nil ? .isSelected : [])

                    ForEach(subtitleStreams, id: \.id) { stream in
                        Button {
                            onSubtitleSelected(stream)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack(spacing: 8) {
                                        Text(stream.displayTitle ?? "Subtitle Track")
                                        if stream.isForced {
                                            Text("Forced")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    if let language = stream.language {
                                        Text(language)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if stream.id == selectedSubtitleId {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .accessibilityAddTraits(stream.id == selectedSubtitleId ? .isSelected : [])
                    }
                }
            }
            .navigationTitle("Audio & Subtitles")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
