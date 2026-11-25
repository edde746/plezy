package com.edde746.plezy.profiles

import com.edde746.plezy.backend.Connection
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.plex.tv.PlexAccountConnection

/** The Plex account this row stores, or null for a Jellyfin/Emby row. */
fun StoredConnection.plexAccount(): PlexAccountConnection? =
    if (kind == BackendKind.PLEX) PlexAccountConnection.fromConfigJson(id, config, createdAt, lastAuthenticatedAt) else null

/** The Jellyfin/Emby user this row stores (its dialect from the row's kind), or null for a Plex row. */
fun StoredConnection.mediaBrowser(): JellyfinConnection? =
    kind.dialect?.let { JellyfinConnection.fromConfigJson(id, config, createdAt, lastAuthenticatedAt, it) }

/** [this] as a row to store. */
fun Connection.stored(): StoredConnection = StoredConnection(id, kind, toConfigJson(), createdAt, lastAuthenticatedAt)
