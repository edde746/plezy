import Foundation
import Observation

@MainActor
@Observable
final class PlayerViewModel: MpvPlayerDelegate {
    private(set) var isPlaying = false
    private(set) var isBuffering = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private(set) var playbackData: PlexClient.VideoPlaybackData?
    private(set) var error: String?

    var selectedAudioStream: PlexClient.MediaStream?
    var selectedSubtitleStream: PlexClient.MediaStream?
    var selectedQuality: PlexClient.VideoQuality = .original

    private let tracker = PlaybackTracker()
    private var mpvCore: MpvPlayerCore?
    private var vlcPlayerCore: VLCPlayerCore?
    private var currentClient: PlexClient?
    private var currentRatingKey: String?
    private var currentBaseURL: String?
    private var currentToken: String?
    private var pendingSeekPosition: Double?
    private var externalSubsLoaded = false
    private var useSubtitleDownloadFallback = false
    var isTranscoding: Bool { selectedQuality != .original }

    // Auto-play (reads from UserDefaults, synced with Settings)
    var autoPlayNext: Bool { UserDefaults.standard.bool(forKey: "autoPlayNext") }
    var nextEpisodeRatingKey: String?
    var onPlayNextEpisode: ((String) -> Void)?

    // Watch Together
    var syncManager: SyncManager?

    func attachCore(_ core: MpvPlayerCore) {
        mpvCore = core
        core.delegate = self

        // Observe mpv properties
        core.observeProperty("time-pos", format: "double")
        core.observeProperty("duration", format: "double")
        core.observeProperty("pause", format: "flag")
        core.observeProperty("paused-for-cache", format: "flag")
        core.observeProperty("eof-reached", format: "flag")
    }

    func attachVLCPlayerCore(_ core: VLCPlayerCore) {
        vlcPlayerCore = core

        core.onTimeUpdate = { [weak self] time in
            self?.currentTime = time
            self?.tracker.currentPosition = Int(time * 1000)
            self?.syncManager?.currentPosition = Int(time * 1000)
        }
        core.onDurationUpdate = { [weak self] dur in
            self?.duration = dur
        }
        core.onPlaybackStateChange = { [weak self] playing in
            self?.isPlaying = playing
            self?.tracker.isPlaying = playing
            self?.syncManager?.isPlaying = playing
        }
        core.onBufferingChange = { [weak self] buffering in
            self?.isBuffering = buffering
        }
        core.onEndOfFile = { [weak self] in
            Task { @MainActor in
                await self?.tracker.sendProgress(state: "stopped")
                if self?.autoPlayNext == true, let nextKey = self?.nextEpisodeRatingKey {
                    self?.onPlayNextEpisode?(nextKey)
                }
            }
        }
        core.onError = { [weak self] message in
            self?.error = "\(message). Try switching to the MPV player in Settings."
        }
        core.onFileLoaded = { }
        core.onPlaybackRestart = { [weak self] in
            self?.isPlaying = true
            // Apply pending seek (from quality switch or resume)
            if let seekPos = self?.pendingSeekPosition {
                self?.pendingSeekPosition = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.vlcPlayerCore?.seek(to: seekPos)
                }
            }
        }
    }

    func loadAndPlay(ratingKey: String, client: PlexClient, baseURL: String, token: String, resumeOffset: Int? = nil, prefetchedData: Task<PlexClient.VideoPlaybackData, Error>? = nil) async {
        error = nil
        currentClient = client
        currentBaseURL = baseURL
        currentToken = token
        currentRatingKey = ratingKey
        externalSubsLoaded = false

        // Read default quality from Settings (user can still change per session)
        if let raw = UserDefaults.standard.string(forKey: "defaultVideoQuality"),
           let quality = PlexClient.VideoQuality(rawValue: raw) {
            selectedQuality = quality
        } else {
            selectedQuality = .original
        }

        do {
            // Use pre-fetched data if available (started in parallel with mpv init),
            // otherwise fetch now.
            let data: PlexClient.VideoPlaybackData
            if let prefetchedData {
                data = try await prefetchedData.value
            } else {
                data = try await client.getVideoPlaybackData(ratingKey: ratingKey)
            }
            playbackData = data

            applyDisplayCriteria()

            // VLC path
            if vlcPlayerCore != nil {
                // Extract initial audio/subtitle selection
                if let selectedAudio = data.audioStreams.first(where: { $0.selected }) {
                    selectedAudioStream = selectedAudio
                }
                if let selectedSub = data.subtitleStreams.first(where: { $0.selected }) {
                    selectedSubtitleStream = selectedSub
                }

                let playURL: URL
                if selectedQuality != .original {
                    // Transcode: set stream selection then get HLS URL
                    await client.setStreamSelection(
                        partId: data.partId,
                        audioStreamID: selectedAudioStream?.id,
                        subtitleStreamID: selectedSubtitleStream?.id
                    )
                    if let result = try? await client.transcodeVideoURL(
                        ratingKey: ratingKey,
                        quality: selectedQuality
                    ) {
                        playURL = result.url
                        tracker.sessionId = result.sessionId
                    } else {
                        playURL = data.videoURL
                        selectedQuality = .original
                    }
                } else {
                    playURL = data.videoURL
                }

                vlcPlayerCore?.loadFile(url: playURL)
                vlcPlayerCore?.play()

                if let offset = resumeOffset, offset > 0 {
                    pendingSeekPosition = Double(offset) / 1000.0
                }

                tracker.startTracking(client: client, ratingKey: ratingKey, duration: data.duration)
                isPlaying = true
                return
            }

            guard let core = mpvCore else {
                self.error = "Player not ready"
                return
            }

            // Set up resume position — seek will be applied on playback-restart
            if let offset = resumeOffset, offset > 0 {
                pendingSeekPosition = Double(offset) / 1000.0
            } else {
                pendingSeekPosition = nil
            }

            // Extract initial audio/subtitle selection from Plex metadata
            // (needed before building transcode URL so we can pass stream IDs)
            if let selectedAudio = data.audioStreams.first(where: { $0.selected }) {
                selectedAudioStream = selectedAudio
            }
            if let selectedSub = data.subtitleStreams.first(where: { $0.selected }) {
                selectedSubtitleStream = selectedSub
            }

            // Use transcoded URL if default quality is not original
            let playURL: URL
            if selectedQuality != .original {
                // Set stream selection on the server before starting transcode
                await client.setStreamSelection(
                    partId: data.partId,
                    audioStreamID: selectedAudioStream?.id,
                    subtitleStreamID: selectedSubtitleStream?.id
                )
                guard let result = try? await client.transcodeVideoURL(
                    ratingKey: ratingKey,
                    quality: selectedQuality
                ) else {
                    playURL = data.videoURL
                    selectedQuality = .original
                    core.command(["loadfile", data.videoURL.absoluteString])
                    tracker.startTracking(client: client, ratingKey: ratingKey, duration: data.duration)
                    isPlaying = true
                    return
                }
                playURL = result.url
                tracker.sessionId = result.sessionId
            } else {
                playURL = data.videoURL
                selectedQuality = .original
            }
            core.command(["loadfile", playURL.absoluteString])

            tracker.startTracking(client: client, ratingKey: ratingKey, duration: data.duration)
            isPlaying = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func play() {
        if let vlcCore = vlcPlayerCore {
            vlcCore.play()
        } else {
            mpvCore?.setProperty("pause", value: "no")
        }
        isPlaying = true
        tracker.isPlaying = true

        if let syncManager {
            Task { await syncManager.broadcastPlay(position: Int(currentTime * 1000)) }
        }
    }

    func pause() {
        if let vlcCore = vlcPlayerCore {
            vlcCore.pause()
        } else {
            mpvCore?.setProperty("pause", value: "yes")
        }
        isPlaying = false
        tracker.isPlaying = false

        if let syncManager {
            Task { await syncManager.broadcastPause() }
        }
    }

    func seek(to time: Double) {
        if let vlcCore = vlcPlayerCore {
            vlcCore.seek(to: time)
        } else {
            mpvCore?.command(["seek", String(time), "absolute"])
        }
        currentTime = time
        tracker.currentPosition = Int(time * 1000)

        if let syncManager {
            Task { await syncManager.broadcastSeek(position: Int(time * 1000)) }
        }
    }

    func selectAudioTrack(_ stream: PlexClient.MediaStream) {
        selectedAudioStream = stream
        if isTranscoding {
            Task { await restartTranscode() }
            return
        }
        if let vlcCore = vlcPlayerCore {
            if let streams = playbackData?.audioStreams,
               let position = streams.firstIndex(where: { $0.id == stream.id }) {
                vlcCore.selectAudioTrack(index: position)
            }
            return
        }
        // mpv numbers audio tracks 1-based within the audio type
        if let streams = playbackData?.audioStreams,
           let position = streams.firstIndex(where: { $0.id == stream.id }) {
            mpvCore?.setProperty("aid", value: "\(position + 1)")
        }
    }

    func selectSubtitleTrack(_ stream: PlexClient.MediaStream?) {
        selectedSubtitleStream = stream
        if isTranscoding {
            Task { await restartTranscode() }
            return
        }
        guard let stream else {
            if vlcPlayerCore != nil {
                vlcPlayerCore?.selectSubtitleTrack(index: nil)
            } else {
                mpvCore?.setProperty("sid", value: "no")
            }
            return
        }
        // VLC subtitle path
        if let vlcCore = vlcPlayerCore {
            if stream.isExternal,
               let baseURL = currentBaseURL,
               let token = currentToken,
               let url = stream.subtitleURL(baseURL: baseURL, token: token) {
                vlcCore.addExternalSubtitle(url: url, flag: "select")
            } else if let streams = playbackData?.subtitleStreams {
                let embeddedStreams = streams.filter { !$0.isExternal }
                if let position = embeddedStreams.firstIndex(where: { $0.id == stream.id }) {
                    vlcCore.selectSubtitleTrack(index: position)
                }
            }
            return
        }
        if stream.isExternal,
           let baseURL = currentBaseURL,
           let token = currentToken,
           let url = stream.subtitleURL(baseURL: baseURL, token: token) {

            // If URL loading previously failed for this session, go straight to download
            if useSubtitleDownloadFallback {
                Task {
                    await self.loadSubtitleViaDownload(url: url, codec: stream.codec ?? "srt", flag: "select")
                }
                return
            }

            mpvCore?.command(["sub-add", url, "select"])

            let currentSid = mpvCore?.getProperty("sid") ?? "no"

            // If sub-add from URL failed, switch to download fallback
            if currentSid == "no" {
                useSubtitleDownloadFallback = true
                Task {
                    await self.loadSubtitleViaDownload(url: url, codec: stream.codec ?? "srt", flag: "select")
                }
            }
        } else if let streams = playbackData?.subtitleStreams {
            // Embedded subtitle: use sid with 1-based index among embedded tracks only
            let embeddedStreams = streams.filter { !$0.isExternal }
            if let position = embeddedStreams.firstIndex(where: { $0.id == stream.id }) {
                mpvCore?.setProperty("sid", value: "\(position + 1)")
            }
        }
    }

    func skipIntro() {
        guard let markers = playbackData?.markers else { return }
        if let intro = markers.first(where: { $0.type == "intro" }) {
            seek(to: Double(intro.endTimeOffset) / 1000.0)
        }
    }

    func skipCredits() {
        guard let markers = playbackData?.markers else { return }
        if let credits = markers.first(where: { $0.type == "credits" }) {
            seek(to: Double(credits.endTimeOffset) / 1000.0)
        }
    }

    func changeQuality(_ quality: PlexClient.VideoQuality) async {
        guard quality != selectedQuality else { return }
        guard let data = playbackData, let client = currentClient else { return }


        let savedPosition = currentTime > 0 ? currentTime : (vlcPlayerCore?.currentTime ?? (mpvCore?.getProperty("time-pos").flatMap(Double.init) ?? 0))
        selectedQuality = quality

        let newURL: URL
        if quality == .original {
            newURL = data.directVideoURL
            tracker.sessionId = nil
        } else {
            await client.setStreamSelection(
                partId: data.partId,
                audioStreamID: selectedAudioStream?.id,
                subtitleStreamID: selectedSubtitleStream?.id
            )
            guard let result = try? await client.transcodeVideoURL(
                ratingKey: data.ratingKey,
                quality: quality
            ) else { return }
            newURL = result.url
            tracker.sessionId = result.sessionId
        }

        pendingSeekPosition = savedPosition
        externalSubsLoaded = false
        if let vlcCore = vlcPlayerCore {
            vlcCore.loadFile(url: newURL)
            vlcCore.play()
        } else {
            mpvCore?.command(["loadfile", newURL.absoluteString])
        }
    }

    /// Downloads a subtitle file and loads it into MPV from a local temp file.
    /// Fixes servers that return wrong content-type (e.g. text/html for .srt).
    private func loadSubtitleViaDownload(url: String, codec: String, flag: String) async {
        guard let remoteUrl = URL(string: url) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: remoteUrl)
            let ext = codec.lowercased() == "ass" ? "ass" : codec.lowercased() == "ssa" ? "ssa" : "srt"
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "sub_\(UUID().uuidString).\(ext)"
            let localPath = tempDir.appendingPathComponent(fileName)
            try data.write(to: localPath)
            await MainActor.run {
                mpvCore?.command(["sub-add", localPath.path, flag])
                let sid = mpvCore?.getProperty("sid") ?? "no"
            }
        } catch {
        }
    }

    /// Restart the transcode session with current audio/subtitle selections.
    /// Used when the user changes audio or subtitle track during transcoding.
    /// Sets the tvOS display criteria from Plex metadata.
    private func applyDisplayCriteria() {
        guard let core = mpvCore, let data = playbackData else { return }

        let fps = data.videoFrameRate > 0 ? data.videoFrameRate :
            (Float(core.getProperty("container-fps") ?? "0") ?? 0)

        guard fps > 0 else {
            print("[PlayerViewModel] No FPS detected, skipping display criteria")
            return
        }

        let range = data.isDolbyVision ? "DV" : data.isHDR10 ? "HDR10" : "SDR"
        print("[PlayerViewModel] Applying display criteria: \(fps)fps \(range)")

        core.setDisplayCriteria(
            fps: fps,
            isDolbyVision: data.isDolbyVision,
            isHDR10: data.isHDR10
        )
    }

    private func restartTranscode() async {
        guard let client = currentClient,
              let ratingKey = currentRatingKey,
              let data = playbackData else { return }

        let savedPosition = currentTime

        // Set stream selection on server, then restart transcode
        await client.setStreamSelection(
            partId: data.partId,
            audioStreamID: selectedAudioStream?.id,
            subtitleStreamID: selectedSubtitleStream?.id
        )
        guard let result = try? await client.transcodeVideoURL(
            ratingKey: ratingKey,
            quality: selectedQuality
        ) else { return }

        tracker.sessionId = result.sessionId
        pendingSeekPosition = savedPosition
        externalSubsLoaded = false
        if let vlcCore = vlcPlayerCore {
            vlcCore.loadFile(url: result.url)
            vlcCore.play()
        } else {
            mpvCore?.command(["loadfile", result.url.absoluteString])
        }
    }

    var currentIntroMarker: PlexClient.PlexMarker? {
        guard let markers = playbackData?.markers else { return nil }
        let posMs = Int(currentTime * 1000)
        return markers.first { $0.type == "intro" && posMs >= $0.startTimeOffset && posMs < $0.endTimeOffset }
    }

    var currentCreditsMarker: PlexClient.PlexMarker? {
        guard let markers = playbackData?.markers else { return nil }
        let posMs = Int(currentTime * 1000)
        return markers.first { $0.type == "credits" && posMs >= $0.startTimeOffset && posMs < $0.endTimeOffset }
    }

    /// Shuts down mpv rendering and detaches the Metal layer so the
    /// dismiss animation doesn't crash. Does NOT call dispose() —
    /// that's handled by MpvVideoView.dismantleUIView after the view
    /// is fully removed from the hierarchy.
    func stop() {
        if let vlcCore = vlcPlayerCore {
            vlcCore.stop()
            vlcPlayerCore = nil
        }
        mpvCore?.shutdown()
        mpvCore = nil
        tracker.dispose()
        isPlaying = false
        syncManager?.stopSyncBroadcast()
    }

    func setupWatchTogether(syncManager: SyncManager) {
        self.syncManager = syncManager
        syncManager.onPlay = { [weak self] in self?.play() }
        syncManager.onPause = { [weak self] in self?.pause() }
        syncManager.onSeek = { [weak self] pos in self?.seek(to: Double(pos) / 1000.0) }
        syncManager.startSyncBroadcast()
    }

    // MARK: - MpvPlayerDelegate

    nonisolated func onPropertyChange(name: String, value: Any?) {
        Task { @MainActor in
            switch name {
            case "time-pos":
                if let pos = value as? Double {
                    self.currentTime = pos
                    self.tracker.currentPosition = Int(pos * 1000)
                    self.syncManager?.currentPosition = Int(pos * 1000)
                }

            case "duration":
                if let dur = value as? Double, dur.isFinite {
                    self.duration = dur
                }

            case "pause":
                if let paused = value as? Bool {
                    self.isPlaying = !paused
                    self.tracker.isPlaying = !paused
                    self.syncManager?.isPlaying = !paused
                }

            case "paused-for-cache":
                if let buffering = value as? Bool {
                    self.isBuffering = buffering
                }

            case "eof-reached":
                if let eof = value as? Bool, eof {
                    Task {
                        await self.tracker.sendProgress(state: "stopped")
                        if self.autoPlayNext, let nextKey = self.nextEpisodeRatingKey {
                            self.onPlayNextEpisode?(nextKey)
                        }
                    }
                }

            default:
                break
            }
        }
    }

    nonisolated func onEvent(name: String, data: [String: Any]?) {
        Task { @MainActor in
            switch name {
            case "file-loaded":
                print("[PlayerViewModel] File loaded")

            case "end-file":
                // mpv reason 4 = MPV_END_FILE_REASON_ERROR
                if let reason = data?["reason"] as? Int, reason == 4 {
                    let mpvError = data?["error"] as? Int ?? 0
                    self.error = "Playback failed (error \(mpvError)). The file may be unavailable or in an unsupported format."
                    self.isPlaying = false
                }
                self.mpvCore?.resetDisplayCriteria()
                print("[PlayerViewModel] End of file")

            case "playback-restart":
                print("[PlayerViewModel] Playback restart")
                // Apply pending resume seek once playback is ready
                if let seekPos = self.pendingSeekPosition {
                    self.pendingSeekPosition = nil
                    self.seek(to: seekPos)
                }
                if self.isTranscoding {
                    // When transcoding with subtitles=burn, the server renders
                    // the subtitle into the video — no mpv track selection needed.
                } else {
                    // Pre-load all external subtitles so switching is instant
                    if !self.externalSubsLoaded,
                       let baseURL = self.currentBaseURL,
                       let token = self.currentToken {
                        self.externalSubsLoaded = true
                        let extSubs = self.playbackData?.subtitleStreams.filter { $0.isExternal } ?? []
                        let tracksBefore = Int(self.mpvCore?.getProperty("track-list/count") ?? "0") ?? 0
                        for stream in extSubs {
                            if let url = stream.subtitleURL(baseURL: baseURL, token: token) {
                                self.mpvCore?.command(["sub-add", url, "auto"])
                            }
                        }
                        // If no tracks were added, download and load from temp files
                        let tracksAfter = Int(self.mpvCore?.getProperty("track-list/count") ?? "0") ?? 0
                        if tracksAfter == tracksBefore {
                            self.useSubtitleDownloadFallback = true
                            for stream in extSubs {
                                if let url = stream.subtitleURL(baseURL: baseURL, token: token) {
                                    await self.loadSubtitleViaDownload(url: url, codec: stream.codec ?? "srt", flag: "auto")
                                }
                            }
                        }
                    }
                    // Apply initial track selections from Plex metadata
                    if let audio = self.selectedAudioStream {
                        self.selectAudioTrack(audio)
                    }
                    self.selectSubtitleTrack(self.selectedSubtitleStream)
                }

            default:
                break
            }
        }
    }
}
