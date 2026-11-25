package com.edde746.plezy.music

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.crash.Breadcrumb
import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.Lyrics
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.music.engine.AudioEvent
import com.edde746.plezy.music.engine.AudioMedia
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.playback.report.OfflineProgressQueue
import com.edde746.plezy.playback.report.PlaybackProgressTracker
import com.edde746.plezy.playback.report.PlaybackReportState
import com.edde746.plezy.playback.report.PlayerProgress
import com.edde746.plezy.playback.source.PlaybackReportingMode
import com.edde746.plezy.presentation.player.DiscordPosters
import com.edde746.plezy.presentation.player.DiscordPresence
import com.edde746.plezy.presentation.player.DiscordPresenceHost
import com.edde746.plezy.presentation.player.MediaCommand
import com.edde746.plezy.presentation.player.MediaCommandHandler
import com.edde746.plezy.presentation.player.MediaControlsHost
import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.NowPlayingKind
import com.edde746.plezy.presentation.player.NowPlayingStatus
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException
import kotlin.random.Random
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.DurationUnit
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * The music session ([MusicPlayback]): owns the audio player, the queue ([MusicQueueController]), gapless arming,
 * per-track progress reports, the OS media controls, Discord's presence, the car's driving rules and the persisted
 * last session.
 *
 * Advancing: after a track opens, the next entry is resolved and armed ([AudioPlayer.setNext]); the engine's
 * [AudioEvent.TrackTransition] is the authoritative advance (the finished track reports stopped at its duration, the
 * cursor moves to the armed entry, the next one is armed). A [AudioEvent.Completed] that stays uncontradicted for
 * [completedConfirmDelay] with nothing armed is the queue's end (the session parks paused on its last track) or a
 * failed arm (the next track opens explicitly). Next, previous, jumps and removing the current entry report the current
 * track stopped where it is and open the target.
 *
 * Errors: a failed resolve, open or engine error goes out on [errors] and skips to the next track; three failures in a
 * row without playback progress stop the session with [MusicPlaybackStatus.ERROR].
 *
 * Main thread. [scope] is the app's: the final reports, the session writes and the volume write outlive [close].
 *
 * @param appleAudioOutput the audio goes out through Apple's audio stack (iOS, iPadOS, macOS, tvOS): compressed audio
 *   may pass through to the receiver, and on a TV the music pauses in the background (tvOS has no background audio).
 * @param volumeWriter persists the music volume; the device setting by default.
 * @param notifier where a track's progress and watched mark show in the app.
 * @param offlineQueue where a downloaded track's progress waits when no server takes it; null keeps none.
 */
class MusicPlaybackService(
    private val scope: CoroutineScope,
    private val audioPlayerFactory: () -> AudioPlayer,
    private val resolver: MusicSourceResolver,
    private val clients: (ServerId) -> MediaBackend?,
    private val settings: DeviceSettingsRepository,
    private val coordinator: PlaybackCoordinator,
    private val foreground: StateFlow<Boolean>,
    private val formFactor: FormFactor,
    private val appleAudioOutput: Boolean,
    private val system: MusicSystem = object : MusicSystem {},
    private val controls: MediaControlsHost? = null,
    discord: DiscordPresenceHost? = null,
    /** Uploads Discord's posters ([DiscordPresence]); none without Discord. */
    private val discordPosters: DiscordPosters? = null,
    private var sessionStore: MusicSessionStore? = null,
    private val notifier: WatchStateNotifier = WatchStateNotifier(),
    private val offlineQueue: OfflineProgressQueue? = null,
    private val clock: Clock = Clock.System,
    private val timeSource: TimeSource = TimeSource.Monotonic,
    private val completedConfirmDelay: Duration = 400.milliseconds,
    private val positionPersistInterval: Duration = 5.seconds,
    private val volumeWriter: suspend (Double) -> Unit = { settings.set(AppSettings.musicVolume, it) },
    random: Random = Random.Default,
) : MusicPlayback {
    /** A gapless-armed next track: what [AudioPlayer.setNext] got, so a transition maps back to its entry and source. */
    private class ArmedTrack(val track: MediaItem, val source: MusicSource)

    /** A restored session's resume point: the first [play] opens the still-current track there. */
    private class PendingResume(val globalKey: String, var position: Duration)

    private val session = scope.childScope()
    private val queue = MusicQueueController(random)
    private val isAutomotive = system.car != null

    /** The vehicle's driving restrictions (one observer of the car service per app: the video player reads it too). */
    internal val car = CarUxRestrictions(system.car, session, timeSource)

    /**
     * The car forbids video now (Android Automotive's driving restrictions, observed here once for the app; never off a
     * car): a watch-together room stops waiting for a viewer who can't watch.
     */
    val vehicleRestricted: Flow<Boolean> = car.state.map { it == CarUxRestrictionState.RESTRICTED }.distinctUntilChanged()

    private val mutableState = MutableStateFlow(MusicState())
    override val state: StateFlow<MusicState> = mutableState.asStateFlow()
    private val mutablePosition = MutableStateFlow(Duration.ZERO)
    override val position: StateFlow<Duration> = mutablePosition.asStateFlow()
    private val jumps = MutableSharedFlow<Duration?>(extraBufferCapacity = 16)
    override val playheadJumps: Flow<Duration?> = jumps.asSharedFlow()
    private val mutableErrors = MutableSharedFlow<Throwable>(extraBufferCapacity = 16)
    override val errors: Flow<Throwable> = mutableErrors.asSharedFlow()
    private val mutableVolumePreview = MutableStateFlow(100.0)
    override val volumePreview: StateFlow<Double> = mutableVolumePreview.asStateFlow()

    private var status = MusicPlaybackStatus.IDLE
    private var currentTrack: MediaItem? = null
    private var currentSource: MusicSource? = null
    private var playContext: MusicPlayContext? = null

    /** The queue plays local copies only: set by the session's start, kept for every open and arm until the next. */
    private var queueOffline = false
    private var player: AudioPlayer? = null
    private var playerEvents: Job? = null
    private var tracker: PlaybackProgressTracker? = null
    private var armed: ArmedTrack? = null

    // The arm last cleared for a re-arm, in its generation: a queue edit can un-arm an entry the instant the engine
    // rolls into it, and that transition must stay adoptable.
    private var staleArm: ArmedTrack? = null
    private var staleArmGeneration = -1
    private var completedConfirm: Job? = null

    /** Bumped on every open, advance and stop: stale continuations drop out. */
    private var generation = 0
    private var playIntentGeneration = 0
    private var queueRevision = 0

    // Gapless arming runs in one latest-request slot: the generation stales continuations, the pending flag tells a
    // request from a cancellation.
    private var armRequestGeneration = 0
    private var armRequestPending = false
    private var armDraining = false

    /** The generation whose replacement open hasn't committed; arm requests wait while an open owns the playlist. */
    private var openingGeneration: Int? = null

    private var consecutiveFailures = 0
    private var pendingResume: PendingResume? = null
    private var lastPositionPersist: TimeMark? = null

    /** A system pause (focus loss, interruption) paused a playing session: the system's resume plays it again. */
    private var resumeAfterInterruption = false
    private var disposed = false

    // The car's claims: the restrictions paused this track (so parking resumes it), and a car pause or resume is in
    // flight (so a verdict landing meanwhile doesn't read the stale status).
    private var pausedByCarRestriction = false
    private var carPauseInFlight = false
    private var carResumeInFlight = false

    /** Whether the playback goes on in the background, as last published (on a car only with a vehicle verdict). */
    private var backgroundPlayback = !isAutomotive

    private var sleepTimer: Job? = null
    private var sleepTimerDuration: Duration? = null
    private var sleepTimerEndOfTrack = false

    // The persisted volume, applied to every new player; the preview moves with a drag.
    private var volume = 100.0
    private var volumeChanged = false
    private var volumeEdits = 0
    private var pendingVolumeWrite: Double? = null
    private var volumeDrain: CompletableDeferred<Unit>? = null

    // The OS media controls, up from the first open until the session ends.
    private var controlsActive = false
    private var shownNowPlaying: NowPlaying? = null
    private var shownAt: TimeMark? = null
    private var trailingControls: Job? = null
    private val nowPlaying = MutableStateFlow<NowPlaying?>(null)
    private var artwork: Pair<String, String?>? = null
    private var hardwareTransport: MusicHardwareTransport? = null
    private val discordPresence = discord?.let {
        DiscordPresence(nowPlaying, settings.observe(AppSettings.enableDiscordRpc), it, session, clock, timeSource) { item ->
            clientFor(item)?.let { backend -> discordPosters?.posterFor(item, backend) }
        }
    }

    private val stopForVideoClaim: suspend () -> Unit = { stopSession(MusicPlaybackStatus.IDLE) }

    private val commands = object : MediaCommandHandler {
        override fun perform(command: MediaCommand) = onMediaCommand(command)
    }

    private val volumeLoad: Job = session.launch(start = CoroutineStart.UNDISPATCHED) {
        val stored = settings.value(AppSettings.musicVolume)
        if (!volumeChanged) {
            volume = stored
            mutableVolumePreview.value = stored
            publish()
        }
    }

    /**
     * A change of the stored volume this service didn't make (a settings reset or import) reaches the volume and the
     * player. Skipped while a write of its own is in flight or the user changed the volume meanwhile: theirs wins.
     */
    private suspend fun followStoredVolume() {
        volumeLoad.join()
        settings.observe(AppSettings.musicVolume).collect {
            if (volumeDrain != null) return@collect
            val edits = volumeEdits
            val stored = settings.value(AppSettings.musicVolume)
            if (edits != volumeEdits || volumeDrain != null || stored == volume) return@collect
            volume = stored
            mutableVolumePreview.value = stored
            publish()
            player?.setVolume(stored)
        }
    }

    init {
        coordinator.registerMusicSession(stopForVideoClaim)
        if (isAutomotive) {
            car.ensureStarted()
            session.launch {
                combine(car.state, foreground) { _, _ -> }.collect {
                    reassertCarBackgroundPlayback()
                    applyCarPlaybackRestrictions()
                }
            }
        }
        session.launch {
            foreground.collect { inFront ->
                if (inFront || disposed) return@collect
                // The process may be about to die: the throttled tick could be a whole interval stale.
                persistSessionProgress()
                if (formFactor == FormFactor.TV && appleAudioOutput && isPlaying) {
                    Log.d(TAG) { "App backgrounded on Apple TV: pausing music" }
                    spawn { pause() }
                }
            }
        }
        sessionStore?.let { store -> session.launch(start = CoroutineStart.UNDISPATCHED) { restoreSession(store) } }
        session.launch { followStoredVolume() }
    }

    private val isPlaying: Boolean get() = status == MusicPlaybackStatus.PLAYING

    override fun beginPlayIntent(): Int = ++playIntentGeneration

    override fun isPlayIntentCurrent(intent: Int): Boolean = !disposed && intent == playIntentGeneration

    override val queueSessionRevision: Int get() = queueRevision

    // ---- Session start ------------------------------------------------------------------------------------------

    /**
     * Where a play the user starts goes instead of here: a cast target that takes [tracks] from [start] (true) plays
     * them, and this session doesn't change. Downloads played offline always play here.
     */
    var castsTo: ((tracks: List<MediaItem>, start: Int, context: MusicPlayContext, shuffle: Boolean) -> Boolean)? = null

    private fun castElsewhere(tracks: List<MediaItem>, startTrack: MediaItem?, context: MusicPlayContext, shuffle: Boolean): Boolean {
        if (tracks.isEmpty()) return false
        val start = startTrack?.let { start -> tracks.indexOfFirst { it.globalKey == start.globalKey } }?.takeIf { it >= 0 } ?: 0
        return castsTo?.invoke(tracks, start, context, shuffle) == true
    }

    override suspend fun playFromList(
        tracks: List<MediaItem>,
        startTrack: MediaItem?,
        playContext: MusicPlayContext,
        shuffle: Boolean,
        initialPosition: Duration?,
        offline: Boolean,
    ) {
        beginPlayIntent()
        if (!offline && castElsewhere(tracks, startTrack, playContext, shuffle)) return
        startQueue(tracks, startTrack, playContext, shuffle, autoplay = true, initialPosition, offline)
    }

    override suspend fun playInstantMix(seed: MediaItem): InstantMixOutcome {
        val intent = beginPlayIntent()
        val backend = clientFor(seed)
        if (backend == null) {
            if (!isPlayIntentCurrent(intent)) return InstantMixOutcome.SUPERSEDED
            throw PlaybackException(T.music.instantMixNoServer, PlaybackFailureReason.SERVER_UNAVAILABLE)
        }
        val tracks = try {
            backend.fetchInstantMix(seed.id)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (!isPlayIntentCurrent(intent)) return InstantMixOutcome.SUPERSEDED
            Log.w(TAG, e) { "Instant mix fetch failed for ${seed.id}" }
            throw e
        }
        if (!isPlayIntentCurrent(intent)) return InstantMixOutcome.SUPERSEDED
        if (tracks.isEmpty()) return InstantMixOutcome.EMPTY
        val context = MusicPlayContext(seed.displayTitle, MusicPlayContextKind.MIX)
        if (castElsewhere(tracks, null, context, shuffle = false)) return InstantMixOutcome.STARTED
        val started = startQueue(tracks, null, context, shuffle = false, autoplay = true)
        return if (started) InstantMixOutcome.STARTED else InstantMixOutcome.SUPERSEDED
    }

    private suspend fun startQueue(
        tracks: List<MediaItem>,
        startTrack: MediaItem?,
        context: MusicPlayContext,
        shuffle: Boolean,
        autoplay: Boolean,
        initialPosition: Duration? = null,
        offline: Boolean = false,
    ): Boolean {
        if (tracks.isEmpty() || disposed) return false
        val intent = beginPlayIntent()
        queueRevision++
        // A new queue is a new decision: the car's claim on what it stopped must not make parking start this one.
        pausedByCarRestriction = false
        val generation = ++generation
        invalidateArmRequests()
        finalizeCurrentTrack()
        // No start track means none has to play first, so a shuffle randomizes the head too.
        val startIndex = startTrack?.let { start -> tracks.indexOfFirst { it.globalKey == start.globalKey }.takeIf { it >= 0 } }
        queue.load(tracks, startIndex, shuffle)
        playContext = context
        queueOffline = offline
        consecutiveFailures = 0
        pendingResume = null
        persistSessionSnapshot(positionOverride = Duration.ZERO)
        openCurrent(generation, autoplay, initialPosition)
        return isPlayIntentCurrent(intent) && generation == this.generation
    }

    // ---- Opening and advancing ----------------------------------------------------------------------------------

    /** Resolves and opens the queue's current track; every failure goes to [handlePlaybackFailure]. */
    private suspend fun openCurrent(generation: Int, play: Boolean = true, initialPosition: Duration? = null) {
        val track = queue.current ?: return
        openingGeneration = generation
        fun current() = generation == this.generation
        var committed: AudioPlayer? = null
        try {
            currentTrack = track
            currentSource = null
            armed = null
            staleArm = null
            setStatus(MusicPlaybackStatus.LOADING)
            // Settle the vehicle's answer first: a cold start would otherwise set the session up as if the car were mute.
            if (isAutomotive) {
                car.ensureResolved()
                if (!current()) return
            }
            val player = ensurePlayer()
            if (!current() || this.player !== player) return
            ensureMediaControls()
            // Re-asserted per open. A car plays in the background only when the vehicle reports its restrictions:
            // they are what stop audio for driving then.
            backgroundPlayback = !isAutomotive || carBackgroundAudioAvailable
            // Drop an arm left from the previous item so a stray transition can't fire mid-switch.
            try {
                player.setNext(null)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "Clearing the arm before an open failed" }
            }

            val source = try {
                resolver.resolve(track, queueOffline)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Music source resolve failed for ${track.id}" }
                if (current()) handlePlaybackFailure(e)
                return
            }
            if (!current() || this.player !== player) return
            currentSource = source

            val shouldPlay = play && playbackAllowed()
            // A restored session's first open resumes at the persisted playhead; any other open discards it.
            val resumeAt = initialPosition ?: consumePendingResume(track)
            try {
                player.open(AudioMedia(source.url, source.headers, resumeAt), shouldPlay)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Music open failed for ${track.id}" }
                if (current()) handlePlaybackFailure(e)
                return
            }
            if (!current() || this.player !== player) return

            val started = shouldPlay && playbackAllowed()
            if (shouldPlay && !started) {
                player.pause()
                if (!current() || this.player !== player) return
            }
            committed = player
            setStatus(if (started) MusicPlaybackStatus.PLAYING else MusicPlaybackStatus.PAUSED)
            bindTrackServices(track, source)
        } finally {
            // A stale open never releases a newer one's ownership; only a committed current open arms its successor.
            if (openingGeneration == generation) {
                openingGeneration = null
                if (committed != null && !disposed && generation == this.generation && player === committed) {
                    requestArmNext()
                } else if (generation == this.generation) {
                    invalidateArmRequests()
                } else {
                    ensureArmDrain()
                }
            }
        }
    }

    /** A manual advance: reports the current track stopped where it is and opens the entry at [cursor]. */
    private suspend fun advanceTo(cursor: Int, play: Boolean = true) {
        val generation = ++generation
        invalidateArmRequests()
        finalizeCurrentTrack()
        pendingResume = null
        queue.jumpTo(cursor)
        persistSessionProgress(positionOverride = Duration.ZERO)
        openCurrent(generation, play)
    }

    /** Arms (or clears) what the engine advances into; nothing when it is armed already; repeat-one reuses the source. */
    private suspend fun applyArmNext(generation: Int, armRequest: Int) {
        val player = player ?: return
        if (!isCurrentArmRequest(player, generation, armRequest)) return
        val targetCursor = if (sleepTimerEndOfTrack) null else queue.nextIndex()
        val target = targetCursor?.let(queue::trackAt)

        if (target == null) {
            if (armed == null) return
            rememberStaleArm()
            trySetNext(player, null)
            return
        }
        if (armed?.track?.globalKey == target.globalKey) return

        rememberStaleArm()
        trySetNext(player, null)
        if (!isCurrentArmRequest(player, generation, armRequest)) return

        val current = currentSource
        val source = if (targetCursor == queue.cursor && current != null) {
            current
        } else {
            try {
                resolver.resolve(target, queueOffline)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Soft: with nothing armed, the confirmed completion opens the next track explicitly.
                Log.w(TAG, e) { "Gapless arm resolve failed for ${target.id}" }
                return
            }
        }
        if (!isCurrentArmRequest(player, generation, armRequest)) return
        val arm = ArmedTrack(target, source)
        armed = arm
        if (!trySetNext(player, AudioMedia(source.url, source.headers)) && armed === arm) {
            // Nothing armed natively: the confirmed completion must advance instead of waiting for a transition.
            armed = null
        }
    }

    private fun isCurrentArmRequest(player: AudioPlayer, generation: Int, armRequest: Int) =
        !disposed && openingGeneration == null && generation == this.generation && armRequest == armRequestGeneration && this.player === player

    private fun requestArmNext() {
        if (disposed || !playbackAllowed()) return
        armRequestGeneration++
        armRequestPending = true
        ensureArmDrain()
    }

    private fun invalidateArmRequests() {
        armRequestGeneration++
        armRequestPending = false
    }

    private fun ensureArmDrain() {
        if (disposed || !armRequestPending || openingGeneration != null || armDraining) return
        armDraining = true
        session.launch(start = CoroutineStart.UNDISPATCHED) {
            try {
                while (!disposed && armRequestPending && openingGeneration == null) {
                    val armRequest = armRequestGeneration
                    val generation = generation
                    armRequestPending = false
                    applyArmNext(generation, armRequest)
                }
            } finally {
                armDraining = false
            }
            if (!disposed && armRequestPending && openingGeneration == null) ensureArmDrain()
        }
    }

    /** Clears [armed] but remembers it, so a transition racing the clear is still adopted. */
    private fun rememberStaleArm() {
        armed?.let {
            staleArm = it
            staleArmGeneration = generation
        }
        armed = null
    }

    private suspend fun trySetNext(player: AudioPlayer, media: AudioMedia?): Boolean {
        if (media != null && !playbackAllowed()) return false
        return try {
            player.setNext(media)
            true
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Arming the next track failed" }
            false
        }
    }

    // ---- The player ---------------------------------------------------------------------------------------------

    private suspend fun ensurePlayer(): AudioPlayer {
        volumeLoad.join()
        val existing = player
        val isNew = existing == null || existing.disposed
        val player = if (isNew) audioPlayerFactory().also { this.player = it; wirePlayerEvents(it) } else existing!!
        player.setVerboseLogging(settings.value(AppSettings.enableDebugLogging))
        if (!isNew || this.player !== player || player.disposed) return player
        val volume = mutableVolumePreview.value
        if (volume != 100.0) spawn { player.setVolume(volume) }
        applyAudioPassthrough(player)
        // The video player's output pick, before the first open so the track starts there.
        player.setAudioDevice(settings.value(AppSettings.audioOutputDevice))
        return player
    }

    /**
     * Apple outputs hand AC3/EAC3 to the system's Dolby decoder (the only path that keeps Atmos in music) when the video
     * player's passthrough is on and loudness normalization off, before the first open. Elsewhere passthrough claims the
     * output device, which music doesn't.
     */
    private suspend fun applyAudioPassthrough(player: AudioPlayer) {
        if (!appleAudioOutput) return
        val device = settings.settings()
        if (!device.audioPassthroughOn(formFactor) || device.audioNormalization) return
        try {
            player.setAudioPassthrough(true)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Music audio passthrough not applied; decoding instead" }
        }
    }

    private fun wirePlayerEvents(player: AudioPlayer) {
        playerEvents?.cancel()
        playerEvents = session.launch(start = CoroutineStart.UNDISPATCHED) {
            player.events.collect { event ->
                if (this@MusicPlaybackService.player !== player) return@collect
                when (event) {
                    is AudioEvent.Position -> onPosition(event.position)
                    is AudioEvent.Playing -> onPlayingChanged(event.playing)
                    is AudioEvent.Buffering -> updateControls()
                    is AudioEvent.DurationChanged -> publish()
                    is AudioEvent.Completed -> onCompleted(event.completed)
                    is AudioEvent.TrackTransition -> onTrackTransition(event.uri)
                    is AudioEvent.PlayheadJump -> jumps.tryEmit(event.position)
                    is AudioEvent.Error -> onPlayerError(event.message)
                }
            }
        }
    }

    private fun onPosition(position: Duration) {
        mutablePosition.value = position
        // Real progress proves the pipeline recovered.
        if (consecutiveFailures != 0 && position > Duration.ZERO && isPlaying) consecutiveFailures = 0
        updateControls()
        if (isPlaying) maybePersistPositionTick(position)
    }

    private fun onPlayingChanged(playing: Boolean) {
        val allowed = playbackAllowed()
        val shouldPlay = playing && allowed
        if (playing && !allowed) {
            CrashCapture.breadcrumb(Breadcrumb("player.driver_distraction", "Blocked automotive restricted playback start"))
            spawn { player?.pause() }
        }
        // A car-owned resume reporting only now discharges the car's claim.
        if (shouldPlay && !carPauseInFlight) pausedByCarRestriction = false
        if (status == MusicPlaybackStatus.PLAYING || status == MusicPlaybackStatus.PAUSED) {
            setStatus(if (shouldPlay) MusicPlaybackStatus.PLAYING else MusicPlaybackStatus.PAUSED)
            tracker?.let { tracker -> scope.launch { tracker.sendProgress(if (shouldPlay) PlaybackReportState.PLAYING else PlaybackReportState.PAUSED) } }
        }
        updateControls(force = true)
    }

    /** The engine advanced into the armed entry: the authoritative track change. */
    private fun onTrackTransition(uri: String) {
        var arm = armed
        val stale = staleArm
        if ((arm == null || arm.source.url != uri) && stale != null && staleArmGeneration == generation && stale.source.url == uri) {
            // The engine rolled into the entry the instant a queue edit un-armed it: still what is audible.
            arm = stale
        }
        staleArm = null
        if (arm == null || arm.source.url != uri) {
            Log.w(TAG) { "Unexpected track transition (armed: ${arm != null})" }
            return
        }
        armed = null
        generation++
        invalidateArmRequests()

        // The finished track played out: stopped at its duration, else where the engine says the outgoing source got to.
        finalizeCurrentTrack(currentTrack?.durationMs?.milliseconds ?: player?.outgoingSourcePosition)

        val expected = queue.nextIndex()
        if (expected != null && queue.trackAt(expected)?.globalKey == arm.track.globalKey) {
            queue.jumpTo(expected)
        } else {
            val index = queue.queue.indexOfFirst { it.globalKey == arm.track.globalKey }
            if (index < 0) {
                // Removed at the boundary: play what the queue says comes next, or park.
                val next = queue.nextIndex()
                if (next != null) {
                    spawn { advanceTo(next) }
                } else {
                    spawn { player?.pause() }
                    parkAtEnd()
                }
                return
            }
            queue.jumpTo(index)
        }

        val track = queue.current ?: arm.track
        currentTrack = track
        currentSource = arm.source
        consecutiveFailures = 0
        persistSessionProgress(positionOverride = Duration.ZERO)
        if (playbackAllowed()) {
            setStatus(MusicPlaybackStatus.PLAYING)
        } else {
            spawn { player?.pause() }
            setStatus(MusicPlaybackStatus.PAUSED)
        }
        bindTrackServices(track, arm.source)
        requestArmNext()
    }

    /**
     * mpv pulses completed at every gapless boundary too, in no fixed order against the transition, so it is never
     * acted on raw: with something armed the transition handles it; otherwise it must stay true for
     * [completedConfirmDelay] (a boundary pulse is contradicted within milliseconds).
     */
    private fun onCompleted(done: Boolean) {
        if (!done || currentTrack == null || status == MusicPlaybackStatus.IDLE) return
        if (armed != null) return
        val generation = generation
        completedConfirm?.cancel()
        completedConfirm = session.launch {
            delay(completedConfirmDelay)
            completedConfirm = null
            if (disposed || generation != this@MusicPlaybackService.generation || armed != null) return@launch
            if (player?.state?.completed != true) return@launch
            handleQueueCompleted()
        }
    }

    private fun handleQueueCompleted() {
        if (sleepTimerEndOfTrack) {
            sleepTimerEndOfTrack = false
            parkAtEnd()
            return
        }
        val next = queue.nextIndex()
        if (next != null) spawn { advanceTo(next) } else parkAtEnd()
    }

    /**
     * The queue played out: the last track reports stopped at its duration and the session parks paused on it (the
     * mini-player stays); play restarts it from the top.
     */
    private fun parkAtEnd() {
        generation++
        invalidateArmRequests()
        finalizeCurrentTrack(currentTrack?.durationMs?.milliseconds)
        setStatus(MusicPlaybackStatus.PAUSED)
        // A played-out queue restores at the top of its last track; after the pause's own flush.
        persistSessionProgress(positionOverride = Duration.ZERO)
        updateControls(force = true)
    }

    private fun onPlayerError(message: String) {
        if (status == MusicPlaybackStatus.IDLE || status == MusicPlaybackStatus.ERROR) return
        Log.w(TAG) { "Music player error: $message" }
        handlePlaybackFailure(PlaybackException(T.messages.playbackFailed))
    }

    private fun handlePlaybackFailure(error: Throwable) {
        mutableErrors.tryEmit(error)
        consecutiveFailures++
        val next = queue.nextIndex(manual = true)
        if (consecutiveFailures >= MAX_CONSECUTIVE_FAILURES || next == null) {
            spawn { stopSession(MusicPlaybackStatus.ERROR) }
            return
        }
        spawn { advanceTo(next) }
    }

    // ---- Per-track services -------------------------------------------------------------------------------------

    /**
     * (Re)binds the track's progress reports and its OS controls; the previous track is already finalized. The first
     * report pins the track's own start and length: on a gapless advance the player still reads the finished track's.
     */
    private fun bindTrackServices(track: MediaItem, source: MusicSource) {
        tracker = null
        val player = player ?: return
        val offline = source.reporting == PlaybackReportingMode.OFFLINE_QUEUE || source.reportingBackend == null
        if (source.reporting != PlaybackReportingMode.DISABLED && (!offline || offlineQueue != null)) {
            tracker = PlaybackProgressTracker(
                backend = source.reportingBackend.takeUnless { offline },
                item = track,
                player = { PlayerProgress(player.state.position, player.state.duration, isActive = player.state.playing && !player.state.completed) },
                scope = scope,
                notifier = notifier,
                isOffline = offline,
                offlineQueue = offlineQueue,
                queueOnOnlineFailure = source.reporting == PlaybackReportingMode.ONLINE_WITH_OFFLINE_FALLBACK,
                playMethod = source.playMethod,
                playSessionId = source.playSessionId,
                mediaInfo = source.mediaInfo,
            ).also { it.startTracking(initialPosition = Duration.ZERO, initialDuration = track.durationMs?.milliseconds) }
        }
        publish()
        updateControls(force = true)
    }

    /** Stops the reports and sends the current track's final one, at [positionOverride] or where the player is. */
    private fun finalizeCurrentTrack(positionOverride: Duration? = null) {
        val tracker = tracker ?: return
        this.tracker = null
        tracker.stopTracking()
        scope.launch(start = CoroutineStart.UNDISPATCHED) { tracker.sendStoppedProgressOnce(positionOverride) }
    }

    private fun ensureMediaControls() {
        if (controlsActive) return
        controlsActive = true
        hardwareTransport = MusicHardwareTransport(system, { !disposed && currentTrack != null }, ::perform).also { it.register() }
    }

    private fun perform(transport: MusicTransport) {
        when (transport) {
            MusicTransport.PLAY -> spawn { play() }
            MusicTransport.PAUSE -> spawn { pause() }
            MusicTransport.TOGGLE -> spawn { togglePlayPause() }
            MusicTransport.NEXT -> spawn { next() }
            MusicTransport.PREVIOUS -> spawn { previous() }
            MusicTransport.STOP -> spawn { stop() }
            MusicTransport.SKIP_FORWARD -> spawn { seekRelative(SKIP_INTERVAL) }
            MusicTransport.SKIP_BACKWARD -> spawn { seekRelative(-SKIP_INTERVAL) }
        }
    }

    /**
     * The OS's commands, for a loaded session only. Next and previous wait for the car's allowance; pause and stop
     * never do (the OS must always be able to stop audio), and starting audio is gated inside [play].
     */
    private fun onMediaCommand(command: MediaCommand) {
        if (disposed || currentTrack == null) return
        when (command) {
            MediaCommand.Play -> spawn { play() }
            MediaCommand.Pause -> spawn { pause() }
            MediaCommand.TogglePause -> spawn { togglePlayPause() }
            is MediaCommand.SeekTo -> spawn { seek(command.seconds.seconds) }
            is MediaCommand.SeekBy -> spawn { seekRelative(command.seconds.seconds) }
            // Music plays at normal speed, and never offers the speed ([NowPlaying.canSetSpeed]).
            is MediaCommand.SetSpeed -> Unit
            MediaCommand.Next -> if (playbackAllowed()) spawn { next() }
            MediaCommand.Previous -> if (playbackAllowed()) spawn { previous() }
            MediaCommand.Stop -> spawn { stop() }
            MediaCommand.SystemPause -> {
                // Music resumes even in the background: background audio is the product.
                val wasPlaying = player?.state?.isActive ?: false
                spawn { pause(PauseOrigin.SYSTEM) }
                resumeAfterInterruption = wasPlaying
            }
            MediaCommand.SystemResume -> if (resumeAfterInterruption) {
                resumeAfterInterruption = false
                spawn { play() }
            }
        }
    }

    /** An in-track seek by [delta], clamped to the track. */
    private suspend fun seekRelative(delta: Duration) {
        val player = player ?: return
        var target = (player.state.position + delta).coerceAtLeast(Duration.ZERO)
        duration()?.let { if (target > it) target = it }
        player.seek(target)
    }

    // ---- Transport ----------------------------------------------------------------------------------------------

    override suspend fun play() {
        if (!playbackAllowed()) {
            Log.d(TAG) { "Music play denied while automotive playback is restricted" }
            return
        }
        if (currentTrack == null) return
        val player = player
        if (player == null) {
            // A parked restored session: the first play opens it at the persisted offset.
            val generation = ++generation
            invalidateArmRequests()
            openCurrent(generation, play = true)
            return
        }
        val generation = generation
        if (player.state.completed) {
            // Parked at the queue's end: the last track again from the top.
            player.seek(Duration.ZERO)
            if (!isCurrentTransport(player, generation)) return
            val track = currentTrack
            val source = currentSource
            if (track != null && source != null) bindTrackServices(track, source)
            requestArmNext()
        }
        if (!playbackAllowed()) return
        player.play()
        if (!isCurrentTransport(player, generation)) return
        if (!playbackAllowed()) {
            player.pause()
            if (isCurrentTransport(player, generation)) setStatus(MusicPlaybackStatus.PAUSED)
            return
        }
        setStatus(MusicPlaybackStatus.PLAYING)
        // The restrictions cleared the arm on the way in: gapless survives a park-and-resume.
        if (isAutomotive) requestArmNext()
    }

    override suspend fun pause() = pause(PauseOrigin.USER)

    private enum class PauseOrigin { USER, CAR, SYSTEM }

    /**
     * Only a [PauseOrigin.CAR] pause is resumed when the restrictions lift, only a [PauseOrigin.SYSTEM] one on the
     * system's resume: any other pause (the user, a command, the sleep timer) takes both claims away.
     */
    private suspend fun pause(origin: PauseOrigin) {
        if (origin != PauseOrigin.CAR) pausedByCarRestriction = false
        if (origin != PauseOrigin.SYSTEM) {
            resumeAfterInterruption = false
            if (controlsActive) controls?.userPaused()
        }
        val player = player ?: return
        if (currentTrack == null) return
        val generation = generation
        player.pause()
        if (!isCurrentTransport(player, generation)) return
        setStatus(MusicPlaybackStatus.PAUSED)
    }

    private fun isCurrentTransport(player: AudioPlayer, generation: Int) =
        !disposed && currentTrack != null && generation == this.generation && this.player === player

    override suspend fun togglePlayPause() {
        val player = player
        if (player == null) {
            if (currentTrack != null) play()
            return
        }
        if (player.state.isActive) pause() else play()
    }

    override suspend fun next() {
        val next = queue.nextIndex(manual = true) ?: return
        advanceTo(next)
    }

    override suspend fun previous() {
        val player = player
        if (player == null) {
            // A parked restored session restarts from the top (or steps back): the resume offset is play's alone.
            if (currentTrack == null) return
            advanceTo(queue.previousIndex() ?: queue.cursor)
            return
        }
        if (player.state.position > PREVIOUS_RESTART_THRESHOLD) {
            player.seek(Duration.ZERO)
            return
        }
        val previous = queue.previousIndex()
        if (previous == null) {
            player.seek(Duration.ZERO)
            return
        }
        advanceTo(previous)
    }

    override suspend fun seek(position: Duration) {
        val pending = pendingResume
        if (player == null && pending != null) {
            // A parked restored session: the resume point moves.
            var target = position.coerceAtLeast(Duration.ZERO)
            duration()?.let { if (target > it) target = it }
            pending.position = target
            mutablePosition.value = target
            persistSessionProgress()
            return
        }
        player?.seek(position)
    }

    override suspend fun setVolume(volume: Double, persist: Boolean) {
        val clamped = volume.coerceIn(0.0, 100.0)
        volumeChanged = true
        volumeEdits++
        var playerUpdate: Deferred<Unit>? = null
        if (clamped != mutableVolumePreview.value) {
            mutableVolumePreview.value = clamped
            playerUpdate = player?.let { player -> session.async(start = CoroutineStart.UNDISPATCHED) { player.setVolume(clamped) } }
        }
        var persistence: Deferred<Unit>? = null
        if (persist) {
            this.volume = clamped
            publish()
            persistence = persistVolume(clamped)
        }
        playerUpdate?.await()
        persistence?.await()
    }

    /** One write in flight; a burst coalesces to its latest value. Every caller of a batch sees its first error. */
    private fun persistVolume(volume: Double): Deferred<Unit> {
        pendingVolumeWrite = volume
        volumeDrain?.let { return it }
        val drain = CompletableDeferred<Unit>()
        volumeDrain = drain
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            var firstError: Throwable? = null
            while (true) {
                val next = pendingVolumeWrite ?: break
                pendingVolumeWrite = null
                try {
                    volumeWriter(next)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    if (firstError == null) firstError = e
                }
            }
            volumeDrain = null
            firstError?.let { drain.completeExceptionally(it) } ?: drain.complete(Unit)
        }
        return drain
    }

    override suspend fun jumpTo(index: Int) {
        if (index !in 0 until queue.length || index == queue.cursor) return
        advanceTo(index)
    }

    // ---- Queue and mode edits -----------------------------------------------------------------------------------

    override fun setRepeatMode(mode: MusicRepeatMode) {
        if (queue.repeatMode == mode) return
        queue.repeatMode = mode
        afterQueueEdit()
    }

    override fun toggleShuffle() {
        if (queue.isEmpty) return
        queue.toggleShuffle()
        afterQueueEdit()
    }

    override fun removeAt(index: Int) {
        if (index !in 0 until queue.length) return
        if (queue.removeAt(index)) {
            if (queue.isEmpty) {
                spawn { stop() }
                return
            }
            persistSessionSnapshot(positionOverride = Duration.ZERO)
            // The cursor is on what was next already.
            spawn { advanceTo(queue.cursor) }
            return
        }
        afterQueueEdit()
    }

    override fun reorder(from: Int, to: Int) {
        if (from == to) return
        queue.move(from, to)
        afterQueueEdit()
    }

    override fun addNext(tracks: List<MediaItem>) = enqueue(tracks, next = true)

    override fun addToEnd(tracks: List<MediaItem>) = enqueue(tracks, next = false)

    /** While idle, an enqueue starts a session parked paused on the first added track. */
    private fun enqueue(tracks: List<MediaItem>, next: Boolean) {
        if (tracks.isEmpty()) return
        if (queue.isEmpty || currentTrack == null) {
            val first = tracks.first()
            val context = MusicPlayContext(first.albumTitle ?: first.title ?: "", MusicPlayContextKind.TRACKS)
            spawn { startQueue(tracks, null, context, shuffle = false, autoplay = false) }
            return
        }
        if (next) queue.addNext(tracks) else queue.addToEnd(tracks)
        afterQueueEdit()
    }

    override fun clearUpcoming() {
        if (queue.isEmpty) return
        queue.clearUpcoming()
        afterQueueEdit()
    }

    /** Re-arms when the next track changed, rewrites the persisted queue and publishes (the OS's next button too). */
    private fun afterQueueEdit() {
        if (player != null && currentTrack != null) requestArmNext()
        persistSessionSnapshot()
        publish()
    }

    // ---- Sleep timer --------------------------------------------------------------------------------------------

    override fun setSleepTimer(duration: Duration?, endOfTrack: Boolean) {
        sleepTimer?.cancel()
        sleepTimer = null
        sleepTimerDuration = null
        val hadEndOfTrack = sleepTimerEndOfTrack
        sleepTimerEndOfTrack = endOfTrack
        if (!endOfTrack && duration != null) {
            sleepTimerDuration = duration
            sleepTimer = session.launch {
                delay(duration)
                sleepTimer = null
                sleepTimerDuration = null
                publish()
                pause()
            }
        }
        // End of track suppresses the arm so the track truly completes; leaving it arms again.
        if (hadEndOfTrack != sleepTimerEndOfTrack) requestArmNext()
        publish()
    }

    private fun cancelSleepTimer() {
        sleepTimer?.cancel()
        sleepTimer = null
        sleepTimerDuration = null
        sleepTimerEndOfTrack = false
    }

    // ---- Stop and teardown --------------------------------------------------------------------------------------

    override suspend fun stop() = stopSession(MusicPlaybackStatus.IDLE)

    /**
     * The active profile changed to the one of [store] (null: no profile): the session the previous profile left is
     * saved where it stands for its next start, and ended; [store]'s session comes back parked paused.
     */
    suspend fun switchProfile(store: MusicSessionStore?) {
        if (disposed || store === sessionStore) return
        persistSessionProgress()
        stopSession(MusicPlaybackStatus.IDLE, forgetSaved = false)
        sessionStore = store
        if (store != null) restoreSession(store)
    }

    /**
     * The full end, shared by a stop, an error stop, video's claim and a profile switch: the audio core is gone when
     * it returns. A session the user saw end comes back on no launch; a profile switch ([forgetSaved] false) keeps it.
     */
    private suspend fun stopSession(endStatus: MusicPlaybackStatus, forgetSaved: Boolean = true) {
        beginPlayIntent()
        queueRevision++
        generation++
        invalidateArmRequests()
        cancelTimersAndFinalizeTrack()
        queue.clear()
        currentTrack = null
        currentSource = null
        armed = null
        staleArm = null
        playContext = null
        queueOffline = false
        pendingResume = null
        if (forgetSaved) clearPersistedSession()
        resumeAfterInterruption = false
        // The car's claim dies with the session.
        pausedByCarRestriction = false
        setStatus(endStatus)
        val player = teardownPlayerAndControls()
        if (player != null && !player.disposed) {
            try {
                player.stop()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "Audio player stop failed during session teardown" }
            }
            try {
                player.dispose()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Audio player dispose failed during session teardown" }
                this.player = player
                throw e
            }
        }
    }

    private fun cancelTimersAndFinalizeTrack() {
        completedConfirm?.cancel()
        completedConfirm = null
        cancelSleepTimer()
        finalizeCurrentTrack()
    }

    /** Detaches the player, the key handler and the OS controls without suspending; returns the player to stop. */
    private fun teardownPlayerAndControls(): AudioPlayer? {
        hardwareTransport?.unregister()
        hardwareTransport = null
        playerEvents?.cancel()
        playerEvents = null
        nowPlaying.value = null
        val player = player
        this.player = null
        trailingControls?.cancel()
        trailingControls = null
        if (controlsActive) {
            controlsActive = false
            if (shownNowPlaying != null) controls?.hide()
            shownNowPlaying = null
        }
        return player
    }

    /** Ends the service with its profile session: a final playhead flush, then everything stops without waiting. */
    fun close() {
        if (disposed) return
        persistSessionProgress()
        playIntentGeneration++
        queueRevision++
        generation++
        invalidateArmRequests()
        disposed = true
        car.close()
        coordinator.unregisterMusicSession(stopForVideoClaim)
        cancelTimersAndFinalizeTrack()
        val player = teardownPlayerAndControls()
        discordPresence?.release()
        session.cancel()
        if (player != null && !player.disposed) {
            scope.launch {
                try {
                    player.dispose()
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "Audio player dispose failed on close" }
                }
            }
        }
    }

    override suspend fun fetchLyrics(track: MediaItem): Lyrics? = clientFor(track)?.fetchLyrics(track)

    private fun clientFor(item: MediaItem): MediaBackend? = ServerId.tryParse(item.serverId)?.let(clients)

    // ---- Car ----------------------------------------------------------------------------------------------------

    private val carBackgroundAudioAvailable: Boolean get() = car.state.value != CarUxRestrictionState.UNKNOWN

    private fun playbackAllowed(): Boolean = automotivePlaybackAllowed(isAutomotive, foreground.value, car.state.value)

    /** A late vehicle answer reconfigures a session opened while the vehicle was silent. */
    private fun reassertCarBackgroundPlayback() {
        if (disposed || !controlsActive) return
        val enabled = carBackgroundAudioAvailable
        if (enabled == backgroundPlayback) return
        backgroundPlayback = enabled
        updateControls(force = true)
    }

    /**
     * Stops audio while the vehicle requires distraction optimization and picks it up again once it doesn't. Resuming
     * is limited to vehicles that report their restrictions: under the foreground fallback, the app coming back only
     * means it regained focus, which isn't a request to play.
     */
    private fun applyCarPlaybackRestrictions() {
        if (disposed) return
        val vehicleReports = carBackgroundAudioAvailable
        if (!playbackAllowed()) {
            invalidateArmRequests()
            rememberStaleArm()
            val player = player
            if (player != null) spawn { trySetNext(player, null) }
            // The session reads loading while a replacement resolves, with the previous track still sounding: ask
            // the player too.
            val sounding = isPlaying || (player?.state?.playing ?: false)
            if (sounding && !carPauseInFlight) {
                Log.d(TAG) { "Vehicle restricted playback: pausing music" }
                pausedByCarRestriction = true
                spawn { pauseForRestriction() }
            }
            return
        }
        if (currentTrack != null) requestArmNext()
        if (!pausedByCarRestriction) return
        // A car pause still landing keeps the claim: the re-evaluation after it resumes.
        if (carPauseInFlight) return
        // Only a definitive verdict consumes the claim; the app regaining focus doesn't.
        if (!vehicleReports) return
        if (carResumeInFlight) return
        if (currentTrack != null && !isPlaying) {
            Log.d(TAG) { "Vehicle restrictions lifted: resuming music" }
            spawn { resumeAfterRestriction() }
            return
        }
        pausedByCarRestriction = false
    }

    /** Resumes what the vehicle stopped, keeping the claim until it actually plays. */
    private suspend fun resumeAfterRestriction() {
        carResumeInFlight = true
        var failed = false
        try {
            play()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            failed = true
            Log.w(TAG, e) { "Failed to resume after vehicle restrictions lifted" }
        } finally {
            carResumeInFlight = false
        }
        if (disposed) return
        if (isPlaying || failed) {
            // A refused play would spin straight back here: the track is left for the user.
            pausedByCarRestriction = false
            return
        }
        // Restricted again mid-resume: the current verdict decides.
        if (!playbackAllowed()) applyCarPlaybackRestrictions()
    }

    /** Pauses for the vehicle, then reads the verdict again: the car may have released playback meanwhile. */
    private suspend fun pauseForRestriction() {
        carPauseInFlight = true
        try {
            pause(PauseOrigin.CAR)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to pause for vehicle restrictions" }
            // Fail closed: nothing else is coming to stop audio in a moving car.
            val stillSounding = isPlaying || (player?.state?.playing ?: false)
            if (!disposed && !playbackAllowed() && stillSounding) {
                try {
                    stop()
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "Failed to stop restricted playback" }
                }
            }
        } finally {
            carPauseInFlight = false
        }
        if (disposed || !playbackAllowed()) return
        applyCarPlaybackRestrictions()
    }

    // ---- Session persistence and restore ------------------------------------------------------------------------

    /**
     * Brings the last session back parked paused: no player, no resolve, no OS controls; the first [play] opens it
     * (offline and while servers still connect too). A play or session that raced the read wins.
     */
    private suspend fun restoreSession(store: MusicSessionStore) {
        val intent = playIntentGeneration
        val revision = queueRevision
        if (!settings.value(AppSettings.resumeMusicOnLaunch)) return
        val snapshot = try {
            store.load()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Music session restore read failed" }
            return
        } ?: return
        if (disposed || intent != playIntentGeneration || revision != queueRevision) return
        if (status != MusicPlaybackStatus.IDLE || currentTrack != null) return
        if (!queue.restoreState(snapshot.queue)) {
            Log.w(TAG) { "Discarding a persisted music session with an invalid queue" }
            return
        }
        val track = queue.current ?: return queue.clear()
        val durationMs = track.durationMs
        val resumeAt = snapshot.position.takeUnless { it < Duration.ZERO || (durationMs != null && it.inWholeMilliseconds >= durationMs) }
            ?: Duration.ZERO
        queueRevision++
        playContext = snapshot.playContext
        currentTrack = track
        pendingResume = PendingResume(track.globalKey, resumeAt)
        Log.i(TAG) { "Restored a parked music session at ${resumeAt.inWholeSeconds}s" }
        mutablePosition.value = resumeAt
        setStatus(MusicPlaybackStatus.PAUSED)
    }

    /** The resume point applies once, to the still-current restored track; any other open discards it. */
    private fun consumePendingResume(track: MediaItem): Duration? {
        val pending = pendingResume ?: return null
        pendingResume = null
        if (pending.globalKey != track.globalKey || pending.position <= Duration.ZERO) return null
        return pending.position
    }

    /** The whole snapshot: queue shape and mode changes only; the playhead goes through [persistSessionProgress]. */
    private fun persistSessionSnapshot(positionOverride: Duration? = null) {
        val store = sessionStore ?: return
        if (disposed || queue.current == null) return
        val snapshot = MusicSessionSnapshot(queue.captureState(), playContext, positionOverride ?: currentPosition())
        persist("snapshot") { store.save(snapshot) }
    }

    private fun persistSessionProgress(positionOverride: Duration? = null) {
        val store = sessionStore ?: return
        if (currentTrack == null) return
        val cursor = queue.cursor
        val position = positionOverride ?: currentPosition()
        persist("progress") { store.updateProgress(cursor, position) }
    }

    private fun maybePersistPositionTick(position: Duration) {
        if (sessionStore == null || currentTrack == null) return
        val last = lastPositionPersist
        if (last != null && last.elapsedNow() < positionPersistInterval) return
        lastPositionPersist = timeSource.markNow()
        persistSessionProgress(position)
    }

    private fun clearPersistedSession() {
        val store = sessionStore ?: return
        persist("clear") { store.clear() }
    }

    /** Whether the session is written to its store: off while a cast plays a sender's music here, which is never kept. */
    var persistsSession: Boolean = true

    private fun persist(what: String, write: suspend () -> Unit) {
        if (!persistsSession) return
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            try {
                write()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Music session $what write failed" }
            }
        }
    }

    // ---- State --------------------------------------------------------------------------------------------------

    private fun currentPosition(): Duration = player?.state?.position ?: pendingResume?.position ?: Duration.ZERO

    private fun duration(): Duration? {
        val track = currentTrack ?: return null
        val playerDuration = player?.state?.duration ?: Duration.ZERO
        if (playerDuration > Duration.ZERO) return playerDuration
        return track.durationMs?.milliseconds
    }

    private fun setStatus(status: MusicPlaybackStatus) {
        if (disposed) return
        val wasPlaying = this.status == MusicPlaybackStatus.PLAYING
        this.status = status
        // A pause stops the playhead: flush it so a quit while paused restores exactly here.
        if (wasPlaying && status == MusicPlaybackStatus.PAUSED) persistSessionProgress()
        publish()
    }

    private fun publish() {
        if (disposed) return
        mutableState.value = MusicState(
            status = status,
            currentTrack = currentTrack,
            queue = queue.queue,
            currentIndex = queue.cursor,
            playContext = playContext,
            shuffled = queue.shuffled,
            repeatMode = queue.repeatMode,
            duration = duration(),
            sleepTimerActive = sleepTimer != null || sleepTimerEndOfTrack,
            sleepTimerDuration = sleepTimerDuration,
            sleepTimerEndOfTrack = sleepTimerEndOfTrack,
            canGoPrevious = queue.previousIndex() != null,
            canGoNext = queue.nextIndex(manual = true) != null,
            volume = volume,
        )
        updateControls()
    }

    /**
     * Publishes the OS controls' [NowPlaying]: at once when anything but the playhead changed (or [force]), else at
     * most once a second, the latest playhead last.
     */
    private fun updateControls(force: Boolean = false) {
        val next = currentNowPlaying()
        nowPlaying.value = next
        if (!controlsActive || controls == null || next == null) return
        val shown = shownNowPlaying
        val since = shownAt?.elapsedNow()
        when {
            force || shown == null || since == null || shown.copy(positionSeconds = next.positionSeconds) != next -> show(next)
            since >= CONTROLS_INTERVAL -> show(next)
            trailingControls == null -> trailingControls = session.launch {
                delay(CONTROLS_INTERVAL - since)
                trailingControls = null
                val latest = currentNowPlaying()
                if (controlsActive && latest != null) show(latest)
            }
        }
    }

    private fun show(nowPlaying: NowPlaying) {
        trailingControls?.cancel()
        trailingControls = null
        shownNowPlaying = nowPlaying
        shownAt = timeSource.markNow()
        controls?.show(nowPlaying, commands)
    }

    private fun currentNowPlaying(): NowPlaying? {
        val track = currentTrack ?: return null
        val status = when (status) {
            MusicPlaybackStatus.LOADING -> NowPlayingStatus.BUFFERING
            MusicPlaybackStatus.PLAYING -> NowPlayingStatus.PLAYING
            MusicPlaybackStatus.PAUSED -> NowPlayingStatus.PAUSED
            MusicPlaybackStatus.IDLE, MusicPlaybackStatus.ERROR -> return null
        }
        return NowPlaying(
            title = track.title ?: "",
            subtitle = track.trackArtistTitle,
            artworkUrl = artworkFor(track),
            durationSeconds = duration()?.toDouble(DurationUnit.SECONDS) ?: 0.0,
            positionSeconds = currentPosition().toDouble(DurationUnit.SECONDS),
            rate = 1.0,
            status = status,
            canSeek = true,
            canSkipNext = queue.nextIndex(manual = true) != null,
            canSkipPrevious = queue.previousIndex() != null,
            live = false,
            kind = NowPlayingKind.MUSIC,
            album = track.albumTitle,
            backgroundPlayback = backgroundPlayback,
            item = track,
            canSkip = true,
        )
    }

    /** The track's square artwork as an absolute http(s) URL, built once per track. */
    private fun artworkFor(track: MediaItem): String? {
        artwork?.let { (key, url) -> if (key == track.globalKey) return url }
        val path = track.thumbPath
        val url = if (path == null) {
            null
        } else {
            try {
                clientFor(track)?.thumbnailUrl(path, ARTWORK_SIZE, ARTWORK_SIZE)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to build the music artwork URL" }
                null
            }
        }?.takeIf { it.startsWith("https://") || it.startsWith("http://") }
        artwork = track.globalKey to url
        return url
    }

    /** Runs [block] now, up to its first suspension, as its own coroutine; a failure is logged. */
    private fun spawn(block: suspend () -> Unit) {
        session.launch(start = CoroutineStart.UNDISPATCHED) {
            try {
                block()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Music command failed" }
            }
        }
    }

    companion object {
        private const val TAG = "MusicPlayback"
        private const val MAX_CONSECUTIVE_FAILURES = 3
        private const val ARTWORK_SIZE = 512
        private val PREVIOUS_RESTART_THRESHOLD = 3.seconds
        private val CONTROLS_INTERVAL = 1.seconds

        /** The step of an in-track skip without the OS's own interval (hardware fast forward and rewind, a remote). */
        val SKIP_INTERVAL: Duration = 15.seconds
    }
}
