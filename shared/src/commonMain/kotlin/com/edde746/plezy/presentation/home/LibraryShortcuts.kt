package com.edde746.plezy.presentation.home

import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.profiles.ProfileBindState
import com.edde746.plezy.servers.LibrariesLoadState
import com.edde746.plezy.servers.LibrariesState
import com.edde746.plezy.servers.MultiServerState

/**
 * A library's shortcut chip on Home ([libraryShortcuts]): the library's [kind] icon, its [title], and its [serverName]
 * where another shortcut has the same title on a different server; a tap opens [globalKey] in Libraries.
 */
data class LibraryShortcutUi(val globalKey: String, val title: String, val serverName: String?, val kind: MediaKind)

/**
 * Home's library shortcuts: [libraries] in their order (the profile's, as Libraries lists them) less those in
 * [hiddenKeys]. A shortcut names its server only while another one carries the same title (case aside) from a
 * different server.
 */
fun libraryShortcuts(libraries: List<MediaLibrary>, hiddenKeys: Set<String>): List<LibraryShortcutUi> {
    val visible = libraries.filter { it.globalKey !in hiddenKeys }
    val serversByTitle = visible.groupBy { it.title.trim().lowercase() }.mapValues { (_, same) -> same.mapTo(HashSet()) { it.serverId } }
    return visible.map { library ->
        val shared = serversByTitle.getValue(library.title.trim().lowercase()).size > 1
        LibraryShortcutUi(library.globalKey, library.title, library.serverName.takeIf { shared }, library.kind)
    }
}

/**
 * Whether Home's chip row is whole: the profile's bind has settled (every server it connects has connected or failed),
 * each of its online servers has answered for its libraries (or the first load failed), and each said whether it has
 * Live TV. A library chip then never gains its server's name when a namesake from a later server arrives.
 */
fun shortcutsSettled(libraries: LibrariesState, servers: MultiServerState, bind: ProfileBindState): Boolean {
    if (bind.unsettled || !servers.liveTvChecked) return false
    return when (libraries.loadState) {
        LibrariesLoadState.ERROR -> true
        LibrariesLoadState.LOADED -> libraries.answeredServerIds.containsAll(servers.onlineServerIds)
        else -> false
    }
}
