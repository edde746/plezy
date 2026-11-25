package com.edde746.plezy.plex

/**
 * Who a Plex Media Server request comes from and where it goes. [headers] are the defaults of every request to the
 * server; per-request headers override them.
 */
data class PlexConfig(
    val baseUrl: String,
    val token: String?,
    val clientIdentifier: String,
    val version: String,
    /** The device identity's platform (`Android`, `iOS`, `tvOS`, `macOS`, `Windows`, `Linux`). */
    val platform: String,
    val product: String = PLEX_PRODUCT,
    /** Device model, header-sanitized. */
    val device: String? = null,
    /** Friendly device name, header-sanitized: Plex dashboards and Tautulli show it as the session's player. */
    val deviceName: String? = null,
    val machineIdentifier: String? = null,
    val languageCode: String? = null,
) {
    val headers: Map<String, String>
        get() = buildMap {
            put("X-Plex-Client-Identifier", clientIdentifier)
            put("X-Plex-Product", product)
            put("X-Plex-Version", version)
            put("X-Plex-Platform", platform)
            put("X-Plex-Client-Profile-Name", "Generic")
            device?.let { put("X-Plex-Device", it) }
            deviceName?.let { put("X-Plex-Device-Name", it) }
            put("Accept", "application/json")
            put("Accept-Charset", "utf-8")
            normalizedLanguageCode?.let {
                put("Accept-Language", it)
                put("X-Plex-Language", it)
            }
            token?.let { put("X-Plex-Token", it) }
        }

    private val normalizedLanguageCode: String?
        get() = languageCode?.trim()?.ifEmpty { null }
}
