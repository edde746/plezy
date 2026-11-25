package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject

class JellyfinConnectionTest {
    private val base = JellyfinConnection(
        id = "srv-1/user-1",
        baseUrl = "https://jellyfin.example.com",
        baseUrls = listOf("https://jellyfin.example.com", "https://jellyfin.lan:8096"),
        serverName = "Home",
        serverMachineId = "srv-1",
        userId = "user-1",
        userName = "edde",
        accessToken = "tok-abc",
        deviceId = "dev-xyz",
        createdAt = 1_768_435_200_000,
        lastAuthenticatedAt = 1_777_075_200_000,
    )

    private fun restore(json: JsonObject, from: JellyfinConnection = base) =
        JellyfinConnection.fromConfigJson(from.id, json, from.createdAt, from.lastAuthenticatedAt)

    @Test fun roundTripPreservesEveryField() = assertEquals(base, restore(base.toConfigJson()))

    @Test fun configJsonKeysAreTheStoredShape() = assertEquals(
        listOf("baseUrl", "baseUrls", "serverName", "serverMachineId", "userId", "userName", "accessToken", "deviceId", "isAdministrator", "primaryImageTag"),
        base.toConfigJson().keys.toList(),
    )

    @Test fun primaryImageTagRoundTrips() = assertEquals("avatar-tag", restore(base.copy(primaryImageTag = "avatar-tag").toConfigJson()).primaryImageTag)

    @Test fun legacyConfigWithoutTagDecodesNull() =
        assertNull(restore(JsonObject(base.toConfigJson() - "primaryImageTag")).primaryImageTag)

    @Test fun blankTagsDecodeNull() = listOf("", " \t\n ").forEach {
        assertNull(restore(JsonObject(base.toConfigJson() + ("primaryImageTag" to JsonPrimitive(it)))).primaryImageTag)
    }

    @Test fun emptyPayloadUsesSafeDefaults() {
        val restored = JellyfinConnection.fromConfigJson("orphan", JsonObject(emptyMap()), 0)
        assertEquals("orphan", restored.id)
        assertEquals("", restored.baseUrl)
        assertTrue(restored.baseUrls.isEmpty())
        assertEquals("Jellyfin", restored.serverName)
        assertEquals("", restored.accessToken)
        assertEquals("Emby", JellyfinConnection.fromConfigJson("o", JsonObject(emptyMap()), 0, dialect = MediaBrowserDialect.EMBY).serverName)
    }

    @Test fun legacyBaseUrlBackfillsBaseUrls() {
        val restored = JellyfinConnection.fromConfigJson(
            "legacy",
            Json.parseToJsonElement("""{"baseUrl":"https://jellyfin.example.com","serverName":"Home","serverMachineId":"srv-1","userId":"user-1"}""").jsonObject,
            0,
        )
        assertEquals("https://jellyfin.example.com", restored.baseUrl)
        assertEquals(listOf("https://jellyfin.example.com"), restored.baseUrls)
    }

    @Test fun baseUrlFallsBackToFirstOfBaseUrls() = assertEquals(
        "https://a.example",
        JellyfinConnection.fromConfigJson("x", Json.parseToJsonElement("""{"baseUrls":["https://a.example","https://b.example"]}""").jsonObject, 0).baseUrl,
    )

    @Test fun activeBaseUrlMovesToFront() {
        val updated = base.copy(baseUrl = "https://jellyfin.lan:8096")
        assertEquals("https://jellyfin.lan:8096", updated.baseUrl)
        assertEquals(listOf("https://jellyfin.lan:8096", "https://jellyfin.example.com"), updated.baseUrls)
    }

    @Test fun urlsAreCanonicalizedAndDeduplicated() {
        val c = base.copy(baseUrl = "HTTPS://jellyfin.example.com/", baseUrls = listOf("https://jellyfin.example.com", "", "https://jellyfin.lan:8096/"))
        assertEquals(listOf("https://jellyfin.example.com", "https://jellyfin.lan:8096"), c.baseUrls)
    }

    @Test fun readsPrimaryImageTagDefensively() {
        fun dto(json: String) = Json.parseToJsonElement(json).jsonObject
        assertEquals("avatar-tag", JellyfinConnection.readPrimaryImageTag(dto("""{"PrimaryImageTag":"avatar-tag"}""")))
        assertNull(JellyfinConnection.readPrimaryImageTag(dto("{}")))
        assertNull(JellyfinConnection.readPrimaryImageTag(dto("""{"PrimaryImageTag":" \t\n "}""")))
        assertEquals("42", JellyfinConnection.readPrimaryImageTag(dto("""{"PrimaryImageTag":42}""")))
    }

    @Test fun dialectDrivesKind() {
        assertEquals(BackendKind.JELLYFIN, base.kind)
        val emby = base.copy(dialect = MediaBrowserDialect.EMBY)
        assertEquals(BackendKind.EMBY, emby.kind)
        assertEquals("emby", emby.kind.id)
    }

    @Test fun display() {
        assertEquals("edde · Home", base.displayName)
        assertEquals("Home", base.displayLabel)
        assertEquals("edde · https://jellyfin.example.com +1", base.displaySubtitle)
        val long = base.copy(baseUrl = "https://a-very-long-host-name.example.com/jellyfin", baseUrls = emptyList())
        assertEquals("edde · https://a-very-long-host-name.example…", long.displaySubtitle)
    }
}
