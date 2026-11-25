package com.edde746.plezy.presentation.explore

import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** An Explore shelf's header names the provider's total only when the provider reports one. */
class ExploreHubTotalsTest {
    private val hub = MediaHub(id = "explore:seerr:popular", title = "Popular", type = "mixed", items = emptyList(), size = 237, more = true)

    @Test
    fun `shows a provider result count in the existing hub header only when supplied`() {
        assertNull(ExploreRow(hub, ExploreRowIcon.POPULAR).toHubUi(342, 1280).totalResults)
        assertEquals(T.explore.totalResults(237), ExploreRow(hub, ExploreRowIcon.POPULAR, totalResults = 237).toHubUi(342, 1280).totalResults)
    }
}
