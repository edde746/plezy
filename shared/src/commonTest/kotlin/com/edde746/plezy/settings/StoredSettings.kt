package com.edde746.plezy.settings

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.db.Device_setting
import com.edde746.plezy.data.db.Profile_setting

/** The JSON stored under the global [key], or null when unset. */
internal suspend fun LocalData.storedJson(key: String): String? =
    db.read { deviceSettingQueries.selectByKey(key).executeAsOneOrNull() }

/** Stores [json] under the global [key] as it is, as an import or an earlier release left it. */
internal suspend fun LocalData.store(key: String, json: String) {
    db.write { q.deviceSettingQueries.upsert(Device_setting(key, json)) }
}

/** The JSON stored under [key] for the profile scope [scope], or null when unset. */
internal suspend fun LocalData.storedProfileJson(scope: String, key: String): String? =
    db.read { deviceSettingQueries.selectProfileSetting(scope, key).executeAsOneOrNull() }

/** Stores [json] under [key] for the profile scope [scope] as it is. */
internal suspend fun LocalData.storeProfile(scope: String, key: String, json: String) {
    db.write { q.deviceSettingQueries.upsertProfileSetting(Profile_setting(scope, key, json)) }
}
