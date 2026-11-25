package com.edde746.plezy.plex

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PlexHomeTest {
    private fun obj(text: String) = Json.parseToJsonElement(text).jsonObject

    @Test
    fun `home users parse drifted scalar shapes 1488`() {
        val home = PlexHome.fromJson(
            obj(
                """{"id":"12","users":[
                  {"id":"5","uuid":"u1","title":"Kid","admin":0,"protected":"1","restricted":"true","updatedAt":"1700000000"},
                  {"id":7,"uuid":"u2","title":"Owner","friendlyName":"  ","admin":true,"guest":1},
                  {"title":42}
                ]}""",
            ),
        )
        assertEquals(12, home.id)
        val kid = home.users[0]
        assertEquals(5, kid.id)
        assertTrue(kid.protected)
        assertTrue(kid.restricted)
        assertEquals(1_700_000_000L, kid.updatedAt)
        assertEquals("Owner", home.users[1].displayName)
        assertTrue(home.users[1].admin)
        assertEquals(0, home.users[2].id)
        assertEquals("42", home.users[2].title)
        assertEquals("", home.users[2].uuid)
        assertEquals(emptyList(), PlexHome.fromJson(obj("""{"id":1}""")).users)
    }

    @Test
    fun `display name prefers a non blank friendly name then title else unknown`() {
        assertEquals("Friend", PlexHomeUser(id = 1, uuid = "u", title = "T", friendlyName = "Friend").displayName)
        assertNull(PlexHomeUser(id = 1, uuid = "u", title = " ").displayName)
    }

    @Test
    fun `home user json round trips`() {
        val user = PlexHomeUser(id = 3, uuid = "u", title = "T", email = "e", thumb = "th", admin = true, updatedAt = 9)
        assertEquals(user, PlexHomeUser.fromJson(user.toJson()))
        val home = PlexHome(1, listOf(user))
        assertEquals(home, PlexHome.fromJson(home.toJson()))
    }

    @Test
    fun `switch reads only a non empty authToken`() {
        assertEquals("tok", parsePlexSwitchAuthToken(obj("""{"authToken":"tok","id":"drift","subscription":[]}""")))
        assertFailsWith<IllegalArgumentException> { parsePlexSwitchAuthToken(obj("""{"authToken":""}""")) }
        assertFailsWith<IllegalArgumentException> { parsePlexSwitchAuthToken(obj("""{"authToken":5}""")) }
    }

    @Test
    fun `library section ids come from query strings paths and plain numbers`() {
        assertEquals(2, plexLibrarySectionIdFromString("/hubs/home/recentlyAdded?type=2&sectionID=2"))
        assertEquals(3, plexLibrarySectionIdFromString("/library/sections/3/all?genre=5"))
        assertEquals(7, plexLibrarySectionIdFromString("7"))
        assertEquals(9, plexLibrarySectionIdFromString("/hubs/sections/all?librarySectionID=9"))
        assertNull(plexLibrarySectionIdFromString("shared"))
        assertNull(plexLibrarySectionIdFromString(null))
        assertNull(plexLibrarySectionIdFromString("/hubs/home/recentlyAdded?type=1"))
        assertEquals(4, plexLibrarySectionIdFromJson(obj("""{"targetLibrarySectionID":"4","key":"/library/sections/8"}""")))
        assertEquals(8, plexLibrarySectionIdFromJson(obj("""{"key":"/library/sections/8/all"}""")))
    }
}
