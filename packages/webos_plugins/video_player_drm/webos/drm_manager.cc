#include "drm_manager.h"
#include <glib.h>

#ifdef TAG
#undef TAG
#endif
#define TAG "DrmManager::"

DrmManager::DrmManager(const std::string &app_id, const std::string &licenseUrl, int drm_type, flutter::BinaryMessenger* messenger, WebOSPlayer* player_instance)
    : app_id_(app_id),
      licenseUrl_(licenseUrl),
      str_drmType_(drmTypeToString(drm_type)),
      drm_type_(drm_type),
      webos_player_instance_(player_instance) {
        drm_method_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger,
          "dev.flutter.video_player_drm.drm",
          &flutter::StandardMethodCodec::GetInstance());
}

DrmManager::~DrmManager() {
  alive_->store(false);  // stop any pending license callback from using us
}

std::string DrmManager::getLicenseUrl() {
  return licenseUrl_;
}

std::string DrmManager::getDrmType() {
  return str_drmType_;
}

std::string DrmManager::drmTypeToString(const int &drmType) {
  switch (drmType)
  {
  case 1:
    return "PLAYREADY";
  case 2:
    return "WIDEVINE";
  default:
    return "none";
  }
}

void DrmManager::processChallenge(const WebOSPlayer::DrmEncryptedCb& info) {
  if (!drm_method_channel_) return;

  // Base64 decode the challenge body the platform DRM client handed us so
  // the Flutter side receives raw bytes ready for the license server.
  std::vector<uint8_t> actual_challenge;
  gsize decoded_length = 0;
  guchar* decoded_data = g_base64_decode(info.drmData.c_str(), &decoded_length);
  if (!decoded_data || decoded_length == 0) {
    LogError(TAG) << "Failed to decode challenge data for session " << info.sessionId;
    actual_challenge.assign(info.drmData.begin(), info.drmData.end());
  } else {
    actual_challenge.assign(decoded_data, decoded_data + decoded_length);
  }
  g_free(decoded_data);

  flutter::EncodableMap args;
  args[flutter::EncodableValue("challenge")] = flutter::EncodableValue(actual_challenge);
  args[flutter::EncodableValue("sessionId")] = flutter::EncodableValue(info.sessionId);

  // Capture the DRM challenge fields we'll need to relay the license back to
  // the platform DRM client. Capture by value because the original info
  // object goes out of scope before the async license-server reply lands.
  const std::string systemId   = info.systemId;
  const std::string service    = info.service;
  const std::string key        = info.key;
  const std::string sessionId  = info.sessionId;
  const int32_t     requestId  = info.requestId;

  // Capture by value (not `this`): the license reply may arrive after dispose,
  // so the callback guards on `alive` before touching the player.
  WebOSPlayer* player = webos_player_instance_;
  auto alive = alive_;
  auto result_handler = std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
      // success callback
      [player, alive, systemId, service, key, sessionId, requestId](
          const flutter::EncodableValue* success_value) {
        if (!alive->load()) return;  // player disposed mid-acquisition
        if (success_value && std::holds_alternative<std::vector<uint8_t>>(*success_value)) {
          const auto& license_bytes = std::get<std::vector<uint8_t>>(*success_value);
          std::string license_str(license_bytes.begin(), license_bytes.end());
          LogInfo(TAG) << "Response data from license server: " << license_str;

          player->setDrmOperation(
            systemId,
            license_str,
            "update",
            service,
            sessionId,
            requestId,
            key
          );
        }
      },
      // failure callback
      [sessionId](const std::string&, const std::string& error_message, const flutter::EncodableValue*) {
        LogError(TAG) << "License request failed for session " << sessionId << ": " << error_message;
      },
      nullptr
  );

  drm_method_channel_->InvokeMethod(
      "requestDrmLicense",
      std::make_unique<flutter::EncodableValue>(args),
      std::move(result_handler)
  );
}