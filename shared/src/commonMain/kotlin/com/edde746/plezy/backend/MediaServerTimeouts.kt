package com.edde746.plezy.backend

import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/** The time budgets every media-server call shares. */
object MediaServerTimeouts {
    val CONNECT: Duration = 10.seconds
    val RESPONSE: Duration = 30.seconds
    val RECEIVE: Duration = 120.seconds
    val HOME_HUB_DEADLINE: Duration = 15.seconds
    val LIBRARY_HUB_DEADLINE: Duration = 20.seconds
    val LIBRARY_LOOKUP: Duration = 20.seconds
    val SEARCH_SERVER_DEADLINE: Duration = 20.seconds
    val LIBRARY_LIST_SERVER_DEADLINE: Duration = 15.seconds
    val PREFERRED_ENDPOINT_PROBE: Duration = 1500.milliseconds
    val PREFERRED_ENDPOINT_HEAD_START: Duration = 300.milliseconds
    val CONNECTION_RACE: Duration = 2.seconds
    val PER_SERVER_CONNECT: Duration = 6500.milliseconds
    val NO_NETWORK_STARTUP_BIND: Duration = 2.seconds
    val TUNE: Duration = 30.seconds
    val TUNE_TRANSPORT: Duration = 3.minutes
    val PLEX_TV_CONNECT: Duration = 15.seconds
    val PLEX_TV_RECEIVE: Duration = 10.seconds
    val PLEX_PROBE: Duration = 8.seconds
    val JELLYFIN_PROBE: Duration = 8.seconds
    /** Whether the user may delete an item: Jellyfin's and Emby's per-item answer, Plex's Allow media deletion switch. */
    val DELETE_PERMISSION_PROBE: Duration = 3.seconds
    val DELETE_IMPACT_PROBE: Duration = 10.seconds
}
