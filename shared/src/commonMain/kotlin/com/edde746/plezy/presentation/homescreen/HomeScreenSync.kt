package com.edde746.plezy.presentation.homescreen

import com.edde746.plezy.app.ContinueWatchingShelf
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch

/**
 * Keeps the TV's home screen ([SystemShelf]) on the active profile's Continue Watching while the app runs.
 *
 * The shelf's session follows [activeProfile]: a switch, sign-out or removal ends the old session (its shelf clears at
 * once) before the new one begins. A PIN-protected profile may not publish while the app asks for a profile on open
 * (the setting on and more than one profile), since the shelf would show its Continue Watching past the PIN; a change of
 * its PIN, of the profiles or of the setting applies again, and a profile allowed again publishes at once. Without the
 * setting the app opens straight into the active profile, so the shelf shows nothing opening the app wouldn't. The
 * items are Home's Continue Watching ([continueWatching], every change Home commits, with the profile it was read for),
 * so the shelf shows what Home's row shows; a list read for another profile than the shelf's owner is dropped. The
 * poster settings (Hide Spoilers, Episode Poster) apply at each publish, and a change to them publishes again. Nothing
 * runs without a home screen.
 */
internal class HomeScreenSync(
    private val shelf: SystemShelf,
    private val activeProfile: Flow<Profile?>,
    private val profiles: Flow<List<Profile>>,
    private val continueWatching: Flow<ContinueWatchingShelf?>,
    private val clientFor: (ServerId) -> MediaBackend?,
    private val settings: DeviceSettingsRepository,
    private val scope: CoroutineScope,
) {
    fun start() {
        scope.launch {
            combine(
                activeProfile,
                profiles,
                continueWatching,
                settings.observe(listOf(AppSettings.requireProfileSelectionOnOpen, AppSettings.hideSpoilers, AppSettings.episodePosterMode)),
            ) { active, all, cw, values ->
                val askOnOpen = values[0] as Boolean && all.size > 1
                Publication(active?.id, active != null && (!active.isPinProtected || !askOnOpen), cw, values[1] as Boolean, values[2] as EpisodePosterMode)
            }.distinctUntilChanged().collect { p ->
                shelf.sessionProfile?.let { if (it != p.profileId) shelf.endProfileSession(it) }
                p.profileId?.let { shelf.beginProfileSession(it, p.mayPublish) }
                // Also after the session changed: a profile allowed again publishes the list it already has.
                p.continueWatching?.let { shelf.sync(it.profileId, it.items, clientFor, p.hideSpoilers, p.episodePosterMode) }
            }
        }
    }

    private data class Publication(
        val profileId: String?,
        val mayPublish: Boolean,
        val continueWatching: ContinueWatchingShelf?,
        val hideSpoilers: Boolean,
        val episodePosterMode: EpisodePosterMode,
    )
}
