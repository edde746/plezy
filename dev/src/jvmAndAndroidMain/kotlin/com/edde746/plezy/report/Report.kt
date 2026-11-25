package com.edde746.plezy.report

import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.RootScreen
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.presentation.navigation.Route
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * The test report's fields, which the test harnesses read: what Android's debug and harness builds (logcat lines) and
 * the desktop harness (report.json samples) write, so both apps report one name and one shape for each. Each platform
 * keeps its own envelope and puts these objects in it under the key each function names ([name]: the screens' names,
 * [stored]: the device's settings). A null value is written as JSON null.
 */
object Report {
    /** `home`, `libraries`, `liveTv`, …, `catalogDetail`, `player`, `settings.<page>`: [route]'s name in `screen` and `backStack` (spelled out: R8 renames classes). */
    fun name(route: Route): String = when (route) {
        Route.Home -> "home"
        Route.Libraries -> "libraries"
        Route.LiveTv -> "liveTv"
        is Route.LiveTvShowSchedule -> "liveTvShowSchedule"
        Route.Explore -> "explore"
        Route.Search -> "search"
        Route.SyncRules -> "syncRules"
        Route.Settings -> "settings"
        Route.Services -> "services"
        is Route.TrackerSettings -> "trackerSettings.${route.service.id}"
        is Route.TrackerLibraryFilter -> "trackerLibraryFilter.${route.service.id}"
        Route.WatchTogether -> "watchTogether"
        is Route.SettingsPage -> "settings.${route.page.name.lowercase()}"
        Route.Player -> "player"
        Route.SignIn -> "signIn"
        is Route.ProfilePicker -> "profilePicker"
        Route.AddProfile -> "addProfile"
        is Route.ProfileDetail -> "profileDetail"
        is Route.AddConnection -> "addConnection"
        is Route.AddPlexAccount -> "addPlexAccount"
        is Route.AddMediaBrowser -> "addMediaBrowser"
        is Route.EditConnection -> "editConnection"
        is Route.BorrowConnection -> "borrowConnection"
        Route.NowPlaying -> "nowPlaying"
        is Route.MusicArtist -> "musicArtist"
        is Route.MusicAlbum -> "musicAlbum"
        is Route.MusicPlaylist -> "musicPlaylist"
        is Route.MediaDetail -> "mediaDetail"
        is Route.Person -> "person"
        is Route.CollectionDetail -> "collectionDetail"
        is Route.CatalogDetail -> "catalogDetail"
        is Route.CatalogSearch -> "catalogSearch"
        is Route.ExploreRow -> "exploreRow"
        is Route.SeerrPerson -> "seerrPerson"
        Route.SeerrConnect -> "seerrConnect"
        Route.SeerrSettings -> "seerrSettings"
        is Route.SeerrRequest -> "seerrRequest"
        is Route.MetadataEdit -> "metadataEdit"
        is Route.PlexMatch -> "plexMatch"
        is Route.HubDetail -> "hubDetail"
        is Route.PlaylistDetail -> "playlistDetail"
    }

    /**
     * `servers`: the active profile's name, how many servers are online and the libraries they offer, by title: what a
     * sign-in brought in.
     */
    fun servers(app: AppSession): JsonObject = obj(
        "profile" to app.profiles.active.value?.displayName,
        "online" to app.servers.store.state.value.onlineServerCount,
        "libraries" to app.servers.libraries.state.value.libraries.map { it.title },
    )

    /** `starting`, `failed`, `main`: the root's screen, the `screen` while no route is on top. */
    fun name(screen: RootScreen): String = when (screen) {
        RootScreen.Starting -> "starting"
        is RootScreen.Failed -> "failed"
        is RootScreen.Main -> "main"
    }

    /** `stored`: what the database holds as the [device]'s settings. */
    fun stored(device: DeviceSettings): JsonObject = obj(
        "hardwareDecoding" to device.hardwareDecoding, "hdr" to device.hdr, "matchFrameRate" to device.matchFrameRate,
        "audioPassthrough" to device.audioPassthrough, "cacheSizeMegabytes" to device.cacheSizeMegabytes,
        "discordPresence" to device.discordPresence, "crashReports" to device.crashReports,
    )
}

/**
 * A report value as JSON: null, a JSON element, a string, number or boolean, a map (its keys as text, in its order), an
 * iterable, or anything else as its text (an envelope's event detail can carry any value).
 */
fun toJson(value: Any?): JsonElement = when (value) {
    null -> JsonNull
    is JsonElement -> value
    is String -> JsonPrimitive(value)
    is Number -> JsonPrimitive(value)
    is Boolean -> JsonPrimitive(value)
    is Map<*, *> -> JsonObject(value.entries.associate { (k, v) -> k.toString() to toJson(v) })
    is Iterable<*> -> JsonArray(value.map(::toJson))
    else -> JsonPrimitive(value.toString())
}

private fun obj(vararg fields: Pair<String, Any?>): JsonObject = JsonObject(fields.associate { (k, v) -> k to toJson(v) })
