import SwiftUI

struct PlayerView: View {
    let ratingKey: String
    var resumeOffset: Int?

    @Environment(AppState.self) private var appState
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var viewModel = PlayerViewModel()
    @State private var currentRatingKey: String
    @State private var showControls = false
    @State private var controlsTask: Task<Void, Never>?
    @State private var transportFocus: TransportFocus = .none
    @State private var pickerState: PickerState = .closed
    @State private var skipSeconds: Int = 0
    @State private var skipForward: Bool = true
    @State private var skipVisible: Bool = false
    @State private var skipDismissTask: Task<Void, Never>?
    @State private var skipOverlayFocus: SkipOverlayFocus = .none
    @State private var prefetchTask: Task<PlexClient.VideoPlaybackData, Error>?
    @State private var useVLC = VideoPlayerType.current == .vlc
    @Namespace private var glassNamespace

    // MARK: - Scrub State (FF/RW)
    @State private var scrubSpeed: Int = 0  // -4..+4, 0 = normal
    @State private var scrubTimer: Timer?

    // MARK: - State Enums

    enum SkipOverlayFocus: Equatable {
        case none
        case playNext
        case skipMarker
    }

    enum TransportFocus: Equatable {
        case none
        case audioButton
        case subtitleButton
        case chaptersButton
        case qualityButton
    }

    enum PickerState: Equatable {
        case closed
        case audioPicker(highlightedIndex: Int)
        case subtitlePicker(highlightedIndex: Int)
        case chapterPicker(highlightedIndex: Int)
        case qualityPicker(highlightedIndex: Int)
    }

    init(ratingKey: String, resumeOffset: Int? = nil) {
        self.ratingKey = ratingKey
        self.resumeOffset = resumeOffset
        self._currentRatingKey = State(initialValue: ratingKey)
    }

    // MARK: - Derived State

    private var isScrubbing: Bool { scrubSpeed != 0 }

    private var isPickerOpen: Bool {
        if case .closed = pickerState { return false }
        return true
    }

    private var isAudioPickerOpen: Bool {
        if case .audioPicker = pickerState { return true }
        return false
    }

    private var isSubtitlePickerOpen: Bool {
        if case .subtitlePicker = pickerState { return true }
        return false
    }

    private var isChapterPickerOpen: Bool {
        if case .chapterPicker = pickerState { return true }
        return false
    }

    private var isQualityPickerOpen: Bool {
        if case .qualityPicker = pickerState { return true }
        return false
    }

    private var pickerHighlightedIndex: Int {
        switch pickerState {
        case .audioPicker(let idx), .subtitlePicker(let idx),
             .chapterPicker(let idx), .qualityPicker(let idx):
            return idx
        case .closed:
            return 0
        }
    }

    private var availableButtons: [TransportFocus] {
        var buttons: [TransportFocus] = []
        if hasAudioStreams { buttons.append(.audioButton) }
        if hasSubtitleStreams { buttons.append(.subtitleButton) }
        if !chapters.isEmpty { buttons.append(.chaptersButton) }
        buttons.append(.qualityButton)
        return buttons
    }

    private var hasPlayNextButton: Bool {
        viewModel.currentCreditsMarker != nil && viewModel.nextEpisodeRatingKey != nil
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
        ZStack {
            if useVLC {
                VLCPlayerVideoView(
                    onCoreReady: { core in
                        viewModel.attachVLCPlayerCore(core)
                        setupAndPlay()
                    },
                    onPlayPause: { handlePlayPause() },
                    onSkipBackward: { handleSkipBackwardTap() },
                    onSkipForward: { handleSkipForwardTap() },
                    onSkipBackwardHold: { startScrubbing(forward: false) },
                    onSkipForwardHold: { startScrubbing(forward: true) },
                    onSelect: { handleSelectInTransport() },
                    onUpArrow: { handleUpInTransport() },
                    onDownArrow: { handleDownInTransport() },
                    onLeftArrow: { handleLeftInTransport() },
                    onRightArrow: { handleRightInTransport() },
                    overlayActive: showControls,
                    transportButtonsFocused: transportFocus != .none || isPickerOpen
                )
                .ignoresSafeArea()
            } else {
                MpvVideoView(
                    onCoreReady: { core in
                        viewModel.attachCore(core)
                        setupAndPlay()
                    },
                    onPlayPause: { handlePlayPause() },
                    onSkipBackward: { handleSkipBackwardTap() },
                    onSkipForward: { handleSkipForwardTap() },
                    onSkipBackwardHold: { startScrubbing(forward: false) },
                    onSkipForwardHold: { startScrubbing(forward: true) },
                    onSelect: { handleSelectInTransport() },
                    onUpArrow: { handleUpInTransport() },
                    onDownArrow: { handleDownInTransport() },
                    onLeftArrow: { handleLeftInTransport() },
                    onRightArrow: { handleRightInTransport() },
                    overlayActive: showControls,
                    transportButtonsFocused: transportFocus != .none || isPickerOpen
                )
                .ignoresSafeArea()
            }

            // Buffering indicator
            if viewModel.isBuffering {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Buffering...")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(24)
                .glassMaterial(in: RoundedRectangle(cornerRadius: 16), effectID: "player-buffering", namespace: glassNamespace)
            }

            // Skip indicator
            if skipVisible {
                Image(systemName: skipForward ? "goforward.10" : "gobackward.10")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
                    .padding(28)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .transition(.opacity)
            }

            // Transport controls overlay
            if showControls {
                VStack {
                    Spacer()

                    // Inline picker (above transport bar)
                    // Use bool checks (not pattern-matched enums with associated values)
                    // so SwiftUI sees stable view identity when only the index changes.
                    if isAudioPickerOpen {
                        InlineTrackPicker(
                            title: "Audio",
                            tracks: audioTrackItems,
                            highlightedIndex: pickerHighlightedIndex
                        )
                        .padding(.bottom, 12)
                    }

                    if isSubtitlePickerOpen {
                        InlineTrackPicker(
                            title: "Subtitles",
                            tracks: subtitleTrackItems,
                            highlightedIndex: pickerHighlightedIndex
                        )
                        .padding(.bottom, 12)
                    }

                    if isChapterPickerOpen {
                        chapterPickerView(highlightedIndex: pickerHighlightedIndex)
                            .padding(.bottom, 12)
                    }

                    if isQualityPickerOpen {
                        InlineTrackPicker(
                            title: "Quality",
                            tracks: qualityTrackItems,
                            highlightedIndex: pickerHighlightedIndex
                        )
                        .padding(.bottom, 12)
                    }

                    transportBar
                }
                .transition(.opacity)
                .allowsHitTesting(false)
            }

            // Skip Intro overlay
            if viewModel.currentIntroMarker != nil && !showControls {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        overlayButton(label: "Skip Intro", focused: skipOverlayFocus == .skipMarker)
                    }
                    .padding(40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentIntroMarker != nil)
                .onAppear { withAnimation(.easeInOut(duration: 0.2)) { skipOverlayFocus = .skipMarker } }
            }

            // Skip Credits overlay (with optional Play Next Episode)
            if viewModel.currentCreditsMarker != nil && !showControls {
                VStack {
                    Spacer()
                    HStack(spacing: 20) {
                        Spacer()
                        if viewModel.nextEpisodeRatingKey != nil {
                            overlayButton(label: "Play Next Episode", focused: skipOverlayFocus == .playNext)
                        }
                        overlayButton(label: "Skip Credits", focused: skipOverlayFocus == .skipMarker)
                    }
                    .padding(40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentCreditsMarker != nil)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        skipOverlayFocus = hasPlayNextButton ? .playNext : .skipMarker
                    }
                }
            }

            // Error overlay
            if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .accessibilityHidden(true)
                    Text(error)
                        .font(.headline)
                    Button("Dismiss") {
                        coordinator.dismissPlayer()
                    }
                }
                .padding(40)
                .glassMaterial(in: RoundedRectangle(cornerRadius: 16), effectID: "player-error", namespace: glassNamespace)
            }
        }
        .onExitCommand {
            handleMenuInTransport()
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            // Start fetching playback data immediately, in parallel with mpv init
            if let client {
                prefetchTask = Task {
                    try await client.getVideoPlaybackData(ratingKey: currentRatingKey)
                }
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            controlsTask?.cancel()
            skipDismissTask?.cancel()
            prefetchTask?.cancel()
            scrubTimer?.invalidate()
            viewModel.stop()
        }
    }

    // MARK: - Helpers

    private var chapters: [PlexClient.PlexChapter] {
        viewModel.playbackData?.chapters ?? []
    }

    private var currentChapterIndex: Int? {
        guard !chapters.isEmpty else { return nil }
        let posMs = Int(viewModel.currentTime * 1000)
        return chapters.lastIndex(where: { posMs >= $0.startTimeOffset })
    }

    private var hasAudioStreams: Bool {
        guard let data = viewModel.playbackData else { return false }
        return !data.audioStreams.isEmpty
    }

    private var hasSubtitleStreams: Bool {
        guard let data = viewModel.playbackData else { return false }
        return !data.subtitleStreams.isEmpty
    }

    // MARK: - Track Items for Picker

    private var audioTrackItems: [InlineTrackPicker.TrackItem] {
        guard let streams = viewModel.playbackData?.audioStreams else { return [] }
        return streams.map { stream in
            InlineTrackPicker.TrackItem(
                id: stream.id,
                label: stream.displayTitle ?? "Track \(stream.id)",
                detail: stream.codec?.uppercased(),
                isActive: stream.id == viewModel.selectedAudioStream?.id,
                isForced: false
            )
        }
    }

    private var subtitleTrackItems: [InlineTrackPicker.TrackItem] {
        var items: [InlineTrackPicker.TrackItem] = [
            InlineTrackPicker.TrackItem(
                id: -1,
                label: "Off",
                detail: nil,
                isActive: viewModel.selectedSubtitleStream == nil,
                isForced: false
            )
        ]
        if let streams = viewModel.playbackData?.subtitleStreams {
            items += streams.map { stream in
                InlineTrackPicker.TrackItem(
                    id: stream.id,
                    label: stream.displayTitle ?? "Track \(stream.id)",
                    detail: stream.codec?.uppercased(),
                    isActive: stream.id == viewModel.selectedSubtitleStream?.id,
                    isForced: stream.isForced
                )
            }
        }
        return items
    }

    private var qualityTrackItems: [InlineTrackPicker.TrackItem] {
        PlexClient.VideoQuality.allCases.map { quality in
            InlineTrackPicker.TrackItem(
                id: PlexClient.VideoQuality.allCases.firstIndex(of: quality)!,
                label: quality.displayTitle,
                detail: quality.detail,
                isActive: quality == viewModel.selectedQuality,
                isForced: false
            )
        }
    }

    // MARK: - Transport Bar

    private var transportBar: some View {
        VStack(spacing: 16) {
            // Track buttons
            trackButtonRow

            // Progress bar and time
            HStack(spacing: 16) {
                if isScrubbing {
                    // Scrub indicator: icon + optional speed number
                    HStack(spacing: 4) {
                        if scrubSpeed < 0 {
                            Text(formatTime(viewModel.currentTime))
                                .font(.callout.monospacedDigit())
                            Image(systemName: "backward.fill")
                                .font(.callout)
                            if abs(scrubSpeed) > 1 {
                                Text("\(abs(scrubSpeed))")
                                    .font(.callout.weight(.bold).monospacedDigit())
                            }
                        } else {
                            Text(formatTime(viewModel.currentTime))
                                .font(.callout.monospacedDigit())
                            Image(systemName: "forward.fill")
                                .font(.callout)
                            if scrubSpeed > 1 {
                                Text("\(scrubSpeed)")
                                    .font(.callout.weight(.bold).monospacedDigit())
                            }
                        }
                    }
                } else {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.title2)

                    Text(formatTime(viewModel.currentTime))
                        .font(.callout.monospacedDigit())
                }

                ProgressView(value: viewModel.currentTime, total: max(1, viewModel.duration))
                    .tint(.white)

                Text(formatRemainingTime(viewModel.currentTime, duration: viewModel.duration))
                    .font(.callout.monospacedDigit())
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 80)
        .padding(.vertical, 24)
        .modifier(TransportBarBackgroundModifier())
    }

    private var trackButtonRow: some View {
        HStack(spacing: 20) {
            if hasAudioStreams {
                transportButton(
                    icon: "speaker.wave.2",
                    label: viewModel.selectedAudioStream?.displayTitle ?? "Audio",
                    isHighlighted: transportFocus == .audioButton
                )
            }
            if hasSubtitleStreams {
                transportButton(
                    icon: "captions.bubble",
                    label: viewModel.selectedSubtitleStream?.displayTitle ?? "Off",
                    isHighlighted: transportFocus == .subtitleButton
                )
            }
            if !chapters.isEmpty {
                transportButton(
                    icon: "list.bullet",
                    label: "Chapters",
                    isHighlighted: transportFocus == .chaptersButton
                )
            }
            transportButton(
                icon: "slider.horizontal.3",
                label: "Video Quality",
                isHighlighted: transportFocus == .qualityButton
            )
        }
    }

    private func transportButton(icon: String, label: String, isHighlighted: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.callout)
            Text(label)
                .font(.callout)
                .lineLimit(1)
        }
        .foregroundStyle(isHighlighted ? .black : .white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isHighlighted ? .white : .white.opacity(0.25))
        )
        .scaleEffect(isHighlighted ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHighlighted)
    }

    private func chapterPickerView(highlightedIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Chapters")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                            chapterRow(chapter, index: index, isHighlighted: index == highlightedIndex)
                                .id(index)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    proxy.scrollTo(highlightedIndex, anchor: .center)
                }
                .onChange(of: highlightedIndex) { _, newIndex in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
        .padding(.bottom, 12)
        .frame(width: 420)
        .frame(maxHeight: 380)
        .glassMaterial(in: RoundedRectangle(cornerRadius: 16), effectID: "chapter-picker", namespace: glassNamespace)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func chapterRow(_ chapter: PlexClient.PlexChapter, index: Int, isHighlighted: Bool) -> some View {
        HStack(spacing: 12) {
            PlexImage(
                path: chapter.thumb,
                token: appState.serverToken,
                baseURL: appState.activeServer?.baseURL ?? "",
                width: 120,
                aspectRatio: 16.0 / 9.0
            )
            .frame(width: 120, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.title ?? "Chapter \(index + 1)")
                    .font(.body)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(formatTime(Double(chapter.startTimeOffset) / 1000.0))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            if let current = currentChapterIndex, current == index {
                Image(systemName: "play.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHighlighted ? .white.opacity(0.25) : .clear)
                .padding(.horizontal, 8)
        )
    }

    private func overlayButton(label: String, focused: Bool) -> some View {
        Text(label)
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(focused ? .white.opacity(0.35) : .white.opacity(0.15))
            )
            .scaleEffect(focused ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: focused)
    }

    // MARK: - Navigation Handlers

    private func handleUpInTransport() {
        if skipOverlayFocus != .none {
            withAnimation(.easeInOut(duration: 0.2)) {
                skipOverlayFocus = .none
            }
            return
        }
        if !showControls {
            showControlsBriefly()
            return
        }
        switch pickerState {
        case .closed:
            withAnimation(.easeInOut(duration: 0.2)) {
                if let first = availableButtons.first {
                    transportFocus = first
                    resumeAutoHideForButtons()
                }
            }
        case .audioPicker(let idx):
            if idx > 0 { pickerState = .audioPicker(highlightedIndex: idx - 1) }
        case .subtitlePicker(let idx):
            if idx > 0 { pickerState = .subtitlePicker(highlightedIndex: idx - 1) }
        case .chapterPicker(let idx):
            if idx > 0 { pickerState = .chapterPicker(highlightedIndex: idx - 1) }
        case .qualityPicker(let idx):
            if idx > 0 { pickerState = .qualityPicker(highlightedIndex: idx - 1) }
        }
    }

    private func handleDownInTransport() {
        if skipOverlayFocus == .none && !showControls &&
            (viewModel.currentIntroMarker != nil || viewModel.currentCreditsMarker != nil) {
            withAnimation(.easeInOut(duration: 0.2)) {
                if hasPlayNextButton {
                    skipOverlayFocus = .playNext
                } else {
                    skipOverlayFocus = .skipMarker
                }
            }
            return
        }
        if !showControls {
            showControlsBriefly()
            return
        }
        switch pickerState {
        case .closed:
            withAnimation(.easeInOut(duration: 0.2)) {
                if transportFocus != .none {
                    transportFocus = .none
                    resumeAutoHide()
                } else {
                    dismissOverlays()
                }
            }
        case .audioPicker(let idx):
            if idx < audioTrackItems.count - 1 {
                pickerState = .audioPicker(highlightedIndex: idx + 1)
            }
        case .subtitlePicker(let idx):
            if idx < subtitleTrackItems.count - 1 {
                pickerState = .subtitlePicker(highlightedIndex: idx + 1)
            }
        case .chapterPicker(let idx):
            if idx < chapters.count - 1 {
                pickerState = .chapterPicker(highlightedIndex: idx + 1)
            }
        case .qualityPicker(let idx):
            let qualityCount = PlexClient.VideoQuality.allCases.count
            if idx < qualityCount - 1 {
                pickerState = .qualityPicker(highlightedIndex: idx + 1)
            }
        }
    }

    private func handleLeftInTransport() {
        guard case .closed = pickerState else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            guard let currentIndex = availableButtons.firstIndex(of: transportFocus),
                  currentIndex > 0 else { return }
            transportFocus = availableButtons[currentIndex - 1]
        }
        resumeAutoHideForButtons()
    }

    private func handleRightInTransport() {
        guard case .closed = pickerState else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            guard let currentIndex = availableButtons.firstIndex(of: transportFocus),
                  currentIndex < availableButtons.count - 1 else { return }
            transportFocus = availableButtons[currentIndex + 1]
        }
        resumeAutoHideForButtons()
    }

    private func handleSelectInTransport() {
        if isScrubbing {
            cancelScrub()
            return
        }
        if skipOverlayFocus != .none {
            switch skipOverlayFocus {
            case .playNext:
                if let nextKey = viewModel.nextEpisodeRatingKey {
                    viewModel.onPlayNextEpisode?(nextKey)
                }
            case .skipMarker:
                if viewModel.currentIntroMarker != nil {
                    viewModel.skipIntro()
                } else if viewModel.currentCreditsMarker != nil {
                    viewModel.skipCredits()
                }
            case .none:
                break
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                skipOverlayFocus = .none
            }
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            switch pickerState {
            case .closed:
                switch transportFocus {
                case .none:
                    // Play/pause
                    if viewModel.isPlaying {
                        viewModel.pause()
                    } else {
                        viewModel.play()
                    }
                    showControlsBriefly()
                case .audioButton:
                    // Open audio picker, highlight current track
                    let currentIdx = audioTrackItems.firstIndex(where: { $0.isActive }) ?? 0
                    pickerState = .audioPicker(highlightedIndex: currentIdx)
                    suspendAutoHide()
                case .subtitleButton:
                    // Open subtitle picker, highlight current track
                    let currentIdx = subtitleTrackItems.firstIndex(where: { $0.isActive }) ?? 0
                    pickerState = .subtitlePicker(highlightedIndex: currentIdx)
                    suspendAutoHide()
                case .chaptersButton:
                    // Open chapter picker, highlight current chapter
                    let currentIdx = currentChapterIndex ?? 0
                    pickerState = .chapterPicker(highlightedIndex: currentIdx)
                    suspendAutoHide()
                case .qualityButton:
                    // Open quality picker, highlight current quality
                    let currentIdx = PlexClient.VideoQuality.allCases.firstIndex(of: viewModel.selectedQuality) ?? 0
                    pickerState = .qualityPicker(highlightedIndex: currentIdx)
                    suspendAutoHide()
                }

            case .audioPicker(let idx):
                // Confirm audio selection
                if let streams = viewModel.playbackData?.audioStreams, idx < streams.count {
                    viewModel.selectAudioTrack(streams[idx])
                }
                pickerState = .closed
                resumeAutoHideForButtons()

            case .subtitlePicker(let idx):
                // Confirm subtitle selection
                if idx == 0 {
                    // "Off" option
                    viewModel.selectSubtitleTrack(nil)
                } else if let streams = viewModel.playbackData?.subtitleStreams, idx - 1 < streams.count {
                    viewModel.selectSubtitleTrack(streams[idx - 1])
                }
                pickerState = .closed
                resumeAutoHideForButtons()

            case .chapterPicker(let idx):
                // Seek to selected chapter
                if idx < chapters.count {
                    viewModel.seek(to: Double(chapters[idx].startTimeOffset) / 1000.0)
                }
                pickerState = .closed
                resumeAutoHideForButtons()

            case .qualityPicker(let idx):
                // Confirm quality selection
                let qualities = PlexClient.VideoQuality.allCases
                if idx < qualities.count {
                    let selected = qualities[idx]
                    Task { await viewModel.changeQuality(selected) }
                }
                pickerState = .closed
                resumeAutoHideForButtons()
            }
        }
    }

    private func handleMenuInTransport() {
        if isScrubbing {
            cancelScrub()
            return
        }
        if skipOverlayFocus != .none {
            withAnimation(.easeInOut(duration: 0.2)) {
                skipOverlayFocus = .none
            }
            return
        }
        if isPickerOpen {
            withAnimation(.easeInOut(duration: 0.2)) {
                pickerState = .closed
            }
            resumeAutoHideForButtons()
        } else if transportFocus != .none {
            withAnimation(.easeInOut(duration: 0.2)) {
                transportFocus = .none
                resumeAutoHide()
            }
        } else if showControls {
            dismissOverlays()
        } else {
            exitPlayer()
        }
    }

    private func exitPlayer() {
        viewModel.pause()
        coordinator.dismissPlayer()
    }

    // MARK: - Play/Pause & Skip Handlers

    private func handlePlayPause() {
        if isScrubbing {
            cancelScrub()
            return
        }
        if viewModel.isPlaying {
            viewModel.pause()
        } else {
            viewModel.play()
        }
        showControlsBriefly()
    }

    private func handleSkipForwardTap() {
        if isScrubbing {
            // Increase speed toward FF
            let newSpeed = min(scrubSpeed + 1, 4)
            if newSpeed == 0 {
                cancelScrub()
            } else {
                scrubSpeed = newSpeed
                restartScrubTimer()
            }
            return
        }
        if skipOverlayFocus != .none && hasPlayNextButton {
            withAnimation(.easeInOut(duration: 0.2)) {
                skipOverlayFocus = .skipMarker
            }
        } else {
            viewModel.seek(to: min(viewModel.duration, viewModel.currentTime + 10))
            showControlsBriefly()
            showSkipIndicator(forward: true)
        }
    }

    private func handleSkipBackwardTap() {
        if isScrubbing {
            // Increase speed toward RW
            let newSpeed = max(scrubSpeed - 1, -4)
            if newSpeed == 0 {
                cancelScrub()
            } else {
                scrubSpeed = newSpeed
                restartScrubTimer()
            }
            return
        }
        if skipOverlayFocus != .none && hasPlayNextButton {
            withAnimation(.easeInOut(duration: 0.2)) {
                skipOverlayFocus = .playNext
            }
        } else {
            viewModel.seek(to: max(0, viewModel.currentTime - 10))
            showControlsBriefly()
            showSkipIndicator(forward: false)
        }
    }

    // MARK: - Scrub Engine

    private func seekAmountForSpeed(_ speed: Int) -> Double {
        switch abs(speed) {
        case 1: return 1.0
        case 2: return 5.0
        case 3: return 15.0
        case 4: return 30.0
        default: return 0
        }
    }

    private func startScrubbing(forward: Bool) {
        viewModel.pause()
        scrubSpeed = forward ? 1 : -1
        suspendAutoHide()
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls = true
            skipOverlayFocus = .none
            transportFocus = .none
            pickerState = .closed
        }
        restartScrubTimer()
    }

    private func restartScrubTimer() {
        scrubTimer?.invalidate()
        scrubTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            let amount = seekAmountForSpeed(scrubSpeed)
            let direction: Double = scrubSpeed > 0 ? 1 : -1
            let newTime = viewModel.currentTime + (amount * direction)
            let clamped = max(0, min(viewModel.duration, newTime))
            viewModel.seek(to: clamped)
            // Cancel if we hit the boundaries
            if clamped <= 0 || clamped >= viewModel.duration {
                cancelScrub()
            }
        }
    }

    private func cancelScrub() {
        scrubTimer?.invalidate()
        scrubTimer = nil
        scrubSpeed = 0
        viewModel.play()
        showControlsBriefly()
    }

    // MARK: - Control Helpers

    private func showSkipIndicator(forward: Bool) {
        skipDismissTask?.cancel()
        if skipVisible && skipForward == forward {
            skipSeconds += 10
        } else {
            skipSeconds = 10
            skipForward = forward
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            skipVisible = true
        }
        skipDismissTask = Task {
            try? await Task.sleep(for: .seconds(0.8))
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.2)) {
                    skipVisible = false
                }
            }
        }
    }

    private func dismissOverlays() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls = false
            transportFocus = .none
            pickerState = .closed
        }
        controlsTask?.cancel()
    }

    private func showControlsBriefly() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls = true
            skipOverlayFocus = .none
        }
        resumeAutoHide()
    }

    private func suspendAutoHide() {
        controlsTask?.cancel()
    }

    private func resumeAutoHide() {
        controlsTask?.cancel()
        controlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = false
                    transportFocus = .none
                    pickerState = .closed
                }
            }
        }
    }

    private func resumeAutoHideForButtons() {
        controlsTask?.cancel()
        controlsTask = Task {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = false
                    transportFocus = .none
                    pickerState = .closed
                }
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    private func formatRemainingTime(_ current: Double, duration: Double) -> String {
        let remaining = max(0, duration - current)
        return "-\(formatTime(remaining))"
    }

    private func setupAndPlay() {
        guard let client else { return }

        // Wire up auto-play next episode
        viewModel.onPlayNextEpisode = { nextKey in
            Task {
                currentRatingKey = nextKey
                await viewModel.loadAndPlay(
                    ratingKey: nextKey,
                    client: client,
                    baseURL: appState.activeServer?.baseURL ?? "",
                    token: appState.serverToken,
                    resumeOffset: nil
                )
                await fetchNextEpisode(for: nextKey, client: client)
            }
        }

        Task {
            await viewModel.loadAndPlay(
                ratingKey: currentRatingKey,
                client: client,
                baseURL: appState.activeServer?.baseURL ?? "",
                token: appState.serverToken,
                resumeOffset: resumeOffset,
                prefetchedData: prefetchTask
            )
            // Don't block playback for episode lookup
            Task { await fetchNextEpisode(for: currentRatingKey, client: client) }
        }
    }

    private func fetchNextEpisode(for episodeRatingKey: String, client: PlexClient) async {
        guard let metadata = (try? await client.getMetadata(ratingKey: episodeRatingKey)) ?? nil,
              let parentRatingKey = metadata.parentRatingKey else {
            viewModel.nextEpisodeRatingKey = nil
            return
        }

        let episodes = (try? await client.getChildren(ratingKey: parentRatingKey)) ?? []

        if let currentIndex = episodes.firstIndex(where: { $0.ratingKey == episodeRatingKey }),
           currentIndex + 1 < episodes.count {
            viewModel.nextEpisodeRatingKey = episodes[currentIndex + 1].ratingKey
        } else {
            viewModel.nextEpisodeRatingKey = nil
        }
    }
}

// MARK: - Transport Bar Background

private struct TransportBarBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.bottom, 40)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}
