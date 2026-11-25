package com.edde746.plezy.backend

import com.edde746.plezy.model.BackendKind
import kotlinx.serialization.json.JsonObject

/**
 * A signed-in account on a backend, as persisted: a Plex account (`plex.<accountUuid>`, all its servers) or one user
 * on one Jellyfin or Emby server (`<machineId>/<userId>`). [toConfigJson] is the stored config, secrets included; the
 * store keeps the secrets out of the database.
 */
interface Connection {
    val id: String
    val kind: BackendKind
    val displayName: String
    val displayLabel: String
    val displaySubtitle: String?

    /** Epoch ms. */
    val createdAt: Long

    /** Epoch ms. */
    val lastAuthenticatedAt: Long?

    fun toConfigJson(): JsonObject
}
