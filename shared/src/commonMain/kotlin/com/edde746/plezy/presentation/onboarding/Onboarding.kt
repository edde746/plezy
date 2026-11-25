package com.edde746.plezy.presentation.onboarding

import com.edde746.plezy.app.BrowserMode
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.BootRoute
import kotlinx.coroutines.CompletableDeferred

/**
 * Where the sign-in, profile and connection screens lead ([AccountsHost]), over the app's [navigator].
 *
 * The sign-in ([Route.SignIn]) and the required profile picker take the shown stack alone, without the chrome, until
 * the app is entered: then the destination the stack belongs to shows at its root. Added from inside the app (Settings,
 * the picker, a profile), a connection's flow closes back to the screen it was opened from.
 *
 * @param openUrlAs opens a web link as a mode asks ([com.edde746.plezy.app.AppPlatform.openUrl]); [closeInAppBrowser]
 *   closes the in-app view it showed ([com.edde746.plezy.app.AppPlatform.closeInAppBrowser]).
 * @param exitApp leaves the app (back on a required picker or the sign-in).
 */
class Onboarding(
    private val navigator: PlezyNavigator,
    private val openUrlAs: (String, BrowserMode) -> Boolean,
    private val closeInAppBrowser: () -> Unit,
    private val exitApp: () -> Unit,
    private val isTv: () -> Boolean,
    private val activeProfileId: () -> String? = { null },
) : AccountsHost {
    /** Asks for profile PINs: the picker's, a profile's own and the binder's ([com.edde746.plezy.profiles.ProfileServices.pinPrompt]). */
    val pin = PinPrompter()

    /** The sign-in says the device's accounts were lost (Apple TV purged its data) until an account is added. */
    var recoveryRequired: Boolean = false
        private set

    private var pendingPick: CompletableDeferred<Boolean>? = null

    /** The borrow [borrowInto] waits for, and its route: leaving that route without a borrow declines it. */
    private var pendingBorrow: Pair<Route.BorrowConnection, CompletableDeferred<Boolean>>? = null

    init {
        navigator.addRemovalListener { route ->
            // Leaving the picker a pick waits for (its Back) declines the pick.
            if (route == Route.ProfilePicker(required = true)) {
                pendingPick?.complete(false)
                pendingPick = null
            }
            val (waiting, result) = pendingBorrow ?: return@addRemovalListener
            if (route != waiting) return@addRemovalListener
            pendingBorrow = null
            result.complete(false)
        }
    }

    override val tv: Boolean get() = isTv()

    /** Shows the sign-in or the required picker for [entry]; [BootRoute.MAIN] leaves the app as it is. */
    fun enter(entry: BootRoute, recoveryRequired: Boolean) {
        this.recoveryRequired = recoveryRequired
        when (entry) {
            BootRoute.SIGN_IN -> navigator.replaceStack(listOf(Route.SignIn))
            BootRoute.PICK_PROFILE -> navigator.replaceStack(listOf(Route.ProfilePicker(required = true)))
            BootRoute.MAIN -> Unit
        }
    }

    /** The sign-in or the required picker is the bottom of the shown stack: the app isn't entered yet. */
    val gated: Boolean get() = navigator.backStack.value.first().let { it == Route.SignIn || it == Route.ProfilePicker(required = true) }

    override fun open(route: Route) = navigator.navigate(route)

    /** Settings' Add connection: for the profile active now, so Borrow is offered and a Plex account attaches to it. */
    fun addConnection() = navigator.navigate(Route.AddConnection(activeProfileId()))

    override fun back() {
        navigator.back()
    }

    override fun connectionAdded(from: Route, pickProfile: Boolean) {
        pendingBorrow?.let { (waiting, result) ->
            if (from != waiting) return@let
            // The flow that waits for this borrow closes itself once it has handled it.
            pendingBorrow = null
            result.complete(true)
            return
        }
        recoveryRequired = false
        val stack = navigator.backStack.value
        when {
            stack.first() == Route.SignIn ->
                if (pickProfile) navigator.replaceStack(listOf(Route.ProfilePicker(required = true))) else enterApp()
            else -> {
                val start = stack.indexOfFirst { it.isAddFlow }.takeIf { it > 0 } ?: stack.indexOf(from).coerceAtLeast(1)
                navigator.replaceStack(stack.take(start))
            }
        }
    }

    override fun profileChosen(from: Route) {
        pendingPick?.let {
            pendingPick = null
            it.complete(true)
        }
        // A picker at the root of the stack (the boot's, or one a stack switch left there) has nothing under it to pop to.
        if (navigator.backStack.value.first() == from) enterApp() else navigator.pop(from)
    }

    override fun leavePicker(from: Route) {
        pendingPick?.let {
            pendingPick = null
            it.complete(false)
            navigator.pop(from)
            return
        }
        if (from == Route.ProfilePicker(required = true) && navigator.backStack.value.first() == from) exitApp() else navigator.pop(from)
    }

    override fun signedOut() {
        navigator.replaceStack(listOf(Route.SignIn))
    }

    override fun pickRequired() {
        navigator.replaceStack(listOf(Route.ProfilePicker(required = true)))
    }

    override suspend fun pickProfile(): Boolean {
        pendingPick?.complete(false)
        val pick = CompletableDeferred<Boolean>()
        pendingPick = pick
        navigator.navigate(Route.ProfilePicker(required = true))
        return pick.await()
    }

    override suspend fun borrowInto(profileId: String): Boolean {
        pendingBorrow?.second?.complete(false)
        val route = Route.BorrowConnection(profileId)
        val result = CompletableDeferred<Boolean>()
        pendingBorrow = route to result
        navigator.navigate(route)
        return result.await()
    }

    override fun openUrl(url: String, mode: BrowserMode): Boolean = openUrlAs(url, mode)

    override fun closeBrowser() = closeInAppBrowser()

    override fun exit() = exitApp()

    private fun enterApp() {
        navigator.select(navigator.stacks.value.shown)
    }
}

/** A route of a flow that adds a connection: it closes, with the screens over it, once the connection is added. */
private val Route.isAddFlow: Boolean
    get() = this is Route.AddConnection || this is Route.AddPlexAccount || this is Route.AddMediaBrowser ||
        this is Route.AddProfile || this is Route.BorrowConnection

/** What the account screens' stores ask of the app ([Onboarding] in the product). Main thread only. */
interface AccountsHost {
    /** The TV layout: QR sign-in first, Quick Connect started by itself. */
    val tv: Boolean

    fun open(route: Route)

    fun back()

    /**
     * A connection was added from [from]'s flow. On the sign-in the app is entered (the picker first when
     * [pickProfile]); inside the app the flow closes.
     */
    fun connectionAdded(from: Route, pickProfile: Boolean)

    /** The picker at [from] made a profile active. */
    fun profileChosen(from: Route)

    /** Back on the picker at [from]: a required one at the bottom leaves the app. */
    fun leavePicker(from: Route)

    /** Nothing is left to use: back to the sign-in. */
    fun signedOut()

    /** Profiles are left but none is active: the required picker. */
    fun pickRequired()

    /** Opens the required picker over the current screen and waits: true once a profile was made active. */
    suspend fun pickProfile(): Boolean

    /**
     * Opens the borrow screen for profile [profileId] over the current screen and waits: true once a connection was
     * borrowed (the screen stays until the caller closes its flow), false when the user left it without one.
     */
    suspend fun borrowInto(profileId: String): Boolean

    /**
     * Opens the web [url] as [mode] asks: over the app ([BrowserMode.IN_APP_WEB_VIEW], [BrowserMode.IN_APP_BROWSER])
     * or outside it; false when it didn't open so (the device has no such view, or nothing took the link).
     */
    fun openUrl(url: String, mode: BrowserMode): Boolean

    /** Closes the in-app view [openUrl] showed, if it still shows; nothing otherwise. */
    fun closeBrowser()

    fun exit()
}
