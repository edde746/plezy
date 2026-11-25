package com.edde746.plezy.presentation.livetv.whatson

import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvHubEntry
import com.edde746.plezy.livetv.LiveTvLaunch
import com.edde746.plezy.livetv.LiveTvLaunchResult
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.liveTvLaunch
import com.edde746.plezy.livetv.liveTvProgramMatchesChannel
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.livetv.LiveTvMessage
import com.edde746.plezy.presentation.livetv.LiveTvRefreshGate
import com.edde746.plezy.presentation.livetv.LiveTvServers
import com.edde746.plezy.presentation.livetv.LiveTvWhatsOnTab
import com.edde746.plezy.presentation.livetv.details.ProgramDetailsHost
import com.edde746.plezy.presentation.livetv.details.ProgramDetailsStore
import com.edde746.plezy.presentation.livetv.forEachLiveTvServer
import com.edde746.plezy.presentation.livetv.localUtcOffsetSeconds
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.ServerSettingsRepository
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.time.Clock
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/**
 * The What's On tab: a spinner while [loading] (only before the first hubs), else [emptyText] or the [hubs] rows (grid
 * cards, episodes as their series' poster). Over it: the program [details] sheet and a snackbar ([message]).
 */
data class WhatsOnUiState(
    val loading: Boolean = true,
    val emptyText: String? = null,
    val hubs: List<MediaHub> = emptyList(),
    val details: ProgramDetailsStore? = null,
    val message: LiveTvMessage? = null,
)

/**
 * The What's On tab's state: the discover hubs of every Plex Live TV server (each once), refreshed every 60 s while
 * [refresh] is open. Tapping an item airing now on a known channel tunes it ([play]); a show opens its schedule
 * ([openShowSchedule]); anything else, and a long press, opens the program's details.
 */
class WhatsOnStore(
    private val servers: LiveTvServers,
    private val serverSettings: ServerSettingsRepository,
    private val play: (LiveTvLaunch) -> Unit,
    private val openShowSchedule: (showTitle: String, serverId: ServerId) -> Unit,
    private var use24HourClock: Boolean,
    appForeground: StateFlow<Boolean>,
    parentScope: CoroutineScope,
    private val now: () -> Instant = { Clock.System.now() },
    private val utcOffset: (Long) -> Int = ::localUtcOffsetSeconds,
) : LiveTvWhatsOnTab, ProgramDetailsHost {
    private val scope = parentScope.childScope()
    private var channels: List<LiveTvChannel> = emptyList()

    /** Each row's entries, by row id, in item order. */
    private var entries: Map<String, List<LiveTvHubEntry>> = emptyMap()

    private val mutableState = MutableStateFlow(WhatsOnUiState())
    val state: StateFlow<WhatsOnUiState> = mutableState.asStateFlow()

    override val refresh = LiveTvRefreshGate(scope, REFRESH_INTERVAL, appForeground, onTick = { load() })

    init {
        scope.launch { load() }
    }

    override fun setChannels(channels: List<LiveTvChannel>) {
        this.channels = channels
    }

    /** Taps the item at [index] of the row [hubId]. */
    fun tap(hubId: String, index: Int) {
        val entry = entries[hubId]?.getOrNull(index) ?: return
        val channel = channelFor(entry.program)
        val serverId = ServerId.tryParse(entry.metadata.serverId)
        when {
            channel != null && entry.program.isAiringAt(now().epochSeconds) -> tune(channel)
            entry.metadata.isShow && serverId != null -> openShowSchedule(entry.metadata.displayTitle, serverId)
            else -> openDetails(entry)
        }
    }

    /** Long-presses the item at [index] of the row [hubId]: its details. */
    fun longPress(hubId: String, index: Int) {
        val entry = entries[hubId]?.getOrNull(index) ?: return
        openDetails(entry)
    }

    fun messageShown() = update { it.copy(message = null) }

    fun setUse24HourClock(value: Boolean) {
        use24HourClock = value
    }

    fun release() {
        state.value.details?.release()
        refresh.close()
        scope.cancel()
    }

    override fun tune(channel: LiveTvChannel) {
        when (val launch = liveTvLaunch(servers.entries, servers::client, channel, channels)) {
            is LiveTvLaunchResult.Ready -> play(launch.launch)
            is LiveTvLaunchResult.Failed -> showMessage(LiveTvMessage(launch.message, isError = true))
        }
    }

    override fun recordingChanged(program: LiveTvProgram, scheduled: Boolean) = Unit

    override fun showMessage(message: LiveTvMessage) = update { it.copy(message = message) }

    override fun closeDetails() {
        state.value.details?.release()
        update { it.copy(details = null) }
    }

    private fun openDetails(entry: LiveTvHubEntry) {
        state.value.details?.release()
        val details = ProgramDetailsStore(
            program = entry.program,
            channel = channelFor(entry.program),
            client = ServerId.tryParse(entry.metadata.serverId)?.let(servers::client),
            posterThumb = entry.metadata.grandparentThumbPath ?: entry.metadata.thumbPath,
            serverSettings = serverSettings,
            host = this,
            use24HourClock = use24HourClock,
            parentScope = scope,
            now = now,
            utcOffset = utcOffset,
        )
        update { it.copy(details = details) }
    }

    private fun channelFor(program: LiveTvProgram): LiveTvChannel? = channels.firstOrNull { liveTvProgramMatchesChannel(program, it) }

    private suspend fun load() {
        if (state.value.hubs.isEmpty()) update { it.copy(loading = true) }
        val hubs = mutableListOf<MediaHub>()
        val loaded = LinkedHashMap<String, List<LiveTvHubEntry>>()
        servers.forEachLiveTvServer(
            onError = { _, entry, error -> Log.e(TAG, error) { "What's On failed for ${entry.serverId}" } },
        ) { client, entry ->
            val whatsOn = client.liveTv.whatsOn ?: return@forEachLiveTvServer
            for (hub in whatsOn.fetchHubs()) {
                val id = "${entry.serverId}\u0000${hub.hubKey}"
                val first = hub.entries.firstOrNull()?.metadata
                loaded[id] = hub.entries
                hubs += MediaHub(
                    id = id,
                    title = hub.title,
                    type = "mixed",
                    items = hub.entries.map { it.metadata },
                    size = hub.entries.size,
                    serverId = first?.serverId,
                    serverName = first?.serverName,
                )
            }
        }
        entries = loaded
        update { it.copy(loading = false, hubs = hubs, emptyText = if (hubs.isEmpty()) T.liveTv.noPrograms else null) }
    }

    private inline fun update(change: (WhatsOnUiState) -> WhatsOnUiState) {
        mutableState.value = change(mutableState.value)
    }

    private companion object {
        const val TAG = "WhatsOnStore"
        val REFRESH_INTERVAL = 60.seconds
    }
}
