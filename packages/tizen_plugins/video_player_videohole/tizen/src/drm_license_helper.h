// Copyright 2022 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_PLUGIN_DRM_LICENSE_HELPER_H_
#define FLUTTER_PLUGIN_DRM_LICENSE_HELPER_H_

typedef long DRM_RESULT;

const DRM_RESULT DRM_SUCCESS = 0x00000000L;
const DRM_RESULT DRM_E_POINTER = 0x80004003L;
const DRM_RESULT DRM_E_INVALIDARG = 0x80070057L;
const DRM_RESULT DRM_E_NETWORK = 0x91000000L;
const DRM_RESULT DRM_E_NETWORK_CURL = 0x91000001L;
const DRM_RESULT DRM_E_NETWORK_HOST = 0x91000002L;
const DRM_RESULT DRM_E_NETWORK_CLIENT = 0x91000003L;
const DRM_RESULT DRM_E_NETWORK_SERVER = 0x91000004L;
const DRM_RESULT DRM_E_NETWORK_HEADER = 0x91000005L;
const DRM_RESULT DRM_E_NETWORK_REQUEST = 0x91000006L;
const DRM_RESULT DRM_E_NETWORK_RESPONSE = 0x91000007L;
const DRM_RESULT DRM_E_NETWORK_CANCELED = 0x91000008L;

class DrmLicenseHelper {
 public:
  enum DrmType {
    kNone = 0,
    kPlayReady,
    kWidevine,
  };

  struct SExtensionCtxTZ {
    char* http_soap_header = nullptr;
    char* http_header = nullptr;
    char* http_user_agent = nullptr;
    bool cancel_request = false;
  };

  static DRM_RESULT DoTransactionTZ(const char* http_server_url,
                                    const void* challenge,
                                    unsigned long challenge_len,
                                    unsigned char** response,
                                    unsigned long* response_len, DrmType type,
                                    const char* http_cookie,
                                    SExtensionCtxTZ* http_ext_ctx);
};

#endif  // FLUTTER_PLUGIN_DRM_LICENSE_HELPER_H_
