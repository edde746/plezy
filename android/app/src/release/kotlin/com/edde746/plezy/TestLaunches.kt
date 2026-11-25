package com.edde746.plezy

import android.content.Intent

/** Release builds have no test launches: the extras a debug build reads (src/debug) do nothing here. */
@Suppress("UNUSED_PARAMETER")
internal fun testLaunch(application: PlezyApplication, intent: Intent): TestLaunch? = null
