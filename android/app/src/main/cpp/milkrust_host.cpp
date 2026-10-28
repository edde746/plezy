// SPDX-License-Identifier: AGPL-3.0-only
#include <jni.h>
#include <android/bitmap.h>
#include <android/native_window_jni.h>
#include <EGL/egl.h>
#include <dlfcn.h>
#include <map>
#include <atomic>
#include "../../../../../shared/visualization/native_worker.h"

using namespace plezy::visualization;
namespace {
struct TapApi {
  void* library = dlopen("libplayer.so", RTLD_NOW | RTLD_LOCAL);
  int (*version)() = library ? reinterpret_cast<int(*)()>(dlsym(library,"plezy_android_visualization_version")) : nullptr;
  int (*enable)(uint64_t,int) = library ? reinterpret_cast<int(*)(uint64_t,int)>(dlsym(library,"plezy_android_visualization_enable")) : nullptr;
  int (*read)(uint64_t,void*,size_t) = library ? reinterpret_cast<int(*)(uint64_t,void*,size_t)>(dlsym(library,"plezy_android_visualization_read")) : nullptr;
  bool available() const { return version && enable && read && version() == 1; }
  // Kept loaded for every host/session lifetime.
};
TapApi& Tap() { static TapApi value; return value; }
std::string DependencyError() {
  if (!Tap().available()) return "This mpv AAR lacks the session-leased visualization PCM bridge v1.";
  return MilkRustApi::Shared().error;
}
class EglContext final : public NativeContext {
 public:
  EglContext() {
    try {
      display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
      if (display_ == EGL_NO_DISPLAY || !eglInitialize(display_, nullptr, nullptr) || !eglBindAPI(EGL_OPENGL_ES_API))
        throw std::runtime_error("Could not initialize visualization EGL.");
      const EGLint attrs[] = {EGL_RENDERABLE_TYPE, 0x40, EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
          EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_NONE};
      EGLConfig config; EGLint count;
      if (!eglChooseConfig(display_, attrs, &config, 1, &count) || count != 1) throw std::runtime_error("GLES 3 is unavailable.");
      const EGLint pb[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE}, ctx[] = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE};
      surface_ = eglCreatePbufferSurface(display_, config, pb);
      context_ = eglCreateContext(display_, config, EGL_NO_CONTEXT, ctx);
      if (surface_ == EGL_NO_SURFACE || context_ == EGL_NO_CONTEXT || !eglMakeCurrent(display_, surface_, surface_, context_))
        throw std::runtime_error("Could not create the GLES 3 visualization context.");
    } catch (...) { Release(); throw; }
  }
  ~EglContext() override { Release(); }
  milkrust_gl_loader Loader() const override {
    return +[](const char* name) -> const void* { return reinterpret_cast<const void*>(eglGetProcAddress(name)); };
  }
  bool IsGles() const override { return true; }
 private:
  EGLDisplay display_ = EGL_NO_DISPLAY; EGLContext context_ = EGL_NO_CONTEXT; EGLSurface surface_ = EGL_NO_SURFACE;
  void Release() {
    if (display_ != EGL_NO_DISPLAY) {
      eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
      if (context_ != EGL_NO_CONTEXT) eglDestroyContext(display_, context_);
      if (surface_ != EGL_NO_SURFACE) eglDestroySurface(display_, surface_);
      eglTerminate(display_); display_ = EGL_NO_DISPLAY;
    }
  }
};
struct JavaDecoder {
  JavaVM* vm = nullptr; jclass type = nullptr; jmethodID method = nullptr;
  JavaDecoder(JNIEnv* env, jobject owner) {
    env->GetJavaVM(&vm); auto local = env->GetObjectClass(owner);
    type = static_cast<jclass>(env->NewGlobalRef(local)); env->DeleteLocalRef(local);
    if (!type) { if (env->ExceptionCheck()) env->ExceptionClear(); throw std::runtime_error("Image decoder reference allocation failed."); }
    method = env->GetStaticMethodID(type,"decodeTexture","(Ljava/lang/String;)Landroid/graphics/Bitmap;");
    if (!type || !method) { if (env->ExceptionCheck()) env->ExceptionClear();
      if (type) env->DeleteGlobalRef(type); type = nullptr;
      throw std::runtime_error("Android image decoder is unavailable."); }
  }
  ~JavaDecoder() {
    JNIEnv* env = nullptr; bool detach = false;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
      if (vm->AttachCurrentThread(&env, nullptr) != JNI_OK) return; detach = true;
    }
    if (type) env->DeleteGlobalRef(type);
    if (detach) vm->DetachCurrentThread();
  }
  MilkRustImage Decode(const std::filesystem::path& path) {
    JNIEnv* env = nullptr;
    if (vm->AttachCurrentThread(&env, nullptr) != JNI_OK) throw std::runtime_error("Could not attach the image decoder worker.");
    struct Detach { JavaVM* vm; ~Detach() { vm->DetachCurrentThread(); } } detach{vm};
    // Native pack paths arrive as UTF-8, converted through Java's UTF-8 decoder
    // rather than JNI modified UTF-8 (which cannot represent all filenames).
    const auto text = path.u8string();
    jbyteArray bytes = env->NewByteArray(static_cast<jsize>(text.size()));
    if (!bytes) { env->ExceptionClear(); throw std::runtime_error("Image path allocation failed."); }
    env->SetByteArrayRegion(bytes, 0, text.size(), reinterpret_cast<const jbyte*>(text.data()));
    jclass string_class = env->FindClass("java/lang/String");
    auto constructor = env->GetMethodID(string_class,"<init>","([BLjava/lang/String;)V");
    auto charset = env->NewStringUTF("UTF-8");
    auto name = env->NewObject(string_class,constructor,bytes,charset);
    auto bitmap = env->CallStaticObjectMethod(type,method,name);
    if (env->ExceptionCheck() || !bitmap) { env->ExceptionClear(); throw std::runtime_error("Android rejected the texture or its image budget."); }
    AndroidBitmapInfo info{};
    if (AndroidBitmap_getInfo(env,bitmap,&info) != ANDROID_BITMAP_RESULT_SUCCESS || info.format != ANDROID_BITMAP_FORMAT_RGBA_8888
        || !info.width || !info.height || info.width > 4096 || info.height > 4096 || static_cast<uint64_t>(info.width)*info.height > 8*1024*1024)
      throw std::runtime_error("Invalid decoded Android texture.");
    MilkRustImage image; image.width = info.width; image.height = info.height;
    image.rgba.resize(static_cast<size_t>(info.width)*info.height*4);
    void* pixels = nullptr;
    if (AndroidBitmap_lockPixels(env,bitmap,&pixels) != ANDROID_BITMAP_RESULT_SUCCESS) throw std::runtime_error("Could not lock decoded texture.");
    for (uint32_t y=0;y<info.height;++y) std::copy_n(static_cast<uint8_t*>(pixels)+y*info.stride,info.width*4,image.rgba.data()+static_cast<size_t>(y)*info.width*4);
    AndroidBitmap_unlockPixels(env,bitmap);
    return image;
  }
};
struct Host {
  uint64_t player = 0; ANativeWindow* window = nullptr;
  std::shared_ptr<JavaDecoder> decoder;
  std::unique_ptr<NativeWorker> worker;
  ~Host() { worker.reset(); if (player && Tap().available()) Tap().enable(player,0); if (window) ANativeWindow_release(window); }
};
std::mutex registry_mutex;
std::map<jlong,std::shared_ptr<Host>> registry;
std::atomic<jlong> next_id{1};
std::shared_ptr<Host> Find(jlong id) {
  std::lock_guard<std::mutex> lock(registry_mutex);
  auto found=registry.find(id); if (found==registry.end()) throw std::runtime_error("Stale native visualization session."); return found->second;
}
void Error(JNIEnv* env, const std::exception& error) {
  if (env->ExceptionCheck()) env->ExceptionClear();
  env->ThrowNew(env->FindClass("java/lang/IllegalStateException"),error.what());
}
std::string Utf8(JNIEnv* env, jstring string) {
  if (!string) throw std::runtime_error("Missing path.");
  const jsize length = env->GetStringLength(string);
  if (length > 32768) throw std::runtime_error("Path is too long.");
  auto chars = env->GetStringChars(string,nullptr);
  if (!chars) throw std::runtime_error("Path allocation failed.");
  std::string out;
  for (jsize i=0; i<length; ++i) {
    uint32_t cp=chars[i];
    if (cp>=0xD800 && cp<=0xDBFF && i+1<length && chars[i+1]>=0xDC00 && chars[i+1]<=0xDFFF)
      cp=0x10000+((cp-0xD800)<<10)+(chars[++i]-0xDC00);
    else if (cp>=0xD800 && cp<=0xDFFF) cp=0xFFFD;
    if (cp==0) { env->ReleaseStringChars(string,chars); throw std::runtime_error("NUL in path."); }
    if (cp<128) out.push_back(static_cast<char>(cp));
    else if (cp<2048) {out.push_back(0xC0|(cp>>6));out.push_back(0x80|(cp&63));}
    else if (cp<65536) {out.push_back(0xE0|(cp>>12));out.push_back(0x80|((cp>>6)&63));out.push_back(0x80|(cp&63));}
    else {out.push_back(0xF0|(cp>>18));out.push_back(0x80|((cp>>12)&63));out.push_back(0x80|((cp>>6)&63));out.push_back(0x80|(cp&63));}
  }
  env->ReleaseStringChars(string,chars); return out;
}
}
#define JNI_NAME(name) Java_com_edde746_plezy_mpv_MilkRustNativeBridge_##name
extern "C" JNIEXPORT jstring JNICALL JNI_NAME(dependencyError)(JNIEnv* env,jobject) {
  try { return env->NewStringUTF(DependencyError().c_str()); } catch (const std::exception& ex) {Error(env,ex);return nullptr;}
}
extern "C" JNIEXPORT jlong JNICALL JNI_NAME(create)(JNIEnv* env,jobject owner,jlong player,jobject surface) {
  try {
    const auto unavailable=DependencyError(); if (!unavailable.empty()) throw std::runtime_error(unavailable);
    auto host=std::make_shared<Host>(); host->decoder=std::make_shared<JavaDecoder>(env,owner);
    host->window=ANativeWindow_fromSurface(env,surface); if (!host->window) throw std::runtime_error("No Android visualization surface.");
    if (player<=0 || Tap().enable(player,1)<0) throw std::runtime_error("Could not attach to the music session PCM.");
    host->player=player; auto decoder=host->decoder; auto* window=host->window;
    host->worker=std::make_unique<NativeWorker>([] {return std::make_unique<EglContext>();},
        [decoder](const auto& path) {return decoder->Decode(path);},
        [player](mpv_plezy_audio_block* block) {return Tap().read(player,block,sizeof(*block));},
        [window, width=0u, height=0u](std::shared_ptr<const NativeFrame> frame) mutable {
          if ((width != frame->width || height != frame->height) && ANativeWindow_setBuffersGeometry(window,frame->width,frame->height,WINDOW_FORMAT_RGBA_8888)<0)
            throw std::runtime_error("Could not size the Android visualization surface.");
          width = frame->width; height = frame->height;
          ANativeWindow_Buffer buffer{};
          if (ANativeWindow_lock(window,&buffer,nullptr)<0) throw std::runtime_error("Android visualization surface was lost.");
          if (buffer.width!=static_cast<int32_t>(frame->width) || buffer.height!=static_cast<int32_t>(frame->height) || buffer.stride<buffer.width) {
            ANativeWindow_unlockAndPost(window); throw std::runtime_error("Android surface dimensions changed.");
          }
          for (uint32_t y=0;y<frame->height;++y) std::copy_n(frame->rgba.data()+static_cast<size_t>(y)*frame->width*4,frame->width*4,
              static_cast<uint8_t*>(buffer.bits)+static_cast<size_t>(y)*buffer.stride*4);
          if (ANativeWindow_unlockAndPost(window)<0) throw std::runtime_error("Android frame presentation failed.");
        });
    std::lock_guard<std::mutex> lock(registry_mutex);
    if (registry.size()>=4) throw std::runtime_error("Too many native visualization sessions.");
    const auto id=next_id.fetch_add(1); if (id<=0) throw std::runtime_error("Native session identity exhausted.");
    registry.emplace(id,std::move(host)); return id;
  } catch (const std::exception& ex) {Error(env,ex);return 0;}
}
extern "C" JNIEXPORT void JNICALL JNI_NAME(destroy)(JNIEnv* env,jobject,jlong id) {
  try {std::shared_ptr<Host> host; {std::lock_guard<std::mutex> lock(registry_mutex);auto it=registry.find(id);
      if(it==registry.end())return;host=std::move(it->second);registry.erase(it);} host.reset();
  } catch(const std::exception& ex){Error(env,ex);}
}
extern "C" JNIEXPORT void JNICALL JNI_NAME(load)(JNIEnv* env,jobject,jlong id,jstring path,jstring root) {
  try{Find(id)->worker->Load(Utf8(env,path),Utf8(env,root));}catch(const std::exception& ex){Error(env,ex);}
}
extern "C" JNIEXPORT void JNICALL JNI_NAME(resize)(JNIEnv* env,jobject,jlong id,jint width,jint height) {
  try{Find(id)->worker->Resize(width,height);}catch(const std::exception& ex){Error(env,ex);}
}
extern "C" JNIEXPORT void JNICALL JNI_NAME(pause)(JNIEnv* env,jobject,jlong id,jboolean paused) {
  try{Find(id)->worker->Pause(paused);}catch(const std::exception& ex){Error(env,ex);}
}
extern "C" JNIEXPORT jobjectArray JNICALL JNI_NAME(status)(JNIEnv* env,jobject,jlong id) {
  try{const auto s=Find(id)->worker->Status(); auto result=env->NewObjectArray(6,env->FindClass("java/lang/String"),nullptr);
    const std::string fields[]={s.state,s.reason,s.has_frame?"1":"0",std::to_string(s.dropped),std::to_string(s.width),std::to_string(s.height)};
    for(int i=0;i<6;++i){auto value=env->NewStringUTF(fields[i].c_str());env->SetObjectArrayElement(result,i,value);env->DeleteLocalRef(value);}return result;
  }catch(const std::exception& ex){Error(env,ex);return nullptr;}
}
