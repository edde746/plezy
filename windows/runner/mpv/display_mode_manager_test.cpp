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
constexpr wchar_t kModeDevice[] = L"\\\\.\\DISPLAY1";
constexpr wchar_t kHDRDevice[] = L"\\\\.\\DISPLAY2";

void Check(bool condition, const char* message) {
  if (!condition) {
    std::cerr << "display_mode_manager_test: " << message << '\n';
    std::exit(1);
  }
}

class FakeRecoveryBackend final : public DisplayRecoveryBackend {
 public:
  std::map<std::wstring, DWORD> dwords;
  std::map<std::wstring, std::wstring> strings;
  std::map<std::wstring, bool> device_present = {{kModeDevice, true}, {kHDRDevice, true}};
  std::vector<std::wstring> events;
  std::wstring expected_mode_device = kModeDevice;
  std::wstring expected_hdr_device = kHDRDevice;
  bool mode_restore_succeeds = true;
  bool hdr_restore_succeeds = true;
  bool mode_marker_clear_succeeds = true;
  bool hdr_marker_clear_succeeds = true;
  bool delete_succeeds = true;
  bool final_mode_marker_write_succeeds = true;
  bool final_hdr_marker_write_succeeds = true;
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
    events.push_back(L"write:" + name + L"=" + std::to_wstring(value));
    if ((name == kModeChanged && value == 1 && !final_mode_marker_write_succeeds) ||
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
    Check(device_name == expected_mode_device, "mode restore must use its persisted display");
    Check(width == 3840 && height == 2160 && refresh_rate == 60, "mode restore must use persisted originals");
    events.push_back(L"restore:mode");
    return mode_restore_succeeds;
  }

  bool RestoreHDR(const std::wstring& device_name, bool enabled) override {
    Check(device_name == expected_hdr_device, "HDR restore must use its independently persisted display");
    Check(!enabled, "HDR restore must use the persisted original state");
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

bool ApplyModeAfterPreparing(FakeRecoveryBackend& backend) {
  if (!DisplayModeManager::PrepareModeRecovery(backend, kModeDevice, 3840, 2160, 60)) {
    return false;
  }
  backend.events.push_back(L"os:mode");
  return true;
}

bool ApplyHDRAfterPreparing(FakeRecoveryBackend& backend) {
  if (!DisplayModeManager::PrepareHDRRecovery(backend, kHDRDevice, false)) return false;
  backend.events.push_back(L"os:hdr");
  return true;
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
          EventIndex(mode.events, L"write:OriginalRefreshRate=60") < mode_marker,
      "all mode originals must precede the operation marker");

  FakeRecoveryBackend hdr;
  Check(ApplyHDRAfterPreparing(hdr), "a complete HDR recovery record must admit the OS mutation");
  const size_t hdr_marker = EventIndex(hdr.events, L"write:HDRChanged=1");
  Check(
      EventIndex(hdr.events, L"write:HDRDeviceName") < hdr_marker &&
          EventIndex(hdr.events, L"write:OriginalHDREnabled=0") < hdr_marker &&
          hdr_marker < EventIndex(hdr.events, L"os:hdr"),
      "the HDR original and marker must be durable before the OS mutation");

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
  Check(backend.dwords[kModeChanged] == 1, "the failed mode marker must remain set");
  Check(backend.dwords[kHDRChanged] == 0, "the successful HDR marker must be cleared");

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
  Check(backend.dwords[kModeChanged] == 1, "an absent display must keep its operation marker");
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
}

void TestMarkerClearFailureRemainsRetryable() {
  FakeRecoveryBackend backend;
  backend.SeedBoth();
  backend.dwords[kHDRChanged] = 0;
  backend.mode_marker_clear_succeeds = false;

  Check(!DisplayModeManager::RecoverIfNeeded(backend), "marker persistence is part of recovery completion");
  Check(backend.dwords[kModeChanged] == 1, "a failed marker clear must retain idempotent recovery evidence");

  backend.events.clear();
  backend.mode_marker_clear_succeeds = true;
  Check(DisplayModeManager::RecoverIfNeeded(backend), "a later pass must retry after marker persistence failure");
  Check(
      EventIndex(backend.events, L"restore:mode") < backend.events.size(),
      "the retained marker must cause the restore to be retried");
}

void TestLifecycleCleanupPreservesPersistedSibling() {
  FakeRecoveryBackend mode_completed;
  mode_completed.SeedBoth();
  Check(
      DisplayModeManager::CompleteRecoveryOperationForTesting(mode_completed, true),
      "successful mode cleanup must durably clear its own marker");
  Check(
      mode_completed.dwords[kModeChanged] == 0 && mode_completed.dwords[kHDRChanged] == 1,
      "mode cleanup must preserve a persisted HDR sibling even without local HDR ownership");
  Check(
      mode_completed.dwords[kOriginalHDR] == 0 && mode_completed.strings[kHDRDeviceName] == kHDRDevice &&
          mode_completed.delete_attempts == 0,
      "mode cleanup must retain the HDR original and avoid deleting its record");

  FakeRecoveryBackend hdr_failed_apply;
  hdr_failed_apply.SeedBoth();
  Check(
      DisplayModeManager::CompleteRecoveryOperationForTesting(hdr_failed_apply, false),
      "failed HDR apply cleanup must durably clear its own marker");
  Check(
      hdr_failed_apply.dwords[kHDRChanged] == 0 && hdr_failed_apply.dwords[kModeChanged] == 1,
      "HDR cleanup must preserve a persisted mode sibling even without local mode ownership");
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
      !DisplayModeManager::RecoverIfNeededForTesting(backend, false, true),
      "a released operation must remain marked while its target is absent");
  Check(
      backend.dwords[kModeChanged] == 1 && backend.dwords[kHDRChanged] == 1,
      "an absent released mode and its live HDR sibling must both retain their markers");

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
      backend.dwords[kModeChanged] == 0 && backend.dwords[kHDRChanged] == 1 && backend.delete_attempts == 0,
      "reconnect recovery must preserve the genuinely live sibling record");
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
  Check(backend.dwords[kModeChanged] == 0, "the successful restore marker must be clear");
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
  mpv::TestVersionlessModeRecoveryAndCleanup();
  mpv::TestVersionlessHDRRecoveryAndCleanup();
  mpv::TestVersionlessModeAndHDRUseSharedDevice();
  mpv::TestCleanupFailureDoesNotBlockNewOverride();
  std::cout << "display_mode_manager_test: PASS\n";
  return 0;
}
