package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals

class LibraryGroupingTest {
    private fun library(id: String, serverId: String?) = MediaLibrary(id = id, backend = BackendKind.PLEX, title = id, serverId = serverId)

    @Test
    fun groupsByServerInOrderOfFirstAppearanceKeepingLibraryOrder() {
        val groups = groupLibrariesByFirstAppearance(
            listOf(library("b1", "b"), library("none", null), library("a1", "a"), library("b2", "b")),
        )
        assertEquals(listOf("b", "", "a"), groups.serverOrder)
        assertEquals(listOf("b1", "b2"), groups.byServer.getValue("b").map { it.id })
        assertEquals(listOf("none"), groups.byServer.getValue("").map { it.id })
    }
}
