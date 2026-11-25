package com.edde746.plezy.presentation.player

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.KeyModifiers
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.playback.AmbientLightingController
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.CustomShader
import com.edde746.plezy.playback.Downmix
import com.edde746.plezy.playback.EngineFeatures
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.PlayerEngineListener
import com.edde746.plezy.playback.ShaderFile
import com.edde746.plezy.playback.ShaderFiles
import com.edde746.plezy.playback.ShaderPreset
import com.edde746.plezy.playback.ShaderRenderer
import com.edde746.plezy.playback.SubtitleStyle
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.playback.VideoLayout
import com.edde746.plezy.playback.session.PlayerSession
import com.edde746.plezy.playback.session.SessionInfo
import com.edde746.plezy.playback.session.SubtitleDownloadOutcome
import com.edde746.plezy.playback.session.SubtitleSearchHit
import com.edde746.plezy.presentation.watch.PlayerWatchUi
import com.edde746.plezy.presentation.watch.WatchRoomText
import com.edde746.plezy.watch.WatchSnapshot
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.coroutines.resume
import kotlin.math.floor
import kotlin.time.Duration
import kotlin.time.Clock
import kotlin.time.Instant
import kotlin.time.TimeSource

/**
 * An engine that records the store's commands. With [echo] it applies them to the session's engine state the way
 * mpv reports property changes back; without, reports lag behind until the test sends them. With [keyframeSeconds] a
 * seek that isn't exact lands, as mpv's keyframe seeks do, on the keyframe at or before its target (keyframes that far
 * apart from the file's start).
 */
class FakeEngine(private val state: MutableStateFlow<EngineState>) : PlayerEngine {
    var echo = true
    var keyframeSeconds: Double? = null
    val paused = mutableListOf<Boolean>()
    val seeks = mutableListOf<Pair<Double, Boolean>>()
    val volumes = mutableListOf<Double>()
    val mutes = mutableListOf<Boolean>()
    val speeds = mutableListOf<Double>()
    val subtitleDelays = mutableListOf<Double>()
    val audioDelays = mutableListOf<Double>()
    val selections = mutableListOf<Pair<TrackKind, Long?>>()
    val secondSelections = mutableListOf<Long?>()
    val subtitleLifts = mutableListOf<Double>()
    val layouts = mutableListOf<VideoLayout>()
    val normalizations = mutableListOf<Boolean>()
    val channels = mutableListOf<AudioChannels>()
    val audioDevices = mutableListOf<String>()
    val statsWanted = mutableListOf<Boolean>()
    val shaders = mutableListOf<List<String>>()
    val ambientLighting = mutableListOf<String?>()

    override fun setPaused(paused: Boolean) {
        this.paused += paused
        report { it.copy(paused = paused) }
    }

    override fun seek(seconds: Double, exact: Boolean) {
        seeks += seconds to exact
        val keyframes = keyframeSeconds
        val lands = if (exact || keyframes == null) seconds else floor(seconds / keyframes) * keyframes
        report { it.copy(positionSeconds = lands, eof = false) }
    }

    override fun setSpeed(speed: Double) {
        speeds += speed
        report { it.copy(speed = speed) }
    }

    override fun setSubtitleDelay(seconds: Double) {
        subtitleDelays += seconds
        report { it.copy(subtitleDelaySeconds = seconds) }
    }

    override fun setAudioDelay(seconds: Double) {
        audioDelays += seconds
        report { it.copy(audioDelaySeconds = seconds) }
    }

    override fun setSubtitleLift(fraction: Double) {
        subtitleLifts += fraction
    }

    override fun setSubtitleStyle(style: SubtitleStyle) = Unit

    override fun setVolume(volume: Double) {
        volumes += volume
        report { it.copy(volume = volume) }
    }

    override fun setMuted(muted: Boolean) {
        mutes += muted
        report { it.copy(muted = muted) }
    }

    override fun selectTrack(kind: TrackKind, id: Long?) {
        selections += kind to id
        // As mpv: the second subtitle's track can't be the first too.
        if (kind == TrackKind.SUBTITLE && state.value.tracks.any { it.kind == kind && it.id == id && it.secondary }) return
        report { s -> s.copy(tracks = s.tracks.map { if (it.kind == kind) it.copy(selected = it.id == id) else it }) }
    }

    /** What [screenshot] answers; the screenshots and subtitle seeks asked for. */
    var screenshotSaves = true
    val screenshots = mutableListOf<Unit>()
    val subtitleSeeks = mutableListOf<Boolean>()

    override fun screenshot(onResult: (saved: Boolean) -> Unit) {
        screenshots += Unit
        onResult(screenshotSaves)
    }

    override fun subtitleSeek(forward: Boolean) {
        subtitleSeeks += forward
    }

    override fun stop() = error("the session stops the engine, not the store")

    override fun selectSecondSubtitle(id: Long?) {
        secondSelections += id
        // As mpv: the first subtitle's track can't be the second too.
        if (state.value.tracks.any { it.kind == TrackKind.SUBTITLE && it.id == id && it.selected }) return
        report { s -> s.copy(tracks = s.tracks.map { if (it.kind == TrackKind.SUBTITLE) it.copy(secondary = it.id == id) else it }) }
    }

    override fun setVideoLayout(layout: VideoLayout) {
        layouts += layout
    }

    override fun setAudioNormalization(enabled: Boolean) {
        normalizations += enabled
    }

    override fun setAudioChannels(channels: AudioChannels, downmix: Downmix) {
        this.channels += channels
    }

    override fun setShaders(paths: List<String>) {
        shaders += paths
    }

    override fun setAmbientLighting(shaderPath: String?) {
        ambientLighting += shaderPath
    }

    override fun setAudioDevice(name: String) {
        audioDevices += name
        report { it.copy(audioDevice = name) }
    }

    override fun setStatsWanted(wanted: Boolean) {
        statsWanted += wanted
    }

    override var features = EngineFeatures()

    /** The player writes no HDR output or Dolby Vision conversion itself: the playback output's plan does ([PlayerHarness.hdrWrites], [PlayerHarness.dvConversionWrites]). */
    override fun setHdrOutput(enabled: Boolean, onResult: (applied: Boolean) -> Unit) = error("the player wrote HDR output itself")

    override fun setDolbyVisionConversion(mode: DolbyVisionConversion) = error("the player wrote the Dolby Vision conversion itself")

    override fun load(request: LoadRequest) = error("the session loads streams, not the store")

    override fun addSubtitle(url: String, title: String?, lang: String?) = error("the session adds subtitles, not the store")

    override fun setListener(listener: PlayerEngineListener?) = error("the session listens to the engine, not the store")

    override fun release() = error("the session releases the engine, not the store")

    private fun report(change: (EngineState) -> EngineState) {
        if (echo) state.update(change)
    }
}

class FakeSession(title: String = "Big Buck Bunny") : PlayerSession {
    override val engineState = MutableStateFlow(EngineState())
    override val info = MutableStateFlow(SessionInfo(title = title))
    var retries = 0
    var nextEpisodes = 0
    var previousEpisodes = 0
    val seeks = mutableListOf<Double>()
    val trackPicks = mutableListOf<Pair<TrackKind, Long?>>()
    val secondSubtitlePicks = mutableListOf<Long?>()
    val autoPlayNext = mutableListOf<Boolean>()
    val addedSubtitles = mutableListOf<String>()

    /** The live seeks asked for ([seekLive]): seconds behind the live edge. */
    val liveSeeks = mutableListOf<Double>()

    override fun retry() {
        retries++
    }

    override fun playNextEpisode() {
        nextEpisodes++
    }

    override fun playPreviousEpisode() {
        previousEpisodes++
    }

    override fun onSeek(seconds: Double) {
        seeks += seconds
    }

    override fun onTrackSelected(kind: TrackKind, id: Long?) {
        trackPicks += kind to id
    }

    override fun onSecondSubtitleSelected(id: Long?) {
        secondSubtitlePicks += id
    }

    override fun addSubtitle(url: String) {
        addedSubtitles += url
    }

    override fun setAutoPlayNext(enabled: Boolean) {
        autoPlayNext += enabled
        info.update { it.copy(nextEpisode = it.nextEpisode?.copy(autoplay = enabled)) }
    }

    override fun seekLive(behindSeconds: Double) {
        liveSeeks += behindSeconds
    }

    /** What the store asked of the session beyond the above, in order ("version 1", "quality ORIGINAL", …). */
    val actions = mutableListOf<String>()
    var searchHits: List<SubtitleSearchHit> = emptyList()
    var downloadOutcome: SubtitleDownloadOutcome = SubtitleDownloadOutcome.APPLIED
    var fileInfo: MediaFileInfo? = null

    override fun selectVersion(index: Int) {
        actions += "version $index"
    }

    override fun selectQuality(preset: TranscodeQualityPreset) {
        actions += "quality $preset"
    }

    override fun selectSourceTrack(kind: TrackKind, id: Int?) {
        actions += "source $kind $id"
    }

    override fun cycleSourceSubtitles() {
        actions += "cycle source subtitles"
    }

    override fun forceTranscode() {
        actions += "transcode"
    }

    override fun playQueueItem(key: String) {
        actions += "queue $key"
    }

    /** While on, each search and file info load waits in [heldSearches] or [heldFileInfo] for its answer. */
    var hold = false
    val heldSearches = mutableListOf<CompletableDeferred<List<SubtitleSearchHit>>>()
    val heldFileInfo = mutableListOf<CompletableDeferred<MediaFileInfo?>>()

    /** The results the last search to answer left to download, as the real session keeps them. */
    private var searchResults: Set<String>? = null

    override suspend fun searchSubtitles(language: String, title: String?): List<SubtitleSearchHit> {
        actions += "search $language $title"
        searchFailure?.let { throw it }
        val hits = if (hold) CompletableDeferred<List<SubtitleSearchHit>>().also { heldSearches += it }.await() else searchHits
        searchResults = hits.map { it.key }.toSet()
        return hits
    }

    /** Thrown by the next searches, or downloads, while set. */
    var searchFailure: Exception? = null
    var downloadFailure: Exception? = null

    override suspend fun downloadSubtitle(key: String): SubtitleDownloadOutcome {
        actions += "download $key"
        downloadFailure?.let { throw it }
        searchResults?.let { check(key in it) { "no search result $key" } }
        return downloadOutcome
    }

    var fileInfoFailure: Exception? = null

    override suspend fun loadFileInfo(): MediaFileInfo? {
        fileInfoFailure?.let { throw it }
        return if (hold) CompletableDeferred<MediaFileInfo?>().also { heldFileInfo += it }.await() else fileInfo
    }

    override fun onSyncOffsetChanged(audio: Boolean, seconds: Double) {
        actions += "${if (audio) "audio" else "subtitle"} offset $seconds"
    }

    override fun onSpeedChanged(speed: Double) {
        actions += "speed $speed"
    }

    override fun close() {
        actions += "close"
    }

    /** The answers to [SessionInfo.choice]; the question goes once answered. */
    val answers = mutableListOf<Int?>()

    override fun answerChoice(index: Int?) {
        answers += index
        info.update { it.copy(choice = null) }
    }

    /** The HTTP statuses simulated. */
    val simulatedStatuses = mutableListOf<Int>()

    override fun simulateHttpError(status: Int) {
        simulatedStatuses += status
    }

    /** What [suspendInBackground] answers (false: not yet, ask again later). */
    var suspends = true
    var suspendCalls = 0
    var restores = 0

    override fun suspendInBackground(): Boolean {
        suspendCalls++
        return suspends
    }

    override suspend fun restoreAfterBackground() {
        restores++
    }
}

/**
 * A room as the player sees it ([PlayerWatch]): what this device may do in it; [seeks] are the seeks the room heard,
 * [presses] the plays and pauses it was asked for while the player [routesControls], [here] the player's stops on this
 * device alone and their ends ("stop", "resume"), [ends] the times the viewer ended the room's media. A stop detaches the
 * player (it no longer routes its controls) and shows [PlayerWatchUi.pausedHere]; its end attaches it again, and
 * [onResume] is the room catching it up.
 */
class FakeWatch(canControl: Boolean, canChangeEpisode: Boolean) : PlayerWatch {
    val seeks = mutableListOf<Double>()
    val presses = mutableListOf<String>()
    val rates = mutableListOf<Double>()
    val here = mutableListOf<String>()
    var ends = 0
    var onResume: () -> Unit = {}
    override var routesControls = false
    override var roomRate: Double? = null
    override var stoppedHere = false
    override val state = MutableStateFlow<PlayerWatchUi?>(
        PlayerWatchUi(
            pill = WatchRoomText.pill(WatchSnapshot()),
            reconnecting = null,
            playBlocked = null,
            mismatch = null,
            room = WatchRoomText.room(WatchSnapshot()),
            canControl = canControl,
            canChangeEpisode = canChangeEpisode,
            controlsLocked = "Only the host controls playback",
            following = false,
            roomRate = null,
            pausedHere = false,
            atMediaEnd = false,
        ),
    )
    override val notices = MutableSharedFlow<String>()

    override fun stopHere() {
        here += "stop"
        stoppedHere = true
        routesControls = false
        state.update { it?.copy(pausedHere = true) }
    }

    override fun resumeHere() {
        here += "resume"
        stoppedHere = false
        routesControls = true
        state.update { it?.copy(pausedHere = false) }
        onResume()
    }

    override fun onLocalSeek(seconds: Double) {
        seeks += seconds
    }

    override fun onLocalRate(rate: Double) {
        rates += rate
    }

    override fun endMedia() {
        ends++
    }

    override fun play(): Boolean {
        presses += "play"
        return true
    }

    override fun pause() {
        presses += "pause"
    }

    override fun execute(command: WatchCommand) {}
}

/**
 * This device's stored player choices, in memory: [choices] emits what the store saves, as the settings would. The
 * picture options are kept per title, as the title scope keeps them: [pictures] by show or movie id (the episode's
 * show), null holding the global ones every other title falls back to.
 */
class FakePreferences(stored: PlayerChoices, picture: PictureChoices) : PlayerPreferences {
    override val choices = MutableStateFlow(stored)
    val pictures = MutableStateFlow(mapOf<String?, PictureChoices>(null to picture))

    /** The volumes the store kept ([setVolume]), in order. */
    val volumes = mutableListOf<Double>()

    override fun setVolume(percent: Double) {
        volumes += percent
    }

    /** What [item] (null: the global ones) has kept. */
    fun kept(item: MediaItem? = null): PictureChoices = pictures.value[titleOf(item)] ?: pictures.value.getValue(null)

    /** Keeps [change] of what [item] (null: the global ones) has kept. */
    fun keep(item: MediaItem?, change: (PictureChoices) -> PictureChoices) {
        pictures.update { it + (titleOf(item) to change(kept(item))) }
    }

    override suspend fun picture(item: MediaItem?) = kept(item)

    override fun setVideoFit(item: MediaItem?, fit: VideoFit) = keep(item) { it.copy(fit = fit) }

    override fun setVideoZoom(item: MediaItem?, zoom: Double) = keep(item) { it.copy(zoom = zoom) }

    override fun setShaderPreset(item: MediaItem?, id: String) = keep(item) { it.copy(shaderPreset = id) }

    private fun titleOf(item: MediaItem?): String? = item?.let { it.grandparentId ?: it.id }

    override fun setAudioNormalization(enabled: Boolean) {
        choices.update { it.copy(audioNormalization = enabled) }
    }

    override fun setAudioChannels(channels: AudioChannels) {
        choices.update { it.copy(audioChannels = channels) }
    }

    override fun setShowPlaybackInfo(enabled: Boolean) {
        choices.update { it.copy(showPlaybackInfo = enabled) }
    }

    override fun setAmbientLighting(enabled: Boolean) {
        choices.update { it.copy(ambientLighting = enabled) }
    }

    override fun setRememberedBrightness(level: Double) {
        choices.update { it.copy(rememberedBrightness = level) }
    }

    override fun addCustomShader(item: MediaItem?, shader: CustomShader) {
        choices.update { it.copy(customShaders = it.customShaders + shader) }
        setShaderPreset(item, shader.id)
    }

    override fun removeCustomShader(shader: CustomShader) {
        choices.update { it.copy(customShaders = it.customShaders - shader) }
        if (kept().shaderPreset == shader.id) keep(null) { it.copy(shaderPreset = ShaderPreset.Off.id) }
    }

    override fun setRotationLocked(locked: Boolean) {
        choices.update { it.copy(rotationLocked = locked) }
    }

    override fun setAlwaysOnTop(enabled: Boolean) {
        choices.update { it.copy(alwaysOnTop = enabled) }
    }

    override fun setSubtitleSearchLanguage(language: String) {
        choices.update { it.copy(subtitleSearchLanguage = language) }
    }

    override fun setHdr(enabled: Boolean) {
        choices.update { it.copy(hdr = enabled) }
    }

    override fun setAudioOutputDevice(name: String) {
        choices.update { it.copy(audioOutputDevice = name) }
    }
}

/**
 * The shaders' files of a device: the app's own under `/app/shaders/`, the imported ones under `/custom/`, numbered as
 * imported ([imported] holds their sources, [deleted] their deleted names), run by [renderer]. [missing] files have no
 * path: [paths] fails.
 */
class FakeShaderFiles(override val renderer: ShaderRenderer = ShaderRenderer.LIBPLACEBO) : ShaderFiles {
    val imported = mutableListOf<String>()
    val deleted = mutableListOf<String>()
    val missing = mutableSetOf<ShaderFile>()

    override suspend fun paths(files: List<ShaderFile>): List<String> = files.map { file ->
        require(file !in missing) { "No shader $file" }
        when (file) {
            is ShaderFile.Bundled -> "/app/shaders/${file.path}"
            is ShaderFile.Custom -> "/custom/${file.fileName}"
        }
    }

    override suspend fun import(source: String): String {
        imported += source
        return "shader-${imported.size}.glsl"
    }

    override suspend fun delete(fileName: String) {
        deleted += fileName
    }

    override suspend fun ambientLighting(): String = AMBIENT_SHADER

    companion object {
        const val AMBIENT_SHADER = "/cache/shaders/ambient_lighting.glsl"
    }
}

class FakeHost : PlayerHost {
    var closed = 0
    val fullscreenRequests = mutableListOf<Boolean>()
    override var levels: DeviceLevels? = null
    override var keepsOnTop = false
    val onTopRequests = mutableListOf<Boolean>()

    /** Video may play now: false while a car forbids it. */
    override var playbackAllowed = true

    override fun close() {
        closed++
    }

    override fun setFullscreen(fullscreen: Boolean) {
        fullscreenRequests += fullscreen
    }

    override fun setAlwaysOnTop(onTop: Boolean) {
        onTopRequests += onTop
    }
}

/** A wall clock that stands at [nowMillis] until a test moves it. */
class FakeClock(var nowMillis: Long) : Clock {
    override fun now(): Instant = Instant.fromEpochMilliseconds(nowMillis)
}

/**
 * A store on the test's virtual clock, with fakes around it; the device had [stored] as its player choices. The store
 * measures time with [timeSource], the virtual clock's unless the test gives its own. Every action runs what it
 * scheduled for "now".
 */
@OptIn(ExperimentalCoroutinesApi::class)
class PlayerHarness(
    private val scope: TestScope,
    config: PlayerConfig,
    stored: PlayerChoices = PlayerChoices(),
    val timeSource: TimeSource = scope.testScheduler.timeSource,
    /** The device's shaders' files; null where the player offers no shaders. */
    val shaderFiles: FakeShaderFiles? = null,
    importsShaders: Boolean = false,
    /** The player runs ambient lighting (with [shaderFiles]). */
    ambientLighting: Boolean = false,
    /** The device's brightness and volume, there from the player's start. */
    levels: DeviceLevels? = null,
    /** The global picture options kept ([FakePreferences.pictures]). */
    picture: PictureChoices = PictureChoices(),
    /** The window is fullscreen as the player opens (Start in fullscreen, F11 at a screen). */
    fullscreen: Boolean = false,
) {
    val session = FakeSession()
    val engine = FakeEngine(session.engineState)
    val host = FakeHost().also { it.levels = levels }
    val preferences = FakePreferences(stored, picture)
    /** The wall clock: 2026-01-01 20:00:00 UTC until a test moves it. */
    val clock = FakeClock(1_767_297_600_000L)
    val ambient = if (ambientLighting && shaderFiles != null) {
        AmbientLightingController(engine, shaderFiles, preferences::setAmbientLighting, scope.backgroundScope)
    } else {
        null
    }

    /** The HDR switch's flips the playback output took as its HDR input, each with the callback that answers it. */
    val hdrWrites = mutableListOf<Pair<Boolean, (Boolean) -> Unit>>()

    /** The Dolby Vision conversions the playback output took as its input. */
    val dvConversionWrites = mutableListOf<DolbyVisionConversion>()
    val store = PlayerStore(
        engine, session, host, preferences, config, scope.backgroundScope, timeSource, shaderFiles, importsShaders, clock, ambient, fullscreen,
    ).also { store ->
        store.followOutput(
            MutableStateFlow(false),
            setHdr = { enabled -> suspendCancellableCoroutine { done -> hdrWrites += enabled to { done.resume(it) } } },
            setDolbyVisionConversion = { dvConversionWrites += it },
        )
    }

    val state: PlayerUiState get() = store.state.value
    val timeline: TimelineState get() = store.timeline.value

    fun engineState(change: (EngineState) -> EngineState) {
        session.engineState.update(change)
        scope.runCurrent()
    }

    fun sessionInfo(change: (SessionInfo) -> SessionInfo) {
        session.info.update(change)
        scope.runCurrent()
    }

    /** The device's stored choices change (another screen, a development setting). */
    fun choices(change: (PlayerChoices) -> PlayerChoices) {
        preferences.choices.update(change)
        scope.runCurrent()
    }

    /** [item]'s kept picture options change (another screen, another player). */
    fun keepPicture(item: MediaItem?, change: (PictureChoices) -> PictureChoices) {
        preferences.keep(item, change)
        scope.runCurrent()
    }

    /** The file is open and playing at [position] of [duration]. */
    fun playing(position: Double = 100.0, duration: Double = 600.0) = engineState {
        it.copy(loaded = true, positionSeconds = position, durationSeconds = duration, paused = false, buffering = false, eof = false)
    }

    fun position(seconds: Double) = engineState { it.copy(positionSeconds = seconds) }

    fun dispatch(command: PlayerCommand) {
        store.dispatch(command)
        scope.runCurrent()
    }

    fun input(event: InputEvent): Boolean = store.onInput(event).also { scope.runCurrent() }

    fun press(key: InputKey, modifiers: KeyModifiers = KeyModifiers.NONE): Boolean {
        val handled = input(InputEvent.KeyDown(key, modifiers))
        input(InputEvent.KeyUp(key))
        return handled
    }

    fun advance(duration: Duration) {
        scope.advanceTimeBy(duration)
        scope.runCurrent()
    }

    /** Runs [block] in the background, the way the watch-together SDK calls the store's adapter, up to its first wait. */
    fun <T> start(block: suspend () -> T): Deferred<T> = scope.backgroundScope.async { block() }.also { scope.runCurrent() }
}

@OptIn(ExperimentalCoroutinesApi::class)
fun playerTest(
    profile: InputProfile = InputProfile.DESKTOP,
    config: PlayerConfig = PlayerConfig.defaults(profile, doubleClickIntervalMillis = 500),
    preferences: PlayerChoices = PlayerChoices(),
    timeSource: TimeSource? = null,
    shaderFiles: FakeShaderFiles? = null,
    importsShaders: Boolean = false,
    ambientLighting: Boolean = false,
    levels: DeviceLevels? = null,
    picture: PictureChoices = PictureChoices(),
    fullscreen: Boolean = false,
    body: PlayerHarness.() -> Unit,
) = runTest {
    val harness = PlayerHarness(
        this, config, preferences, timeSource ?: testScheduler.timeSource, shaderFiles, importsShaders, ambientLighting, levels, picture, fullscreen,
    )
    runCurrent()
    harness.body()
}
