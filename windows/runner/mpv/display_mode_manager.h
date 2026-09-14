#ifndef DISPLAY_MODE_MANAGER_H_
#define DISPLAY_MODE_MANAGER_H_

#include <Windows.h>

#include <optional>
#include <string>
#include <vector>

namespace mpv {

struct DisplayMode {
  DWORD width;
  DWORD height;
  DWORD refresh_rate;
};

// Identifiers for a display target in the DisplayConfig API.
struct DisplayConfigId {
  LUID adapter_id;
  UINT32 id;
};

// Complete active display topology captured with QueryDisplayConfig before a
// display mutation. Restoring it through SetDisplayConfig preserves CCD-level
// path state -- notably the Dynamic Refresh Rate boost flag
// (DISPLAYCONFIG_PATH_BOOST_REFRESH_RATE) -- that a DEVMODEW restore cannot
// express.
struct DisplayConfigSnapshot {
  std::vector<DISPLAYCONFIG_PATH_INFO> paths;
  std::vector<DISPLAYCONFIG_MODE_INFO> modes;
  // Whether the snapshot was captured virtual-refresh-rate-aware; the apply
  // flags must match the query flags.
  bool vrr_aware = false;

  bool valid() const { return !paths.empty(); }
};

// Windows-runner-internal boundary for deterministic crash-recovery tests.
// Production uses the Win32/registry implementation in display_mode_manager.cpp.
class DisplayRecoveryBackend {
 public:
  virtual ~DisplayRecoveryBackend() = default;

  virtual bool RecordExists() const = 0;
  virtual bool ReadDWORD(const wchar_t* value_name, DWORD& value) = 0;
  virtual bool ReadString(const wchar_t* value_name, std::wstring& value) = 0;
  virtual bool WriteDWORD(const wchar_t* value_name, DWORD value) = 0;
  virtual bool WriteString(const wchar_t* value_name, const std::wstring& value) = 0;
  virtual bool IsDevicePresent(const std::wstring& device_name) const = 0;
  virtual bool RestoreMode(const std::wstring& device_name, DWORD width, DWORD height, DWORD refresh_rate) = 0;
  virtual bool RestoreHDR(const std::wstring& device_name, bool enabled) = 0;
  virtual bool ClearMarker(const wchar_t* value_name) = 0;
  virtual bool DeleteRecord() = 0;
};

// Manages Windows display mode switching (refresh rate, HDR) for video playback.
// Pure Win32 utility — no mpv or Flutter dependency.
//
// References:
//   ChangeDisplaySettingsExW:
//   https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-changedisplaysettingsexw
//   EnumDisplaySettingsW:
//   https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumdisplaysettingsw
//   DisplayConfigGetDeviceInfo:
//   https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-displayconfiggetdeviceinfo
//   DisplayConfigSetDeviceInfo:
//   https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-displayconfigsetdeviceinfo
//   Kodi impl: xbmc/platform/win32/DisplayUtilsWin32.cpp, xbmc/platform/win32/WIN32Util.cpp
class DisplayModeManager {
 public:
  DisplayModeManager();
  ~DisplayModeManager();

  // --- Refresh rate / resolution ---

  // Enumerate available display modes for the monitor containing the window.
  std::vector<DisplayMode> EnumerateDisplayModes(HWND window);

  // Get the current display mode.
  DisplayMode GetCurrentMode(HWND window);

  // Save the current mode (legacy DEVMODE plus a CCD topology snapshot) for
  // later restoration.
  void SaveOriginalMode(HWND window);

  // Change the display mode (refresh rate and/or resolution).
  // Uses CDS_FULLSCREEN flag. Implements Kodi's Win8+ workaround for 24/48/60Hz.
  // Returns true on success.
  bool SetDisplayMode(HWND window, DWORD width, DWORD height, DWORD refresh_rate);

  // Restore the previously saved display mode. Prefers re-applying the saved
  // CCD snapshot (which keeps a Dynamic Refresh Rate selection intact); falls
  // back to the legacy DEVMODE restore.
  bool RestoreOriginalMode(HWND window);

  // Returns true if a mode change has been applied (and not yet restored).
  bool IsModeChanged() const { return mode_changed_; }

  // --- HDR ---

  // Check if the display supports HDR (not just ACM/WCG).
  // Uses advancedColorSupported && !wideColorEnforced (pre-24H2)
  // or highDynamicRangeSupported (Win11 24H2+).
  bool IsHDRSupported(HWND window);

  // Check if HDR is currently enabled.
  bool IsHDREnabled(HWND window);

  // Save the current HDR state for later restoration.
  void SaveOriginalHDRState(HWND window);

  // Enable or disable system HDR.
  // Saves/restores DEVMODEW around the toggle (Windows changes display mode on HDR state change).
  // Uses SET_HDR_STATE (type 16) on Win11 24H2+, SET_ADVANCED_COLOR_STATE (type 10) on older.
  // A live change repeated from a different monitor hands off: the recorded
  // display is restored first, then the current monitor becomes the recorded
  // display. If that restore fails, the request is refused.
  bool SetHDREnabled(HWND window, bool enabled);

  // Restore the previously saved HDR state. Gated on and applied to the
  // recorded original display, not the window's current monitor.
  bool RestoreOriginalHDRState(HWND window);

  // Returns true if an HDR state change has been applied (and not yet restored).
  bool IsHDRChanged() const { return hdr_changed_; }

  // --- Crash recovery ---

  // Persist a complete original followed by its operation marker. A failed
  // non-live recovery remains retryable, but durably permits a later
  // conflicting request of the same kind to replace it. Conflicting originals
  // are staged in an inactive slot. A persisted handoff keeps both originals
  // recoverable across the selector switch and OS call; success confirms the
  // new slot, while OS failure rolls back the prior selector and eligibility.
  // Reusing the same original revokes permission before it becomes live.
  // These runner-internal seams make the crash ordering deterministic in tests.
  static bool PrepareModeRecovery(
      DisplayRecoveryBackend& backend, const std::wstring& device_name, DWORD width, DWORD height, DWORD refresh_rate);
  static bool PrepareHDRRecovery(DisplayRecoveryBackend& backend, const std::wstring& device_name, bool enabled);

  // Check for and recover from a prior crash that left display settings
  // changed. Successful operation markers and their takeover dispositions are
  // cleared independently. Failed operations remain recovery-first until a
  // conflicting same-kind preparation consumes their persisted disposition.
  static bool RecoverIfNeeded();
  static bool RecoverIfNeeded(DisplayRecoveryBackend& backend);
#if defined(PLEZY_DISPLAY_MODE_MANAGER_TESTING)
  // Exercise persisted lifecycle exits and per-operation live ownership without
  // touching a real display or registry.
  static bool CompleteRecoveryOperationForTesting(DisplayRecoveryBackend& backend, bool mode);
  static bool FinalizePreparedRecoveryForTesting(DisplayRecoveryBackend& backend, bool mode, bool os_apply_succeeded);
  static bool RecoverIfNeededForTesting(DisplayRecoveryBackend& backend, bool mode_is_live, bool hdr_is_live);
#endif

 private:
  friend class Win32DisplayRecoveryBackend;

  // Get the GDI device name for the monitor containing the window.
  static std::wstring GetMonitorDeviceName(HWND window);

  // Get the DisplayConfig target ID for a given GDI device name.
  // Follows Kodi's GetDisplayTargetId pattern.
  static std::optional<DisplayConfigId> GetDisplayTargetId(const std::wstring& gdi_device_name);

  // Get all active display config paths (with retry for ERROR_INSUFFICIENT_BUFFER).
  static std::vector<DISPLAYCONFIG_PATH_INFO> GetDisplayConfigPaths();

  // Check if running on Win11 24H2 or newer.
  static bool IsWin11_24H2OrNewer();

  // Toggle HDR via DisplayConfig (version-dispatched).
  static LONG SetHDRStateForTarget(const DisplayConfigId& target, bool enabled);

  // Query current HDR enablement for a resolved DisplayConfig target
  // (version-dispatched). Keyed by target so save/restore paths can ask about
  // the recorded display rather than the window's current monitor.
  static bool IsHDREnabledForTarget(const DisplayConfigId& target);

  // Stored original mode for restoration. The snapshot is the preferred
  // restore source; the DEVMODE is the fallback.
  std::wstring original_device_name_;
  DEVMODEW original_devmode_ = {};
  DisplayConfigSnapshot original_config_;
  bool mode_changed_ = false;

  // Stored original HDR state for restoration.
  std::wstring original_hdr_device_name_;
  bool original_hdr_enabled_ = false;
  bool hdr_changed_ = false;
};

}  // namespace mpv

#endif  // DISPLAY_MODE_MANAGER_H_
