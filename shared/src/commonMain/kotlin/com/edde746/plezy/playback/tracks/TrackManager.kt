package com.edde746.plezy.playback.tracks

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaServerUserProfile
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ScopedPlayerPrefs
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.seconds

/** The kind of track a server stream selection is for, as Plex and Jellyfin name it. */
enum class TrackType(val wire: String) { AUDIO("audio"), SUBTITLE("subtitle") }

/**
 * Writes a track pick for part [partId] to the server (Plex: `PUT /library/parts/{id}` with this part's stream only)
 * and answers whether the server stored it. A refusal throws [MediaServerHttpException] with its status; transport
 * failures keep their own type, so "refused" and "never answered" stay apart.
 */
typealias TrackPreferencePersister = suspend (partId: Int, type: TrackType, streamId: Int) -> Boolean

/**
 * Makes a MediaBrowser server honour the stream indexes the progress reports already carry for [type] (Jellyfin's
 * account "remember audio/subtitle selections" flag), and answers whether it will.
 */
typealias TrackSelectionMemoryEnabler = suspend (type: TrackType) -> Boolean

/**
 * Selects one open's audio and subtitle tracks once the player listed them, and keeps the viewer's picks on the server.
 *
 * Selection runs as soon as the tracks are ready ([applyTrackSelectionWhenReady]); after 5 s it applies what it can,
 * and a source advertising subtitles the player has not listed keeps it waiting up to 30 s, when the pass decides from
 * whatever arrived. Every pass belongs to a generation: a user pick or an item change starts a new one
 * ([invalidatePendingSelection]), so a stale pass never overwrites an explicit choice.
 *
 * Runs on [scope], which must be single-threaded (the main dispatcher): state is not synchronised.
 */
class TrackManager(
    private val player: TrackPlayer,
    private val scope: CoroutineScope,
    private val settings: DeviceSettingsRepository,
    /** False once the owning screen is gone. */
    private val isActive: () -> Boolean,
    var metadata: MediaItem,
    var mediaInfo: MediaSourceInfo? = null,
    /** Plex: writes a pick per part. Null for MediaBrowser (picks ride the progress reports) and for no server. */
    private val persistTrackPreference: TrackPreferencePersister? = null,
    /** Jellyfin: turns the account's selection memory on. Null for Plex, Emby and no server. */
    private val enableTrackSelectionMemory: TrackSelectionMemoryEnabler? = null,
    private val getProfileSettings: () -> MediaServerUserProfile? = { null },
    /** Waits until the profile settings are known (offline start). */
    private val waitForProfileSettings: suspend () -> Unit = {},
    /** A transient message (a snackbar). */
    private val showMessage: ((message: String) -> Unit)? = null,
    /** Something else (a Watch Together room) owns the playback rate: passes leave it alone. */
    private val playbackRateOwnedExternally: () -> Boolean = { false },
    var preferredAudioTrack: NativeAudioTrack? = null,
    var preferredSubtitle: PreferredSubtitle? = null,
    var preferredSecondarySubtitle: PreferredSubtitle? = null,
    /** The primary subtitle is burned in by the server: no player track is coming for it. */
    var primarySubtitleIsServerRendered: Boolean = false,
    /**
     * Whether an automatic pass may write its subtitle pick to the server: false when the pick is the source's own
     * selected row rather than the viewer's, which would republish the client's guess over the server's per-episode
     * selection. Explicit picks ([onSubtitleTrackSelectedByUser]) are never gated.
     */
    var persistAutomaticSubtitleSelection: Boolean = true,
) {
    private var applying = false
    private var selectionIdle: CompletableDeferred<Unit>? = null
    /** The player command a pass dispatched last; [invalidatePendingSelection] hands it out (done or not). */
    private var activeMutationDrain: Deferred<Unit>? = null
    private var trackLoadingJob: Job? = null
    private var fallbackJob: Job? = null
    private var disposed = false
    private var selectionGeneration = 0

    /** The "not remembered" notice went out for this manager already: once is enough. */
    private var reportedSelectionNotRemembered = false

    private val managerIsActive: Boolean get() = !disposed && isActive()

    private fun isSelectionCurrent(generation: Int) = managerIsActive && generation == selectionGeneration

    /**
     * Retires every pending automatic selection before the player is reused, and returns the player command in flight
     * now (completed when none) so a reload can await it before opening new media: nothing of the old generation lands
     * on the replacement. Disposal ignores it.
     */
    fun invalidatePendingSelection(): Deferred<Unit> {
        val drain = activeMutationDrain
        selectionGeneration++
        trackLoadingJob?.cancel()
        trackLoadingJob = null
        fallbackJob?.cancel()
        fallbackJob = null
        return drain ?: CompletableDeferred(Unit)
    }

    /**
     * Applies the selection once the tracks are ready: now, on the track list update that makes them ready, or at the
     * 5 s fallback, which keeps waiting another 25 s while advertised subtitles are missing and then decides from
     * what arrived. Does nothing once the manager is inactive.
     */
    fun applyTrackSelectionWhenReady() {
        if (!managerIsActive) return
        val generation = selectionGeneration
        fun current() = isSelectionCurrent(generation)
        if (tracksReadyForSelection(player.tracks.value)) {
            scope.launch { applyTrackSelection() }
            return
        }

        trackLoadingJob?.cancel()
        trackLoadingJob = scope.launch {
            player.tracks.first { current() && tracksReadyForSelection(it) }
            trackLoadingJob = null
            fallbackJob?.cancel()
            fallbackJob = null
            scope.launch { applyTrackSelection() }
        }

        fallbackJob?.cancel()
        fallbackJob = scope.launch {
            delay(FIRST_FALLBACK)
            if (!current()) return@launch
            val waitingForSubtitles = mediaInfo?.subtitleTracks?.isNotEmpty() == true && !tracksReadyForSelection(player.tracks.value)
            if (!waitingForSubtitles) {
                trackLoadingJob?.cancel()
                trackLoadingJob = null
                fallbackJob = null
                scope.launch { applyTrackSelection() }
                return@launch
            }
            Log.w(TAG) { "Player subtitle tracks still pending after 5 s; applying ready settings and waiting on" }
            scope.launch { applyTrackSelection() }
            delay(FINAL_DEADLINE - FIRST_FALLBACK)
            if (!current()) return@launch
            trackLoadingJob?.cancel()
            trackLoadingJob = null
            fallbackJob = null
            if (!tracksReadyForSelection(player.tracks.value)) {
                Log.w(TAG) { "Advertised subtitle selection did not resolve before the 30 s deadline" }
            }
            scope.launch { applyTrackSelection(waitForPendingSource = false) }
        }
    }

    private fun tracksReadyForSelection(tracks: NativeTracks): Boolean {
        val realSubtitles = tracks.realSubtitle
        val selector = TrackSelector(metadata.backend, mediaInfo)
        // A burned-in primary is on screen already; only a carried second subtitle and advertised audio are awaited.
        if (primarySubtitleIsServerRendered) {
            if (!secondaryPreferenceResolves(selector, realSubtitles)) return false
            return !awaitingAdvertisedAudio(tracks)
        }
        if (tracks.audio.isEmpty() && tracks.subtitle.isEmpty()) return false
        val audio = selector.selectAudioTrack(tracks.realAudio, preferredAudioTrack)?.track
        // A null subtitle decision is the only state in which a wanted source track can still arrive.
        return selector.selectSubtitleTrack(realSubtitles, preferredSubtitle, audio) != null
    }

    /** The carried second subtitle has a track to land on; vacuously true when none is wanted or none can show. */
    private fun secondaryPreferenceResolves(selector: TrackSelector, realSubtitles: List<NativeSubtitleTrack>): Boolean {
        val preference = preferredSecondarySubtitle
        if (preference == null || preference == PreferredSubtitle.Off) return true
        if (!player.supportsSecondarySubtitles) return true
        return selector.secondarySubtitleMatch(realSubtitles, preference) != null
    }

    /** The source advertises audio the player has not listed yet; a silent source is never waited for. */
    private fun awaitingAdvertisedAudio(tracks: NativeTracks): Boolean =
        mediaInfo?.audioTracks?.isNotEmpty() == true && tracks.realAudio.isEmpty()

    /**
     * One selection pass ([TrackSelector.selectAndApplyTracks]) with the profile, the carried picks and the title's
     * playback speed; returns whether every player command ran for this still-current generation. A pass asked for
     * while one runs waits for it, then runs if still current. [waitForPendingSource] false (the deadline pass) decides
     * from the tracks that arrived.
     */
    suspend fun applyTrackSelection(waitForPendingSource: Boolean = true): Boolean {
        val generation = selectionGeneration
        fun active() = isSelectionCurrent(generation)
        if (!active()) return false

        if (applying) {
            val running = selectionIdle ?: return false
            running.await()
            if (!active()) return false
            return applyTrackSelection(waitForPendingSource)
        }

        applying = true
        val idle = CompletableDeferred<Unit>()
        selectionIdle = idle
        try {
            waitForProfileSettings()
            if (!active()) return false
            val profile = getProfileSettings()
            val speed = if (playbackRateOwnedExternally()) null else ScopedPlayerPrefs.resolve(settings, ScopedPlayerPrefs.playbackSpeed, metadata)
            if (!active()) return false
            return TrackSelector(metadata.backend, mediaInfo, profile).selectAndApplyTracks(
                player = player,
                preferredAudioTrack = preferredAudioTrack,
                preferredSubtitle = preferredSubtitle,
                preferredSecondarySubtitle = preferredSecondarySubtitle,
                defaultPlaybackSpeed = speed,
                onAudioTrackChanged = ::onAudioTrackChanged,
                onSubtitleTrackChanged = if (persistAutomaticSubtitleSelection) { track -> onSubtitleTrackChanged(track) } else null,
                isActive = ::active,
                onMutationDispatched = { activeMutationDrain = it },
                waitForPendingSource = waitForPendingSource,
                primarySubtitleIsServerRendered = primarySubtitleIsServerRendered,
            )
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to apply track selection" }
            return false
        } finally {
            applying = false
            if (selectionIdle === idle) selectionIdle = null
            idle.complete(Unit)
        }
    }

    /**
     * Records the viewer's audio pick, which the caller already sent to the player. Retires the pending automatic
     * selection first: its late pass would otherwise overwrite the pick.
     */
    suspend fun onAudioTrackSelectedByUser(track: NativeAudioTrack) {
        invalidatePendingSelection().await()
        onAudioTrackChanged(track)
    }

    /** Records the viewer's subtitle pick as [onAudioTrackSelectedByUser]; [sourceStreamId] the row, when known. */
    suspend fun onSubtitleTrackSelectedByUser(track: NativeSubtitleTrack, sourceStreamId: Int? = null) {
        invalidatePendingSelection().await()
        onSubtitleTrackChanged(track, sourceStreamId)
    }

    /** Keeps an audio pick on the server: the stream of this part it matches. */
    suspend fun onAudioTrackChanged(track: NativeAudioTrack) {
        val info = mediaInfo
        val partId = guardTrackChange(info, TrackType.AUDIO) ?: return
        if (info == null) return
        val streamId = findSourceTrackForNativeAudio(track, info.audioTracks, player.tracks.value.audio)?.id
        if (streamId == null) Log.e(TAG) { "Could not match the audio track to a server stream" }
        saveTrackPreference(partId, TrackType.AUDIO, streamId)
    }

    /** Keeps a subtitle pick on the server: off as stream 0, else [sourceStreamId] or the stream the track matches. */
    suspend fun onSubtitleTrackChanged(track: NativeSubtitleTrack, sourceStreamId: Int? = null) {
        val info = mediaInfo
        val partId = guardTrackChange(info, TrackType.SUBTITLE) ?: return
        val streamId = when {
            track.id == NativeSubtitleTrack.OFF.id -> 0
            sourceStreamId != null -> sourceStreamId
            info != null -> findSourceTrackForNativeSubtitle(track, info.subtitleTracks, player.tracks.value.subtitle)?.id
                .also { if (it == null) Log.e(TAG) { "Could not match the subtitle track to a server stream" } }
            else -> null
        }
        saveTrackPreference(partId, TrackType.SUBTITLE, streamId)
    }

    /**
     * The part to write a pick against, or null when nothing is written per part: the viewer opted out
     * (`remember_track_selections`), the backend remembers picks through its account (settled here), or the source has
     * no part id.
     */
    private suspend fun guardTrackChange(info: MediaSourceInfo?, type: TrackType): Int? {
        if (!settings.value(AppSettings.rememberTrackSelections)) return null
        if (persistTrackPreference == null) {
            ensureServerRemembersSelections(type)
            return null
        }
        if (info == null) {
            Log.w(TAG) { "No media info: cannot save the stream selection" }
            return null
        }
        val partId = info.partId
        if (partId == null) {
            Log.w(TAG) { "No part id: cannot save the stream selection" }
            reportSelectionNotRemembered()
        }
        return partId
    }

    /** Writes the pick; a pick that matched no stream, or one the server did not store, is session-only: say so. */
    private suspend fun saveTrackPreference(partId: Int, type: TrackType, streamId: Int?) {
        if (streamId == null) {
            Log.w(TAG) { "Not saving the ${type.wire} selection: no server stream matched" }
            reportSelectionNotRemembered()
            return
        }
        val persist = persistTrackPreference ?: return
        if (!isActive()) return
        val stored = try {
            persist(partId, type, streamId)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            handleServerSyncFailure("save the ${type.wire} stream selection", e)
            return
        }
        if (stored) return
        Log.w(TAG) { "The server did not store the ${type.wire} stream selection" }
        reportSelectionNotRemembered()
    }

    private suspend fun ensureServerRemembersSelections(type: TrackType) {
        val enable = enableTrackSelectionMemory ?: return
        if (!isActive()) return
        val remembered = try {
            enable(type)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            handleServerSyncFailure("turn on the account's ${type.wire} selection memory", e)
            return
        }
        if (remembered) return
        Log.w(TAG) { "The server will not remember ${type.wire} selections" }
        reportSelectionNotRemembered()
    }

    /** A request that never got a verdict (network, timeout, cancellation) only logs; anything else is a refusal. */
    private fun handleServerSyncFailure(action: String, error: Exception) {
        if (error is MediaServerHttpException && (error.isTransient || error.isCancellation)) {
            Log.w(TAG, error) { "Could not $action: no server verdict" }
            return
        }
        Log.w(TAG, error) { "The server refused to $action" }
        reportSelectionNotRemembered()
    }

    /** Tells the viewer once per manager that a pick applies to this playback only. */
    private fun reportSelectionNotRemembered() {
        if (reportedSelectionNotRemembered || !managerIsActive) return
        reportedSelectionNotRemembered = true
        showMessage?.invoke(T.messages.trackSelectionNotRemembered)
    }

    fun dispose() {
        if (disposed) return
        disposed = true
        invalidatePendingSelection()
    }

    private companion object {
        const val TAG = "TrackManager"
        val FIRST_FALLBACK = 5.seconds
        val FINAL_DEADLINE = 30.seconds
    }
}
