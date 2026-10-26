// SPDX-License-Identifier: GPL-3.0-or-later
#include <jni.h>

#include <cstring>
#include <stdexcept>
#include <unordered_map>

#include "steam_runtime.h"
using namespace plezy::steam;
namespace {
JavaVM* vm = nullptr;
std::mutex registryMutex;
std::unordered_map<jlong, std::shared_ptr<Runtime>> registry;
jlong nextHandle = 1;
struct Env {
  JNIEnv* value = nullptr;
  bool attached = false;
  Env() {
    if (vm->GetEnv(reinterpret_cast<void**>(&value), JNI_VERSION_1_6) != JNI_OK) {
#ifdef __ANDROID__
      attached = vm->AttachCurrentThread(&value, nullptr) == JNI_OK;
#else
      attached = vm->AttachCurrentThread(reinterpret_cast<void**>(&value), nullptr) == JNI_OK;
#endif
    }
  }
  ~Env() {
    if (attached) vm->DetachCurrentThread();
  }
};
std::shared_ptr<Runtime> get(jlong handle) {
  std::lock_guard<std::mutex> lock(registryMutex);
  auto it = registry.find(handle);
  return it == registry.end() ? nullptr : it->second;
}
std::string string(JNIEnv* env, jstring value) {
  if (!value) return {};
  const char* chars = env->GetStringUTFChars(value, nullptr);
  if (!chars) return {};
  std::string result(chars);
  env->ReleaseStringUTFChars(value, chars);
  return result;
}
bool credentials(JNIEnv* env, jlong device, jlong user, jbyteArray key, Credentials& out) {
  if (!key || env->GetArrayLength(key) != 32 || !device) return false;
  out.device = static_cast<uint64_t>(device);
  out.user = static_cast<uint64_t>(user);
  env->GetByteArrayRegion(key, 0, 32, reinterpret_cast<jbyte*>(out.key.data()));
  return !env->ExceptionCheck();
}
void fail(JNIEnv* env, int code) {
  const char* kind = code == 1 || code == 11 ? "java/lang/SecurityException" : "java/lang/IllegalStateException";
  const char* message = code == -2   ? "Connection cancelled"
                        : code == -3 ? "Connection timed out"
                                     : "Steam connection failed";
  jclass type = env->FindClass(kind);
  if (type) {
    env->ThrowNew(type, message);
    env->DeleteLocalRef(type);
  }
}
class JavaSink final : public Sink {
 public:
  explicit JavaSink(JNIEnv* env, jobject value) {
    object_ = env->NewGlobalRef(value);
    jclass cls = env->GetObjectClass(value);
    video_ = env->GetMethodID(cls, "onVideo", "(III[B)Z");
    frame_ = env->GetMethodID(cls, "onFrame", "([BIZ)Z");
    audio_ = env->GetMethodID(cls, "onAudio", "(II)Z");
    samples_ = env->GetMethodID(cls, "onSamples", "([S)V");
    env->DeleteLocalRef(cls);
  }
  ~JavaSink() override {
    Env env;
    if (env.value && object_) env.value->DeleteGlobalRef(object_);
  }
  bool valid() const { return object_ && video_ && frame_ && audio_ && samples_; }
  bool video(int codec, int width, int height, const uint8_t* data, size_t length) override {
    Env env;
    if (!env.value) return false;
    jbyteArray extra = bytes(env.value, data, length);
    if (!extra) return false;
    bool result = env.value->CallBooleanMethod(object_, video_, codec, width, height, extra);
    env.value->DeleteLocalRef(extra);
    return healthy(env.value) && result;
  }
  bool frame(const uint8_t* data, size_t length, uint32_t id, bool key) override {
    Env env;
    if (!env.value) return false;
    jbyteArray buffer = bytes(env.value, data, length);
    if (!buffer) return false;
    bool result =
        env.value->CallBooleanMethod(object_, frame_, buffer, static_cast<jint>(id), static_cast<jboolean>(key));
    env.value->DeleteLocalRef(buffer);
    return healthy(env.value) && result;
  }
  bool audio(int channels, int rate) override {
    Env env;
    if (!env.value) return false;
    bool result = env.value->CallBooleanMethod(object_, audio_, channels, rate);
    return healthy(env.value) && result;
  }
  void samples(const int16_t* pcm, size_t count) override {
    Env env;
    if (!env.value || count > 11520) return;
    jshortArray data = env.value->NewShortArray(static_cast<jsize>(count));
    if (!data) {
      healthy(env.value);
      return;
    }
    env.value->SetShortArrayRegion(data, 0, static_cast<jsize>(count), pcm);
    env.value->CallVoidMethod(object_, samples_, data);
    env.value->DeleteLocalRef(data);
    healthy(env.value);
  }

 private:
  static bool healthy(JNIEnv* env) {
    if (!env->ExceptionCheck()) return true;
    env->ExceptionClear();
    return false;  // Decoder failure is returned to the transport.
  }
  static jbyteArray bytes(JNIEnv* env, const uint8_t* data, size_t length) {
    if (length > 2 * 1024 * 1024 || (length && !data)) return nullptr;
    auto result = env->NewByteArray(static_cast<jsize>(length));
    if (!result) {
      healthy(env);
      return nullptr;
    }
    if (length) env->SetByteArrayRegion(result, 0, static_cast<jsize>(length), reinterpret_cast<const jbyte*>(data));
    return result;
  }
  jobject object_ = nullptr;
  jmethodID video_ = nullptr, frame_ = nullptr, audio_ = nullptr, samples_ = nullptr;
};
}  // namespace
#define JNI(name) Java_org_snapetech_plezyng_games_steam_NativeSteam_##name
extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* machine, void*) {
  vm = machine;
  return JNI_VERSION_1_6;
}
extern "C" JNIEXPORT jlong JNICALL JNI(create)(JNIEnv*, jclass) {
  std::lock_guard<std::mutex> lock(registryMutex);
  jlong id = nextHandle++;
  registry.emplace(id, std::make_shared<Runtime>());
  return id;
}
extern "C" JNIEXPORT void JNICALL JNI(cancel)(JNIEnv*, jclass, jlong id) {
  if (auto r = get(id)) r->cancel();
}
extern "C" JNIEXPORT void JNICALL JNI(destroy)(JNIEnv*, jclass, jlong id) {
  std::shared_ptr<Runtime> owner;
  {
    std::lock_guard<std::mutex> lock(registryMutex);
    auto it = registry.find(id);
    if (it == registry.end()) return;
    owner = it->second;
    registry.erase(it);
  }
  owner->cancel();
}
extern "C" JNIEXPORT jbyteArray JNICALL JNI(pair)(
    JNIEnv* env, jclass, jlong id, jstring address, jint port, jlong hostId, jlong deviceId, jbyteArray key,
    jstring pin) {
  auto runtime = get(id);
  Credentials c{};
  if (!runtime || port < 1 || port > 65535 || !credentials(env, deviceId, 0, key, c)) {
    fail(env, -1);
    return nullptr;
  }
  int result = runtime->pair(
      {string(env, address), static_cast<uint16_t>(port), static_cast<uint64_t>(hostId)}, c, string(env, pin));
  if (result != 0) {
    fail(env, result);
    return nullptr;
  }
  uint8_t data[40]{};
  for (int i = 0; i < 8; ++i) data[i] = static_cast<uint8_t>(c.user >> (8 * i));
  std::memcpy(data + 8, c.key.data(), 32);
  auto output = env->NewByteArray(40);
  if (output) env->SetByteArrayRegion(output, 0, 40, reinterpret_cast<const jbyte*>(data));
  std::fill(c.key.begin(), c.key.end(), 0);
  std::memset(data, 0, sizeof(data));
  return output;
}
extern "C" JNIEXPORT void JNICALL JNI(run)(
    JNIEnv* env, jclass, jlong id, jstring address, jint port, jlong hostId, jlong deviceId, jlong userId,
    jbyteArray key, jlong game, jboolean hevc, jobject target) {
  auto runtime = get(id);
  Credentials c{};
  if (!runtime || !target || port < 1 || port > 65535 || !credentials(env, deviceId, userId, key, c)) {
    fail(env, -1);
    return;
  }
  auto sink = std::make_shared<JavaSink>(env, target);
  if (env->ExceptionCheck() || !sink->valid()) return;
  int result = runtime->run(
      {string(env, address), static_cast<uint16_t>(port), static_cast<uint64_t>(hostId)}, c,
      static_cast<uint64_t>(game), hevc, sink);
  std::fill(c.key.begin(), c.key.end(), 0);
  if (result != 0 && result != -2) fail(env, result);
}
extern "C" JNIEXPORT void JNICALL JNI(pad)(JNIEnv* env, jclass, jlong id, jshortArray axes, jint buttons) {
  auto r = get(id);
  if (!r || !axes || env->GetArrayLength(axes) != 6) return;
  std::array<int16_t, 6> values{};
  env->GetShortArrayRegion(axes, 0, 6, values.data());
  r->pad(values, buttons);
}
extern "C" JNIEXPORT void JNICALL JNI(key)(JNIEnv*, jclass, jlong id, jint usage, jboolean down) {
  if (auto r = get(id)) r->key(usage, down);
}
extern "C" JNIEXPORT void JNICALL
JNI(mouse)(JNIEnv*, jclass, jlong id, jfloat x, jfloat y, jint button, jboolean down) {
  if (auto r = get(id)) r->mouse(x, y, button, down);
}
extern "C" JNIEXPORT void JNICALL JNI(text)(JNIEnv* env, jclass, jlong id, jstring value) {
  if (auto r = get(id)) r->text(string(env, value));
}
extern "C" JNIEXPORT void JNICALL JNI(frameComplete)(JNIEnv*, jclass, jlong id, jint frame, jboolean displayed) {
  if (auto r = get(id)) r->frameComplete(frame, displayed);
}
