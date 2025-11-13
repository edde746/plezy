//
//  LibrariesView.swift
//  Plezy tvOS
//
//  Library browser
//

import SwiftUI

struct LibrariesView: View {
    @EnvironmentObject var authService: PlexAuthService
    @State private var libraries: [PlexLibrary] = []
    @State private var selectedLibrary: PlexLibrary?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            } else if libraries.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)

                    Text("No libraries found")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 400, maximum: 600), spacing: 30)
                    ], spacing: 30) {
                        ForEach(libraries) { library in
                            LibraryCard(library: library) {
                                selectedLibrary = library
                            }
                        }
                    }
                    .padding(80)
                }
            }
        }
        .navigationTitle("Libraries")
        .task {
            await loadLibraries()
        }
        .sheet(item: $selectedLibrary) { library in
            LibraryContentView(library: library)
        }
    }

    private func loadLibraries() async {
        guard let client = authService.currentClient else {
            return
        }

        isLoading = true

        do {
            libraries = try await client.getLibraries()
        } catch {
            print("Error loading libraries: \(error)")
        }

        isLoading = false
    }
}

struct LibraryCard: View {
    let library: PlexLibrary
    let action: () -> Void
    @State private var isFocused = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: libraryIcon)
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                    .frame(width: 80)

                VStack(alignment: .leading, spacing: 8) {
                    Text(library.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(library.type.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(isFocused ? 0.15 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isFocused ? Color.orange : Color.white.opacity(0.2), lineWidth: isFocused ? 4 : 2)
            )
        }
        .buttonStyle(.plain)
        .focusable(true) { focused in
            withAnimation(.easeInOut(duration: 0.2)) {
                isFocused = focused
            }
        }
    }

    private var libraryIcon: String {
        switch library.mediaType {
        case .movie:
            return "film.fill"
        case .show:
            return "tv.fill"
        case .artist:
            return "music.note.list"
        case .photo:
            return "photo.on.rectangle.angled"
        case .unknown:
            return "folder.fill"
        }
    }
}

#Preview {
    LibrariesView()
        .environmentObject(PlexAuthService())
}
