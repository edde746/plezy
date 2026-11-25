package com.edde746.plezy.presentation.browse

import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.settings.ContinueWatchingAction
import com.edde746.plezy.settings.EpisodeAction
import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * The question a Continue Watching row of several copies asks before it opens one ([MediaActions.pick]): [options] one
 * line per copy, none while no question is open.
 */
data class CopyPicker(val title: String, val options: List<String>) {
    val shown: Boolean get() = options.isNotEmpty()
}

/**
 * What the browse screens do with an item: open it as selecting it says ([activationOf]), asking first which copy when
 * a Continue Watching row stands for several ([picker]), play it ([play]), and its [menu]. Main thread only.
 *
 * @param copiesOf the copies merged into a Continue Watching row (empty: the row stands alone).
 * @param play plays an item in the player.
 * @param playTrack plays a track in its album's queue in the music player.
 * @param openLibrary shows a library (by its global key) in Libraries.
 * @param notify shows a message over the app.
 */
class MediaActions(
    private val navigator: PlezyNavigator,
    private val continueWatchingAction: StateFlow<ContinueWatchingAction>,
    private val episodeAction: StateFlow<EpisodeAction>,
    private val copiesOf: (MediaItem) -> List<MediaItem>,
    private val play: (MediaItem) -> Unit,
    private val playTrack: (MediaItem) -> Unit,
    private val openLibrary: (String) -> Unit,
    private val notify: (String) -> Unit,
    /** Items' and playlists' menus. */
    val menu: MediaMenu,
) {
    private val mutablePicker = MutableStateFlow(CopyPicker(T.discover.selectVersion, emptyList()))
    private var pending: List<MediaItem> = emptyList()

    /** The copy question, [CopyPicker.shown] while open. */
    val picker: StateFlow<CopyPicker> = mutablePicker.asStateFlow()

    /** Opens [item]; [playDirectly] for Continue Watching, which asks first between the copies a row merged. */
    fun open(item: MediaItem, playDirectly: Boolean) {
        val copies = if (playDirectly) copiesOf(item) else emptyList()
        if (copies.size > 1) {
            pending = copies
            mutablePicker.value = CopyPicker(T.discover.selectVersion, copyLabels(copies))
            return
        }
        activate(item, playDirectly)
    }

    /** Opens the copy at [index] of the [picker]'s options. */
    fun pick(index: Int) {
        val copy = pending.getOrNull(index) ?: return
        dismiss()
        activate(copy, playDirectly = true)
    }

    /** Plays [item] at once (the hero's play button), whatever selecting it would do. */
    fun play(item: MediaItem) = play.invoke(item)

    /** Closes the [picker] without opening anything. */
    fun dismiss() {
        pending = emptyList()
        mutablePicker.value = CopyPicker(T.discover.selectVersion, emptyList())
    }

    private fun activate(item: MediaItem, playDirectly: Boolean) {
        when (val activation = activationOf(item, playDirectly, continueWatchingAction.value, episodeAction.value)) {
            is ItemActivation.Open -> navigator.navigate(activation.route)
            is ItemActivation.Play -> play(activation.item)
            is ItemActivation.PlayTrack -> playTrack(activation.item)
            is ItemActivation.OpenLibrary -> openLibrary(activation.globalKey)
            is ItemActivation.Unsupported -> notify(activation.message)
            null -> Unit
        }
    }
}
