import SwiftUI
import WatchKit

struct IdleView: View {
  @EnvironmentObject var connectivity: WatchConnectivityManager
  @ObservedObject private var audioPlayer = WatchAudioPlayer.shared
  @ObservedObject private var recentlyPlayed = RecentlyPlayedManager.shared
  @State private var hasCredentials = PlexWatchClient.shared.hasCredentials
  @State private var isSignedOut = PlexWatchClient.shared.isSignedOutOnWatch
  @State private var replayError: String?
  @State private var loadingItemId: String?
  @State private var credentialsExpiredMessage: String?

  var body: some View {
    NavigationStack {
      List {
        if audioPlayer.hasQueue {
          nowPlayingSection
        }

        if hasCredentials {
          quickPlaySection
        }

        if !recentlyPlayed.recentArtists.isEmpty {
          recentArtistsSection
        } else if hasCredentials && recentlyPlayed.isSyncingFromPlex {
          loadingRecentSection
        }

        if !recentNonArtistItems.isEmpty {
          recentlyPlayedSection
        }

        if hasCredentials {
          browseSection
          accountSection
        } else if isSignedOut {
          signedOutSection
        } else if connectivity.isReachable {
          syncingSection
        } else {
          setupSection
        }
      }
      .navigationTitle("Plezy")
      .refreshable {
        if hasCredentials {
          await recentlyPlayed.syncFromPlex(force: true)
        } else {
          connectivity.requestCredentials()
        }
      }
    }
    .instrumentScreen("IdleView")
    .instrumentState("hasCredentials", in: "IdleView", value: hasCredentials)
    .instrumentState("hasQueue", in: "IdleView", value: audioPlayer.hasQueue)
    .instrumentState("recentArtistCount", in: "IdleView", value: recentlyPlayed.recentArtists.count)
    .instrumentState("recentItemCount", in: "IdleView", value: recentlyPlayed.items.count)
    .instrumentState("isSyncing", in: "IdleView", value: recentlyPlayed.isSyncingFromPlex)
    .onAppear {
      logIdleSnapshot()
      credentialsExpiredMessage = nil
      if hasCredentials {
        Task { await PlexWatchClient.shared.fetchMachineIdentifier() }
      } else {
        connectivity.startCredentialsRetryLoop()
        connectivity.requestCredentials()
      }
    }
    .onDisappear {
      if hasCredentials {
        connectivity.stopCredentialsRetryLoop()
      }
    }
    .onChange(of: recentlyPlayed.recentArtists.count) { _, _ in logIdleSnapshot() }
    .onChange(of: recentlyPlayed.items.count) { _, _ in logIdleSnapshot() }
    .onChange(of: audioPlayer.hasQueue) { _, _ in logIdleSnapshot() }
    .task(id: hasCredentials) {
      guard hasCredentials else { return }
      #if DEBUG
        if InstrumentDriver.isEnabled { return }
      #endif
      await recentlyPlayed.syncFromPlex()
    }
    .onReceive(connectivity.objectWillChange) { _ in
      refreshCredentialState()
    }
    .onReceive(NotificationCenter.default.publisher(for: .plexCredentialsDidChange)) { _ in
      refreshCredentialState()
    }
    .onReceive(NotificationCenter.default.publisher(for: .plexCredentialsExpired)) { _ in
      hasCredentials = false
      credentialsExpiredMessage = "Plex sign-in expired. Open Plezy on iPhone or set up manually."
      connectivity.startCredentialsRetryLoop()
    }
  }

  private func refreshCredentialState() {
    isSignedOut = PlexWatchClient.shared.isSignedOutOnWatch
    let updated = PlexWatchClient.shared.hasCredentials
    if updated != hasCredentials {
      hasCredentials = updated
      if updated {
        credentialsExpiredMessage = nil
        connectivity.stopCredentialsRetryLoop()
      }
    }
  }

  private var recentNonArtistItems: [RecentlyPlayedManager.RecentItem] {
    recentlyPlayed.items.filter { $0.type != .artist }
  }

  // MARK: - Now Playing

  private var nowPlayingSection: some View {
    Section {
      Button(action: {
        WKInterfaceDevice.current().play(.click)
        connectivity.returnToPlayer()
      }) {
        HStack(spacing: 10) {
          ZStack {
            Circle()
              .fill(Color.accentColor.opacity(0.2))
              .frame(width: 36, height: 36)
            Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
              .font(.body)
              .foregroundColor(.accentColor)
          }
          VStack(alignment: .leading, spacing: 2) {
            Text(audioPlayer.currentItem?.title ?? "Now Playing")
              .font(.headline)
              .lineLimit(1)
            if let artist = audioPlayer.currentItem?.artist {
              Text(artist)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }
        }
      }
      .listRowBackground(Color.accentColor.opacity(0.1))
    }
  }

  // MARK: - Quick play (one-tap actions)

  private var quickPlaySection: some View {
    Section {
      NavigationLink(destination: SearchableView()) {
        Label("Search", systemImage: "magnifyingglass")
      }

      if recentlyPlayed.recentArtists.count >= 2 {
        Button(action: { shuffleMix() }) {
          HStack {
            Label("Shuffle Mix", systemImage: "shuffle")
            Spacer()
            if loadingItemId == "shuffle-mix" {
              ProgressView().scaleEffect(0.7)
            }
          }
        }
        .disabled(loadingItemId != nil)
      }
    }
  }

  // MARK: - Recent artists

  @ViewBuilder
  private var recentArtistsSection: some View {
    Section {
      if let credentialsExpiredMessage {
        Text(credentialsExpiredMessage)
          .font(.caption2)
          .foregroundStyle(.orange)
      }

      if let replayError {
        Text(replayError)
          .font(.caption2)
          .foregroundStyle(.red)
      }

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
          ForEach(recentlyPlayed.recentArtists.prefix(10)) { artist in
            RecentArtistChip(
              item: artist,
              isLoading: loadingItemId == artist.id,
              onRadio: { replayArtistRadio(artist) },
              onPlayAll: { replayArtistPlayAll(artist) }
            )
          }
        }
        .padding(.vertical, 4)
      }
      .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
    } header: {
      HStack {
        Text("Recent Artists")
        if recentlyPlayed.isSyncingFromPlex {
          ProgressView().scaleEffect(0.6)
        }
      }
    } footer: {
      Text("Tap for radio · hold for more")
        .font(.caption2)
    }
  }

  private var loadingRecentSection: some View {
    Section {
      HStack(spacing: 10) {
        ProgressView()
        Text("Loading recent artists…")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  // MARK: - Recently played list

  @ViewBuilder
  private var recentlyPlayedSection: some View {
    Section("Recently Played") {
      if let replayError {
        Text(replayError)
          .font(.caption2)
          .foregroundStyle(.red)
      }

      ForEach(recentNonArtistItems.prefix(8)) { item in
        RecentItemRow(
          item: item,
          isLoading: loadingItemId == item.id,
          onTap: { replayItem(item) }
        )
        .contextMenu { recentContextMenu(for: item) }
      }
    }
  }

  @ViewBuilder
  private func recentContextMenu(for item: RecentlyPlayedManager.RecentItem) -> some View {
    switch item.type {
    case .album:
      Button("Play Album") { replayItem(item) }
      Button("Album Radio") { replayRadio(item) }
    case .track, .station:
      Button("Track Radio") { replayRadio(item) }
      Button("Play Track") { replayPlayAll(item, shuffle: false) }
    case .artist:
      Button("Artist Radio") { replayItem(item) }
      Button("Play All") { replayPlayAll(item, shuffle: false) }
    }
  }

  // MARK: - Browse

  private var browseSection: some View {
    Section {
      NavigationLink(destination: LibraryBrowserView()) {
        Label("Library", systemImage: "music.note.list")
      }
      #if DEBUG
        NavigationLink(destination: DebugView()) {
          Label("Debug Log", systemImage: "waveform")
        }
      #endif
    }
  }

  // MARK: - Account

  private var accountSection: some View {
    Section {
      HStack {
        Image(systemName: "server.rack")
          .foregroundStyle(.secondary)
        VStack(alignment: .leading, spacing: 2) {
          Text(PlexWatchClient.shared.serverDisplayName)
            .font(.caption)
            .lineLimit(1)
          Text("Works without iPhone")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      if connectivity.isReachable {
        Button("Refresh from iPhone") {
          connectivity.requestCredentials(force: true)
        }
      }
      NavigationLink(destination: SetupView()) {
        Label("Server Settings", systemImage: "gear")
      }
      Button(role: .destructive) {
        connectivity.signOut()
        credentialsExpiredMessage = nil
      } label: {
        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
      }
    }
  }

  // MARK: - Setup states

  private var syncingSection: some View {
    Section {
      HStack(spacing: 10) {
        ProgressView()
        VStack(alignment: .leading, spacing: 2) {
          Text("Phone connected")
            .font(.body)
          Text(connectivity.credentialsHint ?? "Getting Plex credentials…")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .onAppear { connectivity.requestCredentials() }
    } footer: {
      Text("Keep Plezy open on your iPhone")
        .font(.caption2)
    }
  }

  private var signedOutSection: some View {
    Section {
      Text("Signed out")
        .font(.body)
      Button("Sign In from iPhone") {
        connectivity.requestCredentials(force: true)
        refreshCredentialState()
      }
      NavigationLink(destination: SetupView()) {
        Label("Manual Setup", systemImage: "gear")
      }
    }
  }

  private var setupSection: some View {
    Section {
      VStack(alignment: .leading, spacing: 8) {
        Label("Open Plezy on iPhone", systemImage: "iphone")
          .font(.body)
        Text(connectivity.credentialsHint ?? "Phone not connected")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Text("Or set up manually:")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      NavigationLink(destination: SetupView()) {
        Label("Manual Setup", systemImage: "gear")
      }
    }
  }

  // MARK: - Actions

  private func logIdleSnapshot() {
    WatchInstrument.uiSnapshot(
      screen: "IdleView",
      fields: [
        "hasCredentials": hasCredentials,
        "hasQueue": audioPlayer.hasQueue,
        "isPlaying": audioPlayer.isPlaying,
        "phoneReachable": connectivity.isReachable,
        "recentArtists": recentlyPlayed.recentArtists.count,
        "recentItems": recentlyPlayed.items.count,
        "syncing": recentlyPlayed.isSyncingFromPlex,
      ])
  }

  private func shuffleMix() {
    guard let artist = recentlyPlayed.recentArtists.randomElement() else { return }
    WatchInstrument.action("shuffleMix", detail: artist.title)
    withLoading(id: "shuffle-mix") {
      await MusicPlaybackCoordinator.shared.playRecent(artist, connectivity: connectivity)
    }
  }

  private func withLoading(id: String, work: @escaping () async -> String?) {
    guard loadingItemId == nil else { return }
    loadingItemId = id
    replayError = nil
    Task {
      let error = await work()
      await MainActor.run {
        loadingItemId = nil
        replayError = error
        if let error {
          WKInterfaceDevice.current().play(.failure)
          WatchInstrument.action("replayFailed", detail: error)
        }
        // Success haptic is played by coordinator after playback actually starts
      }
    }
  }

  private func replayItem(_ item: RecentlyPlayedManager.RecentItem) {
    WatchInstrument.action("replayItem", detail: "\(item.type.rawValue) '\(item.title)'")
    withLoading(id: item.id) {
      await MusicPlaybackCoordinator.shared.playRecent(item, connectivity: connectivity)
    }
  }

  private func replayRadio(_ item: RecentlyPlayedManager.RecentItem) {
    guard let musicItem = item.asMusicItem ?? item.asAlbumItem ?? item.asTrackItem else {
      replayItem(item)
      return
    }
    withLoading(id: item.id) {
      await MusicPlaybackCoordinator.shared.play(item: musicItem, style: .radio, connectivity: connectivity)
    }
  }

  private func replayPlayAll(_ item: RecentlyPlayedManager.RecentItem, shuffle: Bool) {
    guard let musicItem = item.asMusicItem ?? item.asAlbumItem ?? item.asTrackItem else {
      replayItem(item)
      return
    }
    withLoading(id: item.id) {
      await MusicPlaybackCoordinator.shared.play(
        item: musicItem,
        style: .playAll(shuffle: shuffle),
        connectivity: connectivity
      )
    }
  }

  private func replayArtistRadio(_ artist: RecentlyPlayedManager.RecentItem) {
    WatchInstrument.action("artistRadio", detail: artist.title)
    replayItem(artist)
  }

  private func replayArtistPlayAll(_ artist: RecentlyPlayedManager.RecentItem) {
    WatchInstrument.action("artistPlayAll", detail: artist.title)
    guard let musicItem = artist.asMusicItem else { return }
    withLoading(id: artist.id) {
      await MusicPlaybackCoordinator.shared.play(
        item: musicItem,
        style: .playAll(shuffle: false),
        connectivity: connectivity
      )
    }
  }
}

// MARK: - Recent item → MusicItem conversions

extension RecentlyPlayedManager.RecentItem {
  var asAlbumItem: MusicItem? {
    guard type == .album else { return nil }
    return MusicItem(ratingKey: ratingKey, title: title, type: "album", artist: subtitle, thumb: thumb)
  }

  var asTrackItem: MusicItem? {
    guard type == .track || type == .station else { return nil }
    return MusicItem(ratingKey: ratingKey, title: title, type: "track", artist: subtitle, thumb: thumb)
  }
}

/// Small cached thumbnail view used in browse lists and recently played
struct CachedThumbnailView: View {
  let urlString: String?
  let size: CGFloat
  @State private var image: UIImage?

  var body: some View {
    Group {
      if let image = image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
      } else {
        Rectangle()
          .fill(Color.gray.opacity(0.3))
          .overlay(
            Image(systemName: "music.note")
              .font(.system(size: size * 0.4))
              .foregroundStyle(.secondary)
          )
      }
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: size > 36 ? 6 : 4))
    .onAppear { loadImage() }
    .onChange(of: urlString) { _, _ in loadImage() }
  }

  private func loadImage() {
    guard let urlString = urlString else { return }
    let token = PlexWatchClient.shared.credentials?.token
    WatchImageCache.shared.loadImage(urlString: urlString, token: token) { loaded in
      self.image = loaded
    }
  }
}

#Preview {
  IdleView()
    .environmentObject(WatchConnectivityManager.shared)
}
