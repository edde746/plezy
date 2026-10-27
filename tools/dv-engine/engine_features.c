#include <stdio.h>
#include <string.h>

#include <libavcodec/bsf.h>
#include <libavformat/avformat.h>
#include <libplacebo/config.h>
#include <libplacebo/renderer.h>
#include <mpv/client.h>
#include <mpv/render.h>

#if PL_API_VER < 366
#error libplacebo must expose FEL composition
#endif
#ifndef PL_HAVE_DOVI
#error libplacebo was built without Dolby Vision reshaping
#endif
#if defined(PLEZYNG_DV_REQUIRE_D3D11)
#ifndef PL_HAVE_D3D11
#error the Windows engine needs libplacebo D3D11 support
#endif
#else
#ifndef PL_HAVE_OPENGL
#error the experimental embedding needs libplacebo OpenGL support
#endif
#endif

#if defined(PLEZYNG_DV_REQUIRE_D3D11)
#define RENDER_BACKEND "d3d11"
#else
#define RENDER_BACKEND "opengl"
#endif

int main(void) {
  // Compile against the actual paired-frame and residual metadata interfaces.
  struct pl_frame frame = {0};
  struct pl_dovi_metadata dovi = {0};
  frame.enhancement_layer = NULL;
  dovi.nlq_active = true;
  frame.repr.dovi = &dovi;
  enum AVStreamGroupParamsType group_type = AV_STREAM_GROUP_PARAMS_DOLBY_VISION;
  if (!av_bsf_get_by_name("dovi_split") ||
      strcmp(MPV_RENDER_API_TYPE_OPENGL_NEXT, "opengl-next") != 0 ||
      group_type == AV_STREAM_GROUP_PARAMS_NONE || !frame.repr.dovi->nlq_active) {
    fputs("Required dual-layer/FEL engine interfaces are missing\n", stderr);
    return 1;
  }
  mpv_handle *mpv = mpv_create();
  if (!mpv)
    return 1;
  int result = mpv_set_option_string(mpv, "config", "no");
  result |= mpv_set_option_string(mpv, "vo", "null");
  result |= mpv_set_option_string(mpv, "ao", "null");
  if (result < 0 || mpv_initialize(mpv) < 0) {
    mpv_terminate_destroy(mpv);
    return 1;
  }
  char *identity = mpv_get_property_string(mpv, "plezyng-dv-engine");
  int identity_matches = identity && strcmp(identity, "plezyng-dv-fel-v1") == 0;
  mpv_free(identity);
  mpv_terminate_destroy(mpv);
  if (!identity_matches) {
    fputs("The loaded libmpv lacks the fail-closed FEL integration\n", stderr);
    return 1;
  }
  printf("{\"dovi_split\":true,\"paired_frame_api\":true,"
         "\"fel_nlq_api\":true,\"libplacebo_api\":%d,\"libmpv_api\":%lu,"
         "\"engine_id\":\"plezyng-dv-fel-v1\",\"render_backend\":\"" RENDER_BACKEND "\","
         "\"embedded_api\":\"opengl-next\",\"fel_pixels\":\"not_tested\","
         "\"dv_output\":\"not_tested\"}\n", PL_API_VER, mpv_client_api_version());
  return 0;
}

