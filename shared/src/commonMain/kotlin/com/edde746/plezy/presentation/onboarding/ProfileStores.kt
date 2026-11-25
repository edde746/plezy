package com.edde746.plezy.presentation.onboarding

import com.edde746.plezy.backend.MediaServerUrlException
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.jellyfin.JellyfinEndpointDiscovery
import com.edde746.plezy.jellyfin.prepareMediaBrowserEndpoints
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.BorrowCandidate
import com.edde746.plezy.profiles.BorrowResult
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.PlexHomeProfile
import com.edde746.plezy.profiles.PlexHomeUser
import com.edde746.plezy.profiles.PostRemovalOutcome
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import com.edde746.plezy.profiles.ProfileRemoval
import com.edde746.plezy.profiles.ProfileServices
import com.edde746.plezy.profiles.ProfileSwitchResult
import com.edde746.plezy.profiles.groupConnectionsByProfile
import com.edde746.plezy.profiles.mediaBrowser
import com.edde746.plezy.profiles.plexAccount
import com.edde746.plezy.profiles.resolveProfileAvatarUrls
import com.edde746.plezy.profiles.stored
import com.edde746.plezy.profiles.verifyProfilePin
import com.edde746.plezy.profiles.visibleProfileConnections
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import io.ktor.client.HttpClient
import com.edde746.plezy.links.DeepLink
import com.edde746.plezy.links.linkProfileRef
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch

/** A connection under a profile's name: its backend's badge and its label. */
data class ConnectionChip(val backend: BackendKind, val label: String)

/** What a profile tile's menu offers. */
enum class ProfileAction { MANAGE, SHOW_LINK, DELETE, SIGN_OUT }

/**
 * A profile in the picker. [active]: the current one (not in a required pick), drawn with Active and not tappable;
 * [locked]: a PIN guards it; [hasConnections] false shows "No connections" in the error colour.
 */
data class ProfileTileUi(
    val id: String,
    val name: String,
    val avatarUrl: String?,
    val active: Boolean,
    val locked: Boolean,
    val chips: List<ConnectionChip>,
    val hasConnections: Boolean,
    val actions: List<ProfileAction>,
)

/** A question before a destructive step; the UIs show it as a dialog, with a switch when it has a [toggle]. */
data class ConfirmUi(val title: String, val message: String, val confirmLabel: String, val toggle: ConfirmToggle? = null)

/** A confirmation's switch ([ConfirmUi.toggle]), off at first; confirming answers with whether it's [checked]. */
data class ConfirmToggle(val title: String, val description: String, val checked: Boolean = false)

/**
 * The profile picker ([Route.ProfilePicker]): [loading] until the profiles are read, then the tiles (empty: No profiles
 * available) and Add profile. [switching] covers it with "Switching profile…" once the switch is past its PIN.
 * [message] is a snackbar to show once ([ProfilePickerStore.messageShown]); [confirm] a dialog.
 */
data class ProfilePickerUiState(
    val required: Boolean,
    /** Opened to manage the profiles ([Route.ProfilePicker.manage]). */
    val manage: Boolean = false,
    val loading: Boolean = true,
    val tiles: List<ProfileTileUi> = emptyList(),
    val switching: Boolean = false,
    val message: String? = null,
    val confirm: ConfirmUi? = null,
    /** The link that switches to a profile ("Show profile link"), as a QR code and text; null while none shows. */
    val link: ProfileLinkUi? = null,
) {
    /**
     * "Who's watching?" over a required pick (the app's start, which the pick opens on); Manage profiles, the label of
     * the row and menu entry that open it to manage them; else Switch Profile (Settings' profile card).
     */
    val title: String
        get() = when {
            required -> T.profiles.whosWatching
            manage -> T.profiles.manageProfiles
            else -> T.screens.switchProfile
        }
}

/** A profile's `plezy://open` link and what opening it does ([com.edde746.plezy.strings.T]'s `deepLinks.profileHint`). */
data class ProfileLinkUi(val url: String, val hint: String = T.deepLinks.profileHint)

/**
 * The profile picker. A tap switches (a PIN asked through [pins]); a required pick can't be left except by leaving
 * the app. Manage and Delete of another PIN-protected local profile ask its PIN first; Sign out removes a Plex account
 * with its Home users. Every action is off while switching and in a required pick.
 */
class ProfilePickerStore(
    private val route: Route.ProfilePicker,
    private val profiles: ProfileServices,
    private val removal: ProfileRemoval,
    connections: ConnectionStore,
    bindings: ProfileConnectionRegistry,
    private val pins: PinPrompter,
    private val host: AccountsHost,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(ProfilePickerUiState(required = route.required, manage = route.manage))
    private var pendingConfirm: (suspend (toggled: Boolean) -> Unit)? = null
    private var byId: Map<String, Profile> = emptyMap()
    private var storedById: Map<String, StoredConnection> = emptyMap()
    private val selecting = MutableStateFlow(false)

    /**
     * The tiles' order as a switch began, kept once it succeeds: the profile switched to, now the one used last, would
     * otherwise jump to the front under "Switching profile…" before the picker closes.
     */
    private var switchOrder: List<String>? = null

    val state: StateFlow<ProfilePickerUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            combine(
                profiles.profiles,
                profiles.active,
                profiles.hydrated,
                combine(connections.observe(), bindings.observeAll(), profiles.plexHomeUsers, ::Triple),
                profileSwitchBusy(selecting, profiles, pins),
            ) { all, active, hydrated, (stored, rows, homeUsers), switching ->
                byId = all.associateBy { it.id }
                val tiles = all.map { tile(it, active, stored, rows, homeUsers) }
                Triple(!hydrated, tiles, switching)
            }.collect { (loading, tiles, switching) ->
                val ordered = switchOrder?.let { ids -> tiles.sortedBy { tile -> ids.indexOf(tile.id).takeIf { it >= 0 } ?: ids.size } } ?: tiles
                mutableState.value = mutableState.value.copy(loading = loading, tiles = ordered, switching = switching)
            }
        }
    }

    /** Switches to profile [id]; on success the picker closes (a required pick enters the app). */
    fun select(id: String) {
        val profile = byId[id] ?: return
        if (selecting.value || (profile.id == profiles.active.value?.id && !route.required)) return
        selecting.value = true
        switchOrder = mutableState.value.tiles.map { it.id }
        scope.launch {
            val result = try {
                profiles.switchProfile(profile, pins::ask)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Switching to ${profile.id} failed" }
                ProfileSwitchResult.FAILED
            } finally {
                selecting.value = false
            }
            if (result != ProfileSwitchResult.SWITCHED) switchOrder = null
            mutableState.value = mutableState.value.copy(
                message = if (result == ProfileSwitchResult.FAILED) T.errors.failedToSwitchProfile(profile.displayName) else null,
            )
            if (result == ProfileSwitchResult.SWITCHED) host.profileChosen(route)
        }
    }

    fun act(id: String, action: ProfileAction) {
        val profile = byId[id] ?: return
        if (mutableState.value.switching || route.required) return
        scope.launch {
            when (action) {
                ProfileAction.MANAGE -> if (verifyForAction(profile)) host.open(Route.ProfileDetail(profile.id))
                ProfileAction.SHOW_LINK -> mutableState.value = mutableState.value.copy(link = ProfileLinkUi(DeepLink.Open(linkProfileRef(profile)).toUrl()))
                ProfileAction.DELETE -> if (verifyForAction(profile)) {
                    ask(ConfirmUi(T.profiles.deleteThisProfileTitle, T.profiles.deleteThisProfileMessage(profile.displayName), T.profiles.delete)) {
                        deleteProfile(removal, profiles, profile, host) { mutableState.value = mutableState.value.copy(message = it) }
                    }
                }
                ProfileAction.SIGN_OUT -> {
                    val parent = profile.parentConnectionId ?: return@launch
                    signOutPlexConfirm(parent)
                }
            }
        }
    }

    fun confirm() {
        val action = pendingConfirm ?: return
        val toggled = mutableState.value.confirm?.toggle?.checked == true
        pendingConfirm = null
        mutableState.value = mutableState.value.copy(confirm = null)
        scope.launch { action(toggled) }
    }

    /** Turns the open confirmation's switch on or off. */
    fun setConfirmToggle(checked: Boolean) {
        val confirm = mutableState.value.confirm ?: return
        val toggle = confirm.toggle ?: return
        mutableState.value = mutableState.value.copy(confirm = confirm.copy(toggle = toggle.copy(checked = checked)))
    }

    /** The profile link was copied: says so. */
    fun linkCopied() {
        mutableState.value = mutableState.value.copy(message = T.deepLinks.copied)
    }

    /** The profile link's dialog closed. */
    fun dismissLink() {
        mutableState.value = mutableState.value.copy(link = null)
    }

    fun dismissConfirm() {
        pendingConfirm = null
        mutableState.value = mutableState.value.copy(confirm = null)
    }

    fun addProfile() {
        if (!mutableState.value.switching) host.open(Route.AddProfile)
    }

    /** Back: a required pick at the bottom leaves the app. */
    fun back() = host.leavePicker(route)

    fun messageShown() {
        mutableState.value = mutableState.value.copy(message = null)
    }

    fun close() = scope.cancel()

    private suspend fun signOutPlexConfirm(accountId: String) {
        val account = storedById[accountId] ?: return
        ask(plexSignOutConfirm(removal, account)) { deleteDownloads ->
            signOutPlex(removal, profiles, account, deleteDownloads, host) { mutableState.value = mutableState.value.copy(message = it) }
        }
    }


    private fun ask(confirm: ConfirmUi, action: suspend (toggled: Boolean) -> Unit) {
        pendingConfirm = action
        mutableState.value = mutableState.value.copy(confirm = confirm)
    }

    /** Another PIN-protected local profile's PIN, until right or cancelled. */
    private suspend fun verifyForAction(profile: Profile): Boolean {
        if (profile !is LocalProfile || !profile.isPinProtected || profile.id == profiles.active.value?.id) return true
        var incorrect = false
        while (true) {
            val pin = pins.ask(profile, incorrect) ?: return false
            if (verifyProfilePin(profile, pin)) return true
            incorrect = true
        }
    }

    private fun tile(
        profile: Profile,
        active: Profile?,
        stored: List<StoredConnection>,
        rows: List<ProfileConnection>,
        homeUsers: Map<String, List<PlexHomeUser>>,
    ): ProfileTileUi {
        storedById = stored.associateBy { it.id }
        val (chips, has) = connectionChips(profile, storedById, rows.filter { it.profileId == profile.id }, homeUsers)
        val actions = buildList {
            add(ProfileAction.MANAGE)
            add(ProfileAction.SHOW_LINK)
            if (profile is LocalProfile) add(ProfileAction.DELETE)
            if (profile is PlexHomeProfile && profile.parentConnectionId?.let(storedById::get) != null) add(ProfileAction.SIGN_OUT)
        }
        return ProfileTileUi(
            id = profile.id,
            name = profile.displayName,
            avatarUrl = resolveProfileAvatarUrls(listOf(profile), groupConnectionsByProfile(rows), storedById, homeUsers)[profile.id],
            active = !route.required && profile.id == active?.id,
            locked = profile.isPinProtected,
            chips = chips,
            hasConnections = has,
            actions = if (route.required) emptyList() else actions,
        )
    }

    private companion object {
        const val TAG = "ProfilePicker"
    }
}

/**
 * The chips under [profile]'s name and whether it reaches any connection. A Plex account names its Home user, and the
 * account too only when the device has more than one Plex account; a Plex Home profile's own account comes first.
 */
fun connectionChips(
    profile: Profile,
    stored: Map<String, StoredConnection>,
    rows: List<ProfileConnection>,
    homeUsers: Map<String, List<PlexHomeUser>>,
): Pair<List<ConnectionChip>, Boolean> {
    val namesAccount = stored.values.count { it.kind == BackendKind.PLEX } > 1
    val chips = mutableListOf<ConnectionChip>()
    var has = false
    fun chip(conn: StoredConnection, user: String?) {
        val account = conn.plexAccount()
        val label = when {
            account != null && user != null && !namesAccount -> user
            account != null && user != null -> T.profiles.plexAccountUserChip(user, account.accountLabel)
            account != null -> T.profiles.plexAccountChip(account.accountLabel)
            else -> conn.mediaBrowser()?.displayLabel ?: conn.id
        }
        chips += ConnectionChip(conn.kind, label)
    }
    if (profile is PlexHomeProfile) {
        profile.parentConnectionId?.let(stored::get)?.let {
            has = true
            if (namesAccount) chip(it, profile.displayName)
        }
    }
    for (row in visibleProfileConnections(profile, rows)) {
        val conn = stored[row.connectionId] ?: continue
        has = true
        val user = if (conn.kind == BackendKind.PLEX && row.userIdentifier.isNotEmpty()) {
            homeUsers[conn.id]?.firstOrNull { it.uuid == row.userIdentifier }?.displayName
        } else {
            null
        }
        chip(conn, user)
    }
    return chips to has
}

/** Deletes local [profile] ([ProfileRemoval.deleteLocalProfile]) and settles the session; [message] reports a failure. */
internal suspend fun deleteProfile(removal: ProfileRemoval, profiles: ProfileServices, profile: Profile, host: AccountsHost, message: (String) -> Unit): Boolean {
    try {
        removal.deleteLocalProfile(profile.id)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.e("Profiles", e) { "Deleting ${profile.id} failed" }
        message(T.errors.failedToDeleteProfile(profile.displayName))
        return false
    }
    settle(profiles, host)
    return true
}

/**
 * The question before signing out of Plex [account]: with the switch to delete its downloads too when the sign-out
 * could delete any ([ProfileRemoval.plexSignOutOwnsDownloads]).
 */
internal suspend fun plexSignOutConfirm(removal: ProfileRemoval, account: StoredConnection): ConfirmUi = ConfirmUi(
    T.profiles.signOutPlexTitle,
    T.profiles.signOutPlexMessage(account.plexAccount()?.displayLabel ?: ""),
    T.profiles.signOut,
    toggle = if (removal.plexSignOutOwnsDownloads(account)) {
        ConfirmToggle(T.profiles.signOutPlexDeleteDownloads, T.profiles.signOutPlexDeleteDownloadsDescription)
    } else {
        null
    },
)

/** Signs out of Plex [account] (its Home users go too), deleting its downloads with [deleteDownloads], and settles the session. */
internal suspend fun signOutPlex(
    removal: ProfileRemoval,
    profiles: ProfileServices,
    account: StoredConnection,
    deleteDownloads: Boolean,
    host: AccountsHost,
    message: (String) -> Unit,
) {
    try {
        removal.signOutPlexAccount(account, deleteDownloads)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.e("Profiles", e) { "Signing out of ${account.id} failed" }
        message(T.profiles.signOutFailed)
        return
    }
    message(T.profiles.signedOutPlex)
    settle(profiles, host)
}

/** After a removal: back to the sign-in when nothing is left, to the required picker when no profile could be made active. */
internal suspend fun settle(profiles: ProfileServices, host: AccountsHost) {
    when (profiles.settleAfterRemoval(rebindIfActiveKept = true)) {
        PostRemovalOutcome.SignedOut -> host.signedOut()
        PostRemovalOutcome.PickProfile -> host.pickRequired()
        else -> Unit
    }
}

/** The new local profile form ([Route.AddProfile]): a name and an optional PIN, then its first connection. */
data class AddProfileUiState(val name: String = "", val pinSet: Boolean = false, val nameRequired: Boolean = false, val message: String? = null, val busy: Boolean = false)

class AddProfileStore(
    private val profiles: ProfileServices,
    private val pins: PinPrompter,
    private val host: AccountsHost,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(AddProfileUiState())
    private var pin: String? = null

    val state: StateFlow<AddProfileUiState> = mutableState.asStateFlow()

    fun setName(text: String) {
        mutableState.value = mutableState.value.copy(name = text, nameRequired = false)
    }

    /** Asks for a new PIN twice; a mismatch says PINs don't match and keeps the old one. */
    fun setPin() {
        scope.launch {
            val next = pins.askNew { mutableState.value = mutableState.value.copy(message = T.profiles.pinsDontMatch) } ?: return@launch
            pin = next
            mutableState.value = mutableState.value.copy(pinSet = true)
        }
    }

    fun clearPin() {
        pin = null
        mutableState.value = mutableState.value.copy(pinSet = false)
    }

    /** Stores the profile, then opens its Add connection. */
    fun save() {
        val s = mutableState.value
        if (s.busy) return
        if (s.name.isBlank()) {
            mutableState.value = s.copy(nameRequired = true)
            return
        }
        mutableState.value = s.copy(busy = true)
        scope.launch {
            val profile = profiles.createLocalProfile(s.name, pin)
            mutableState.value = mutableState.value.copy(busy = false)
            host.open(Route.AddConnection(profile.id))
        }
    }

    fun cancel() = host.back()

    fun messageShown() {
        mutableState.value = mutableState.value.copy(message = null)
    }

    fun close() = scope.cancel()
}

/** A connection of a profile, in its detail: [subtitle] says the Home user it signs in as and Default. */
data class ProfileConnectionUi(
    val connectionId: String,
    val backend: BackendKind,
    val label: String,
    val subtitle: String?,
    val isDefault: Boolean,
    val editable: Boolean,
    /** The Plex Home profile's own account: it can only be signed out of. */
    val plexHomeAccount: Boolean,
)

/**
 * A profile's detail ([Route.ProfileDetail]): its name (a local profile's editable), its PIN (a Plex Home user's
 * managed on plex.tv), its connections (Make default, Edit for Jellyfin/Emby, Remove; the Plex Home account's Sign
 * out), Add and Delete profile.
 */
data class ProfileDetailUiState(
    val title: String = "",
    /** The profile's picture: its Plex Home user's, else its oldest connection's user picture; null for initials. */
    val avatarUrl: String? = null,
    val local: Boolean = true,
    val name: String = "",
    val pinSet: Boolean = false,
    val pinNote: String? = null,
    val connections: List<ProfileConnectionUi> = emptyList(),
    val message: String? = null,
    val confirm: ConfirmUi? = null,
    val gone: Boolean = false,
)

class ProfileDetailStore(
    private val route: Route.ProfileDetail,
    private val profiles: ProfileServices,
    private val removal: ProfileRemoval,
    connections: ConnectionStore,
    private val bindings: ProfileConnectionRegistry,
    private val pins: PinPrompter,
    private val host: AccountsHost,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(ProfileDetailUiState())
    private var profile: Profile? = null
    private var stored: Map<String, StoredConnection> = emptyMap()
    private var pendingConfirm: (suspend (toggled: Boolean) -> Unit)? = null

    val state: StateFlow<ProfileDetailUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            combine(profiles.profiles, connections.observe(), bindings.observeForProfile(route.profileId), profiles.plexHomeUsers, ::Quad).collect { (all, conns, rows, users) ->
                val current = all.firstOrNull { it.id == route.profileId }
                stored = conns.associateBy { it.id }
                if (current == null) {
                    mutableState.value = mutableState.value.copy(gone = true)
                    return@collect
                }
                val first = profile == null
                profile = current
                mutableState.value = mutableState.value.copy(
                    title = current.displayName,
                    avatarUrl = resolveProfileAvatarUrls(listOf(current), mapOf(current.id to rows), stored, users)[current.id],
                    local = current is LocalProfile,
                    name = if (first || current !is LocalProfile) current.displayName else mutableState.value.name,
                    pinSet = current.isPinProtected,
                    pinNote = (current as? PlexHomeProfile)?.let { if (it.plexProtected) T.profiles.pinManagedByPlex else T.profiles.noPinSetEditOnPlex },
                    connections = rowsOf(current, rows, users),
                )
            }
        }
    }

    fun setName(text: String) {
        mutableState.value = mutableState.value.copy(name = text)
    }

    fun saveName() {
        val local = profile as? LocalProfile ?: return
        val name = mutableState.value.name.trim()
        if (name.isEmpty() || name == local.displayName) return
        edit {
            profiles.renameLocalProfile(local.id, name)
            mutableState.value = mutableState.value.copy(message = T.profiles.profileRenamed)
        }
    }

    fun setPin() {
        val local = profile as? LocalProfile ?: return
        edit {
            val pin = pins.askNew { mutableState.value = mutableState.value.copy(message = T.profiles.pinsDontMatch) } ?: return@edit
            profiles.setLocalProfilePin(local.id, pin)
        }
    }

    fun clearPin() {
        val local = profile as? LocalProfile ?: return
        edit { profiles.setLocalProfilePin(local.id, null) }
    }

    /** Changes the stored profile; deleted meanwhile (the screen goes), it changes nothing. */
    private fun edit(change: suspend () -> Unit) {
        scope.launch {
            try {
                change()
            } catch (e: IllegalStateException) {
                Log.w("Profiles", e) { "${route.profileId} went before its change" }
            }
        }
    }

    fun addConnection() = host.open(Route.AddConnection(route.profileId))

    fun makeDefault(connectionId: String) {
        scope.launch {
            bindings.setDefault(route.profileId, connectionId)
            profiles.rebindIfActive(route.profileId)
        }
    }

    fun edit(connectionId: String) = host.open(Route.EditConnection(connectionId))

    fun remove(connectionId: String) {
        val conn = stored[connectionId] ?: return
        val current = profile ?: return
        val label = conn.plexAccount()?.displayLabel ?: conn.mediaBrowser()?.displayLabel ?: conn.id
        ask(ConfirmUi(T.profiles.removeConnectionTitle, T.profiles.removeConnectionMessage(current.displayName, label), T.profiles.removeConnection)) {
            try {
                removal.removeProfileConnection(route.profileId, conn)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e("Profiles", e) { "Removing ${conn.id} from ${route.profileId} failed" }
                return@ask
            }
            settle(profiles, host)
            profiles.rebindIfActive(route.profileId)
        }
    }

    fun signOut(connectionId: String) {
        val conn = stored[connectionId] ?: return
        scope.launch {
            ask(plexSignOutConfirm(removal, conn)) { deleteDownloads ->
                signOutPlex(removal, profiles, conn, deleteDownloads, host) { mutableState.value = mutableState.value.copy(message = it) }
            }
        }
    }

    fun delete() {
        val current = profile as? LocalProfile ?: return
        ask(ConfirmUi(T.profiles.deleteProfileTitle, T.profiles.deleteProfileMessage(current.displayName), T.common.delete)) {
            if (deleteProfile(removal, profiles, current, host) { mutableState.value = mutableState.value.copy(message = it) }) host.back()
        }
    }

    fun confirm() {
        val action = pendingConfirm ?: return
        val toggled = mutableState.value.confirm?.toggle?.checked == true
        pendingConfirm = null
        mutableState.value = mutableState.value.copy(confirm = null)
        scope.launch { action(toggled) }
    }

    /** Turns the open confirmation's switch on or off. */
    fun setConfirmToggle(checked: Boolean) {
        val confirm = mutableState.value.confirm ?: return
        val toggle = confirm.toggle ?: return
        mutableState.value = mutableState.value.copy(confirm = confirm.copy(toggle = toggle.copy(checked = checked)))
    }

    fun dismissConfirm() {
        pendingConfirm = null
        mutableState.value = mutableState.value.copy(confirm = null)
    }

    fun messageShown() {
        mutableState.value = mutableState.value.copy(message = null)
    }

    fun close() = scope.cancel()

    private fun ask(confirm: ConfirmUi, action: suspend (toggled: Boolean) -> Unit) {
        pendingConfirm = action
        mutableState.value = mutableState.value.copy(confirm = confirm)
    }

    private fun rowsOf(profile: Profile, rows: List<ProfileConnection>, users: Map<String, List<PlexHomeUser>>): List<ProfileConnectionUi> = buildList {
        if (profile is PlexHomeProfile) {
            profile.parentConnectionId?.let(stored::get)?.let { conn ->
                add(ProfileConnectionUi(conn.id, conn.kind, conn.plexAccount()?.displayLabel ?: conn.id, T.profiles.plexHomeAccount, false, false, true))
            }
        }
        for (row in visibleProfileConnections(profile, rows)) {
            val conn = stored[row.connectionId] ?: continue
            val plex = conn.plexAccount()
            val user = if (plex != null) users[conn.id]?.firstOrNull { it.uuid == row.userIdentifier }?.displayName else null
            val parts = listOfNotNull(user?.let { T.profiles.connectionAs(it) }, if (row.isDefault) T.profiles.connectionDefault else null)
            add(
                ProfileConnectionUi(
                    connectionId = conn.id,
                    backend = conn.kind,
                    label = plex?.displayLabel ?: conn.mediaBrowser()?.displayName ?: conn.id,
                    subtitle = parts.joinToString(" · ").ifEmpty { null },
                    isDefault = row.isDefault,
                    editable = plex == null,
                    plexHomeAccount = false,
                ),
            )
        }
    }
}

private data class Quad<A, B, C, D>(val a: A, val b: B, val c: C, val d: D)


/** One way to add a connection ([Route.AddConnection]): its card's title and subtitle, and the screen it opens. */
data class AddConnectionOption(val backend: BackendKind?, val title: String, val subtitle: String, val route: Route)

/**
 * The Add connection screen's cards, in order: Sign in with Plex, Connect to Jellyfin, Connect to Emby and, for a
 * profile, Borrow from another profile.
 */
fun addConnectionOptions(route: Route.AddConnection, profileName: String?): Pair<String, List<AddConnectionOption>> {
    val scoped = route.profileId != null
    val title = if (scoped && profileName != null) T.addServer.addConnectionTitleScoped(profileName) else T.addServer.addConnectionTitle
    val options = buildList {
        add(
            AddConnectionOption(
                BackendKind.PLEX,
                T.addServer.signInWithPlexCard,
                if (scoped) T.addServer.signInWithPlexCardSubtitleScoped else T.addServer.signInWithPlexCardSubtitle,
                Route.AddPlexAccount(route.profileId),
            ),
        )
        for (dialect in listOf(MediaBrowserDialect.JELLYFIN, MediaBrowserDialect.EMBY)) {
            add(
                AddConnectionOption(
                    dialect.backend,
                    T.addServer.connectToMediaBrowserCard(dialect.productName),
                    T.addServer.connectToMediaBrowserCardSubtitle,
                    Route.AddMediaBrowser(dialect, route.profileId),
                ),
            )
        }
        if (route.profileId != null) {
            add(AddConnectionOption(null, T.addServer.borrowFromAnotherProfile, T.addServer.borrowFromAnotherProfileSubtitle, Route.BorrowConnection(route.profileId)))
        }
    }
    return title to options
}

/** A connection another profile lends ([Route.BorrowConnection]). */
data class BorrowCandidateUi(val index: Int, val backend: BackendKind, val label: String, val from: String, val locked: Boolean)

data class BorrowUiState(
    val title: String,
    val loading: Boolean = true,
    val failed: Boolean = false,
    val candidates: List<BorrowCandidateUi> = emptyList(),
    val busy: Boolean = false,
    val message: String? = null,
)

class BorrowStore(
    private val route: Route.BorrowConnection,
    private val profiles: ProfileServices,
    private val pins: PinPrompter,
    private val host: AccountsHost,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val target = profiles.profiles.value.firstOrNull { it.id == route.profileId }
    private val mutableState = MutableStateFlow(BorrowUiState(T.profiles.borrowAddTo(target?.displayName ?: "")))
    private var candidates: List<BorrowCandidate> = emptyList()

    val state: StateFlow<BorrowUiState> = mutableState.asStateFlow()

    init {
        load()
    }

    fun retry() = load()

    fun borrow(index: Int) {
        val candidate = candidates.getOrNull(index) ?: return
        val profile = target ?: return
        if (mutableState.value.busy) return
        mutableState.value = mutableState.value.copy(busy = true)
        scope.launch {
            val result = profiles.borrow(profile, candidate, pins::ask)
            mutableState.value = mutableState.value.copy(
                busy = false,
                message = when (result) {
                    BorrowResult.BORROWED -> T.profiles.borrowConnectionBorrowed
                    BorrowResult.CANCELLED -> null
                    BorrowResult.INCORRECT_PIN -> T.profiles.incorrectPin
                    BorrowResult.SOURCE_ACCOUNT_MISSING -> T.profiles.sourceProfileMissingParentAccount
                    BorrowResult.FAILED -> T.profiles.borrowFailed
                },
            )
            if (result == BorrowResult.BORROWED) host.connectionAdded(route, pickProfile = false)
        }
    }

    fun messageShown() {
        mutableState.value = mutableState.value.copy(message = null)
    }

    fun close() = scope.cancel()

    private fun load() {
        val profile = target ?: return run { mutableState.value = mutableState.value.copy(loading = false, failed = true) }
        mutableState.value = mutableState.value.copy(loading = true, failed = false)
        scope.launch {
            candidates = try {
                profiles.borrowCandidates(profile)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w("Borrow", e) { "Listing what ${profile.id} can borrow failed" }
                mutableState.value = mutableState.value.copy(loading = false, failed = true)
                return@launch
            }
            mutableState.value = mutableState.value.copy(
                loading = false,
                candidates = candidates.mapIndexed { i, c ->
                    BorrowCandidateUi(
                        index = i,
                        backend = c.connection.kind,
                        label = c.connection.plexAccount()?.displayLabel ?: c.connection.mediaBrowser()?.displayName ?: c.connection.id,
                        from = T.profiles.borrowFromProfile(c.source.displayName),
                        locked = c.source.isPinProtected,
                    )
                },
            )
        }
    }
}

/** A Jellyfin/Emby connection's URLs ([Route.EditConnection]), one per line; Save races them and keeps the reachable. */
data class EditConnectionUiState(val title: String = "", val intro: String = "", val urls: String = "", val busy: Boolean = false, val error: String? = null)

class EditConnectionStore(
    private val route: Route.EditConnection,
    private val profiles: ProfileServices,
    private val connections: ConnectionStore,
    private val http: HttpClient,
    private val host: AccountsHost,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(EditConnectionUiState())
    private var stored: StoredConnection? = null

    val state: StateFlow<EditConnectionUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            val row = connections.get(route.connectionId) ?: return@launch
            val conn = row.mediaBrowser() ?: return@launch
            stored = row
            mutableState.value = EditConnectionUiState(
                title = T.connections.editMediaBrowserTitle(conn.dialect.productName),
                intro = T.connections.editMediaBrowserIntro(conn.serverName),
                urls = conn.baseUrls.joinToString("\n"),
            )
        }
    }

    fun setUrls(text: String) {
        mutableState.value = mutableState.value.copy(urls = text, error = null)
    }

    /** Probes and stores the URLs; a save while one runs is refused, so only one stores and closes the screen. */
    fun save() {
        if (mutableState.value.busy) return
        val row = stored ?: return
        val conn = row.mediaBrowser() ?: return
        val urls = JellyfinEndpointDiscovery.parseUserEnteredUrls(mutableState.value.urls)
        if (urls.isEmpty()) {
            mutableState.value = mutableState.value.copy(error = T.addServer.required)
            return
        }
        mutableState.value = mutableState.value.copy(busy = true, error = null)
        scope.launch {
            try {
                val next = prepareMediaBrowserEndpoints(http, conn, urls)
                connections.upsert(next.stored(), expected = row)
                profiles.active.value?.let { profiles.rebindIfActive(it.id) }
                host.back()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w("EditConnection", e) { "Saving ${route.connectionId}'s URLs failed" }
                val error = (e as? MediaServerUrlException)?.display ?: T.addServer.couldNotReachServer(localizedErrorReason(e))
                mutableState.value = mutableState.value.copy(busy = false, error = error)
            }
        }
    }

    fun close() = scope.cancel()
}
