//
//  LibraryContentView.swift
//  Plezy tvOS
//
//  Content browser for a specific library
//

import SwiftUI

struct LibraryContentView: View {
    let library: PlexLibrary
    @EnvironmentObject var authService: PlexAuthService
    @Environment(\.dismiss) var dismiss
    @State private var items: [PlexMetadata] = []
    @State private var isLoading = true
    @State private var selectedMedia: PlexMetadata?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)

                    Text(library.title)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 30)

                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Loading content...")
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if items.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)

                        Text("No content found")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 300, maximum: 350), spacing: 30)
                        ], spacing: 40) {
                            ForEach(items) { item in
                                MediaCard(media: item) {
                                    selectedMedia = item
                                }
                            }
                        }
                        .padding(80)
                    }
                }
            }
        }
        .task {
            await loadContent()
        }
        .sheet(item: $selectedMedia) { media in
            MediaDetailView(media: media)
        }
    }

    private func loadContent() async {
        guard let client = authService.currentClient else {
            return
        }

        isLoading = true

        do {
            items = try await client.getLibraryContent(sectionKey: library.key, size: 100)
        } catch {
            print("Error loading library content: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    LibraryContentView(library: PlexLibrary(
        key: "1",
        title: "Movies",
        type: "movie",
        agent: nil,
        scanner: nil,
        language: nil,
        uuid: UUID().uuidString,
        updatedAt: nil,
        createdAt: nil,
        scannedAt: nil,
        thumb: nil,
        art: nil
    ))
    .environmentObject(PlexAuthService())
}
