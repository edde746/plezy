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
#ifndef PL_HAVE_OPENGL
#error the experimental embedding needs libplacebo OpenGL support
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
  printf("{\"dovi_split\":true,\"paired_frame_api\":true,"
         "\"fel_nlq_api\":true,\"libplacebo_api\":%d,\"libmpv_api\":%lu,"
         "\"embedded_api\":\"opengl-next\",\"fel_pixels\":\"not_tested\","
         "\"dv_output\":\"not_tested\"}\n", PL_API_VER, mpv_client_api_version());
  return 0;
}
