package com.edde746.plezy.presentation.livetv

import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvLaunch
import com.edde746.plezy.livetv.LiveTvLaunchResult
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.liveTvLaunch
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.livetv.details.ProgramDetailsHost
import com.edde746.plezy.presentation.livetv.details.ProgramDetailsStore
import com.edde746.plezy.presentation.livetv.guide.GuideEvent
import com.edde746.plezy.presentation.livetv.guide.GuideStore
import com.edde746.plezy.presentation.livetv.recordings.RecordingsStore
import com.edde746.plezy.presentation.livetv.whatson.WhatsOnStore
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.ServerSettingsRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * The Live TV destination: the screen's store ([screen]) and its tabs' stores ([guide], [whatsOn], [recordings]), wired
 * together. What the guide asks for lands here: a tune opens the channel through [play], details open the program's
 * sheet ([details]), a favourite toggle goes to the screen's favourites, and leaving the guide moves focus to the side
 * navigation ([LiveTvScreenFocus.SIDEBAR]) or the tab bar.
 *
 * Main thread only; [close] when the destination's route leaves every stack.
 *
 * @param play opens the player on a channel.
 * @param openShowSchedule opens a show's upcoming airings on one server.
 * @param isTv a TV: SELECT on an airing program tunes it, and holds act.
 */
class LiveTvScreen(
    private val servers: LiveTvServers,
    private val serverSettings: ServerSettingsRepository,
    private val play: (LiveTvLaunch) -> Unit,
    openShowSchedule: (showTitle: String, serverId: ServerId) -> Unit,
    appForeground: StateFlow<Boolean>,
    favoritesOnly: Boolean,
    isTv: Boolean,
    private var use24HourClock: Boolean,
    parentScope: CoroutineScope,
) : ProgramDetailsHost {
    private val scope = parentScope.childScope()

    val guide = GuideStore(servers, scope, appForeground, isTv, use24HourClock)
    val whatsOn = WhatsOnStore(servers, serverSettings, play, openShowSchedule, use24HourClock, appForeground, scope)
    val recordings = RecordingsStore(servers, serverSettings, use24HourClock, appForeground, scope)
    val screen = LiveTvStore(servers, guide, whatsOn, recordings, favoritesOnly, scope, use24HourClock)

    private val mutableDetails = MutableStateFlow<ProgramDetailsStore?>(null)

    /** The guide's program details sheet, or null. */
    val details: StateFlow<ProgramDetailsStore?> = mutableDetails.asStateFlow()

    private val mutableFocus = MutableStateFlow<LiveTvScreenFocus?>(null)

    /** Where focus leaves the screen to, once; [focusHandled] clears it. */
    val focus: StateFlow<LiveTvScreenFocus?> = mutableFocus.asStateFlow()

    init {
        scope.launch {
            guide.events.collect { event ->
                when (event) {
                    is GuideEvent.Tune -> tune(event.channel)
                    is GuideEvent.ShowDetails -> openDetails(event.channel, event.program)
                    is GuideEvent.ToggleFavorite -> screen.toggleFavorite(event.channel)
                    GuideEvent.Back -> mutableFocus.value = LiveTvScreenFocus.SIDEBAR
                    GuideEvent.FocusTabs -> screen.focusTabBar()
                }
            }
        }
    }

    fun focusHandled() {
        mutableFocus.value = null
    }

    /** The platform's 12/24-hour clock changed. */
    fun setUse24HourClock(value: Boolean) {
        use24HourClock = value
        guide.setUse24HourClock(value)
        whatsOn.setUse24HourClock(value)
        recordings.setUse24HourClock(value)
        screen.setUse24HourClock(value)
    }

    override fun tune(channel: LiveTvChannel) {
        when (val launch = liveTvLaunch(servers.entries, servers::client, channel, screen.state.value.channels)) {
            is LiveTvLaunchResult.Ready -> play(launch.launch)
            is LiveTvLaunchResult.Failed -> screen.showMessage(LiveTvMessage(launch.message, isError = true))
        }
    }

    override fun recordingChanged(program: LiveTvProgram, scheduled: Boolean) = guide.setRecordingOverride(program, scheduled)

    override fun showMessage(message: LiveTvMessage) = screen.showMessage(message)

    override fun closeDetails() {
        mutableDetails.value?.release()
        mutableDetails.value = null
    }

    private fun openDetails(channel: LiveTvChannel, program: LiveTvProgram) {
        mutableDetails.value?.release()
        mutableDetails.value = ProgramDetailsStore(
            program = program,
            channel = channel,
            client = (program.serverId ?: channel.serverId)?.let(ServerId::tryParse)?.let(servers::client),
            posterThumb = program.thumb,
            serverSettings = serverSettings,
            host = this,
            use24HourClock = use24HourClock,
            parentScope = scope,
        )
    }

    fun close() {
        closeDetails()
        screen.close()
        guide.close()
        whatsOn.release()
        recordings.release()
        scope.cancel()
    }
}

/** Where focus goes when it leaves the Live TV screen's content. */
enum class LiveTvScreenFocus {
    /** The side navigation (TV and desktop). */
    SIDEBAR,
}
