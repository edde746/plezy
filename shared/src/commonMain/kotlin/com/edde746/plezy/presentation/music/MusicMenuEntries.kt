package com.edde746.plezy.presentation.music

import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.browse.MenuEntry
import com.edde746.plezy.presentation.browse.MenuEntryProvider
import com.edde746.plezy.presentation.browse.MenuIcon
import com.edde746.plezy.presentation.browse.MenuMessage
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.browse.MenuSlot
import com.edde746.plezy.presentation.browse.MenuTarget

/**
 * The music actions in an artist's, album's or track's menu ([MenuSlot.MUSIC]): [MusicScreens.menuActions], run by
 * [MusicScreens.runMenuAction], whose feedback the music screens' snackbars show.
 */
internal class MusicMenuEntries(private val screens: () -> MusicScreens) : MenuEntryProvider {
    override val slot: MenuSlot get() = MenuSlot.MUSIC

    override fun entries(target: MenuTarget, place: MenuPlace): List<MenuEntry> {
        val item = (target as? MenuTarget.Item)?.item?.takeIf { it.kind in MUSIC_KINDS } ?: return emptyList()
        return screens().menuActions(item, albumScreen = place.albumId, artistScreen = place.artistId)
            .map { MenuEntry(it.entryId, it.label, it.icon) }
    }

    override suspend fun perform(target: MenuTarget, place: MenuPlace, entryId: String): MenuMessage? {
        val item = (target as? MenuTarget.Item)?.item ?: return null
        val action = MusicMenuAction.entries.firstOrNull { it.entryId == entryId } ?: return null
        screens().runMenuAction(item, action)
        return null
    }

    private companion object {
        val MUSIC_KINDS = setOf(MediaKind.ARTIST, MediaKind.ALBUM, MediaKind.TRACK)

        val MusicMenuAction.entryId: String get() = "music_${name.lowercase()}"

        val MusicMenuAction.icon: MenuIcon
            get() = when (this) {
                MusicMenuAction.PLAY -> MenuIcon.PLAY
                MusicMenuAction.PLAY_NEXT -> MenuIcon.PLAY_NEXT
                MusicMenuAction.ADD_TO_QUEUE -> MenuIcon.QUEUE
                MusicMenuAction.INSTANT_MIX -> MenuIcon.INSTANT_MIX
                MusicMenuAction.GO_TO_ALBUM -> MenuIcon.ALBUM
                MusicMenuAction.GO_TO_ARTIST -> MenuIcon.ARTIST
            }
    }
}
