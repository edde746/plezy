// SPDX-License-Identifier: GPL-3.0-or-later
#import "PlezySteamPlugin.h"
#import <AVFoundation/AVFoundation.h>
#import <Network/Network.h>
#import <Security/Security.h>
#include <arpa/inet.h>
#include <cstring>
#include <map>
#include <stdexcept>
#include <thread>
#include "SteamAppleSink.h"
#include "steam_input.h"

using namespace plezy::steam;
namespace {
void mainQueue(std::function<void()> action) {
  dispatch_async(dispatch_get_main_queue(), ^{
    action();
  });
}
FlutterError* unavailable(NSString* code = @"UNAVAILABLE") {
  return [FlutterError errorWithCode:code message:@"Steam connection unavailable" details:nil];
}
NSDictionary* arguments(id value) {
  if (![value isKindOfClass:NSDictionary.class] || [value count] > 64) throw std::invalid_argument("Invalid arguments");
  return value;
}
std::string stringValue(id value) {
  if (![value isKindOfClass:NSString.class] || [value length] > 256) throw std::invalid_argument("Invalid string");
  const char* bytes = [value UTF8String];
  if (!bytes || std::strlen(bytes) != [value lengthOfBytesUsingEncoding:NSUTF8StringEncoding])
    throw std::invalid_argument("Invalid string");
  return bytes;
}
uint64_t identifier(id value, bool zero = false) {
  auto s = stringValue(value);
  if (s.empty() || s.size() > 20 || s.find_first_not_of("0123456789") != std::string::npos)
    throw std::invalid_argument("Invalid identifier");
  auto id = std::stoull(s);
  if (!id && !zero) throw std::invalid_argument("Invalid identifier");
  return id;
}
bool isNumber(id value) {
  return [value isKindOfClass:NSNumber.class] && CFGetTypeID((__bridge CFTypeRef)value) != CFBooleanGetTypeID();
}
int64_t integer(id value) {
  if (!isNumber(value) || std::strchr("fd", [value objCType][0])) throw std::invalid_argument("Invalid integer");
  return [value longLongValue];
}
int number(NSDictionary* args, NSString* key, int fallback, int min, int max) {
  if (!args[key]) return fallback;
  auto value = integer(args[key]);
  if (value < min || value > max) throw std::invalid_argument("Invalid limit");
  return int(value);
}
bool boolean(NSDictionary* args, NSString* key, bool fallback = false) {
  id value = args[key];
  if (!value) return fallback;
  if (CFGetTypeID((__bridge CFTypeRef)value) != CFBooleanGetTypeID()) throw std::invalid_argument("Invalid boolean");
  return [value boolValue];
}
Host hostFrom(NSDictionary* args) {
  return {stringValue(args[@"address"]), uint16_t(number(args, @"port", 27036, 1, 65535)), identifier(args[@"hostId"])};
}
bool usable(const sockaddr* address) {
  if (!address || address->sa_family != AF_INET) return false;
  uint32_t ip = ntohl(reinterpret_cast<const sockaddr_in*>(address)->sin_addr.s_addr);
  return ip != 0 && ip != 0xffffffffu && (ip & 0xf0000000u) != 0xe0000000u;
}
Host resolveHost(Host host, const std::atomic<bool>& cancelled) {
  struct Resolution {
    std::mutex mutex;
    std::condition_variable changed;
    bool done = false;
    std::string address;
  };
  auto state = std::make_shared<Resolution>();
  auto endpoint = nw_endpoint_create_host(host.address.c_str(), std::to_string(host.port).c_str());
  auto parameters =
      nw_parameters_create_secure_udp(NW_PARAMETERS_DISABLE_PROTOCOL, NW_PARAMETERS_DEFAULT_CONFIGURATION);
  auto stack = nw_parameters_copy_default_protocol_stack(parameters);
  auto ip = nw_protocol_stack_copy_internet_protocol(stack);
  nw_ip_options_set_version(ip, nw_ip_version_4);
  auto connection = nw_connection_create(endpoint, parameters);
  if (!connection) throw std::runtime_error("Resolution failed");
  nw_connection_set_queue(connection, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0));
  nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t status, nw_error_t) {
    if (status != nw_connection_state_ready && status != nw_connection_state_failed &&
        status != nw_connection_state_cancelled)
      return;
    std::string selected;
    if (status == nw_connection_state_ready) {
      auto path = nw_connection_copy_current_path(connection);
      auto remote = path ? nw_path_copy_effective_remote_endpoint(path) : nullptr;
      const auto* address = remote ? nw_endpoint_get_address(remote) : nullptr;
      if (usable(address)) {
        char text[INET_ADDRSTRLEN]{};
        if (inet_ntop(AF_INET, &reinterpret_cast<const sockaddr_in*>(address)->sin_addr, text, sizeof(text)))
          selected = text;
      }
    }
    {
      std::lock_guard<std::mutex> lock(state->mutex);
      state->address = selected;
      state->done = true;
    }
    state->changed.notify_one();
  });
  nw_connection_start(connection);
  {
    std::unique_lock<std::mutex> lock(state->mutex);
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(10);
    while (!state->done && !cancelled && std::chrono::steady_clock::now() < deadline)
      state->changed.wait_for(lock, std::chrono::milliseconds(50));
    host.address = state->address;
  }
  nw_connection_set_state_changed_handler(connection, nil);  // Break the temporary connection/block cycle.
  nw_connection_cancel(connection);
  if (cancelled || host.address.empty()) throw std::runtime_error("Resolution cancelled or unavailable");
  return host;
}
NSMutableDictionary* trustQuery(uint64_t host) {
  return [@{
    (__bridge NSString*)kSecClass : (__bridge id)kSecClassGenericPassword,
    (__bridge NSString*)kSecAttrService : @"org.snapetech.plezyng.Steam",
    (__bridge NSString*)kSecAttrAccount : [NSString stringWithFormat:@"%llu", (unsigned long long)host]
  } mutableCopy];
}
bool loadTrust(uint64_t host, Credentials& out) {
  auto query = trustQuery(host);
  query[(__bridge NSString*)kSecReturnData] = @YES;
  query[(__bridge NSString*)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
  CFTypeRef result = nullptr;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
  bool valid = status == errSecSuccess && result && CFGetTypeID(result) == CFDataGetTypeID() &&
               CFDataGetLength((CFDataRef)result) == 48;
  if (valid) {
    const UInt8* b = CFDataGetBytePtr((CFDataRef)result);
    out.device = out.user = 0;
    for (int i = 0; i < 8; ++i) {
      out.device |= uint64_t(b[i]) << (i * 8);
      out.user |= uint64_t(b[8 + i]) << (i * 8);
    }
    std::copy_n(b + 16, 32, out.key.data());
  }
  if (result) CFRelease(result);
  return valid && out.device && out.user;
}
bool saveTrust(uint64_t host, const Credentials& c) {
  std::array<uint8_t, 48> record{};
  for (int i = 0; i < 8; ++i) {
    record[i] = uint8_t(c.device >> (i * 8));
    record[8 + i] = uint8_t(c.user >> (i * 8));
  }
  std::copy(c.key.begin(), c.key.end(), record.begin() + 16);
  auto query = trustQuery(host);
  NSData* data = [NSData dataWithBytesNoCopy:record.data() length:record.size() freeWhenDone:NO];
  NSDictionary* update = @{
    (__bridge NSString*)kSecValueData : data,
    (__bridge NSString*)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
  };
  OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)update);
  if (status == errSecItemNotFound) {
    [query addEntriesFromDictionary:update];
    status = SecItemAdd((__bridge CFDictionaryRef)query, nullptr);
  }
  volatile uint8_t* wipe = record.data();
  for (size_t i = 0; i < record.size(); ++i) wipe[i] = 0;
  return status == errSecSuccess;
}
bool forgetTrust(uint64_t host) {
  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)trustQuery(host));
  return status == errSecSuccess || status == errSecItemNotFound;
}
}  // namespace

@interface PlezySteamTexture : NSObject <FlutterTexture> {
 @public
  std::mutex mutex;
  CVPixelBufferRef current;
  std::function<void(bool)> completion;
}
- (void)install:(CVPixelBufferRef)pixel completion:(std::function<void(bool)>)done;
- (void)retire;
@end
@implementation PlezySteamTexture
- (void)install:(CVPixelBufferRef)pixel completion:(std::function<void(bool)>)done {
  std::function<void(bool)> previous;
  {
    std::lock_guard<std::mutex> lock(mutex);
    if (current) CVPixelBufferRelease(current);
    current = CVPixelBufferRetain(pixel);
    previous = std::move(completion);
    completion = std::move(done);
  }
  if (previous) previous(false);
}
- (CVPixelBufferRef)copyPixelBuffer {
  CVPixelBufferRef result = nullptr;
  std::function<void(bool)> done;
  {
    std::lock_guard<std::mutex> lock(mutex);
    if (current) result = CVPixelBufferRetain(current);
    done = std::move(completion);
  }
  if (done) done(result != nullptr);
  return result;
}
- (void)retire {
  std::function<void(bool)> done;
  {
    std::lock_guard<std::mutex> lock(mutex);
    if (current) CVPixelBufferRelease(current);
    current = nullptr;
    done = std::move(completion);
  }
  if (done) done(false);
}
- (void)dealloc {
  [self retire];
}
@end

namespace {
struct Manager;
struct Session : std::enable_shared_from_this<Session> {
  std::weak_ptr<Manager> owner;
  Host host;
  uint64_t game;
  StreamOptions options;
  bool hevc, pyrowave, audible = false;
  InputState input;
  int64_t sessionId, textureId;
  __weak id<FlutterTextureRegistry> registry;
  PlezySteamTexture* texture;
  FlutterMethodChannel* channel;
  std::thread worker;
  std::mutex mutex;
  std::shared_ptr<Runtime> runtime;
  std::shared_ptr<AppleSink> sink;
  std::atomic<bool> closing{false}, active{false}, notifyPending{false};
  std::atomic<uint64_t> renderedEpoch{0}, renderedSize{0};
  NSString* state = @"connecting";
  NSMutableArray* stopReplies = [NSMutableArray new];
  Session(
      int64_t value, Host h, uint64_t game, StreamOptions o, bool hevc, bool pyrowave,
      id<FlutterPluginRegistrar> registrar)
      : host(std::move(h)),
        game(game),
        options(o),
        hevc(hevc),
        pyrowave(pyrowave),
        input(o.controllerCount),
        sessionId(value),
        registry([registrar textures]),
        texture([PlezySteamTexture new]) {
    textureId = [registry registerTexture:texture];
    // iOS assigns texture zero to the first registration. macOS instead uses
    // an object address for the ID and returns zero on registration failure.
    if (!registry || textureId < 0
#if TARGET_OS_OSX
        || textureId == 0
#endif
    )
      throw std::runtime_error("Texture registration failed");
    channel = [FlutterMethodChannel
        methodChannelWithName:[NSString stringWithFormat:@"com.plezy/games/steam_stream/%lld", (long long)sessionId]
              binaryMessenger:[registrar messenger]];
  }
  ~Session() {
    if (worker.joinable()) worker.join();
  }
  void setState(NSString* next) {
    if (closing || [state isEqualToString:next]) return;
    state = next;
    [channel invokeMethod:@"sessionState" arguments:next];
  }
  void notifyState(NSString* state) {
    auto weak = weak_from_this();
    mainQueue([weak, state] {
      if (auto s = weak.lock()) s->setState(state);
    });
  }
  bool present(CVPixelBufferRef buffer, uint32_t frame, std::weak_ptr<Runtime> source) {
    if (closing) return false;
    const size_t width = CVPixelBufferGetWidth(buffer), height = CVPixelBufferGetHeight(buffer);
    auto weak = weak_from_this();
    [texture
           install:buffer
        completion:[weak, source, frame, width, height](bool shown) {
          if (auto r = source.lock()) {
            r->frameComplete(frame, shown);
            if (shown)
              if (auto s = weak.lock()) {
                const uint64_t size = (uint64_t(width) << 32) | height;
                if (s->renderedEpoch != r->metrics().epoch || s->renderedSize != size)
                  mainQueue([weak, r, width, height, size] {
                    if (auto s = weak.lock()) {
                      std::lock_guard<std::mutex> lock(s->mutex);
                      if (s->closing || !s->active || s->runtime != r) return;
                      s->renderedEpoch = r->metrics().epoch;
                      if (s->renderedSize.exchange(size) != size)
                        [s->channel invokeMethod:@"videoSize" arguments:@{@"width" : @(width), @"height" : @(height)}];
                      s->setState(@"playing");
                    }
                  });
              }
          }
        }];
    if (!notifyPending.exchange(true))
      mainQueue([weak] {
        if (auto s = weak.lock()) {
          s->notifyPending = false;
          if (!s->closing) [s->registry textureFrameAvailable:s->textureId];
        }
      });
    return true;
  }
  void start() {
    auto self = shared_from_this();
    auto weak = weak_from_this();
    [channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult reply) {
      try {
        if (auto s = weak.lock())
          s->method(call, reply);
        else
          reply(unavailable());
      } catch (...) {
        reply(unavailable(@"INVALID_ARGUMENT"));
      }
    }];
    worker = std::thread([self] {
      @autoreleasepool {
        try {
          Credentials credentials;
          if (!loadTrust(self->host.id, credentials)) throw std::runtime_error("Pairing required");
          Host resolved = resolveHost(self->host, self->closing);
          bool hevc = self->hevc, pyrowave = self->pyrowave && AppleSink::supportsPyrowave();
          int channels = self->options.audioChannels;
          for (int attempt = 0; attempt < 4 && !self->closing; ++attempt) {
            auto r = std::make_shared<Runtime>();
            struct Failure {
              std::atomic<bool> video{false}, audio{false};
            };
            auto failure = std::make_shared<Failure>();
            std::weak_ptr<Runtime> source = r;
            std::weak_ptr<Session> weak = self;
            auto sink = std::make_shared<AppleSink>(
                [weak, source](CVPixelBufferRef pixel, uint32_t frame) {
                  if (auto s = weak.lock()) return s->present(pixel, frame, source);
                  return false;
                },
                [source](uint32_t frame, bool shown) {
                  if (auto r = source.lock()) r->frameComplete(frame, shown);
                },
                [source, failure](bool audio) {
                  (audio ? failure->audio : failure->video) = true;
                  if (auto r = source.lock()) r->cancel();
                });
            {
              std::lock_guard<std::mutex> lock(self->mutex);
              self->runtime = r;
              self->sink = sink;
              self->active = true;
              sink->volume(self->audible);
              if (self->closing) r->cancel();
            }
            auto options = self->options;
            options.audioChannels = channels;
            int result = r->run(resolved, credentials, self->game, hevc, pyrowave, sink, options);
            {
              std::lock_guard<std::mutex> lock(self->mutex);
              self->active = false;
              self->input.enabled(*r, false);
            }
            sink->close();
            {
              std::lock_guard<std::mutex> lock(self->mutex);
              self->sink.reset();
            }
            if (self->closing) break;
            bool stereo = failure->audio && channels > 2;
            bool h264 = (failure->video || result == -4) && hevc && r->metrics().codec == 5;
            bool conventional = pyrowave && (failure->video || (result != 0 && r->metrics().presentedFrames == 0));
            if (stereo || h264 || conventional) {
              if (stereo) channels = 2;
              if (h264) hevc = false;
              if (conventional) pyrowave = false;
              self->notifyState(@"reconnecting");
              continue;
            }
            self->notifyState(result == 0 && !failure->audio && !failure->video ? @"disconnected" : @"failed");
            break;
          }
        } catch (...) {
          if (!self->closing) self->notifyState(@"failed");
        }
      }
    });
  }
  void close(FlutterResult reply = nil);
  void method(FlutterMethodCall*, FlutterResult);
};
struct Manager : std::enable_shared_from_this<Manager> {
  __weak id<FlutterPluginRegistrar> registrar;
  FlutterMethodChannel *games, *receiver;
  std::map<int64_t, std::shared_ptr<Session>> sessions;
  int64_t next = 1;
  std::atomic<bool> cancelled{false}, closed{false};
  bool busy = false;
  std::mutex mutex;
  std::shared_ptr<Runtime> operation;
  Manager(id<FlutterPluginRegistrar> r) : registrar(r) {}
  void suspend() {
    cancelled = true;
    {
      std::lock_guard<std::mutex> lock(mutex);
      if (operation) operation->cancel();
    }
    for (auto& [_, s] : sessions) {
      std::lock_guard<std::mutex> lock(s->mutex);
      if (s->runtime) {
        s->input.enabled(*s->runtime, false);
        s->runtime->cancel();
      }
      if (s->sink) s->sink->volume(false);
    }
  }
  void shutdown() {
    if (closed.exchange(true)) return;
    suspend();
    auto copy = sessions;
    for (auto& [_, s] : copy) s->close();
    [games setMethodCallHandler:nil];
    [receiver setMethodCallHandler:nil];
  }
  void method(FlutterMethodCall*, FlutterResult, bool);
};
void Session::close(FlutterResult reply) {
  if (reply) [stopReplies addObject:[reply copy]];
  if (closing.exchange(true)) return;
  active = false;
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
    mainQueue([self] {
      [self->texture retire];
      [self->registry unregisterTexture:self->textureId];
      [self->channel setMethodCallHandler:nil];
      if (auto manager = self->owner.lock()) manager->sessions.erase(self->sessionId);
      for (FlutterResult reply in self->stopReplies) reply(nil);
      [self->stopReplies removeAllObjects];
    });
  }).detach();
}
void Session::method(FlutterMethodCall* call, FlutterResult reply) {
  NSString* method = call.method;
  if ([method isEqualToString:@"disconnect"]) {
    close(reply);
    return;
  }
  if ([method isEqualToString:@"getSessionState"]) {
    reply(state);
    return;
  }
  if (closing) {
    reply(unavailable());
    return;
  }
  std::lock_guard<std::mutex> lock(mutex);
  if ([method isEqualToString:@"resetInput"]) {
    if (runtime) input.reset(*runtime);
  } else if ([method isEqualToString:@"releaseTouchControls"]) {
    if (runtime) input.releaseAssistance(*runtime);
  } else if ([method isEqualToString:@"getStreamMetrics"]) {
    if (!runtime) {
      reply(nil);
      return;
    }
    const auto m = runtime->metrics();
    reply(@{
      @"version" : @1,
      @"epoch" : @(m.epoch),
      @"sampledAtUs" : @(m.sampledAtUs),
      @"receivedFrames" : @(m.receivedFrames),
      @"presentedFrames" : @(m.presentedFrames),
      @"droppedFrames" : @(m.droppedFrames),
      @"resetFrames" : @(m.resetFrames),
      @"videoBytes" : @(m.videoBytes),
      @"completionTotalUs" : @(m.completionTotalUs),
      @"completedFrames" : @(m.completedFrames),
      @"width" : @(m.width),
      @"height" : @(m.height),
      @"codec" : @(m.codec),
      @"audioChannels" : @(m.audioChannels),
      @"fpsNumerator" : @(m.fpsNumerator),
      @"fpsDenominator" : @(m.fpsDenominator),
      @"fpsReasons" : @(m.fpsReasons),
      @"targetBitrate" : @(m.targetBitrate),
      @"reliableRetries" : @(m.reliability.reliableRetries),
      @"reliableGiveUps" : @(m.reliability.reliableGiveUps),
      @"reliableOutstanding" : @(m.reliability.reliableOutstanding),
      @"maxAckLatencyMs" : @(m.reliability.reliableMaxAckLatencyMs),
      @"hidPending" : @(m.reliability.hidPending),
      @"hidInFlight" : @(m.reliability.hidInFlight),
      @"decoderKind" : @(sink ? sink->decoderKind() : 0),
      @"chromaFormat" : @(sink ? sink->chromaFormat() : 0)
    });
    return;
  } else {
    auto args = arguments(call.arguments);
    if ([method isEqualToString:@"setAudioEnabled"]) {
      audible = boolean(args, @"enabled");
#if !TARGET_OS_OSX
      if (audible) [[AVAudioSession sharedInstance] setActive:YES error:nil];
#endif
      if (sink) sink->volume(audible);
    } else if ([method isEqualToString:@"setInputEnabled"]) {
      if (runtime) input.enabled(*runtime, boolean(args, @"enabled") && [state isEqualToString:@"playing"]);
    } else if ([method isEqualToString:@"inputKey"]) {
      if (runtime && active && runtime->metrics().epoch == renderedEpoch) {
        if (args[@"usage"])
          input.hidKey(*runtime, number(args, @"usage", 0, 4, 231), boolean(args, @"down"));
        else
          input.key(*runtime, stringValue(args[@"key"]), boolean(args, @"down"));
      }
    } else if ([@[ @"inputMouse", @"inputWheel", @"releasePointer" ] containsObject:method]) {
      if (runtime && active && runtime->metrics().epoch == renderedEpoch) {
        if ([method isEqualToString:@"releasePointer"])
          input.releasePointer(*runtime);
        else if ([method isEqualToString:@"inputWheel"])
          input.wheel(*runtime, number(args, @"direction", 0, 1, 4));
        else {
          if (!isNumber(args[@"x"]) || !isNumber(args[@"y"])) throw std::invalid_argument("Invalid coordinate");
          input.mouse(
              *runtime, [args[@"x"] doubleValue], [args[@"y"] doubleValue], number(args, @"button", 0, 0, 16),
              boolean(args, @"down"));
        }
      }
    } else if ([@[ @"disconnectController", @"setControllerDeviceState", @"setTouchControllerState" ]
                   containsObject:method]) {
      const bool assistance = [method isEqualToString:@"setTouchControllerState"];
      int64_t device = assistance ? 0 : integer(args[@"deviceId"]);
      if (runtime && active && runtime->metrics().epoch == renderedEpoch) {
        if ([method isEqualToString:@"disconnectController"])
          input.disconnect(*runtime, device);
        else {
          for (NSString* group in @[ @"buttons", @"axes" ]) {
            if (!args[group]) continue;
            auto values = arguments(args[group]);
            if (values.count > 32) throw std::invalid_argument("Too many controls");
            for (NSString* key in values) {
              auto name = stringValue(key);
              if ([group isEqualToString:@"buttons"])
                input.button(*runtime, device, name, boolean(values, key), assistance);
              else if (isNumber(values[key]))
                input.axis(*runtime, device, name, [values[key] doubleValue], assistance);
            }
          }
        }
      }
    } else {
      reply(FlutterMethodNotImplemented);
      return;
    }
  }
  reply(nil);
}
void Manager::method(FlutterMethodCall* call, FlutterResult reply, bool create) {
  if (closed) {
    reply(unavailable());
    return;
  }
  NSString* name = call.method;
  if (!create && [name isEqualToString:@"cancel"]) {
    cancelled = true;
    std::lock_guard<std::mutex> lock(mutex);
    if (operation) operation->cancel();
    reply(nil);
    return;
  }
  auto args = arguments(call.arguments);
  if (!create && [name isEqualToString:@"capabilities"]) {
    bool available = stringValue(args[@"protocol"]) == "steam";
    reply(@{
      @"available" : @(available),
      @"inlinePairing" : @(available),
      @"library" : @(available),
      @"embeddedSurface" : @(available)
    });
    return;
  }
  if (create && [name isEqualToString:@"create"]) {
    if (sessions.size() >= 8) {
      reply(unavailable());
      return;
    }
    auto host = hostFrom(args);
    auto game = identifier(args[@"appId"], true);
    StreamOptions options;
    options.width = number(args, @"streamWidth", 1920, 640, 1920);
    options.height = number(args, @"streamHeight", 1080, 360, 1080);
    options.fps = number(args, @"streamFps", 60, 15, 60);
    options.bitrateKbps = number(args, @"streamBitrateKbps", 30000, 1000, 50000);
    options.controllerCount = number(args, @"controllerCount", 1, 1, 4);
    options.audioChannels = number(args, @"audioChannels", 2, 2, 6);
    if (!options.valid()) throw std::invalid_argument("Invalid stream options");
    auto session = std::make_shared<Session>(
        next++, host, game, options, boolean(args, @"allowHevc", true) && AppleSink::supportsHevc(),
        boolean(args, @"pyrowave"), registrar);
    session->owner = shared_from_this();
    sessions.emplace(session->sessionId, session);
    session->start();
    reply(@{@"id" : @(session->sessionId), @"textureId" : @(session->textureId)});
    return;
  }
  if (create || stringValue(args[@"protocol"]) != "steam" ||
      (![@[ @"pair", @"games", @"forget" ] containsObject:name])) {
    reply(FlutterMethodNotImplemented);
    return;
  }
  if (busy) {
    reply(unavailable(@"BUSY"));
    return;
  }
  Host host = hostFrom(args);
  auto pin = [name isEqualToString:@"pair"] ? stringValue(args[@"pin"]) : "";
  if ([name isEqualToString:@"pair"] && (pin.size() != 4 || pin.find_first_not_of("0123456789") != std::string::npos))
    throw std::invalid_argument("Invalid PIN");
  if ([name isEqualToString:@"forget"]) {
    auto copy = sessions;
    for (auto& [_, s] : copy)
      if (s->host.id == host.id) s->close();
  }
  busy = true;
  cancelled = false;
  auto r = std::make_shared<Runtime>();
  {
    std::lock_guard<std::mutex> lock(mutex);
    operation = r;
  }
  auto self = shared_from_this();
  std::thread([self, r, host, pin, name, reply] {
    @autoreleasepool {
      bool success = false;
      try {
        Credentials c;
        if ([name isEqualToString:@"games"])
          success = loadTrust(host.id, c);
        else if ([name isEqualToString:@"forget"])
          success = forgetTrust(host.id);
        else {
          if (SecRandomCopyBytes(kSecRandomDefault, sizeof(c.device), &c.device) != errSecSuccess ||
              SecRandomCopyBytes(kSecRandomDefault, c.key.size(), c.key.data()) != errSecSuccess)
            throw std::runtime_error("Entropy unavailable");
          success = r->pair(resolveHost(host, self->cancelled), c, pin) == 0;
          success = success && !self->cancelled && !self->closed && saveTrust(host.id, c);
          if (self->cancelled || self->closed) {
            success = false;
            Credentials stored;
            if (loadTrust(host.id, stored) && stored.device == c.device) forgetTrust(host.id);
          }
        }
      } catch (...) {
      }
      mainQueue([self, r, success, name, reply] {
        self->busy = false;
        {
          std::lock_guard<std::mutex> lock(self->mutex);
          if (self->operation == r) self->operation.reset();
        }
        if (self->cancelled || self->closed)
          reply(unavailable(@"CANCELLED"));
        else if (!success)
          reply(unavailable([name isEqualToString:@"games"] ? @"PAIRING_REQUIRED" : @"UNAVAILABLE"));
        else
          reply([name isEqualToString:@"games"] ? (id) @[] : (id) @YES);
      });
    }
  }).detach();
}
}  // namespace

@implementation PlezySteamPlugin {
  std::shared_ptr<Manager> manager_;
  id backgroundObserver_;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  auto plugin = [PlezySteamPlugin new];
  auto manager = std::make_shared<Manager>(registrar);
  plugin->manager_ = manager;
  std::weak_ptr<Manager> weak = manager;
  manager->games = [FlutterMethodChannel methodChannelWithName:@"com.plezy/games"
                                               binaryMessenger:[registrar messenger]];
  manager->receiver = [FlutterMethodChannel methodChannelWithName:@"com.plezy/games/steam_receiver"
                                                  binaryMessenger:[registrar messenger]];
  for (bool create : {false, true}) {
    FlutterMethodChannel* channel = create ? manager->receiver : manager->games;
    [channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult reply) {
      try {
        if (auto m = weak.lock())
          m->method(call, reply, create);
        else
          reply(unavailable());
      } catch (...) {
        reply(unavailable(@"INVALID_ARGUMENT"));
      }
    }];
  }
#if TARGET_OS_OSX
  plugin->backgroundObserver_ =
      [[[NSWorkspace sharedWorkspace] notificationCenter] addObserverForName:NSWorkspaceWillSleepNotification
                                                                      object:nil
                                                                       queue:NSOperationQueue.mainQueue
                                                                  usingBlock:^(NSNotification*) {
                                                                    if (auto m = weak.lock()) m->suspend();
                                                                  }];
#else
  plugin->backgroundObserver_ =
      [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil
                                                       queue:NSOperationQueue.mainQueue
                                                  usingBlock:^(NSNotification*) {
                                                    if (auto m = weak.lock()) m->suspend();
                                                  }];
#endif
  [registrar publish:plugin];
}
- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  if (manager_) manager_->shutdown();
}
- (void)dealloc {
#if TARGET_OS_OSX
  [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:backgroundObserver_];
#else
  [NSNotificationCenter.defaultCenter removeObserver:backgroundObserver_];
#endif
  if (manager_) manager_->shutdown();
}
@end
