package com.edde746.plezy.seerr

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.int

class SeerrModelsTest {
    @Test
    fun parsesThePageInfoPaginationShape() {
        val page = SeerrPage.fromJson(jsonObject("""{"pageInfo":{"page":2,"pages":2,"totalResults":55},"results":[{"id":1}]}""")) {
            it.getValue("id").let { id -> (id as JsonPrimitive).int }
        }
        assertFalse(page.hasMore)
        assertEquals(listOf(1), page.items)
        assertEquals(55, page.totalResults)
    }

    @Test
    fun parsesTheTmdbPaginationShape() {
        val page = SeerrPage.fromJson(jsonObject("""{"page":1,"totalPages":4,"totalResults":80,"results":[{"id":1},"junk",{"id":2}]}""")) {
            it.getValue("id").toString()
        }
        assertTrue(page.hasMore)
        assertEquals(listOf("1", "2"), page.items)
        assertEquals(80, page.totalResults)
    }

    @Test
    fun adminImpliesEverythingOtherwiseAnyOfApplies() {
        assertTrue(SeerrPermission.has(SeerrPermission.ADMIN, SeerrPermission.REQUEST_4K))
        assertFalse(SeerrPermission.has(SeerrPermission.REQUEST, SeerrPermission.REQUEST_4K))
        assertTrue(SeerrPermission.has(SeerrPermission.REQUEST_MOVIE, SeerrPermission.REQUEST, SeerrPermission.REQUEST_MOVIE))
    }

    @Test
    fun canRequestHonorsThePerKindPermissionSplit() {
        assertTrue(SeerrPermission.canRequest(SeerrPermission.REQUEST, movie = true))
        assertTrue(SeerrPermission.canRequest(SeerrPermission.REQUEST, movie = false))
        assertTrue(SeerrPermission.canRequest(SeerrPermission.REQUEST_MOVIE, movie = true))
        assertFalse(SeerrPermission.canRequest(SeerrPermission.REQUEST_MOVIE, movie = false))
        assertTrue(SeerrPermission.canRequest(SeerrPermission.REQUEST_TV, movie = false))
        assertFalse(SeerrPermission.canRequest(SeerrPermission.REQUEST_TV, movie = true))
        assertFalse(SeerrPermission.canRequest(SeerrPermission.REQUEST_4K, movie = true))
    }

    @Test
    fun aSessionRoundTripsThroughEncodeAndDecode() {
        assertEquals(session(), SeerrSession.decode(session().encode()))
        assertEquals(
            jsonObject(
                """{"base_url":"https://seerr.example.com","method":"jellyfin","identifier":"alice","secret":"hunter2",
                "cookie":"old-cookie","user_id":7,"permissions":2,"display_name":"Alice","instance_label":"Seerr",
                "product":"unknown","created_at":0}""",
            ),
            session().toJson(),
        )
    }

    @Test
    fun theProductRoundTripsAndALegacyPayloadDecodesAsUnknown() {
        assertEquals(SeerrProduct.JELLYSEERR, SeerrSession.decode(session(product = SeerrProduct.JELLYSEERR).encode()).product)
        // Sessions kept before the product was recorded have no `product`: the conservative unknown.
        val legacy = JsonObject(session(product = SeerrProduct.OVERSEERR).toJson() - "product")
        assertEquals(SeerrProduct.UNKNOWN, SeerrSession.fromJson(legacy).product)
    }

    @Test
    fun aStoredSessionWithAnUnknownMethodOrNoUserDoesNotDecode() {
        assertFailsWith<IllegalArgumentException> { SeerrSession.fromJson(JsonObject(session().toJson() + ("method" to JsonPrimitive("apiKey")))) }
        assertFailsWith<IllegalArgumentException> { SeerrSession.fromJson(JsonObject(session().toJson() - "user_id")) }
        assertFailsWith<IllegalArgumentException> { SeerrSession.decode("not json") }
        // Optional fields default as the earlier releases wrote them.
        val minimal = SeerrSession.decode("""{"base_url":"https://s.example","method":"quickConnect","user_id":3}""")
        assertEquals(SeerrSession("https://s.example", SeerrAuthMethod.QUICK_CONNECT, "", "", "", 3, 0, "", "", SeerrProduct.UNKNOWN, 0), minimal)
    }

    @Test
    fun aSessionsTextLeavesTheCookieAndSecretOut() {
        val text = session().toString()
        assertFalse("old-cookie" in text || "hunter2" in text, text)
    }

    @Test
    fun codes1To5DecodeIdenticallyForEveryProduct() {
        for (product in SeerrProduct.entries) {
            assertEquals(SeerrMediaStatus.UNKNOWN, SeerrMediaStatus.resolve(1, product), "$product")
            assertEquals(SeerrMediaStatus.PENDING, SeerrMediaStatus.resolve(2, product), "$product")
            assertEquals(SeerrMediaStatus.PROCESSING, SeerrMediaStatus.resolve(3, product), "$product")
            assertEquals(SeerrMediaStatus.PARTIALLY_AVAILABLE, SeerrMediaStatus.resolve(4, product), "$product")
            assertEquals(SeerrMediaStatus.AVAILABLE, SeerrMediaStatus.resolve(5, product), "$product")
        }
    }

    @Test
    fun codes6And7DecodePerProductAndAnUnknownProductStaysConservative() {
        // Overseerr: DELETED=6, 7 unused. Jellyseerr: BLOCKLISTED=6, DELETED=7.
        assertEquals(SeerrMediaStatus.DELETED, SeerrMediaStatus.resolve(6, SeerrProduct.OVERSEERR))
        assertEquals(SeerrMediaStatus.UNKNOWN, SeerrMediaStatus.resolve(7, SeerrProduct.OVERSEERR))
        assertEquals(SeerrMediaStatus.BLOCKLISTED, SeerrMediaStatus.resolve(6, SeerrProduct.JELLYSEERR))
        assertEquals(SeerrMediaStatus.DELETED, SeerrMediaStatus.resolve(7, SeerrProduct.JELLYSEERR))
        // A session that doesn't know its product: never available, never requestable, whichever product answers.
        assertEquals(SeerrMediaStatus.BLOCKLISTED, SeerrMediaStatus.resolve(6, SeerrProduct.UNKNOWN))
        assertEquals(SeerrMediaStatus.BLOCKLISTED, SeerrMediaStatus.resolve(7, SeerrProduct.UNKNOWN))
    }

    @Test
    fun nullAndUnrecognizedCodesDecodeAsUnknown() {
        assertEquals(SeerrMediaStatus.UNKNOWN, SeerrMediaStatus.resolve(null, SeerrProduct.JELLYSEERR))
        assertEquals(SeerrMediaStatus.UNKNOWN, SeerrMediaStatus.resolve(99, SeerrProduct.OVERSEERR))
    }

    @Test
    fun decodesAllFiveRequestCodesAndFallsBackToPending() {
        assertEquals(SeerrRequestStatus.PENDING, SeerrRequestStatus.fromCode(1))
        assertEquals(SeerrRequestStatus.APPROVED, SeerrRequestStatus.fromCode(2))
        assertEquals(SeerrRequestStatus.DECLINED, SeerrRequestStatus.fromCode(3))
        assertEquals(SeerrRequestStatus.FAILED, SeerrRequestStatus.fromCode(4))
        assertEquals(SeerrRequestStatus.COMPLETED, SeerrRequestStatus.fromCode(5))
        // An unknown code reads as requested: conservative, it blocks re-submission.
        assertEquals(SeerrRequestStatus.PENDING, SeerrRequestStatus.fromCode(6))
        assertEquals(SeerrRequestStatus.PENDING, SeerrRequestStatus.fromCode(null))
    }

    @Test
    fun mediaTitlesFallBackPastBlankTranslationsAndYearsComeFromTheDate() {
        val show = SeerrMedia.fromJson(jsonObject("""{"id":1,"name":" ","originalName":"Dark","firstAirDate":"2017-12-01","originCountry":["DE"]}"""))
        assertEquals("Dark", show.displayTitle)
        assertEquals(2017, show.year)
        assertEquals("Dark", show.displayOriginalTitle)
        assertEquals(listOf("DE"), show.originCountry)
        assertEquals("", SeerrMedia.fromJson(jsonObject("""{"id":2,"title":""}""")).displayTitle)
        assertEquals(null, SeerrMedia.fromJson(jsonObject("""{"id":3,"releaseDate":"20"}""")).year)
    }
}
