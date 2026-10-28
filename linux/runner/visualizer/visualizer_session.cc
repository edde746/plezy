#include "visualizer_session.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>
#include <dlfcn.h>
#include <algorithm>
#include <atomic>
#include <chrono>
#include <cctype>
#include <condition_variable>
#include <filesystem>
#include <mutex>
#include <stdexcept>
#include <thread>
#include <vector>
#include "../../../shared/visualization/pcm_resampler.h"

namespace {
using Clock = std::chrono::steady_clock;
struct Frame {
  uint32_t width = 0, height = 0;
  std::vector<uint8_t> pixels;
};
struct FrameState {
  std::mutex mutex;
  std::shared_ptr<const Frame> latest;
  std::atomic<uint64_t> serial{0};
  std::atomic<uint64_t> preset_serial{0};
};

typedef struct _PlezyBufferTexture {
  FlPixelBufferTexture parent_instance;
  std::shared_ptr<FrameState>* state;
  std::shared_ptr<const Frame>* displayed;
} PlezyBufferTexture;
typedef struct _PlezyBufferTextureClass {
  FlPixelBufferTextureClass parent_class;
} PlezyBufferTextureClass;
G_DEFINE_TYPE(PlezyBufferTexture, plezy_buffer_texture, fl_pixel_buffer_texture_get_type())

gboolean CopyPixels(FlPixelBufferTexture* texture, const uint8_t** buffer,
                    uint32_t* width, uint32_t* height, GError**) {
  auto* self = reinterpret_cast<PlezyBufferTexture*>(texture);
  const auto& state = *self->state;
  if (!state) return FALSE;
  {
    std::lock_guard<std::mutex> lock(state->mutex);
    *self->displayed = state->latest;
  }
  // Flutter consumes the pointer after this callback returns. The texture
  // retains this immutable snapshot until its next callback or finalization.
  const auto& frame = *self->displayed;
  if (!frame) return FALSE;
  *buffer = frame->pixels.data(); *width = frame->width; *height = frame->height;
  return TRUE;
}
void TextureFinalize(GObject* object) {
  auto* texture = reinterpret_cast<PlezyBufferTexture*>(object);
  delete texture->displayed; delete texture->state;
  G_OBJECT_CLASS(plezy_buffer_texture_parent_class)->finalize(object);
}
void plezy_buffer_texture_class_init(PlezyBufferTextureClass* klass) {
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = CopyPixels;
  G_OBJECT_CLASS(klass)->finalize = TextureFinalize;
}
void plezy_buffer_texture_init(PlezyBufferTexture* self) {
  self->state = new std::shared_ptr<FrameState>();
  self->displayed = new std::shared_ptr<const Frame>();
}

struct ProjectMApi {
  void* library = nullptr;
  std::string error;
  void* (*create)() = nullptr;
  void (*destroy)(void*) = nullptr;
  void (*version)(int*, int*, int*) = nullptr;
  void (*load)(void*, const char*, bool) = nullptr;
  void (*resize)(void*, size_t, size_t) = nullptr;
  void (*paths)(void*, const char**, size_t) = nullptr;
  void (*lock)(void*, bool) = nullptr;
  void (*failed)(void*, void (*)(const char*, const char*, void*), void*) = nullptr;
  void (*pcm)(void*, const float*, unsigned int, int) = nullptr;
  unsigned int (*max_samples)() = nullptr;
  int (*render)(void*, unsigned int) = nullptr;

  ProjectMApi() {
    library = dlopen("libprojectM-4.so.4", RTLD_NOW | RTLD_LOCAL);
    if (!library) { error = "The native projectM renderer is not installed in this build."; return; }
#define LOAD(field, symbol) field = reinterpret_cast<decltype(field)>(dlsym(library, symbol)); \
    if (!field) { error = "The projectM dependency lacks the pinned Plezy framebuffer API."; return; }
    LOAD(create, "projectm_create")
    LOAD(destroy, "projectm_destroy")
    LOAD(version, "projectm_get_version_components")
    LOAD(load, "projectm_load_preset_file")
    LOAD(resize, "projectm_set_window_size")
    LOAD(paths, "projectm_set_texture_search_paths")
    LOAD(lock, "projectm_set_preset_locked")
    LOAD(failed, "projectm_set_preset_switch_failed_event_callback")
    LOAD(pcm, "projectm_pcm_add_float")
    LOAD(max_samples, "projectm_pcm_get_max_samples")
    LOAD(render, "projectm_plezy_render_frame_fbo")
#undef LOAD
    int major = 0, minor = 0, patch = 0;
    version(&major, &minor, &patch);
    if (major != 4 || minor != 1 || patch != 8)
      error = "This build requires the pinned projectM 4.1.8 dependency.";
  }
  ~ProjectMApi() { if (library) dlclose(library); }
};
ProjectMApi& Api() { static ProjectMApi api; return api; }

// An independent surfaceless Mesa EGL display avoids sharing or altering
// Flutter's context and the Wayland video plane's context/display lifecycle.
struct OffscreenContext {
  EGLDisplay display = EGL_NO_DISPLAY;
  EGLSurface surface = EGL_NO_SURFACE;
  EGLContext context = EGL_NO_CONTEXT;
  GLuint framebuffer = 0, texture = 0;
  int width = 0, height = 0;
  void Initialize() {
    using GetDisplay = EGLDisplay (*)(EGLenum, void*, const EGLint*);
    auto get_display = reinterpret_cast<GetDisplay>(eglGetProcAddress("eglGetPlatformDisplayEXT"));
    if (!get_display) throw std::runtime_error("Surfaceless EGL is unavailable on this driver.");
    display = get_display(0x31DD /* EGL_PLATFORM_SURFACELESS_MESA */, EGL_DEFAULT_DISPLAY, nullptr);
    if (display == EGL_NO_DISPLAY || !eglInitialize(display, nullptr, nullptr))
      throw std::runtime_error("Could not initialize the offscreen visualization display.");
    if (!eglBindAPI(EGL_OPENGL_ES_API)) throw std::runtime_error("OpenGL ES is unavailable.");
    EGLint attributes[] = {EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RENDERABLE_TYPE, 0x0040,
                           EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8,
                           EGL_ALPHA_SIZE, 8, EGL_NONE};
    EGLConfig config{}; EGLint count = 0;
    if (!eglChooseConfig(display, attributes, &config, 1, &count) || count != 1)
      throw std::runtime_error("No GLES 3 configuration for visualization.");
    EGLint pbuffer[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};
    surface = eglCreatePbufferSurface(display, config, pbuffer);
    EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE};
    context = eglCreateContext(display, config, EGL_NO_CONTEXT, context_attributes);
    if (surface == EGL_NO_SURFACE || context == EGL_NO_CONTEXT ||
        !eglMakeCurrent(display, surface, surface, context))
      throw std::runtime_error("Could not create a visualization GLES context.");
  }
  void Resize(int w, int h) {
    if (w == width && h == height) return;
    if (framebuffer) glDeleteFramebuffers(1, &framebuffer);
    if (texture) glDeleteTextures(1, &texture);
    framebuffer = texture = 0;
    glGenTextures(1, &texture); glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glGenFramebuffers(1, &framebuffer); glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
      throw std::runtime_error("Visualization framebuffer is incomplete.");
    width = w; height = h;
  }
  ~OffscreenContext() {
    if (context != EGL_NO_CONTEXT && display != EGL_NO_DISPLAY) {
      eglMakeCurrent(display, surface, surface, context);
      if (framebuffer) glDeleteFramebuffers(1, &framebuffer);
      if (texture) glDeleteTextures(1, &texture);
      eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
      eglDestroyContext(display, context);
    }
    if (surface != EGL_NO_SURFACE) eglDestroySurface(display, surface);
    if (display != EGL_NO_DISPLAY) eglTerminate(display);
  }
};
struct Engine {
  void* instance = nullptr;
  ~Engine() { if (instance) { try { Api().destroy(instance); } catch (...) {} } }
};
} // namespace

namespace plezy::visualization {
struct VisualizerSession::Impl {
  FlTextureRegistrar* registrar;
  PlezyBufferTexture* texture;
  std::shared_ptr<FrameState> frames = std::make_shared<FrameState>();
  AudioReader reader;
  mutable std::mutex mutex;
  std::condition_variable condition;
  std::thread worker;
  bool stopping = false, paused = true;
  int width = 768, height = 432;
  std::string path, root, state = "starting", error;
  uint64_t preset_serial = 0;
  uint32_t dropped = 0;
  guint timer = 0;
  uint64_t marked_serial = 0;

  Impl(FlTextureRegistrar* r, AudioReader callback)
      : registrar(FL_TEXTURE_REGISTRAR(g_object_ref(r))), reader(std::move(callback)) {
    texture = reinterpret_cast<PlezyBufferTexture*>(g_object_new(plezy_buffer_texture_get_type(), nullptr));
    *texture->state = frames;
    if (!fl_texture_registrar_register_texture(registrar, FL_TEXTURE(texture))) {
      g_object_unref(texture); g_object_unref(registrar);
      throw std::runtime_error("Flutter rejected the visualization texture.");
    }
    timer = g_timeout_add(33, [](gpointer data) -> gboolean {
      auto* self = static_cast<Impl*>(data);
      auto serial = self->frames->serial.load();
      if (serial != self->marked_serial) {
        self->marked_serial = serial;
        fl_texture_registrar_mark_texture_frame_available(self->registrar, FL_TEXTURE(self->texture));
      }
      return G_SOURCE_CONTINUE;
    }, this);
    try {
      worker = std::thread([this] { Run(); });
    } catch (...) {
      g_source_remove(timer);
      fl_texture_registrar_unregister_texture(registrar, FL_TEXTURE(texture));
      g_object_unref(texture); g_object_unref(registrar);
      throw;
    }
  }
  ~Impl() {
    if (timer) g_source_remove(timer);
    { std::lock_guard<std::mutex> lock(mutex); stopping = true; }
    condition.notify_all();
    if (worker.joinable()) worker.join();
    fl_texture_registrar_unregister_texture(registrar, FL_TEXTURE(texture));
    g_object_unref(texture); g_object_unref(registrar);
  }
  void State(const std::string& value, const std::string& reason = {}) {
    std::lock_guard<std::mutex> lock(mutex); state = value; error = reason;
  }
  void Run() {
    try {
      if (!Api().error.empty()) throw std::runtime_error(Api().error);
      OffscreenContext graphics; graphics.Initialize();
      std::string load_error; // Callback target must outlive Engine destruction.
      Engine engine;
      uint64_t loaded_serial = 0;
      uint32_t generation = 0;
      PcmResampler resampler;
      std::vector<float> pcm;
      auto audio_at = Clock::time_point{};
      for (;;) {
        auto started = Clock::now();
        std::string requested_path, requested_root;
        uint64_t serial; int w, h;
        {
          std::unique_lock<std::mutex> lock(mutex);
          condition.wait(lock, [this] { return stopping || (!paused && !path.empty()); });
          if (stopping) break;
          requested_path = path; requested_root = root; serial = preset_serial;
          w = width; h = height;
        }
        graphics.Resize(w, h);
        mpv_plezy_audio_block block{};
        bool audio_received = false;
        for (int n = 0; n < 32; ++n) {
          const int result = reader(&block);
          if (result == MPV_PLEZY_AUDIO_UNSUPPORTED) {
            State("unavailable", "The active audio output cannot provide visualization PCM.");
            audio_received = false; audio_at = Clock::time_point{}; break;
          }
          if (result < 0) throw std::runtime_error("The music PCM tap was lost.");
          if (result == 0) break;
          if (block.generation != generation) {
            if (engine.instance) { Api().destroy(engine.instance); engine.instance = nullptr; }
            generation = block.generation; loaded_serial = 0;
            resampler = PcmResampler();
          }
          if (!engine.instance) {
            engine.instance = Api().create();
            if (!engine.instance) throw std::runtime_error("projectM could not initialize.");
            Api().failed(engine.instance, [](const char*, const char* message, void* target) {
              *static_cast<std::string*>(target) = message ? message : "Preset loading failed.";
            }, &load_error);
            Api().lock(engine.instance, true);
          }
          Api().resize(engine.instance, w, h);
          if (loaded_serial != serial) {
            std::string textures = requested_root + "/textures";
            const char* roots[] = {requested_root.c_str(), textures.c_str()};
            Api().paths(engine.instance, roots, 2);
            load_error.clear();
            Api().load(engine.instance, requested_path.c_str(), loaded_serial != 0);
            if (!load_error.empty()) throw std::runtime_error(load_error);
            loaded_serial = serial;
          }
          if (!resampler.Convert(block, &pcm)) {
            State("unavailable", "This sample rate or speaker layout is not supported for analysis.");
            audio_received = false; audio_at = Clock::time_point{}; break;
          }
          const unsigned int maximum = Api().max_samples();
          if (!maximum) throw std::runtime_error("Invalid projectM PCM capacity.");
          for (size_t offset = 0; offset < pcm.size() / 2;) {
            auto count = static_cast<unsigned int>(std::min<size_t>(maximum, pcm.size() / 2 - offset));
            Api().pcm(engine.instance, pcm.data() + offset * 2, count, 2 /* stereo */);
            offset += count;
          }
          audio_received = true;
          { std::lock_guard<std::mutex> lock(mutex); dropped = block.dropped_frames; }
        }
        if (audio_received) audio_at = Clock::now();
        if (engine.instance && loaded_serial == serial && Clock::now() - audio_at < std::chrono::milliseconds(250)) {
          Api().resize(engine.instance, w, h);
          if (Api().render(engine.instance, graphics.framebuffer) != 0)
            throw std::runtime_error("projectM failed to render this preset.");
          auto frame = std::make_shared<Frame>();
          frame->width = w; frame->height = h; frame->pixels.resize(static_cast<size_t>(w) * h * 4);
          glBindFramebuffer(GL_FRAMEBUFFER, graphics.framebuffer);
          glPixelStorei(GL_PACK_ALIGNMENT, 1);
          glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, frame->pixels.data());
          if (glGetError() != GL_NO_ERROR) throw std::runtime_error("Visualization frame readback failed.");
          const size_t stride = static_cast<size_t>(w) * 4;
          for (int y = 0; y < h / 2; ++y)
            std::swap_ranges(frame->pixels.begin() + y * stride, frame->pixels.begin() + (y + 1) * stride,
                             frame->pixels.begin() + (h - y - 1) * stride);
          { std::lock_guard<std::mutex> lock(frames->mutex); frames->latest = std::move(frame); }
          frames->preset_serial.store(serial);
          frames->serial.fetch_add(1);
          State("rendering");
        } else {
          std::lock_guard<std::mutex> lock(mutex);
          if (state != "unavailable") { state = "waiting-audio"; error.clear(); }
        }
        std::unique_lock<std::mutex> lock(mutex);
        condition.wait_until(lock, started + std::chrono::milliseconds(33), [this] { return stopping || paused; });
        if (stopping) break;
      }
    } catch (const std::exception& ex) { State("failed", ex.what()); }
      catch (...) { State("failed", "The native visualization engine stopped unexpectedly."); }
  }
};

std::string VisualizerSession::DependencyError() { return Api().error; }
VisualizerSession::VisualizerSession(FlTextureRegistrar* registrar, AudioReader reader)
    : impl_(std::make_unique<Impl>(registrar, std::move(reader))) {}
VisualizerSession::~VisualizerSession() = default;
int64_t VisualizerSession::texture_id() const { return fl_texture_get_id(FL_TEXTURE(impl_->texture)); }
bool VisualizerSession::LoadPreset(const std::string& path, const std::string& root, std::string* error) {
  try {
    const auto base = std::filesystem::canonical(root);
    const auto file = std::filesystem::canonical(path);
    const auto relative = file.lexically_relative(base);
    std::string extension = file.extension().string();
    std::transform(extension.begin(), extension.end(), extension.begin(), [](unsigned char c) { return std::tolower(c); });
    if (relative.empty() || *relative.begin() == ".." || extension != ".milk" ||
        !std::filesystem::is_regular_file(file) || std::filesystem::file_size(file) > 2 * 1024 * 1024)
      throw std::runtime_error("Select a .milk file within the installed library, no larger than 2 MB.");
    { std::lock_guard<std::mutex> lock(impl_->mutex);
      if (impl_->state == "failed" || impl_->stopping)
        throw std::runtime_error("Create a new visualization session to retry this preset.");
      impl_->path = file.string(); impl_->root = base.string(); ++impl_->preset_serial;
      impl_->error.clear(); impl_->state = "loading";
    }
    impl_->condition.notify_all();
    return true;
  } catch (const std::exception& ex) { *error = ex.what(); return false; }
}
void VisualizerSession::Resize(int width, int height) {
  width = std::clamp(width, 1, 16384); height = std::clamp(height, 1, 16384);
  const double scale = std::min({1.0, 1280.0 / width, 720.0 / height});
  std::lock_guard<std::mutex> lock(impl_->mutex);
  impl_->width = std::max(1, static_cast<int>(width * scale));
  impl_->height = std::max(1, static_cast<int>(height * scale));
}
void VisualizerSession::SetPaused(bool paused) {
  { std::lock_guard<std::mutex> lock(impl_->mutex); impl_->paused = paused; }
  impl_->condition.notify_all();
}
FlValue* VisualizerSession::Status() const {
  std::lock_guard<std::mutex> lock(impl_->mutex);
  FlValue* result = fl_value_new_map();
  const bool inactive = impl_->paused && impl_->state != "failed" && impl_->state != "unavailable";
  fl_value_set_string_take(result, "state", fl_value_new_string(inactive ? "paused" : impl_->state.c_str()));
  fl_value_set_string_take(result, "reason", fl_value_new_string(impl_->error.c_str()));
  fl_value_set_string_take(result, "hasFrame", fl_value_new_bool(impl_->frames->serial.load() != 0 &&
      impl_->frames->preset_serial.load() == impl_->preset_serial));
  fl_value_set_string_take(result, "droppedFrames", fl_value_new_int(impl_->dropped));
  fl_value_set_string_take(result, "width", fl_value_new_int(impl_->width));
  fl_value_set_string_take(result, "height", fl_value_new_int(impl_->height));
  return result;
}
} // namespace plezy::visualization
