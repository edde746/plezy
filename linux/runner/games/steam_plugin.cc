// SPDX-License-Identifier: GPL-3.0-or-later
#include "steam_plugin.h"

#include <libsecret/secret.h>
#include <sys/random.h>

#include <cerrno>
#include <cstring>
#include <functional>
#include <map>
#include <stdexcept>
#include <thread>

#include "steam_gstreamer.h"
#include "steam_input.h"

using namespace plezy::steam;
namespace {
void onMain(std::function<void()> action) {
  auto* value = new std::function<void()>(std::move(action));
  GSource* source = g_idle_source_new();
  g_source_set_callback(
      source,
      [](gpointer p) -> gboolean {
        (*static_cast<std::function<void()>*>(p))();
        return G_SOURCE_REMOVE;
      },
      value, [](gpointer p) { delete static_cast<std::function<void()>*>(p); });
  g_source_attach(source, g_main_context_default());
  g_source_unref(source);
}
FlValue* field(FlValue* map, const char* key) {
  return map && fl_value_get_type(map) == FL_VALUE_TYPE_MAP ? fl_value_lookup_string(map, key) : nullptr;
}
std::string text(FlValue* map, const char* key) {
  auto* value = field(map, key);
  if (!value || fl_value_get_type(value) != FL_VALUE_TYPE_STRING || std::strlen(fl_value_get_string(value)) > 256)
    throw std::invalid_argument("Invalid argument");
  return fl_value_get_string(value);
}
uint64_t identifier(const std::string& value, bool zero = false) {
  if (value.empty() || value.size() > 20 || value.find_first_not_of("0123456789") != std::string::npos)
    throw std::invalid_argument("Invalid identifier");
  auto result = std::stoull(value);
  if (!zero && !result) throw std::invalid_argument("Invalid identifier");
  return result;
}
int number(FlValue* map, const char* key, int fallback, int min, int max) {
  auto* value = field(map, key);
  if (!value) return fallback;
  if (fl_value_get_type(value) != FL_VALUE_TYPE_INT) throw std::invalid_argument("Invalid number");
  auto n = fl_value_get_int(value);
  if (n < min || n > max) throw std::invalid_argument("Invalid limit");
  return int(n);
}
bool boolean(FlValue* map, const char* key, bool fallback = false) {
  auto* value = field(map, key);
  if (!value) return fallback;
  if (fl_value_get_type(value) != FL_VALUE_TYPE_BOOL) throw std::invalid_argument("Invalid boolean");
  return fl_value_get_bool(value);
}
double real(FlValue* map, const char* key) {
  auto* value = field(map, key);
  if (!value || fl_value_get_type(value) != FL_VALUE_TYPE_FLOAT || !std::isfinite(fl_value_get_float(value)))
    throw std::invalid_argument("Invalid coordinate");
  return fl_value_get_float(value);
}
Host hostFrom(FlValue* args) {
  return {text(args, "address"), uint16_t(number(args, "port", 27036, 1, 65535)), identifier(text(args, "hostId"))};
}
Host resolve(Host host, GCancellable* cancel) {
  g_autoptr(GResolver) resolver = g_resolver_get_default();
  GError* error = nullptr;
  GList* addresses = g_resolver_lookup_by_name(resolver, host.address.c_str(), cancel, &error);
  if (error) {
    g_error_free(error);
    throw std::runtime_error("Resolution failed");
  }
  std::string selected;
  for (GList* p = addresses; p; p = p->next) {
    auto* address = G_INET_ADDRESS(p->data);
    if (g_inet_address_get_family(address) != G_SOCKET_FAMILY_IPV4 || g_inet_address_get_is_any(address) ||
        g_inet_address_get_is_multicast(address))
      continue;
    g_autofree gchar* s = g_inet_address_to_string(address);
    if (g_strcmp0(s, "255.255.255.255") != 0) {
      selected = s;
      break;
    }
  }
  g_resolver_free_addresses(addresses);
  if (selected.empty()) throw std::runtime_error("No usable address");
  host.address = selected;
  return host;
}
void ok(FlMethodCall* call, FlValue* value = nullptr) { fl_method_call_respond_success(call, value, nullptr); }
void error(FlMethodCall* call, const char* code = "UNAVAILABLE") {
  fl_method_call_respond_error(call, code, "Steam connection unavailable", nullptr, nullptr);
}
void put(FlValue* map, const char* key, uint64_t value) {
  fl_value_set_string_take(map, key, fl_value_new_int(static_cast<int64_t>(value)));
}

const SecretSchema schema = {
    "org.snapetech.plezyng.Steam",
    SECRET_SCHEMA_NONE,
    {{"host", SECRET_SCHEMA_ATTRIBUTE_STRING}, {nullptr, SECRET_SCHEMA_ATTRIBUTE_STRING}},
    0,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr};
void randomBytes(uint8_t* target, size_t length) {
  while (length) {
    auto n = getrandom(target, length, 0);
    if (n < 0 && errno == EINTR) continue;
    if (n <= 0) throw std::runtime_error("No entropy");
    target += n;
    length -= size_t(n);
  }
}
void loadTrust(uint64_t id, Credentials& out, GCancellable* cancel) {
  auto key = std::to_string(id);
  GError* failure = nullptr;
  gchar* saved = secret_password_lookup_sync(&schema, cancel, &failure, "host", key.c_str(), nullptr);
  if (failure) {
    g_error_free(failure);
    throw std::runtime_error("Credential store unavailable");
  }
  if (!saved) throw std::runtime_error("Pairing required");
  std::array<uint8_t, 48> record{};
  bool valid = std::strlen(saved) == record.size() * 2;
  auto digit = [](char c) { return c >= '0' && c <= '9' ? c - '0' : c >= 'a' && c <= 'f' ? c - 'a' + 10 : -1; };
  for (size_t i = 0; valid && i < record.size(); ++i) {
    int a = digit(saved[i * 2]), b = digit(saved[i * 2 + 1]);
    if (a < 0 || b < 0)
      valid = false;
    else
      record[i] = uint8_t(a * 16 + b);
  }
  secret_password_free(saved);
  if (valid) {
    out.device = out.user = 0;
    for (int i = 0; i < 8; ++i) {
      out.device |= uint64_t(record[i]) << (8 * i);
      out.user |= uint64_t(record[8 + i]) << (8 * i);
    }
    std::copy_n(record.data() + 16, 32, out.key.data());
  }
  volatile uint8_t* wipe = record.data();
  for (size_t i = 0; i < record.size(); ++i) wipe[i] = 0;
  if (!valid || !out.device || !out.user) throw std::runtime_error("Pairing required");
}
bool saveTrust(uint64_t id, const Credentials& c, GCancellable* cancel) {
  std::array<char, 97> encoded{};
  const char* hex = "0123456789abcdef";
  for (size_t i = 0; i < 48; ++i) {
    uint8_t byte = i < 8 ? uint8_t(c.device >> (8 * i)) : i < 16 ? uint8_t(c.user >> (8 * (i - 8))) : c.key[i - 16];
    encoded[i * 2] = hex[byte >> 4];
    encoded[i * 2 + 1] = hex[byte & 15];
  }
  GError* failure = nullptr;
  const auto key = std::to_string(id);
  bool saved = secret_password_store_sync(
      &schema, SECRET_COLLECTION_DEFAULT, "PlezyNG Steam pairing", encoded.data(), cancel, &failure, "host",
      key.c_str(), nullptr);
  volatile char* wipe = encoded.data();
  for (size_t i = 0; i < encoded.size(); ++i) wipe[i] = 0;
  if (failure) g_error_free(failure);
  return saved;
}
bool forgetTrust(uint64_t id, GCancellable* cancel) {
  GError* failure = nullptr;
  const auto key = std::to_string(id);
  secret_password_clear_sync(&schema, cancel, &failure, "host", key.c_str(), nullptr);
  if (failure) {
    g_error_free(failure);
    return false;
  }
  return true;
}

struct PendingPixels {
  DecodedPixels pixels;
  std::function<void(bool)> complete;
};
struct PixelsData {
  std::mutex mutex;
  std::unique_ptr<PendingPixels> pending;
  // Flutter owns the read buffer until the texture is unregistered. Network
  // and decoder threads never mutate it; only copy_pixels does.
  std::vector<uint8_t> output = std::vector<uint8_t>(1920 * 1080 * 4);
  uint32_t width = 1, height = 1;
  ~PixelsData() {
    if (pending) pending->complete(false);
  }
};
}  // namespace

typedef struct _SteamPixels {
  FlPixelBufferTexture parent;
  PixelsData* data;
} SteamPixels;
typedef struct _SteamPixelsClass {
  FlPixelBufferTextureClass parent;
} SteamPixelsClass;
G_DEFINE_TYPE(SteamPixels, steam_pixels, fl_pixel_buffer_texture_get_type())
static gboolean steam_pixels_copy(
    FlPixelBufferTexture* texture, const uint8_t** bytes, uint32_t* width, uint32_t* height, GError**) {
  auto* data = reinterpret_cast<SteamPixels*>(texture)->data;
  std::unique_ptr<PendingPixels> pending;
  {
    std::lock_guard<std::mutex> lock(data->mutex);
    pending = std::move(data->pending);
  }
  if (pending) {
    data->width = pending->pixels.width;
    data->height = pending->pixels.height;
    std::copy(pending->pixels.rgba.begin(), pending->pixels.rgba.end(), data->output.begin());
  }
  *bytes = data->output.data();
  *width = data->width;
  *height = data->height;
  if (pending) pending->complete(true);
  return TRUE;
}
static void steam_pixels_finalize(GObject* object) {
  delete reinterpret_cast<SteamPixels*>(object)->data;
  G_OBJECT_CLASS(steam_pixels_parent_class)->finalize(object);
}
static void steam_pixels_class_init(SteamPixelsClass* cls) {
  G_OBJECT_CLASS(cls)->finalize = steam_pixels_finalize;
  FL_PIXEL_BUFFER_TEXTURE_CLASS(cls)->copy_pixels = steam_pixels_copy;
}
static void steam_pixels_init(SteamPixels* texture) { texture->data = new PixelsData(); }

namespace {
struct Manager;
struct Session : std::enable_shared_from_this<Session> {
  std::weak_ptr<Manager> owner;
  uint64_t id;
  Host host;
  uint64_t game;
  StreamOptions options;
  bool hevc, audible = false;
  InputState input;
  FlBinaryMessenger* messenger;
  FlTextureRegistrar* registrar;
  SteamPixels* texture;
  FlMethodChannel* channel;
  GCancellable* cancellable = g_cancellable_new();
  std::thread worker;
  std::mutex mutex;
  std::shared_ptr<Runtime> runtime;
  std::shared_ptr<GStreamerSink> sink;
  std::atomic<bool> closing{false}, notifyPending{false}, active{false};
  std::atomic<uint64_t> renderedEpoch{0}, renderedSize{0};
  std::vector<FlMethodCall*> stopReplies;  // UI thread only.
  std::string state = "connecting";
  std::string channelName;
  Session(uint64_t id, Host h, uint64_t game, StreamOptions o, bool hevc, FlPluginRegistrar* plugin)
      : id(id),
        host(std::move(h)),
        game(game),
        options(o),
        hevc(hevc),
        input(o.controllerCount),
        messenger(FL_BINARY_MESSENGER(g_object_ref(fl_plugin_registrar_get_messenger(plugin)))),
        registrar(FL_TEXTURE_REGISTRAR(g_object_ref(fl_plugin_registrar_get_texture_registrar(plugin)))),
        texture(reinterpret_cast<SteamPixels*>(g_object_new(steam_pixels_get_type(), nullptr))),
        channel(nullptr) {
    channelName = "com.plezy/games/steam_stream/" + std::to_string(id);
    g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
    channel = fl_method_channel_new(messenger, channelName.c_str(), FL_METHOD_CODEC(codec));
  }
  ~Session() {
    if (worker.joinable()) worker.join();
    g_object_unref(cancellable);
    g_object_unref(channel);
    g_object_unref(texture);
    g_object_unref(registrar);
    g_object_unref(messenger);
  }
  void setState(const char* value) {
    if (closing || state == value) return;
    state = value;
    g_autoptr(FlValue) arg = fl_value_new_string(value);
    fl_method_channel_invoke_method(channel, "sessionState", arg, nullptr, nullptr, nullptr);
  }
  void notifyState(const char* state) {
    auto weak = weak_from_this();
    onMain([weak, state] {
      if (auto self = weak.lock()) self->setState(state);
    });
  }
  bool pixels(DecodedPixels&& pixels, std::weak_ptr<Runtime> source) {
    if (closing) return false;
    const auto frame = pixels.id;
    const auto frameWidth = pixels.width, frameHeight = pixels.height;
    auto pending = std::make_unique<PendingPixels>(PendingPixels{
        std::move(pixels),
        [weak = weak_from_this(), source, frame, width = frameWidth, height = frameHeight](bool shown) {
          if (auto r = source.lock()) {
            r->frameComplete(frame, shown);
            if (shown)
              if (auto self = weak.lock()) {
                const uint64_t epoch = r->metrics().epoch;
                const bool first = self->renderedEpoch.exchange(epoch) != epoch;
                const bool resized =
                    self->renderedSize.exchange((uint64_t(width) << 32) | height) != ((uint64_t(width) << 32) | height);
                if (first || resized)
                  onMain([weak, source, width, height] {
                    if (auto s = weak.lock()) {
                      {
                        std::lock_guard<std::mutex> lock(s->mutex);
                        if (!s->active || s->runtime != source.lock()) return;
                      }
                      g_autoptr(FlValue) size = fl_value_new_map();
                      put(size, "width", width);
                      put(size, "height", height);
                      fl_method_channel_invoke_method(s->channel, "videoSize", size, nullptr, nullptr, nullptr);
                      s->setState("playing");
                    }
                  });
              }
          }
        }});
    std::unique_ptr<PendingPixels> old;
    {
      std::lock_guard<std::mutex> lock(texture->data->mutex);
      old = std::move(texture->data->pending);
      texture->data->pending = std::move(pending);
    }
    if (old) old->complete(false);
    if (!notifyPending.exchange(true)) {
      auto weak = weak_from_this();
      onMain([weak] {
        if (auto self = weak.lock()) {
          self->notifyPending = false;
          if (!self->closing)
            fl_texture_registrar_mark_texture_frame_available(self->registrar, FL_TEXTURE(self->texture));
        }
      });
    }
    return true;
  }
  void start();
  void close(FlMethodCall* reply = nullptr);
  void method(FlMethodCall* call);
};
struct Manager : std::enable_shared_from_this<Manager> {
  FlPluginRegistrar* registrar;
  std::map<uint64_t, std::shared_ptr<Session>> sessions;  // Main thread.
  uint64_t next = 1;
  std::atomic<bool> closed{false};
  bool busy = false;
  std::mutex mutex;
  std::shared_ptr<Runtime> operation;
  GCancellable* cancel = g_cancellable_new();
  explicit Manager(FlPluginRegistrar* r) : registrar(FL_PLUGIN_REGISTRAR(g_object_ref(r))) {}
  ~Manager() {
    g_object_unref(cancel);
    g_object_unref(registrar);
  }
  void shutdown() {
    closed = true;
    g_cancellable_cancel(cancel);
    {
      std::lock_guard<std::mutex> lock(mutex);
      if (operation) operation->cancel();
    }
    auto active = sessions;
    for (auto& entry : active) entry.second->close();
  }
  void method(FlMethodCall* call, bool receiver);
};

void Session::start() {
  const auto weak = weak_from_this();
  worker = std::thread([this, weak] {
    try {
      Credentials credentials;
      loadTrust(host.id, credentials, cancellable);
      auto target = resolve(host, cancellable);
      int channels = options.audioChannels;
      bool allowHevc = hevc;
      for (int attempt = 0; attempt < 3 && !closing; ++attempt) {
        active = false;
        auto current = std::make_shared<Runtime>();
        std::atomic<bool> audioFailed{false}, videoFailed{false};
        auto decoder = std::make_shared<GStreamerSink>(
            [weak, source = std::weak_ptr<Runtime>(current)](DecodedPixels&& pixels) {
              auto self = weak.lock();
              return self && self->pixels(std::move(pixels), source);
            },
            [source = std::weak_ptr<Runtime>(current)](uint32_t frame, bool shown) {
              if (auto r = source.lock()) r->frameComplete(frame, shown);
            },
            [source = std::weak_ptr<Runtime>(current), &audioFailed, &videoFailed](bool audio) {
              if (audio)
                audioFailed = true;
              else
                videoFailed = true;
              if (auto r = source.lock()) r->cancel();
            });
        {
          std::lock_guard<std::mutex> lock(mutex);
          runtime = current;
          sink = decoder;
          active = true;
          input.reset(*current);
          decoder->volume(audible);
          if (closing) current->cancel();
        }
        auto request = options;
        request.audioChannels = channels;
        int result = current->run(target, credentials, game, allowHevc, false, decoder, request);
        active = false;
        decoder->close();
        // No callback may retain references to these attempt-local flags.
        {
          std::lock_guard<std::mutex> lock(mutex);
          sink.reset();
        }
        if (closing) break;
        const bool dropSurround = audioFailed && channels > 2;
        const bool dropHevc = (videoFailed || result == -4) && allowHevc && current->metrics().codec == 5;
        if (dropSurround || dropHevc) {
          if (dropSurround) channels = 2;
          if (dropHevc) allowHevc = false;
          notifyState("reconnecting");
          continue;
        }
        notifyState(result == 0 && !audioFailed && !videoFailed ? "disconnected" : "failed");
        break;
      }
    } catch (...) {
      if (!closing) notifyState("failed");
    }
  });
}
void Session::close(FlMethodCall* reply) {
  if (reply) stopReplies.push_back(FL_METHOD_CALL(g_object_ref(reply)));
  if (closing.exchange(true)) return;
  active = false;
  g_cancellable_cancel(cancellable);
  {
    std::lock_guard<std::mutex> lock(mutex);
    if (runtime) {
      input.enabled(*runtime, false);
      runtime->cancel();
    }
  }
  auto self = shared_from_this();
  std::thread([self] {
    if (self->worker.joinable()) self->worker.join();
    onMain([self] {
      // Acknowledgement follows transport AND decoder termination.
      fl_texture_registrar_unregister_texture(self->registrar, FL_TEXTURE(self->texture));
      fl_binary_messenger_set_message_handler_on_channel(
          self->messenger, self->channelName.c_str(), nullptr, nullptr, nullptr);
      if (auto manager = self->owner.lock()) manager->sessions.erase(self->id);
      for (auto* reply : self->stopReplies) {
        ok(reply);
        g_object_unref(reply);
      }
      self->stopReplies.clear();
    });
  }).detach();
}
void Session::method(FlMethodCall* call) {
  const std::string method = fl_method_call_get_name(call);
  auto* args = fl_method_call_get_args(call);
  if (method == "disconnect") {
    close(call);
    return;
  }
  if (method == "getSessionState") {
    g_autoptr(FlValue) value = fl_value_new_string(state.c_str());
    ok(call, value);
    return;
  }
  if (closing) {
    error(call);
    return;
  }
  std::lock_guard<std::mutex> lock(mutex);
  if (method == "setAudioEnabled") {
    audible = boolean(args, "enabled");
    if (sink) sink->volume(audible);
  } else if (method == "setInputEnabled") {
    if (runtime) input.enabled(*runtime, boolean(args, "enabled") && state == "playing");
  } else if (method == "resetInput") {
    if (runtime) input.reset(*runtime);
  } else if (method == "releaseTouchControls") {
    if (runtime) input.releaseAssistance(*runtime);
  } else if (method == "inputKey") {
    if (runtime && active && runtime->metrics().epoch == renderedEpoch) {
      if (field(args, "usage"))
        input.hidKey(*runtime, number(args, "usage", 0, 4, 231), boolean(args, "down"));
      else
        input.key(*runtime, text(args, "key"), boolean(args, "down"));
    }
  } else if (method == "inputMouse" || method == "inputWheel" || method == "releasePointer") {
    if (runtime && active && runtime->metrics().epoch == renderedEpoch) {
      if (method == "releasePointer")
        input.releasePointer(*runtime);
      else if (method == "inputWheel")
        input.wheel(*runtime, number(args, "direction", 0, 1, 4));
      else
        input.mouse(
            *runtime, real(args, "x"), real(args, "y"), number(args, "button", 0, 0, 16), boolean(args, "down"));
    }
  } else if (
      method == "disconnectController" || method == "setControllerDeviceState" || method == "setTouchControllerState") {
    const bool assistance = method == "setTouchControllerState";
    auto* device = field(args, "deviceId");
    if (!assistance && (!device || fl_value_get_type(device) != FL_VALUE_TYPE_INT))
      throw std::invalid_argument("Invalid device");
    if (runtime && active && runtime->metrics().epoch == renderedEpoch) {
      auto id = assistance ? 0 : fl_value_get_int(device);
      if (method == "disconnectController")
        input.disconnect(*runtime, id);
      else {
        for (const char* group : {"buttons", "axes"}) {
          auto* values = field(args, group);
          if (!values) continue;
          if (fl_value_get_type(values) != FL_VALUE_TYPE_MAP || fl_value_get_length(values) > 32)
            throw std::invalid_argument("Invalid controller state");
          for (size_t i = 0; i < fl_value_get_length(values); ++i) {
            auto* k = fl_value_get_map_key(values, i);
            auto* v = fl_value_get_map_value(values, i);
            if (fl_value_get_type(k) != FL_VALUE_TYPE_STRING) continue;
            if (std::strcmp(group, "buttons") == 0 && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
              input.button(*runtime, id, fl_value_get_string(k), fl_value_get_bool(v), assistance);
            else if (fl_value_get_type(v) == FL_VALUE_TYPE_FLOAT)
              input.axis(*runtime, id, fl_value_get_string(k), fl_value_get_float(v), assistance);
            else if (fl_value_get_type(v) == FL_VALUE_TYPE_INT)
              input.axis(*runtime, id, fl_value_get_string(k), double(fl_value_get_int(v)), assistance);
          }
        }
      }
    }
  } else if (method == "getStreamMetrics") {
    if (!runtime) {
      ok(call);
      return;
    }
    const auto m = runtime->metrics();
    g_autoptr(FlValue) v = fl_value_new_map();
    put(v, "version", 1);
    put(v, "epoch", m.epoch);
    put(v, "sampledAtUs", m.sampledAtUs);
    put(v, "receivedFrames", m.receivedFrames);
    put(v, "presentedFrames", m.presentedFrames);
    put(v, "droppedFrames", m.droppedFrames);
    put(v, "resetFrames", m.resetFrames);
    put(v, "videoBytes", m.videoBytes);
    put(v, "completionTotalUs", m.completionTotalUs);
    put(v, "completedFrames", m.completedFrames);
    put(v, "width", m.width);
    put(v, "height", m.height);
    put(v, "codec", m.codec);
    put(v, "audioChannels", m.audioChannels);
    put(v, "fpsNumerator", m.fpsNumerator);
    put(v, "fpsDenominator", m.fpsDenominator);
    put(v, "fpsReasons", m.fpsReasons);
    put(v, "targetBitrate", m.targetBitrate);
    put(v, "reliableRetries", m.reliability.reliableRetries);
    put(v, "reliableGiveUps", m.reliability.reliableGiveUps);
    put(v, "reliableOutstanding", m.reliability.reliableOutstanding);
    put(v, "maxAckLatencyMs", m.reliability.reliableMaxAckLatencyMs);
    put(v, "hidPending", m.reliability.hidPending);
    put(v, "hidInFlight", m.reliability.hidInFlight);
    put(v, "decoderKind", 2);
    ok(call, v);
    return;
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  ok(call);
}

void Manager::method(FlMethodCall* call, bool receiver) {
  if (closed) {
    error(call);
    return;
  }
  const std::string name = fl_method_call_get_name(call);
  auto* args = fl_method_call_get_args(call);
  if (name == "cancel" && !receiver) {
    g_cancellable_cancel(cancel);
    {
      std::lock_guard<std::mutex> lock(mutex);
      if (operation) operation->cancel();
    }
    ok(call);
    return;
  }
  if (!args || fl_value_get_type(args) != FL_VALUE_TYPE_MAP || fl_value_get_length(args) > 64)
    throw std::invalid_argument("Invalid arguments");
  if (!receiver && name == "capabilities") {
    const bool available = text(args, "protocol") == "steam" && GStreamerSink::supported();
    g_autoptr(FlValue) result = fl_value_new_map();
    for (const char* key : {"available", "inlinePairing", "library", "embeddedSurface"})
      fl_value_set_string_take(result, key, fl_value_new_bool(available));
    ok(call, result);
    return;
  }
  if (receiver && name == "create") {
    if (sessions.size() >= 8 || !GStreamerSink::supported()) {
      error(call);
      return;
    }
    auto host = hostFrom(args);
    auto game = identifier(text(args, "appId"), true);
    StreamOptions options;
    options.width = number(args, "streamWidth", 1920, 640, 1920);
    options.height = number(args, "streamHeight", 1080, 360, 1080);
    options.fps = number(args, "streamFps", 60, 15, 60);
    options.bitrateKbps = number(args, "streamBitrateKbps", 30000, 1000, 50000);
    options.controllerCount = number(args, "controllerCount", 1, 1, 4);
    options.audioChannels = number(args, "audioChannels", 2, 2, 6);
    if (!options.valid()) throw std::invalid_argument("Invalid options");
    auto session = std::make_shared<Session>(
        next++, host, game, options, boolean(args, "allowHevc", true) && GStreamerSink::supported(true), registrar);
    session->owner = shared_from_this();
    if (!fl_texture_registrar_register_texture(session->registrar, FL_TEXTURE(session->texture))) {
      fl_binary_messenger_set_message_handler_on_channel(
          session->messenger, session->channelName.c_str(), nullptr, nullptr, nullptr);
      error(call);
      return;
    }
    sessions.emplace(session->id, session);
    auto* weak = new std::weak_ptr<Session>(session);
    fl_method_channel_set_method_call_handler(
        session->channel,
        [](FlMethodChannel*, FlMethodCall* call, gpointer data) {
          try {
            if (auto session = static_cast<std::weak_ptr<Session>*>(data)->lock())
              session->method(call);
            else
              error(call);
          } catch (...) {
            error(call, "INVALID_ARGUMENT");
          }
        },
        weak, [](gpointer data) { delete static_cast<std::weak_ptr<Session>*>(data); });
    g_autoptr(FlValue) result = fl_value_new_map();
    put(result, "id", session->id);
    put(result, "textureId", fl_texture_get_id(FL_TEXTURE(session->texture)));
    session->start();
    ok(call, result);
    return;
  }
  if (receiver || text(args, "protocol") != "steam" || (name != "pair" && name != "games" && name != "forget")) {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  if (busy) {
    error(call, "BUSY");
    return;
  }
  auto host = hostFrom(args);
  const std::string pin = name == "pair" ? text(args, "pin") : "";
  if (name == "pair" && (pin.size() != 4 || pin.find_first_not_of("0123456789") != std::string::npos))
    throw std::invalid_argument("Invalid PIN");
  if (name == "forget") {
    auto active = sessions;
    for (auto& entry : active)
      if (entry.second->host.id == host.id) entry.second->close();
  }
  busy = true;
  g_cancellable_reset(cancel);
  auto r = std::make_shared<Runtime>();
  {
    std::lock_guard<std::mutex> lock(mutex);
    operation = r;
  }
  auto self = shared_from_this();
  g_object_ref(call);
  std::thread([self, r, call, host, pin, name] {
    bool success = false, pairingRequired = false;
    try {
      Credentials credentials;
      if (name == "forget")
        success = forgetTrust(host.id, self->cancel);
      else if (name == "games") {
        loadTrust(host.id, credentials, self->cancel);
        success = true;
      } else {
        randomBytes(reinterpret_cast<uint8_t*>(&credentials.device), sizeof(credentials.device));
        randomBytes(credentials.key.data(), credentials.key.size());
        success = r->pair(resolve(host, self->cancel), credentials, pin) == 0;
        if (success && !g_cancellable_is_cancelled(self->cancel) && !self->closed)
          success = saveTrust(host.id, credentials, self->cancel);
        else
          success = false;
        // The keyring service can commit just before acknowledging cancellation.
        // Retire only this attempt's record, never an older pairing or one from
        // another window. Pairing operations on this manager are serialized.
        if (g_cancellable_is_cancelled(self->cancel) || self->closed) {
          success = false;
          try {
            Credentials stored;
            loadTrust(host.id, stored, nullptr);
            if (stored.device == credentials.device) forgetTrust(host.id, nullptr);
          } catch (...) {
          }
        }
      }
    } catch (...) {
      pairingRequired = name == "games";
    }
    onMain([self, r, call, success, pairingRequired, name] {
      self->busy = false;
      {
        std::lock_guard<std::mutex> lock(self->mutex);
        if (self->operation == r) self->operation.reset();
      }
      if (self->closed || g_cancellable_is_cancelled(self->cancel))
        error(call, "CANCELLED");
      else if (!success)
        error(call, pairingRequired ? "PAIRING_REQUIRED" : "UNAVAILABLE");
      else {
        g_autoptr(FlValue) value = name == "games" ? fl_value_new_list() : fl_value_new_bool(true);
        ok(call, value);
      }
      g_object_unref(call);
    });
  }).detach();
}
}  // namespace

void steam_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  auto manager = std::make_shared<Manager>(registrar);
  // Window destruction retires the manager before any pending worker callback.
  g_object_set_data_full(
      G_OBJECT(fl_plugin_registrar_get_view(registrar)), "plezy-steam", new std::shared_ptr<Manager>(manager),
      [](gpointer data) {
        auto* holder = static_cast<std::shared_ptr<Manager>*>(data);
        (*holder)->shutdown();
        delete holder;
      });
  for (bool receiver : {false, true}) {
    g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
    g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
        fl_plugin_registrar_get_messenger(registrar), receiver ? "com.plezy/games/steam_receiver" : "com.plezy/games",
        FL_METHOD_CODEC(codec));
    using Target = std::pair<std::weak_ptr<Manager>, bool>;
    fl_method_channel_set_method_call_handler(
        channel,
        [](FlMethodChannel*, FlMethodCall* call, gpointer data) {
          auto* target = static_cast<Target*>(data);
          try {
            if (auto m = target->first.lock())
              m->method(call, target->second);
            else
              error(call);
          } catch (...) {
            error(call, "INVALID_ARGUMENT");
          }
        },
        new Target(manager, receiver), [](gpointer data) { delete static_cast<Target*>(data); });
  }
}
