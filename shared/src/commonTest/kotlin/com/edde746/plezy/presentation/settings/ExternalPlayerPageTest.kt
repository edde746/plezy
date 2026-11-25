package com.edde746.plezy.presentation.settings

import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.players.ExternalPlayerPlatform
import com.edde746.plezy.playback.players.FakeProbe
import com.edde746.plezy.playback.players.KnownPlayers
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.CustomPlayerType
import com.edde746.plezy.settings.ExternalPlayerChoice
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * External player: the players listed (System Default, detected, a selected one detection
 * missed, custom ones), which ones can be deleted, the fallback when the selected one goes, and adding custom players.
 */
class ExternalPlayerPageTest {
    private val vlc = KnownPlayers.findById("vlc")!!.choice
    private val custom = ExternalPlayerChoice("custom_1", "Custom Test Player", isCustom = true, customValue = "myplayer", customType = CustomPlayerType.COMMAND)

    private class External(val fixture: SettingsFixture, val store: ExternalPlayerPage) {
        val state get() = store.state.value
        suspend fun <T> stored(setting: DeviceSetting<T>) = fixture.data.deviceSettings.value(setting)
    }

    /** Linux with [commands] on PATH, or [platform] with every player found. */
    private suspend fun TestScope.external(
        commands: Set<String> = setOf("vlc"),
        platform: ExternalPlayerPlatform = ExternalPlayerPlatform.LINUX,
        os: String = "Linux",
        setup: suspend SettingsFixture.() -> Unit = {},
    ): External {
        val probe = if (platform == ExternalPlayerPlatform.LINUX) FakeProbe(commands = commands) else FakeProbe(everything = true)
        val form = if (os == "Android" || os == "iOS") FormFactor.HANDHELD else FormFactor.DESKTOP
        val fixture = settingsFixture(SettingsPlatform(os = os, formFactor = form, externalPlayers = FakePlayerApps(platform, probe)))
        fixture.setup()
        val external = External(fixture, fixture.stores.externalPlayer())
        runCurrent()
        return external
    }

    @Test
    fun onlyCustomPlayersCanBeDeletedAndDeletingTheSelectedOneFallsBackToSystemDefault() = runTest {
        val external = external {
            data.deviceSettings.set(AppSettings.useExternalPlayer, true)
            data.deviceSettings.set(AppSettings.customExternalPlayers, listOf(custom))
            data.deviceSettings.set(AppSettings.selectedExternalPlayer, custom)
        }
        assertTrue(external.state.enabled)
        assertEquals(listOf(T.externalPlayer.systemDefault, "VLC"), external.state.players.map { it.name })
        assertTrue(external.state.players.first().systemDefault)
        assertEquals(listOf("custom_1"), external.state.custom.map { it.id })
        assertTrue(external.state.custom.single().selected)
        assertFalse(external.state.players.any { it.selected })

        assertFailsWith<IllegalArgumentException> { external.store.delete("vlc") }
        assertFailsWith<IllegalArgumentException> { external.store.delete(KnownPlayers.SYSTEM_DEFAULT_ID) }

        external.store.delete("custom_1")
        runCurrent()
        assertEquals(emptyList(), external.stored(AppSettings.customExternalPlayers))
        assertEquals(ExternalPlayerChoice.SYSTEM_DEFAULT, external.stored(AppSettings.selectedExternalPlayer))
        assertEquals(emptyList(), external.state.custom)
        assertTrue(external.state.players.first().selected)
    }

    @Test
    fun aSelectedPlayerDetectionMissesStaysListed() = runTest {
        val external = external(commands = emptySet()) {
            data.deviceSettings.set(AppSettings.useExternalPlayer, true)
            data.deviceSettings.set(AppSettings.selectedExternalPlayer, vlc)
        }
        assertEquals(listOf(T.externalPlayer.systemDefault, "VLC"), external.state.players.map { it.name })
        val missed = external.state.players.last()
        assertEquals("vlc", missed.id)
        assertTrue(missed.selected)
    }

    @Test
    fun selectingAPlayerStoresItAndTheSwitchKeepsTheChoice() = runTest {
        val external = external()
        assertFalse(external.state.enabled)

        external.store.setEnabled(true)
        runCurrent()
        assertTrue(external.state.enabled)
        assertTrue(external.state.players.first().selected)

        external.store.select("vlc")
        runCurrent()
        assertEquals(vlc, external.stored(AppSettings.selectedExternalPlayer))
        assertFailsWith<IllegalArgumentException> { external.store.select("custom_missing") }

        external.store.setEnabled(false)
        runCurrent()
        assertFalse(external.state.enabled)
        assertEquals(vlc, external.stored(AppSettings.selectedExternalPlayer))
    }

    @Test
    fun aCustomPlayerNeedsANameAndAValue() = runTest {
        val external = external()
        assertEquals(listOf(ExternalPlayerPage.COMMAND, ExternalPlayerPage.URL_SCHEME), external.state.customTypes.map { it.id })
        assertEquals("/usr/bin/player", external.state.customValueHint[ExternalPlayerPage.COMMAND])

        assertFalse(external.store.addCustom("  ", ExternalPlayerPage.COMMAND, "mpv"))
        assertFalse(external.store.addCustom("mpv", ExternalPlayerPage.COMMAND, " "))
        runCurrent()
        assertEquals(emptyList(), external.stored(AppSettings.customExternalPlayers))

        assertTrue(external.store.addCustom(" My mpv ", ExternalPlayerPage.COMMAND, " /usr/bin/mpv "))
        assertTrue(external.store.addCustom("Scheme", ExternalPlayerPage.URL_SCHEME, "myplayer://play?url="))
        runCurrent()
        val added = external.stored(AppSettings.customExternalPlayers)
        assertEquals(
            listOf(Triple("My mpv", "/usr/bin/mpv", CustomPlayerType.COMMAND), Triple("Scheme", "myplayer://play?url=", CustomPlayerType.URL_SCHEME)),
            added.map { Triple(it.name, it.customValue, it.customType) },
        )
        assertTrue(added.all { it.isCustom })
        assertEquals(2, added.map { it.id }.toSet().size, "players added together get their own ids")
        assertEquals(listOf("My mpv", "Scheme"), external.state.custom.map { it.name })
    }

    @Test
    fun androidAddsPackagesAndIosUrlSchemes() = runTest {
        val android = external(platform = ExternalPlayerPlatform.ANDROID, os = "Android")
        assertEquals(listOf(ExternalPlayerPage.COMMAND), android.state.customTypes.map { it.id })
        assertEquals(T.externalPlayer.playerPackage, android.state.customTypes.single().label)
        val ios = external(platform = ExternalPlayerPlatform.IOS, os = "iOS")
        assertEquals(listOf(ExternalPlayerPage.URL_SCHEME), ios.state.customTypes.map { it.id })
        assertFailsWith<IllegalArgumentException> { ios.store.addCustom("mpv", ExternalPlayerPage.COMMAND, "mpv") }
    }
}
