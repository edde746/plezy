package com.edde746.plezy.app

import com.edde746.plezy.data.inMemoryDatabase
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertFailsWith

/** The shared core starts only once the platform has reported the system's settings ([SystemInputs.report]). */
class SystemInputsTest {
    private val reportedBefore = SystemInputs.reported

    @AfterTest
    fun restore() {
        SystemInputs.reported = reportedBefore
    }

    @Test
    fun aCoreBuiltBeforeTheSystemsSettingsAreReportedFailsInsteadOfShowingEnglish() {
        SystemInputs.reported = false
        val error = assertFailsWith<IllegalStateException> {
            AppBootstrap.local(inMemoryDatabase(), BuildFlavor.SIDELOADED, "test").close()
        }
        assertContains(error.message.orEmpty(), "SystemInputs.report")
    }
}
