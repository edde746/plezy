import SwiftUI

struct FilterSheet: View {
    let filters: [PlexFilter]
    let activeFilters: [String: String]
    var loadValues: (PlexFilter) async -> [PlexFilterValue]
    var onApply: (String, String) -> Void
    var onClear: () -> Void

    @State private var genreValues: [PlexFilterValue] = []
    @State private var isLoading = false

    private var genreFilter: PlexFilter? {
        filters.first(where: { $0.filter == "genre" })
    }

    private var activeGenre: String? {
        guard let genreFilter else { return nil }
        return activeFilters[genreFilter.filter]
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Genre")
                .font(.headline)

            ScrollView {
                VStack(spacing: 0) {
                    if activeGenre != nil {
                        FilterSheetRow(action: { onClear() }) {
                            Text("All Genres")
                                .foregroundStyle(.secondary)
                        }
                        Divider().opacity(0.3)
                    }

                    if isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else {
                        ForEach(Array(genreValues.enumerated()), id: \.element.id) { index, value in
                            if index > 0 {
                                Divider().opacity(0.3)
                            }
                            FilterSheetRow(action: {
                                if let genreFilter {
                                    onApply(genreFilter.filter, value.key)
                                }
                            }) {
                                HStack {
                                    Text(value.title)
                                    Spacer()
                                    if activeGenre == value.key {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(40)
        .task {
            guard let genreFilter else { return }
            isLoading = true
            genreValues = await loadValues(genreFilter)
            isLoading = false
        }
    }
}

private struct FilterSheetRow<Content: View>: View {
    var action: () -> Void
    @ViewBuilder var content: Content

    @FocusState private var isFocused: Bool

    var body: some View {
        content
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(isFocused ? 0.2 : 0))
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .focusable()
            .focused($isFocused)
            .onTapGesture { action() }
            .onPlayPauseCommand { action() }
    }
}
