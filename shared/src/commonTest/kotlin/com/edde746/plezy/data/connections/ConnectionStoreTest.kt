package com.edde746.plezy.data.connections

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.secrets.SecretStore
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ConnectionStoreTest {
    private val data = testData(TestClock())
    private val secrets = MemorySecretStore()
    private val store = ConnectionStore(data, secrets)

    @AfterTest
    fun close() = data.close()

    private fun config(json: String) = Json.parseToJsonElement(json).jsonObject

    private fun jellyfin(id: String = "srv-1", createdAt: Long = 1_000_000, kind: BackendKind = BackendKind.JELLYFIN, token: String = "tok-$id") =
        StoredConnection(
            id,
            kind,
            config(
                """{"baseUrl":"https://jellyfin.local","baseUrls":["https://jellyfin.local"],"serverName":"Home",""" +
                    """"serverMachineId":"machine-$id","userId":"user-$id","userName":"edde","accessToken":"$token",""" +
                    """"deviceId":"dev-1","isAdministrator":false,"primaryImageTag":null}""",
            ),
            createdAt,
        )

    private fun plex(id: String = "plex-1") = StoredConnection(
        id,
        BackendKind.PLEX,
        config(
            """{"accountToken":"tok-$id","clientIdentifier":"cid-$id","accountLabel":"me@example.com","activeProfile":null,""" +
                """"servers":[{"name":"Server","clientIdentifier":"server-$id","accessToken":"server-token-$id",""" +
                """"connections":[{"protocol":"https","address":"plex.example.com","port":443,"uri":"https://plex.example.com",""" +
                """"local":false,"relay":false,"IPv6":false}],"owned":true,"product":null,"platform":null,"lastSeenAt":null}]}""",
        ),
        1_000_000,
        2_000_000,
    )

    @Test
    fun anUpsertedConnectionRoundTrips() = runTest {
        assertEquals(emptyList(), store.list())
        val connection = plex("p")
        store.upsert(connection)
        store.upsert(jellyfin("j"))
        store.upsert(jellyfin("e", kind = BackendKind.EMBY))
        assertEquals(connection, store.get("p"))
        assertEquals(BackendKind.EMBY, store.get("e")!!.kind)
        assertEquals(mapOf("p" to "plex", "j" to "jellyfin", "e" to "emby"), data.db.read { connectionQueries.selectAll().executeAsList() }.associate { it.id to it.kind })
    }

    @Test
    fun tokensAreInTheSecretStoreNotInSqlite() = runTest {
        store.upsert(plex("p"))
        store.upsert(jellyfin("j"))
        store.upsert(jellyfin("e", kind = BackendKind.EMBY, token = "emby-raw-token"))
        val raw = data.db.read { connectionQueries.selectAll().executeAsList() }.joinToString { it.config_json }
        listOf("tok-p", "server-token-p", "tok-j", "emby-raw-token").forEach { assertFalse(it in raw, "$it reached the database") }
        assertEquals(setOf("tok-p", "server-token-p", "tok-j", "emby-raw-token"), tokens())
        assertEquals(JsonPrimitive("emby-raw-token"), store.get("e")!!.config["accessToken"])
    }

    private fun tokens(): Set<String> = secrets.entries.values.map { it.decodeToString() }.toSet()

    @Test
    fun anImportedRowsUnversionedTokenIsReadThenReplaced() = runTest {
        data.db.write {
            q.connectionQueries.insertRow(com.edde746.plezy.data.db.Connections("j", "jellyfin", """{"baseUrl":"https://jellyfin.local"}""", 1, null, null))
        }
        secrets.put("connection.j.token", "imported".encodeToByteArray())
        assertEquals(JsonPrimitive("imported"), store.get("j")!!.config["accessToken"])

        store.upsert(jellyfin("j", token = "fresh"))

        assertEquals(JsonPrimitive("fresh"), store.get("j")!!.config["accessToken"])
        assertEquals(setOf("fresh"), tokens(), "the imported token went once nothing named it")
    }

    @Test
    fun aRowThatDoesNotDecodeIsLeftOut() = runTest {
        store.upsert(jellyfin("good"))
        data.db.write { q.connectionQueries.insertRow(com.edde746.plezy.data.db.Connections("bad", "plex", "not json", 1, null, null)) }
        data.db.write { q.connectionQueries.insertRow(com.edde746.plezy.data.db.Connections("odd", "betamax", "{}", 1, null, null)) }
        assertEquals(listOf("good"), store.list().map { it.id })
    }

    @Test
    fun aPlexAccountWhoseServerLacksARequiredFieldIsLeftOutBesideAValidSibling() = runTest {
        store.upsert(jellyfin("good"))
        val valid = plex("p")
        val nameless = JsonObject((valid.config["servers"] as JsonArray).single().jsonObject - "name")
        store.upsert(valid.copy(id = "nameless", config = JsonObject(valid.config + ("servers" to JsonArray(listOf(nameless))))))
        assertEquals(listOf("good"), store.list().map { it.id })
        assertNull(store.get("nameless"))
    }

    @Test
    fun upsertingAgainKeepsTheCreationOrder() = runTest {
        store.upsert(jellyfin("first", createdAt = 1_000_000))
        store.upsert(jellyfin("second", createdAt = 2_000_000))
        store.upsert(jellyfin("first", createdAt = 9_000_000))
        val list = store.list()
        assertEquals(listOf("first", "second"), list.map { it.id })
        assertEquals(1_000_000, list.first().createdAt)
    }

    @Test
    fun aNewConnectionKeepsTheCreationTimeItWasBuiltWith() = runTest {
        store.upsert(jellyfin("a", createdAt = 5_000_000))
        assertEquals(5_000_000, store.list().single().createdAt)
    }

    @Test
    fun connectionsListByCreationTimeWhateverOrderTheyWereStoredIn() = runTest {
        store.upsert(jellyfin("late", createdAt = 3_000_000))
        store.upsert(jellyfin("early", createdAt = 1_000_000))
        store.upsert(jellyfin("middle", createdAt = 2_000_000))
        assertEquals(listOf("early", "middle", "late"), store.list().map { it.id })
    }

    @Test
    fun anExpectedConfigurationThatChangedRefusesTheWrite() = runTest {
        val validated = jellyfin("a")
        store.upsert(validated)
        val edited = jellyfin("a", token = "new")
        store.upsert(jellyfin("a", token = "rotated"))
        val failure = assertFailsWith<IllegalStateException> { store.upsert(edited, expected = validated) }
        assertEquals("The connection changed after validation.", failure.message)
        assertEquals(JsonPrimitive("rotated"), store.get("a")!!.config["accessToken"])
        store.upsert(edited, expected = store.get("a"))
        assertEquals(JsonPrimitive("new"), store.get("a")!!.config["accessToken"])
        assertFailsWith<IllegalStateException> { store.upsert(jellyfin("missing"), expected = jellyfin("missing")) }
    }

    @Test
    fun aDroppedServerTakesItsTokenWithIt() = runTest {
        val connection = plex("p")
        store.upsert(connection)
        store.upsert(connection.copy(config = JsonObject(connection.config + ("servers" to Json.parseToJsonElement("[]")))))
        assertEquals(setOf("tok-p"), tokens())
    }

    @Test
    fun removeDropsTheConnectionItsBindingsAndTheirTokens() = runTest {
        val bindings = ProfileConnectionRegistry(data, secrets)
        store.upsert(plex("a"))
        store.upsert(jellyfin("b"))
        bindings.upsert(ProfileConnection("p1", "a", "user-token", "home"))
        bindings.upsert(ProfileConnection("p1", "b", "jf-token", "user-b"))
        store.remove("a")
        assertEquals(listOf("b"), store.list().map { it.id })
        assertEquals(listOf("b"), bindings.listAll().map { it.connectionId })
        assertTrue(bindings.listForProfile("p1").single().isDefault, "the profile's remaining binding is its default")
        assertEquals(setOf("tok-b", "jf-token"), tokens())
        store.clear()
        assertEquals(emptyList(), store.list())
        assertEquals(emptyList(), bindings.listAll())
        assertTrue(secrets.entries.isEmpty())
    }

    @Test
    fun `summaries follow changes and read no token`() = runTest {
        val counted = object : SecretStore by secrets {
            var reads = 0

            override suspend fun get(key: String): ByteArray? {
                reads++
                return secrets.get(key)
            }
        }
        val store = ConnectionStore(data, counted)
        store.upsert(plex("p"))
        store.upsert(jellyfin("j"))
        val readsBefore = counted.reads

        val summaries = store.observeSummaries().first()
        assertEquals(readsBefore, counted.reads, "a summary read a token")
        assertEquals(
            setOf(
                ConnectionSummary("p", BackendKind.PLEX, mapOf("server-p" to "Server")),
                ConnectionSummary("j", BackendKind.JELLYFIN, mapOf("machine-j" to "Home")),
            ),
            summaries.toSet(),
        )

        store.remove("j")
        assertEquals(listOf("p"), store.observeSummaries().first().map { it.id })
        assertEquals(readsBefore, counted.reads)
    }
}
