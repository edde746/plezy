package com.edde746.plezy.app

import com.edde746.plezy.net.PlezyHttpClient
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.HttpSend
import io.ktor.client.plugins.plugin
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import io.ktor.util.AttributeKey
import kotlinx.io.IOException

/**
 * The session's HTTP client: with `--dev-plex fixture`, plex.tv answered from recorded responses (a new PIN that is
 * never claimed, so the sign-in waits on its code; `expired`: one plex.tv no longer knows, so it expires as it is
 * first checked) and every other host refused; otherwise the product's. While the session holds the device offline
 * (`offline=true`, [holdDevOffline]) every request fails as it does without a network.
 */
fun DevLaunch.httpClient(appVersion: String): HttpClient {
    val client = plex?.let(::recordedPlexTv) ?: PlezyHttpClient.create(appVersion)
    client.plugin(HttpSend).intercept { request ->
        if (client.attributes.getOrNull(HELD_OFFLINE) == true) throw IOException("${request.url.host}: no network (held offline)")
        execute(request)
    }
    return client
}

/** Holds the session's requests offline ([held]) or lets them out again, as [DevLaunch.httpClient] made the client. */
internal fun HttpClient.holdDevOffline(held: Boolean) {
    attributes.put(HELD_OFFLINE, held)
}

private val HELD_OFFLINE = AttributeKey<Boolean>("DevHeldOffline")

/** `--dev-plex <fixture|expired>`: where plex.tv's answers come from, and whether its PINs expire. */
enum class DevPlex { FIXTURE, EXPIRED }

private fun recordedPlexTv(plex: DevPlex): HttpClient = HttpClient(MockEngine) {
    engine {
        addHandler { request ->
            val json = headersOf(HttpHeaders.ContentType, "application/json")
            val path = request.url.encodedPath
            when {
                request.url.host != "plex.tv" -> respond("", HttpStatusCode.ServiceUnavailable)
                request.method == HttpMethod.Post && path == "/api/v2/pins" ->
                    respond(if (request.url.parameters["strong"] == "true") PIN_CREATED else SHORT_PIN_CREATED, HttpStatusCode.Created, json)
                plex == DevPlex.EXPIRED -> respond("", HttpStatusCode.NotFound)
                request.method == HttpMethod.Get && path == "/api/v2/pins/$PIN_ID" -> respond(PIN_WAITING, HttpStatusCode.OK, json)
                request.method == HttpMethod.Get && path == "/api/v2/pins/$SHORT_PIN_ID" -> respond(SHORT_PIN_CREATED, HttpStatusCode.OK, json)
                else -> respond("", HttpStatusCode.NotFound)
            }
        }
    }
}

private const val PIN_ID = 2_103_465_201
private const val SHORT_PIN_ID = 1_013_914_539

// plex.tv's answers to `POST /api/v2/pins?strong=true` and `GET /api/v2/pins/{id}` before the PIN is claimed, recorded
// with this app's product name and a made-up client identifier.
private const val PIN_CREATED = """{"id":$PIN_ID,"code":"8pm7hgxk4fb2vwbn5bwjrn6k1","product":"Plezy","trusted":false,"qr":"https://plex.tv/api/v2/pins/qr/8pm7hgxk4fb2vwbn5bwjrn6k1","clientIdentifier":"6f1c2b9e-4d3a-4e8f-9b7c-1a2d3e4f5a6b","location":{"code":"SE","european_union_member":true,"continent_code":"EU","country":"Sweden","city":"Stockholm","time_zone":"Europe/Stockholm","postal_code":"111 20","in_privacy_restricted_country":false,"in_privacy_restricted_region":false,"subdivisions":"Stockholm","coordinates":"59.3293, 18.0686"},"expiresIn":1800,"createdAt":"2026-11-06T12:00:00Z","expiresAt":"2026-11-06T12:30:00Z","authToken":null,"newRegistration":null}"""
private const val PIN_WAITING = PIN_CREATED

// plex.tv's answer to `POST /api/v2/pins?strong=false` (the same before the PIN is claimed), recorded likewise.
private const val SHORT_PIN_CREATED = """{"id":$SHORT_PIN_ID,"code":"6TWW","product":"Plezy","trusted":false,"qr":"https://plex.tv/api/v2/pins/qr/6TWW","clientIdentifier":"6f1c2b9e-4d3a-4e8f-9b7c-1a2d3e4f5a6b","location":{"code":"SE","european_union_member":true,"continent_code":"EU","country":"Sweden","city":"Stockholm","time_zone":"Europe/Stockholm","postal_code":"111 20","in_privacy_restricted_country":false,"in_privacy_restricted_region":false,"subdivisions":"Stockholm","coordinates":"59.3293, 18.0686"},"expiresIn":900,"createdAt":"2026-11-14T11:10:01Z","expiresAt":"2026-11-14T11:25:01Z","authToken":null,"newRegistration":null}"""

/** `--dev-entry`: where the session enters ([DevLaunch.entry]). */
enum class DevEntry { MAIN, BOOT }
