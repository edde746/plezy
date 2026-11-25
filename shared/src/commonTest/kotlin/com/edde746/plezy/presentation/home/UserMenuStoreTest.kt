package com.edde746.plezy.presentation.home

import com.edde746.plezy.app.BrowserMode
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.onboarding.AccountsHost
import com.edde746.plezy.presentation.onboarding.PinPrompter
import com.edde746.plezy.profiles.MediaBrowserAddResult
import com.edde746.plezy.profiles.ProfileHarness
import com.edde746.plezy.profiles.jellyfin
import com.edde746.plezy.profiles.profileTest
import com.edde746.plezy.strings.T
import com.edde746.plezy.trackers.TrackerService
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

private class MenuHost : AccountsHost {
    val opened = mutableListOf<Route>()
    var signedOut = 0
    override val tv: Boolean = false
    override fun open(route: Route) {
        opened += route
    }
    override fun back() = Unit
    override fun connectionAdded(from: Route, pickProfile: Boolean) = Unit
    override fun profileChosen(from: Route) = Unit
    override fun leavePicker(from: Route) = Unit
    override fun signedOut() {
        signedOut++
    }
    override fun pickRequired() = Unit
    override suspend fun pickProfile(): Boolean = false
    override suspend fun borrowInto(profileId: String): Boolean = false
    override fun openUrl(url: String, mode: BrowserMode): Boolean = false
    override fun closeBrowser() = Unit
    override fun exit() = Unit
}

class UserMenuStoreTest {
    private class Menu(val store: UserMenuStore, val pins: PinPrompter, val host: MenuHost, val settings: MutableList<Unit>)

    /** The active profile "User user-a", then "Kids" (PIN 1234) and "Guest", each with a server. */
    private suspend fun TestScope.menu(h: ProfileHarness): Menu {
        h.services.start()
        h.store(jellyfin())
        assertIs<MediaBrowserAddResult.Added>(h.services.addMediaBrowserConnection(jellyfin()))
        val kids = h.services.createLocalProfile("Kids", pin = "1234")
        h.services.addMediaBrowserConnection(jellyfin(userId = "user-b"), targetProfile = kids)
        val guest = h.services.createLocalProfile("Guest")
        h.services.addMediaBrowserConnection(jellyfin(userId = "user-c"), targetProfile = guest)
        val pins = PinPrompter()
        val host = MenuHost()
        val settings = mutableListOf<Unit>()
        val store = UserMenuStore(h.services, h.removal, pins, host, { settings += Unit }, backgroundScope)
        advanceTimeBy(5_000)
        return Menu(store, pins, host, settings)
    }

    @Test
    fun `the menu lists the other profiles with their locks then the actions in order`() = profileTest { h ->
        val menu = menu(h)
        val state = menu.store.state.value

        assertEquals("User user-a", state.active?.name)
        assertEquals(listOf("Kids" to true, "Guest" to false), state.profiles.map { it.name to it.locked })
        assertEquals(listOf(UserMenuAction.MANAGE_PROFILES, UserMenuAction.SETTINGS, UserMenuAction.LOGOUT), state.actions)
        assertEquals(listOf(T.profiles.manageProfiles, T.common.settings, T.common.logout), state.actions.map { it.label })
    }

    @Test
    fun `switching shows only once the PIN is accepted and the menu waits until the switch ends`() = profileTest { h ->
        val menu = menu(h)
        val kids = menu.store.state.value.profiles.first { it.name == "Kids" }
        h.mediaBrowser.healthDelay[jellyfin(userId = "user-b").id] = 2.seconds

        menu.store.switchTo(kids.id)
        runCurrent()
        assertEquals("Kids", menu.pins.request.value?.title)
        assertFalse(menu.store.state.value.switching, "nothing covers the PIN pad")

        menu.pins.submit("1234")
        advanceTimeBy(1_000)
        assertTrue(menu.store.state.value.switching)
        menu.store.act(UserMenuAction.SETTINGS)
        assertTrue(menu.settings.isEmpty(), "the menu is off while switching")

        advanceTimeBy(5_000)
        assertEquals(kids.id, h.services.active.first()?.id)
        val state = menu.store.state.value
        assertFalse(state.switching)
        assertEquals("Kids", state.active?.name)
        assertEquals(listOf("User user-a", "Guest"), state.profiles.map { it.name })
    }

    @Test
    fun `a cancelled PIN keeps the profile`() = profileTest { h ->
        val menu = menu(h)
        val active = h.services.active.value?.id

        menu.store.switchTo(menu.store.state.value.profiles.first { it.name == "Kids" }.id)
        runCurrent()
        assertFalse(menu.store.state.value.switching)
        menu.pins.cancel()
        advanceTimeBy(5_000)

        assertEquals(active, h.services.active.value?.id)
        assertFalse(menu.store.state.value.switching)
        assertNull(menu.store.state.value.message)
    }

    @Test
    fun `manage profiles opens the picker and settings opens settings`() = profileTest { h ->
        val menu = menu(h)

        menu.store.act(UserMenuAction.MANAGE_PROFILES)
        menu.store.act(UserMenuAction.SETTINGS)

        assertEquals(listOf<Route>(Route.ProfilePicker(required = false, manage = true)), menu.host.opened)
        assertEquals(1, menu.settings.size)
    }

    @Test
    fun `log out asks first and only a confirm logs out of every profile`() = profileTest { h ->
        val menu = menu(h)

        menu.store.act(UserMenuAction.LOGOUT)
        val confirm = menu.store.state.value.confirm
        assertEquals(T.messages.logoutConfirm, confirm?.message)
        assertEquals(T.common.logout, confirm?.confirmLabel)
        menu.store.dismissConfirm()
        advanceTimeBy(1_000)
        assertNull(menu.store.state.value.confirm)
        assertEquals(3, h.services.profiles.value.size)
        assertEquals(0, menu.host.signedOut)

        val active = checkNotNull(h.services.active.value).id
        h.data.trackerAccounts.connect(active, TrackerService.TRAKT, "alex", 1)
        menu.store.act(UserMenuAction.LOGOUT)
        menu.store.confirm()
        advanceTimeBy(5_000)
        assertTrue(h.services.profiles.value.isEmpty())
        assertNull(h.services.active.value)
        assertEquals(1, menu.host.signedOut)
        // The integrations go with the profiles: the next sign-in finds none of them.
        assertTrue(h.data.trackerAccounts.connections().isEmpty())
    }
}
