package com.edde746.plezy.links

import com.edde746.plezy.app.AppServers
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.profiles.ProfileSwitchResult
import com.edde746.plezy.servers.OfflineWatchDownloads
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch
import kotlin.time.Duration

/**
 * The running app's `plezy://` links ([com.edde746.plezy.app.AppSession.links]): every platform hands each link it is
 * opened with to [open], and one queue ([DeepLinks]) delivers it.
 *
 * A link waits for a profile session: the active profile, once it is read and bound. A link naming a profile is
 * applied first: at startup the profiles' start activates it ([startupProfile]); later the switch asks for its PIN as
 * the profile picker does ([start]'s `pinPrompt`). What a link can't do (an invalid link, an unknown profile, a title
 * no server has) shows as [message] until the UI dismisses it.
 */
class AppLinks internal constructor(private val scope: CoroutineScope) {
    private val mutableMessage = MutableStateFlow<String?>(null)

    /** What a link couldn't do, for the UI to show (a snackbar) and then [dismissMessage]. */
    val message: StateFlow<String?> = mutableMessage.asStateFlow()

    private var returnFromExternalPlayer: suspend (String) -> Unit = {}

    private val queue = DeepLinks(scope, ::report, { returnFromExternalPlayer(it) })

    /** Whether a link is about to choose the profile: a profile picker must not ask over it. */
    val selectsProfile: Boolean get() = queue.selectsProfile

    /** Takes a link the OS handed the app. */
    fun open(url: String) = queue.receive(url)

    /** Clears [message] once the UI has shown [shown]. */
    fun dismissMessage(shown: String) {
        mutableMessage.compareAndSet(shown, null)
    }

    /** For the profiles' start: the profile a launch link names, unless it has a PIN to ask. */
    internal fun startupProfile(profiles: List<Profile>): Profile? = queue.claimStartupProfile(profiles) { !it.isPinProtected }

    internal fun settleStartupProfile(applied: Boolean) = queue.settleStartupProfile(applied)

    /**
     * Starts delivering links in the app over [servers]: profile switches through [servers]' profiles with
     * [pinPrompt], sessions following the active profile, play links resolved over its servers ([PlayLinkResolver]:
     * [downloads] for downloaded copies, no wait for a server while [isOffline], the connected Plex catalog
     * ([plexCatalog]) for a catalogue link's Plex GUID) and handed to [launch] once the screens are the profile's
     * ([screensFor]), external player returns to [externalPlayerReturn]. A link's profile switch first ends the video
     * playing ([stopPlayback]), so its last progress report goes out as the profile it played for.
     */
    internal fun start(
        servers: AppServers,
        downloads: OfflineWatchDownloads,
        isOffline: () -> Boolean,
        plexCatalog: () -> CatalogSource?,
        stopPlayback: () -> Unit,
        screensFor: suspend (profileId: String) -> Unit,
        launch: suspend (DeepLink, PlayLinkResolver) -> Unit,
        externalPlayerReturn: suspend (String) -> Unit,
    ) {
        val profiles = servers.profiles
        returnFromExternalPlayer = externalPlayerReturn
        queue.host = object : LinkProfiles {
            override val profiles: List<Profile> get() = profiles.profiles.value
            override val activeProfileId: String? get() = profiles.active.value?.id

            override suspend fun switchTo(profile: Profile): Boolean {
                stopPlayback()
                val prompt = profiles.pinPrompt ?: { _, _ -> null }
                return profiles.switchProfile(profile, prompt) == ProfileSwitchResult.SWITCHED
            }

            override suspend fun awaitScreens(profileId: String) = screensFor(profileId)
        }
        scope.launch {
            var session: LinkSession? = null
            combine(profiles.active, profiles.hydrated, profiles.bindState) { active, hydrated, bind ->
                active?.id?.takeIf { hydrated && !bind.binding }
            }.distinctUntilChanged().collect { profileId ->
                session?.let(queue::detach)
                session = profileId?.let { id ->
                    LinkSession(id) { link ->
                        val store = servers.store
                        val plex = plexCatalog()
                        val resolver = PlayLinkResolver(
                            PlayLinkSources(
                                clientFor = store::client,
                                isServerOnline = { store.state.value.isServerOnline(it) },
                                hasOnlineServers = { store.state.value.hasConnectedServers },
                                serversChanged = store.state,
                                findCatalogCopies = { target ->
                                    servers.aggregation.findByExternalIdsAcrossServers(
                                        target.ids,
                                        target.kind,
                                        store.state.value.expectedServerIds.toSet(),
                                        plexGuid = target.plexGuid,
                                    )
                                },
                                downloadedItem = { serverId: ServerId, itemId: String -> downloads.metadata(buildGlobalKey(serverId, itemId)) },
                                resolvePlexHash = if (plex == null) null else { target -> plex.resolveItemIds(target.kind, target.ids)?.plex },
                            ),
                            serverWait = if (isOffline()) Duration.ZERO else PlayLinkResolver.SERVER_WAIT,
                        )
                        launch(link, resolver)
                    }
                }
                session?.let(queue::attach)
            }
        }
    }

    /** Shows [failure] as what a play link couldn't do ([message]). */
    internal fun report(failure: PlayLinkFailure) = report(
        when (failure) {
            PlayLinkFailure.SERVER_UNAVAILABLE -> T.deepLinks.serverUnavailable
            PlayLinkFailure.NOT_FOUND -> T.deepLinks.notFound
            PlayLinkFailure.UNSUPPORTED_ITEM -> T.deepLinks.unsupportedItem
        },
    )

    /** Shows [message] ([AppLinks.message]): an invalid link, an unknown profile, a live channel not found. */
    internal fun report(message: String) {
        mutableMessage.value = message
    }
}
