#ifndef WEBOS_VIDEO_PLAYER_DRM_MANAGER_H_
#define WEBOS_VIDEO_PLAYER_DRM_MANAGER_H_
#include <atomic>
#include <memory>
#include <string>
#include "log.h"
#include "webos_player.h"
#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_method_codec.h>
#include <flutter/method_result_functions.h>

typedef enum {
    DRM_TYPE_NONE,
    DRM_TYPE_PLAYREADAY,
    DRM_TYPE_WIDEVINECDM,
  } DrmType;

class DrmManager {
 public:
  explicit DrmManager(const std::string &app_id, const std::string &licenseUrl, int drm_type, flutter::BinaryMessenger* messenger, WebOSPlayer* player_instance);
  ~DrmManager();
  void processChallenge(const WebOSPlayer::DrmEncryptedCb& info);
  std::string getLicenseUrl();
  std::string getDrmType();

 private:
  std::string app_id_;
  std::string licenseUrl_;
  std::string str_drmType_;
  int drm_type_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> drm_method_channel_;
  WebOSPlayer* webos_player_instance_;
  // Liveness flag for the in-flight license callback, which may run after this
  // object is destroyed. Avoids a use-after-free.
  std::shared_ptr<std::atomic<bool>> alive_ =
      std::make_shared<std::atomic<bool>>(true);
  void handleDrmLoadResponse(const std::string &response);
  std::string drmTypeToString(const int &drmType);
};
#endif // WEBOS_VIDEO_PLAYER_DRM_MANAGER_H_