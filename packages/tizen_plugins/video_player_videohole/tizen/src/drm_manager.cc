// Copyright 2022 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "drm_manager.h"

#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

#include "drm_license_helper.h"
#include "ftpw_video_player_videohole.h"
#include "log.h"

static std::string GetDrmSubType(int drm_type) {
  switch (drm_type) {
    case DrmManager::DRM_TYPE_PLAYREADAY:
      return "com.microsoft.playready";
    case DrmManager::DRM_TYPE_WIDEVINECDM:
    default:
      return "com.widevine.alpha";
  }
}

DrmManager::DrmManager() : drm_type_(DRM_TYPE_NONE) {
  // Initialize GMainContext and license request state
  main_context_ = std::unique_ptr<GMainContext, GMainContextDeleter>(
      g_main_context_ref_thread_default());
  license_request_state_ = std::make_shared<DrmManager::LicenseRequestState>();
  license_request_state_->manager = this;
}

DrmManager::~DrmManager() {
  ReleaseDrmSession();

  // Mark license request state as disposed and cancel pending event source
  if (license_request_state_) {
    std::lock_guard<std::mutex> lock(license_request_state_->mutex);
    license_request_state_->disposed = true;
    license_request_state_->manager = nullptr;

    if (license_request_state_->pending_source_id != 0) {
      g_source_remove(license_request_state_->pending_source_id);
      license_request_state_->pending_source_id = 0;
    }
  }

  main_context_.reset();
}

bool DrmManager::CreateDrmSession(int drm_type, bool local_mode) {
  if (local_mode) {
    ftpw_video_player_videohole_DMGRSetDRMLocalMode();
  }

  drm_type_ = drm_type;
  std::string sub_type = GetDrmSubType(drm_type);
  LOG_INFO("[DrmManager] drm type is %s", sub_type.c_str());
  drm_session_ =
      ftpw_video_player_videohole_DMGRCreateDRMSession(sub_type.c_str());
  if (!drm_session_) {
    LOG_ERROR("[DrmManager] Fail to create drm session.");
    return false;
  }
  LOG_INFO("[DrmManager] Drm session is created, drm_session: %p",
           drm_session_);

  SetDataParam_t configure_param = {};
  configure_param.param1 = reinterpret_cast<void *>(OnDrmManagerError);
  configure_param.param2 = drm_session_;
  int ret = ftpw_video_player_videohole_DMGRSetData(
      drm_session_, "error_event_callback", &configure_param);
  if (ret != DM_ERROR_NONE) {
    LOG_ERROR(
        "[DrmManager] Fail to set error_event_callback to drm session: %s",
        get_error_message(ret));
    ReleaseDrmSession();
    return false;
  }

  return true;
}

bool DrmManager::SetChallenge(const std::string &media_url,
                              flutter::BinaryMessenger *binary_messenger) {
  request_license_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          binary_messenger, "dev.flutter.videoplayer.drm",
          &flutter::StandardMethodCodec::GetInstance());
  return DM_ERROR_NONE == SetChallenge(media_url);
}

bool DrmManager::SetChallenge(const std::string &media_url,
                              const std::string &license_server_url) {
  license_server_url_ = license_server_url;
  return DM_ERROR_NONE == SetChallenge(media_url);
}

void DrmManager::StopDrmSession() {
  if (drm_session_ == nullptr) {
    LOG_ERROR("[DrmManager] Already released.");
    return;
  }

  SetDataParam_t challenge_data_param = {};
  challenge_data_param.param1 = nullptr;
  challenge_data_param.param2 = nullptr;
  int ret = ftpw_video_player_videohole_DMGRSetData(
      drm_session_, "eme_request_key_callback", &challenge_data_param);
  if (ret != DM_ERROR_NONE) {
    LOG_ERROR("[DrmManager] Fail to unset eme_request_key_callback: %s",
              get_error_message(ret));
  }

  ret = ftpw_video_player_videohole_DMGRSetData(drm_session_, "Finalize",
                                                nullptr);

  if (ret != DM_ERROR_NONE) {
    LOG_ERROR("[DrmManager] Fail to set finalize to drm session: %s",
              get_error_message(ret));
  }
}

void DrmManager::ReleaseDrmSession() {
  if (drm_session_ == nullptr) {
    LOG_ERROR("[DrmManager] Already released.");
    return;
  }

  int ret = ftpw_video_player_videohole_DMGRReleaseDRMSession(drm_session_);
  if (ret != DM_ERROR_NONE) {
    LOG_ERROR("[DrmManager] Fail to release drm session: %s",
              get_error_message(ret));
  }
  drm_session_ = nullptr;
}

bool DrmManager::GetDrmHandle(int *handle) {
  if (drm_session_) {
    *handle = 0;
    int ret = ftpw_video_player_videohole_DMGRGetData(drm_session_,
                                                      "drm_handle", handle);
    if (ret != DM_ERROR_NONE) {
      LOG_ERROR("[DrmManager] Fail to get drm_handle from drm session: %s",
                get_error_message(ret));
      return false;
    }
    LOG_INFO("[DrmManager] Get drm handle: %d", *handle);
    return true;
  } else {
    LOG_ERROR("[DrmManager] Invalid drm session.");
    return false;
  }
}

int DrmManager::UpdatePsshData(const void *data, int length) {
  if (!drm_session_) {
    LOG_ERROR("[DrmManager] Invalid drm session.");
    return DM_ERROR_INVALID_SESSION;
  }

  SetDataParam_t pssh_data_param = {};
  pssh_data_param.param1 = const_cast<void *>(data);
  pssh_data_param.param2 = reinterpret_cast<void *>(length);
  int ret = ftpw_video_player_videohole_DMGRSetData(
      drm_session_, "update_pssh_data", &pssh_data_param);
  if (DM_ERROR_NONE != ret) {
    LOG_ERROR("[DrmManager] Fail to set update_pssh_data to drm session: %s",
              get_error_message(ret));
  }
  return ret;
}

bool DrmManager::SecurityInitCompleteCB(int *drm_handle, unsigned int len,
                                        unsigned char *pssh_data,
                                        void *user_data) {
  // IMPORTANT: SetDataParam_t cannot be stack allocated because
  // DMGRSecurityInitCompleteCB is called multiple times during video playback
  // and the parameter should always be available.
  SetDataParam_t security_param = {};
  if (user_data) {
    security_param.param1 = user_data;
  }
  security_param.param2 = drm_session_;

  return ftpw_video_player_videohole_DMGRSecurityInitCompleteCB(
      drm_handle, len, pssh_data, &security_param);
}

int DrmManager::SetChallenge(const std::string &media_url) {
  if (!drm_session_) {
    LOG_ERROR("[DrmManager] Invalid drm session.");
    return DM_ERROR_INVALID_SESSION;
  }

  SetDataParam_t challenge_data_param = {};
  challenge_data_param.param1 = reinterpret_cast<void *>(OnChallengeData);
  challenge_data_param.param2 = this;
  int ret = ftpw_video_player_videohole_DMGRSetData(
      drm_session_, "eme_request_key_callback", &challenge_data_param);
  if (ret != DM_ERROR_NONE) {
    LOG_ERROR(
        "[DrmManager] Fail to set eme_request_key_callback to drm session: "
        "%s",
        get_error_message(ret));
    return ret;
  }

  ret = ftpw_video_player_videohole_DMGRSetData(
      drm_session_, "set_playready_manifest",
      static_cast<void *>(const_cast<char *>(media_url.c_str())));
  if (ret != DM_ERROR_NONE) {
    LOG_ERROR(
        "[DrmManager] Fail to set set_playready_manifest to drm session: %s",
        get_error_message(ret));
    return ret;
  }

  ret = ftpw_video_player_videohole_DMGRSetData(drm_session_, "Initialize",
                                                nullptr);
  if (ret != DM_ERROR_NONE) {
    LOG_ERROR("[DrmManager] Fail to set initialize to drm session: %s",
              get_error_message(ret));
    return ret;
  }
  initialized_ = true;
  return ret;
}

int DrmManager::OnChallengeData(void *session_id, int message_type,
                                void *message, int message_length,
                                void *user_data) {
  LOG_INFO("[DrmManager] challenge data: %s, challenge length: %d", message,
           message_length);
  DrmManager *self = static_cast<DrmManager *>(user_data);
  LOG_INFO("[DrmManager] drm_type: %d, license server: %s", self->drm_type_,
           self->license_server_url_.c_str());
  DataForLicenseProcess process_message(session_id, message, message_length);
  self->PushLicenseRequestData(process_message);
  return DM_ERROR_NONE;
}

void DrmManager::OnDrmManagerError(long error_code, char *error_message,
                                   void *user_data) {
  LOG_ERROR("[DrmManager] DRM manager had an error: [%ld][%s]", error_code,
            error_message);
}

bool DrmManager::ProcessLicense(DataForLicenseProcess &data) {
  LOG_INFO("[DrmManager] Start process license.");

  if (!license_server_url_.empty()) {
    // Get license via the license server.
    unsigned char *response_data = nullptr;
    unsigned long response_len = 0;
    DRM_RESULT ret = DrmLicenseHelper::DoTransactionTZ(
        license_server_url_.c_str(), data.message.c_str(), data.message.size(),
        &response_data, &response_len,
        static_cast<DrmLicenseHelper::DrmType>(drm_type_), nullptr, nullptr);
    if (DRM_SUCCESS != ret || nullptr == response_data || 0 == response_len) {
      LOG_ERROR("[DrmManager] Fail to get respone by license server url.");
      return false;
    }
    LOG_INFO("[DrmManager] Response length : %lu", response_len);
    InstallKey(const_cast<void *>(
                   reinterpret_cast<const void *>(data.session_id.c_str())),
               static_cast<void *>(response_data),
               reinterpret_cast<void *>(response_len));
    free(response_data);
  } else if (request_license_channel_) {
    // Get license via the Dart callback.
    RequestLicense(data.session_id, data.message);
  } else {
    LOG_ERROR("[DrmManager] No way to request license.");
  }
  return false;
}

void DrmManager::InstallKey(void *session_id, void *response_data,
                            void *response_len) {
  LOG_INFO("[DrmManager] Start install license.");

  SetDataParam_t license_param = {};
  license_param.param1 = session_id;
  license_param.param2 = response_data;
  license_param.param3 = response_len;
  int ret = ftpw_video_player_videohole_DMGRSetData(
      drm_session_, "install_eme_key", &license_param);
  if (ret != DM_ERROR_NONE) {
    LOG_ERROR("[DrmManager] Fail to install eme key: %s",
              get_error_message(ret));
  }
}

void DrmManager::RequestLicense(std::string &session_id, std::string &message) {
  LOG_INFO("[DrmManager] Start request license.");

  if (request_license_channel_ == nullptr) {
    LOG_ERROR("[DrmManager] request license channel is null.");
    return;
  }

  std::vector<uint8_t> message_vec(message.begin(), message.end());
  flutter::EncodableMap args_map = {
      {flutter::EncodableValue("message"),
       flutter::EncodableValue(message_vec)},
  };
  auto result_handler =
      std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(

          [session_id, this](const flutter::EncodableValue *success_value) {
            std::vector<uint8_t> response;
            if (std::holds_alternative<std::vector<uint8_t>>(*success_value)) {
              response = std::get<std::vector<uint8_t>>(*success_value);
            } else {
              LOG_ERROR("[DrmManager] Fail to get response.");
              return;
            }
            LOG_INFO("[DrmManager] Response length : %d", response.size());
            InstallKey(const_cast<void *>(
                           reinterpret_cast<const void *>(session_id.c_str())),
                       reinterpret_cast<void *>(response.data()),
                       reinterpret_cast<void *>(response.size()));
          },
          nullptr, nullptr);
  request_license_channel_->InvokeMethod(
      "requestLicense",
      std::make_unique<flutter::EncodableValue>(
          flutter::EncodableValue(args_map)),
      std::move(result_handler));
}

void DrmManager::ScheduleProcessLicenseRequest() {
  std::lock_guard<std::mutex> lock(license_request_state_->mutex);

  // Check conditions and deduplicate
  if (!main_context_ || !license_request_state_ ||
      license_request_state_->disposed ||
      license_request_state_->pending_source_id != 0) {
    return;
  }

  auto *state =
      new std::shared_ptr<LicenseRequestState>(license_request_state_);

  GSource *source = g_idle_source_new();
  g_source_set_callback(
      source,
      [](gpointer data) -> gboolean {
        auto state = static_cast<std::shared_ptr<LicenseRequestState> *>(data);
        DrmManager *manager = nullptr;
        {
          std::lock_guard<std::mutex> lock((*state)->mutex);
          if (!(*state)->disposed && (*state)->manager) {
            (*state)->pending_source_id = 0;
            manager = (*state)->manager;
          }
        }
        if (manager) {
          manager->ExecuteRequest();
        }
        return G_SOURCE_REMOVE;
      },
      state,
      [](gpointer data) {
        delete static_cast<std::shared_ptr<LicenseRequestState> *>(data);
      });

  license_request_state_->pending_source_id =
      g_source_attach(source, main_context_.get());
  g_source_unref(source);
}

void DrmManager::PushLicenseRequestData(DataForLicenseProcess &data) {
  {
    std::lock_guard<std::mutex> lock(queue_mutex_);
    license_request_queue_.push(data);
  }
  ScheduleProcessLicenseRequest();
}

void DrmManager::ExecuteRequest() {
  std::lock_guard<std::mutex> lock(queue_mutex_);
  while (!license_request_queue_.empty()) {
    DataForLicenseProcess data = license_request_queue_.front();
    ProcessLicense(data);
    license_request_queue_.pop();
  }
}
