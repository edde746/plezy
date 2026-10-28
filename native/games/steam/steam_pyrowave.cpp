// SPDX-License-Identifier: GPL-3.0-or-later
#include "steam_pyrowave.h"

#include <algorithm>
#include <limits>
#include <new>
#include <stdexcept>

#if PLEZY_STEAM_PYROWAVE
#include <vulkan/vulkan.h>
#include <pyrowave.h>
#endif

namespace plezy::steam {
namespace {
constexpr size_t kMaxFrameBytes = 2 * 1024 * 1024;
constexpr uint32_t kMaxWidth = 1920;
constexpr uint32_t kMaxHeight = 1080;

uint16_t read16(const uint8_t* p) { return uint16_t(p[0]) | (uint16_t(p[1]) << 8); }
uint32_t read32(const uint8_t* p) {
  return uint32_t(p[0]) | (uint32_t(p[1]) << 8) | (uint32_t(p[2]) << 16) | (uint32_t(p[3]) << 24);
}
uint8_t clamp8(int value) { return static_cast<uint8_t>(std::clamp(value, 0, 255)); }
}  // namespace

bool parsePyrowaveFrame(const uint8_t* bytes, size_t length, uint32_t width, uint32_t height,
                        PyrowaveFrameInfo& info, bool allow444) {
  if (!bytes || length < 8 || length > kMaxFrameBytes || width == 0 || height == 0 || width > kMaxWidth ||
      height > kMaxHeight || (width & 1) != 0 || (height & 1) != 0) {
    return false;
  }

  bool foundSequence = false;
  uint32_t sequenceHeader = 0, sequenceFlags = 0;
  size_t offset = 0;
  PyrowaveFrameInfo result{};
  while (offset < length) {
    if (length - offset < 8) return false;
    const uint8_t* packet = bytes + offset;
    const uint32_t first = read32(packet);
    if ((first & 0x80000000u) != 0) {
      const uint32_t second = read32(packet + 4);
      const uint32_t packetWidth = (first & 0x3fffu) + 1;
      const uint32_t packetHeight = ((first >> 14) & 0x3fffu) + 1;
      const uint32_t code = (second >> 24) & 0x3u;
      const uint32_t chroma = (second >> 26) & 0x1u;
      const uint32_t primaries = (second >> 27) & 0x1u;
      const uint32_t transfer = (second >> 28) & 0x1u;
      const uint32_t transform = (second >> 29) & 0x1u;
      const uint32_t range = (second >> 30) & 0x1u;
      if (foundSequence && (sequenceHeader != first || sequenceFlags != second)) return false;
      sequenceHeader = first; sequenceFlags = second;

      // Current surfaces are SDR BT.709. The legacy Android converter accepts
      // 4:2:0 only; the Metal path explicitly opts into full-resolution chroma.
      if (code != 0 || (chroma != 0 && !allow444) || primaries != 0 || transfer != 0 || transform != 0 ||
          packetWidth != width || packetHeight != height) {
        return false;
      }
      const bool left = (second >> 31) != 0;
      if (foundSequence && (result.fullRange != (range == 0) || result.chroma444 != (chroma != 0) || result.chromaLeft != left)) return false;
      result.width = packetWidth;
      result.height = packetHeight;
      result.fullRange = range == 0;
      result.chroma444 = chroma != 0;
      result.chromaLeft = left;
      foundSequence = true;
      offset += 8;
      continue;
    }

    const uint32_t words = read16(packet + 2) & 0x0fffu;
    const size_t packetBytes = size_t(words) * sizeof(uint32_t);
    if (words < 2 || packetBytes > length - offset) return false;
    offset += packetBytes;
  }
  if (!foundSequence) return false;
  info = result;
  return true;
}

void convertPyrowave420ToArgb(const uint8_t* y, size_t yStride, const uint8_t* cb, size_t cbStride,
                              const uint8_t* cr, size_t crStride, const PyrowaveFrameInfo& info,
                              std::vector<uint8_t>& argb) {
  if (!y || !cb || !cr || info.chroma444 || info.width == 0 || info.height == 0 || info.width > kMaxWidth ||
      info.height > kMaxHeight || yStride < info.width || cbStride < info.width / 2 ||
      crStride < info.width / 2) {
    throw std::invalid_argument("invalid Pyrowave output planes");
  }
  const size_t pixels = size_t(info.width) * info.height;
  if (pixels > std::numeric_limits<size_t>::max() / 4) throw std::length_error("Pyrowave frame too large");
  argb.resize(pixels * 4);
  for (uint32_t row = 0; row < info.height; ++row) {
    const uint8_t* yRow = y + size_t(row) * yStride;
    const uint8_t* cbRow = cb + size_t(row / 2) * cbStride;
    const uint8_t* crRow = cr + size_t(row / 2) * crStride;
    for (uint32_t column = 0; column < info.width; ++column) {
      const int yValue = yRow[column];
      const int cbValue = int(cbRow[column / 2]) - 128;
      const int crValue = int(crRow[column / 2]) - 128;
      int red, green, blue;
      if (info.fullRange) {
        red = yValue + ((403 * crValue + 128) >> 8);
        green = yValue - ((48 * cbValue + 120 * crValue + 128) >> 8);
        blue = yValue + ((475 * cbValue + 128) >> 8);
      } else {
        const int luma = std::max(0, yValue - 16);
        red = (298 * luma + 459 * crValue + 128) >> 8;
        green = (298 * luma - 55 * cbValue - 136 * crValue + 128) >> 8;
        blue = (298 * luma + 541 * cbValue + 128) >> 8;
      }
      const size_t out = (size_t(row) * info.width + column) * 4;
      // Android ARGB_8888 is native-endian BGRA bytes on supported Android ABIs.
      argb[out] = clamp8(blue);
      argb[out + 1] = clamp8(green);
      argb[out + 2] = clamp8(red);
      argb[out + 3] = 255;
    }
  }
}

#if PLEZY_STEAM_PYROWAVE
struct PyrowaveDecoder::Impl {
  pyrowave_device device = nullptr;
  pyrowave_decoder decoder = nullptr;
  int width = 0;
  int height = 0;

  ~Impl() { reset(); }

  void reset() {
    if (decoder) pyrowave_decoder_destroy(decoder);
    decoder = nullptr;
    if (device) pyrowave_device_destroy(device);
    device = nullptr;
    width = height = 0;
  }
};

PyrowaveDecoder::PyrowaveDecoder() : impl_(std::make_unique<Impl>()) {}
PyrowaveDecoder::~PyrowaveDecoder() = default;

bool PyrowaveDecoder::probe() {
  pyrowave_device device = nullptr;
  pyrowave_decoder decoder = nullptr;
  try {
    uint32_t major = 0, minor = 0, patch = 0;
    pyrowave_get_api_version(&major, &minor, &patch);
    if (major != PYROWAVE_API_VERSION_MAJOR) return false;
    if (pyrowave_create_default_device(&device) != PYROWAVE_SUCCESS || !device) {
      if (device) pyrowave_device_destroy(device);
      return false;
    }
    pyrowave_decoder_create_info info{};
    info.device = device;
    info.width = 32;
    info.height = 32;
    info.chroma = PYROWAVE_CHROMA_SUBSAMPLING_420;
    info.fragment_path = pyrowave_decoder_device_prefers_fragment_path(device);
    const bool supported = pyrowave_decoder_create(&info, &decoder) == PYROWAVE_SUCCESS && decoder;
    if (decoder) pyrowave_decoder_destroy(decoder);
    decoder = nullptr;
    pyrowave_device_destroy(device);
    device = nullptr;
    return supported;
  } catch (...) {
    if (decoder) pyrowave_decoder_destroy(decoder);
    if (device) pyrowave_device_destroy(device);
    return false;
  }
}

bool PyrowaveDecoder::start(int width, int height, const uint8_t* initial, size_t initialLength) {
  reset();
  if (width < 2 || height < 2 || width > static_cast<int>(kMaxWidth) || height > static_cast<int>(kMaxHeight) ||
      (width & 1) != 0 || (height & 1) != 0) {
    return false;
  }
  if (pyrowave_create_default_device(&impl_->device) != PYROWAVE_SUCCESS || !impl_->device) {
    reset();
    return false;
  }
  pyrowave_decoder_create_info info{};
  info.device = impl_->device;
  info.width = width;
  info.height = height;
  info.chroma = PYROWAVE_CHROMA_SUBSAMPLING_420;
  info.fragment_path = pyrowave_decoder_device_prefers_fragment_path(impl_->device);
  if (pyrowave_decoder_create(&info, &impl_->decoder) != PYROWAVE_SUCCESS || !impl_->decoder) {
    reset();
    return false;
  }
  impl_->width = width;
  impl_->height = height;
  if (initialLength != 0) {
    PyrowaveFrameInfo info;
    if (!parsePyrowaveFrame(initial, initialLength, static_cast<uint32_t>(width), static_cast<uint32_t>(height), info) ||
        pyrowave_decoder_push_packet(impl_->decoder, initial, initialLength) != PYROWAVE_SUCCESS) {
      reset();
      return false;
    }
  }
  return true;
}

PyrowaveDecodeStatus PyrowaveDecoder::decode(const uint8_t* bytes, size_t length, std::vector<uint8_t>& argb) {
  if (!impl_->decoder || !bytes || length == 0 || length > kMaxFrameBytes) return PyrowaveDecodeStatus::invalid;
  PyrowaveFrameInfo frameInfo;
  if (!parsePyrowaveFrame(bytes, length, impl_->width, impl_->height, frameInfo)) return PyrowaveDecodeStatus::invalid;
  if (pyrowave_decoder_push_packet(impl_->decoder, bytes, length) != PYROWAVE_SUCCESS)
    return PyrowaveDecodeStatus::invalid;
  if (!pyrowave_decoder_decode_is_ready(impl_->decoder, false)) return PyrowaveDecodeStatus::pending;

  const size_t ySize = size_t(impl_->width) * impl_->height;
  const size_t chromaStride = size_t(impl_->width) / 2;
  const size_t chromaSize = chromaStride * (size_t(impl_->height) / 2);
  std::vector<uint8_t> y(ySize), cb(chromaSize), cr(chromaSize);
  pyrowave_cpu_buffer output{};
  output.data[0] = y.data();
  output.data[1] = cb.data();
  output.data[2] = cr.data();
  output.row_stride_in_bytes[0] = impl_->width;
  output.row_stride_in_bytes[1] = chromaStride;
  output.row_stride_in_bytes[2] = chromaStride;
  output.plane_size_in_bytes[0] = ySize;
  output.plane_size_in_bytes[1] = chromaSize;
  output.plane_size_in_bytes[2] = chromaSize;
  output.width = impl_->width;
  output.height = impl_->height;
  output.format = PYROWAVE_CPU_BUFFER_FORMAT_YUV420P;
  if (pyrowave_decoder_decode_cpu_buffer_synchronous(impl_->decoder, &output) != PYROWAVE_SUCCESS)
    return PyrowaveDecodeStatus::invalid;
  convertPyrowave420ToArgb(y.data(), impl_->width, cb.data(), chromaStride, cr.data(), chromaStride, frameInfo,
                           argb);
  return PyrowaveDecodeStatus::frame;
}

void PyrowaveDecoder::reset() { impl_->reset(); }
#else
// Builds without a Vulkan backend never advertise or accept Pyrowave.
struct PyrowaveDecoder::Impl {};
PyrowaveDecoder::PyrowaveDecoder() : impl_(std::make_unique<Impl>()) {}
PyrowaveDecoder::~PyrowaveDecoder() = default;
bool PyrowaveDecoder::probe() { return false; }
bool PyrowaveDecoder::start(int, int, const uint8_t*, size_t) { return false; }
PyrowaveDecodeStatus PyrowaveDecoder::decode(const uint8_t*, size_t, std::vector<uint8_t>&) {
  return PyrowaveDecodeStatus::invalid;
}
void PyrowaveDecoder::reset() {}
#endif
}  // namespace plezy::steam
