#ifndef MPV_TEXTURE_H_
#define MPV_TEXTURE_H_

#include <flutter_linux/flutter_linux.h>

#include "mpv_player.h"

G_BEGIN_DECLS

#define MPV_TEXTURE_TYPE (mpv_texture_get_type())

G_DECLARE_FINAL_TYPE(MpvTexture, mpv_texture, MPV, TEXTURE, FlTextureGL)

/// Creates a new MpvTexture that renders mpv video to an offscreen FBO.
MpvTexture* mpv_texture_new(mpv::MpvPlayer* player,
                            FlTextureRegistrar* registrar,
                            FlView* view);

/// Notifies Flutter that a new frame is available.
void mpv_texture_mark_frame_available(MpvTexture* self);

/// Cleans up GL resources (FBO/texture).
void mpv_texture_dispose(MpvTexture* self);

/// Returns the Flutter texture ID.
int64_t mpv_texture_get_id(MpvTexture* self);

G_END_DECLS

#endif  // MPV_TEXTURE_H_
