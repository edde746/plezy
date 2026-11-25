package com.edde746.plezy.livetv

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals

class LiveTvFlexibleParsingTest {
    private fun json(text: String) = Json.parseToJsonElement(text).jsonObject

    @Test
    fun liveTvCollectionModelsSkipMalformedEntriesAndKeepValidSiblings() {
        val dvr = LiveTvDvr.fromJson(json("""{"key":"dvr-1","ChannelMapping":[{"channelKey":7},{"channelKey":"channel-1"}]}"""))
        assertEquals(listOf<String?>("channel-1"), dvr.channelMappings.map { it.channelKey })

        val template = SubscriptionTemplate.fromJson(json("""{"MediaSubscription":[{"title":7},{"key":"subscription-1","title":"Recordings"}]}"""))
        assertEquals(listOf("subscription-1"), template.subscriptions.map { it.key })
    }
}
