package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaServerUserProfile
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.queue.EpisodeQueue
import com.edde746.plezy.playback.queue.SleepTimer
import com.edde746.plezy.playback.report.OfflineProgressQueue
import com.edde746.plezy.playback.source.PlaybackServers
import com.edde746.plezy.playback.source.PlaybackSourceResolver
import com.edde746.plezy.playback.tracks.TrackType
import com.edde746.plezy.servers.LocalPlaybackHistory
import com.edde746.plezy.servers.PlaybackStateStore
import com.edde746.plezy.servers.TrackerWatchMarks
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.trackers.TrackedPlayback
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.time.Clock

/**
 * What every [PlaybackSession] of one app session shares: the servers and how a play resolves on them, the queue, the
 * reports' destinations, the trackers, the one-video-at-a-time registry and the sleep timer. Built once per signed-in
 * app session; each playback takes it with its own engine.
 *
 * @param serverStatus each server's online state as it changes ([com.edde746.plezy.servers.MultiServerManager.statusUpdates]):
 *   a server back online while the video buffers reconnects the stream.
 * @param reportScope a scope that outlives each playback: the last stopped report and watched mark finish in it after
 *   the player closed.
 * @param sidecars has each sidecar subtitle's local file, which the engine adds ([SidecarFetcher]).
 * @param profile the active profile's server-side preferences (track languages, subtitle mode), when known.
 * @param awaitProfile waits, briefly, for [profile] to be known: a local file's open waits for it before choosing tracks.
 * @param trackSelectionMemory turns a Jellyfin account's memory of the viewer's audio or subtitle picks on, for the
 *   account the client plays as; true when the server will remember them.
 * @param meteredNetwork whether the device is on a metered (cellular) network now: the startup quality is then the
 *   cellular one, when set.
 * @param playbackAllowed answers whether video may play now (a car's driving restrictions); true elsewhere. A file
 *   opens paused while it says no.
 * @param downloadedEpisodes the completed downloads of a show (its global key) the active profile owns, any order: the
 *   offline library's next and previous episodes.
 * @param requests where a play's start reads the database and asks the server for its item and source
 *   ([PlaybackSession.prepare]): the app's is off the main thread, so the start never waits behind the frames that
 *   present the player. In place by default.
 */
class PlaybackEnvironment(
    val servers: PlaybackServers,
    val serverStatus: Flow<Map<ServerId, Boolean>>,
    val resolver: PlaybackSourceResolver,
    val queue: EpisodeQueue,
    val playbackState: PlaybackStateStore,
    val settings: DeviceSettingsRepository,
    val notifier: WatchStateNotifier,
    val offlineQueue: OfflineProgressQueue?,
    val history: LocalPlaybackHistory,
    val trackers: TrackedPlayback?,
    val trackerMarks: TrackerWatchMarks?,
    val videoSessions: VideoSessions,
    val sleepTimer: SleepTimer?,
    val reportScope: CoroutineScope,
    val sidecars: SidecarFetcher,
    val clock: Clock = Clock.System,
    val profile: () -> MediaServerUserProfile? = { null },
    val awaitProfile: suspend () -> Unit = {},
    val trackSelectionMemory: (suspend (MediaBackend, TrackType) -> Boolean)? = null,
    val meteredNetwork: () -> Boolean = { false },
    val playbackAllowed: () -> Boolean = { true },
    val downloadedEpisodes: suspend (showGlobalKey: String) -> List<MediaItem> = { emptyList() },
    val requests: CoroutineContext = EmptyCoroutineContext,
)
