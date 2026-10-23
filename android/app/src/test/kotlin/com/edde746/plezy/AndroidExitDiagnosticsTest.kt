package com.edde746.plezy

import android.app.ApplicationExitInfo
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AndroidExitDiagnosticsTest {

  @Test
  fun mapsExitReasonsDeterministically() {
    mapOf(
      ApplicationExitInfo.REASON_EXIT_SELF to "exit_self",
      ApplicationExitInfo.REASON_SIGNALED to "signaled",
      ApplicationExitInfo.REASON_LOW_MEMORY to "low_memory",
      ApplicationExitInfo.REASON_CRASH to "crash",
      ApplicationExitInfo.REASON_CRASH_NATIVE to "native_crash",
      ApplicationExitInfo.REASON_ANR to "anr",
      ApplicationExitInfo.REASON_INITIALIZATION_FAILURE to "initialization_failure",
      ApplicationExitInfo.REASON_PERMISSION_CHANGE to "permission_change",
      ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE to "excessive_resource_usage",
      ApplicationExitInfo.REASON_USER_REQUESTED to "user_requested",
      ApplicationExitInfo.REASON_USER_STOPPED to "user_requested",
      ApplicationExitInfo.REASON_DEPENDENCY_DIED to "dependency_died",
      ApplicationExitInfo.REASON_FREEZER to "freezer",
      ApplicationExitInfo.REASON_PACKAGE_STATE_CHANGE to "package_state_change",
      ApplicationExitInfo.REASON_PACKAGE_UPDATED to "package_updated",
      ApplicationExitInfo.REASON_OTHER to "other",
      ApplicationExitInfo.REASON_UNKNOWN to "other",
      999 to "other"
    ).forEach { (code, reason) -> assertEquals("code $code", reason, AndroidExitReportMapper.mapReason(code)) }
  }

  @Test
  fun suppressesDuplicateAndReportsNewerRecord() {
    var storedKey: String? = null
    val store = PreviousExitReportStore(
      readDedupeKey = { storedKey },
      persistDedupeKey = { key ->
        storedKey = key
        true
      }
    )
    val first = mappedRecord(timestamp = 100)

    assertNotNull(store.takeIfNew(first))
    assertNull(store.takeIfNew(first))
    assertNotNull(store.takeIfNew(mappedRecord(timestamp = 101)))
  }

  @Test
  fun doesNotReportWhenDedupeKeyCannotBePersisted() {
    val report = mappedRecord(timestamp = 100)
    val store = PreviousExitReportStore(
      readDedupeKey = { null },
      persistDedupeKey = { false }
    )

    assertNull(store.takeIfNew(report))
  }

  @Test
  fun snapshotsPreviousPhaseBeforeMarkingCurrentLaunch() {
    var persistedPhase: String? = "database_ready"
    val store = StartupPhaseStore(
      readPhase = { persistedPhase },
      persistPhase = { phase ->
        persistedPhase = phase
        true
      }
    )

    assertEquals("database_ready", store.previousPhase)
    assertTrue(store.mark(AndroidStartupPhases.NATIVE_ON_CREATE))
    assertEquals("native_on_create", persistedPhase)
    assertEquals("database_ready", store.previousPhase)
  }

  @Test
  fun reportsStartupPhaseCommitFailure() {
    var attempts = 0
    val store = StartupPhaseStore(
      readPhase = { "database_ready" },
      persistPhase = {
        attempts++
        false
      }
    )

    assertFalse(store.mark("first_frame"))
    assertEquals(1, attempts)
    assertEquals("database_ready", store.previousPhase)
  }

  @Test
  fun acceptsOnlyFixedStartupPhaseVocabulary() {
    val written = mutableListOf<String>()
    val store = StartupPhaseStore(
      readPhase = { null },
      persistPhase = {
        written += it
        true
      }
    )
    val phases = listOf(
      "native_on_create",
      "dart_main",
      "runApp",
      "first_frame",
      "database_open_started",
      "database_ready",
      "credentials_loaded",
      "binding_started",
      "binding_settled",
      "main_screen"
    )

    phases.forEach { phase -> assertTrue(store.mark(phase)) }
    assertEquals(phases, written)
    assertFalse(store.mark("server_name"))
    assertEquals(phases, written)
  }

  @Test
  fun attachesPhaseWithoutChangingExitDedupeKey() {
    val firstFrame = mappedRecord(timestamp = 100, startupPhase = "first_frame")
    val mainScreen = mappedRecord(timestamp = 100, startupPhase = "main_screen")
    val invalid = mappedRecord(timestamp = 100, startupPhase = "profile-name")

    assertEquals(firstFrame.dedupeKey, mainScreen.dedupeKey)
    assertEquals("first_frame", firstFrame.toMap()["startupPhase"])
    assertEquals("main_screen", mainScreen.toMap()["startupPhase"])
    assertNull(invalid.startupPhase)
    assertFalse(invalid.toMap().containsKey("startupPhase"))
  }

  @Test
  fun dedupeKeyUsesStableMappedFieldsWithoutBeingReported() {
    val first = mappedRecord(timestamp = 100)
    val same = mappedRecord(timestamp = 100)
    val newer = mappedRecord(timestamp = 101)

    assertEquals(first.dedupeKey, same.dedupeKey)
    assertNotEquals(first.dedupeKey, newer.dedupeKey)
    assertEquals(
      setOf("reason", "status", "importance", "timestamp", "deviceModel", "apiLevel", "abi", "lowRam"),
      first.toMap().keys
    )
    assertFalse(first.toMap().containsKey("dedupeKey"))
    assertFalse(first.toMap().containsKey("processName"))
  }

  @Test
  fun masksExitDescriptionToFixedCharactersWithoutIdentifiers() {
    val sanitize = AndroidExitReportMapper::sanitizeDescription
    assertEquals(
      "[FORCE STOP] stop <pkg> due to from pid #",
      sanitize("[FORCE STOP] stop com.edde746.plezy due to from pid 6092")
    )
    assertEquals(
      "excessive cpu # during # dur=# limit=#",
      sanitize("excessive cpu 1234 during 300000 dur=300000 limit=2")
    )
    assertEquals("kill server", sanitize("kill\u0000 ü\n server"))
    assertNull(sanitize("ü\u0000"))
    assertNull(sanitize(null))
    assertEquals(120, sanitize("a".repeat(500))!!.length)
  }

  @Test
  fun reportsDescriptionAndOnlyPlausibleMemoryFigures() {
    val mapped = AndroidExitReportMapper.map(
      record = HistoricalExitRecord(
        reason = 3,
        status = 0,
        importance = 400,
        timestamp = 100,
        description = "too many cached",
        pssKb = 204_800,
        rssKb = 0
      ),
      deviceModel = "NVIDIA Shield",
      apiLevel = 35,
      abi = "arm64-v8a",
      lowRam = false
    ).toMap()

    assertEquals("too many cached", mapped["description"])
    assertEquals(204_800L, mapped["pssKb"])
    assertFalse(mapped.containsKey("rssKb"))
  }

  @Test
  fun sanitizesDeviceFieldsWithoutAcceptingArbitraryAbiValues() {
    val mapped = AndroidExitReportMapper.map(
      record = HistoricalExitRecord(reason = 6, status = 0, importance = 100, timestamp = 100),
      deviceModel = "  Shield\u0000   Pro  ",
      apiLevel = 35,
      abi = "user-supplied",
      lowRam = false
    )

    assertEquals("Shield Pro", mapped.deviceModel)
    assertEquals("unknown", mapped.abi)
  }

  @Test
  fun mapsOnlyFixedRuntimeDiagnosticFields() {
    val mapped = AndroidExitReportMapper.map(
      record = HistoricalExitRecord(reason = 5, status = 0, importance = 100, timestamp = 100),
      deviceModel = "NVIDIA Shield",
      apiLevel = 35,
      abi = "arm64-v8a",
      lowRam = false,
      runtime = RuntimeDiagnosticSnapshot(
        codecContext = "audio:truehd",
        channelCount = 8,
        sampleRate = 48000,
        selectedDecoder = "c2.android.truehd.decoder",
        passthroughEnabled = true,
        downmixEnabled = false,
        normalizationEnabled = false,
        uiState = "player"
      )
    ).toMap()

    assertEquals("audio:truehd", mapped["codecContext"])
    assertEquals(8, mapped["channelCount"])
    assertEquals(48000, mapped["sampleRate"])
    assertEquals("c2.android.truehd.decoder", mapped["selectedDecoder"])
    assertEquals(true, mapped["passthroughEnabled"])
    assertEquals(false, mapped["downmixEnabled"])
    assertEquals(false, mapped["normalizationEnabled"])
    assertEquals("player", mapped["uiState"])
  }

  @Test
  fun reducesRemoteCodecMetadataToFixedContextValues() {
    assertEquals("audio:eac3", AndroidRuntimeDiagnostics.codecContextForMime("audio/eac3-joc"))
    assertEquals("video:dolby_vision", AndroidRuntimeDiagnostics.codecContextForMime("video/dolby-vision"))
    assertEquals("audio:other", AndroidRuntimeDiagnostics.codecContextForMime("audio/user-defined"))
    assertNull(AndroidRuntimeDiagnostics.codecContextForMime("https://example.test/private"))
    assertEquals("unknown", AndroidRuntimeDiagnostics.sanitizeDecoderName("decoder with a remote label"))
    assertNull(AndroidRuntimeDiagnostics.sanitizeUiState("server-name"))
  }

  private fun mappedRecord(timestamp: Long, startupPhase: String? = null): PreviousExitReport = AndroidExitReportMapper.map(
    record = HistoricalExitRecord(
      reason = 4,
      status = 1,
      importance = 100,
      timestamp = timestamp
    ),
    deviceModel = "NVIDIA Shield",
    apiLevel = 35,
    abi = "arm64-v8a",
    lowRam = false,
    startupPhase = startupPhase
  )
}
