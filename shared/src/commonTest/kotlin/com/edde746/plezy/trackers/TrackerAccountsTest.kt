package com.edde746.plezy.trackers

import com.edde746.plezy.trackers.TrackerService.ANILIST
import com.edde746.plezy.trackers.TrackerService.MYANIMELIST
import com.edde746.plezy.trackers.TrackerService.SIMKL
import com.edde746.plezy.trackers.TrackerService.TRAKT
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNotSame
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/**
 * Connections held on this device: a sign-in keeps the service's session in the secret store, each connection
 * refreshes it at the service when it nearly expires or a request is refused, and a session the service declares dead
 * drops the connection. One sign-in runs at a time, and one that is no longer current keeps nothing.
 */
class TrackerAccountsTest {
    private val fixtures = mutableListOf<TrackerFixture>()

    @AfterTest
    fun close() = fixtures.forEach { it.close() }

    private fun TestScope.fixture(relay: OAuthRelay? = null) = TrackerFixture(this, relay = relay).also { fixtures += it }

    private suspend fun TrackerFixture.queueWrite(service: TrackerService) {
        val binding = data.trackerAccounts.account(profileId, service)!!.connectedAt
        data.trackerWriteQueue.enqueue(profileId, service, binding, listOf(movieWrite(service)), 1)
    }

    private val grant = DeviceCodeGrant("dc", "ABCD-1234", "https://trakt.tv/activate", "https://trakt.tv/activate/ABCD-1234", expiresInSeconds = 600, intervalSeconds = 5)

    private val approved = DevicePoll.Success(JsonObject(emptyMap()))

    /** [service]'s device-code sign-in approving at the first poll, its account lookup held until the test opens it. */
    private fun TrackerFixture.heldSignIn(service: TrackerService) = FakeDeviceCode(scope, listOf(approved), grant).also {
        it.lookupGate = CompletableDeferred()
        providers.getValue(service).deviceCode = it
    }

    /**
     * Refreshes [service]'s sessions as the service does, each after [latency]: `<service>-access-N` with refresh token
     * `rN`, valid an hour; [refreshes] counts them.
     */
    private class CountingRefresher(private val f: TrackerFixture, private val service: TrackerService) : TokenRefresher {
        var refreshes = 0
        var latency = 0.seconds
        var failure: TrackerException? = null

        override suspend fun refresh(session: TrackerSession): TrackerSession {
            delay(latency)
            failure?.let { throw it }
            refreshes++
            return session.copy(
                accessToken = "${service.id}-access-$refreshes",
                refreshToken = "r$refreshes",
                expiresAt = f.clock.now().epochSeconds + 3600,
            )
        }
    }

    private fun TrackerFixture.refresher(service: TrackerService) =
        CountingRefresher(this, service).also { providers.getValue(service).refresher = it }

    @Test
    fun theHeldTokenServesUntilItNearlyExpiresThenItIsRefreshedOnce() = runTest {
        val f = fixture()
        val refresher = f.refresher(TRAKT)
        val expiresAt = f.clock.now().epochSeconds + 3600
        f.connect(TRAKT, TrackerSession("a0", "r0", expiresAt = expiresAt, username = "alex", createdAt = 1))
        val credentials = f.tracker(TRAKT).credentials
        assertEquals("a0", credentials.accessToken())
        f.advance(3000.seconds)
        assertEquals("a0", credentials.accessToken(), "ten minutes left: still the held token")
        assertEquals(0, refresher.refreshes)

        f.advance(400.seconds)
        val refreshed = credentials.accessToken()
        assertEquals("trakt-access-1", refreshed, "within the five-minute window: refreshed at the service")
        assertEquals(refreshed, credentials.accessToken())
        assertEquals(1, refresher.refreshes)
        assertEquals(listOf(refreshed, "r1"), f.stored(TRAKT)?.let { listOf(it.accessToken, it.refreshToken) }, "kept before it was handed out")

        // The next launch takes the kept session.
        val next = f.newHub().accounts.bound(f.profileId).first().single().tracker as FakeTracker
        assertEquals(refreshed, next.credentials.accessToken())
        assertEquals(1, refresher.refreshes)
    }

    @Test
    fun aRefreshedSessionIsKeptAndTheBindingStaysTheSame() = runTest {
        val f = fixture()
        f.refresher(TRAKT)
        f.connect(TRAKT)
        val binding = f.hub.accounts.bindings(f.profileId).first().single()
        assertEquals("trakt-access-1", binding.credentials.refreshAfterUnauthorized("a0"))
        assertEquals(listOf("trakt-access-1", "r1"), f.stored(TRAKT)?.let { listOf(it.accessToken, it.refreshToken) })
        assertSame(binding, f.hub.accounts.bindings(f.profileId).first().single(), "a refresh doesn't replace the binding or its tracker")
    }

    @Test
    fun concurrentRejectedRequestsRefreshOnce() = runTest {
        val f = fixture()
        val refresher = f.refresher(TRAKT).apply { latency = 2.seconds }
        f.connect(TRAKT)
        val credentials = f.tracker(TRAKT).credentials
        val first = async { credentials.refreshAfterUnauthorized("a0") }
        val second = async { credentials.refreshAfterUnauthorized("a0") }
        f.advance(3.seconds)
        assertEquals("trakt-access-1", first.await())
        assertEquals("trakt-access-1", second.await(), "the second caller waited for the first refresh instead of refreshing again")
        assertEquals(1, refresher.refreshes)

        // A request that was rejected with the old token later gets the new one without refreshing.
        assertEquals("trakt-access-1", credentials.refreshAfterUnauthorized("a0"))
        assertEquals("trakt-access-1", credentials.accessToken())
        assertEquals(1, refresher.refreshes)
    }

    @Test
    fun aRefusedRefreshDropsTheConnectionAndItsQueuedWrites() = runTest {
        val f = fixture()
        f.refresher(TRAKT).failure = TrackerException.Auth(TRAKT, "refresh refused", 401, permanent = true)
        f.connect(TRAKT)
        f.connect(SIMKL)
        f.queueWrite(TRAKT)
        f.queueWrite(SIMKL)
        val credentials = f.tracker(TRAKT).credentials
        val refused = assertFailsWith<TrackerException.Auth> { credentials.refreshAfterUnauthorized("a0") }
        assertTrue(refused.permanent)
        f.settle()
        assertEquals(listOf(SIMKL), f.hub.accounts.accounts(f.profileId).map { it.service })
        assertNull(f.stored(TRAKT))
        assertEquals(listOf("simkl simkl|movie|imdb=tt1 watched=true attempts=0"), f.queued(), "the next account can't replay them")
        assertTrue(assertFailsWith<TrackerException.Auth> { credentials.accessToken() }.permanent)
    }

    @Test
    fun aTransientRefreshFailureKeepsTheConnection() = runTest {
        val f = fixture()
        f.refresher(TRAKT).failure = TrackerException.Auth(TRAKT, "refresh failed", 503, permanent = false)
        f.connect(TRAKT)
        val failed = assertFailsWith<TrackerException.Auth> { f.tracker(TRAKT).credentials.refreshAfterUnauthorized("a0") }
        assertFalse(failed.permanent)
        f.settle()
        assertEquals(listOf(TRAKT), f.hub.accounts.accounts(f.profileId).map { it.service })
        assertEquals("r0", f.stored(TRAKT)?.refreshToken)
    }

    @Test
    fun aRefreshAnsweringAfterTheDisconnectDoesNotRestoreTheSession() = runTest {
        val f = fixture()
        f.refresher(TRAKT).latency = 5.seconds
        f.connect(TRAKT)
        val credentials = f.tracker(TRAKT).credentials
        val refresh = async { credentials.refreshAfterUnauthorized("a0") }
        f.advance(1.seconds)
        f.hub.accounts.disconnect(f.profileId, TRAKT)
        f.advance(10.seconds)
        refresh.await()
        assertNull(f.stored(TRAKT))
        assertEquals(emptyList(), f.hub.accounts.accounts(f.profileId))
    }

    @Test
    fun aRefreshIsKeptUnderTheProfileItsSignInBelongsToWhileAnotherIsActive() = runTest {
        val f = fixture()
        f.refresher(TRAKT)
        f.connect(TRAKT)
        f.hub.accounts.connect("p2", TRAKT, TrackerSession("p2-a0", "p2-r0", FAR_FUTURE, "sam", 1))
        f.settle()
        val other = f.hub.accounts.bindings("p2").first().single()

        assertEquals("trakt-access-1", other.credentials.refreshAfterUnauthorized("p2-a0"))

        assertEquals(listOf("trakt-access-1", "r1"), f.tokens.load("p2", TRAKT)?.session?.let { listOf(it.accessToken, it.refreshToken) })
        assertEquals("a0", f.stored(TRAKT)?.accessToken, "the active profile's session is untouched")
        assertSame(other, f.hub.accounts.bindings("p2").first().single(), "the same binding and tracker")
    }

    @Test
    fun aRefreshOfASignInThatWasReplacedKeepsNothing() = runTest {
        val f = fixture()
        f.refresher(TRAKT).latency = 5.seconds
        f.connect(TRAKT)
        val old = f.hub.accounts.bindings(f.profileId).first().single().credentials
        val refresh = async { old.refreshAfterUnauthorized("a0") }
        f.advance(1.seconds)
        f.connect(TRAKT, TrackerSession("b0", "rb", FAR_FUTURE, "alex", 2))
        f.advance(10.seconds)
        refresh.await()

        assertEquals(listOf("b0", "rb"), f.stored(TRAKT)?.let { listOf(it.accessToken, it.refreshToken) })
        assertEquals("b0", f.hub.accounts.bindings(f.profileId).first().single().credentials.accessToken())
    }

    @Test
    fun aServiceShowsConnectedWithTheSessionsNameOnlyForItsProfileAndUntilItsDisconnected() = runTest {
        val f = fixture()
        f.connect(MYANIMELIST, TrackerSession("m0", "r0", FAR_FUTURE, "carol", 1))

        assertEquals(listOf(MYANIMELIST to "carol"), f.hub.accounts.observe(f.profileId).first().map { it.service to it.username })
        assertEquals(emptyList(), f.hub.accounts.observe("p2").first())
        assertEquals(emptyList(), f.hub.accounts.bindings("p2").first(), "another profile gets no client of it")

        f.hub.accounts.disconnect(f.profileId, MYANIMELIST)
        assertEquals(emptyList(), f.hub.accounts.observe(f.profileId).first())
    }

    @Test
    fun forgettingAProfileScopeEndsItsConnectionsSessionsAndQueuedWrites() = runTest {
        val f = fixture()
        f.connect(TRAKT)
        f.queueWrite(TRAKT)
        f.hub.accounts.connect("other", SIMKL, TrackerSession("s0", "r0", FAR_FUTURE, "sam", 1))
        f.settle()
        val credentials = f.tracker(TRAKT).credentials

        f.data.trackerAccounts.forgetScopes(setOf(f.profileId))
        f.settle()

        assertEquals(emptyList(), f.hub.accounts.accounts(f.profileId))
        assertEquals(emptyList(), f.queued())
        assertNull(f.stored(TRAKT))
        assertTrue(assertFailsWith<TrackerException.Auth> { credentials.accessToken() }.permanent)
        assertEquals(listOf(SIMKL), f.hub.accounts.accounts("other").map { it.service })
        assertNotNull(f.tokens.load("other", SIMKL))
    }

    @Test
    fun aConnectionWithoutAUsableSessionIsNeverShownConnected() = runTest {
        val f = fixture()
        f.connect(SIMKL)
        f.queueWrite(SIMKL)
        // The platform's store lost the entry (a restored backup, a cleared Keystore); the app starts again.
        f.store.memory.delete(TrackerTokenStore.key(f.profileId, SIMKL))
        val next = f.newHub()
        assertEquals(emptyList(), next.accounts.observe(f.profileId).first())
        assertEquals(emptyList(), next.accounts.bindings(f.profileId).first())
        f.settle()
        assertEquals(emptyList(), f.data.trackerAccounts.accounts(f.profileId), "the connection goes, so the user signs in again")
        assertEquals(emptyList(), f.queued(), "with its queued writes")
    }

    @Test
    fun aRotatedSessionTheStoreFailedToKeepIsKeptBeforeItsNextUseAndSurvivesARestart() = runTest {
        val f = fixture()
        val refresher = f.refresher(TRAKT)
        f.connect(TRAKT, TrackerSession("a0", "r0", expiresAt = f.clock.now().epochSeconds + 60, username = "alex", createdAt = 1))
        val credentials = f.tracker(TRAKT).credentials

        f.store.failWrites = true
        assertEquals("trakt-access-1", credentials.accessToken(), "the service rotated the session: its new token serves")
        assertEquals("r0", f.stored(TRAKT)?.refreshToken, "the store failed to keep it")
        assertEquals("trakt-access-1", credentials.accessToken(), "still failing: it stays in memory")

        f.store.failWrites = false
        assertEquals("trakt-access-1", credentials.accessToken())
        assertEquals("r1", f.stored(TRAKT)?.refreshToken, "kept before the next use")

        // The next launch takes the rotated session, without refreshing again.
        val next = f.newHub().accounts.bindings(f.profileId).first().single()
        assertEquals("trakt-access-1", next.credentials.accessToken())
        assertEquals(1, refresher.refreshes)
    }

    @Test
    fun aKeptSessionThatCanNeverRenewIsASignInAgain() = runTest {
        val f = fixture()
        // A Trakt session without a refresh token: it would die at its expiry with no way back.
        f.connect(TRAKT, TrackerSession("a0", refreshToken = null, expiresAt = FAR_FUTURE, username = "alex", createdAt = 1))
        assertNull(f.tokens.load(f.profileId, TRAKT))
        assertEquals(emptyList(), f.hub.accounts.bindings(f.profileId).first(), "never bound")
        f.settle()
        assertEquals(emptyList(), f.data.trackerAccounts.accounts(f.profileId), "the connection goes, so the user signs in again")
    }

    @Test
    fun aDeadSessionOfAnOldSignInDoesNotDropTheNewOne() = runTest {
        val f = fixture()
        f.connect(ANILIST)
        val old = f.tracker(ANILIST).credentials
        f.connect(ANILIST, TrackerSession("b0", null, FAR_FUTURE, "sam", 2))
        old.invalidate("a0")
        f.settle()
        assertEquals("sam", f.hub.accounts.accounts(f.profileId).single().username)
        assertEquals("b0", f.stored(ANILIST)?.accessToken)
        assertEquals("b0", f.tracker(ANILIST).credentials.accessToken())

        // AniList has no refresh: a 401 on the current sign-in ends it.
        f.tracker(ANILIST).credentials.invalidate("b0")
        f.settle()
        assertEquals(emptyList(), f.hub.accounts.accounts(f.profileId))
        assertNull(f.stored(ANILIST))
    }

    @Test
    fun aDeviceCodeSignInKeepsTheServicesSessionWithTheAccountsName() = runTest {
        val f = fixture()
        val signIn = FakeDeviceCode(this, listOf(DevicePoll.Pending, DevicePoll.SlowDown, DevicePoll.Pending, approved), grant)
        f.providers.getValue(TRAKT).deviceCode = signIn
        val prompts = mutableListOf<SignInPrompt>()
        val account = async { f.hub.accounts.signIn(f.profileId, TRAKT) { prompts += it } }
        f.advance(60.seconds)
        val connected = assertNotNull(account.await())
        assertEquals("alex", connected.username)
        assertEquals(listOf<SignInPrompt>(SignInPrompt.DeviceCode(grant)), prompts)
        assertEquals(listOf(5_000L, 10_000L, 20_000L, 30_000L), signIn.polls, "slow_down adds 5 s to the interval")
        assertEquals(f.wallClock.now + 30_000L, connected.connectedAt, "the binding is when the sign-in was approved")
        assertEquals(listOf("granted", "r0", "alex"), f.stored(TRAKT)?.let { listOf(it.accessToken, it.refreshToken, it.username) })
    }

    @Test
    fun aFailedAccountLookupStillConnectsWithoutAName() = runTest {
        val f = fixture()
        val signIn = FakeDeviceCode(this, listOf(approved), grant).also { it.accounts.clear() }
        f.providers.getValue(TRAKT).deviceCode = signIn
        val account = async { f.hub.accounts.signIn(f.profileId, TRAKT) {} }
        f.advance(10.seconds)
        assertNull(assertNotNull(account.await()).username)
        assertEquals(listOf("granted", "r0"), f.stored(TRAKT)?.let { listOf(it.accessToken, it.refreshToken) }, "the tokens unchanged")
    }

    @Test
    fun aRelaySignInConnectsOnceTheUserAuthorizedAndNotWhenDeclined() = runTest {
        val relay = FakeRelay()
        val f = fixture(relay)
        f.providers.getValue(MYANIMELIST).relaySignIn = FakeRelaySignIn
        val prompts = mutableListOf<SignInPrompt>()
        val account = async { f.hub.accounts.signIn(f.profileId, MYANIMELIST) { prompts += it } }
        f.settle()
        assertEquals(listOf<SignInPrompt>(SignInPrompt.Link(RelayStart("s1", "https://relay.example/auth/mal?state=s1"))), prompts)
        relay.result.complete(RelayResult(accessToken = "m0", refreshToken = "mr0", expiresInSeconds = 3600))
        f.settle()
        assertEquals("kai", assertNotNull(account.await()).username)
        assertEquals(listOf("m0", "mr0"), f.stored(MYANIMELIST)?.let { listOf(it.accessToken, it.refreshToken) })

        val declined = FakeRelay().apply { result.complete(null) }
        val other = TrackerFixture(this, relay = declined).also { fixtures += it }
        other.providers.getValue(ANILIST).relaySignIn = FakeRelaySignIn
        assertNull(other.hub.accounts.signIn(other.profileId, ANILIST) {})
        assertEquals(emptyList(), other.hub.accounts.accounts(other.profileId))
    }

    @Test
    fun oneSignInRunsAtATimeAndAConnectedServiceIsNotSignedInAgain() = runTest {
        val f = fixture()
        f.heldSignIn(TRAKT)
        val first = async { f.hub.accounts.signIn(f.profileId, TRAKT) {} }
        f.advance(10.seconds)
        assertEquals(TRAKT, f.hub.accounts.connecting.value?.service)

        f.providers.getValue(SIMKL).deviceCode = FakeDeviceCode(this, listOf(approved), grant)
        assertNull(f.hub.accounts.signIn(f.profileId, SIMKL) {}, "refused while another sign-in is in flight")
        assertNull(f.hub.accounts.signIn("p2", SIMKL) {}, "for every profile")

        f.providers.getValue(TRAKT).deviceCode!!.lookupGate!!.complete(Unit)
        assertNotNull(first.await())
        assertNull(f.hub.accounts.connecting.value)
        assertNull(f.hub.accounts.signIn(f.profileId, TRAKT) {}, "connected already")
        assertEquals(1, f.providers.getValue(TRAKT).deviceCode!!.lookups.size)
    }

    @Test
    fun cancellingAfterAuthorizationKeepsNothing() = runTest {
        val f = fixture()
        val signIn = f.heldSignIn(TRAKT)
        val account = async { f.hub.accounts.signIn(f.profileId, TRAKT) {} }
        f.advance(10.seconds)
        assertEquals(1, signIn.lookups.size, "authorized, the account being looked up")
        f.hub.accounts.cancelConnect()
        signIn.lookupGate!!.complete(Unit)
        assertNull(account.await())
        assertNull(f.hub.accounts.connecting.value)
        assertEquals(emptyList(), f.hub.accounts.accounts(f.profileId))
        assertNull(f.stored(TRAKT))
    }

    @Test
    fun cancellingTheCallerKeepsNothing() = runTest {
        val f = fixture()
        val signIn = f.heldSignIn(TRAKT)
        val account = async { f.hub.accounts.signIn(f.profileId, TRAKT) {} }
        f.advance(10.seconds)
        account.cancel()
        signIn.lookupGate!!.complete(Unit)
        f.settle()
        assertNull(f.hub.accounts.connecting.value)
        assertNull(f.stored(TRAKT))
    }

    @Test
    fun switchingProfilesCancelsTheSignInInFlight() = runTest {
        val f = fixture()
        val signIn = f.heldSignIn(TRAKT)
        val account = async { f.hub.accounts.signIn(f.profileId, TRAKT) {} }
        f.advance(10.seconds)
        f.hub.onActiveProfileChanged("p2")
        signIn.lookupGate!!.complete(Unit)
        assertNull(account.await())
        assertNull(f.hub.accounts.connecting.value)
        assertNull(f.stored(TRAKT))
    }

    @Test
    fun cancelConnectWithNothingInFlightDoesNothing() = runTest {
        val f = fixture()
        f.hub.accounts.cancelConnect()
        assertNull(f.hub.accounts.connecting.value)
        f.providers.getValue(TRAKT).deviceCode = FakeDeviceCode(this, listOf(approved), grant)
        val account = async { f.hub.accounts.signIn(f.profileId, TRAKT) {} }
        f.advance(10.seconds)
        assertNotNull(account.await(), "an earlier cancel doesn't reach a later sign-in")
    }

    @Test
    fun aSignInOvertakenByAnotherConnectionCannotReplaceIt() = runTest {
        val f = fixture()
        val signIn = f.heldSignIn(TRAKT)
        val stale = async { f.hub.accounts.signIn(f.profileId, TRAKT) {} }
        f.advance(10.seconds)
        // Another sign-in of the service landed meanwhile (the app's next launch, say).
        f.newHub().accounts.connect(f.profileId, TRAKT, TrackerSession("newer", "rn", FAR_FUTURE, "sam", 2))
        f.settle()
        val newer = f.hub.accounts.bindings(f.profileId).first().single()
        signIn.lookupGate!!.complete(Unit)
        assertNull(stale.await())
        assertEquals("newer", f.stored(TRAKT)?.accessToken)
        assertSame(newer, f.hub.accounts.bindings(f.profileId).first().single())
        assertEquals("newer", newer.credentials.accessToken())
    }

    @Test
    fun aSignInForOneProfileNeverConnectsAnother() = runTest {
        val f = fixture()
        f.hub.accounts.connect("p2", TRAKT, TrackerSession("p2-token", "r", FAR_FUTURE, "sam", 1))
        val signIn = f.heldSignIn(ANILIST)
        val account = async { f.hub.accounts.signIn(f.profileId, ANILIST) {} }
        f.advance(10.seconds)
        signIn.lookupGate!!.complete(Unit)
        assertNotNull(account.await())
        assertEquals(listOf(TRAKT), f.hub.accounts.accounts("p2").map { it.service })
        assertEquals("p2-token", f.tokens.load("p2", TRAKT)?.session?.accessToken)
        assertNull(f.tokens.load("p2", ANILIST))
        assertEquals(listOf(ANILIST), f.hub.accounts.accounts(f.profileId).map { it.service })
    }

    @Test
    fun disconnectingTheServiceCancelsItsSignInAndAnotherServicesDoesNot() = runTest {
        val f = fixture()
        val trakt = f.heldSignIn(TRAKT)
        val cancelled = async { f.hub.accounts.signIn(f.profileId, TRAKT) {} }
        f.advance(10.seconds)
        f.hub.accounts.disconnect(f.profileId, TRAKT)
        trakt.lookupGate!!.complete(Unit)
        assertNull(cancelled.await())
        assertNull(f.stored(TRAKT))

        f.connect(ANILIST)
        val simkl = f.heldSignIn(SIMKL)
        val kept = async { f.hub.accounts.signIn(f.profileId, SIMKL) {} }
        f.advance(10.seconds)
        f.hub.accounts.disconnect(f.profileId, ANILIST)
        simkl.lookupGate!!.complete(Unit)
        assertNotNull(kept.await())
        assertEquals(listOf(SIMKL), f.hub.accounts.accounts(f.profileId).map { it.service })
        assertEquals("granted", f.stored(SIMKL)?.accessToken)
    }

    @Test
    fun disconnectingDropsEverythingHereThenRevokesTheSession() = runTest {
        val f = fixture()
        f.connect(TRAKT)
        f.connect(ANILIST)
        f.queueWrite(TRAKT)
        f.queueWrite(ANILIST)
        f.hub.accounts.disconnect(f.profileId, TRAKT)
        assertEquals(listOf("a0"), f.providers.getValue(TRAKT).revoked.map { it.accessToken })
        assertEquals(listOf(ANILIST), f.hub.accounts.accounts(f.profileId).map { it.service }, "other services untouched")
        assertEquals(listOf("anilist anilist|movie|imdb=tt1 watched=true attempts=0"), f.queued())
        assertNull(f.stored(TRAKT))
        assertTrue(assertFailsWith<TrackerException.Auth> { f.tracker(TRAKT).credentials.accessToken() }.permanent, "the old binding is gone")

        // Nothing connected: nothing to drop or revoke.
        f.hub.accounts.disconnect(f.profileId, SIMKL)
        assertEquals(emptyList(), f.providers.getValue(SIMKL).revoked)
    }

    @Test
    fun aBindingLastsAsLongAsItsSignIn() = runTest {
        val f = fixture()
        f.connect(TRAKT)
        val first = f.hub.accounts.bindings(f.profileId).first().single()
        assertSame(first, f.hub.accounts.bindings(f.profileId).first().single())
        f.connect(TRAKT, TrackerSession("b0", "r", FAR_FUTURE, "sam", 2))
        val second = f.hub.accounts.bindings(f.profileId).first().single()
        assertNotSame(first, second)
        assertEquals("b0", second.credentials.accessToken())
        assertTrue(assertFailsWith<TrackerException.Auth> { first.credentials.accessToken() }.permanent)
    }

    @Test
    fun writesMadeWhileTheTokenCanNotBeRefreshedQueue() = runTest {
        val f = fixture()
        val refresher = f.refresher(TRAKT)
        f.connect(TRAKT, TrackerSession("a0", "r0", expiresAt = f.clock.now().epochSeconds + 60, username = "alex", createdAt = 1))
        f.advance(120.seconds)
        refresher.failure = TrackerException.Network(TRAKT, IllegalStateException("offline"))
        f.coordinator.watchMarks.mark(episodeItem("tt0903747", 1, 1), f.backend, true)
        f.drain()
        assertEquals(listOf("trakt trakt|s1e1|imdb=tt0903747 watched=true attempts=0"), f.queued(), "an expired token and no refresh: queued")
        assertEquals(emptyList(), f.calls(TRAKT))

        refresher.failure = null
        f.hub.onNetworkRestored()
        f.advance(30.seconds)
        assertEquals(listOf("watched tt0903747:1:1"), f.undated(TRAKT))
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun aConnectionGoneFromTheDatabaseTakesItsSessionWithIt() = runTest {
        val f = fixture()
        for (profile in listOf("kept", "gone")) f.hub.accounts.connect(profile, TRAKT, TrackerSession("a0", "r0", FAR_FUTURE, "alex", 1))
        f.settle()
        // Removed without the tracker accounts (the profile it belonged to deleted).
        f.data.trackerAccounts.disconnect("gone", TRAKT)
        f.settle()
        assertNull(f.tokens.load("gone", TRAKT))
        assertEquals("a0", f.tokens.load("kept", TRAKT)?.session?.accessToken)
        assertEquals(setOf("kept" to TRAKT), f.tokens.stored())
    }

    @Test
    fun aDeviceCodeSignInEndsWithoutAConnectionWhenDeclinedOrExpired() = runTest {
        val f = fixture()
        val shortGrant = DeviceCodeGrant("dc", "ABCD", "https://simkl.com/pin", expiresInSeconds = 20, intervalSeconds = 5)
        val declined = FakeDeviceCode(this, listOf(DevicePoll.Pending, DevicePoll.Denied), shortGrant)
        f.providers.getValue(SIMKL).deviceCode = declined
        val first = async { f.hub.accounts.signIn(f.profileId, SIMKL) {} }
        f.advance(60.seconds)
        assertNull(first.await())
        assertEquals(2, declined.polls.size)

        val unanswered = FakeDeviceCode(this, emptyList(), shortGrant)
        f.providers.getValue(SIMKL).deviceCode = unanswered
        val second = async { f.hub.accounts.signIn(f.profileId, SIMKL) {} }
        f.advance(60.seconds)
        assertNull(second.await())
        assertEquals(4, unanswered.polls.size, "polled until the code's 20 s were up")
        assertEquals(emptyList(), f.hub.accounts.accounts(f.profileId))
        assertTrue(f.store.memory.entries.isEmpty())
    }

    @Test
    fun aServiceWithoutAProviderIsNotOffered() = runTest {
        val f = TrackerFixture(this, services = listOf(TRAKT, SIMKL)).also { fixtures += it }
        assertEquals(listOf(TRAKT, SIMKL), f.hub.accounts.services)
        assertFailsWith<TrackerException.SignIn> { f.hub.accounts.signIn(f.profileId, ANILIST) {} }
    }
}
