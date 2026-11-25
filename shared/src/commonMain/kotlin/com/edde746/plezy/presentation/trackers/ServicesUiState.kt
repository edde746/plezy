package com.edde746.plezy.presentation.trackers

import com.edde746.plezy.presentation.settings.trailingValueOf
import com.edde746.plezy.presentation.settings.valueSubtitleOf
import com.edde746.plezy.settings.TrackerLibraryFilterMode
import com.edde746.plezy.trackers.TrackerService

/**
 * Settings > Services and the screens under it: the hub's rows, the connect dialog while a sign-in waits, the
 * per-service settings of each connected service and each service's library filter.
 *
 * The hub lists [rows] (Trakt, MyAnimeList, AniList, Simkl, MDBList); the Seerr row, another feature's, follows them.
 */
data class ServicesUiState(
    val title: String,
    val subtitle: String,
    val rows: List<ServiceRowUi>,
    /** The connect dialog, while a sign-in waits for the user; it closes when the sign-in resolves or is cancelled. */
    val dialog: ConnectDialogUi? = null,
    /** A sign-in's link to open in the browser now (pointer input); the view opens it, then calls `urlOpened()`. */
    val openUrl: String? = null,
    /** A snackbar to show once (a failed sign-in); the view calls `messageShown()` after. */
    val message: String? = null,
    /** The settings of each connected service; a service missing here closes its settings screen. */
    val settings: List<TrackerSettingsUi> = emptyList(),
    /** Every service's library filter. */
    val filters: List<LibraryFilterUi> = emptyList(),
    /**
     * The Integrations group's Discord Rich Presence switch (`T.settings.discordRichPresence`), on or off; null where
     * the app doesn't speak to Discord, and the group is left out.
     */
    val discordPresence: Boolean? = null,
) {
    fun settings(service: TrackerService): TrackerSettingsUi? = settings.firstOrNull { it.service == service }

    fun filter(service: TrackerService): LibraryFilterUi? = filters.firstOrNull { it.service == service }
}

/**
 * A service's hub row. Tapping a [connected] row opens its settings; any other row starts the sign-in (nothing while
 * [busy]).
 */
data class ServiceRowUi(
    val service: TrackerService,
    val title: String,
    /** "Connected as @name", plain "Connected" when the service told no name, or "Not connected". */
    val subtitle: String,
    val connected: Boolean,
    val busy: Boolean,
)

/**
 * The dialog of a sign-in waiting for the user: a QR code of [url] and the [readableUrl] to type, plus a [DeviceCode]'s
 * code to enter there. [openLabel] opens [url] in the browser (not on Apple TV); [cancel] cancels the sign-in, as the
 * system back does.
 */
sealed interface ConnectDialogUi {
    val service: TrackerService
    val title: String
    val body: String

    /** What the QR code encodes, the open button opens and the URL copy copies. */
    val url: String

    /** The URL as shown: without its scheme and trailing slashes. */
    val readableUrl: String
    val openLabel: String
    val copyUrl: String
    val urlCopied: String
    val waiting: String
    val cancel: String

    /** Trakt, Simkl, MDBList: enter [userCode] at the readable URL, or scan [url] (prefilled where the service can). */
    data class DeviceCode(
        override val service: TrackerService,
        override val title: String,
        override val body: String,
        override val url: String,
        override val readableUrl: String,
        override val openLabel: String,
        override val copyUrl: String,
        override val urlCopied: String,
        override val waiting: String,
        override val cancel: String,
        val userCode: String,
        val copyCode: String,
        val codeCopied: String,
    ) : ConnectDialogUi

    /** MyAnimeList, AniList: open (or scan) the relay's link and sign in there. */
    data class Link(
        override val service: TrackerService,
        override val title: String,
        override val body: String,
        override val url: String,
        override val readableUrl: String,
        override val openLabel: String,
        override val copyUrl: String,
        override val urlCopied: String,
        override val waiting: String,
        override val cancel: String,
    ) : ConnectDialogUi
}

/** A connected service's settings screen. */
data class TrackerSettingsUi(
    val service: TrackerService,
    val title: String,
    val accountTitle: String,
    val accountSubtitle: String?,
    /** Simkl's "Reconnect" row under the account, while the connection uses the sign-in Simkl is retiring. */
    val reconnect: ReconnectRowUi?,
    val behaviorTitle: String,
    val toggles: List<TrackerToggleUi>,
    val libraryFilterTitle: String,
    /** What the filter syncs ("Syncing all libraries", "3 blocked"): beside the title while short, else under it. */
    val libraryFilterValue: String,
    val disconnect: String,
    /** The destructive confirmation the disconnect row asks first. */
    val disconnectConfirm: DisconnectConfirmUi,
) {
    val libraryFilterTrailingValue: String? get() = trailingValueOf(libraryFilterValue)
    val libraryFilterSubtitle: String? get() = valueSubtitleOf(libraryFilterValue, null)
}

data class ReconnectRowUi(val title: String, val subtitle: String)

enum class TrackerToggle {
    /** The service's scrobbling (`enable_<service>_scrobble`). */
    SCROBBLE,

    /** Trakt's watched-state sync (`enable_trakt_watched_sync`). */
    WATCHED_SYNC,
}

data class TrackerToggleUi(val toggle: TrackerToggle, val title: String, val subtitle: String, val on: Boolean)

data class DisconnectConfirmUi(val title: String, val body: String, val confirm: String, val cancel: String)

/**
 * A service's library filter screen: the [hint] for the mode, the mode control and one switch per library ([groups]),
 * on when the library is in the filter list in either mode. A toggle is kept at once.
 */
data class LibraryFilterUi(
    val service: TrackerService,
    val title: String,
    val hint: String,
    val modeTitle: String,
    val modes: List<FilterModeUi>,
    /** The libraries by server, titled by server only when there is more than one; one untitled-by-server group else. */
    val groups: List<LibraryGroupUi>,
    /** "No libraries", shown in the libraries group when there is none. */
    val empty: String?,
)

data class FilterModeUi(val mode: TrackerLibraryFilterMode, val label: String, val selected: Boolean)

data class LibraryGroupUi(val title: String, val libraries: List<LibrarySwitchUi>)

data class LibrarySwitchUi(val globalKey: String, val title: String, val on: Boolean)
