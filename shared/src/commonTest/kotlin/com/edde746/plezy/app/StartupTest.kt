@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.app

import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/** The splash's status line: the step the product's start is on, named once the start has taken half a second. */
class StartupTest {
    @Test
    fun theStatusNamesTheStepOnlyAfterHalfASecondFollowsItAndGoesOnceTheStartIsDone() = runTest {
        val startup = Startup(backgroundScope, Duration.ZERO)
        assertEquals(StartupUiState(StartupStep.DATABASE, null), startup.state.value)

        startup.begin(StartupStep.MIGRATION)
        advanceTimeBy(Startup.STATUS_DELAY - 1.milliseconds)
        runCurrent()
        assertEquals(StartupUiState(StartupStep.MIGRATION, null), startup.state.value)

        advanceTimeBy(1.milliseconds)
        runCurrent()
        assertEquals(StartupUiState(StartupStep.MIGRATION, T.app.startup.migration), startup.state.value)

        startup.finish()
        assertEquals(StartupUiState(null, null), startup.state.value)
        startup.begin(StartupStep.MIGRATION)
        advanceTimeBy(10.seconds)
        assertEquals(StartupUiState(null, null), startup.state.value)
    }

    @Test
    fun aStartDoneWithinHalfASecondShowsTheLoaderAlone() = runTest {
        val startup = Startup(backgroundScope, Duration.ZERO)
        val seen = record(startup)

        startup.begin(StartupStep.MIGRATION)
        advanceTimeBy(Startup.STATUS_DELAY - 1.milliseconds)
        startup.finish()
        advanceTimeBy(10.seconds)

        assertEquals(
            listOf(StartupUiState(StartupStep.DATABASE, null), StartupUiState(StartupStep.MIGRATION, null), StartupUiState(null, null)),
            seen,
        )
    }

    @Test
    fun theProductStartEndsOnceTheDatabaseIsOpenAndTheAppShows() = runTest {
        // A debug launch's slow start holds the start past the status delay.
        val startup = Startup(backgroundScope, 1.seconds)
        val seen = record(startup)

        val root = RootSession(testGraph(), FakeAppPlatform(), startup)
        assertEquals(RootScreen.Starting, root.screen.value)
        advanceTimeBy(2.seconds)
        runCurrent()

        assertIs<RootScreen.Main>(root.screen.value)
        assertEquals(
            listOf(
                StartupUiState(StartupStep.DATABASE, null),
                StartupUiState(StartupStep.DATABASE, T.app.startup.database),
                StartupUiState(null, null),
            ),
            seen,
        )
        root.close()
    }

    /** Every state [startup] goes through from now on. */
    private fun TestScope.record(startup: Startup): List<StartupUiState> =
        mutableListOf<StartupUiState>().also { seen -> backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { startup.state.toList(seen) } }
}
