package com.edde746.plezy.livetv

import com.edde746.plezy.backend.FakeMediaBackend.NotScripted
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.livetv.FavoriteChannel
import kotlin.time.Instant

/**
 * A scripted [LiveTvSupport] with its DVR adapter: every member is a handler a test sets; an unset one throws
 * [NotScripted]. [dvr] is this object until a test sets [hasDvr] false; [whatsOn] likewise with [hasWhatsOn].
 */
class FakeLiveTv(
    var hasDvr: Boolean = true,
    var hasWhatsOn: Boolean = false,
    override var favoriteStoreKey: String = "fake",
    override var favoritePersistenceMode: FavoriteChannelPersistenceMode = FavoriteChannelPersistenceMode.SERVER_SLICE,
    override var supportsRuleProcessing: Boolean = false,
) : LiveTvSupport, LiveTvDvrSupport, LiveTvWhatsOn {
    val calls = mutableListOf<String>()

    var available: suspend () -> Boolean = { throw NotScripted("liveTv.isAvailable") }
    var channels: suspend (lineup: String?) -> List<LiveTvChannel> = { throw NotScripted("liveTv.fetchChannels") }
    var schedule: suspend (from: Instant?, to: Instant?) -> List<LiveTvProgram> = { _, _ -> throw NotScripted("liveTv.fetchSchedule") }
    var start: suspend (channelKey: String, dvrKey: String?, quality: TranscodeQualityPreset) -> LiveTvPlaybackSession? =
        { _, _, _ -> throw NotScripted("liveTv.startPlayback") }
    var favoriteSource: suspend (lineup: String?) -> String = { throw NotScripted("liveTv.buildFavoriteChannelSource") }
    var favorites: suspend (migrate: Boolean) -> List<FavoriteChannel> = { throw NotScripted("liveTv.fetchFavoriteChannels") }
    var saveFavorites: suspend (List<FavoriteChannel>) -> Unit = { throw NotScripted("liveTv.setFavoriteChannels") }
    var dvrs: suspend () -> List<LiveTvDvr> = { throw NotScripted("dvr.fetchDvrs") }
    var reload: suspend (dvrId: String) -> Unit = { throw NotScripted("dvr.reloadGuide") }
    var template: suspend (guid: String) -> List<SubscriptionTemplate> = { throw NotScripted("dvr.getSubscriptionTemplate") }
    var rules: suspend (includeGrabs: Boolean, includeStorage: Boolean) -> List<MediaSubscription> = { _, _ -> throw NotScripted("dvr.fetchRecordingRules") }
    var create: suspend (MediaSubscriptionCreateRequest) -> MediaSubscription? = { throw NotScripted("dvr.createRecordingRule") }
    var update: suspend (id: String, prefs: Map<String, Any?>) -> MediaSubscription? = { _, _ -> throw NotScripted("dvr.updateRecordingRule") }
    var delete: suspend (id: String) -> Unit = { throw NotScripted("dvr.deleteRecordingRule") }
    var process: suspend () -> Unit = { throw NotScripted("dvr.processRecordingRules") }
    var scheduled: suspend () -> List<MediaGrabOperation> = { throw NotScripted("dvr.fetchScheduledRecordings") }
    var cancel: suspend (operationId: String) -> Unit = { throw NotScripted("dvr.cancelGrab") }
    var mapping: suspend (providerId: String, ratingKeys: List<String>) -> List<MediaSubscription> = { _, _ -> throw NotScripted("dvr.fetchSubscriptionMapping") }
    var hubs: suspend (count: Int) -> List<LiveTvHub> = { throw NotScripted("whatsOn.fetchHubs") }

    override val dvr: LiveTvDvrSupport? get() = if (hasDvr) this else null
    override val whatsOn: LiveTvWhatsOn? get() = if (hasWhatsOn) this else null

    override suspend fun isAvailable(): Boolean = record("isAvailable") { available() }
    override suspend fun fetchChannels(lineup: String?): List<LiveTvChannel> = record("fetchChannels($lineup)") { channels(lineup) }
    override suspend fun fetchSchedule(from: Instant?, to: Instant?): List<LiveTvProgram> = record("fetchSchedule") { schedule(from, to) }
    override suspend fun startPlayback(channelKey: String, dvrKey: String?, quality: TranscodeQualityPreset): LiveTvPlaybackSession? =
        record("startPlayback($channelKey,$dvrKey)") { start(channelKey, dvrKey, quality) }
    override suspend fun buildFavoriteChannelSource(lineup: String?): String = record("buildFavoriteChannelSource($lineup)") { favoriteSource(lineup) }
    override suspend fun fetchFavoriteChannels(migrate: Boolean, checkCurrent: (() -> Unit)?): List<FavoriteChannel> =
        record("fetchFavoriteChannels") { favorites(migrate) }
    override suspend fun setFavoriteChannels(channels: List<FavoriteChannel>, checkCurrent: (() -> Unit)?) =
        record("setFavoriteChannels") { saveFavorites(channels) }
    override suspend fun fetchDvrs(): List<LiveTvDvr> = record("fetchDvrs") { dvrs() }
    override suspend fun reloadGuide(dvrId: String) = record("reloadGuide($dvrId)") { reload(dvrId) }
    override suspend fun getSubscriptionTemplate(guid: String): List<SubscriptionTemplate> = record("getSubscriptionTemplate($guid)") { template(guid) }
    override suspend fun fetchRecordingRules(includeGrabs: Boolean, includeStorage: Boolean): List<MediaSubscription> =
        record("fetchRecordingRules") { rules(includeGrabs, includeStorage) }
    override suspend fun createRecordingRule(request: MediaSubscriptionCreateRequest): MediaSubscription? = record("createRecordingRule") { create(request) }
    override suspend fun updateRecordingRule(subscriptionId: String, prefs: Map<String, Any?>, checkCurrent: (() -> Unit)?): MediaSubscription? =
        record("updateRecordingRule($subscriptionId)") { update(subscriptionId, prefs) }
    override suspend fun deleteRecordingRule(subscriptionId: String) = record("deleteRecordingRule($subscriptionId)") { delete(subscriptionId) }
    override suspend fun processRecordingRules() = record("processRecordingRules") { process() }
    override suspend fun fetchScheduledRecordings(): List<MediaGrabOperation> = record("fetchScheduledRecordings") { scheduled() }
    override suspend fun cancelGrab(operationId: String) = record("cancelGrab($operationId)") { cancel(operationId) }
    override suspend fun fetchSubscriptionMapping(providerId: String, ratingKeys: List<String>, includeStorage: Boolean): List<MediaSubscription> =
        record("fetchSubscriptionMapping($providerId)") { mapping(providerId, ratingKeys) }
    override suspend fun fetchHubs(count: Int): List<LiveTvHub> = record("fetchHubs") { hubs(count) }

    private inline fun <T> record(call: String, block: () -> T): T {
        calls += call
        return block()
    }
}
