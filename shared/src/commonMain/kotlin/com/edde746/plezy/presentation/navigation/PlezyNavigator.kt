package com.edde746.plezy.presentation.navigation

import com.edde746.plezy.model.buildGlobalKey
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map

/**
 * The app's back stacks, one per top-level destination ([stacks]), the shown one ([backStack]; each UI renders it in its
 * own navigation container, with the top entry as a sheet where [layout] says so), and what lives as long as their
 * entries. Stores never see this: their host interfaces call the app, which calls these. Main thread only.
 *
 * - A destination's stack has the destination's route at its bottom and exists from the first time the destination
 *   shows. Picking another destination in the chrome ([pick]) shows its stack as it was left; picking the shown one
 *   pops its stack to its root, and picking it at its root is a reselection ([reselected]). A screen opens on the
 *   shown stack ([navigate]), and is on one stack at a time, once:
 *   opened while the shown stack holds it, the stack pops back to it; opened while another destination's stack holds
 *   it, it leaves that stack and opens anew. A destination's route is never pushed: opening it shows its stack
 *   ([navigate], [select]).
 * - The player and a sheet ([RoutePresentation.SHEET]) are only ever on the shown stack: showing another destination
 *   takes them, and whatever lies over them, off the stack left (the player's route leaving ends the playback). Closing
 *   the player returns to the screen under it, on the stack it opened on.
 * - Back ([back]) pops the shown stack; at the root of a destination other than the [first] one it shows the first's
 *   stack (Home's, or Downloads' offline: the shell sets [first] to the first destination it shows).
 * - [retain] keeps an object (a screen's store) for as long as its route is on any stack, across the screen leaving
 *   the view hierarchy while another screen or destination is shown, and releases it once the route has left every
 *   stack. A route on no stack gets nothing. A destination's route stays at the bottom of its stack until [close] (the
 *   session ends), so a destination shown again finds its screens as they were.
 * - A sheet is only ever the top entry: whatever opens next replaces it ([navigate]).
 *
 * @param start the stacks to start on ([NavigationStacks.of] of one first screen).
 */
class PlezyNavigator(start: NavigationStacks) {
    /** Starts on [start] alone ([NavigationStacks.of]). */
    constructor(start: Route) : this(NavigationStacks.of(start))

    private val state = MutableStateFlow(start)
    private val shownStack = MutableStateFlow(start.current)

    /** Every destination's stack and the one shown. */
    val stacks: StateFlow<NavigationStacks> = state.asStateFlow()

    /** The shown destination's stack, bottom to top; never empty. */
    val backStack: StateFlow<List<Route>> = shownStack.asStateFlow()

    /** The top screen. */
    val current: Route get() = shownStack.value.last()

    /** The destination [back] returns to from another's root: the first the chrome shows. */
    var first: TopLevelDestination = TopLevelDestination.HOME

    /** The shown stack as the UIs draw it: the screens and the sheet over them ([BackStackLayout.of] of [backStack]). */
    val layout: BackStackLayout get() = BackStackLayout.of(shownStack.value)

    private val retained = HashMap<Route, MutableMap<String, Retained<*>>>()
    private val removalListeners = mutableListOf<(Route) -> Unit>()
    private val mutableReselected = MutableSharedFlow<TopLevelDestination>(extraBufferCapacity = 1, onBufferOverflow = BufferOverflow.DROP_OLDEST)

    /**
     * A destination the user picked ([pick]) while it showed at its root: the stacks stay as they are, and the
     * destination's screen does what a reselection does (Home refreshes).
     */
    val reselected: SharedFlow<TopLevelDestination> = mutableReselected.asSharedFlow()

    /**
     * Opens [route] on top of the shown stack; already on it, the stack pops back to it (a screen is on a stack once, its
     * kept objects and saved state its own: Detail A → More like this B → More like this A returns to A). A sheet on top
     * ([layout]) closes first: [route] replaces it, or, when [route] is the screen under the sheet, closing the sheet is
     * all it does. A destination's route shows its stack as it was left. A screen is on one destination's stack at a
     * time: [route] on another's leaves it, with the screens over it, and opens anew, its kept objects made again.
     */
    fun navigate(route: Route) {
        TopLevelDestination.of(route)?.let { return show(it) }
        val stacks = state.value
        val current = stacks.current
        val base = if (layout.sheet != null) current.dropLast(1) else current
        val next = base.opened(route)
        if (next == current) return
        val left = stacks.stacks.filter { (destination, stack) -> destination != stacks.shown && route in stack }
            .mapValues { (destination, stack) -> stack.take(stack.indexOf(route)).ifEmpty { listOf(destination.route) } }
        if (left.isNotEmpty()) retained.remove(route)?.values?.forEach { it.release() }
        // A title opened from a card is placed in the library it was opened under.
        val library = (route as? Route.MediaDetail)?.let { detail -> detail.seed?.libraryId?.let { buildGlobalKey(detail.serverId, it) } }
        commit(NavigationStacks(stacks.shown, stacks.stacks + left + (stacks.shown to next), library?.let { mapOf<Route, String>(route to it) }.orEmpty()))
    }

    /**
     * Places [route], while it is on a stack, in the library [libraryKey] (a global key) unless its library is known
     * already: the one an item was opened under wins over the one its screen finds it belongs to.
     */
    fun placeIn(route: Route, libraryKey: String) {
        val stacks = state.value
        if (route !in stacks || route in stacks.libraries) return
        state.value = stacks.copy(libraries = stacks.libraries + (route to libraryKey))
    }

    /**
     * Pops the shown stack's top screen; at the root of a destination other than [first], shows [first]'s stack as it
     * was left. False (and nothing changes) at [first]'s root.
     */
    fun back(): Boolean {
        val shown = state.value
        when {
            shown.current.size > 1 -> change(shown.current.dropLast(1))
            shown.shown != first -> show(first)
            else -> return false
        }
        return true
    }

    /** Replaces the shown stack's top screen with [route]; with [route] under it, the stack pops back to it ([navigate]). */
    fun replace(route: Route) = change(shownStack.value.dropLast(1).opened(route))

    /**
     * Replaces the shown stack with [routes] (not empty): the sign-in and the required profile picker take the whole
     * stack, without the chrome, until the app is entered ([select]).
     */
    fun replaceStack(routes: List<Route>) {
        require(routes.isNotEmpty()) { "A stack needs a screen" }
        change(routes)
    }

    /** Pops [route] (and anything above it) off the shown stack; false when it isn't on it or is its root. */
    fun pop(route: Route): Boolean {
        val stack = shownStack.value
        val index = stack.lastIndexOf(route)
        if (index <= 0) return false
        change(stack.take(index))
        return true
    }

    /**
     * Takes [route] alone off every stack it is on, leaving the screens over it where they are (a screen whose content
     * went away closes itself without closing the one above it); a stack's root stays. False when it was on none.
     */
    fun remove(route: Route): Boolean {
        val stacks = state.value
        val next = stacks.stacks.mapValues { (_, stack) -> if (stack.indexOf(route) > 0) stack - route else stack }
        if (next == stacks.stacks) return false
        commit(NavigationStacks(stacks.shown, next))
        return true
    }

    /**
     * Whether [route] is out of view, as the stacks change: a screen lies over it on the shown stack (the player,
     * another screen opened from it; a sheet doesn't hide it), or it is on another destination's stack only. False while
     * [route] is on no stack.
     */
    fun covered(route: Route): Flow<Boolean> = state.map { stacks ->
        val shown = stacks.current
        val index = shown.lastIndexOf(route)
        if (index < 0) route in stacks else shown.subList(index + 1, shown.size).any { it.presentation == RoutePresentation.SCREEN }
    }.distinctUntilChanged()

    /**
     * Shows [destination] at its root: its stack popped to the destination's route, with [screen] over it in the same
     * change. A link or another screen opening a destination does this; the chrome [pick]s.
     */
    fun select(destination: TopLevelDestination, screen: Route? = null) =
        show(destination, listOf(destination.route) + listOfNotNull(screen))

    /**
     * The user picked [destination] in the app's navigation (the tab bar, the sidebar, the rail, the Mac's and iPad's
     * menus): another destination shows its stack as it was left, the shown one pops its stack to its root; the shown
     * one at its root already is [reselected].
     */
    fun pick(destination: TopLevelDestination) {
        val shown = state.value
        if (destination != shown.shown) return show(destination)
        if (shown.current == listOf(destination.route)) mutableReselected.tryEmit(destination) else show(destination, listOf(destination.route))
    }

    /**
     * The object kept for [route] under [key]: created by [create] on first use, released by [release] once the route
     * has left every stack, which for a destination's route is at [close]: a destination shown again finds its store as
     * it was. Null while a route other than a destination's is on no stack: a popped route's screen still draws while
     * it animates out, and the navigation container can even compose it for the first time then; an object made for it
     * would outlive the route, over what the navigator no longer keeps for it. A destination's route gets its object
     * before it first shows (the side rail's Libraries section lists the libraries from Home). A screen calls it once per
     * appearance of its route (Compose: `remember(route) { … }`), so the one it got keeps drawing while it animates out,
     * and draws nothing when it got none.
     */
    fun <S : Any> retain(route: Route, key: String, create: () -> S, release: (S) -> Unit): S? {
        if (route !in state.value && TopLevelDestination.entries.none { it.route == route }) return null
        val forRoute = retained.getOrPut(route) { HashMap() }
        @Suppress("UNCHECKED_CAST")
        (forRoute[key] as Retained<S>?)?.let { return it.value }
        return create().also { forRoute[key] = Retained(it, release) }
    }

    /** What [retain] keeps for [route] under [key], if anything (diagnostics and test reports). */
    fun retained(route: Route, key: String): Any? = retained[route]?.get(key)?.value

    /** Calls [listener] with every route that leaves the last stack it was on. */
    fun addRemovalListener(listener: (Route) -> Unit) {
        removalListeners += listener
    }

    /** Stops calling [listener] ([addRemovalListener]). */
    fun removeRemovalListener(listener: (Route) -> Unit) {
        removalListeners -= listener
    }

    /**
     * Starts the screens anew (the active profile changed): every destination's stack goes back to its root, the shown
     * destination's keeping the routes [keep] takes (the profile picker that is switching, the player of a video no
     * profile played), and everything kept for the other routes is released, the destinations' own included, so each
     * screen is made again when the UIs draw it.
     */
    fun restart(keep: (Route) -> Boolean) {
        val before = state.value
        val stacks = before.stacks.mapValues { (destination, stack) ->
            if (destination == before.shown) listOf(stack.first()) + stack.drop(1).filter(keep) else listOf(stack.first())
        }
        for (route in retained.keys.filter { !keep(it) }) retained.remove(route)?.values?.forEach { it.release() }
        commit(NavigationStacks(before.shown, stacks))
    }

    /** Releases everything retained; the navigator is done. */
    fun close() {
        val all = retained.values.flatMap { it.values }
        retained.clear()
        all.forEach { it.release() }
    }

    /** Replaces the shown stack with [next]. */
    private fun change(next: List<Route>) {
        val stacks = state.value
        commit(NavigationStacks(stacks.shown, stacks.stacks + (stacks.shown to next)))
    }

    /**
     * Shows [destination]'s stack: [stack] when given, else as it was left (its route alone the first time). The stack
     * left keeps what lies under its player or sheet.
     */
    private fun show(destination: TopLevelDestination, stack: List<Route>? = null) {
        val before = state.value
        val stacks = before.stacks.toMutableMap()
        if (destination != before.shown) {
            val left = before.current
            val transient = left.indexOfFirst { it == Route.Player || it.presentation == RoutePresentation.SHEET }
            if (transient > 0) stacks[before.shown] = left.take(transient)
        }
        stacks[destination] = stack ?: stacks[destination] ?: listOf(destination.route)
        commit(NavigationStacks(destination, stacks))
    }

    /**
     * Sets the stacks to [change], whose [NavigationStacks.libraries] add to the routes' known ones (those of routes that
     * left every stack go), then releases and reports what left them all.
     */
    private fun commit(change: NavigationStacks) {
        val before = state.value
        val live = change.routes
        val next = change.copy(libraries = (before.libraries + change.libraries).filterKeys { it in live })
        if (next == before) return
        state.value = next
        shownStack.value = next.current
        val gone = before.routes - live
        // A destination's own object stays until [close] or [restart], shown or not: the side rail's Libraries section
        // holds the Libraries store from the launch, whatever opens meanwhile.
        for (route in retained.keys.filter { it !in live && TopLevelDestination.entries.none { d -> d.route == it } }) {
            retained.remove(route)?.values?.forEach { it.release() }
        }
        for (route in gone) removalListeners.toList().forEach { it(route) }
    }

    private class Retained<S : Any>(val value: S, private val onRelease: (S) -> Unit) {
        fun release() = onRelease(value)
    }

    private companion object {
        /** This stack with [route] on top: pushed, or popped back to where it is (a route is on a stack once). */
        fun List<Route>.opened(route: Route): List<Route> = indexOf(route).let { if (it < 0) this + route else take(it + 1) }
    }
}

/**
 * The back stack of each top-level destination shown so far, bottom to top, and the [shown] one
 * ([PlezyNavigator.stacks]). A destination's stack has its route at the bottom; a development session started on
 * another screen has that screen at the bottom of Home's until Home is picked while it shows. [libraries] holds the
 * library (its global key) of each screen on the stacks whose library is known: the one a title was opened under, else
 * the one its screen found it in ([PlezyNavigator.placeIn]); the navigation highlights it
 * ([TopLevelDestination.Companion.highlightedLibrary]).
 */
data class NavigationStacks(
    val shown: TopLevelDestination,
    val stacks: Map<TopLevelDestination, List<Route>>,
    val libraries: Map<Route, String> = emptyMap(),
) {
    /** [destination]'s stack; null until the destination first shows. */
    fun stack(destination: TopLevelDestination): List<Route>? = stacks[destination]

    /** The shown destination's stack. */
    val current: List<Route> get() = stacks.getValue(shown)

    /**
     * The destinations whose screens the chrome keeps drawn: each one shown so far that the chrome still shows, in
     * [visible]'s order, and [shown] always. A destination mounts the first time it shows and stays mounted (its scroll
     * positions, focus and other view state kept) while another shows; only [shown]'s screens are active, the rest
     * hidden, without focus, input or running timers.
     */
    fun mounted(visible: List<TopLevelDestination>): List<TopLevelDestination> =
        visible.filter { it in stacks }.let { if (shown in it) it else it + shown }

    /**
     * The stack [route] is on, for its screen: the shown one when it holds [route], else another destination's (whose
     * screens stay drawn while another destination shows); null when none does.
     */
    fun stackOf(route: Route): List<Route>? = current.takeIf { route in it } ?: stacks.values.firstOrNull { route in it }

    /** Every route on a stack. */
    internal val routes: Set<Route> get() = stacks.values.flatMapTo(HashSet()) { it }

    /** [route] is on a stack. */
    operator fun contains(route: Route): Boolean = stacks.values.any { route in it }

    companion object {
        /**
         * [start] alone, shown: a destination's route as that destination's stack; any other (a development session's
         * first screen) as the bottom of Home's until Home is picked while it shows, which pops it to Home.
         */
        fun of(start: Route): NavigationStacks =
            (TopLevelDestination.of(start) ?: TopLevelDestination.HOME).let { NavigationStacks(it, mapOf(it to listOf(start))) }
    }
}
