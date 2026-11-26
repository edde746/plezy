package com.edde746.plezy

import android.content.Intent

/** Release builds have no test launches: the extras a debug build reads (src/debug) do nothing here. */
@Suppress("UNUSED_PARAMETER")
internal fun testLaunch(application: PlezyApplication, intent: Intent): TestLaunch? = null

/** Release builds leave lists' semantics to the accessibility services that are on ([LocalKeepsSemantics]). */
@Suppress("UNUSED_PARAMETER")
internal fun keepsSemantics(launch: TestLaunch?): Boolean = false
