package com.edde746.plezy.presentation.settings

import com.edde746.plezy.app.BundledText
import com.edde746.plezy.log.Log
import com.edde746.plezy.servers.childScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.coroutines.CoroutineContext

/**
 * About → Open Source Licenses: what this build ships on [os] ([ThirdPartyNotices]), sorted by name; with
 * [name], that component's licence texts, read from the app's bundled resources off the main thread ([readTexts]) and
 * reflowed to wrap at any width ([reflowLicense]). Call it on the main thread; [release] ends it.
 */
class LicensesStore internal constructor(
    os: String,
    name: String?,
    private val readTexts: (String) -> List<BundledText>,
    parentScope: CoroutineScope,
    io: CoroutineContext = Dispatchers.IO,
) {
    private val scope = parentScope.childScope()
    private val notices = ThirdPartyNotices.forPlatform(os).sortedBy { it.name.lowercase() }
    private val opened = name?.let { wanted -> notices.firstOrNull { it.name == wanted } ?: throw IllegalArgumentException("No component $wanted") }

    private val mutableState = MutableStateFlow(
        LicensesUiState(
            notices.map { LicenseEntryUi(it.name, it.license, it.url) },
            opened?.let { LicenseDetailUi(it.name, it.license, it.url, texts = null) },
        ),
    )
    val state: StateFlow<LicensesUiState> = mutableState.asStateFlow()

    init {
        opened?.let { notice ->
            scope.launch {
                val texts = withContext(io) { read(notice) }
                mutableState.value = mutableState.value.copy(detail = mutableState.value.detail?.copy(texts = texts))
            }
        }
    }

    fun release() {
        scope.cancel()
    }

    /** Every file under each of [notice]'s folders, in paragraphs; a folder that can't be read is logged and skipped. */
    private fun read(notice: ThirdPartyNotice): List<LicenseTextUi> = notice.texts.flatMap { folder ->
        val files = try {
            readTexts(folder)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e("settings", e) { "${notice.name}: reading the licence texts in $folder failed" }
            emptyList()
        }
        if (files.isEmpty()) Log.e("settings") { "${notice.name}: no licence text in $folder" }
        files.map { LicenseTextUi(it.path, reflowLicense(it.text)) }
    }
}
