package com.edde746.plezy.presentation.livetv.guide

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvChannelGroup
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.liveTvDvr
import com.edde746.plezy.livetv.scopeKey
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.livetv.LiveTvGuideTab
import com.edde746.plezy.presentation.livetv.LiveTvRefreshGate
import com.edde746.plezy.presentation.livetv.LiveTvServers
import com.edde746.plezy.presentation.livetv.forEachLiveTvServer
import com.edde746.plezy.format.clockTime
import com.edde746.plezy.presentation.livetv.liveTvDuration
import com.edde746.plezy.presentation.livetv.localDay
import com.edde746.plezy.presentation.livetv.localUtcOffsetSeconds
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlin.math.round
import kotlin.time.Clock
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Instant

/**
 * The Live TV guide's state ([GuideUiState]) and its D-pad model; the UIs map keys ([onKeyDown], [onKeyUp]) and
 * pointer gestures to it and render. What it asks of the Live TV screen comes out of [events].
 *
 * - Loading: every Live TV server once (the first of its entries) gives the window's airings and its recordings'
 *   keys. A load another one supersedes never lands; a server that fails is logged and the others show.
 * - The window opens an hour before the current half hour ("now-anchored"). ◀ ▶ move it two hours, the day picker to a
 *   day (keeping its time of day) and then a time slot. Every minute the now line moves on, and a now-anchored window
 *   now has left is moved to now; a picked one never is. Coming back after half an hour or more scrolls back to now.
 * - Recording dots: a recording started or cancelled from the guide ([setRecordingOverride]) decides its airing's dot
 *   until the next load; else the grid's subscription tag; else the server's scheduled recordings and the rules' grabs
 *   that still record.
 * - On a TV ([isTv]) SELECT on an airing that is on now tunes its channel, anywhere else it opens the details; holding
 *   SELECT opens the details on an airing and the channel's menu ([GuideUiState.channelMenu]) on a channel, as the Menu
 *   key does.
 *
 * Main thread only; [close] with the Live TV screen.
 *
 * @param use24HourClock the platform's 24-hour setting ([setUse24HourClock] when it changes).
 * @param utcOffset the device time zone's offset from UTC at an instant (epoch milliseconds), in seconds.
 */
class GuideStore(
    private val servers: LiveTvServers,
    parentScope: CoroutineScope,
    appForeground: StateFlow<Boolean>,
    private val isTv: Boolean,
    private var use24HourClock: Boolean,
    private val now: () -> Instant = { Clock.System.now() },
    private val utcOffset: (Long) -> Int = ::localUtcOffsetSeconds,
) : LiveTvGuideTab {
    private val scope = parentScope.childScope()

    private var channels: List<LiveTvChannel> = emptyList()
    private var groups: List<LiveTvChannelGroup> = emptyList()
    private var favoriteKeys: Set<String> = emptySet()

    private var programs: List<LiveTvProgram> = emptyList()
    private var programsByScope: Map<String, List<LiveTvProgram>> = emptyMap()
    private var scheduledKeys: Set<String> = emptySet()
    private var recordingOverrides: Map<String, Boolean> = emptyMap()

    private var isLoading = true
    private var hasLoadedOnce = false
    private var loadJob: Job? = null
    private var scheduledKeysJob: Job? = null

    private var windowStart: Long = guideNowWindowStart(nowSeconds(), utcOffset)
    private var nowWasInWindow = true

    // Whether the loaded window opens at now (the first load, Now): it scrolls to the now line. A window the user moved
    // to (±2 h, a day, a time slot) opens at its start, the time its label shows.
    private var opensAtNow = true
    private var hiddenSince: Long? = null

    // The part of the window the UI shows ([setView]), in points from its start; null until the UI says what it shows
    // of the window loaded last.
    private var viewStart: Double? = null
    private var viewWidth = 0.0

    private var focus = GuideFocus()
    private var hasFocus = false
    private var pendingFocus = false
    private var pendingJump: Pair<LiveTvChannel, LiveTvProgram?>? = null
    private var menu: GuideMenu? = null
    private var channelMenu: Int? = null
    private var scroll: GuideScroll? = null
    private var focusRequest = 0

    // The SELECT hold: a press starts the timer; its end is a hold, a release before it a press.
    private var selectDown = false
    private var holdJob: Job? = null
    private var suppressSelectUntilUp = false

    /** The rows as last built; null when something they show changed. */
    private var rows: List<GuideRow>? = null

    private val mutableState = MutableStateFlow(GuideUiState())
    val state: StateFlow<GuideUiState> = mutableState.asStateFlow()

    private val eventChannel = Channel<GuideEvent>(Channel.UNLIMITED)
    val events: Flow<GuideEvent> = eventChannel.receiveAsFlow()

    override val refresh: LiveTvRefreshGate = LiveTvRefreshGate(
        parentScope = scope,
        interval = 1.minutes,
        appForeground = appForeground,
        onTick = { tick() },
        onPaused = { hiddenSince = hiddenSince ?: nowSeconds() },
        onResumed = { resumed() },
    )

    init {
        load()
    }

    override fun setChannels(displayed: List<LiveTvChannel>, groups: List<LiveTvChannelGroup>, favoriteKeys: Set<String>) {
        val focusedKey = channels.getOrNull(focus.channelIndex)?.scopeKey
        if (displayed != channels) programsByScope = indexGuidePrograms(programs, displayed)
        channels = displayed
        this.groups = groups
        this.favoriteKeys = favoriteKeys
        if (displayed.isNotEmpty()) refocusChannel(focusedKey)
        rows = null
        publish()
    }

    /** The platform's 24-hour setting changed. */
    fun setUse24HourClock(use24HourClock: Boolean) {
        if (use24HourClock == this.use24HourClock) return
        this.use24HourClock = use24HourClock
        rows = null
        publish()
    }

    /** The guide gained or lost the platform's focus. */
    fun setFocused(focused: Boolean) {
        if (focused == hasFocus) return
        if (!focused) {
            resetHold()
            // The held SELECT's release goes to whatever took the focus: the next press here is a new one.
            suppressSelectUntilUp = false
        }
        hasFocus = focused
        publish()
    }

    /**
     * The UI shows the window from [start] points across the grid, [width] wide (the airings' sideways scroll and its
     * viewport). The day pill and the time beside it name what is in view ([GuideUiState.dayLabel]).
     */
    fun setView(start: Double, width: Double) {
        if (start == viewStart && width == viewWidth) return
        val before = labels(nowSeconds())
        viewStart = start
        viewWidth = width
        if (labels(nowSeconds()) != before) publish()
    }

    /**
     * Puts the D-pad focus on the first channel (the day picker without channels) and asks for the platform's focus;
     * while a window loads, once it has. The UI calls it in keyboard or D-pad mode as focus enters the guide.
     */
    fun focusContent() {
        if (isLoading) {
            pendingFocus = true
            return
        }
        pendingFocus = false
        focus = if (channels.isNotEmpty()) {
            GuideFocus(zone = GuideZone.GRID, channelIndex = 0, column = GuideColumn.CHANNEL)
        } else {
            GuideFocus(zone = GuideZone.TIME_NAV, timeNavItem = GuideTimeNavItem.DAY)
        }
        focusRequest++
        publish()
    }

    override fun jumpToChannel(channel: LiveTvChannel) {
        if (isLoading) {
            pendingJump = channel to null
            return
        }
        val index = channelIndex(channel) ?: return
        focus = GuideFocus(zone = GuideZone.GRID, channelIndex = index, column = GuideColumn.CHANNEL)
        focusRequest++
        requestScroll(index, null)
        publish()
    }

    /** Outside the window, the window moves to start one slot before the half hour [program] begins in, and loads first. */
    override fun jumpToProgram(channel: LiveTvChannel, program: LiveTvProgram) {
        if (isLoading) {
            pendingJump = channel to program
            return
        }
        val index = channelIndex(channel) ?: return
        val begin = program.beginsAt
        val end = program.endsAt ?: begin
        if (begin != null && !(end != null && begin < windowStart + GuideLayout.WINDOW_SECONDS && end > windowStart)) {
            pendingJump = channel to program
            setWindow(guideAiringWindowStart(begin, utcOffset))
            return
        }
        // The search's airings come from its own fetch: the block is the loaded airing with the same start.
        val target = programsOf(index).firstOrNull { it.beginsAt == program.beginsAt }
        focus = GuideFocus(
            zone = GuideZone.GRID,
            channelIndex = index,
            column = if (target != null) GuideColumn.PROGRAM else GuideColumn.CHANNEL,
            program = target,
        )
        focusRequest++
        requestScroll(index, target?.let { GuideHorizontalScroll.ToProgram(blockLeft(it)) })
        publish()
    }

    /**
     * A recording of [program] was started ([scheduled]) or cancelled from the guide: its dot follows until the next
     * load, whatever the server's lists say meanwhile. The scheduled recordings are asked for again.
     */
    fun setRecordingOverride(program: LiveTvProgram, scheduled: Boolean) {
        val keys = guideRecordingKeys(program)
        if (keys.isNotEmpty()) {
            recordingOverrides = recordingOverrides + keys.associateWith { scheduled }
            rows = null
            publish()
        }
        refreshScheduledKeys()
    }

    /** A key went down ([repeat]: the platform's auto-repeat). Returns whether the guide used it. */
    fun onKeyDown(key: InputKey, repeat: Boolean = false): Boolean = onKey(key, if (repeat) KeyPhase.REPEAT else KeyPhase.DOWN)

    /** A key came up. Platforms without key-ups (a tvOS press) send a key-down, then its key-up. */
    fun onKeyUp(key: InputKey): Boolean = onKey(key, KeyPhase.UP)

    /** A click or tap on the time navigation's [item]: ◀ ▶ move the window, the day pill opens the day picker. */
    fun selectTimeNav(item: GuideTimeNavItem) {
        when (item) {
            GuideTimeNavItem.EARLIER -> shiftWindow(-GuideLayout.SHIFT_HOURS)
            GuideTimeNavItem.DAY -> openDayMenu()
            GuideTimeNavItem.LATER -> shiftWindow(GuideLayout.SHIFT_HOURS)
        }
    }

    /** A click or tap on [channelIndex]'s channel cell tunes it. */
    fun tapChannel(channelIndex: Int) {
        channels.getOrNull(channelIndex)?.let { emit(GuideEvent.Tune(it)) }
    }

    /** A long press, a secondary click, a held SELECT (TV) or the Menu key on [channelIndex]'s channel cell opens its menu. */
    fun openChannelMenu(channelIndex: Int) {
        if (channels.getOrNull(channelIndex) == null) return
        channelMenu = channelIndex
        publish()
    }

    /** The channel's menu closed, picked from or not: the guide takes the focus back. */
    fun dismissChannelMenu() {
        if (channelMenu == null) return
        channelMenu = null
        focusRequest++
        publish()
    }

    /** Adds [channelIndex]'s channel to the favourites or takes it off (its menu's Favorite, the F key). */
    fun toggleFavorite(channelIndex: Int) {
        channels.getOrNull(channelIndex)?.let { emit(GuideEvent.ToggleFavorite(it)) }
    }

    /** A click or tap on [program]'s block on [channelIndex]'s row: on a TV an airing on now tunes, else its details. */
    fun tapProgram(channelIndex: Int, program: LiveTvProgram) {
        channels.getOrNull(channelIndex)?.let { activate(it, program) }
    }

    /** A long press or secondary click on [program]'s block opens its details. */
    fun longPressProgram(channelIndex: Int, program: LiveTvProgram) {
        channels.getOrNull(channelIndex)?.let { emit(GuideEvent.ShowDetails(it, program)) }
    }

    /** Opens the day picker ([GuideMenu.Days]). */
    fun openDayMenu() {
        menu = GuideMenu.Days(dayChoices())
        publish()
    }

    /** The day picker's choices: "Now", then today and the days after it; selected, "Now" on the live window, else its day. */
    fun dayChoices(): List<GuideDayChoice> {
        val today = localDay(nowSeconds() * 1000, utcOffset)
        val windowDay = localDay(windowStart * 1000, utcOffset)
        return listOf(GuideDayChoice(T.liveTv.now, null, opensAtNow)) +
            (today until today + GUIDE_PICKER_DAYS).map { GuideDayChoice(guideDayLabel(it, nowSeconds(), utcOffset), it, !opensAtNow && it == windowDay) }
    }

    /** A day picked: "Now" goes back to the live window; a day applies at once and offers its time slots. */
    fun pickDay(choice: GuideDayChoice) {
        val day = choice.epochDay
        if (day == null) {
            closeMenu()
            jumpToNow()
            return
        }
        setWindow(guideDayWindowStart(windowStart, day, utcOffset))
        menu = GuideMenu.Slots(day, choice.label.uppercase(), guideTimeSlots())
        publish()
    }

    /** A time slot picked on the slots menu: the window starts at its hour of that day. */
    fun pickSlot(slot: GuideTimeSlot) {
        val slots = menu as? GuideMenu.Slots ?: return
        pickSlot(slots.epochDay, slot)
    }

    /** A time slot of [epochDay] picked from its day's submenu (Apple TV): the window starts at its hour of that day. */
    fun pickSlot(epochDay: Long, slot: GuideTimeSlot) {
        closeMenu()
        setWindow(guideSlotWindowStart(epochDay, slot.hour, utcOffset))
    }

    /** The slots menu's back entry: the day picker again. */
    fun backToDays() = openDayMenu()

    /** The menu closed without a pick: a day picked before stays. */
    fun dismissMenu() = closeMenu()

    fun close() {
        scope.cancel()
        eventChannel.close()
    }

    private fun onKey(key: InputKey, phase: KeyPhase): Boolean {
        if (key == InputKey.SELECT && suppressSelectUntilUp) {
            if (phase == KeyPhase.UP) {
                suppressSelectUntilUp = false
                resetHold()
            }
            return true
        }
        if (key == InputKey.BACK || key == InputKey.ESCAPE) {
            if (phase == KeyPhase.UP) {
                if (focus.zone == GuideZone.GRID) {
                    focus = focus.copy(zone = GuideZone.TIME_NAV, timeNavItem = GuideTimeNavItem.DAY)
                    publish()
                } else {
                    emit(GuideEvent.Back)
                }
            }
            return true
        }
        if (isTv && key == InputKey.SELECT) {
            programTarget()?.let { (channel, program) ->
                val owner = focus.channelIndex
                val identity = guideAiringIdentity(channel, program)
                return holdSelect(
                    phase,
                    isOwnerActive = { programTarget()?.let { guideAiringIdentity(it.first, it.second) } == identity && focus.channelIndex == owner },
                    onPress = { activate(channel, program) },
                    onHold = { emit(GuideEvent.ShowDetails(channel, program)) },
                )
            }
            channelTarget()?.let { channel ->
                val owner = focus.channelIndex
                return holdSelect(
                    phase,
                    isOwnerActive = { channelTarget() != null && focus.channelIndex == owner },
                    onPress = { emit(GuideEvent.Tune(channel)) },
                    onHold = { openChannelMenu(owner) },
                )
            }
        }
        if (key == InputKey.MENU) {
            programTarget()?.let { (channel, program) ->
                if (phase == KeyPhase.UP) return false
                resetHold()
                emit(GuideEvent.ShowDetails(channel, program))
                return true
            }
            // Once per press: a held key's repeats land on the menu that opened.
            channelTarget()?.let {
                if (phase == KeyPhase.DOWN) openChannelMenu(focus.channelIndex)
                return true
            }
        }
        if (phase == KeyPhase.UP) return false
        return if (focus.zone == GuideZone.TIME_NAV) timeNavKey(key) else gridKey(key)
    }

    private fun timeNavKey(key: InputKey): Boolean {
        direction(key)?.let {
            move(it)
            return true
        }
        if (key != InputKey.SELECT) return false
        // The day picker opens on this key-down: its menu must not take the same press's key-up as a pick.
        selectTimeNav(focus.timeNavItem)
        return true
    }

    private fun gridKey(key: InputKey): Boolean {
        direction(key)?.let {
            move(it)
            return true
        }
        when (key) {
            InputKey.SELECT -> {
                val channel = channels.getOrNull(focus.channelIndex) ?: return true
                val program = focus.program
                if (focus.column == GuideColumn.CHANNEL) {
                    emit(GuideEvent.Tune(channel))
                } else if (program != null) {
                    activate(channel, program)
                }
                return true
            }
            InputKey.F -> {
                if (focus.column != GuideColumn.CHANNEL) return false
                toggleFavorite(focus.channelIndex)
                return true
            }
            else -> return false
        }
    }

    private fun move(direction: GuideDirection) {
        val result = guideMove(focus, direction, grid())
        focus = result.focus
        result.exit?.let(::emit)
        if (result.scrollToRow || result.scrollToProgram != null) {
            requestScroll(
                focus.channelIndex.takeIf { result.scrollToRow },
                result.scrollToProgram?.let { GuideHorizontalScroll.ToProgram(blockLeft(it)) },
            )
        }
        publish()
    }

    private fun holdSelect(phase: KeyPhase, isOwnerActive: () -> Boolean, onPress: () -> Unit, onHold: () -> Unit): Boolean {
        when (phase) {
            KeyPhase.DOWN -> if (!selectDown) {
                // Some platforms repeat a held key as more key-downs: only the first one starts the hold.
                selectDown = true
                holdJob?.cancel()
                holdJob = scope.launch {
                    delay(SELECT_HOLD_MILLIS)
                    holdJob = null
                    if (!isOwnerActive() || !selectDown) return@launch
                    resetHold()
                    suppressSelectUntilUp = true
                    onHold()
                }
            }
            KeyPhase.REPEAT -> Unit
            KeyPhase.UP -> {
                val pressed = holdJob != null && selectDown
                resetHold()
                if (pressed) onPress()
            }
        }
        return true
    }

    private fun resetHold() {
        holdJob?.cancel()
        holdJob = null
        selectDown = false
    }

    private fun activate(channel: LiveTvChannel, program: LiveTvProgram) {
        emit(if (isTv && program.isAiringAt(nowSeconds())) GuideEvent.Tune(channel) else GuideEvent.ShowDetails(channel, program))
    }

    private fun programTarget(): Pair<LiveTvChannel, LiveTvProgram>? {
        if (focus.zone != GuideZone.GRID || focus.column != GuideColumn.PROGRAM) return null
        val program = focus.program ?: return null
        return channels.getOrNull(focus.channelIndex)?.let { it to program }
    }

    private fun channelTarget(): LiveTvChannel? {
        if (focus.zone != GuideZone.GRID || focus.column != GuideColumn.CHANNEL) return null
        return channels.getOrNull(focus.channelIndex)
    }

    private fun closeMenu() {
        menu = null
        focusRequest++
        publish()
    }

    private fun shiftWindow(hours: Int) = setWindow(windowStart + hours * 3600L)

    private fun jumpToNow() {
        windowStart = guideNowWindowStart(nowSeconds(), utcOffset)
        nowWasInWindow = true
        opensAtNow = true
        rows = null
        load()
    }

    /** Moves the window to [start] and loads it. Now-anchored only when now falls in it. */
    private fun setWindow(start: Long) {
        windowStart = start
        nowWasInWindow = guideWindowContains(start, nowSeconds())
        opensAtNow = false
        rows = null
        load()
    }

    private fun load() {
        loadJob?.cancel()
        isLoading = true
        viewStart = null
        publish()
        val from = Instant.fromEpochSeconds(windowStart)
        val to = Instant.fromEpochSeconds(windowStart + GuideLayout.WINDOW_SECONDS)
        // Undispatched: the first server's request goes out now, so a load a later one supersedes was still asked for.
        // The job is in place before it runs, as a load answered at once may start the next one (a search jump).
        val job = SupervisorJob(scope.coroutineContext[Job])
        loadJob = job
        scope.launch(job, start = CoroutineStart.UNDISPATCHED) {
            val loaded = mutableListOf<LiveTvProgram>()
            val keys = HashSet<String>()
            servers.forEachLiveTvServer(
                onError = { _, entry, error -> Log.e(TAG, error) { "Failed to load programs from server ${entry.serverId.value}" } },
            ) { client, entry ->
                loaded += client.liveTv.fetchSchedule(from, to)
                addScheduledKeys(client, entry.serverId.value, keys)
            }
            commit(loaded, keys)
        }
        job.complete()
    }

    private fun commit(loaded: List<LiveTvProgram>, keys: Set<String>) {
        programs = loaded
        programsByScope = indexGuidePrograms(loaded, channels)
        scheduledKeys = keys
        recordingOverrides = emptyMap()
        isLoading = false
        hasLoadedOnce = true
        rows = null
        // A focused airing moves to the fresh list's copy of it, or, when the list lacks it, to what its row has on now.
        val focused = focus.program
        if (focus.zone == GuideZone.GRID && focus.column == GuideColumn.PROGRAM && focused != null) {
            val fresh = loaded.firstOrNull { it == focused }
            focus = if (fresh != null) {
                focus.copy(program = fresh)
            } else {
                val current = guideCurrentProgram(programsOf(focus.channelIndex), nowSeconds())
                focus.copy(column = if (current != null) GuideColumn.PROGRAM else GuideColumn.CHANNEL, program = current)
            }
        }
        // A search jump asked for during the load wins over the scroll to now and a focus request.
        val jump = pendingJump
        pendingJump = null
        if (jump != null) {
            pendingFocus = false
            publish()
            val (channel, program) = jump
            if (program != null) jumpToProgram(channel, program) else jumpToChannel(channel)
            return
        }
        if (opensAtNow) scrollToNow() else requestScroll(null, GuideHorizontalScroll.ToProgram(0.0))
        if (pendingFocus) focusContent() else publish()
    }

    private fun refreshScheduledKeys() {
        scheduledKeysJob?.cancel()
        scheduledKeysJob = scope.launch {
            val keys = HashSet<String>()
            servers.forEachLiveTvServer { client, entry -> addScheduledKeys(client, entry.serverId.value, keys) }
            scheduledKeys = keys
            rows = null
            publish()
        }
    }

    /** [client]'s scheduled recordings and its rules' grabs that still record; either failing is logged and skipped. */
    private suspend fun addScheduledKeys(client: MediaBackend, serverId: String, keys: MutableSet<String>) {
        val dvr = client.liveTvDvr ?: return
        try {
            dvr.fetchScheduledRecordings().forEach { keys += guideRecordingKeys(it, serverId) }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "Failed to load scheduled recordings for $serverId" }
        }
        try {
            dvr.fetchRecordingRules(includeGrabs = true, includeStorage = false).forEach { rule ->
                rule.grabOperations.forEach { keys += guideRecordingKeys(it, serverId) }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "Failed to load active recording grabs for $serverId" }
        }
    }

    /** Every minute: the now line moves, and a now-anchored window now has left moves to now. */
    private fun tick() {
        if (!isLoading && nowWasInWindow && !guideWindowContains(windowStart, nowSeconds())) {
            jumpToNow()
            return
        }
        rows = null
        publish()
    }

    /** Back on screen: the recordings again; a stale now-anchored window to now, else after a long absence the view. */
    private fun resumed() {
        refreshScheduledKeys()
        val hidden = hiddenSince
        hiddenSince = null
        // A load under way ends with a scroll to now.
        if (isLoading) return
        val nowSeconds = nowSeconds()
        val nowInWindow = guideWindowContains(windowStart, nowSeconds)
        if (nowWasInWindow && !nowInWindow) {
            jumpToNow()
        } else if (nowInWindow && hidden != null && nowSeconds - hidden >= REALIGN_AFTER_SECONDS) {
            scrollToNow()
            publish()
        }
    }

    private fun scrollToNow() = requestScroll(null, GuideHorizontalScroll.ToNow(guideOffsetAt(nowSeconds(), windowStart)))

    private fun requestScroll(channelIndex: Int?, horizontal: GuideHorizontalScroll?) {
        val id = (scroll?.id ?: 0) + 1
        scroll = GuideScroll(id, channelIndex?.let { guideRowTop(currentRows(), it) }, horizontal)
    }

    private fun emit(event: GuideEvent) {
        eventChannel.trySend(event)
    }

    private fun channelIndex(channel: LiveTvChannel): Int? = channels.indexOfFirst { it.scopeKey == channel.scopeKey }.takeIf { it >= 0 }

    private fun programsOf(channelIndex: Int): List<LiveTvProgram> =
        channels.getOrNull(channelIndex)?.let { programsByScope[it.scopeKey] }.orEmpty()

    /**
     * After the channel list changed, the focus follows the channel [focusedKey] it was on (or keeps its row, clamped,
     * when that channel left), and a focused airing stays only when that row has it, else what the row has on now.
     */
    private fun refocusChannel(focusedKey: String?) {
        val index = channels.indexOfFirst { it.scopeKey == focusedKey }.takeIf { it >= 0 }
            ?: focus.channelIndex.coerceAtMost(channels.lastIndex)
        val focused = focus.program
        focus = if (focus.column != GuideColumn.PROGRAM || focused == null || focused in programsOf(index)) {
            focus.copy(channelIndex = index)
        } else {
            val current = guideCurrentProgram(programsOf(index), nowSeconds())
            focus.copy(channelIndex = index, column = if (current != null) GuideColumn.PROGRAM else GuideColumn.CHANNEL, program = current)
        }
    }

    private fun grid(): GuideGrid = GuideGrid(
        channels = channels,
        displayOrder = currentRows().mapNotNull { (it as? GuideRow.Channel)?.channelIndex },
        windowStart = windowStart,
        viewTime = viewTime(nowSeconds()),
        programs = { programsByScope[it.scopeKey].orEmpty() },
    )

    private fun blockLeft(program: LiveTvProgram): Double {
        val end = windowStart + GuideLayout.WINDOW_SECONDS
        return guideOffsetAt((program.beginsAt ?: windowStart).coerceIn(windowStart, end), windowStart)
    }

    private fun nowSeconds(): Long = now().epochSeconds

    private fun currentRows(): List<GuideRow> = rows ?: buildRows().also { rows = it }

    private fun buildRows(): List<GuideRow> {
        val nowSeconds = nowSeconds()
        val indexByScope = HashMap<String, Int>()
        channels.forEachIndexed { index, channel -> indexByScope.getOrPut(channel.scopeKey) { index } }
        fun row(channel: LiveTvChannel): GuideRow.Channel = GuideRow.Channel(
            channel = channel,
            channelIndex = indexByScope[channel.scopeKey] ?: 0,
            isFavorite = channel.scopeKey in favoriteKeys,
            programs = programsByScope[channel.scopeKey].orEmpty().mapNotNull { cell(it, nowSeconds) },
        )
        if (groups.size <= 1) return channels.map(::row)
        return groups.flatMap { group -> listOf(GuideRow.SourceHeader(group.label)) + group.channels.map(::row) }
    }

    private fun cell(program: LiveTvProgram, nowSeconds: Long): GuideProgramCell? {
        val end = windowStart + GuideLayout.WINDOW_SECONDS
        val begins = (program.beginsAt ?: windowStart).coerceIn(windowStart, end)
        val ends = (program.endsAt ?: end).coerceIn(windowStart, end)
        if (ends <= begins) return null
        val left = guideOffsetAt(begins, windowStart)
        val show = program.grandparentTitle
        val season = program.parentIndex
        val episode = program.index
        val start = program.beginsAt?.let { clockTime(it, use24HourClock, utcOffset) }
        return GuideProgramCell(
            program = program,
            left = left,
            width = maxOf(guideOffsetAt(ends, windowStart) - left, GuideLayout.MIN_BLOCK_WIDTH),
            title = show ?: program.title,
            subtitle = show?.let { (if (season != null && episode != null) "S${season}E$episode · " else "") + program.title },
            timeText = start?.let { "$it · ${liveTvDuration(program.durationMinutes)}" },
            startText = start,
            isRecordingScheduled = guideIsRecordingScheduled(program, recordingOverrides, scheduledKeys),
            isPremiere = program.premiere == true,
            timing = when {
                program.endsAt.let { it != null && it < nowSeconds } -> GuideTiming.PAST
                program.isAiringAt(nowSeconds) -> GuideTiming.AIRING
                else -> GuideTiming.FUTURE
            },
        )
    }

    /**
     * The day pill's label and the time beside it: "Now" alone while the live window shows now; else the day and time of
     * the half hour nearest the view's start ([viewSlotStart]).
     */
    private fun labels(nowSeconds: Long): Pair<String, String?> {
        if (opensAtNow && showsNow(nowSeconds)) return T.liveTv.now to null
        val shown = viewSlotStart()
        return guideDayLabel(localDay(shown * 1000, utcOffset), nowSeconds, utcOffset) to clockTime(shown, use24HourClock, utcOffset)
    }

    /**
     * The start of the half hour nearest the view's start. Until the UI says what it shows, the window shows where it
     * opens: the live window now, any other its start.
     */
    private fun viewSlotStart(): Long {
        val lastSlot = (GuideLayout.WINDOW_SECONDS / GuideLayout.SLOT_SECONDS - 1).toInt()
        val slot = viewStart?.let { round(it / GuideLayout.SLOT_WIDTH).toInt().coerceIn(0, lastSlot) } ?: 0
        return windowStart + slot * GuideLayout.SLOT_SECONDS
    }

    /** Whether the view shows now; until the UI says what it shows, whether the window opens on now. */
    private fun showsNow(nowSeconds: Long): Boolean {
        val start = viewStart ?: return opensAtNow && guideWindowContains(windowStart, nowSeconds)
        return guideWindowContains(windowStart, nowSeconds) && guideOffsetAt(nowSeconds, windowStart) in start..start + viewWidth
    }

    /** The time in view: now while the view shows it, else the half hour nearest the view's start. */
    private fun viewTime(nowSeconds: Long): Long = if (showsNow(nowSeconds)) nowSeconds else viewSlotStart()

    private fun publish() {
        val nowSeconds = nowSeconds()
        val end = windowStart + GuideLayout.WINDOW_SECONDS
        // The live window names itself by its pick, "Now", while it shows now: it opens on now, an hour after its start,
        // which may be the day before (11:00 PM on a guide opened at 12:15 AM).
        val (dayLabel, timeLabel) = labels(nowSeconds)
        mutableState.value = GuideUiState(
            windowStart = windowStart,
            now = nowSeconds,
            dayLabel = dayLabel,
            timeLabel = timeLabel,
            timeMarks = guideTimeMarks(windowStart, use24HourClock, utcOffset),
            rows = currentRows(),
            // The line moves by whole minutes.
            nowOffset = if (nowSeconds < windowStart || nowSeconds > end) null else guideOffsetAt(windowStart + (nowSeconds - windowStart) / 60 * 60, windowStart),
            isLoading = isLoading,
            hasLoadedOnce = hasLoadedOnce,
            focus = focus,
            hasFocus = hasFocus,
            menu = menu,
            channelMenu = channelMenu,
            scroll = scroll,
            focusRequest = focusRequest,
        )
    }

    private fun direction(key: InputKey): GuideDirection? = when (key) {
        InputKey.UP -> GuideDirection.UP
        InputKey.DOWN -> GuideDirection.DOWN
        InputKey.LEFT -> GuideDirection.LEFT
        InputKey.RIGHT -> GuideDirection.RIGHT
        else -> null
    }

    private enum class KeyPhase { DOWN, REPEAT, UP }

    private companion object {
        const val TAG = "LiveTvGuide"
        const val SELECT_HOLD_MILLIS = 500L

        /** How long the guide must have been away before coming back scrolls it to now. */
        const val REALIGN_AFTER_SECONDS = 30 * 60L
    }
}
