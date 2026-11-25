package com.edde746.plezy.seerr

import com.edde746.plezy.backend.net.MockServer
import com.edde746.plezy.profiles.plexHomeProfileId
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.secrets.SecretStore
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException

class SeerrAccountsTest {
    /**
     * A session as a local login was kept before permissions were read from `/auth/me`: the login body's permissions 0
     * and the email as the display name. No secret, so nothing can sign it in again.
     */
    private val stale = SeerrSession(
        baseUrl = BASE_URL,
        method = SeerrAuthMethod.LOCAL,
        identifier = "a@b.c",
        secret = "",
        cookie = "stored-cookie",
        userId = 7,
        permissions = 0,
        displayName = "a@b.c",
        instanceLabel = "Seerr",
        createdAt = 0,
    )

    /** The secret store with [stale] kept for [PROFILE] under the key the first-launch import writes too. */
    private fun storedStale() = MemorySecretStore().apply { entries["seerr_session.$PROFILE"] = stale.encode().encodeToByteArray() }

    private fun TestScope.accounts(server: MockServer, secrets: SecretStore) = SeerrAccounts(
        http = server.http,
        secrets = secrets,
        scope = backgroundScope,
        plexToken = { null },
        language = { "en" },
        clock = FixedClock,
        dispatcher = StandardTestDispatcher(testScheduler),
    )

    private suspend fun stored(secrets: SecretStore, profileId: String = PROFILE) = SeerrSessionStore(secrets).load(profileId)

    /**
     * Binds [PROFILE] and waits for its background `/auth/me` read by joining it (concurrent refreshes share one read),
     * then lets the saves it queued land. The HTTP client finishes part of a response off the test scheduler, so
     * advancing virtual time alone can't wait for a background request.
     */
    private suspend fun TestScope.bindAndRefresh(accounts: SeerrAccounts) {
        accounts.onActiveProfileChanged(PROFILE)
        accounts.refreshUser()
        advanceUntilIdle()
    }

    @Test
    fun aStoredSessionReReadsItsPermissionsFromAuthMeOnBind() = runTest {
        val secrets = storedStale()
        val server = MockServer(this) { request ->
            assertEquals(cookieHeader("stored-cookie"), request.cookie)
            json(user(SeerrPermission.REQUEST))
        }
        val accounts = accounts(server, secrets)

        accounts.onActiveProfileChanged(PROFILE)
        // The stored snapshot is bound at once; the refresh follows.
        assertEquals(0, accounts.session.value?.permissions)
        accounts.refreshUser()
        advanceUntilIdle()

        assertEquals(listOf("/api/v1/auth/me"), server.requests.map { it.path })
        assertEquals(SeerrPermission.REQUEST, accounts.session.value?.permissions)
        assertEquals("Alice", accounts.session.value?.displayName)
        assertEquals(SeerrPermission.REQUEST, accounts.client.value?.session?.permissions)
        assertEquals(SeerrPermission.REQUEST, stored(secrets)?.permissions)
        assertEquals("stored-cookie", stored(secrets)?.cookie)
    }

    @Test
    fun anUnreachableInstanceLeavesTheStoredSnapshotBound() = runTest {
        val secrets = storedStale()
        val accounts = accounts(MockServer(this) { throw IOException("connection refused") }, secrets)

        accounts.onActiveProfileChanged(PROFILE)
        advanceUntilIdle()

        assertEquals(0, accounts.session.value?.permissions)
        assertEquals(0, stored(secrets)?.permissions)
    }

    @Test
    fun aJson401FromAGatewayOnTheBindTimeRefreshKeepsTheStoredSession() = runTest {
        // Seerr never answers 401: the wall's JSON body is no verdict on the cookie.
        val secrets = storedStale()
        val server = MockServer(this) { json("""{"message":"Unauthorized"}""", 401) }
        val accounts = accounts(server, secrets)

        accounts.onActiveProfileChanged(PROFILE)
        advanceUntilIdle()

        assertEquals(listOf("/api/v1/auth/me"), server.requests.map { it.path }, "no re-login through the wall")
        assertEquals("stored-cookie", accounts.session.value?.cookie)
        assertEquals("stored-cookie", stored(secrets)?.cookie)
    }

    @Test
    fun aSeerr403OnTheBindTimeRefreshUnlinksOnceReauthHasNothingToOffer() = runTest {
        // Seerr's middleware refused the cookie and the session keeps no secret to sign in again with.
        val secrets = storedStale()
        val accounts = accounts(MockServer(this) { sessionGone() }, secrets)

        bindAndRefresh(accounts)

        assertNull(accounts.session.value)
        assertNull(accounts.client.value)
        assertNull(stored(secrets))
    }

    @Test
    fun forgettingTheActiveScopeEndsItsBindingAndALateRefreshKeepsNothing() = runTest {
        val secrets = storedStale().apply { entries["seerr_session.other"] = stale.encode().encodeToByteArray() }
        val answer = CompletableDeferred<Unit>()
        val server = MockServer(this) {
            answer.await()
            json(user(SeerrPermission.REQUEST))
        }
        val accounts = accounts(server, secrets)
        accounts.onActiveProfileChanged(PROFILE)
        val refresh = async { accounts.refreshUser() }
        runCurrent()

        accounts.forgetScopes(setOf(PROFILE))
        assertNull(accounts.session.value)
        assertNull(accounts.client.value)
        answer.complete(Unit)
        refresh.await()
        advanceUntilIdle()

        assertNull(accounts.session.value)
        assertNull(stored(secrets))
        assertEquals("stored-cookie", stored(secrets, "other")?.cookie)
    }

    @Test
    fun aCoalescedExplicitRefreshRecoversAGrantAndRejectsADifferentPrincipal() = runTest {
        val secrets = storedStale()
        val response = CompletableDeferred<Unit>()
        var calls = 0
        var userId = 7
        val server = MockServer(this) {
            calls++
            when (calls) {
                1 -> json("""{"id":7,"permissions":0}""")
                2 -> {
                    response.await()
                    json("""{"id":7,"permissions":${SeerrPermission.REQUEST}}""")
                }
                else -> json("""{"id":$userId,"permissions":0}""")
            }
        }
        val accounts = accounts(server, secrets)
        bindAndRefresh(accounts)

        val refreshes = listOf(async { accounts.refreshUser() }, async { accounts.refreshUser() })
        runCurrent()
        response.complete(Unit)
        refreshes.awaitAll()
        assertEquals(2, calls)
        assertEquals(SeerrPermission.REQUEST, accounts.session.value?.permissions)

        userId = 99
        accounts.refreshUser()
        assertEquals(SeerrPermission.REQUEST, accounts.session.value?.permissions)
        assertEquals(7, accounts.session.value?.userId)
        advanceUntilIdle()
        assertEquals(SeerrPermission.REQUEST, stored(secrets)?.permissions)
    }

    @Test
    fun anOldProfilesRefreshCannotAlterANewlyAdoptedAccountOrItsSavedCookie() = runTest {
        val secrets = storedStale()
        val response = CompletableDeferred<Unit>()
        val started = CompletableDeferred<Unit>()
        val server = MockServer(this) {
            started.complete(Unit)
            response.await()
            json(user(SeerrPermission.ADMIN))
        }
        val accounts = accounts(server, secrets)
        accounts.onActiveProfileChanged(PROFILE)
        started.await()

        accounts.onActiveProfileChanged("profile-2")
        assertNull(accounts.session.value)
        accounts.adoptSession(stale.copy(cookie = "new-account-cookie", permissions = SeerrPermission.REQUEST))
        response.complete(Unit)
        advanceUntilIdle()

        assertEquals("new-account-cookie", accounts.session.value?.cookie)
        assertEquals(SeerrPermission.REQUEST, accounts.session.value?.permissions)
        assertEquals("new-account-cookie", stored(secrets, "profile-2")?.cookie)
        assertEquals(0, stored(secrets)?.permissions)
    }

    @Test
    fun aRecreatedAccountStoreLoadsAfterTheClosedOneFinishesItsSave() = runTest {
        val secrets = DeferredPutSecretStore()
        val server = MockServer(this) { throw IOException("offline") }
        val old = accounts(server, secrets)
        old.onActiveProfileChanged(PROFILE)
        val save = async { old.adoptSession(stale.copy(cookie = "rotated-cookie", secret = "pass-rotated")) }
        secrets.started.await()
        old.close()

        val current = accounts(server, secrets)
        val load = async { current.onActiveProfileChanged(PROFILE) }
        runCurrent()
        secrets.release.complete(Unit)
        listOf(save, load).awaitAll()
        current.refreshUser()

        assertEquals("rotated-cookie", current.session.value?.cookie)
        assertEquals("pass-rotated", current.session.value?.secret)
        assertEquals("rotated-cookie", stored(secrets)?.cookie)
    }

    @Test
    fun disconnectClearsAfterADeferredAdoptionAndCannotResurrectItsSession() = runTest {
        val secrets = DeferredPutSecretStore()
        val accounts = accounts(MockServer(this) { throw IOException("offline") }, secrets)
        accounts.onActiveProfileChanged(PROFILE)
        val save = async { accounts.adoptSession(stale.copy(secret = "pass-deferred")) }
        secrets.started.await()
        val clear = async { accounts.disconnect() }
        runCurrent()
        secrets.release.complete(Unit)
        listOf(save, clear).awaitAll()

        assertNull(accounts.session.value)
        assertNull(stored(secrets))
    }

    @Test
    fun aRecreatedAccountStoresAdoptionSupersedesItsPendingLoadAndTheClosedOnesSave() = runTest {
        val secrets = DeferredPutSecretStore()
        val server = MockServer(this) { throw IOException("offline") }
        val old = accounts(server, secrets)
        old.onActiveProfileChanged(PROFILE)
        val oldSave = async { old.adoptSession(stale.copy(cookie = "old-binding-cookie", secret = "pass-old")) }
        secrets.started.await()
        old.close()

        val current = accounts(server, secrets)
        val load = async { current.onActiveProfileChanged(PROFILE) }
        val newSave = async { current.adoptSession(stale.copy(cookie = "new-binding-cookie", secret = "pass-new")) }
        runCurrent()
        secrets.release.complete(Unit)
        listOf(oldSave, load, newSave).awaitAll()

        assertEquals("new-binding-cookie", current.session.value?.cookie)
        assertEquals("pass-new", current.session.value?.secret)
        assertEquals("new-binding-cookie", stored(secrets)?.cookie)
        assertEquals("pass-new", stored(secrets)?.secret)
    }

    @Test
    fun disconnectForgetsTheSessionThenSignsOutWithItsCookie() = runTest {
        val secrets = storedStale()
        val server = MockServer(this) { request ->
            if (request.path == "/api/v1/auth/logout") throw IOException("offline") else json(user(0))
        }
        val accounts = accounts(server, secrets)
        accounts.onActiveProfileChanged(PROFILE)
        advanceUntilIdle()
        val client = accounts.client.value!!

        accounts.disconnect()

        assertNull(accounts.session.value)
        assertNull(accounts.client.value)
        assertNull(stored(secrets))
        assertEquals("/api/v1/auth/logout", server.requests.last().path)
        assertEquals(cookieHeader("stored-cookie"), server.requests.last().cookie)
        // The unbound client is done: a late caller holding it can't send as the forgotten session.
        assertTrue(runCatching { client.getMe() }.exceptionOrNull() is IllegalStateException)
    }

    @Test
    fun aClientChangeIsKeptAndPublishedWithoutANewClient() = runTest {
        val secrets = storedStale()
        var permissions = 0
        val accounts = accounts(MockServer(this) { json(user(permissions)) }, secrets)
        bindAndRefresh(accounts)
        val client = accounts.client.value

        permissions = SeerrPermission.REQUEST_ADVANCED
        accounts.refreshUser()
        advanceUntilIdle()

        assertSame(client, accounts.client.value)
        assertEquals(SeerrPermission.REQUEST_ADVANCED, accounts.session.value?.permissions)
        assertEquals(SeerrPermission.REQUEST_ADVANCED, stored(secrets)?.permissions)
    }

    @Test
    fun plexHomeProfilesOfOneUserShareTheirSession() = runTest {
        val secrets = MemorySecretStore()
        val accounts = accounts(MockServer(this) { throw IOException("offline") }, secrets)
        accounts.onActiveProfileChanged(plexHomeProfileId("account-1", HOME_USER))
        accounts.adoptSession(stale)

        assertTrue("seerr_session.$HOME_USER" in secrets.entries)
        accounts.onActiveProfileChanged(plexHomeProfileId("account-2", HOME_USER))
        assertEquals(stale, accounts.session.value)
    }

    @Test
    fun aProfileWithoutASessionOrNoProfileBindsNothing() = runTest {
        val secrets = storedStale()
        val accounts = accounts(MockServer(this) { json(user()) }, secrets)
        accounts.onActiveProfileChanged(PROFILE)
        assertEquals(stale, accounts.session.value)

        accounts.onActiveProfileChanged(null)
        assertNull(accounts.session.value)
        assertNull(accounts.client.value)
        accounts.onActiveProfileChanged("profile-without-seerr")
        assertNull(accounts.session.value)
    }

    @Test
    fun theStoredSessionIsTheProfilesSecretStoreEntry() = runTest {
        val secrets = MemorySecretStore()
        val store = SeerrSessionStore(secrets)
        store.save(PROFILE, stale.copy(secret = "pass-kept"))
        assertEquals(stale.copy(secret = "pass-kept"), SeerrSession.decode(secrets.entries.getValue("seerr_session.$PROFILE").decodeToString()))
        assertEquals(stale.copy(secret = "pass-kept"), store.load(PROFILE))

        // A value that doesn't decode reads as no session.
        secrets.entries["seerr_session.$PROFILE"] = """{"base_url":"x","method":"apiKey","user_id":1}""".encodeToByteArray()
        assertNull(store.load(PROFILE))

        store.clear(PROFILE)
        assertFalse("seerr_session.$PROFILE" in secrets.entries)
    }

    /** A secret store whose first write waits for [release] once it has [started]. */
    private class DeferredPutSecretStore(private val memory: MemorySecretStore = MemorySecretStore()) : SecretStore {
        val started = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()

        override suspend fun get(key: String): ByteArray? = memory.get(key)

        override suspend fun put(key: String, value: ByteArray) {
            if (!started.isCompleted) {
                started.complete(Unit)
                release.await()
            }
            memory.put(key, value)
        }

        override suspend fun delete(key: String) = memory.delete(key)

        override suspend fun deleteAll(prefix: String) = memory.deleteAll(prefix)
    }

    private companion object {
        const val PROFILE = "profile-1"
        const val HOME_USER = "0123456789abcdef"
    }
}
