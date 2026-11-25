package com.edde746.plezy.links

import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.strings.InterfaceLocale
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

/**
 * The one link queue: a link waits for a profile session and is delivered once, a newer one replaces it, the same URL
 * within two seconds is one delivery, a link naming another profile switches first (backing out drops it) and acts once
 * the screens are that profile's, an unknown profile or an invalid link is reported, the start claims a link's profile,
 * and external player returns skip the queue.
 */
class DeepLinksTest {
    private val parents = profile("parents", "Parents")
    private val kids = profile("kids", "Kids")

    private class FakeHost(override var activeProfileId: String?, override val profiles: List<Profile>) : LinkProfiles {
        val switches = mutableListOf<String>()
        private var pendingSwitch: CompletableDeferred<Boolean>? = null

        /** Completes the switch in flight; on success [activeProfileId] follows. */
        fun finishSwitch(switched: Boolean) {
            if (switched) activeProfileId = switches.last()
            pendingSwitch!!.complete(switched)
        }

        override suspend fun switchTo(profile: Profile): Boolean {
            switches += profile.id
            return CompletableDeferred<Boolean>().also { pendingSwitch = it }.await()
        }

        /** The screens' restart lags the switch: a link waits for [screensStarted]. */
        var screensLag = false
        private val screens = CompletableDeferred<Unit>()

        fun screensStarted() = screens.complete(Unit)

        override suspend fun awaitScreens(profileId: String) {
            if (screensLag) screens.await()
        }
    }

    private class Session(profileId: String?) {
        val launched = mutableListOf<String>()
        val session = LinkSession(profileId) { launched += it.toUrl() }
    }

    private val reports = mutableListOf<String>()
    private val playerReturns = mutableListOf<String>()
    private val time = TestTimeSource()

    @BeforeTest
    fun english() = InterfaceLocale.setSystemLanguages(listOf("en"))

    private fun TestScope.links() = DeepLinks(backgroundScope, reports::add, { playerReturns += it }, time)

    private fun host(active: String) = FakeHost(active, listOf(parents, kids))

    @Test
    fun aLinkWaitsForAProfileSessionAndIsDeliveredOnce() = runTest {
        val links = links()
        links.host = host("parents")
        links.receive("plezy://play?server=s1&id=1")

        val session = Session("parents")
        links.attach(session.session)
        links.attach(session.session)
        runCurrent()
        assertEquals(listOf("plezy://play?server=s1&id=1"), session.launched)
    }

    @Test
    fun aNewerLinkReplacesOneStillWaiting() = runTest {
        val links = links()
        links.host = host("parents")
        links.receive("plezy://play?server=s1&id=1")
        links.receive("plezy://live?channel=4.1")

        val session = Session("parents")
        links.attach(session.session)
        runCurrent()
        assertEquals(listOf("plezy://live?channel=4.1"), session.launched)
    }

    @Test
    fun theSameUrlWithinTwoSecondsIsOneDelivery() = runTest {
        val links = links()
        links.host = host("parents")
        val session = Session("parents")
        links.attach(session.session)

        links.receive("plezy://play?server=s1&id=1")
        time += 1.seconds
        links.receive("plezy://play?server=s1&id=1")
        runCurrent()
        assertEquals(1, session.launched.size)

        time += 2.seconds + 1.milliseconds
        links.receive("plezy://play?server=s1&id=1")
        runCurrent()
        assertEquals(2, session.launched.size)
    }

    @Test
    fun aLinkNamingAnotherProfileSwitchesFirstThenPlaysInThatProfile() = runTest {
        val links = links()
        val host = host("parents")
        links.host = host
        val parentsSession = Session("parents")
        links.attach(parentsSession.session)

        links.receive("plezy://play?server=s1&id=1&profile=Kids")
        runCurrent()
        assertEquals(listOf("kids"), host.switches)
        assertTrue(links.selectsProfile)

        // The switch rebuilds the profile session: the new one attaches while the switch is still settling, and must
        // wait for it.
        val kidsSession = Session("kids")
        links.attach(kidsSession.session)
        runCurrent()
        assertTrue(kidsSession.launched.isEmpty())

        host.finishSwitch(true)
        links.detach(parentsSession.session)
        runCurrent()
        assertTrue(parentsSession.launched.isEmpty())
        assertEquals(listOf("plezy://play?server=s1&id=1&profile=Kids"), kidsSession.launched)
        assertFalse(links.selectsProfile)
    }

    @Test
    fun aLinkActsOnlyOnceTheScreensAreItsProfiles() = runTest {
        val links = links()
        val host = host("parents")
        host.screensLag = true
        links.host = host
        links.attach(Session("parents").session)

        links.receive("plezy://play?server=s1&id=1&profile=Kids")
        runCurrent()
        val kidsSession = Session("kids")
        links.attach(kidsSession.session)
        host.finishSwitch(true)
        runCurrent()
        // The switch is over but the screens haven't started anew for it: the restart would take the link's player off.
        assertTrue(kidsSession.launched.isEmpty())

        host.screensStarted()
        runCurrent()
        assertEquals(listOf("plezy://play?server=s1&id=1&profile=Kids"), kidsSession.launched)
    }

    @Test
    fun aNewerLinkArrivingDuringTheSwitchRunsAfterIt() = runTest {
        val links = links()
        val host = host("parents")
        links.host = host
        val session = Session("parents")
        links.attach(session.session)

        links.receive("plezy://open?profile=kids")
        runCurrent()
        links.receive("plezy://play?server=s1&id=2")
        host.finishSwitch(false)
        runCurrent()
        assertEquals(listOf("plezy://play?server=s1&id=2"), session.launched)
    }

    @Test
    fun backingOutOfTheSwitchDropsTheLink() = runTest {
        val links = links()
        val host = host("parents")
        links.host = host
        val session = Session("parents")
        links.attach(session.session)

        links.receive("plezy://open?profile=kids")
        runCurrent()
        host.finishSwitch(false)
        runCurrent()

        links.attach(session.session)
        runCurrent()
        assertTrue(session.launched.isEmpty())
        assertFalse(links.selectsProfile)
    }

    @Test
    fun aLinkForTheActiveProfilePlaysWithoutSwitching() = runTest {
        val links = links()
        val host = host("kids")
        links.host = host
        val session = Session("kids")
        links.attach(session.session)

        links.receive("plezy://play?server=s1&id=1&profile=KIDS")
        runCurrent()
        assertTrue(host.switches.isEmpty())
        assertEquals(1, session.launched.size)
    }

    @Test
    fun anOpenLinkSwitchesOnlyToAnotherProfileItNames() = runTest {
        val links = links()
        val host = host("parents")
        links.host = host
        val session = Session("parents")
        links.attach(session.session)

        links.receive("plezy://open")
        links.receive("plezy://open?profile=Parents")
        runCurrent()
        assertTrue(host.switches.isEmpty())

        links.receive("plezy://open?profile=KIDS")
        runCurrent()
        assertEquals(listOf("kids"), host.switches)
    }

    @Test
    fun anUnknownProfileIsReportedAndTheLinkDropped() = runTest {
        val links = links()
        links.host = host("parents")
        val session = Session("parents")
        links.attach(session.session)

        links.receive("plezy://play?server=s1&id=1&profile=Grandma")
        runCurrent()
        assertTrue(session.launched.isEmpty())
        assertEquals(listOf("No profile matches \"Grandma\"."), reports)
    }

    @Test
    fun `a link still resolving when the profile switches neither plays nor reports in the next profile`() = runTest {
        val links = links()
        val host = host("parents")
        links.host = host
        val resolution = CompletableDeferred<Unit>()
        val played = mutableListOf<String>()
        val parentsSession = LinkSession("parents") { link ->
            resolution.await()
            played += link.toUrl()
            reports += "Couldn't play it."
        }
        links.attach(parentsSession)
        links.receive("plezy://play?server=s1&id=1")
        runCurrent()

        links.detach(parentsSession)
        host.activeProfileId = "kids"
        links.attach(Session("kids").session)
        resolution.complete(Unit)
        runCurrent()
        assertTrue(played.isEmpty())
        assertTrue(reports.isEmpty())
    }

    @Test
    fun anInvalidLinkIsReported() = runTest {
        val links = links()
        links.receive("plezy://play?id=1")
        assertEquals(listOf("This Plezy link isn't valid."), reports)
    }

    @Test
    fun aClaimedProfileIsAppliedByTheStartNotSwitchedAgain() = runTest {
        val links = links()
        val host = host("kids")
        links.host = host
        links.receive("plezy://play?server=s1&id=1&profile=kids")

        assertEquals(kids, links.claimStartupProfile(listOf(parents, kids)))
        assertTrue(links.selectsProfile)

        links.settleStartupProfile(applied = true)
        val session = Session("kids")
        links.attach(session.session)
        runCurrent()
        assertTrue(host.switches.isEmpty())
        assertEquals(1, session.launched.size)
    }

    @Test
    fun aProfileTheStartCouldNotApplyDropsTheLink() = runTest {
        val links = links()
        links.host = host("parents")
        links.receive("plezy://play?server=s1&id=1&profile=kids")
        assertEquals(kids, links.claimStartupProfile(listOf(parents, kids)))

        links.settleStartupProfile(applied = false)
        val session = Session("parents")
        links.attach(session.session)
        runCurrent()
        assertTrue(session.launched.isEmpty())
    }

    @Test
    fun nothingIsClaimedForALinkWithoutAProfileOrWithAnUnknownOne() = runTest {
        val links = links()
        links.receive("plezy://play?server=s1&id=1")
        assertNull(links.claimStartupProfile(listOf(parents, kids)))
        links.receive("plezy://open?profile=Grandma")
        assertNull(links.claimStartupProfile(listOf(parents, kids)))
    }

    @Test
    fun aProfileTheStartCannotActivateItselfIsLeftToTheSwitch() = runTest {
        val links = links()
        val host = host("parents")
        links.host = host
        links.receive("plezy://play?server=s1&id=1&profile=kids")
        assertNull(links.claimStartupProfile(listOf(parents, kids)) { it.id != "kids" })

        links.attach(Session("parents").session)
        runCurrent()
        assertEquals(listOf("kids"), host.switches)
    }

    @Test
    fun externalPlayerReturnLinksGoToThePlayerNotASession() = runTest {
        val links = links()
        links.host = host("parents")
        val session = Session("parents")
        links.attach(session.session)

        val url = "plezy://external-player/success/s1?position=12"
        links.receive(url)
        runCurrent()
        assertEquals(listOf(url), playerReturns)
        assertTrue(session.launched.isEmpty())
    }

    @Test
    fun eachPlayLinkFailureShowsItsOwnMessage() = runTest {
        val links = AppLinks(backgroundScope)
        links.report(PlayLinkFailure.SERVER_UNAVAILABLE)
        assertEquals("Couldn't reach the server for this link.", links.message.value)
        links.report(PlayLinkFailure.NOT_FOUND)
        assertEquals("Couldn't find this title in your libraries.", links.message.value)
        links.report(PlayLinkFailure.UNSUPPORTED_ITEM)
        assertEquals("This link can't be played.", links.message.value)
        links.dismissMessage("This link can't be played.")
        assertNull(links.message.value)
    }

    private fun profile(id: String, name: String): Profile = LocalProfile(id = id, displayName = name, createdAt = 0)
}
