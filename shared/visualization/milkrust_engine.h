// SPDX-License-Identifier: AGPL-3.0-only
#pragma once
#include "milkrust.h"
#include <algorithm>
#include <filesystem>
#include <fstream>
#include <functional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>
#if defined(_WIN32)
#include <windows.h>
#else
#include <dlfcn.h>
#endif

namespace plezy::visualization {
struct MilkRustApi {
  void* library = nullptr;
  std::string error;
#define DECLARE(name) decltype(&milkrust_##name) name = nullptr;
  DECLARE(abi_version) DECLARE(create) DECLARE(load) DECLARE(texture_names)
  DECLARE(texture) DECLARE(pcm) DECLARE(render) DECLARE(render_rgba) DECLARE(destroy) DECLARE(last_error)
#undef DECLARE
  MilkRustApi() {
#if defined(_WIN32)
    library = reinterpret_cast<void*>(LoadLibraryExW(L"milkrust_native.dll", nullptr,
        LOAD_LIBRARY_SEARCH_APPLICATION_DIR | LOAD_LIBRARY_SEARCH_SYSTEM32));
#elif defined(__APPLE__)
    // Mobile builds link a static library and export its public symbols. Desktop
    // bundles may ship the equivalent dylib in their signed Frameworks folder.
    library = dlopen(nullptr, RTLD_NOW | RTLD_LOCAL);
#else
    library = dlopen("libmilkrust_native.so", RTLD_NOW | RTLD_LOCAL);
#endif
    if (!library) { error = "Native MilkRust is not installed in this build."; return; }
#define LOAD(name) name = reinterpret_cast<decltype(name)>(Symbol("milkrust_" #name)); \
    if (!name) { error = "Native MilkRust lacks the required ABI v1 symbols."; return; }
    LOAD(abi_version) LOAD(create) LOAD(load) LOAD(texture_names) LOAD(texture)
    LOAD(pcm) LOAD(render) LOAD(render_rgba) LOAD(destroy) LOAD(last_error)
#undef LOAD
    if (abi_version() != MILKRUST_ABI_VERSION) error = "Native MilkRust ABI version does not match the app.";
  }
  void* Symbol(const char* name) const {
#if defined(_WIN32)
    return reinterpret_cast<void*>(GetProcAddress(static_cast<HMODULE>(library), name));
#else
    return dlsym(library, name);
#endif
  }
  ~MilkRustApi() {
    if (!library) return;
#if defined(_WIN32)
    FreeLibrary(static_cast<HMODULE>(library));
#else
    dlclose(library);
#endif
  }
  std::string Error() const {
    if (!error.empty()) return error;
    const auto size = last_error(nullptr, 0);
    if (size == 0 || size > 8193) return "Invalid native MilkRust error response.";
    std::vector<uint8_t> bytes(size);
    last_error(bytes.data(), bytes.size());
    return std::string(reinterpret_cast<const char*>(bytes.data()));
  }
  static MilkRustApi& Shared() { static MilkRustApi api; return api; }
};

struct MilkRustImage { uint32_t width = 0, height = 0; std::vector<uint8_t> rgba; };
using MilkRustImageDecoder = std::function<MilkRustImage(const std::filesystem::path&)>;

// A render-thread object. Context and decoder ownership stay with the host.
class MilkRustEngine {
 public:
  explicit MilkRustEngine(milkrust_gl_loader loader, bool gles) : api_(MilkRustApi::Shared()) {
    if (!api_.error.empty()) throw std::runtime_error(api_.error);
    handle_ = api_.create(loader, gles ? 1 : 0);
    if (!handle_) throw std::runtime_error(api_.Error());
  }
  ~MilkRustEngine() { if (handle_) api_.destroy(handle_); }
  MilkRustEngine(const MilkRustEngine&) = delete;
  MilkRustEngine& operator=(const MilkRustEngine&) = delete;

  void Load(const std::filesystem::path& path, const std::filesystem::path& root,
            const MilkRustImageDecoder& decode) {
    const auto canonical_root = std::filesystem::canonical(root);
    const auto file = Inside(canonical_root, path);
    const auto size = std::filesystem::file_size(file);
    if (size == 0 || size > 2*1024*1024) throw std::runtime_error("Preset exceeds 2 MiB or is empty.");
    std::ifstream input(file, std::ios::binary);
    std::vector<uint8_t> source(static_cast<size_t>(size));
    if (!input.read(reinterpret_cast<char*>(source.data()), static_cast<std::streamsize>(source.size())) || input.peek() != EOF)
      throw std::runtime_error("Preset changed while loading.");
    Check(api_.load(handle_, source.data(), source.size()));
    const auto capacity = api_.texture_names(handle_, nullptr, 0);
    if (!capacity || capacity > 64*513+1) throw std::runtime_error("Invalid texture dependency list.");
    std::vector<uint8_t> names(capacity);
    if (api_.texture_names(handle_, names.data(), names.size()) != capacity) throw std::runtime_error("Texture dependency list changed.");
    std::istringstream lines(std::string(reinterpret_cast<const char*>(names.data())));
    uint64_t pixels = 0;
    for (std::string name; std::getline(lines, name);) {
      const auto asset = Resolve(canonical_root, file.parent_path(), name);
      if (asset.empty()) continue; // Engine reports a missing asset if the active stage needs it.
      if (std::filesystem::file_size(asset) > 16*1024*1024) throw std::runtime_error("Texture exceeds 16 MiB.");
      const auto image = decode(asset); // Decoder must enforce dimensions before allocation.
      pixels += static_cast<uint64_t>(image.width)*image.height;
      if (!image.width || !image.height || image.width > 4096 || image.height > 4096 ||
          static_cast<uint64_t>(image.width)*image.height > 8*1024*1024 || pixels > 32*1024*1024 ||
          image.rgba.size() != static_cast<uint64_t>(image.width)*image.height*4)
        throw std::runtime_error("Texture dimensions or decoded byte count exceed the image budget.");
      Check(api_.texture(handle_, reinterpret_cast<const uint8_t*>(name.data()), name.size(),
          image.width, image.height, image.rgba.data(), image.rgba.size()));
    }
  }
  void Pcm(const float* stereo, size_t frames, uint32_t generation) {
    for (size_t offset = 0; offset < frames;) {
      const auto count = std::min<size_t>(4096, frames-offset);
      Check(api_.pcm(handle_, stereo+offset*2, count, generation)); offset += count;
    }
  }
  void Render(uint32_t framebuffer, uint32_t width, uint32_t height, double seconds) {
    Check(api_.render(handle_, framebuffer, width, height, seconds));
  }
  void Capture(uint32_t width, uint32_t height, double seconds, std::vector<uint8_t>& rgba) {
    if (!width || !height || width > 4096 || height > 4096 || static_cast<uint64_t>(width)*height > 8*1024*1024)
      throw std::runtime_error("Capture exceeds image budget.");
    rgba.resize(static_cast<size_t>(width)*height*4);
    Check(api_.render_rgba(handle_, width, height, seconds, rgba.data(), rgba.size()));
  }
 private:
  MilkRustApi& api_;
  milkrust_handle handle_ = 0;
  void Check(int result) const { if (result != 0) throw std::runtime_error(api_.Error()); }
  static std::filesystem::path Inside(const std::filesystem::path& root, const std::filesystem::path& candidate) {
    const auto path = std::filesystem::canonical(candidate);
    const auto relative = path.lexically_relative(root);
    if (relative.empty() || *relative.begin() == ".." || !std::filesystem::is_regular_file(path))
      throw std::runtime_error("Asset is outside its verified preset root.");
    return path;
  }
  static std::string Fold(std::string value) {
    for (auto& ch : value) if (ch >= 'A' && ch <= 'Z') ch += 'a'-'A';
    return value;
  }
  static std::filesystem::path CaseInsensitive(const std::filesystem::path& root,
      const std::filesystem::path& candidate, size_t& remaining) {
    auto current = root;
    const auto relative = candidate.lexically_relative(root);
    if (relative.empty()) return {};
    for (const auto& part : relative) {
      if (part == ".." || part == ".") return {};
      if (!std::filesystem::is_directory(current)) return {};
      std::filesystem::path found;
      const auto folded = Fold(part.u8string());
      for (const auto& entry : std::filesystem::directory_iterator(current)) {
        if (remaining == 0) throw std::runtime_error("Texture lookup exceeds the pack entry budget.");
        --remaining;
        if (Fold(entry.path().filename().u8string()) != folded) continue;
        if (!found.empty()) throw std::runtime_error("Texture path has ambiguous case aliases.");
        if (entry.is_symlink()) throw std::runtime_error("Texture paths cannot follow symbolic links.");
        found = entry.path();
      }
      if (found.empty()) return {};
      current = found;
    }
    return Inside(root, current);
  }
  static std::filesystem::path Resolve(const std::filesystem::path& root,
      const std::filesystem::path& preset_folder, std::string name) {
    std::replace(name.begin(), name.end(), '\\', '/');
    const auto relative = std::filesystem::u8path(name);
    if (name.empty() || relative.is_absolute() || name.find(':') != std::string::npos)
      throw std::runtime_error("Texture name is not a relative pack asset.");
    for (const auto& part : relative) if (part == ".." || part == ".") throw std::runtime_error("Unsafe texture path.");
    size_t remaining = 20000;
    for (const auto& directory : {preset_folder, root, root/"textures"}) {
      for (const char* extension : {"", ".png", ".jpg", ".jpeg", ".bmp", ".webp", ".tga", ".dds"}) {
        if (*extension && relative.has_extension()) continue;
        const auto candidate = directory / std::filesystem::u8path(name + extension);
        if (std::filesystem::exists(candidate)) return Inside(root, candidate);
        const auto folded = CaseInsensitive(root, candidate, remaining);
        if (!folded.empty()) return folded;
      }
    }
    return {};
  }
};
} // namespace plezy::visualization
