package com.edde746.plezy.ui.components

import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.AccessibilityManager
import androidx.compose.ui.platform.LocalAccessibilityManager
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.graphics.toPixelMap
import com.edde746.plezy.ui.theme.Oled
import androidx.compose.ui.test.performClick
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/** A message's severity shows: an error toast is drawn on the error colour. */
@OptIn(ExperimentalTestApi::class)
class ErrorToastTest {
    @Test
    fun anErrorToastIsDrawnOnTheErrorColour() = runComposeUiTest {
        setContent { PlezyTheme { TimedToast("Permission revoked", "toast", onShown = {}, isError = true) } }
        val pixels = onNodeWithText("Permission revoked").captureToImage().toPixelMap()
        assertEquals(Oled.error, pixels[pixels.width / 2, 2])
    }
}

/** A store's one-off message at the bottom of a screen: TalkBack speaks it, and it stays up as its user needs. */
@OptIn(ExperimentalTestApi::class)
class TimedToastTest {
    private var text by mutableStateOf<String?>("Added to Downloads")
    private var isError by mutableStateOf(false)
    private var shown = 0

    /** TalkBack speaks a toast as it shows and as its text changes, wherever its focus is. */
    @Test
    fun aToastIsSpokenAsItShowsAndChanges() = runComposeUiTest {
        toast(accessibility = null)
        onNodeWithText("Added to Downloads").assert(spoken)
        text = "Sam joined"
        onNodeWithText("Sam joined").assert(spoken)
    }

    /**
     * Android's "Time to take action" set to 20 s keeps a toast up past its usual 3 s: the store hears it was shown (and
     * clears it) only after the 20 s.
     */
    @Test
    fun aToastStaysForTheTimeTheUserAsksFor() = runComposeUiTest {
        toast(accessibility = twentySeconds)
        mainClock.advanceTimeBy(ERROR_TOAST_MILLIS + 500)
        onNodeWithText("Added to Downloads").assertExists()
        runOnIdle { assertEquals(0, shown) }
        mainClock.advanceTimeBy(20_000)
        onNodeWithText("Added to Downloads").assertDoesNotExist()
        runOnIdle { assertEquals(1, shown) }
    }

    /** A message shows 3 s, an error 4 s. */
    @Test
    fun aMessageShowsThreeSecondsAndAnErrorFour() = runComposeUiTest {
        text = null
        toast(accessibility = null)
        for ((error, millis) in listOf(false to 3_000L, true to 4_000L)) {
            shown = 0
            isError = error
            text = "Added to Downloads"
            mainClock.advanceTimeBy(millis - 200)
            runOnIdle { assertEquals(0, shown, "error $error went before $millis ms") }
            mainClock.advanceTimeBy(400)
            runOnIdle { assertEquals(1, shown, "error $error stayed past $millis ms") }
        }
    }

    /** On the desktop a click dismisses a toast at once. */
    @Test
    fun aClickDismissesADesktopToast() = runComposeUiTest {
        toast(accessibility = null)
        onNodeWithText("Added to Downloads").performClick()
        runOnIdle { assertEquals(1, shown) }
    }

    /** The toast while [text] is set, with [accessibility] as the platform's accessibility settings (none: desktop's). */
    private fun ComposeUiTest.toast(accessibility: AccessibilityManager?) = setContent {
        CompositionLocalProvider(LocalAccessibilityManager provides accessibility) {
            PlezyTheme {
                text?.let {
                    TimedToast(it, "toast", onShown = {
                        shown++
                        text = null
                    }, isError = isError)
                }
            }
        }
    }

    private val spoken = SemanticsMatcher.expectValue(SemanticsProperties.LiveRegion, LiveRegionMode.Polite)

    /** Android's "Time to take action" set to 20 s: what shows text or icons stays up at least that long. */
    private val twentySeconds = object : AccessibilityManager {
        override fun calculateRecommendedTimeoutMillis(
            originalTimeoutMillis: Long,
            containsIcons: Boolean,
            containsText: Boolean,
            containsControls: Boolean,
        ) = if (containsText || containsIcons) maxOf(originalTimeoutMillis, 20_000L) else originalTimeoutMillis
    }
}
