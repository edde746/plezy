// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#ifndef FLUTTER_TIZEN_PLUGINS_WRAPPER_VIDEO_PLAYER_VIDEOHOLE_H_
#define FLUTTER_TIZEN_PLUGINS_WRAPPER_VIDEO_PLAYER_VIDEOHOLE_H_

#include <stdbool.h>
#include <stdint.h>

#define MAX_STRING_NAME_LEN 255
#define MMPLAYER_FOUR_CC_LEN 14
#define PLAYER_LANG_NAME_SIZE 10

typedef struct {
  char fourCC[MMPLAYER_FOUR_CC_LEN + 1]; /**< codec fourcc */
  char name[MAX_STRING_NAME_LEN]; /**< name: video/audio, it maybe not exit in
                                     some track*/
  /*dynamic infos in hls,ss,dash streams*/
  int width;    /**< resolution width */
  int height;   /**< resolution height */
  int bit_rate; /**< bitrate in bps */
} player_video_track_info_v2;

typedef struct {
  char fourCC[MMPLAYER_FOUR_CC_LEN + 1]; /**< codec fourcc */
  char language[PLAYER_LANG_NAME_SIZE];  /**< language info*/
  /*dynamic infos in hls,ss,dash streams*/
  int sample_rate; /**< sample rate in this track*/
  int channel;     /**< channel in this track*/
  int bit_rate;    /**< bitrate  in this track*/
} player_audio_track_info_v2;

typedef struct {
  char fourCC[MMPLAYER_FOUR_CC_LEN + 1]; /**< codec fourcc */
  char language[PLAYER_LANG_NAME_SIZE];  /**< language info*/
  int subtitle_type; /**< text subtitle = 0, picture subtitle = 1 */
} player_subtitle_track_info_v2;

typedef enum {
  PLAYER_DRM_TYPE_EME = 14,
} player_drm_type_e;

typedef enum {
  PLAYER_DISPLAY_TYPE_TCORE_OVERLAY,         /**< Video overlay using
                                                tizen_core_wl_window_h */
  PLAYER_DISPLAY_TYPE_TCORE_OVERLAY_SYNC_UI, /**< Sync UI video overlay using
                                             handle string from
                                             tizen_core_wl_video_shell_surface_get_handle()
                                           */
} player_display_type_tcore_e;

typedef enum {
  PLAYER_ADAPTIVE_INFO_LIVE_DURATION = 3,
  PLAYER_ADAPTIVE_INFO_IS_LIVE = 19,
} player_adaptive_Info_e;

typedef enum {
  CENC = 0,
  KEYIDS = 1,
  WEBM = 2,
} drm_init_data_type;

typedef bool (*security_init_complete_cb)(int *drmhandle, unsigned int length,
                                          unsigned char *psshdata,
                                          void *user_data);
typedef int (*set_drm_init_data_cb)(drm_init_data_type init_type, void *data,
                                    int data_length, void *user_data);

typedef enum {
  DM_ERROR_NONE = 0,
  DM_ERROR_INVALID_SESSION = 21,
} dm_error_e;

typedef struct SetDataParam_s {
  void *param1; /**< Parameter 1 */
  void *param2; /**< Parameter 2 */
  void *param3; /**< Parameter 3 */
  void *param4; /**< Parameter 4 */
} SetDataParam_t;

typedef void *DRMSessionHandle_t;

#ifdef __cplusplus
extern "C" {
#endif

// Native libraries remain loaded for the process lifetime (callbacks may
// outlive calls).

int ftpw_video_player_videohole_player_set_ecore_wl_display(
    void *player, int type, void *ecore_wl_window, int x, int y, int width,
    int height);
int ftpw_video_player_videohole_player_set_tcore_display(
    void *player, player_display_type_tcore_e type, void *display);
int ftpw_video_player_videohole_player_set_drm_handle(
    void *player, player_drm_type_e drm_type, int drm_handle);
int ftpw_video_player_videohole_player_set_drm_init_complete_cb(
    void *player, security_init_complete_cb callback, void *user_data);
int ftpw_video_player_videohole_player_set_drm_init_data_cb(
    void *player, set_drm_init_data_cb callback, void *user_data);
int ftpw_video_player_videohole_player_get_adaptive_streaming_info(
    void *player, void *adaptive_info, int adaptive_type);
int ftpw_video_player_videohole_player_get_track_count_v2(void *player,
                                                          int type,
                                                          int *pcount);
int ftpw_video_player_videohole_player_get_video_track_info_v2(
    void *player, int index, player_video_track_info_v2 **track_info);
int ftpw_video_player_videohole_player_get_audio_track_info_v2(
    void *player, int index, player_audio_track_info_v2 **track_info);
int ftpw_video_player_videohole_player_get_subtitle_track_info_v2(
    void *player, int index, player_subtitle_track_info_v2 **track_info);
bool ftpw_video_player_videohole_device_power_is_standby(void);
int ftpw_video_player_videohole_DMGRSetData(DRMSessionHandle_t drm_session,
                                            const char *data_type,
                                            void *input_data);
int ftpw_video_player_videohole_DMGRGetData(DRMSessionHandle_t drm_session,
                                            const char *data_type,
                                            void *output_data);
void ftpw_video_player_videohole_DMGRSetDRMLocalMode(void);
DRMSessionHandle_t ftpw_video_player_videohole_DMGRCreateDRMSession(
    const char *drm_sub_type);
bool ftpw_video_player_videohole_DMGRSecurityInitCompleteCB(
    int *drm_handle, unsigned int len, unsigned char *pssh_data,
    void *user_data);
int ftpw_video_player_videohole_DMGRReleaseDRMSession(
    DRMSessionHandle_t drm_session);

#ifdef __cplusplus
}
#endif

#endif  // FLUTTER_TIZEN_PLUGINS_WRAPPER_VIDEO_PLAYER_VIDEOHOLE_H_
