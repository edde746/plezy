// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "steam_runtime.h"
#include <algorithm>
#include <cmath>
#include <map>
#include <set>

namespace plezy::steam {
// Platform adapters serialize calls to this state on their UI thread.
class InputState {
 public:
  explicit InputState(unsigned count) : count_(std::clamp(count, 1u, 4u)) {}
  void enabled(Runtime& runtime, bool value) { if (!value) reset(runtime); enabled_ = value; }
  void button(Runtime& runtime, int64_t device, const std::string& name, bool down, bool assistance = false) {
    if (!enabled_) return;
    const auto key = normalize(name);
    static const std::map<std::string, unsigned> bits = {
      {"a",0},{"b",1},{"x",2},{"y",3},{"select",4},{"back",4},{"view",4},
      {"mode",5},{"guide",5},{"home",5},{"start",6},{"leftstick",7},{"rightstick",8},
      {"leftbumper",9},{"leftshoulder",9},{"rightbumper",10},{"rightshoulder",10},
      {"dpadup",11},{"dpaddown",12},{"dpadleft",13},{"dpadright",14}};
    if (key == "lefttrigger" || key == "righttrigger") { axis(runtime, device, key, down ? 1 : 0, assistance); return; }
    auto found = bits.find(key);
    if (found == bits.end()) return;
    int slot = assistance ? 0 : seat(device);
    if (slot < 0) return;
    auto& state = assistance ? assistance_ : pads_[slot];
    if (down) state.buttons |= 1u << found->second; else state.buttons &= ~(1u << found->second);
    emit(runtime, slot);
  }
  void axis(Runtime& runtime, int64_t device, const std::string& name, double value, bool assistance = false) {
    if (!enabled_ || !std::isfinite(value)) return;
    static const std::array<std::string, 6> names = {
        "leftstickx","leftsticky","rightstickx","rightsticky","lefttrigger","righttrigger"};
    auto it = std::find(names.begin(), names.end(), normalize(name));
    if (it == names.end()) return;
    int slot = assistance ? 0 : seat(device);
    if (slot < 0) return;
    const size_t index = it - names.begin();
    (assistance ? assistance_ : pads_[slot]).axes[index] = int16_t(std::clamp(value, index < 4 ? -1.0 : 0.0, 1.0) * 32767);
    emit(runtime, slot);
  }
  void disconnect(Runtime& runtime, int64_t device) {
    auto it = seats_.find(device);
    if (it == seats_.end()) return;
    pads_[it->second] = {};
    emit(runtime, it->second);
    seats_.erase(it);
  }
  void key(Runtime& runtime, const std::string& name, bool down) {
    if (!enabled_) return;
    auto n = normalize(name);
    uint32_t usage = 0;
    if (n.size() == 1 && n[0] >= 'a' && n[0] <= 'z') usage = 4 + n[0] - 'a';
    else if (n.size() == 1 && n[0] >= '1' && n[0] <= '9') usage = 30 + n[0] - '1';
    else {
      static const std::map<std::string,uint32_t> keys = {{"0",39},{"enter",40},{"escape",41},
        {"backspace",42},{"tab",43},{"space",44},{"minus",45},{"equal",46},
        {"bracketleft",47},{"bracketright",48},{"backslash",49},{"semicolon",51},
        {"quote",52},{"backquote",53},{"comma",54},{"period",55},{"slash",56},
        {"f1",58},{"f2",59},{"f3",60},{"f4",61},{"f5",62},{"f6",63},
        {"f7",64},{"f8",65},{"f9",66},{"f10",67},{"f11",68},{"f12",69},
        {"insert",73},{"home",74},{"pageup",75},{"delete",76},{"end",77},{"pagedown",78},
        {"arrowright",79},{"arrowleft",80},
        {"arrowdown",81},{"arrowup",82},{"controlleft",224},{"shiftleft",225},{"altleft",226},
        {"metaleft",227},{"controlright",228},{"shiftright",229},{"altright",230},{"metaright",231}};
      auto it = keys.find(n);
      if (it != keys.end()) usage = it->second;
    }
    hidKey(runtime, usage, down);
  }
  void hidKey(Runtime& runtime, uint32_t usage, bool down) {
    if (!enabled_ || usage < 4 || usage > 231) return;
    if (down) keys_.insert(usage); else keys_.erase(usage);
    runtime.key(usage, down);
  }
  void mouse(Runtime& runtime, double x, double y, int button, bool down) {
    if (!enabled_ || !std::isfinite(x) || !std::isfinite(y) ||
        (button != 0 && button != 1 && button != 2 && button != 16)) return;
    mouseX_ = float(std::clamp(x, 0.0, 1.0)); mouseY_ = float(std::clamp(y, 0.0, 1.0));
    if (button) { if (down) mouseButtons_.insert(button); else mouseButtons_.erase(button); }
    runtime.mouse(mouseX_, mouseY_, button, down);
  }
  void wheel(Runtime& runtime, int direction) { if (enabled_) runtime.mouseWheel(direction); }
  void releasePointer(Runtime& runtime) {
    for (int button : mouseButtons_) runtime.mouse(mouseX_, mouseY_, button, false);
    mouseButtons_.clear();
  }
  void releaseAssistance(Runtime& runtime) { assistance_ = {}; emit(runtime, 0); }
  void reset(Runtime& runtime) {
    assistance_ = {};
    for (unsigned seat = 0; seat < count_; ++seat) { pads_[seat] = {}; runtime.padSeat(seat, {}, 0); }
    for (auto key : keys_) runtime.key(key, false);
    keys_.clear();
    releasePointer(runtime);
  }
 private:
  void emit(Runtime& runtime, unsigned seat) {
    auto state = pads_[seat];
    if (seat == 0) {
      state.buttons |= assistance_.buttons;
      for (size_t i = 0; i < state.axes.size(); ++i)
        if (std::abs(int(assistance_.axes[i])) > std::abs(int(state.axes[i]))) state.axes[i] = assistance_.axes[i];
    }
    runtime.padSeat(seat,state.axes,state.buttons);
  }
  static std::string normalize(const std::string& s) {
    std::string out;
    for (unsigned char c : s) {
      if (c >= 'A' && c <= 'Z') c += 'a' - 'A';
      if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) out += char(c);
    }
    return out;
  }
  int seat(int64_t device) {
    auto it = seats_.find(device);
    if (it != seats_.end()) return it->second;
    for (unsigned s = 0; s < count_; ++s) {
      if (std::none_of(seats_.begin(), seats_.end(), [s](auto& entry) { return entry.second == s; })) {
        seats_[device] = s; return s;
      }
    }
    return -1;
  }
  struct Pad { std::array<int16_t,6> axes{}; uint32_t buttons = 0; };
  std::array<Pad,4> pads_{};
  Pad assistance_{}; // Touch/TV assistance shares player one without consuming a physical seat.
  std::map<int64_t,unsigned> seats_;
  std::set<uint32_t> keys_;
  std::set<int> mouseButtons_;
  float mouseX_ = 0.5f, mouseY_ = 0.5f;
  unsigned count_;
  bool enabled_ = false;
};
} // namespace plezy::steam
