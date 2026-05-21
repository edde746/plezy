import SwiftUI

struct SearchView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var viewModel = SearchViewModel()
    @State private var isNumericMode = false

    private let alphabet = "abcdefghijklmnopqrstuvwxyz".map { String($0) }
    private let numericKeys = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ",", "'", "?", "!"]

    private var currentKeys: [String] {
        isNumericMode ? numericKeys : alphabet
    }

    private var client: PlexClient? {
        guard let server = appState.activeServer, let token = appState.authToken else { return nil }
        return PlexClient(
            baseURL: server.baseURL,
            token: server.accessToken ?? token,
            clientIdentifier: appState.clientIdentifier,
            serverId: server.clientIdentifier,
            serverName: server.name
        )
    }

    var body: some View {
        VStack(spacing: 24) {
            queryDisplay
            alphabetRail
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 60)
            content
            Spacer()
        }
        .padding(.top, 30)
        .onAppear {
            if let client {
                viewModel.setClient(client)
            }
        }
        .onChange(of: viewModel.query) {
            if let client {
                Task {
                    await viewModel.search(client: client)
                }
            }
        }
        .onPlayPauseCommand {
            isNumericMode.toggle()
        }
        .background {
            LinearGradient(
                stops: [
                    .init(color: Color(white: 0.15), location: 0),
                    .init(color: Color(white: 0.06), location: 0.5),
                    .init(color: .black, location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var queryDisplay: some View {
        HStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(viewModel.query.isEmpty ? "Movies, TV Shows, Episodes..." : viewModel.query)
                .font(.system(size: 36))
                .foregroundStyle(viewModel.query.isEmpty ? .tertiary : .primary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 22)
        .frame(maxWidth: 760)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search field")
        .accessibilityValue(viewModel.query.isEmpty ? "empty" : viewModel.query)
    }

    private var alphabetRail: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                PillKey(label: isNumericMode ? "ABC" : "123") {
                    isNumericMode.toggle()
                }
                PillKey(label: "SPACE") {
                    viewModel.query += " "
                }
                ForEach(currentKeys, id: \.self) { key in
                    LetterKey(letter: key) {
                        viewModel.query += key
                    }
                }
            }
            Spacer(minLength: 16)
            IconKey(systemImage: "xmark") {
                if !viewModel.query.isEmpty {
                    viewModel.query.removeLast()
                }
            }
        }
        .padding(.horizontal, 40)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isSearching {
            ProgressView("Searching...")
                .padding(.top, 30)
        } else if viewModel.hasSearched && viewModel.results.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
                Text("No results found")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 40)
        } else if !viewModel.results.isEmpty {
            ScrollView {
                MediaGrid(
                    items: viewModel.results,
                    baseURL: appState.activeServer?.baseURL ?? "",
                    token: appState.serverToken,
                    onItemSelected: { item in
                        coordinator.showMediaDetail(ratingKey: item.ratingKey)
                    }
                )
                .padding(.vertical, 30)
            }
        } else {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
                Text("Search your media")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
        }
    }
}

private struct PillKey: View {
    let label: String
    let action: () -> Void
    @FocusState private var isFocused: Bool

    private var width: CGFloat {
        label == "SPACE" ? 96 : 64
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isFocused ? Color.white : Color.white.opacity(0.12))
            Text(label)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isFocused ? .black : .white.opacity(0.7))
        }
        .frame(width: width, height: 56)
        .contentShape(Rectangle())
        .focusable(true)
        .focused($isFocused)
        .focusEffectDisabled()
        .onTapGesture { action() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}

private struct LetterKey: View {
    let letter: String
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            if isFocused {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
            }
            Text(letter)
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(isFocused ? .black : .white.opacity(0.65))
        }
        .frame(width: 54, height: 62)
        .contentShape(Rectangle())
        .focusable(true)
        .focused($isFocused)
        .focusEffectDisabled()
        .onTapGesture { action() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        if Int(letter) != nil { return "Number \(letter)" }
        if letter.count == 1, letter.first!.isLetter { return "Letter \(letter.uppercased())" }
        return letter
    }
}

private struct IconKey: View {
    let systemImage: String
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isFocused ? Color.white : Color.white.opacity(0.12))
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isFocused ? .black : .white.opacity(0.7))
        }
        .frame(width: 64, height: 56)
        .contentShape(Rectangle())
        .focusable(true)
        .focused($isFocused)
        .focusEffectDisabled()
        .onTapGesture { action() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Delete")
        .accessibilityAddTraits(.isButton)
    }
}
