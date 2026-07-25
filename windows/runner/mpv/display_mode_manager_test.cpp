#include "display_mode_manager.h"

#include <cstdlib>
#include <iostream>
#include <map>
#include <string>
#include <vector>

namespace mpv {
namespace {

constexpr wchar_t kVersion[] = L"Version";
constexpr wchar_t kModeDeviceName[] = L"ModeDeviceName";
constexpr wchar_t kLegacyDeviceName[] = L"DeviceName";
constexpr wchar_t kHDRDeviceName[] = L"HDRDeviceName";
constexpr wchar_t kOriginalRefreshRate[] = L"OriginalRefreshRate";
constexpr wchar_t kOriginalWidth[] = L"OriginalWidth";
constexpr wchar_t kOriginalHeight[] = L"OriginalHeight";
constexpr wchar_t kOriginalHDR[] = L"OriginalHDREnabled";
constexpr wchar_t kModeChanged[] = L"ModeChanged";
constexpr wchar_t kHDRChanged[] = L"HDRChanged";
constexpr wchar_t kModeTakeoverEligible[] = L"ModeTakeoverEligible";
constexpr wchar_t kHDRTakeoverEligible[] = L"HDRTakeoverEligible";
constexpr wchar_t kModeRecoverySlot[] = L"ModeRecoverySlot";
constexpr wchar_t kHDRRecoverySlot[] = L"HDRRecoverySlot";
constexpr wchar_t kModeDeviceNameAlternate[] = L"ModeDeviceNameAlternate";
constexpr wchar_t kHDRDeviceNameAlternate[] = L"HDRDeviceNameAlternate";
constexpr wchar_t kOriginalRefreshRateAlternate[] = L"OriginalRefreshRateAlternate";
constexpr wchar_t kOriginalWidthAlternate[] = L"OriginalWidthAlternate";
constexpr wchar_t kOriginalHeightAlternate[] = L"OriginalHeightAlternate";
constexpr wchar_t kOriginalHDRAlternate[] = L"OriginalHDREnabledAlternate";
constexpr wchar_t kModeHandoffPending[] = L"ModeHandoffPending";
constexpr wchar_t kHDRHandoffPending[] = L"HDRHandoffPending";
constexpr wchar_t kModePreviousRecoverySlot[] = L"ModePreviousRecoverySlot";
constexpr wchar_t kHDRPreviousRecoverySlot[] = L"HDRPreviousRecoverySlot";
constexpr wchar_t kModeDevice[] = L"\\\\.\\DISPLAY1";
constexpr wchar_t kHDRDevice[] = L"\\\\.\\DISPLAY2";
constexpr wchar_t kReplacementModeDevice[] = L"\\\\.\\DISPLAY3";
constexpr wchar_t kReplacementHDRDevice[] = L"\\\\.\\DISPLAY4";

void Check(bool condition, const char* message) {
  if (!condition) {
    std::cerr << "display_mode_manager_test: " << message << '\n';
    std::exit(1);
  }
}

struct ExpectedModeRestore {
  std::wstring device_name;
  DWORD width;
  DWORD height;
  DWORD refresh_rate;
};

struct ExpectedHDRRestore {
  std::wstring device_name;
  bool enabled;
};

class FakeRecoveryBackend final : public DisplayRecoveryBackend {
 public:
  std::map<std::wstring, DWORD> dwords;
  std::map<std::wstring, std::wstring> strings;
  std::map<std::wstring, bool> device_present = {
      {kModeDevice, true}, {kHDRDevice, true}, {kReplacementModeDevice, true}, {kReplacementHDRDevice, true}};
  std::vector<std::wstring> events;
  std::wstring expected_mode_device = kModeDevice;
  DWORD expected_mode_width = 3840;
  DWORD expected_mode_height = 2160;
  DWORD expected_mode_refresh_rate = 60;
  std::wstring expected_hdr_device = kHDRDevice;
  bool expected_original_hdr = false;
  std::vector<ExpectedModeRestore> expected_mode_restores;
  std::vector<ExpectedHDRRestore> expected_hdr_restores;
  size_t mode_restore_attempts = 0;
  size_t hdr_restore_attempts = 0;
  bool mode_restore_succeeds = true;
  bool hdr_restore_succeeds = true;
  bool mode_marker_clear_succeeds = true;
  bool hdr_marker_clear_succeeds = true;
  bool delete_succeeds = true;
  bool final_mode_marker_write_succeeds = true;
  bool final_hdr_marker_write_succeeds = true;
  std::wstring rejected_dword_write_event;
  int delete_attempts = 0;

  void SeedBoth() {
    dwords[kVersion] = 1;
    dwords[kModeChanged] = 1;
    dwords[kHDRChanged] = 1;
    dwords[kOriginalWidth] = 3840;
    dwords[kOriginalHeight] = 2160;
    dwords[kOriginalRefreshRate] = 60;
    dwords[kOriginalHDR] = 0;
    strings[kModeDeviceName] = kModeDevice;
    strings[kHDRDeviceName] = kHDRDevice;
  }

  bool RecordExists() const override { return !dwords.empty() || !strings.empty(); }

  bool ReadDWORD(const wchar_t* value_name, DWORD& value) override {
    const auto it = dwords.find(value_name);
    if (it == dwords.end()) return false;
    value = it->second;
    return true;
  }

  bool ReadString(const wchar_t* value_name, std::wstring& value) override {
    const auto it = strings.find(value_name);
    if (it == strings.end()) return false;
    value = it->second;
    return true;
  }

  bool WriteDWORD(const wchar_t* value_name, DWORD value) override {
    const std::wstring name(value_name);
    const std::wstring event = L"write:" + name + L"=" + std::to_wstring(value);
    events.push_back(event);
    if (event == rejected_dword_write_event ||
        (name == kModeChanged && value == 1 && !final_mode_marker_write_succeeds) ||
        (name == kHDRChanged && value == 1 && !final_hdr_marker_write_succeeds)) {
      return false;
    }
    dwords[name] = value;
    return true;
  }

  bool WriteString(const wchar_t* value_name, const std::wstring& value) override {
    const std::wstring name(value_name);
    events.push_back(L"write:" + name);
    strings[name] = value;
    return true;
  }

  bool IsDevicePresent(const std::wstring& device_name) const override {
    const auto it = device_present.find(device_name);
    return it != device_present.end() && it->second;
  }

  bool RestoreMode(const std::wstring& device_name, DWORD width, DWORD height, DWORD refresh_rate) override {
    if (expected_mode_restores.empty()) {
      Check(device_name == expected_mode_device, "mode restore must use its persisted display");
      Check(
          width == expected_mode_width && height == expected_mode_height && refresh_rate == expected_mode_refresh_rate,
          "mode restore must use persisted originals");
    } else {
      Check(mode_restore_attempts < expected_mode_restores.size(), "mode recovery made an unexpected extra restore");
      const auto& expected = expected_mode_restores[mode_restore_attempts];
      Check(device_name == expected.device_name, "mode handoff restore order must be deterministic");
      Check(
          width == expected.width && height == expected.height && refresh_rate == expected.refresh_rate,
          "mode handoff restore must use each persisted original");
    }
    ++mode_restore_attempts;
    events.push_back(L"restore:mode");
    return mode_restore_succeeds;
  }

  bool RestoreHDR(const std::wstring& device_name, bool enabled) override {
    if (expected_hdr_restores.empty()) {
      Check(device_name == expected_hdr_device, "HDR restore must use its independently persisted display");
      Check(enabled == expected_original_hdr, "HDR restore must use the persisted original state");
    } else {
      Check(hdr_restore_attempts < expected_hdr_restores.size(), "HDR recovery made an unexpected extra restore");
      const auto& expected = expected_hdr_restores[hdr_restore_attempts];
      Check(device_name == expected.device_name, "HDR handoff restore order must be deterministic");
      Check(enabled == expected.enabled, "HDR handoff restore must use each persisted original");
    }
    ++hdr_restore_attempts;
    events.push_back(L"restore:hdr");
    return hdr_restore_succeeds;
  }

  bool ClearMarker(const wchar_t* value_name) override {
    const std::wstring name(value_name);
    events.push_back(L"clear:" + name);
    const bool succeeds = name == kModeChanged ? mode_marker_clear_succeeds : hdr_marker_clear_succeeds;
    if (succeeds) dwords[name] = 0;
    return succeeds;
  }

  bool DeleteRecord() override {
    ++delete_attempts;
    events.push_back(L"delete");
    if (!delete_succeeds) return false;
    dwords.clear();
    strings.clear();
    return true;
  }
};

size_t EventIndex(const std::vector<std::wstring>& events, const std::wstring& event) {
  for (size_t index = 0; index < events.size(); ++index) {
    if (events[index] == event) return index;
  }
  return events.size();
}

bool ApplyModeAfterPreparing(
    FakeRecoveryBackend& backend, const std::wstring& device_name = kModeDevice, DWORD width = 3840,
    DWORD height = 2160, DWORD refresh_rate = 60, bool os_apply_succeeds = true) {
  if (!DisplayModeManager::PrepareModeRecovery(backend, device_name, width, height, refresh_rate)) {
    return false;
  }
  backend.events.push_back(os_apply_succeeds ? L"os:mode" : L"os:mode:failed");
  DisplayModeManager::FinalizePreparedRecoveryForTesting(backend, true, os_apply_succeeds);
  return os_apply_succeeds;
}

bool ApplyHDRAfterPreparing(
    FakeRecoveryBackend& backend, const std::wstring& device_name = kHDRDevice, bool enabled = false,
    bool os_apply_succeeds = true) {
  if (!DisplayModeManager::PrepareHDRRecovery(backend, device_name, enabled)) return false;
  backend.events.push_back(os_apply_succeeds ? L"os:hdr" : L"os:hdr:failed");
  DisplayModeManager::FinalizePreparedRecoveryForTesting(backend, false, os_apply_succeeds);
  return os_apply_succeeds;
}

void TestMarkersArePersistedBeforeMutation() {
  FakeRecoveryBackend mode;
  Check(ApplyModeAfterPreparing(mode), "a complete mode recovery record must admit the OS mutation");
  const size_t mode_marker = EventIndex(mode.events, L"write:ModeChanged=1");
  const size_t mode_os = EventIndex(mode.events, L"os:mode");
  Check(mode_marker < mode_os, "the mode marker must be durable before the OS mutation");
  Check(
      EventIndex(mode.events, L"write:ModeDeviceName") < mode_marker &&
          EventIndex(mode.events, L"write:OriginalWidth=3840") < mode_marker &&
          EventIndex(mode.events, L"write:OriginalHeight=2160") < mode_marker &&
          EventIndex(mode.events, L"write:OriginalRefreshRate=60") < mode_marker &&
          EventIndex(mode.events, L"write:ModeTakeoverEligible=0") < mode_marker &&
          EventIndex(mode.events, L"write:ModeRecoverySlot=0") < mode_marker,
      "all mode originals, slot, and reset disposition must precede the operation marker");

  FakeRecoveryBackend hdr;
  Check(ApplyHDRAfterPreparing(hdr), "a complete HDR recovery record must admit the OS mutation");
  const size_t hdr_marker = EventIndex(hdr.events, L"write:HDRChanged=1");
  Check(
      EventIndex(hdr.events, L"write:HDRDeviceName") < hdr_marker &&
          EventIndex(hdr.events, L"write:OriginalHDREnabled=0") < hdr_marker &&
          EventIndex(hdr.events, L"write:HDRTakeoverEligible=0") < hdr_marker &&
          EventIndex(hdr.events, L"write:HDRRecoverySlot=0") < hdr_marker &&
          hdr_marker < EventIndex(hdr.events, L"os:hdr"),
      "the HDR original, slot, reset disposition, and marker must be durable before the OS mutation");

  FakeRecoveryBackend failed_marker;
  failed_marker.final_mode_marker_write_succeeds = false;
  Check(
      !ApplyModeAfterPreparing(failed_marker),
      "an OS mutation must not run when its final recovery marker cannot be persisted");
  Check(
      EventIndex(failed_marker.events, L"os:mode") == failed_marker.events.size(),
      "a failed marker write must leave the display untouched");
}

void TestMalformedRecordIsIgnored() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.dwords[kVersion] = 2;
  backend.strings[kLegacyDeviceName] = kModeDevice;

  Check(!DisplayModeManager::RecoverIfNeeded(backend), "an unknown recovery version must be ignored");
  Check(
      EventIndex(backend.events, L"restore:mode") == backend.events.size() &&
          EventIndex(backend.events, L"restore:hdr") == backend.events.size(),
      "a malformed record must not reach display APIs");
  Check(backend.delete_attempts == 1 && !backend.RecordExists(), "a malformed record must be discarded");
}

void TestValidModeSurvivesMalformedHDR() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.dwords[kOriginalHDR] = 2;

  Check(
      DisplayModeManager::RecoverIfNeeded(backend),
      "malformed HDR evidence must not discard an independently valid mode restore");
  Check(
      EventIndex(backend.events, L"restore:mode") < backend.events.size() &&
          EventIndex(backend.events, L"restore:hdr") == backend.events.size(),
      "only the valid mode operation may reach a display API");
  Check(
      EventIndex(backend.events, L"clear:HDRChanged") < backend.events.size(),
      "the malformed HDR operation must be discarded independently");
}

void TestValidHDRSurvivesMalformedMode() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.dwords.erase(kOriginalHeight);

  Check(
      DisplayModeManager::RecoverIfNeeded(backend),
      "malformed mode evidence must not discard an independently valid HDR restore");
  Check(
      EventIndex(backend.events, L"restore:mode") == backend.events.size() &&
          EventIndex(backend.events, L"restore:hdr") < backend.events.size(),
      "only the valid HDR operation may reach a display API");
  Check(
      EventIndex(backend.events, L"clear:ModeChanged") < backend.events.size(),
      "the malformed mode operation must be discarded independently");
}

void TestPreparationClearsMalformedSibling() {
  FakeRecoveryBackend mode;
  mode.SeedBoth();
  mode.dwords[kModeChanged] = 0;
  mode.dwords[kOriginalHDR] = 2;
  Check(ApplyModeAfterPreparing(mode), "a malformed HDR sibling must not block a new valid mode operation");
  Check(mode.dwords[kHDRChanged] == 0, "mode preparation must not preserve malformed HDR evidence");

  FakeRecoveryBackend hdr;
  hdr.SeedBoth();
  hdr.dwords[kHDRChanged] = 0;
  hdr.dwords.erase(kOriginalHeight);
  Check(ApplyHDRAfterPreparing(hdr), "a malformed mode sibling must not block a new valid HDR operation");
  Check(hdr.dwords[kModeChanged] == 0, "HDR preparation must not preserve malformed mode evidence");
}

void TestModeAndHDRRestoreIndependently() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.mode_restore_succeeds = false;

  Check(!DisplayModeManager::RecoverIfNeeded(backend), "one failed restore must retain the record");
  Check(
      EventIndex(backend.events, L"restore:mode") < backend.events.size() &&
          EventIndex(backend.events, L"restore:hdr") < backend.events.size(),
      "mode failure must not prevent the independent HDR restore");
  Check(
      backend.dwords[kModeChanged] == 1 && backend.dwords[kModeTakeoverEligible] == 1,
      "the failed mode marker and its takeover disposition must remain set");
  Check(
      backend.dwords[kHDRChanged] == 0 && backend.dwords[kHDRTakeoverEligible] == 0,
      "the successful HDR marker and matching disposition must be cleared");

  backend.events.clear();
  backend.mode_restore_succeeds = true;
  Check(DisplayModeManager::RecoverIfNeeded(backend), "a later pass must finish the retained mode restore");
  Check(
      EventIndex(backend.events, L"restore:mode") < backend.events.size() &&
          EventIndex(backend.events, L"restore:hdr") == backend.events.size(),
      "a later pass must not repeat the completed HDR restore");
}

void TestFailedRestoreRemainsForTopologyRetry() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.dwords[kHDRChanged] = 0;
  backend.device_present[kModeDevice] = false;

  Check(!DisplayModeManager::RecoverIfNeeded(backend), "an absent display must retain its marked restore");
  Check(
      backend.dwords[kModeChanged] == 1 && backend.dwords[kModeTakeoverEligible] == 1,
      "an absent display must keep its operation marker and persist takeover eligibility");
  Check(
      EventIndex(backend.events, L"restore:mode") == backend.events.size(),
      "an absent display must not call its restore API");

  backend.events.clear();
  backend.device_present[kModeDevice] = true;
  Check(
      DisplayModeManager::RecoverIfNeeded(backend), "a synchronous topology retry must restore a reconnected display");
  Check(
      EventIndex(backend.events, L"restore:mode") < backend.events.size(),
      "the topology retry must attempt the retained restore");
  Check(
      !backend.RecordExists() && backend.dwords.find(kModeTakeoverEligible) == backend.dwords.end(),
      "reconnect recovery must clear the marker and remove its disposition through normal cleanup");
}

void TestMarkerClearFailureRemainsRetryable() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.dwords[kHDRChanged] = 0;
  backend.mode_marker_clear_succeeds = false;

  Check(!DisplayModeManager::RecoverIfNeeded(backend), "marker persistence is part of recovery completion");
  Check(
      backend.dwords[kModeChanged] == 1 && backend.dwords[kModeTakeoverEligible] == 1,
      "a failed marker clear must retain recovery evidence and become takeover eligible");

  backend.events.clear();
  backend.mode_marker_clear_succeeds = true;
  Check(DisplayModeManager::RecoverIfNeeded(backend), "a later pass must retry after marker persistence failure");
  Check(
      EventIndex(backend.events, L"restore:mode") < backend.events.size(),
      "the retained marker must cause the restore to be retried");
  Check(!backend.RecordExists(), "the successful retry must remove the marker and stale disposition");
}

void TestLifecycleCleanupPreservesPersistedSibling() {
  FakeRecoveryBackend mode_completed;
  mode_completed.SeedBoth();
  mode_completed.dwords[kModeTakeoverEligible] = 1;
  mode_completed.dwords[kHDRTakeoverEligible] = 1;
  Check(
      DisplayModeManager::CompleteRecoveryOperationForTesting(mode_completed, true),
      "successful mode cleanup must durably clear its own marker");
  Check(
      mode_completed.dwords[kModeChanged] == 0 && mode_completed.dwords[kModeTakeoverEligible] == 0 &&
          mode_completed.dwords[kHDRChanged] == 1 && mode_completed.dwords[kHDRTakeoverEligible] == 1,
      "mode cleanup must reset only its disposition while preserving a persisted HDR sibling");
  Check(
      mode_completed.dwords[kOriginalHDR] == 0 && mode_completed.strings[kHDRDeviceName] == kHDRDevice &&
          mode_completed.delete_attempts == 0,
      "mode cleanup must retain the HDR original and avoid deleting its record");

  FakeRecoveryBackend hdr_failed_apply;
  hdr_failed_apply.SeedBoth();
  hdr_failed_apply.dwords[kModeTakeoverEligible] = 1;
  hdr_failed_apply.dwords[kHDRTakeoverEligible] = 1;
  Check(
      DisplayModeManager::CompleteRecoveryOperationForTesting(hdr_failed_apply, false),
      "failed HDR apply cleanup must durably clear its own marker");
  Check(
      hdr_failed_apply.dwords[kHDRChanged] == 0 && hdr_failed_apply.dwords[kHDRTakeoverEligible] == 0 &&
          hdr_failed_apply.dwords[kModeChanged] == 1 && hdr_failed_apply.dwords[kModeTakeoverEligible] == 1,
      "HDR cleanup must reset only its disposition while preserving a persisted mode sibling");
  Check(
      hdr_failed_apply.dwords[kOriginalWidth] == 3840 && hdr_failed_apply.strings[kModeDeviceName] == kModeDevice &&
          hdr_failed_apply.delete_attempts == 0,
      "HDR cleanup must retain the mode original and avoid deleting its record");
}

void TestReleasedLiveOperationRecoversAfterReconnect() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.device_present[kModeDevice] = false;

  Check(
      !DisplayModeManager::RecoverIfNeededForTesting(backend, true, true),
      "topology recovery must not take either genuinely live operation");
  Check(backend.events.empty(), "live operations must not reach restore or persistence APIs");
  Check(
      backend.dwords.find(kModeTakeoverEligible) == backend.dwords.end() &&
          backend.dwords.find(kHDRTakeoverEligible) == backend.dwords.end(),
      "live operations must not acquire takeover dispositions");

  Check(
      !DisplayModeManager::RecoverIfNeededForTesting(backend, false, true),
      "a released operation must remain marked while its target is absent");
  Check(
      backend.dwords[kModeChanged] == 1 && backend.dwords[kModeTakeoverEligible] == 1 &&
          backend.dwords[kHDRChanged] == 1,
      "an absent released mode must become eligible without changing its live HDR sibling");

  backend.events.clear();
  backend.device_present[kModeDevice] = true;
  Check(
      DisplayModeManager::RecoverIfNeededForTesting(backend, false, true),
      "a topology retry must restore the released mode after reconnect");
  Check(
      EventIndex(backend.events, L"restore:mode") < backend.events.size() &&
          EventIndex(backend.events, L"restore:hdr") == backend.events.size(),
      "reconnect recovery must restore the released mode without stealing live HDR");
  Check(
      backend.dwords[kModeChanged] == 0 && backend.dwords[kModeTakeoverEligible] == 0 &&
          backend.dwords[kHDRChanged] == 1 && backend.delete_attempts == 0,
      "reconnect recovery must clear its disposition while preserving the live sibling record");
}

void TestUnfailedMarkersRejectSameKindTakeover() {
  FakeRecoveryBackend mode;
  mode.SeedBoth();
  const auto mode_dwords = mode.dwords;
  const auto mode_strings = mode.strings;

  Check(
      !ApplyModeAfterPreparing(mode, kReplacementModeDevice, 2560, 1440, 120),
      "a version-1 mode marker without a failed-recovery disposition must remain authoritative");
  Check(
      mode.dwords == mode_dwords && mode.strings == mode_strings && mode.events.empty(),
      "rejected mode takeover must not rewrite either operation or reach the OS mutation");

  FakeRecoveryBackend hdr;
  hdr.SeedBoth();
  hdr.dwords[kHDRTakeoverEligible] = 2;
  const auto hdr_dwords = hdr.dwords;
  const auto hdr_strings = hdr.strings;

  Check(
      !ApplyHDRAfterPreparing(hdr, kReplacementHDRDevice, true),
      "only an HDR takeover disposition of exactly one may replace a valid marker");
  Check(
      hdr.dwords == hdr_dwords && hdr.strings == hdr_strings && hdr.events.empty(),
      "rejected HDR takeover must preserve its mode sibling and avoid the OS mutation");
}

void TestAbsentModeTakeoverSurvivesRelaunchAndPreservesHDRSibling() {
  FakeRecoveryBackend failed_recovery;
  failed_recovery.SeedBoth();
  failed_recovery.dwords[kModeTakeoverEligible] = 0;
  failed_recovery.dwords[kHDRTakeoverEligible] = 1;
  failed_recovery.device_present[kModeDevice] = false;

  Check(
      !DisplayModeManager::RecoverIfNeededForTesting(failed_recovery, false, true),
      "an absent mode target must produce a retained failed recovery");
  Check(
      failed_recovery.dwords[kModeChanged] == 1 && failed_recovery.dwords[kModeTakeoverEligible] == 1,
      "the failed non-live mode recovery must durably become takeover eligible");
  Check(
      failed_recovery.dwords[kHDRChanged] == 1 && failed_recovery.dwords[kHDRTakeoverEligible] == 1 &&
          failed_recovery.dwords[kOriginalHDR] == 0 && failed_recovery.strings[kHDRDeviceName] == kHDRDevice,
      "recording mode failure must not alter the live HDR sibling");

  // A new backend represents the next process reading only persisted state.
  FakeRecoveryBackend relaunched;
  relaunched.dwords = failed_recovery.dwords;
  relaunched.strings = failed_recovery.strings;
  Check(
      ApplyModeAfterPreparing(relaunched, kReplacementModeDevice, 2560, 1440, 120),
      "a persisted failed mode recovery must admit a conflicting request after relaunch");
  Check(
      relaunched.dwords[kModeChanged] == 1 && relaunched.dwords[kModeTakeoverEligible] == 0 &&
          relaunched.dwords[kModeRecoverySlot] == 1 && relaunched.dwords[kOriginalWidthAlternate] == 2560 &&
          relaunched.dwords[kOriginalHeightAlternate] == 1440 &&
          relaunched.dwords[kOriginalRefreshRateAlternate] == 120 &&
          relaunched.strings[kModeDeviceNameAlternate] == kReplacementModeDevice,
      "mode takeover must atomically select its staged original and revoke the consumed disposition");
  Check(
      relaunched.dwords[kOriginalWidth] == 3840 && relaunched.dwords[kOriginalHeight] == 2160 &&
          relaunched.dwords[kOriginalRefreshRate] == 60 && relaunched.strings[kModeDeviceName] == kModeDevice,
      "mode takeover must retain the prior originals in the inactive slot");
  Check(
      relaunched.dwords[kHDRChanged] == 1 && relaunched.dwords[kHDRTakeoverEligible] == 1 &&
          relaunched.dwords[kOriginalHDR] == 0 && relaunched.strings[kHDRDeviceName] == kHDRDevice,
      "mode takeover must preserve every persisted HDR sibling value");
  Check(
      EventIndex(relaunched.events, L"write:ModeTakeoverEligible=0") <
              EventIndex(relaunched.events, L"write:ModeRecoverySlot=1") &&
          EventIndex(relaunched.events, L"write:ModeRecoverySlot=1") < EventIndex(relaunched.events, L"os:mode") &&
          EventIndex(relaunched.events, L"clear:ModeChanged") == relaunched.events.size() &&
          EventIndex(relaunched.events, L"write:ModeChanged=1") == relaunched.events.size(),
      "mode takeover must keep its marker authoritative and commit the staged slot immediately before mutation");

  FakeRecoveryBackend recovery_relaunch;
  recovery_relaunch.dwords = relaunched.dwords;
  recovery_relaunch.strings = relaunched.strings;
  recovery_relaunch.expected_mode_device = kReplacementModeDevice;
  recovery_relaunch.expected_mode_width = 2560;
  recovery_relaunch.expected_mode_height = 1440;
  recovery_relaunch.expected_mode_refresh_rate = 120;
  Check(
      DisplayModeManager::RecoverIfNeededForTesting(recovery_relaunch, false, true),
      "relaunch recovery must follow the committed mode slot");
  Check(
      EventIndex(recovery_relaunch.events, L"restore:mode") < recovery_relaunch.events.size(),
      "the committed alternate mode original must reach recovery");
}

void TestBadModeHDRRestoreAllowsSameKindTakeover() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.dwords[kModeTakeoverEligible] = 1;
  backend.dwords[kHDRTakeoverEligible] = 0;
  backend.hdr_restore_succeeds = false;

  Check(
      !DisplayModeManager::RecoverIfNeededForTesting(backend, true, false),
      "a present HDR target whose restore fails must retain its marker");
  Check(
      EventIndex(backend.events, L"restore:hdr") < backend.events.size() && backend.dwords[kHDRChanged] == 1 &&
          backend.dwords[kHDRTakeoverEligible] == 1,
      "a failed HDR restore must durably grant only HDR takeover");

  backend.events.clear();
  Check(
      ApplyHDRAfterPreparing(backend, kReplacementHDRDevice, true),
      "a later conflicting HDR request must consume the failed-restore disposition");
  Check(
      backend.dwords[kHDRChanged] == 1 && backend.dwords[kHDRTakeoverEligible] == 0 &&
          backend.dwords[kHDRRecoverySlot] == 1 && backend.dwords[kOriginalHDRAlternate] == 1 &&
          backend.strings[kHDRDeviceNameAlternate] == kReplacementHDRDevice,
      "HDR takeover must atomically select its staged replacement original");
  Check(
      backend.dwords[kOriginalHDR] == 0 && backend.strings[kHDRDeviceName] == kHDRDevice,
      "HDR takeover must retain the prior original in the inactive slot");
  Check(
      backend.dwords[kModeChanged] == 1 && backend.dwords[kModeTakeoverEligible] == 1 &&
          backend.dwords[kOriginalWidth] == 3840 && backend.dwords[kOriginalHeight] == 2160 &&
          backend.dwords[kOriginalRefreshRate] == 60 && backend.strings[kModeDeviceName] == kModeDevice,
      "HDR takeover must preserve every persisted mode sibling value");
  Check(
      EventIndex(backend.events, L"write:HDRTakeoverEligible=0") <
              EventIndex(backend.events, L"write:HDRRecoverySlot=1") &&
          EventIndex(backend.events, L"write:HDRRecoverySlot=1") < EventIndex(backend.events, L"os:hdr") &&
          EventIndex(backend.events, L"clear:HDRChanged") == backend.events.size() &&
          EventIndex(backend.events, L"write:HDRChanged=1") == backend.events.size(),
      "HDR takeover must keep its marker authoritative and commit the staged slot immediately before mutation");

  FakeRecoveryBackend recovery_relaunch;
  recovery_relaunch.dwords = backend.dwords;
  recovery_relaunch.strings = backend.strings;
  recovery_relaunch.expected_hdr_device = kReplacementHDRDevice;
  recovery_relaunch.expected_original_hdr = true;
  Check(
      DisplayModeManager::RecoverIfNeededForTesting(recovery_relaunch, true, false),
      "relaunch recovery must follow the committed HDR slot");
  Check(
      EventIndex(recovery_relaunch.events, L"restore:hdr") < recovery_relaunch.events.size(),
      "the committed alternate HDR original must reach recovery");
}

void TestFailedOSApplyRollsBackTakeover() {
  FakeRecoveryBackend mode;
  mode.SeedBoth();
  mode.dwords[kModeTakeoverEligible] = 1;
  mode.dwords[kHDRTakeoverEligible] = 1;
  Check(
      !ApplyModeAfterPreparing(mode, kReplacementModeDevice, 2560, 1440, 120, false),
      "a failed mode OS apply must report failure");
  Check(
      mode.dwords[kModeChanged] == 1 && mode.dwords[kModeRecoverySlot] == 0 &&
          mode.dwords[kModeTakeoverEligible] == 1 && mode.dwords[kModeHandoffPending] == 0 &&
          mode.dwords[kOriginalWidth] == 3840 && mode.dwords[kOriginalHeight] == 2160 &&
          mode.dwords[kOriginalRefreshRate] == 60 && mode.strings[kModeDeviceName] == kModeDevice &&
          mode.dwords[kHDRChanged] == 1 && mode.dwords[kHDRTakeoverEligible] == 1,
      "failed mode apply must restore the prior selector, eligibility, original, and sibling");
  Check(
      EventIndex(mode.events, L"write:ModeHandoffPending=1") < EventIndex(mode.events, L"write:ModeRecoverySlot=1") &&
          EventIndex(mode.events, L"write:ModeRecoverySlot=1") < EventIndex(mode.events, L"os:mode:failed") &&
          EventIndex(mode.events, L"os:mode:failed") < EventIndex(mode.events, L"write:ModeRecoverySlot=0") &&
          EventIndex(mode.events, L"clear:ModeChanged") == mode.events.size(),
      "mode rollback must retain both records until the failed OS apply is observed");

  FakeRecoveryBackend mode_relaunch;
  mode_relaunch.dwords = mode.dwords;
  mode_relaunch.strings = mode.strings;
  Check(
      DisplayModeManager::RecoverIfNeededForTesting(mode_relaunch, false, true),
      "relaunch after failed mode apply must recover the prior original");

  FakeRecoveryBackend hdr;
  hdr.SeedBoth();
  hdr.dwords[kModeTakeoverEligible] = 1;
  hdr.dwords[kHDRTakeoverEligible] = 1;
  Check(!ApplyHDRAfterPreparing(hdr, kReplacementHDRDevice, true, false), "a failed HDR OS apply must report failure");
  Check(
      hdr.dwords[kHDRChanged] == 1 && hdr.dwords[kHDRRecoverySlot] == 0 && hdr.dwords[kHDRTakeoverEligible] == 1 &&
          hdr.dwords[kHDRHandoffPending] == 0 && hdr.dwords[kOriginalHDR] == 0 &&
          hdr.strings[kHDRDeviceName] == kHDRDevice && hdr.dwords[kModeChanged] == 1 &&
          hdr.dwords[kModeTakeoverEligible] == 1,
      "failed HDR apply must restore the prior selector, eligibility, original, and sibling");
  Check(
      EventIndex(hdr.events, L"write:HDRHandoffPending=1") < EventIndex(hdr.events, L"write:HDRRecoverySlot=1") &&
          EventIndex(hdr.events, L"write:HDRRecoverySlot=1") < EventIndex(hdr.events, L"os:hdr:failed") &&
          EventIndex(hdr.events, L"os:hdr:failed") < EventIndex(hdr.events, L"write:HDRRecoverySlot=0") &&
          EventIndex(hdr.events, L"clear:HDRChanged") == hdr.events.size(),
      "HDR rollback must retain both records until the failed OS apply is observed");

  FakeRecoveryBackend hdr_relaunch;
  hdr_relaunch.dwords = hdr.dwords;
  hdr_relaunch.strings = hdr.strings;
  Check(
      DisplayModeManager::RecoverIfNeededForTesting(hdr_relaunch, true, false),
      "relaunch after failed HDR apply must recover the prior original");
}

void TestCrashDuringTakeoverHandoffRecoversBothOriginals() {
  FakeRecoveryBackend mode;
  mode.SeedBoth();
  mode.dwords[kModeTakeoverEligible] = 1;
  mode.dwords[kHDRTakeoverEligible] = 1;
  Check(
      DisplayModeManager::PrepareModeRecovery(mode, kReplacementModeDevice, 2560, 1440, 120),
      "mode takeover preparation must reach its pre-apply handoff");
  Check(
      mode.dwords[kModeChanged] == 1 && mode.dwords[kModeHandoffPending] == 1 &&
          mode.dwords[kModePreviousRecoverySlot] == 0 && mode.dwords[kModeRecoverySlot] == 1,
      "mode pre-apply handoff must retain both slot identities under one marker");
  mode.expected_mode_restores = {{kReplacementModeDevice, 2560, 1440, 120}, {kModeDevice, 3840, 2160, 60}};
  Check(
      DisplayModeManager::RecoverIfNeededForTesting(mode, false, true),
      "crash recovery must restore both mode originals from a pending handoff");
  Check(
      mode.mode_restore_attempts == 2 && mode.dwords[kModeChanged] == 0 && mode.dwords[kModeHandoffPending] == 0 &&
          mode.dwords[kHDRChanged] == 1,
      "mode handoff recovery must restore replacement then prior and preserve its sibling");

  FakeRecoveryBackend hdr;
  hdr.SeedBoth();
  hdr.dwords[kModeTakeoverEligible] = 1;
  hdr.dwords[kHDRTakeoverEligible] = 1;
  Check(
      DisplayModeManager::PrepareHDRRecovery(hdr, kReplacementHDRDevice, true),
      "HDR takeover preparation must reach its pre-apply handoff");
  Check(
      hdr.dwords[kHDRChanged] == 1 && hdr.dwords[kHDRHandoffPending] == 1 &&
          hdr.dwords[kHDRPreviousRecoverySlot] == 0 && hdr.dwords[kHDRRecoverySlot] == 1,
      "HDR pre-apply handoff must retain both slot identities under one marker");
  hdr.expected_hdr_restores = {{kReplacementHDRDevice, true}, {kHDRDevice, false}};
  Check(
      DisplayModeManager::RecoverIfNeededForTesting(hdr, true, false),
      "crash recovery must restore both HDR originals from a pending handoff");
  Check(
      hdr.hdr_restore_attempts == 2 && hdr.dwords[kHDRChanged] == 0 && hdr.dwords[kHDRHandoffPending] == 0 &&
          hdr.dwords[kModeChanged] == 1,
      "HDR handoff recovery must restore replacement then prior and preserve its sibling");
}

void TestHDRReconnectRecoversBeforeTakeover() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.dwords[kModeChanged] = 0;
  backend.device_present[kHDRDevice] = false;

  Check(!DisplayModeManager::RecoverIfNeeded(backend), "an absent HDR target must retain its recovery marker");
  Check(
      backend.dwords[kHDRChanged] == 1 && backend.dwords[kHDRTakeoverEligible] == 1 &&
          EventIndex(backend.events, L"restore:hdr") == backend.events.size(),
      "absent HDR recovery must become eligible without calling the restore API");

  backend.events.clear();
  backend.device_present[kHDRDevice] = true;
  Check(
      DisplayModeManager::RecoverIfNeeded(backend),
      "reconnecting HDR before a conflicting request must recover the old target");
  Check(
      EventIndex(backend.events, L"restore:hdr") < backend.events.size() && !backend.RecordExists(),
      "successful reconnect recovery must win and remove its disposition");
}

void TestEligibleSameOriginalReuseResetsDisposition() {
  FakeRecoveryBackend mode;
  mode.SeedBoth();
  mode.dwords[kModeTakeoverEligible] = 1;
  mode.dwords[kHDRTakeoverEligible] = 1;

  Check(ApplyModeAfterPreparing(mode), "an eligible mode marker must remain reusable by the same original");
  Check(
      mode.dwords[kModeTakeoverEligible] == 0 && mode.dwords[kHDRTakeoverEligible] == 1,
      "same-original mode reuse must revoke only mode takeover");
  mode.events.clear();
  Check(
      !ApplyModeAfterPreparing(mode, kReplacementModeDevice, 2560, 1440, 120) && mode.events.empty(),
      "a mismatched mode request must not steal a marker after same-original reuse");

  FakeRecoveryBackend hdr;
  hdr.SeedBoth();
  hdr.dwords[kModeTakeoverEligible] = 1;
  hdr.dwords[kHDRTakeoverEligible] = 1;

  Check(ApplyHDRAfterPreparing(hdr), "an eligible HDR marker must remain reusable by the same original");
  Check(
      hdr.dwords[kHDRTakeoverEligible] == 0 && hdr.dwords[kModeTakeoverEligible] == 1,
      "same-original HDR reuse must revoke only HDR takeover");
  hdr.events.clear();
  Check(
      !ApplyHDRAfterPreparing(hdr, kReplacementHDRDevice, true) && hdr.events.empty(),
      "a mismatched HDR request must not steal a marker after same-original reuse");
}

void TestRepeatedModeTakeoverStagesOnlyTheInactiveSlot() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.dwords[kModeTakeoverEligible] = 1;
  backend.dwords[kHDRTakeoverEligible] = 1;
  Check(
      ApplyModeAfterPreparing(backend, kReplacementModeDevice, 2560, 1440, 120),
      "the first mode takeover must commit the alternate slot");

  backend.events.clear();
  backend.device_present[kReplacementModeDevice] = false;
  Check(
      !DisplayModeManager::RecoverIfNeededForTesting(backend, false, true),
      "a later failed recovery must make the alternate mode original eligible");
  Check(
      backend.dwords[kModeRecoverySlot] == 1 && backend.dwords[kModeTakeoverEligible] == 1,
      "the active alternate slot must remain selected after recovery failure");

  backend.events.clear();
  backend.device_present[kReplacementModeDevice] = true;
  backend.rejected_dword_write_event = L"write:OriginalRefreshRate=75";
  Check(
      !ApplyModeAfterPreparing(backend, kModeDevice, 1920, 1080, 75),
      "a repeated takeover must fail when staging into the primary slot fails");
  Check(
      backend.dwords[kModeChanged] == 1 && backend.dwords[kModeRecoverySlot] == 1 &&
          backend.dwords[kOriginalWidthAlternate] == 2560 && backend.dwords[kOriginalHeightAlternate] == 1440 &&
          backend.dwords[kOriginalRefreshRateAlternate] == 120 &&
          backend.strings[kModeDeviceNameAlternate] == kReplacementModeDevice &&
          EventIndex(backend.events, L"os:mode") == backend.events.size(),
      "failed repeated staging must not overwrite or deselect the active alternate original");

  FakeRecoveryBackend relaunched;
  relaunched.dwords = backend.dwords;
  relaunched.strings = backend.strings;
  relaunched.expected_mode_device = kReplacementModeDevice;
  relaunched.expected_mode_width = 2560;
  relaunched.expected_mode_height = 1440;
  relaunched.expected_mode_refresh_rate = 120;
  Check(
      DisplayModeManager::RecoverIfNeededForTesting(relaunched, false, true),
      "relaunch must still recover the alternate original after repeated takeover staging fails");
}

void TestLiveMarkersCannotBecomeEligibleOrBeTakenOver() {
  FakeRecoveryBackend mode;
  mode.SeedBoth();
  mode.dwords[kHDRChanged] = 0;
  Check(
      !DisplayModeManager::RecoverIfNeededForTesting(mode, true, false),
      "a live mode marker must be skipped by synchronous recovery");
  Check(
      mode.events.empty() && mode.dwords.find(kModeTakeoverEligible) == mode.dwords.end(),
      "skipping live mode recovery must not grant takeover");
  Check(
      !ApplyModeAfterPreparing(mode, kReplacementModeDevice, 2560, 1440, 120),
      "a mismatched request must not steal a live mode marker");

  FakeRecoveryBackend hdr;
  hdr.SeedBoth();
  hdr.dwords[kModeChanged] = 0;
  Check(
      !DisplayModeManager::RecoverIfNeededForTesting(hdr, false, true),
      "a live HDR marker must be skipped by synchronous recovery");
  Check(
      hdr.events.empty() && hdr.dwords.find(kHDRTakeoverEligible) == hdr.dwords.end(),
      "skipping live HDR recovery must not grant takeover");
  Check(
      !ApplyHDRAfterPreparing(hdr, kReplacementHDRDevice, true),
      "a mismatched request must not steal a live HDR marker");
}

void TestTakeoverPersistenceFailuresRemainConservative() {
  FakeRecoveryBackend failed_grant;
  failed_grant.SeedBoth();
  failed_grant.dwords[kHDRChanged] = 0;
  failed_grant.device_present[kModeDevice] = false;
  failed_grant.rejected_dword_write_event = L"write:ModeTakeoverEligible=1";
  Check(
      !DisplayModeManager::RecoverIfNeeded(failed_grant),
      "failure to persist mode takeover eligibility must leave recovery incomplete");
  Check(
      failed_grant.dwords[kModeChanged] == 1 &&
          failed_grant.dwords.find(kModeTakeoverEligible) == failed_grant.dwords.end(),
      "a failed eligibility write must leave the old marker authoritative");
  failed_grant.rejected_dword_write_event.clear();
  failed_grant.events.clear();
  Check(
      !ApplyModeAfterPreparing(failed_grant, kReplacementModeDevice, 2560, 1440, 120) && failed_grant.events.empty(),
      "an unpersisted failure must not admit takeover");

  FakeRecoveryBackend failed_reuse_reset;
  failed_reuse_reset.SeedBoth();
  failed_reuse_reset.dwords[kHDRTakeoverEligible] = 1;
  failed_reuse_reset.rejected_dword_write_event = L"write:HDRTakeoverEligible=0";
  Check(!ApplyHDRAfterPreparing(failed_reuse_reset), "same-original reuse must fail when takeover cannot be reset");
  Check(
      failed_reuse_reset.dwords[kHDRChanged] == 1 && failed_reuse_reset.dwords[kHDRTakeoverEligible] == 1 &&
          EventIndex(failed_reuse_reset.events, L"os:hdr") == failed_reuse_reset.events.size(),
      "failed HDR disposition reset must retain the marker and prevent mutation");

  FakeRecoveryBackend failed_mode_stage;
  failed_mode_stage.SeedBoth();
  failed_mode_stage.dwords[kModeTakeoverEligible] = 1;
  failed_mode_stage.dwords[kHDRTakeoverEligible] = 1;
  failed_mode_stage.rejected_dword_write_event = L"write:OriginalRefreshRateAlternate=120";
  Check(
      !ApplyModeAfterPreparing(failed_mode_stage, kReplacementModeDevice, 2560, 1440, 120),
      "mode takeover must fail if a staged replacement original cannot be persisted");
  Check(
      failed_mode_stage.dwords[kModeChanged] == 1 && failed_mode_stage.dwords[kModeTakeoverEligible] == 1 &&
          failed_mode_stage.dwords.find(kModeRecoverySlot) == failed_mode_stage.dwords.end() &&
          failed_mode_stage.dwords[kOriginalWidth] == 3840 && failed_mode_stage.dwords[kOriginalHeight] == 2160 &&
          failed_mode_stage.dwords[kOriginalRefreshRate] == 60 &&
          failed_mode_stage.strings[kModeDeviceName] == kModeDevice && failed_mode_stage.dwords[kHDRChanged] == 1 &&
          failed_mode_stage.dwords[kHDRTakeoverEligible] == 1 && failed_mode_stage.dwords[kOriginalHDR] == 0 &&
          failed_mode_stage.strings[kHDRDeviceName] == kHDRDevice &&
          EventIndex(failed_mode_stage.events, L"os:mode") == failed_mode_stage.events.size(),
      "failed mode staging must leave the old marker and originals authoritative");

  FakeRecoveryBackend failed_mode_commit;
  failed_mode_commit.SeedBoth();
  failed_mode_commit.dwords[kModeTakeoverEligible] = 1;
  failed_mode_commit.dwords[kHDRTakeoverEligible] = 1;
  failed_mode_commit.rejected_dword_write_event = L"write:ModeRecoverySlot=1";
  Check(
      !ApplyModeAfterPreparing(failed_mode_commit, kReplacementModeDevice, 2560, 1440, 120),
      "mode takeover must fail when its atomic authority switch cannot be persisted");
  Check(
      failed_mode_commit.dwords[kModeChanged] == 1 && failed_mode_commit.dwords[kModeTakeoverEligible] == 1 &&
          failed_mode_commit.dwords[kModeRecoverySlot] == 0 && failed_mode_commit.dwords[kModeHandoffPending] == 0 &&
          failed_mode_commit.dwords[kOriginalWidth] == 3840 && failed_mode_commit.dwords[kOriginalHeight] == 2160 &&
          failed_mode_commit.dwords[kOriginalRefreshRate] == 60 &&
          failed_mode_commit.strings[kModeDeviceName] == kModeDevice &&
          failed_mode_commit.dwords[kOriginalWidthAlternate] == 2560 &&
          failed_mode_commit.strings[kModeDeviceNameAlternate] == kReplacementModeDevice &&
          failed_mode_commit.dwords[kHDRChanged] == 1 && failed_mode_commit.dwords[kHDRTakeoverEligible] == 1 &&
          failed_mode_commit.dwords[kOriginalHDR] == 0 && failed_mode_commit.strings[kHDRDeviceName] == kHDRDevice &&
          EventIndex(failed_mode_commit.events, L"os:mode") == failed_mode_commit.events.size(),
      "failed mode commit must keep the primary recovery point authoritative despite complete staging");

  FakeRecoveryBackend mode_relaunch;
  mode_relaunch.dwords = failed_mode_commit.dwords;
  mode_relaunch.strings = failed_mode_commit.strings;
  Check(
      DisplayModeManager::RecoverIfNeededForTesting(mode_relaunch, false, true),
      "relaunch after a failed mode commit must recover the old primary original");
  Check(
      EventIndex(mode_relaunch.events, L"restore:mode") < mode_relaunch.events.size(),
      "failed mode authority switch must not redirect relaunch recovery to staging");

  FakeRecoveryBackend failed_hdr_stage;
  failed_hdr_stage.SeedBoth();
  failed_hdr_stage.dwords[kModeTakeoverEligible] = 1;
  failed_hdr_stage.dwords[kHDRTakeoverEligible] = 1;
  failed_hdr_stage.rejected_dword_write_event = L"write:OriginalHDREnabledAlternate=1";
  Check(
      !ApplyHDRAfterPreparing(failed_hdr_stage, kReplacementHDRDevice, true),
      "HDR takeover must fail if its staged replacement original cannot be persisted");
  Check(
      failed_hdr_stage.dwords[kHDRChanged] == 1 && failed_hdr_stage.dwords[kHDRTakeoverEligible] == 1 &&
          failed_hdr_stage.dwords.find(kHDRRecoverySlot) == failed_hdr_stage.dwords.end() &&
          failed_hdr_stage.dwords[kOriginalHDR] == 0 && failed_hdr_stage.strings[kHDRDeviceName] == kHDRDevice &&
          failed_hdr_stage.dwords[kModeChanged] == 1 && failed_hdr_stage.dwords[kModeTakeoverEligible] == 1 &&
          failed_hdr_stage.dwords[kOriginalWidth] == 3840 && failed_hdr_stage.dwords[kOriginalHeight] == 2160 &&
          failed_hdr_stage.dwords[kOriginalRefreshRate] == 60 &&
          failed_hdr_stage.strings[kModeDeviceName] == kModeDevice &&
          EventIndex(failed_hdr_stage.events, L"os:hdr") == failed_hdr_stage.events.size(),
      "failed HDR staging must leave the old marker and original authoritative");

  FakeRecoveryBackend failed_hdr_commit;
  failed_hdr_commit.SeedBoth();
  failed_hdr_commit.dwords[kModeTakeoverEligible] = 1;
  failed_hdr_commit.dwords[kHDRTakeoverEligible] = 1;
  failed_hdr_commit.rejected_dword_write_event = L"write:HDRRecoverySlot=1";
  Check(
      !ApplyHDRAfterPreparing(failed_hdr_commit, kReplacementHDRDevice, true),
      "HDR takeover must fail when its atomic authority switch cannot be persisted");
  Check(
      failed_hdr_commit.dwords[kHDRChanged] == 1 && failed_hdr_commit.dwords[kHDRTakeoverEligible] == 1 &&
          failed_hdr_commit.dwords[kHDRRecoverySlot] == 0 && failed_hdr_commit.dwords[kHDRHandoffPending] == 0 &&
          failed_hdr_commit.dwords[kOriginalHDR] == 0 && failed_hdr_commit.strings[kHDRDeviceName] == kHDRDevice &&
          failed_hdr_commit.dwords[kOriginalHDRAlternate] == 1 &&
          failed_hdr_commit.strings[kHDRDeviceNameAlternate] == kReplacementHDRDevice &&
          failed_hdr_commit.dwords[kModeChanged] == 1 && failed_hdr_commit.dwords[kModeTakeoverEligible] == 1 &&
          failed_hdr_commit.dwords[kOriginalWidth] == 3840 && failed_hdr_commit.dwords[kOriginalHeight] == 2160 &&
          failed_hdr_commit.dwords[kOriginalRefreshRate] == 60 &&
          failed_hdr_commit.strings[kModeDeviceName] == kModeDevice &&
          EventIndex(failed_hdr_commit.events, L"os:hdr") == failed_hdr_commit.events.size(),
      "failed HDR commit must keep the primary recovery point authoritative despite complete staging");

  FakeRecoveryBackend hdr_relaunch;
  hdr_relaunch.dwords = failed_hdr_commit.dwords;
  hdr_relaunch.strings = failed_hdr_commit.strings;
  Check(
      DisplayModeManager::RecoverIfNeededForTesting(hdr_relaunch, true, false),
      "relaunch after a failed HDR commit must recover the old primary original");
  Check(
      EventIndex(hdr_relaunch.events, L"restore:hdr") < hdr_relaunch.events.size(),
      "failed HDR authority switch must not redirect relaunch recovery to staging");
}

void TestVersionlessModeRecoveryAndCleanup() {
  FakeRecoveryBackend backend;
  backend.dwords[kModeChanged] = 1;
  backend.dwords[kHDRChanged] = 0;
  backend.dwords[kOriginalWidth] = 3840;
  backend.dwords[kOriginalHeight] = 2160;
  backend.dwords[kOriginalRefreshRate] = 60;
  backend.strings[kLegacyDeviceName] = kModeDevice;

  Check(DisplayModeManager::RecoverIfNeeded(backend), "the released versionless mode layout must be recovered");
  Check(
      EventIndex(backend.events, L"restore:mode") < backend.events.size(),
      "versionless mode recovery must use the backend restore");
  Check(
      backend.delete_attempts == 1 && !backend.RecordExists(),
      "completed versionless mode recovery must clean the legacy DeviceName and record");
}

void TestVersionlessHDRRecoveryAndCleanup() {
  FakeRecoveryBackend backend;
  backend.dwords[kModeChanged] = 0;
  backend.dwords[kHDRChanged] = 1;
  backend.dwords[kOriginalHDR] = 0;
  backend.strings[kLegacyDeviceName] = kHDRDevice;

  Check(DisplayModeManager::RecoverIfNeeded(backend), "the released versionless HDR layout must be recovered");
  Check(
      EventIndex(backend.events, L"restore:hdr") < backend.events.size(),
      "versionless HDR recovery must use the backend restore");
  Check(
      backend.delete_attempts == 1 && !backend.RecordExists(),
      "completed versionless HDR recovery must clean the legacy DeviceName and record");
}

void TestVersionlessModeAndHDRUseSharedDevice() {
  FakeRecoveryBackend backend;
  backend.dwords[kModeChanged] = 1;
  backend.dwords[kHDRChanged] = 1;
  backend.dwords[kOriginalWidth] = 3840;
  backend.dwords[kOriginalHeight] = 2160;
  backend.dwords[kOriginalRefreshRate] = 60;
  backend.dwords[kOriginalHDR] = 0;
  backend.strings[kLegacyDeviceName] = kModeDevice;
  backend.expected_hdr_device = kModeDevice;

  Check(
      DisplayModeManager::RecoverIfNeeded(backend),
      "both versionless operations must recover from their shared DeviceName");
  Check(
      EventIndex(backend.events, L"restore:mode") < backend.events.size() &&
          EventIndex(backend.events, L"restore:hdr") < backend.events.size(),
      "the released shared-device layout must restore mode and HDR independently");
  Check(
      backend.delete_attempts == 1 && !backend.RecordExists(),
      "shared versionless recovery must remove the legacy record after both markers clear");
}

void TestCleanupFailureDoesNotBlockNewOverride() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.dwords[kHDRChanged] = 0;
  backend.delete_succeeds = false;

  Check(
      DisplayModeManager::RecoverIfNeeded(backend),
      "successful restoration must complete even when stale-value deletion fails");
  Check(
      backend.dwords[kModeChanged] == 0 && backend.dwords[kModeTakeoverEligible] == 0,
      "the successful restore marker and matching disposition must be clear");
  Check(backend.delete_attempts == 1, "completed recovery must make one best-effort cleanup attempt");

  backend.events.clear();
  Check(ApplyModeAfterPreparing(backend), "failed cleanup must not block persistence or admission of a fresh override");
  Check(
      backend.dwords[kModeChanged] == 1 &&
          EventIndex(backend.events, L"write:ModeChanged=1") < EventIndex(backend.events, L"os:mode"),
      "the fresh override must replace stale values with a pre-mutation marker");
}

}  // namespace
}  // namespace mpv

int main() {
  mpv::TestMarkersArePersistedBeforeMutation();
  mpv::TestMalformedRecordIsIgnored();
  mpv::TestValidModeSurvivesMalformedHDR();
  mpv::TestValidHDRSurvivesMalformedMode();
  mpv::TestPreparationClearsMalformedSibling();
  mpv::TestModeAndHDRRestoreIndependently();
  mpv::TestFailedRestoreRemainsForTopologyRetry();
  mpv::TestMarkerClearFailureRemainsRetryable();
  mpv::TestLifecycleCleanupPreservesPersistedSibling();
  mpv::TestReleasedLiveOperationRecoversAfterReconnect();
  mpv::TestUnfailedMarkersRejectSameKindTakeover();
  mpv::TestAbsentModeTakeoverSurvivesRelaunchAndPreservesHDRSibling();
  mpv::TestBadModeHDRRestoreAllowsSameKindTakeover();
  mpv::TestFailedOSApplyRollsBackTakeover();
  mpv::TestCrashDuringTakeoverHandoffRecoversBothOriginals();
  mpv::TestHDRReconnectRecoversBeforeTakeover();
  mpv::TestEligibleSameOriginalReuseResetsDisposition();
  mpv::TestRepeatedModeTakeoverStagesOnlyTheInactiveSlot();
  mpv::TestLiveMarkersCannotBecomeEligibleOrBeTakenOver();
  mpv::TestTakeoverPersistenceFailuresRemainConservative();
  mpv::TestVersionlessModeRecoveryAndCleanup();
  mpv::TestVersionlessHDRRecoveryAndCleanup();
  mpv::TestVersionlessModeAndHDRUseSharedDevice();
  mpv::TestCleanupFailureDoesNotBlockNewOverride();
  std::cout << "display_mode_manager_test: PASS\n";
  return 0;
}
