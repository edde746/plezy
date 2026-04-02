#ifndef DISPLAY_MODE_MANAGER_H_
#define DISPLAY_MODE_MANAGER_H_

#include <Windows.h>

#include <map>
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

// Manages Windows display mode switching (refresh rate, HDR) for video playback.
// Pure Win32 utility — no mpv or Flutter dependency.
//
// References:
//   ChangeDisplaySettingsExW: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-changedisplaysettingsexw
//   EnumDisplaySettingsW: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumdisplaysettingsw
//   DisplayConfigGetDeviceInfo: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-displayconfiggetdeviceinfo
//   DisplayConfigSetDeviceInfo: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-displayconfigsetdeviceinfo
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

  // Save the current mode for later restoration.
  void SaveOriginalMode(HWND window);

  // Change the display mode (refresh rate and/or resolution).
  // Uses CDS_FULLSCREEN flag. Implements Kodi's Win8+ workaround for 24/48/60Hz.
  // Returns true on success.
  bool SetDisplayMode(HWND window, DWORD width, DWORD height, DWORD refresh_rate);

  // Restore the previously saved display mode.
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
  bool SetHDREnabled(HWND window, bool enabled);

  // Restore the previously saved HDR state.
  bool RestoreOriginalHDRState(HWND window);

  // Returns true if an HDR state change has been applied (and not yet restored).
  bool IsHDRChanged() const { return hdr_changed_; }

  // --- Crash recovery ---

  // Write current override state to registry for crash recovery.
  void WriteRecoveryState();

  // Clear the recovery state from registry.
  void ClearRecoveryState();

  // Check for and recover from a prior crash that left display settings changed.
  // Should be called early in app startup. Returns true if recovery was performed.
  static bool RecoverIfNeeded(HWND window);

  // --- Refresh rate matching ---

  // Find the best matching refresh rate for a given video fps from available modes.
  // Returns 0 if no suitable match found.
  static DWORD FindBestRefreshRate(double video_fps,
                                   const std::vector<DisplayMode>& modes,
                                   DWORD current_width, DWORD current_height);

 private:
  // Get the GDI device name for the monitor containing the window.
  static std::wstring GetMonitorDeviceName(HWND window);

  // Get the DisplayConfig target ID for a given GDI device name.
  // Follows Kodi's GetDisplayTargetId pattern.
  static std::optional<DisplayConfigId> GetDisplayTargetId(const std::wstring& gdi_device_name);

  // Get all active display config paths (with retry for ERROR_INSUFFICIENT_BUFFER).
  static std::vector<DISPLAYCONFIG_PATH_INFO> GetDisplayConfigPaths();

  // Check if running on Win11 24H2 or newer.
  static bool IsWin11_24H2OrNewer();

  // Registry helpers for crash recovery.
  static bool WriteRegistryDWORD(const wchar_t* value_name, DWORD value);
  static bool WriteRegistryString(const wchar_t* value_name, const std::wstring& value);
  static bool ReadRegistryDWORD(const wchar_t* value_name, DWORD& value);
  static bool ReadRegistryString(const wchar_t* value_name, std::wstring& value);
  static bool DeleteRegistryValue(const wchar_t* value_name);

  // Stored original mode for restoration.
  std::wstring original_device_name_;
  DEVMODEW original_devmode_ = {};
  bool mode_changed_ = false;

  // Stored original HDR state for restoration.
  std::wstring original_hdr_device_name_;
  bool original_hdr_enabled_ = false;
  bool hdr_changed_ = false;
};

}  // namespace mpv

#endif  // DISPLAY_MODE_MANAGER_H_
