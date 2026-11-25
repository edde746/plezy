package com.edde746.plezy.playback.players

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.CustomPlayerType
import com.edde746.plezy.settings.ExternalPlayerChoice
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class ExternalPlayerSettingsTest {
    private val custom = ExternalPlayerChoice("custom-test-player", "Custom Test Player", isCustom = true, customValue = "custom-player", customType = CustomPlayerType.COMMAND)

    private fun TestScope.data() = LocalData(inMemoryDatabase(), { 1_790_000_000_000L }, StandardTestDispatcher(testScheduler))

    @Test
    fun removingTheSelectedCustomPlayerSelectsTheSystemDefault() = runTest {
        val data = data()
        val settings = data.deviceSettings
        ExternalPlayerSettings.replaceCustomPlayers(settings, listOf(custom))
        ExternalPlayerSettings.selectPlayer(settings, custom)
        assertEquals(custom, settings.value(AppSettings.selectedExternalPlayer))

        ExternalPlayerSettings.removeCustomPlayer(settings, custom.id)

        assertEquals(emptyList(), settings.value(AppSettings.customExternalPlayers))
        assertEquals(ExternalPlayerChoice.SYSTEM_DEFAULT, settings.value(AppSettings.selectedExternalPlayer))
        data.close()
    }

    @Test
    fun aSelectedCustomPlayerFollowsItsNewDefinition() = runTest {
        val data = data()
        val settings = data.deviceSettings
        ExternalPlayerSettings.replaceCustomPlayers(settings, listOf(custom))
        ExternalPlayerSettings.selectPlayer(settings, custom)
        val renamed = custom.copy(name = "Renamed")
        ExternalPlayerSettings.replaceCustomPlayers(settings, listOf(renamed))
        assertEquals(renamed, settings.value(AppSettings.selectedExternalPlayer))
        data.close()
    }

    @Test
    fun onlyValidUniqueCustomPlayersAreStoredAndOnlyStoredOnesSelected() = runTest {
        val data = data()
        val settings = data.deviceSettings
        for (bad in listOf(
            listOf(custom.copy(isCustom = false)),
            listOf(custom.copy(id = "vlc")),
            listOf(custom, custom),
            listOf(custom.copy(customType = null)),
            listOf(custom.copy(name = " ")),
            listOf(custom.copy(customValue = "")),
        )) {
            assertFailsWith<IllegalArgumentException>(bad.toString()) { ExternalPlayerSettings.replaceCustomPlayers(settings, bad) }
        }
        assertFailsWith<IllegalArgumentException> { ExternalPlayerSettings.selectPlayer(settings, custom) }
        assertEquals(emptyList(), settings.value(AppSettings.customExternalPlayers))
        data.close()
    }

    @Test
    fun aSelectedKnownPlayerStaysListedWhenDetectionMissesIt() {
        val detected = listOf(KnownPlayers.systemDefault)
        val vlc = KnownPlayers.findById("vlc")!!
        assertEquals(listOf(KnownPlayers.systemDefault, vlc), ExternalPlayerSettings.listed(detected, "vlc", ExternalPlayerPlatform.LINUX))
        // One this platform doesn't offer, or a custom one, isn't added.
        assertEquals(detected, ExternalPlayerSettings.listed(detected, "iina", ExternalPlayerPlatform.LINUX))
        assertEquals(detected, ExternalPlayerSettings.listed(detected, custom.id, ExternalPlayerPlatform.LINUX))
    }
}
