package com.edde746.plezy.app

import com.edde746.plezy.presentation.browse.MenuEntry
import com.edde746.plezy.presentation.browse.MenuEntryProvider
import com.edde746.plezy.presentation.browse.MenuIcon
import com.edde746.plezy.presentation.browse.MenuMessage
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.browse.MenuSlot
import com.edde746.plezy.presentation.browse.MenuTarget
import com.edde746.plezy.presentation.metadata.MetadataAction
import com.edde746.plezy.presentation.metadata.MetadataEditing

/**
 * The metadata edits in an item's menu ([MenuSlot.METADATA]): Edit..., Quick Tag..., Match... or Fix Match... and
 * Unmatch, as [MetadataEditing.menu] offers them to the signed-in user. Edit and Match open their screens; Quick Tag and
 * Unmatch's confirmation are drawn over the app from [MetadataEditing.quickTag] and [MetadataEditing.unmatchPrompt].
 * [editing] is read at each use: the session makes it after its menus.
 */
internal class MetadataMenuEntries(private val editing: () -> MetadataEditing) : MenuEntryProvider {
    private val metadata: MetadataEditing get() = editing()

    override val slot: MenuSlot get() = MenuSlot.METADATA

    override fun entries(target: MenuTarget, place: MenuPlace): List<MenuEntry> {
        val item = (target as? MenuTarget.Item)?.item ?: return emptyList()
        return metadata.menu(item).map { MenuEntry(it.action.id, it.label, it.action.icon, destructive = it.action == MetadataAction.UNMATCH) }
    }

    override suspend fun perform(target: MenuTarget, place: MenuPlace, entryId: String): MenuMessage? {
        val item = (target as? MenuTarget.Item)?.item ?: return null
        when (MetadataAction.entries.first { it.id == entryId }) {
            MetadataAction.EDIT -> metadata.open(MetadataAction.EDIT, item)
            MetadataAction.MATCH -> metadata.open(MetadataAction.MATCH, item)
            MetadataAction.QUICK_TAG -> metadata.startQuickTag(item)
            MetadataAction.UNMATCH -> metadata.askUnmatch(item)
        }
        return null
    }

    private val MetadataAction.id: String
        get() = when (this) {
            MetadataAction.EDIT -> "edit_metadata"
            MetadataAction.QUICK_TAG -> "quick_tag"
            MetadataAction.MATCH -> "match"
            MetadataAction.UNMATCH -> "unmatch"
        }

    private val MetadataAction.icon: MenuIcon
        get() = when (this) {
            MetadataAction.EDIT -> MenuIcon.EDIT
            MetadataAction.QUICK_TAG -> MenuIcon.LABEL
            MetadataAction.MATCH -> MenuIcon.SEARCH
            MetadataAction.UNMATCH -> MenuIcon.LINK_OFF
        }
}
