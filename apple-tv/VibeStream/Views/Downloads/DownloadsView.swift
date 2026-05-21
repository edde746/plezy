import SwiftUI

struct DownloadsView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var viewModel = DownloadsViewModel()
    @State private var selectedTab = 0
    @State private var showLongPressOverlay = false
    @State private var longPressItem: DownloadItem?
    @State private var navigationPath = NavigationPath()

    private var completedMovies: [DownloadItem] {
        viewModel.completedDownloads.filter { $0.type == "movie" }
    }

    private var downloadedShows: [DownloadedShow] {
        let episodes = viewModel.completedDownloads.filter {
            ["show", "episode", "season", "clip"].contains($0.type)
        }
        var grouped: [String: DownloadedShow] = [:]
        for ep in episodes {
            let key = ep.grandparentRatingKey ?? ep.ratingKey
            if var show = grouped[key] {
                show.episodes.append(ep)
                grouped[key] = show
            } else {
                grouped[key] = DownloadedShow(
                    grandparentRatingKey: key,
                    title: ep.grandparentTitle ?? ep.title,
                    thumb: ep.grandparentThumb ?? ep.thumb,
                    episodes: [ep]
                )
            }
        }
        return Array(grouped.values).sorted { $0.title < $1.title }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Custom title + tab bar
                VStack(spacing: 20) {
                    Text("Downloads")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 50)

                    DownloadsTabBar(
                        tabs: ["Queue", "Movies", "TV Shows"],
                        selectedIndex: $selectedTab
                    )
                }
                .padding(.top, 20)

                // Tab content — Queue needs vertical scroll, Movies/Shows handle their own
                Group {
                    switch selectedTab {
                    case 0:
                        ScrollView {
                            queueTab
                        }
                    case 1:
                        moviesTab
                    case 2:
                        tvShowsTab
                    default:
                        EmptyView()
                    }
                }
                .focusSection()
                .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationDestination(for: String.self) { showKey in
                let title = downloadedShows.first(where: { $0.grandparentRatingKey == showKey })?.title ?? ""
                DownloadedEpisodesView(
                    showKey: showKey,
                    showTitle: title,
                    baseURL: appState.activeServer?.baseURL ?? "",
                    token: appState.serverToken,
                    onPlay: { item in
                        coordinator.playMedia(ratingKey: item.ratingKey)
                    }
                )
            }
            .overlay {
                if viewModel.downloads.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                        Text("No downloads")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Download media from detail screens for offline viewing")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .overlay {
                if showLongPressOverlay, let item = longPressItem {
                    DownloadLongPressOverlay(
                        item: item,
                        baseURL: appState.activeServer?.baseURL ?? "",
                        token: appState.serverToken,
                        onDismiss: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showLongPressOverlay = false
                            }
                            longPressItem = nil
                        },
                        onPlay: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showLongPressOverlay = false
                            }
                            longPressItem = nil
                            coordinator.playMedia(ratingKey: item.ratingKey)
                        },
                        onDelete: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showLongPressOverlay = false
                            }
                            longPressItem = nil
                            viewModel.deleteDownload(globalKey: item.globalKey)
                        }
                    )
                    .transition(.opacity)
                }
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
    }

    // MARK: - Queue Tab

    @ViewBuilder
    private var queueTab: some View {
        if let warning = viewModel.storageWarning {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text(warning)
                    .font(.subheadline)
            }
            .padding()
            .glassMaterial(in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 50)
            .padding(.top, 20)
        }

        LazyVStack(spacing: 12) {
            ForEach(viewModel.activeDownloads) { item in
                downloadRow(item)
            }
        }
        .padding(.horizontal, 50)
        .padding(.vertical, 20)
    }

    // MARK: - Movies Tab (poster grid)

    @ViewBuilder
    private var moviesTab: some View {
        if completedMovies.isEmpty {
            emptyDownloadsPlaceholder
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    ForEach(completedMovies) { item in
                        DownloadPosterCard(
                            item: item,
                            baseURL: appState.activeServer?.baseURL ?? "",
                            token: appState.serverToken,
                            onSelect: {
                                coordinator.playMedia(ratingKey: item.ratingKey)
                            },
                            onLongPress: {
                                longPressItem = item
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showLongPressOverlay = true
                                }
                            }
                        )
                    }
                }
                .focusSection()
                .padding(.horizontal, 50)
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - TV Shows Tab (show grouping → drill-in)

    @ViewBuilder
    private var tvShowsTab: some View {
        if downloadedShows.isEmpty {
            emptyDownloadsPlaceholder
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    ForEach(downloadedShows) { show in
                        DownloadShowCard(
                            show: show,
                            baseURL: appState.activeServer?.baseURL ?? "",
                            token: appState.serverToken,
                            onSelect: {
                                navigationPath.append(show.grandparentRatingKey)
                            }
                        )
                    }
                }
                .focusSection()
                .padding(.horizontal, 50)
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - Empty State Placeholder

    private var emptyDownloadsPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.to.line.circle")
                .font(.system(size: 70, weight: .thin))
                .foregroundStyle(.secondary)
            Text("No downloads yet")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Downloaded content will appear here for offline viewing")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Queue Row

    @ViewBuilder
    private func downloadRow(_ item: DownloadItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.title)
                .font(.headline)

            HStack(spacing: 12) {
                Text(item.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(statusColor(item.status))

                if item.totalBytes > 0 {
                    Text("\(item.downloadedFormatted) / \(item.totalFormatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if item.status == .downloading, !item.speedFormatted.isEmpty {
                    Text(item.speedFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                if item.status == .downloading {
                    Text("\(Int(item.progressPercent))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            if item.status == .downloading || item.status == .queued {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                        Capsule()
                            .fill(item.status == .queued ? Color.gray : Color.blue)
                            .frame(width: geo.size.width * max(CGFloat(item.progress), item.status == .queued ? 0 : 0.01))
                    }
                }
                .frame(height: 6)
                .clipShape(Capsule())
            }

            if let error = item.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            // Action buttons
            HStack(spacing: 16) {
                switch item.status {
                case .downloading:
                    Button {
                        viewModel.pauseDownload(globalKey: item.globalKey)
                    } label: {
                        Label("Pause", systemImage: "pause.circle")
                    }
                    .buttonStyle(.bordered)
                case .paused:
                    Button {
                        viewModel.retryDownload(globalKey: item.globalKey, token: appState.serverToken)
                    } label: {
                        Label("Resume", systemImage: "play.circle")
                    }
                    .buttonStyle(.bordered)
                case .failed:
                    Button {
                        viewModel.retryDownload(globalKey: item.globalKey, token: appState.serverToken)
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                default:
                    EmptyView()
                }

                Button(role: .destructive) {
                    viewModel.deleteDownload(globalKey: item.globalKey)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statusColor(_ status: DownloadStatus) -> Color {
        switch status {
        case .downloading: return .blue
        case .completed: return .green
        case .paused: return .yellow
        case .failed: return .red
        case .cancelled: return .gray
        case .queued: return .secondary
        case .partial: return .orange
        }
    }
}

// MARK: - Custom Tab Bar (no Button chrome → no flicker)

private struct DownloadsTabBar: View {
    let tabs: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                DownloadsTab(
                    title: title,
                    isSelected: selectedIndex == index,
                    onSelect: { selectedIndex = index }
                )
            }
            Spacer()
        }
        .focusSection()
        .padding(.horizontal, 50)
    }
}

private struct DownloadsTab: View {
    let title: String
    let isSelected: Bool
    var onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(isFocused ? .black : isSelected ? .white : .white.opacity(0.5))
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isFocused ? .white : isSelected ? .white.opacity(0.15) : .clear)
            )
            .focusable()
            .focused($isFocused)
            .onPlayPauseCommand { onSelect() }
            .onTapGesture { onSelect() }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Downloaded Show Grouping

struct DownloadedShow: Identifiable {
    let grandparentRatingKey: String
    let title: String
    let thumb: String?
    var episodes: [DownloadItem]
    var id: String { grandparentRatingKey }

    var episodeCount: Int { episodes.count }
}

// MARK: - Download Poster Card (Movies)

private struct DownloadPosterCard: View {
    let item: DownloadItem
    let baseURL: String
    let token: String
    var width: CGFloat = 242
    var onSelect: (() -> Void)?
    var onLongPress: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PlexImage(
                path: item.posterPath,
                token: token,
                baseURL: baseURL,
                width: width,
                aspectRatio: 2.0 / 3.0
            )
            .frame(width: width, height: width / (2.0 / 3.0))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .opacity(isFocused ? 1 : 0)
            )

            Text(item.title)
                .font(.caption)
                .lineLimit(1)
                .frame(width: width, alignment: .leading)

            if let year = item.year {
                Text(String(year))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: width, alignment: .leading)
            }
        }
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onPlayPauseCommand { onSelect?() }
        .onTapGesture { onSelect?() }
        .onTVLongPress(duration: 1.0) { onLongPress?() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Play \(item.title)")
    }
}

// MARK: - Download Show Card (TV Shows grid)

private struct DownloadShowCard: View {
    let show: DownloadedShow
    let baseURL: String
    let token: String
    var width: CGFloat = 242
    var onSelect: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PlexImage(
                path: show.thumb ?? "/library/metadata/\(show.grandparentRatingKey)/thumb",
                token: token,
                baseURL: baseURL,
                width: width,
                aspectRatio: 2.0 / 3.0
            )
            .frame(width: width, height: width / (2.0 / 3.0))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .opacity(isFocused ? 1 : 0)
            )

            Text(show.title)
                .font(.caption)
                .lineLimit(1)
                .frame(width: width, alignment: .leading)

            Text("\(show.episodeCount) episode\(show.episodeCount == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: width, alignment: .leading)
        }
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onPlayPauseCommand { onSelect?() }
        .onTapGesture { onSelect?() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(show.title), \(show.episodeCount) episodes")
    }
}

// MARK: - Downloaded Episodes View (drill-in for a show)

private struct DownloadedEpisodesView: View {
    let showKey: String
    let showTitle: String
    let baseURL: String
    let token: String
    var onPlay: ((DownloadItem) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showLongPressOverlay = false
    @State private var longPressItem: DownloadItem?

    /// Live episodes from DownloadManager, filtered & sorted for this show.
    private var sortedEpisodes: [DownloadItem] {
        DownloadManager.shared.completedDownloads
            .filter { ($0.grandparentRatingKey ?? $0.ratingKey) == showKey }
            .sorted {
                let s0 = $0.parentIndex ?? 0
                let s1 = $1.parentIndex ?? 0
                if s0 != s1 { return s0 < s1 }
                return ($0.index ?? 0) < ($1.index ?? 0)
            }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sortedEpisodes) { episode in
                    DownloadEpisodeRow(
                        item: episode,
                        baseURL: baseURL,
                        token: token,
                        onSelect: { onPlay?(episode) },
                        onLongPress: {
                            longPressItem = episode
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showLongPressOverlay = true
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 20)
        }
        .navigationTitle(showTitle)
        .onChange(of: sortedEpisodes.count) { _, newCount in
            if newCount == 0 {
                dismiss()
            }
        }
        .overlay {
            if showLongPressOverlay, let item = longPressItem {
                DownloadLongPressOverlay(
                    item: item,
                    baseURL: baseURL,
                    token: token,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showLongPressOverlay = false
                        }
                        longPressItem = nil
                    },
                    onPlay: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showLongPressOverlay = false
                        }
                        longPressItem = nil
                        onPlay?(item)
                    },
                    onDelete: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showLongPressOverlay = false
                        }
                        longPressItem = nil
                        DownloadManager.shared.deleteDownload(globalKey: item.globalKey)
                    }
                )
                .transition(.opacity)
            }
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
}

// MARK: - Download Episode Row

private struct DownloadEpisodeRow: View {
    let item: DownloadItem
    let baseURL: String
    let token: String
    var onSelect: (() -> Void)?
    var onLongPress: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 16) {
            PlexImage(
                path: item.thumb ?? "/library/metadata/\(item.ratingKey)/thumb",
                token: token,
                baseURL: baseURL,
                width: 240,
                aspectRatio: 16.0 / 9.0
            )

            VStack(alignment: .leading, spacing: 6) {
                // Season line
                if let season = item.parentTitle {
                    Text(season)
                        .font(.subheadline)
                        .foregroundStyle(isFocused ? .white.opacity(0.8) : .white.opacity(0.5))
                        .lineLimit(1)
                } else if let s = item.parentIndex {
                    Text("Season \(s)")
                        .font(.subheadline)
                        .foregroundStyle(isFocused ? .white.opacity(0.8) : .white.opacity(0.5))
                        .lineLimit(1)
                }

                // Episode number + title
                HStack(spacing: 6) {
                    if let e = item.index {
                        Text("E\(e)")
                            .font(.headline)
                            .foregroundStyle(isFocused ? .white : .white.opacity(0.7))
                    }
                    if let epTitle = item.episodeTitle {
                        Text(epTitle)
                            .font(.headline)
                            .foregroundStyle(isFocused ? .white : .white.opacity(0.9))
                            .lineLimit(1)
                    } else {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(isFocused ? .white : .white.opacity(0.9))
                            .lineLimit(1)
                    }
                }

                Text(item.downloadedFormatted)
                    .font(.caption2)
                    .foregroundStyle(isFocused ? .white.opacity(0.7) : .white.opacity(0.4))
            }

            Spacer()

            if isFocused {
                Image(systemName: "play.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.trailing, 20)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 50)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isFocused ? .white.opacity(0.2) : .white.opacity(0.05))
                .padding(.horizontal, 36)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onPlayPauseCommand { onSelect?() }
        .onTapGesture { onSelect?() }
        .onTVLongPress(duration: 1.0) { onLongPress?() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.episodeLabel ?? item.title)
    }
}

// MARK: - Download Long Press Overlay

private struct DownloadLongPressOverlay: View {
    let item: DownloadItem
    let baseURL: String
    let token: String
    var onDismiss: () -> Void
    var onPlay: () -> Void
    var onDelete: () -> Void

    @FocusState private var focusedButton: ButtonID?

    private enum ButtonID: Hashable {
        case play
        case delete
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            HStack(alignment: .center, spacing: 60) {
                // Left side: Poster + title
                VStack(spacing: 16) {
                    PlexImage(
                        path: item.posterPath,
                        token: token,
                        baseURL: baseURL,
                        width: 400,
                        aspectRatio: 2.0 / 3.0
                    )
                    .frame(width: 400, height: 600)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(spacing: 4) {
                        Text(item.grandparentTitle ?? item.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)

                        if let label = item.episodeLabel {
                            Text(label)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        } else if let year = item.year {
                            Text(String(year))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .frame(width: 400)
                }

                // Right side: Action buttons
                VStack(spacing: 12) {
                    overlayButton("Play", icon: "play.fill", id: .play) {
                        onPlay()
                    }

                    overlayButton("Delete Download", icon: "trash", id: .delete) {
                        onDelete()
                    }
                }
            }
        }
        .focusSection()
        .onExitCommand { onDismiss() }
        .onAppear { focusedButton = .play }
    }

    @ViewBuilder
    private func overlayButton(_ title: String, icon: String, id: ButtonID, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
            Text(title)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(width: 500, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(focusedButton == id ? .white : .white.opacity(0.15))
        )
        .foregroundStyle(focusedButton == id ? .black : .white)
        .focusable()
        .focused($focusedButton, equals: id)
        .onTapGesture { action() }
    }
}
