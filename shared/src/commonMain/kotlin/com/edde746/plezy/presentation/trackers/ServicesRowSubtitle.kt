package com.edde746.plezy.presentation.trackers

import com.edde746.plezy.data.tracker.TrackerAccount
import com.edde746.plezy.strings.T

/**
 * Settings' Services row subtitle: the names of the profile's connected trackers in the hub's order, joined by
 * " · "; the row's description while none is connected.
 */
internal fun servicesRowSubtitle(accounts: List<TrackerAccount>): String {
    val connected = accounts.mapTo(HashSet()) { it.service }
    val names = TrackerServicesStore.HUB_ORDER.filter { it in connected }.map(TrackerServicesStore::name)
    return if (names.isEmpty()) T.settings.servicesDescription else names.joinToString(" · ")
}
