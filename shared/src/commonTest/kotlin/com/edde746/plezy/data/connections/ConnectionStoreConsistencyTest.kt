package com.edde746.plezy.data.connections

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.profiles.ControllableSecretStore
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

class ConnectionStoreConsistencyTest {
    private val data = testData(TestClock())
    private val secrets = ControllableSecretStore()
    private val store = ConnectionStore(data, secrets)

    @AfterTest
    fun close() = data.close()

    private fun jellyfin(token: String, userName: String = "edde") = StoredConnection(
        "machine/user",
        BackendKind.JELLYFIN,
        Json.parseToJsonElement("""{"baseUrl":"https://jellyfin.local","userName":"$userName","accessToken":"$token"}""").jsonObject,
        1_000,
    )

    private fun plex(accountToken: String, serverToken: String, label: String = "Plex") = StoredConnection(
        "plex.a",
        BackendKind.PLEX,
        Json.parseToJsonElement(
            """{"accountToken":"$accountToken","accountLabel":"$label",""" +
                """"servers":[{"name":"Server","clientIdentifier":"srv","accessToken":"$serverToken","connections":[{"protocol":"https","address":"10.0.0.2","port":32400,"uri":"https://10-0-0-2.example.invalid:32400","local":true,"relay":false,"IPv6":false}]}]}""",
        ).jsonObject,
        1_000,
    )

    private suspend fun letOthersRun() = withContext(Dispatchers.Default) { delay(100) }

    @Test
    fun aChangedTokenAloneFailsTheValidatedWrite() = runTest {
        val validated = jellyfin("token-a")
        store.upsert(validated)
        store.upsert(jellyfin("token-rotated"))
        val failure = assertFailsWith<IllegalStateException> { store.upsert(jellyfin("token-a", userName = "renamed"), expected = validated) }
        assertEquals("The connection changed after validation.", failure.message)
        assertEquals(jellyfin("token-rotated").config, store.get("machine/user")!!.config)
    }

    @Test
    fun concurrentUpsertsEndWithTheLaterOnesConfigurationAndTokens() = runTest {
        val held = secrets.holdNextPut()
        val first = launch { store.upsert(plex("account-1", "server-1")) }
        held.await()
        val second = launch { store.upsert(plex("account-2", "server-2", label = "Second")) }
        letOthersRun()
        secrets.release()
        joinAll(first, second)
        assertEquals(plex("account-2", "server-2", label = "Second").config, store.get("plex.a")!!.config)
        assertEquals(setOf("account-2", "server-2"), secrets.tokens())
    }

    @Test
    fun aSecretStoreFailureLeavesTheConnectionAsItWas() = runTest {
        val original = plex("account-1", "server-1")
        store.upsert(original)
        // The second upsert's account token is put 2, its server token put 3.
        secrets.failPutNumber = 3
        assertFailsWith<IllegalStateException> { store.upsert(plex("account-2", "server-2", label = "Changed")) }
        assertEquals(original, store.get("plex.a"))
        assertEquals(setOf("account-1", "server-1"), secrets.tokens(), "the failed change's tokens went")
    }

    @Test
    fun anAppEndingAnywhereInAChangeLeavesTheConnectionWithTheTokensItWasStoredWith() = runTest {
        val old = plex("account-1", "server-1", label = "Old")
        val new = plex("account-2", "server-2", label = "New")
        // The change puts the two new tokens, commits, then deletes the two old ones; 4 is no crash.
        for (crashAt in 0..4) {
            val data = testData(TestClock())
            val secrets = ControllableSecretStore()
            ConnectionStore(data, secrets).upsert(old)
            secrets.crashAtOperation(crashAt)
            runCatching { ConnectionStore(data, secrets).upsert(new) }

            secrets.restart()
            val restarted = ConnectionStore(data, secrets)
            val (expected, tokens) = if (crashAt < 2) old to setOf("account-1", "server-1") else new to setOf("account-2", "server-2")
            assertEquals(expected, restarted.get("plex.a"), "crash at $crashAt")
            restarted.sweepUnreferencedSecrets()
            assertEquals(expected, restarted.get("plex.a"), "crash at $crashAt, swept")
            assertEquals(tokens, secrets.tokens(), "crash at $crashAt: only the row's own tokens are left")
            data.close()
        }
    }

    @Test
    fun anAppEndingWhileARemovalDeletesTokensLeavesNoRowAndTheStartDeletesTheRest() = runTest {
        // The removal commits, then deletes the account, server and binding tokens; 3 is no crash.
        for (crashAt in 0..3) {
            val data = testData(TestClock())
            val secrets = ControllableSecretStore()
            ConnectionStore(data, secrets).upsert(plex("account-1", "server-1"))
            ProfileConnectionRegistry(data, secrets).upsert(ProfileConnection("p1", "plex.a", "user-token", "home"))
            secrets.crashAtOperation(crashAt)
            runCatching { ConnectionStore(data, secrets).remove("plex.a") }

            secrets.restart()
            val restarted = ConnectionStore(data, secrets)
            assertNull(restarted.get("plex.a"), "crash at $crashAt")
            assertEquals(emptyList(), ProfileConnectionRegistry(data, secrets).listAll(), "crash at $crashAt")
            restarted.sweepUnreferencedSecrets()
            assertEquals(emptySet(), secrets.tokens(), "crash at $crashAt")
            data.close()
        }
    }
}
