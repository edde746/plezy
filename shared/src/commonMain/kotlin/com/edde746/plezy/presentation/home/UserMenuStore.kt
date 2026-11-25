package com.edde746.plezy.presentation.home

import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.onboarding.AccountsHost
import com.edde746.plezy.presentation.onboarding.ConfirmUi
import com.edde746.plezy.presentation.onboarding.PinPrompter
import com.edde746.plezy.presentation.onboarding.profileSwitchBusy
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.profiles.ProfileRemoval
import com.edde746.plezy.profiles.ProfileServices
import com.edde746.plezy.profiles.ProfileSwitchResult
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** A profile in Home's user menu: its avatar ([avatarUrl], else its initial) and a lock where a PIN guards it. */
data class UserMenuProfile(val id: String, val name: String, val avatarUrl: String?, val locked: Boolean)

/** The user menu's entries after the profiles (a divider between), in this order. */
enum class UserMenuAction {
    /** The profile picker, where profiles are managed. */
    MANAGE_PROFILES,
    SETTINGS,

    /** Logs out of every profile, after a confirm. */
    LOGOUT,
    ;

    val label: String
        get() = when (this) {
            MANAGE_PROFILES -> T.profiles.manageProfiles
            SETTINGS -> T.common.settings
            LOGOUT -> T.common.logout
        }
}

/**
 * Home's user menu: the button shows [active]'s avatar (none: the account icon); the menu lists the other [profiles],
 * then [actions]. [switching] covers the screen with "Switching profile…" and disables the menu; [confirm] is Log out's
 * question; [message] a snackbar to show once.
 */
data class UserMenuUiState(
    val active: UserMenuProfile? = null,
    val profiles: List<UserMenuProfile> = emptyList(),
    val actions: List<UserMenuAction> = UserMenuAction.entries,
    val switching: Boolean = false,
    val confirm: ConfirmUi? = null,
    val message: String? = null,
)

/**
 * Home's user menu (the toolbar's last action). A profile switches to it, its PIN asked through [pins]; Manage profiles
 * opens the profile picker, Settings [openSettings]; Log out asks first, then logs out of every profile with its
 * integrations ([ProfileRemoval.logOutAll]) and goes back to the sign-in. Nothing acts while a switch runs.
 */
class UserMenuStore(
    private val profiles: ProfileServices,
    private val removal: ProfileRemoval,
    private val pins: PinPrompter,
    private val host: AccountsHost,
    private val openSettings: () -> Unit,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private var others: List<Profile> = othersOf(profiles.profiles.value, profiles.active.value)

    // Seeded from the profiles as they are now, so a screen that opens with the store draws the profile at once.
    private val mutableState = MutableStateFlow(UserMenuUiState(active = profiles.active.value?.let(::entry), profiles = others.map(::entry)))
    private val switchingTo = MutableStateFlow(false)

    val state: StateFlow<UserMenuUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            combine(profiles.profiles, profiles.active, ::Pair).collect { (all, active) ->
                others = othersOf(all, active)
                mutableState.update { it.copy(active = active?.let(::entry), profiles = others.map(::entry)) }
            }
        }
        scope.launch {
            profileSwitchBusy(switchingTo, profiles, pins).collect { switching -> mutableState.update { it.copy(switching = switching) } }
        }
    }

    private fun othersOf(all: List<Profile>, active: Profile?) = all.filter { it.id != active?.id }

    /** Switches to profile [id], asking its PIN where one guards it. */
    fun switchTo(id: String) {
        if (switchingTo.value) return
        val profile = others.firstOrNull { it.id == id } ?: return
        switchingTo.value = true
        scope.launch {
            val result = try {
                profiles.switchProfile(profile, pins::ask)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Switching to ${profile.id} failed" }
                ProfileSwitchResult.FAILED
            } finally {
                switchingTo.value = false
            }
            if (result == ProfileSwitchResult.FAILED) mutableState.update { it.copy(message = T.errors.failedToSwitchProfile(profile.displayName)) }
        }
    }

    fun act(action: UserMenuAction) {
        if (mutableState.value.switching) return
        when (action) {
            UserMenuAction.MANAGE_PROFILES -> host.open(Route.ProfilePicker(required = false, manage = true))
            UserMenuAction.SETTINGS -> openSettings()
            UserMenuAction.LOGOUT -> mutableState.update { it.copy(confirm = ConfirmUi(T.common.logout, T.messages.logoutConfirm, T.common.logout)) }
        }
    }

    /** Log out confirmed: every profile, account and integration goes, and the sign-in shows. */
    fun confirm() {
        if (mutableState.value.confirm == null) return
        mutableState.update { it.copy(confirm = null) }
        scope.launch {
            removal.logOutAll()
            host.signedOut()
        }
    }

    fun dismissConfirm() {
        mutableState.update { it.copy(confirm = null) }
    }

    fun messageShown() {
        mutableState.update { it.copy(message = null) }
    }

    fun close() = scope.cancel()

    private fun entry(profile: Profile) = UserMenuProfile(profile.id, profile.displayName, profile.avatarThumbUrl, profile.isPinProtected)

    private companion object {
        const val TAG = "UserMenu"
    }
}
