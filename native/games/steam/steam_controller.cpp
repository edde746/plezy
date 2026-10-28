// SPDX-License-Identifier: GPL-3.0-or-later
// Steam's canonical SDL gamepad report, also used by Steam-Link-PS5's HID
// adapter (GPL-3.0-or-later). No platform SDL dependency is required.
#include <algorithm>
#include <cstring>

#include "steam_runtime.h"
extern "C" {
#include "hid/device.h"
#include "hid/provider.h"
}

namespace plezy::steam {
namespace {
struct Device {
  IHS_HIDDevice base{};
  std::shared_ptr<PadState> state;
  std::string serial;
  std::array<uint8_t, 128> report{}, previous{};
  size_t length = 48;
  bool started = false;
};
struct Provider {
  IHS_HIDProvider base{};
  std::shared_ptr<PadState> state;
  std::string path, serial;
  bool changed = true;
};
Device* device(IHS_HIDDevice* value) { return reinterpret_cast<Device*>(value); }
Provider* provider(IHS_HIDProvider* value) { return reinterpret_cast<Provider*>(value); }
void little(uint8_t* out, uint32_t value, size_t bytes) {
  for (size_t i = 0; i < bytes; ++i) out[i] = static_cast<uint8_t>(value >> (8 * i));
}
int full(IHS_HIDDevice* value) {
  auto* d = device(value);
  IHS_HIDDeviceReportAddFull(value, d->report.data(), d->length);
  d->previous = d->report;
  return 0;
}
int string(IHS_Buffer* out, const char* text) {
  IHS_BufferWriteMem(out, 0, reinterpret_cast<const uint8_t*>(text), std::strlen(text) + 1);
  return 0;
}
const IHS_HIDDeviceClass deviceClass = {
    [](const IHS_HIDDeviceClass* cls) {
      auto* d = new Device;
      d->base.cls = cls;
      return &d->base;
    },
    [](IHS_HIDDevice* d) { delete device(d); },
    nullptr,
    nullptr,
    [](IHS_HIDDevice* d, const uint8_t* data, size_t length) {
      if (length >= 2 && data[0] == 9) device(d)->report[27] = data[1];
      return 0;
    },
    [](IHS_HIDDevice*, IHS_Buffer* out, size_t length, uint32_t) {
      if (length > 128) return -1;
      auto* bytes = IHS_BufferPointerForAppend(out, length);
      if (!bytes) return -1;
      std::memset(bytes, 0, length);
      return static_cast<int>(length);
    },
    [](IHS_HIDDevice*, const uint8_t*, size_t) { return -1; },
    [](IHS_HIDDevice* d, const uint8_t* number, size_t count, IHS_Buffer* out, size_t length) {
      if (count < 1) return -1;
      uint8_t data[21]{};
      data[0] = number[0];
      size_t size = 0;
      switch (number[0]) {
        case 2:
          data[1] = 0xff;
          size = 2;
          break;
        case 4:
          data[1] = 1;  // valid; not raw HID/XInput
          little(data + 3, IHS_CONTROLLER_TYPE_XBOX_ONE, 4);
          little(data + 16, 0x001003ff, 4);  // basic buttons/sticks/triggers
          size = 21;
          break;
        case 7:
          std::memcpy(data + 1, device(d)->serial.c_str(), 13);
          size = 14;
          break;
        default:
          return -1;
      }
      if (length < size) return -1;
      IHS_BufferWriteMem(out, 0, data, size);
      return 0;
    },
    [](IHS_HIDDevice*, IHS_Buffer* out) { return string(out, "PlezyNG"); },
    [](IHS_HIDDevice*, IHS_Buffer* out) { return string(out, "PlezyNG Controller"); },
    [](IHS_HIDDevice* d, IHS_Buffer* out) { return string(out, device(d)->serial.c_str()); },
    [](IHS_HIDDevice* d, size_t length) {
      if (length > 128 || length < 48) return -1;
      device(d)->length = length;
      device(d)->started = true;
      return full(d);
    },
    full,
    [](IHS_HIDDevice*, int, const uint8_t*, size_t) { return 0; },
    [](IHS_HIDDevice* value) {
      auto* d = device(value);
      if (!d->started) return 0;
      {
        std::lock_guard<std::mutex> lock(d->state->mutex);
        for (size_t i = 0; i < 6; ++i) little(d->report.data() + i * 2, static_cast<uint16_t>(d->state->axes[i]), 2);
        little(d->report.data() + 16, d->state->buttons, 4);
      }
      if (d->report == d->previous) return 0;
      IHS_HIDDeviceReportAddDelta(value, d->previous.data(), d->report.data(), d->length);
      d->previous = d->report;
      return 1;
    }};
const IHS_HIDProviderClass providerClass = {
    [](const IHS_HIDProviderClass* cls) {
      auto* p = new Provider;
      p->base.cls = cls;
      return &p->base;
    },
    [](IHS_HIDProvider* p) { delete provider(p); },
    [](IHS_HIDProvider* p, const char* name) { return name && provider(p)->path == name; },
    [](IHS_HIDProvider* p, const char* name) -> IHS_HIDDevice* {
      if (!name || provider(p)->path != name) return nullptr;
      auto* d = device(IHS_HIDDeviceCreate(&deviceClass));
      d->state = provider(p)->state;
      d->serial = provider(p)->serial;
      return &d->base;
    },
    [](IHS_HIDProvider* p) {
      bool changed = provider(p)->changed;
      provider(p)->changed = false;
      return changed;
    },
    [](IHS_HIDProvider*) {
      static int slot = 0;
      return IHS_EnumerationArrayCreate(&slot, sizeof(slot), 1, nullptr);
    },
    [](IHS_HIDProvider* p, IHS_Enumeration*, IHS_HIDDeviceInfo* info) {
      info->path = provider(p)->path.c_str();
      info->product_string = "PlezyNG Controller";
      info->serial_number = provider(p)->serial.c_str();
      info->vendor_id = 0x045e;
      info->product_id = 0x02ea;
      info->product_version = 0x0100;
    }};
}  // namespace
IHS_HIDProvider* makeController(const std::shared_ptr<PadState>& state, unsigned seat) {
  if (!state || seat >= 4) return nullptr;
  auto* p = provider(IHS_SessionHIDProviderCreate(&providerClass));
  p->state = state;
  p->path = "plezy://controller/" + std::to_string(seat);
  // Keep the original identity for player one. Each other seat must have its
  // own serial or Steam may coalesce distinct physical controllers.
  p->serial = seat == 0 ? "02504C455A59" : "02504C455A5" + std::to_string(seat);
  return &p->base;
}
}  // namespace plezy::steam
