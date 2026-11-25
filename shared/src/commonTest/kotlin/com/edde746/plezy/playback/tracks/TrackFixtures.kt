package com.edde746.plezy.playback.tracks

import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaAudioTrack
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.model.SubtitlePlaybackMode

internal fun profile(
    autoSelectAudio: Boolean = true,
    defaultAudioLanguage: String? = null,
    defaultSubtitleLanguage: String? = null,
    subtitleMode: SubtitlePlaybackMode? = null,
) = AccountPreferences(
    selectAudioByLanguage = autoSelectAudio,
    preferredAudioLanguage = defaultAudioLanguage,
    preferredSubtitleLanguage = defaultSubtitleLanguage,
    subtitlePlaybackMode = subtitleMode,
)

internal fun audio(
    id: String,
    lang: String? = null,
    title: String? = null,
    codec: String? = null,
    channels: Int? = null,
    isDefault: Boolean = false,
) = NativeAudioTrack(id = id, language = lang, title = title, codec = codec, channels = channels, isDefault = isDefault)

internal fun sub(
    id: String,
    lang: String? = null,
    title: String? = null,
    codec: String? = null,
    isDefault: Boolean = false,
    isForced: Boolean = false,
    isExternal: Boolean = false,
    isContainer: Boolean = false,
    uri: String? = null,
) = NativeSubtitleTrack(
    id = id,
    language = lang,
    title = title,
    codec = codec,
    isDefault = isDefault,
    isForced = isForced,
    isExternal = isExternal,
    isContainer = isContainer,
    uri = uri,
)

internal fun sourceAudio(
    id: Int,
    index: Int? = null,
    language: String? = null,
    languageCode: String? = language,
    title: String? = null,
    displayTitle: String? = null,
    channels: Int? = null,
    selected: Boolean = false,
    codec: String? = null,
    isDefault: Boolean = false,
) = MediaAudioTrack(
    id = id,
    index = index,
    language = language,
    languageCode = languageCode,
    title = title,
    displayTitle = displayTitle,
    channels = channels,
    selected = selected,
    codec = codec,
    isDefault = isDefault,
)

internal fun sourceSub(
    id: Int,
    index: Int? = null,
    language: String? = null,
    languageCode: String? = language,
    title: String? = null,
    displayTitle: String? = null,
    selected: Boolean = false,
    forced: Boolean = false,
    codec: String? = null,
    external: Boolean = false,
    key: String? = null,
) = MediaSubtitleTrack(
    id = id,
    index = index,
    language = language,
    languageCode = languageCode,
    title = title,
    displayTitle = displayTitle,
    selected = selected,
    forced = forced,
    codec = codec,
    external = external,
    key = key,
)

internal fun sourceInfo(
    audio: List<MediaAudioTrack> = emptyList(),
    subs: List<MediaSubtitleTrack> = emptyList(),
    defaultAudioStreamIndex: Int? = null,
    defaultSubtitleStreamIndex: Int? = null,
    partId: Int? = null,
) = MediaSourceInfo(
    videoUrl = "",
    audioTracks = audio,
    subtitleTracks = subs,
    chapters = emptyList(),
    partId = partId,
    defaultAudioStreamIndex = defaultAudioStreamIndex,
    defaultSubtitleStreamIndex = defaultSubtitleStreamIndex,
)

internal fun selector(
    backend: BackendKind = BackendKind.PLEX,
    info: MediaSourceInfo? = null,
    profile: AccountPreferences? = null,
) = TrackSelector(backend, info, profile)

internal fun native(track: NativeSubtitleTrack) = PreferredSubtitle.Native(track)
