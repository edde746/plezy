package com.edde746.plezy.profiles

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.testData
import com.edde746.plezy.data.withConnections
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

class ProfileConnectionRegistryConsistencyTest {
    private val data = testData(TestClock()).withConnections("c1")
    private val secrets = ControllableSecretStore()
    private val registry = ProfileConnectionRegistry(data, secrets)

    @AfterTest
    fun close() = data.close()

    /** Real time for a change started on another coroutine to get as far as it can. */
    private suspend fun letOthersRun() = withContext(Dispatchers.Default) { delay(100) }

    @Test
    fun concurrentUpsertsEndWithTheLaterOnesRowAndToken() = runTest {
        val held = secrets.holdNextPut()
        val first = launch { registry.upsert(ProfileConnection("p1", "c1", "token-a", "user-a")) }
        held.await()
        val second = launch { registry.upsert(ProfileConnection("p1", "c1", "token-b", "user-b")) }
        letOthersRun()
        secrets.release()
        joinAll(first, second)
        val stored = registry.get("p1", "c1")!!
        assertEquals("token-b" to "user-b", stored.userToken to stored.userIdentifier)
    }

    @Test
    fun anInvalidationAfterARecordingIsNotOvertakenByIt() = runTest {
        registry.upsert(ProfileConnection("p1", "c1", null, "user"))
        val held = secrets.holdNextPut()
        val record = launch { registry.recordToken("p1", "c1", "fresh") }
        held.await()
        val invalidate = launch { registry.invalidateToken("p1", "c1") }
        letOthersRun()
        secrets.release()
        joinAll(record, invalidate)
        val stored = registry.get("p1", "c1")!!
        assertNull(stored.userToken)
        assertNull(stored.tokenAcquiredAt)
    }

    @Test
    fun aSecretStoreFailureLeavesTheBindingAsItWas() = runTest {
        registry.upsert(ProfileConnection("p1", "c1", "old", "user-old"))
        secrets.failPutNumber = 1
        assertFailsWith<IllegalStateException> { registry.upsert(ProfileConnection("p1", "c1", "new", "user-new")) }
        val stored = registry.get("p1", "c1")!!
        assertEquals("old" to "user-old", stored.userToken to stored.userIdentifier)
        assertEquals(setOf("old"), secrets.tokens(), "the failed change's token went")
    }

    @Test
    fun anAppEndingAnywhereInAChangeLeavesTheUserWithTheTokenItWasStoredWith() = runTest {
        // The change puts the new token, commits, then deletes the old one; 2 is no crash.
        for (crashAt in 0..2) {
            val data = testData(TestClock()).withConnections("c1")
            val secrets = ControllableSecretStore()
            ProfileConnectionRegistry(data, secrets).upsert(ProfileConnection("p1", "c1", "old-token", "old-user"))
            secrets.crashAtOperation(crashAt)
            runCatching { ProfileConnectionRegistry(data, secrets).upsert(ProfileConnection("p1", "c1", "new-token", "new-user")) }

            secrets.restart()
            val restarted = ProfileConnectionRegistry(data, secrets)
            val expected = if (crashAt < 1) "old-token" to "old-user" else "new-token" to "new-user"
            val stored = restarted.get("p1", "c1")!!
            assertEquals(expected, stored.userToken to stored.userIdentifier, "crash at $crashAt")
            ConnectionStore(data, secrets).sweepUnreferencedSecrets()
            val swept = restarted.get("p1", "c1")!!
            assertEquals(expected, swept.userToken to swept.userIdentifier, "crash at $crashAt, swept")
            assertEquals(setOf(expected.first), secrets.tokens(), "crash at $crashAt: only the binding's own token is left")
            data.close()
        }
    }
}
