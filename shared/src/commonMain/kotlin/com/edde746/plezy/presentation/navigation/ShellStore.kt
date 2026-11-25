package com.edde746.plezy.presentation.navigation

import com.edde746.plezy.servers.childScope
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.seconds

/** What decides which destinations show ([NavigationTabs.visible]) and whether Live TV opens, as it changes. */
data class ShellAvailability(
    val offline: Boolean,
    /** A connected server has live TV. */
    val hasLiveTv: Boolean,
    /** A catalog source is connected and the Explore tab is on. */
    val hasExplore: Boolean,
)

/** The app's navigation chrome: the destinations it shows and the one selected ([ShellStore]). */
data class ShellUiState(
    /** The bar's, rail's and sidebar's destinations, in order. */
    val destinations: List<TopLevelDestination>,
    val selected: TopLevelDestination,
    val offline: Boolean,
    /** Live TV opens ([ShellStore.openLiveTv]): a connected server has it, online. Home offers its shortcut. */
    val liveTv: Boolean,
    /** "Press back again to exit" shows: a second back now exits ([ShellStore.back]). */
    val exitPrompt: Boolean,
)

/** What [ShellStore.back] did. */
enum class ShellBack {
    /** Popped the shown destination's stack. */
    POPPED,

    /** Showed the first destination, from another's root. */
    FIRST_DESTINATION,

    /** At the first destination's root: armed the exit; the prompt shows ([ShellUiState.exitPrompt]). */
    EXIT_PROMPT,

    /** A second back while the prompt showed: the app exits. */
    EXIT,

    /** The Apple TV at the first destination's root: the system takes back (to the Apple TV's home), unprompted. */
    SYSTEM,
}

/**
 * The navigation chrome's rules over the [navigator]: which destinations show as servers, catalog sources and the
 * network come and go ([availability]), where the app starts, tab selection and back at a destination's root. Main
 * thread only; [close] when the app goes.
 *
 * - Start: [NavigationTabs.startup] with the [preferred] start (the startup section setting); offline the first
 *   destination that shows (Libraries, on its downloads). A preferred Explore that doesn't show yet, or Live TV before a
 *   server has it, starts on the first destination and opens once it shows, unless the user picked a destination first.
 * - Going offline remembers the destination shown and, when it no longer shows, switches to the first that shows
 *   (Libraries). Coming back online returns to the remembered one when the switch was automatic; picking a destination
 *   while offline cancels that. A destination that stops showing (Explore gone) gives way to the first; Live TV gone
 *   leaves Home's stack.
 * - [select] ignores a destination that doesn't show.
 * - [back]: pops the shown stack; at another destination's root shows the first; at the first's root arms the exit for
 *   3 s, and a second back in that window exits. On the Apple TV the system takes that back instead.
 */
class ShellStore(
    private val navigator: PlezyNavigator,
    private val availability: StateFlow<ShellAvailability>,
    preferred: Startup?,
    private val appleTv: Boolean,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private var visible = visibleFor(availability.value)
    private var offline = availability.value.offline
    private var hasLiveTv = availability.value.hasLiveTv

    /** Explore or Live TV, preferred at the start but not shown yet: opened once it can be. */
    private var pending: Startup? = null

    /** The destination shown when the app went offline, and whether going offline switched away from it. */
    private var lastOnline: TopLevelDestination? = null
    private var autoSwitched = false

    private var exitWindow: Job? = null

    private val mutableState: MutableStateFlow<ShellUiState>
    val state: StateFlow<ShellUiState>

    init {
        navigator.first = visible.first()
        val start = NavigationTabs.startup(visible, preferred?.destination.takeIf { !offline })
        when {
            offline || preferred == null -> show(start)
            !opens(preferred) -> {
                pending = preferred
                show(start)
            }
            else -> open(preferred)
        }
        mutableState = MutableStateFlow(build())
        state = mutableState.asStateFlow()
        scope.launch { availability.drop(1).collect(::changed) }
        scope.launch { navigator.stacks.collect { publish() } }
    }

    /** The user picked [destination] in the chrome; ignored unless it shows. */
    fun select(destination: TopLevelDestination) {
        if (destination !in visible) return
        picked()
        navigator.pick(destination)
    }

    /**
     * The user picked the library [globalKey] in the chrome (a sidebar's library row, Home's library shortcut), which
     * shows Libraries with it selected; [standsFor] is the library Libraries' stack stands for now
     * ([TopLevelDestination.Companion.highlightedLibrary] over it). Libraries shows its stack as it was left only while
     * that stands for the library picked; else at its root, so a title left open under another library doesn't come back
     * in the picked one's place. Ignored unless Libraries shows.
     */
    fun selectLibrary(globalKey: String, standsFor: String?) {
        val libraries = TopLevelDestination.LIBRARIES
        if (standsFor == globalKey || navigator.stacks.value.shown == libraries) return select(libraries)
        if (libraries !in visible) return
        picked()
        navigator.select(libraries)
    }

    /** A destination picked: the start's pending one, an offline switch's return and the armed exit are dropped. */
    private fun picked() {
        pending = null
        if (offline) autoSwitched = false
        disarmExit()
    }

    /**
     * Whether the first destination's root shows, where [back] arms the exit. A desktop keyboard's Escape (outside TV
     * mode) never does that: there it only takes the window out of fullscreen.
     */
    val atFirstRoot: Boolean
        get() = navigator.backStack.value.size == 1 && navigator.stacks.value.shown == visible.first()

    /** Opens Live TV over Home (Home's shortcut, a link); ignored while it can't open ([ShellUiState.liveTv]). */
    fun openLiveTv() {
        if (!opens(Startup.LIVE_TV)) return
        pending = null
        open(Startup.LIVE_TV)
    }

    /** Opens Libraries on [section] (Home's Downloads shortcut, a remote's Downloads tab); ignored while it doesn't show. */
    fun openLibrary(section: LibrarySection) {
        if (TopLevelDestination.LIBRARIES !in visible) return
        pending = null
        if (offline) autoSwitched = false
        open(Startup(TopLevelDestination.LIBRARIES, section = section))
    }

    /** Back, from the chrome's or the system's back ([ShellBack] says what it did). */
    fun back(): ShellBack {
        when {
            navigator.backStack.value.size > 1 -> {
                navigator.back()
                return ShellBack.POPPED
            }
            navigator.stacks.value.shown != visible.first() -> {
                disarmExit()
                navigator.pick(visible.first())
                return ShellBack.FIRST_DESTINATION
            }
            appleTv -> return ShellBack.SYSTEM
            exitWindow?.isActive == true -> {
                disarmExit()
                return ShellBack.EXIT
            }
            else -> {
                exitWindow = scope.launch {
                    delay(EXIT_WINDOW)
                    exitWindow = null
                    publish()
                }
                publish()
                return ShellBack.EXIT_PROMPT
            }
        }
    }

    fun close() {
        scope.cancel()
    }

    private fun changed(next: ShellAvailability) {
        val wasOffline = offline
        offline = next.offline
        hasLiveTv = next.hasLiveTv
        visible = visibleFor(next)
        navigator.first = visible.first()
        val shown = navigator.stacks.value.shown
        // The sign-in or the required picker holds the shown stack until the app is entered: switching away would leave
        // it there, out of sight, to show again once the device is back online.
        val gated = navigator.backStack.value.first().let { it == Route.SignIn || it == Route.ProfilePicker(required = true) }
        when {
            gated -> Unit
            offline && !wasOffline -> {
                lastOnline = shown
                if (shown !in visible) {
                    autoSwitched = true
                    show(visible.first())
                }
            }
            !offline && wasOffline && autoSwitched -> {
                autoSwitched = false
                show(lastOnline?.takeIf { it in visible } ?: visible.first())
            }
            shown !in visible -> show(visible.first())
        }
        if (!hasLiveTv) navigator.remove(Route.LiveTv)
        pending?.takeIf(::opens)?.let {
            pending = null
            open(it)
        }
        publish()
    }

    /** [start] can open now: online, its destination shows, and Live TV has a server. */
    private fun opens(start: Startup) =
        !offline && start.destination in visible && (start.screen != Route.LiveTv || hasLiveTv)

    private fun open(start: Startup) {
        disarmExit()
        when {
            start.section != null -> navigator.openLibrary(start.section)
            start.screen != null -> navigator.select(start.destination, start.screen)
            else -> show(start.destination)
        }
    }

    private fun show(destination: TopLevelDestination) {
        disarmExit()
        if (navigator.stacks.value.shown != destination) navigator.pick(destination)
    }

    private fun disarmExit() {
        exitWindow?.cancel()
        exitWindow = null
    }

    private fun visibleFor(availability: ShellAvailability) =
        NavigationTabs.visible(availability.offline, availability.hasExplore, appleTv)

    private fun build() = ShellUiState(
        destinations = visible,
        selected = navigator.stacks.value.shown,
        offline = offline,
        liveTv = !offline && hasLiveTv,
        exitPrompt = exitWindow != null,
    )

    private fun publish() {
        mutableState.value = build()
    }

    private companion object {
        val EXIT_WINDOW = 3.seconds
    }
}
