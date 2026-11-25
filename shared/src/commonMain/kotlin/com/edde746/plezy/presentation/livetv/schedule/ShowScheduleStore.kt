package com.edde746.plezy.presentation.livetv.schedule

import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvLaunch
import com.edde746.plezy.livetv.LiveTvLaunchResult
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.liveTvDvr
import com.edde746.plezy.livetv.liveTvLaunch
import com.edde746.plezy.livetv.liveTvProgramMatchesChannel
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.livetv.LiveTvMessage
import com.edde746.plezy.presentation.livetv.LiveTvServers
import com.edde746.plezy.presentation.livetv.details.ProgramDetailsHost
import com.edde746.plezy.presentation.livetv.details.ProgramDetailsStore
import com.edde746.plezy.format.clockTime
import com.edde746.plezy.presentation.livetv.liveTvRelativeDay
import com.edde746.plezy.presentation.livetv.localUtcOffsetSeconds
import com.edde746.plezy.presentation.livetv.recordings.RecordEntries
import com.edde746.plezy.presentation.livetv.recordings.RecordOptionsMode
import com.edde746.plezy.presentation.livetv.recordings.RecordOptionsStore
import com.edde746.plezy.presentation.livetv.recordings.recordEntriesFor
import com.edde746.plezy.presentation.livetv.recordings.recordOutcomeMessage
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.ServerSettingsRepository
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.Instant

/**
 * A show's upcoming airings, titled [title]: a spinner while [loading], else [emptyText] or the [rows]. The app bar
 * carries the "Record show" action when [recordShowLabel] is set. Over it: the program [details] sheet, the Record
 * Options sheet ([recordOptions]) and a snackbar ([message]).
 */
data class ShowScheduleUiState(
    val title: String,
    val loading: Boolean = true,
    val emptyText: String? = null,
    val rows: List<ScheduleRow> = emptyList(),
    val recordShowLabel: String? = null,
    val details: ProgramDetailsStore? = null,
    val recordOptions: RecordOptionsStore? = null,
    val message: LiveTvMessage? = null,
)

/**
 * One airing: [title] ("S1 · E2 — Pilot" or the title) with the [premiereBadge] pill; airing now ([live]) it is tinted
 * with a play icon; [subtitle] says when ("12 min left", "Starting in 30 min", "Tomorrow at 20:00") and the summary;
 * [channelName] the channel it airs on.
 */
data class ScheduleRow(
    val title: String,
    val premiereBadge: String?,
    val live: Boolean,
    val subtitle: String,
    val channelName: String?,
)

/**
 * The show schedule screen's state: the airings of [showTitle] on [serverId] from an hour ago to 48 hours ahead (the
 * episodes of the show, or airings titled as it when they have no show), by start. Tapping an airing on now with a
 * known channel tunes it ([play]); any other opens its details. "Record show" shows when the server records and an
 * airing has a guid; it records the first such airing (its template offers the series rule too). The channels the
 * airings are matched to follow [channels], the Live TV screen's as they load.
 */
class ShowScheduleStore(
    private val showTitle: String,
    private val serverId: ServerId,
    channels: Flow<List<LiveTvChannel>>,
    private val servers: LiveTvServers,
    private val serverSettings: ServerSettingsRepository,
    private val play: (LiveTvLaunch) -> Unit,
    private var use24HourClock: Boolean,
    parentScope: CoroutineScope,
    private val now: () -> Instant = { Clock.System.now() },
    private val utcOffset: (Long) -> Int = ::localUtcOffsetSeconds,
) : ProgramDetailsHost {
    private val scope = parentScope.childScope()
    private var programs: List<LiveTvProgram> = emptyList()
    private var knownChannels: List<LiveTvChannel> = emptyList()
    private var loaded = false

    private val mutableState = MutableStateFlow(ShowScheduleUiState(title = showTitle))
    val state: StateFlow<ShowScheduleUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            channels.collect {
                knownChannels = it
                if (loaded) publish()
            }
        }
        scope.launch { load() }
    }

    /** Taps the airing at [index] of [ShowScheduleUiState.rows]. */
    fun tap(index: Int) {
        val program = programs.getOrNull(index) ?: return
        val channel = channelFor(program)
        if (channel != null && program.isAiringAt(now().epochSeconds)) tune(channel) else openDetails(program, channel)
    }

    /** Records the show: the Record Options sheet for its first recordable airing. */
    fun recordShow() {
        val client = servers.client(serverId) ?: return
        val seed = programs.firstOrNull { !it.guid.isNullOrEmpty() } ?: return
        scope.launch {
            when (val entries = recordEntriesFor(client, seed)) {
                is RecordEntries.Unavailable -> showMessage(entries.message)
                is RecordEntries.Ready -> {
                    val options = RecordOptionsStore(client, serverSettings, RecordOptionsMode.Create(seed.displayTitle, entries.entries), scope) { outcome ->
                        state.value.recordOptions?.release()
                        update { it.copy(recordOptions = null) }
                        recordOutcomeMessage(outcome)?.let(::showMessage)
                    }
                    update { it.copy(recordOptions = options) }
                }
            }
        }
    }

    fun messageShown() = update { it.copy(message = null) }

    fun setUse24HourClock(value: Boolean) {
        if (use24HourClock == value) return
        use24HourClock = value
        publish()
    }

    fun release() {
        state.value.details?.release()
        state.value.recordOptions?.release()
        scope.cancel()
    }

    override fun tune(channel: LiveTvChannel) {
        when (val launch = liveTvLaunch(servers.entries, servers::client, channel, knownChannels)) {
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

    private fun openDetails(program: LiveTvProgram, channel: LiveTvChannel?) {
        state.value.details?.release()
        val details = ProgramDetailsStore(
            program = program,
            channel = channel,
            client = servers.client(serverId),
            posterThumb = program.thumb,
            serverSettings = serverSettings,
            host = this,
            use24HourClock = use24HourClock,
            parentScope = scope,
            now = now,
            utcOffset = utcOffset,
        )
        update { it.copy(details = details) }
    }

    private suspend fun load() {
        val client = servers.client(serverId)
        if (client != null) {
            val at = now()
            programs = try {
                client.liveTv.fetchSchedule(at - 1.hours, at + 48.hours)
                    .filter { it.grandparentTitle == showTitle || (it.grandparentTitle == null && it.title == showTitle) }
                    .sortedBy { it.beginsAt ?: 0 }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Show schedule failed for $serverId" }
                emptyList()
            }
        }
        loaded = true
        publish()
    }

    private fun channelFor(program: LiveTvProgram): LiveTvChannel? = knownChannels.firstOrNull { liveTvProgramMatchesChannel(program, it) }

    private fun publish() {
        val nowSeconds = now().epochSeconds
        val recordable = servers.client(serverId)?.liveTvDvr != null && programs.any { !it.guid.isNullOrEmpty() }
        update {
            it.copy(
                loading = false,
                emptyText = if (programs.isEmpty()) T.liveTv.noPrograms else null,
                rows = programs.map { program -> row(program, nowSeconds) },
                recordShowLabel = if (recordable) T.liveTv.recordShow else null,
            )
        }
    }

    private fun row(program: LiveTvProgram, nowSeconds: Long): ScheduleRow {
        val live = program.isAiringAt(nowSeconds)
        val season = program.parentIndex
        val episode = program.index
        val title = if (season != null && episode != null) "S$season · E$episode — ${program.title}" else program.title
        val subtitle = listOfNotNull(timeInfo(program, live, nowSeconds), program.summary?.takeIf { it.isNotEmpty() }).joinToString(" — ")
        return ScheduleRow(
            title = title,
            premiereBadge = if (program.premiere == true) T.liveTv.premiereBadge else null,
            live = live,
            subtitle = subtitle,
            channelName = channelFor(program)?.displayName,
        )
    }

    private fun timeInfo(program: LiveTvProgram, live: Boolean, nowSeconds: Long): String {
        val begins = program.beginsAt ?: return ""
        val ends = program.endsAt
        if (live && ends != null) return T.discover.minutesLeft(minutes = ((ends - nowSeconds) / 60).toString())
        val minutesUntil = (begins - nowSeconds) / 60
        if (minutesUntil in 1 until STARTING_SOON_MINUTES) return T.liveTv.startingInMinutes(minutes = minutesUntil.toString())
        return T.liveTv.dayAtTime(
            day = liveTvRelativeDay(begins, nowSeconds, utcOffset),
            time = clockTime(begins, use24HourClock, utcOffset),
        )
    }

    private inline fun update(change: (ShowScheduleUiState) -> ShowScheduleUiState) {
        mutableState.value = change(mutableState.value)
    }

    private companion object {
        const val TAG = "ShowScheduleStore"
        const val STARTING_SOON_MINUTES = 90L
    }
}
