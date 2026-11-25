package com.edde746.plezy.data

import com.edde746.plezy.data.db.Connections
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import com.edde746.plezy.secrets.MemorySecretStore
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFails

/** The schema's foreign keys hold on every platform's driver. */
class ForeignKeysTest {
    private val data = testData()
    private val bindings = ProfileConnectionRegistry(data, MemorySecretStore())

    @AfterTest
    fun close() = data.close()

    @Test
    fun aBindingToAConnectionThatIsGoneIsRefused() = runTest {
        assertFails { bindings.upsert(ProfileConnection("p1", "gone", null, "user")) }
        assertEquals(emptyList(), bindings.listAll())
    }

    @Test
    fun aSyncRuleLinkWithoutItsRuleIsRefused() = runTest {
        assertFails { data.db.write { q.syncRuleQueries.linkDownload(42, "p1", "server:1") } }
        assertEquals(emptyList(), data.db.read { syncRuleQueries.selectLinkedKeys(42).executeAsList() })
    }

    @Test
    fun removingAConnectionTakesItsBindings() = runTest {
        data.db.write { q.connectionQueries.insertRow(Connections("c1", "jellyfin", "{}", 1, null, null)) }
        bindings.upsert(ProfileConnection("p1", "c1", null, "user"))
        data.db.write { q.connectionQueries.deleteById("c1") }
        assertEquals(emptyList(), bindings.listAll())
    }
}
