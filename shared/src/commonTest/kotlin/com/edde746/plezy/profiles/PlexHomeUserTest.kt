package com.edde746.plezy.profiles

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class PlexHomeUserTest {
    private val user = PlexHomeUser(id = 1, uuid = "user-1", title = "Owner", thumb = "", admin = true)

    @Test
    fun theCacheFormatRoundTrips() {
        val encoded = encodePlexHomeUsers(listOf(user)).toString()
        assertEquals(
            """[{"id":1,"uuid":"user-1","title":"Owner","username":null,"email":null,"friendlyName":null,"thumb":"",""" +
                """"hasPassword":false,"restricted":false,"updatedAt":null,"admin":true,"guest":false,"protected":false}]""",
            encoded,
        )
        assertEquals(listOf(user), decodePlexHomeUsers(encoded))
    }

    @Test
    fun aCacheThatIsNotAListIsRejected() {
        assertFailsWith<IllegalArgumentException> { decodePlexHomeUsers("""{"uuid":"user-1"}""") }
    }

    @Test
    fun entriesThatAreNotObjectsAreSkipped() {
        val raw = "[null, 1, \"bad\", ${encodePlexHomeUsers(listOf(user)).toString().substring(1)}"
        assertEquals(listOf(user), decodePlexHomeUsers(raw))
    }

    @Test
    fun fieldsReadLeniently() {
        val raw = """[{"id":"12","uuid":42,"title":"Kid","thumb":null,"admin":"1","guest":1,"protected":"true","restricted":"no","updatedAt":"x"}]"""
        val decoded = decodePlexHomeUsers(Json.parseToJsonElement(raw).jsonArray).single()
        assertEquals(PlexHomeUser(id = 12, uuid = "42", title = "Kid", thumb = "", admin = true, guest = true, protected = true), decoded)
    }
}
