#if DEBUG
  import Foundation

  /// Automated drive-through for instrument testing.
  /// Launch with: SIMCTL_CHILD_PLEZY_INSTRUMENT_DRIVE=1 simctl launch …
  ///
  /// With no phone to sign in from, also set PLEZY_DRIVE_SERVER and
  /// PLEZY_DRIVE_TOKEN. PLEZY_DRIVE_ALBUM then plays that album through to its
  /// end and nothing else, shuffled if PLEZY_DRIVE_SHUFFLE=1.
  enum InstrumentDriver {
    private static let environment = ProcessInfo.processInfo.environment

    static var isEnabled: Bool {
      environment["PLEZY_INSTRUMENT_DRIVE"] == "1"
    }

    @MainActor
    static func run(connectivity: WatchConnectivityManager) {
      guard isEnabled else { return }
      Task { await drive(connectivity: connectivity) }
    }

    @MainActor
    private static func drive(connectivity: WatchConnectivityManager) async {
      WatchInstrument.log(.lifecycle, "InstrumentDriver START credentialed=\(PlexWatchClient.shared.hasCredentials)")

      if let server = environment["PLEZY_DRIVE_SERVER"], let token = environment["PLEZY_DRIVE_TOKEN"] {
        PlexWatchClient.shared.saveCredentials(serverUrl: server, token: token, isManual: true)
      }
      if let album = environment["PLEZY_DRIVE_ALBUM"] {
        let item = MusicItem(ratingKey: album, title: "Drive album", type: "album")
        let style = MusicPlaybackCoordinator.PlayStyle.playAll(shuffle: environment["PLEZY_DRIVE_SHUFFLE"] == "1")
        let error = await MusicPlaybackCoordinator.shared.play(item: item, style: style, connectivity: connectivity)
        WatchInstrument.log(.lifecycle, "InstrumentDriver album result: \(error ?? "OK")")
        return
      }

      // Wait for phone to push credentials (retry loop runs in parallel)
      if !PlexWatchClient.shared.hasCredentials {
        connectivity.startCredentialsRetryLoop()
        await waitForCredentials(timeoutMs: 20_000, connectivity: connectivity)
      }

      WatchInstrument.uiSnapshot(
        screen: "InstrumentDriver",
        fields: [
          "phase": "postCredentials",
          "credentialed": PlexWatchClient.shared.hasCredentials,
          "hint": connectivity.credentialsHint ?? "none",
        ])

      // Sync Plex history when credentialed; skip if we already have local data (faster playback tests).
      if PlexWatchClient.shared.hasCredentials,
        RecentlyPlayedManager.shared.recentArtists.isEmpty
      {
        await phasePlexSync()
        await pause(500, label: "after plex sync")
      } else {
        WatchInstrument.log(
          .lifecycle,
          "InstrumentDriver skipping plexSync — local artists=\(RecentlyPlayedManager.shared.recentArtists.count)")
      }

      // Only seed fake data on simulators without credentials
      if !PlexWatchClient.shared.hasCredentials {
        await phaseSeedRecent()
        await pause(500, label: "after seed")
      }

      await phasePlayback(connectivity: connectivity)
      await pause(800, label: "after playback")

      await phaseModeTransitions(connectivity: connectivity)

      if let artist = RecentlyPlayedManager.shared.recentArtists.first {
        await phaseReplayRecent(artist, connectivity: connectivity)
      }

      WatchInstrument.log(.lifecycle, "InstrumentDriver DONE")
    }

    // MARK: - Phases

    @MainActor
    private static func phaseSeedRecent() async {
      WatchInstrument.log(.lifecycle, "InstrumentDriver phase: seedRecent (no credentials)")
      let recent = RecentlyPlayedManager.shared

      recent.recordArtist(ratingKey: "drive-artist-1", title: "Radiohead", thumb: nil)
      recent.recordArtist(ratingKey: "drive-artist-2", title: "Björk", thumb: nil)
      recent.recordArtist(ratingKey: "drive-artist-3", title: "Aphex Twin", thumb: nil)

      recent.record(
        ratingKey: "drive-album-1", title: "OK Computer", type: .album,
        subtitle: "Radiohead", playStyle: .playAll(shuffle: false))
      recent.record(
        ratingKey: "drive-track-1", title: "Paranoid Android", type: .track,
        subtitle: "Radiohead", playStyle: .trackRadio)

      WatchInstrument.uiSnapshot(
        screen: "InstrumentDriver",
        fields: [
          "phase": "seedRecent",
          "artists": recent.recentArtists.count,
          "items": recent.items.count,
        ])
    }

    @MainActor
    private static func phasePlayback(connectivity: WatchConnectivityManager) async {
      WatchInstrument.log(
        .lifecycle, "InstrumentDriver phase: playback credentialed=\(PlexWatchClient.shared.hasCredentials)")

      guard PlexWatchClient.shared.hasCredentials else {
        WatchInstrument.log(.lifecycle, "InstrumentDriver playback skipped — no credentials")
        return
      }

      let recent = RecentlyPlayedManager.shared
      var error: String?

      if let track = recent.items.first(where: { $0.type == .track }),
        let item = track.asTrackItem
      {
        WatchInstrument.action("drive.playTrack", detail: track.title)
        error = await MusicPlaybackCoordinator.shared.play(
          item: item, style: .playAll(shuffle: false), connectivity: connectivity
        )
      } else if let album = recent.items.first(where: { $0.type == .album }),
        let item = album.asAlbumItem
      {
        WatchInstrument.action("drive.playAlbum", detail: album.title)
        error = await MusicPlaybackCoordinator.shared.play(
          item: item, style: .playAll(shuffle: false), connectivity: connectivity
        )
      } else if let artist = recent.recentArtists.first?.asMusicItem {
        WatchInstrument.action("drive.artistRadio", detail: "local \(artist.title)")
        error = await MusicPlaybackCoordinator.shared.play(
          item: artist, style: .radio, connectivity: connectivity
        )
        if error != nil {
          WatchInstrument.action("drive.artistPlayAll", detail: artist.title)
          error = await MusicPlaybackCoordinator.shared.play(
            item: artist, style: .playAll(shuffle: false), connectivity: connectivity
          )
        }
      } else {
        WatchInstrument.log(.lifecycle, "InstrumentDriver playback skipped — no recent items")
        return
      }

      WatchInstrument.log(.lifecycle, "InstrumentDriver playback result: \(error ?? "OK")")

      if error == nil {
        await waitForPlayback(timeoutMs: 20_000)
        WatchInstrument.uiSnapshot(
          screen: "InstrumentDriver",
          fields: [
            "phase": "afterPlay",
            "isPlaying": WatchAudioPlayer.shared.isPlaying,
            "hasQueue": WatchAudioPlayer.shared.hasQueue,
            "mode": connectivity.appMode,
          ])
        if WatchAudioPlayer.shared.isPlaying {
          WatchInstrument.playback("drive.pause")
          WatchAudioPlayer.shared.pause()
          await pause(500, label: "paused")
        }
      }

      let radioArtist = recent.recentArtists.first(where: { $0.type == .artist })

      if let radioArtist, let artistItem = radioArtist.asMusicItem {
        WatchInstrument.action("drive.artistRadio", detail: radioArtist.title)
        let radioError = await MusicPlaybackCoordinator.shared.play(
          item: artistItem, style: .radio, connectivity: connectivity
        )
        WatchInstrument.log(.lifecycle, "InstrumentDriver artist radio: \(radioError ?? "OK")")
        if radioError == nil {
          await waitForPlayback(timeoutMs: 20_000)
        }
      }
    }

    @MainActor
    private static func waitForCredentials(timeoutMs: UInt64, connectivity: WatchConnectivityManager) async {
      let deadline = Date().addingTimeInterval(Double(timeoutMs) / 1000)
      while Date() < deadline {
        if PlexWatchClient.shared.hasCredentials {
          connectivity.stopCredentialsRetryLoop()
          WatchInstrument.log(.connectivity, "InstrumentDriver credentials OK")
          return
        }
        await pause(1000, label: "awaiting credentials")
      }
      WatchInstrument.log(
        .connectivity, "InstrumentDriver credentials TIMEOUT hint=\(connectivity.credentialsHint ?? "?")")
    }

    @MainActor
    private static func waitForPlayback(timeoutMs: UInt64) async {
      let deadline = Date().addingTimeInterval(Double(timeoutMs) / 1000)
      while Date() < deadline {
        let player = WatchAudioPlayer.shared
        if player.isPlaying {
          WatchInstrument.playback(
            "InstrumentDriver playback confirmed isPlaying=true pos=\(Int(player.currentPosition))s")
          return
        }
        if let error = player.error, !error.isEmpty {
          WatchInstrument.playback("InstrumentDriver playback FAILED: \(error)")
          return
        }
        await pause(500, label: "awaiting playback")
      }
      WatchInstrument.playback("InstrumentDriver playback TIMEOUT isPlaying=\(WatchAudioPlayer.shared.isPlaying)")
    }

    @MainActor
    private static func phasePlexSync() async {
      WatchInstrument.log(.lifecycle, "InstrumentDriver phase: plexSync")
      await RecentlyPlayedManager.shared.syncFromPlex()
      let recent = RecentlyPlayedManager.shared
      WatchInstrument.uiSnapshot(
        screen: "InstrumentDriver",
        fields: [
          "phase": "plexSync",
          "artists": recent.recentArtists.count,
          "items": recent.items.count,
          "syncing": recent.isSyncingFromPlex,
        ])
    }

    @MainActor
    private static func phaseModeTransitions(connectivity: WatchConnectivityManager) async {
      WatchInstrument.log(.lifecycle, "InstrumentDriver phase: modeTransitions")

      if WatchAudioPlayer.shared.hasQueue {
        connectivity.returnToPlayer()
        await pause(500, label: "returnToPlayer")
        WatchInstrument.uiSnapshot(screen: "InstrumentDriver", fields: ["mode": connectivity.appMode])
        connectivity.dismissToBackground()
        await pause(500, label: "localBrowsing")
        WatchInstrument.uiSnapshot(screen: "InstrumentDriver", fields: ["mode": connectivity.appMode])
      }
    }

    @MainActor
    private static func phaseReplayRecent(
      _ artist: RecentlyPlayedManager.RecentItem,
      connectivity: WatchConnectivityManager
    ) async {
      WatchInstrument.log(.lifecycle, "InstrumentDriver phase: replayRecent '\(artist.title)'")
      let error = await MusicPlaybackCoordinator.shared.playRecent(artist, connectivity: connectivity)
      WatchInstrument.log(.lifecycle, "InstrumentDriver replay result: \(error ?? "OK")")
      await pause(500, label: "after replay")
    }

    private static func pause(_ ms: UInt64, label: String) async {
      WatchInstrument.log(.timing, "InstrumentDriver pause \(ms)ms (\(label))")
      try? await Task.sleep(nanoseconds: ms * 1_000_000)
    }
  }
#endif
