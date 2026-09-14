package com.edde746.plezy

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
    assertEquals("low_memory", AndroidExitReportMapper.mapReason(3))
    assertEquals("crash", AndroidExitReportMapper.mapReason(4))
    assertEquals("native_crash", AndroidExitReportMapper.mapReason(5))
    assertEquals("anr", AndroidExitReportMapper.mapReason(6))
    assertEquals("user_requested", AndroidExitReportMapper.mapReason(10))
    assertEquals("user_requested", AndroidExitReportMapper.mapReason(11))
    assertEquals("other", AndroidExitReportMapper.mapReason(1))
    assertEquals("other", AndroidExitReportMapper.mapReason(999))
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
    assertFalse(first.toMap().containsKey("description"))
    assertFalse(first.toMap().containsKey("processName"))
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
