// SPDX-License-Identifier: AGPL-3.0-only
#include "visualizer_session.h"
#include <windows.h>
#include <gl/GL.h>
#include <wincodec.h>
#include <wrl/client.h>

namespace plezy::visualization {
namespace {
using Microsoft::WRL::ComPtr;
void Check(HRESULT result) { if (FAILED(result)) throw std::runtime_error("Windows image decoder failed."); }
class WglContext final : public NativeContext {
 public:
  WglContext() {
    try {
      Check(CoInitializeEx(nullptr, COINIT_MULTITHREADED)); com_ = true;
      static std::once_flag once;
      std::call_once(once, [] {
        WNDCLASSW cls{}; cls.lpfnWndProc = DefWindowProcW; cls.hInstance = GetModuleHandleW(nullptr);
        cls.style = CS_OWNDC; cls.lpszClassName = L"PlezyMilkRustOffscreen";
        if (!RegisterClassW(&cls) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS)
          throw std::runtime_error("Could not register the offscreen visualization window.");
      });
      window_ = CreateWindowW(L"PlezyMilkRustOffscreen", L"", WS_POPUP, 0, 0, 1, 1,
          nullptr, nullptr, GetModuleHandleW(nullptr), nullptr);
      if (!window_ || !(dc_ = GetDC(window_))) throw std::runtime_error("Could not allocate the offscreen visualization window.");
      PIXELFORMATDESCRIPTOR format{}; format.nSize = sizeof(format); format.nVersion = 1;
      format.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL; format.iPixelType = PFD_TYPE_RGBA;
      format.cColorBits = 32; format.cAlphaBits = 8; format.iLayerType = PFD_MAIN_PLANE;
      const auto index = ChoosePixelFormat(dc_, &format);
      if (!index || !SetPixelFormat(dc_, index, &format)) throw std::runtime_error("No OpenGL pixel format.");
      context_ = wglCreateContext(dc_);
      if (!context_ || !wglMakeCurrent(dc_, context_)) throw std::runtime_error("Could not initialize OpenGL.");
      using Create = HGLRC (WINAPI*)(HDC, HGLRC, const int*);
      auto create = reinterpret_cast<Create>(Proc("wglCreateContextAttribsARB"));
      if (!create) throw std::runtime_error("OpenGL 3.2 core contexts are unavailable.");
      const int attributes[] = {0x2091, 3, 0x2092, 2, 0x9126, 1, 0};
      auto core = create(dc_, nullptr, attributes);
      if (!core) throw std::runtime_error("Could not create the MilkRust OpenGL 3.2 context.");
      wglMakeCurrent(nullptr, nullptr); wglDeleteContext(context_); context_ = core;
      if (!wglMakeCurrent(dc_, context_)) throw std::runtime_error("Could not activate the MilkRust context.");
    } catch (...) { Release(); throw; }
  }
  ~WglContext() override { Release(); }
  milkrust_gl_loader Loader() const override { return Proc; }
  bool IsGles() const override { return false; }
 private:
  HWND window_ = nullptr; HDC dc_ = nullptr; HGLRC context_ = nullptr; bool com_ = false;
  static const void* Proc(const char* name) {
    const auto pointer = wglGetProcAddress(name);
    const auto value = reinterpret_cast<uintptr_t>(pointer);
    if (pointer && value > 3 && value != UINTPTR_MAX) return reinterpret_cast<const void*>(pointer);
    return reinterpret_cast<const void*>(GetProcAddress(GetModuleHandleW(L"opengl32.dll"), name));
  }
  void Release() {
    if (context_) { wglMakeCurrent(nullptr, nullptr); wglDeleteContext(context_); context_ = nullptr; }
    if (dc_) { ReleaseDC(window_, dc_); dc_ = nullptr; }
    if (window_) { DestroyWindow(window_); window_ = nullptr; }
    if (com_) { CoUninitialize(); com_ = false; }
  }
};
MilkRustImage Decode(const std::filesystem::path& path) {
  const auto length = std::filesystem::file_size(path);
  if (!length || length > 16*1024*1024) throw std::runtime_error("Texture exceeds the encoded image budget.");
  std::vector<uint8_t> bytes(static_cast<size_t>(length));
  std::ifstream file(path, std::ios::binary);
  if (!file.read(reinterpret_cast<char*>(bytes.data()), static_cast<std::streamsize>(bytes.size())) || file.peek() != EOF)
    throw std::runtime_error("Texture changed while loading.");
  ComPtr<IWICImagingFactory> factory; Check(CoCreateInstance(CLSID_WICImagingFactory, nullptr,
      CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory)));
  ComPtr<IWICStream> stream; Check(factory->CreateStream(&stream));
  Check(stream->InitializeFromMemory(bytes.data(), static_cast<DWORD>(bytes.size())));
  ComPtr<IWICBitmapDecoder> decoder; Check(factory->CreateDecoderFromStream(stream.Get(), nullptr,
      WICDecodeMetadataCacheOnDemand, &decoder));
  ComPtr<IWICBitmapFrameDecode> frame; Check(decoder->GetFrame(0, &frame));
  MilkRustImage image; Check(frame->GetSize(&image.width, &image.height));
  if (!image.width || !image.height || image.width > 4096 || image.height > 4096 ||
      static_cast<uint64_t>(image.width)*image.height > 8*1024*1024)
    throw std::runtime_error("Texture dimensions exceed the decoded image budget.");
  ComPtr<IWICFormatConverter> converter; Check(factory->CreateFormatConverter(&converter));
  Check(converter->Initialize(frame.Get(), GUID_WICPixelFormat32bppRGBA, WICBitmapDitherTypeNone,
      nullptr, 0, WICBitmapPaletteTypeCustom));
  image.rgba.resize(static_cast<size_t>(image.width)*image.height*4);
  Check(converter->CopyPixels(nullptr, image.width*4, static_cast<UINT>(image.rgba.size()), image.rgba.data()));
  return image;
}
struct FrameSlot { std::mutex mutex; std::shared_ptr<const NativeFrame> frame; };
struct PixelLease {
  std::shared_ptr<const NativeFrame> frame;
  FlutterDesktopPixelBuffer buffer{};
  explicit PixelLease(std::shared_ptr<const NativeFrame> value) : frame(std::move(value)) {
    buffer.buffer = frame->rgba.data(); buffer.width = frame->width; buffer.height = frame->height;
    buffer.release_context = this; buffer.release_callback = [](void* context) { delete static_cast<PixelLease*>(context); };
  }
};
} // namespace
WindowsVisualizerSession::WindowsVisualizerSession(flutter::TextureRegistrar* registrar, NativeWorker::AudioReader reader)
    : registrar_(registrar) {
  if (!MilkRustApi::Shared().error.empty()) throw std::runtime_error(MilkRustApi::Shared().error);
  auto slot = std::make_shared<FrameSlot>();
  texture_ = std::make_shared<flutter::TextureVariant>(flutter::PixelBufferTexture(
      [slot](size_t, size_t) -> const FlutterDesktopPixelBuffer* {
        std::lock_guard<std::mutex> lock(slot->mutex);
        return slot->frame ? &(new PixelLease(slot->frame))->buffer : nullptr;
      }));
  texture_id_ = registrar_->RegisterTexture(texture_.get());
  if (texture_id_ < 0) throw std::runtime_error("Flutter rejected the native visualization texture.");
  try {
    worker_ = std::make_unique<NativeWorker>([] { return std::make_unique<WglContext>(); }, Decode,
        std::move(reader), [slot, registrar, id = texture_id_](std::shared_ptr<const NativeFrame> frame) {
          { std::lock_guard<std::mutex> lock(slot->mutex); slot->frame = std::move(frame); }
          registrar->MarkTextureFrameAvailable(id);
        });
  } catch (...) { registrar_->UnregisterTexture(texture_id_, [keep = texture_] {}); throw; }
}
WindowsVisualizerSession::~WindowsVisualizerSession() {
  worker_.reset();
  if (texture_id_ >= 0) registrar_->UnregisterTexture(texture_id_, [keep = std::move(texture_)] {});
}
} // namespace plezy::visualization
