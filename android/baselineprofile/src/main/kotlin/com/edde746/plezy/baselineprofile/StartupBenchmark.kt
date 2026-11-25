package com.edde746.plezy.baselineprofile

import androidx.benchmark.macro.BaselineProfileMode
import androidx.benchmark.macro.CompilationMode
import androidx.benchmark.macro.MacrobenchmarkScope
import androidx.benchmark.macro.StartupMode
import androidx.benchmark.macro.StartupTimingMetric
import androidx.benchmark.macro.junit4.MacrobenchmarkRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The product's cold start of a signed-in session (signed in once before, [signIn]) to Home, with the app's shipped
 * Baseline Profile installed as a store installs it: timeToInitialDisplay, per iteration and its median. The same
 * `server` instrumentation argument as [BaselineProfileGenerator]'s.
 */
@RunWith(AndroidJUnit4::class)
class StartupBenchmark {
    @get:Rule
    val rule = MacrobenchmarkRule()

    @Test
    fun startup() {
        MacrobenchmarkScope(PACKAGE, launchWithClearTask = true).signIn()
        rule.measureRepeated(
            PACKAGE,
            listOf(StartupTimingMetric()),
            CompilationMode.Partial(BaselineProfileMode.Require),
            StartupMode.COLD,
            iterations = 10,
            // On a TV a key press first: until one, Android is in touch mode, where nothing is focused.
            setupBlock = { if (TV) device.pressDPadDown() },
        ) {
            startActivityAndWait()
            awaitHome()
        }
    }
}
