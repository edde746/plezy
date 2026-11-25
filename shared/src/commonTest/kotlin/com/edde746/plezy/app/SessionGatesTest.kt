package com.edde746.plezy.app

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

class SessionGatesTest {
    private val time = TestTimeSource()
    private val gate = ResumeGate(time)

    @Test
    fun aColdOpenNeitherPromptsNorRefreshes() {
        assertNull(gate.resumed())
    }

    @Test
    fun aShortBackgroundingPromptsButDoesNotRefresh() {
        gate.backgrounded()
        time += 4.minutes
        assertEquals(ResumeGate.Resume(prompt = true, staleRefresh = false), gate.resumed())
    }

    @Test
    fun aBackgroundingLongerThanTheThresholdRefreshesOnce() {
        gate.backgrounded()
        time += 5.minutes
        assertEquals(ResumeGate.Resume(prompt = true, staleRefresh = true), gate.resumed())
        assertNull(gate.resumed())
    }

    @Test
    fun theEarliestBackgroundedTimeIsKept() {
        gate.backgrounded()
        time += 3.minutes
        gate.backgrounded()
        time += 3.minutes
        assertTrue(assertNotNull(gate.resumed()).staleRefresh)
    }

    @Test
    fun aResumeResetsTheLatch() {
        gate.backgrounded()
        time += 10.minutes
        gate.resumed()
        gate.backgrounded()
        time += 30.seconds
        assertFalse(assertNotNull(gate.resumed()).staleRefresh)
    }

    @Test
    fun aBackgroundingSpentInPictureInPictureDoesNotPromptButStillCountsAsStale() {
        gate.backgrounded(inPictureInPicture = true)
        time += 10.minutes
        assertEquals(ResumeGate.Resume(prompt = false, staleRefresh = true), gate.resumed())

        gate.backgrounded(inPictureInPicture = true)
        gate.backgrounded()
        assertEquals(ResumeGate.Resume(prompt = true, staleRefresh = false), gate.resumed(), "it left picture in picture in the background")
    }

    @Test
    fun theResumePromptIsSuppressedWhileACastPlaysHereButNotDuringPlayback() {
        fun prompt(offline: Boolean = false, picker: Boolean = false, desktop: Boolean = false, casting: Boolean = false) =
            shouldPromptProfileOnResume(true, offline, picker, desktop, casting)
        assertTrue(prompt())
        assertFalse(prompt(casting = true))
        assertFalse(prompt(offline = true))
        assertFalse(prompt(picker = true))
        assertFalse(prompt(desktop = true))
        assertFalse(shouldPromptProfileOnResume(false, false, false, false, false))
    }

    @Test
    fun aSameProfileRebindInvalidatesOnceWhenBindingSettles() {
        val settles = RebindSettles()
        // The start's bind.
        assertFalse(settles.onState("a", binding = true))
        assertFalse(settles.onState("a", binding = false))
        // A rebind of the same profile.
        assertFalse(settles.onState("a", binding = true))
        assertTrue(settles.onState("a", binding = false))
        assertFalse(settles.onState("a", binding = false))
    }

    @Test
    fun aProfileSwitchInvalidatesNothingHere() {
        val settles = RebindSettles()
        settles.onState("a", binding = true)
        settles.onState("a", binding = false)
        assertFalse(settles.onState("b", binding = true))
        assertFalse(settles.onState("b", binding = false))
        // The switched-to profile's next rebind does.
        settles.onState("b", binding = true)
        assertTrue(settles.onState("b", binding = false))
    }
}
