package com.edde746.plezy.jellyfin

import com.edde746.plezy.net.UriComponent

/**
 * The `MediaBrowser` Authorization header both dialects read. Every value is percent-encoded (the server decodes it):
 * a device name like `Bjørn PC` cannot travel verbatim, and quotes, commas and `=` have no escape in the grammar.
 * Client, device and version need non-empty values to open a session, so they fall back; an empty device id or
 * token is omitted.
 */
object JellyfinAuthHeader {
    private val CONTROL = Regex("[\\u0000-\\u001f\\u007f-\\u009f]")

    fun build(clientName: String, clientVersion: String, deviceName: String, deviceId: String, accessToken: String? = null): String {
        val client = meaningful(clientName).ifEmpty { "Plezy" }
        val device = meaningful(deviceName).ifEmpty { client }
        val id = meaningful(deviceId)
        val token = meaningful(accessToken.orEmpty())
        val parts = buildList {
            add(field("Client", client))
            add(field("Device", device))
            if (id.isNotEmpty()) add(field("DeviceId", id))
            add(field("Version", meaningful(clientVersion).ifEmpty { "1.0" }))
            if (token.isNotEmpty()) add(field("Token", token))
        }
        return "MediaBrowser " + parts.joinToString(", ")
    }

    /**
     * `Plezy {platform}` the way first-party apps name themselves (`Jellyfin Android TV`): sessions carry no platform
     * field, so dashboards keyword-match this string.
     */
    fun clientName(platform: String, isTv: Boolean): String {
        val p = meaningful(platform)
        if (p.isEmpty()) return "Plezy"
        if (isTv && p.lowercase() == "android") return "Plezy Android TV"
        return "Plezy $p"
    }

    /** The user-facing device name, else the hardware model, else the platform, else `Plezy`. */
    fun deviceName(platform: String, deviceModel: String? = null, deviceName: String? = null): String =
        listOfNotNull(deviceName, deviceModel, platform).map(::meaningful).firstOrNull { it.isNotEmpty() } ?: "Plezy"

    /**
     * The stable device id unauthenticated session creation needs. Never substituted: both dialects key sessions and
     * tokens by it, so a shared placeholder would collide across installs.
     */
    fun requireDeviceId(deviceId: String): String {
        require(deviceId.isNotEmpty() && deviceId == deviceId.trim() && deviceId.all { it.code in 0x20..0x7E } && '"' !in deviceId) {
            "deviceId must be a non-empty HTTP-safe value"
        }
        return deviceId
    }

    private fun field(name: String, value: String) = name + "=\"" + UriComponent.encode(value) + "\""

    private fun meaningful(value: String) = value.replace(CONTROL, "").trim()
}

/** What the server sees of this install: the header's client, device and version, and the app-wide device id. */
data class JellyfinDeviceIdentity(
    val clientName: String,
    val deviceName: String,
    val clientVersion: String,
    /** The app-wide client identifier (UUID v4, generated once). */
    val deviceId: String,
) {
    fun authorization(accessToken: String? = null) =
        JellyfinAuthHeader.build(clientName, clientVersion, deviceName, deviceId, accessToken)
}
