#ifndef MPV_CONTAINER_H_
#define MPV_CONTAINER_H_

#include <ShObjIdl.h>
#include <Windows.h>

#include <memory>

namespace mpv {

// Forward declaration
class MpvCore;

// Container window that holds the mpv video window behind Flutter.
// This is a singleton that creates a hidden window with no taskbar entry.
class MpvContainer {
 public:
  static MpvContainer* GetInstance();

  MpvContainer() = default;
  ~MpvContainer();

  // Creates the container window.
  HWND Create();

  // Gets the container window handle, positioning it relative to the Flutter window.
  HWND Get(HWND flutter_window);

  // Returns the raw handle.
  HWND handle() const { return handle_; }

 private:
  static LRESULT CALLBACK WindowProc(HWND window, UINT message, WPARAM wparam,
                                     LPARAM lparam) noexcept;

  HWND handle_ = nullptr;
  ITaskbarList3* taskbar_ = nullptr;

  static constexpr wchar_t kClassName[] = L"MPV_CONTAINER";
  static constexpr wchar_t kWindowName[] = L"";

  static std::unique_ptr<MpvContainer> instance_;
};

}  // namespace mpv

#endif  // MPV_CONTAINER_H_
