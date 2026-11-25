package com.edde746.plezy.model

/** Libraries bucketed by server: [serverOrder] lists server ids (`""` for none) in order of first appearance. */
data class LibraryServerGroups(val serverOrder: List<String>, val byServer: Map<String, List<MediaLibrary>>)

/** [libraries] grouped by server id, servers in order of first appearance, each server's libraries in list order. */
fun groupLibrariesByFirstAppearance(libraries: List<MediaLibrary>): LibraryServerGroups {
    val byServer = LinkedHashMap<String, MutableList<MediaLibrary>>()
    for (library in libraries) byServer.getOrPut(library.serverId ?: "") { mutableListOf() } += library
    return LibraryServerGroups(byServer.keys.toList(), byServer)
}
