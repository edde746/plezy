package com.edde746.plezy.plex.tv

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.plex.PlexConnection
import com.edde746.plezy.plex.PlexHomeUser
import com.edde746.plezy.plex.PlexServer
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PlexAccountConnectionTest {
    private val base = PlexAccountConnection(
        id = "plex.client-uuid",
        accountToken = "token-xyz",
        clientIdentifier = "client-uuid",
        accountLabel = "edde",
        servers = emptyList(),
        activeProfile = null,
        createdAt = 1_768_435_200_000,
        lastAuthenticatedAt = 1_777_075_200_000,
    )

    private val server = PlexServer(
        name = "Home Server",
        clientIdentifier = "srv-1",
        accessToken = "server-token",
        connections = listOf(
            PlexConnection("https", "203.0.113.5", 32400, "https://203-0-113-5.machine.plex.direct:32400", local = false, relay = false, ipv6 = false),
        ),
        owned = true,
    )

    @Test
    fun `toConfigJson and fromConfigJson round trip preserves identity fields`() {
        val restored = PlexAccountConnection.fromConfigJson(base.id, base.toConfigJson(), base.createdAt, base.lastAuthenticatedAt)

        assertEquals(base, restored)
        assertTrue(restored.servers.isEmpty())
        assertNull(restored.activeProfile)
    }

    @Test
    fun `round trip keeps the active profile and servers`() {
        val connection = base.copy(activeProfile = PlexHomeUser(id = 2, uuid = "kid-uuid", title = "Kid"), servers = listOf(server))

        assertEquals(connection, PlexAccountConnection.fromConfigJson(connection.id, connection.toConfigJson(), connection.createdAt, connection.lastAuthenticatedAt))
    }

    @Test
    fun `config json has the stored schema`() {
        assertEquals(
            setOf("accountToken", "clientIdentifier", "accountLabel", "activeProfile", "servers"),
            base.toConfigJson().keys,
        )
    }

    @Test
    fun `fromConfigJson with empty payload uses safe defaults no NPE`() {
        val restored = PlexAccountConnection.fromConfigJson("orphan", JsonObject(emptyMap()), createdAt = 1)

        assertEquals("orphan", restored.id)
        assertEquals("", restored.accountToken)
        assertEquals("", restored.clientIdentifier)
        assertEquals("Plex", restored.accountLabel)
        assertNull(restored.activeProfile)
        assertTrue(restored.servers.isEmpty())
    }

    @Test
    fun `fromConfigJson skips mistyped profile and non object servers`() {
        val json = Json.parseToJsonElement(
            """{"accountToken":"t","activeProfile":"kid","servers":[1,"x",${server.toJson()}]}""",
        ).jsonObject

        val restored = PlexAccountConnection.fromConfigJson("plex.a", json, createdAt = 1)

        assertNull(restored.activeProfile)
        assertEquals(listOf("srv-1"), restored.servers.map { it.clientIdentifier })
        assertTrue(PlexAccountConnection.fromConfigJson("plex.a", Json.parseToJsonElement("""{"servers":{}}""").jsonObject, 1).servers.isEmpty())
    }

    @Test
    fun `kind and backend match Plex`() {
        assertEquals(BackendKind.PLEX, base.kind)
    }

    @Test
    fun `display name names the active profile with a title subtitle counts servers`() {
        assertEquals("edde", base.displayName)
        assertEquals("edde", base.copy(activeProfile = PlexHomeUser(id = 2, uuid = "u", title = "")).displayName)
        val kid = base.copy(activeProfile = PlexHomeUser(id = 2, uuid = "u", title = "Kid"))
        assertEquals("Kid · edde", kid.displayName)
        assertEquals("Kid · edde", kid.displayLabel)
        assertEquals("0 Plex servers", base.displaySubtitle)
        assertEquals("1 Plex server", base.copy(servers = listOf(server)).displaySubtitle)
        assertEquals("2 Plex servers", base.copy(servers = listOf(server, server)).displaySubtitle)
    }

    @Test
    fun `registration keys the account by uuid and labels it username email then Plex`() = runTest {
        suspend fun build(info: String, keyByAccountUuid: Boolean = true) = buildPlexAccountConnection(
            token = "tok",
            clientIdentifier = "client-uuid",
            now = 42,
            fetchUserInfo = { Json.parseToJsonElement(info).jsonObject },
            fetchServers = { listOf(server) },
            keyByAccountUuid = keyByAccountUuid,
        ).connection

        val named = build("""{"uuid":" acct-1 ","username":"edde","email":"e@x"}""")
        assertEquals("plex.acct-1", named.id)
        assertEquals("edde", named.accountLabel)
        assertEquals("tok", named.accountToken)
        assertEquals(listOf(server), named.servers)
        assertEquals(42, named.createdAt)
        assertEquals(42, named.lastAuthenticatedAt)
        assertEquals("e@x", build("""{"uuid":"acct-1","email":"e@x"}""").accountLabel)
        assertEquals("Plex", build("""{"uuid":"acct-1"}""").accountLabel)
        assertEquals("plex.client-uuid", build("""{"uuid":"  "}""").id)
        assertEquals("plex.client-uuid", build("""{"uuid":"acct-1"}""", keyByAccountUuid = false).id)
    }

    @Test
    fun `registration falls back to the client identifier when user info fails unless told not to`() = runTest {
        val failing: suspend (String) -> JsonObject = { throw IllegalStateException("plex.tv down") }

        val build = buildPlexAccountConnection("tok", "client-uuid", 1, failing, { emptyList() })
        assertEquals("plex.client-uuid", build.connection.id)
        assertEquals("Plex", build.connection.accountLabel)
        assertEquals("", build.accountUuid)

        assertFailsWith<IllegalStateException> {
            buildPlexAccountConnection("tok", "client-uuid", 1, failing, { emptyList() }, tolerateUserInfoFailure = false)
        }
        assertFailsWith<IllegalStateException> {
            buildPlexAccountConnection("tok", "client-uuid", 1, { JsonObject(emptyMap()) }, { throw IllegalStateException("no servers") })
        }
    }
}
