import SwiftUI

struct PersonFilmographySheet: View {
    let person: PlexRole
    let sectionId: String
    let baseURL: String
    let token: String
    let onSelectItem: (PlexMetadata) -> Void

    @State private var allContent: [PlexMetadata] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            // Header — compact with smaller photo
            HStack(spacing: 16) {
                if let thumb = person.thumb {
                    PlexImage(
                        path: thumb,
                        token: token,
                        baseURL: baseURL,
                        width: 150,
                        aspectRatio: 1
                    )
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(.quaternary)
                        .frame(width: 150, height: 150)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(person.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    if let roleName = person.displayRole {
                        Text(roleName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if !isLoading {
                        Text("\(allContent.count) title\(allContent.count == 1 ? "" : "s") in your library")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 50)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if !allContent.isEmpty {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(180), spacing: 40), count: min(allContent.count, 4)),
                    spacing: 40
                ) {
                    ForEach(allContent) { item in
                        PosterCard(
                            item: item,
                            token: token,
                            baseURL: baseURL,
                            onSelect: { onSelectItem(item) }
                        )
                    }
                }
                .padding(.horizontal, 50)
            }
        }
        .padding(.vertical, 30)
        }
        .background {
            LinearGradient(
                stops: [
                    .init(color: Color(white: 0.10), location: 0),
                    .init(color: Color(white: 0.05), location: 0.5),
                    .init(color: .black, location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .task {
            await loadFilmography()
        }
    }

    private func loadFilmography() async {
        guard let personId = person.id else {
            isLoading = false
            return
        }

        let client = PlexClient(
            baseURL: baseURL,
            token: token,
            clientIdentifier: "",
            serverId: nil,
            serverName: nil
        )

        allContent = (try? await client.getContentByPerson(sectionId: sectionId, personId: personId, role: "actor")) ?? []
        isLoading = false
    }
}

// MARK: - Poster Card

private struct PosterCard: View {
    let item: PlexMetadata
    let token: String
    let baseURL: String
    let onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PlexImage(
                path: item.posterThumb(),
                token: token,
                baseURL: baseURL,
                width: 180,
                aspectRatio: 2/3
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white, lineWidth: isFocused ? 3 : 0)
            )

            Text(item.displayTitle)
                .font(.caption)
                .lineLimit(2)
                .frame(width: 180, alignment: .leading)

            if let year = item.year {
                Text(String(year))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 180, alignment: .leading)
            }
        }
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onPlayPauseCommand { onSelect() }
        .onTapGesture { onSelect() }
    }
}
