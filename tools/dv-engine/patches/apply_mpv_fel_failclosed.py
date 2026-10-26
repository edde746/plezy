#!/usr/bin/env python3
"""Apply the experiment's fail-closed FEL integration to its pinned mpv fork."""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess


EXPECTED_COMMIT = "16563d120f3260cdc0beb1b07f199818fc32dd8c"


def replace_once(root: Path, relative: str, old: str, new: str) -> None:
    path = root / relative
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"Expected one pinned source match in {relative}, found {count}")
    path.write_text(text.replace(old, new, 1))


def apply(root: Path) -> None:
    root = root.resolve(strict=True)
    head = subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=root, check=True,
        text=True, stdout=subprocess.PIPE,
    ).stdout.strip()
    if head != EXPECTED_COMMIT:
        raise SystemExit(f"Refusing to patch unexpected mpv source: {head}")

    replace_once(
        root, "filters/f_enhancement_pair.c",
        "#include <libavutil/buffer.h>\n",
        "#include <libavutil/buffer.h>\n\n#include <math.h>\n\n#include <libplacebo/colorspace.h>\n",
    )
    replace_once(
        root, "filters/f_enhancement_pair.c",
        "    bool bl_eof;\n    bool el_eof;\n    bool el_seen;\n",
        "    bool bl_eof;\n    bool el_eof;\n    bool failed;\n    bool failure_eof_sent;\n    bool warned_unmatched;\n    bool warned_invalid_pair;\n",
    )
    replace_once(
        root, "filters/f_enhancement_pair.c",
        """static int pts_cmp(double a, double b)
{
    if (a == MP_NOPTS_VALUE || b == MP_NOPTS_VALUE)
        return 0;
    if (a < b - PTS_MATCH_TOLERANCE) return -1;
    if (a > b + PTS_MATCH_TOLERANCE) return  1;
    return 0;
}
""",
        """static int pts_cmp(double a, double b)
{
    if (!isfinite(a) || !isfinite(b) ||
        a == MP_NOPTS_VALUE || b == MP_NOPTS_VALUE)
        return 2; // Unknown PTS can never certify a frame pair.
    if (a < b - PTS_MATCH_TOLERANCE) return -1;
    if (a > b + PTS_MATCH_TOLERANCE) return  1;
    return 0;
}
""",
    )
    replace_once(
        root, "filters/f_enhancement_pair.c",
        """static void inherit_dovi_from_el(struct mp_image *bl, struct mp_image *el)
{
    if (bl->params.no_dovi || bl->dovi || !el->dovi)
        return;
    bl->dovi = av_buffer_ref(el->dovi);
    if (!bl->dovi)
        return;
    bl->params.repr.dovi = (void *)bl->dovi->data;
    bl->params.repr.sys = el->params.repr.sys;
    bl->params.color.primaries = el->params.color.primaries;
    bl->params.color.transfer = el->params.color.transfer;
    bl->params.color.hdr.min_luma = el->params.color.hdr.min_luma;
    bl->params.color.hdr.max_luma = el->params.color.hdr.max_luma;
    bl->params.color.hdr.max_pq_y = el->params.color.hdr.max_pq_y;
    bl->params.color.hdr.avg_pq_y = el->params.color.hdr.avg_pq_y;
}
""",
        """static bool inherit_dovi_from_el(struct mp_image *bl, struct mp_image *el)
{
    if (bl->params.no_dovi)
        return false;
    if (bl->params.repr.sys == PL_COLOR_SYSTEM_DOLBYVISION &&
        bl->params.repr.dovi)
        return true;
    if (bl->dovi)
        return false; // Do not overwrite ambiguous BL metadata ownership.
    if (!el->dovi || !el->params.repr.dovi ||
        el->params.repr.sys != PL_COLOR_SYSTEM_DOLBYVISION)
        return false;
    bl->dovi = av_buffer_ref(el->dovi);
    if (!bl->dovi)
        return false;
    bl->params.repr.dovi = (void *)bl->dovi->data;
    bl->params.repr.sys = el->params.repr.sys;
    bl->params.color.primaries = el->params.color.primaries;
    bl->params.color.transfer = el->params.color.transfer;
    bl->params.color.hdr.min_luma = el->params.color.hdr.min_luma;
    bl->params.color.hdr.max_luma = el->params.color.hdr.max_luma;
    bl->params.color.hdr.max_pq_y = el->params.color.hdr.max_pq_y;
    bl->params.color.hdr.avg_pq_y = el->params.color.hdr.avg_pq_y;
    return true;
}
""",
    )
    replace_once(
        root, "filters/f_enhancement_pair.c",
        """static void pair_process(struct mp_filter *f)
{
    struct priv *p = f->priv;
    struct mp_pin *in = f->ppins[0];
    struct mp_pin *out = f->ppins[1];

    drain_pin(f, in, &p->bl_pending, &p->num_bl_pending, &p->bl_eof);
    drain_pin(f, p->el_in, &p->el_pending, &p->num_el_pending, &p->el_eof);
    if (p->num_el_pending > 0)
        p->el_seen = true;

    while (mp_pin_in_needs_data(out)) {
        if (p->num_bl_pending == 0) {
            if (p->bl_eof) {
                while (p->num_el_pending)
                    pop_head(&p->el_pending, &p->num_el_pending);
                mp_pin_in_write(out, MP_EOF_FRAME);
            }
            return;
        }

        struct mp_image *bl = p->bl_pending[0];
        int cmp = p->num_el_pending > 0
                ? pts_cmp(p->el_pending[0]->pts, bl->pts) : 0;

        // EL older than BL: its BL partner already left or never arrived.
        if (p->num_el_pending > 0 && cmp < 0) {
            MP_VERBOSE(f, "dropping stale EL %.6f (oldest BL %.6f)\\n",
                       p->el_pending[0]->pts, bl->pts);
            pop_head(&p->el_pending, &p->num_el_pending);
            continue;
        }

        if (p->num_el_pending > 0 && cmp == 0) {
            struct mp_image *el = take_head(&p->el_pending, &p->num_el_pending);
            take_head(&p->bl_pending, &p->num_bl_pending);
            inherit_dovi_from_el(bl, el);
            if (bl->params.no_enhancement_layer) {
                talloc_free(el);
            } else {
                bl->enhancement_layer = el;
            }
            mp_pin_in_write(out, MAKE_FRAME(MP_FRAME_VIDEO, bl));
            continue;
        }

        // No EL match for the oldest BL. Hold BL unless we have affirmative
        // evidence no EL is coming.
        bool give_up = p->el_eof ||
                       (p->num_el_pending > 0 && cmp > 0) ||
                       (p->num_bl_pending >= QUEUE_MAX && p->el_seen);
        if (!give_up)
            return;

        MP_VERBOSE(f, "emitting BL %.6f alone (%s; bl_pending=%d el_pending=%d"
                   " el head %.6f)\\n", bl->pts,
                   p->el_eof ? "el_eof" :
                   (p->num_el_pending > 0 && cmp > 0) ? "el_newer" : "queue_full",
                   p->num_bl_pending, p->num_el_pending,
                   p->num_el_pending > 0 ? p->el_pending[0]->pts : -1.0);

        take_head(&p->bl_pending, &p->num_bl_pending);
        bl->enhancement_layer = NULL;
        mp_pin_in_write(out, MAKE_FRAME(MP_FRAME_VIDEO, bl));
    }
}
""",
        """static void pair_process(struct mp_filter *f)
{
    struct priv *p = f->priv;
    struct mp_pin *in = f->ppins[0];
    struct mp_pin *out = f->ppins[1];

    if (p->failed) {
        if (!p->failure_eof_sent && mp_pin_in_needs_data(out)) {
            mp_pin_in_write(out, MP_EOF_FRAME);
            p->failure_eof_sent = true;
        }
        return;
    }

    drain_pin(f, in, &p->bl_pending, &p->num_bl_pending, &p->bl_eof);
    drain_pin(f, p->el_in, &p->el_pending, &p->num_el_pending, &p->el_eof);

    while (mp_pin_in_needs_data(out)) {
        if (p->num_bl_pending == 0) {
            if (p->bl_eof) {
                while (p->num_el_pending)
                    pop_head(&p->el_pending, &p->num_el_pending);
                mp_pin_in_write(out, MP_EOF_FRAME);
            }
            return;
        }

        struct mp_image *bl = p->bl_pending[0];
        bool have_el = p->num_el_pending > 0;
        int cmp = have_el ? pts_cmp(p->el_pending[0]->pts, bl->pts) : 2;

        // EL older than BL: its BL partner already left or never arrived.
        if (have_el && cmp < 0) {
            MP_VERBOSE(f, "dropping stale EL %.6f (oldest BL %.6f)\\n",
                       p->el_pending[0]->pts, bl->pts);
            pop_head(&p->el_pending, &p->num_el_pending);
            continue;
        }

        if (have_el && cmp == 0) {
            struct mp_image *el = take_head(&p->el_pending, &p->num_el_pending);
            take_head(&p->bl_pending, &p->num_bl_pending);
            if (bl->params.no_enhancement_layer || !inherit_dovi_from_el(bl, el)) {
                if (!p->warned_invalid_pair) {
                    MP_ERR(f, "Matched BL/EL frames lack usable Dolby Vision metadata; "
                              "dropping the frame instead of claiming FEL.\\n");
                    p->warned_invalid_pair = true;
                }
                talloc_free(el);
                talloc_free(bl);
                continue;
            }
            bl->enhancement_layer = el;
            mp_pin_in_write(out, MAKE_FRAME(MP_FRAME_VIDEO, bl));
            continue;
        }

        // Unknown PTS never means equal. Keep the queues bounded, then drop
        // unmatched BL frames instead of pairing by packet order or rendering
        // them without their required enhancement data.
        bool give_up = p->el_eof || (have_el && cmp > 0) ||
                       p->num_bl_pending >= QUEUE_MAX;
        if (!give_up)
            return;

        const char *reason = p->el_eof ? "EL EOF" :
                             (have_el && cmp > 0) ? "newer EL PTS" :
                             (have_el && cmp == 2) ? "unknown PTS" :
                             "bounded pairing queue";
        if (!p->warned_unmatched) {
            MP_WARN(f, "Dropping unmatched BL frame (%.6f; %s); "
                       "base-layer-only output is disabled for this FEL experiment.\\n",
                    bl->pts, reason);
            p->warned_unmatched = true;
        }
        pop_head(&p->bl_pending, &p->num_bl_pending);
    }
}
""",
    )
    replace_once(
        root, "filters/f_enhancement_pair.c",
        """    p->bl_eof = false;
    p->el_eof = false;
    p->el_seen = false;
""",
        """    p->bl_eof = false;
    p->el_eof = false;
    p->failure_eof_sent = false;
    p->warned_unmatched = false;
    p->warned_invalid_pair = false;
""",
    )
    replace_once(
        root, "filters/f_enhancement_pair.c",
        """struct mp_filter *mp_enhancement_pair_create(struct mp_filter *parent,
                                             struct sh_stream *el_sh)
{
    if (!el_sh)
        return NULL;

    struct mp_filter *f = mp_filter_create(parent, &pair_filter);
    if (!f)
        return NULL;
    mp_filter_add_pin(f, MP_PIN_IN,  "in");
    mp_filter_add_pin(f, MP_PIN_OUT, "out");

    struct priv *p = f->priv;
    p->el_dec = mp_decoder_wrapper_create(f, el_sh);
    if (p->el_dec)
        mp_decoder_wrapper_set_extra_hw_frames(p->el_dec, QUEUE_MAX);
    if (!p->el_dec || !mp_decoder_wrapper_reinit(p->el_dec)) {
        MP_WARN(f, "Failed to set up enhancement-layer decoder; "
                "rendering base layer only.\\n");
        talloc_free(f);
        return NULL;
    }
    p->el_in = p->el_dec->f->pins[0];
    mp_pin_set_manual_connection_for(p->el_in, f);

    return f;
}
""",
        """struct mp_filter *mp_enhancement_pair_create(struct mp_filter *parent,
                                             struct sh_stream *el_sh,
                                             bool require_el)
{
    if (!el_sh && !require_el)
        return NULL;

    struct mp_filter *f = mp_filter_create(parent, &pair_filter);
    if (!f)
        return NULL;
    mp_filter_add_pin(f, MP_PIN_IN,  "in");
    mp_filter_add_pin(f, MP_PIN_OUT, "out");

    struct priv *p = f->priv;
    if (!el_sh) {
        p->failed = true;
        MP_ERR(f, "Dolby Vision declares an enhancement layer but no EL stream "
                  "is available; refusing base-layer-only playback.\\n");
        return f;
    }

    p->el_dec = mp_decoder_wrapper_create(f, el_sh);
    if (p->el_dec)
        mp_decoder_wrapper_set_extra_hw_frames(p->el_dec, QUEUE_MAX);
    if (!p->el_dec || !mp_decoder_wrapper_reinit(p->el_dec)) {
        MP_ERR(f, "Failed to set up enhancement-layer decoder; "
                  "refusing base-layer-only playback.\\n");
        p->failed = true;
        return f;
    }
    p->el_in = p->el_dec->f->pins[0];
    mp_pin_set_manual_connection_for(p->el_in, f);

    return f;
}
""",
    )
    replace_once(
        root, "filters/f_enhancement_pair.h",
        """// Enhancement-layer pairing filter.
//
// Reads base-layer (BL) mp_image frames from its input pin, decodes the
// enhancement-layer (EL) stream `el_sh` via an internal mp_decoder_wrapper,
// and attaches each decoded EL frame as `mpi->enhancement_layer` of the BL
// frame with the matching PTS. Unmatched BL frames are forwarded unchanged
// (BL-only fallback).
//
// `el_sh` must be a dependent sibling of the BL stream via sh_stream_group,
// it is auto-selected by the demuxer when the BL is selected.
//
// 1 input pin (BL frames), 1 output pin (paired BL frames). Returns NULL
// on init failure. The caller should fall back to BL-only rendering.
struct mp_filter *mp_enhancement_pair_create(struct mp_filter *parent,
                                             struct sh_stream *el_sh);
""",
        """// Enhancement-layer pairing filter for the isolated FEL experiment.
//
// Reads BL and EL frames, requires valid matching PTS values and Dolby Vision
// metadata, and attaches each EL to its BL. Unmatched or unpairable BL frames
// are dropped. Missing EL streams or decoder setup failures produce EOF rather
// than a silent base-layer-only result.
struct mp_filter *mp_enhancement_pair_create(struct mp_filter *parent,
                                             struct sh_stream *el_sh,
                                             bool require_el);
""",
    )
    replace_once(
        root, "filters/f_output_chain.h",
        """// Add an enhancement-layer pairing filter at the tail of the chain.
// Pass el_sh=NULL to remove. No-op if the same el_sh is already installed.
struct sh_stream;
void mp_output_chain_set_el_stream(struct mp_output_chain *p,
                                   struct sh_stream *el_sh);
""",
        """// Add a fail-closed enhancement-layer pairing filter at the tail.
// `required` also covers interleaved P7 sources whose splitter failed.
struct sh_stream;
void mp_output_chain_set_el_stream(struct mp_output_chain *p,
                                   struct sh_stream *el_sh, bool required);
""",
    )
    replace_once(
        root, "filters/f_output_chain.c",
        """    struct mp_user_filter *el_pair;
    struct sh_stream *el_sh;
""",
        """    struct mp_user_filter *el_pair;
    struct sh_stream *el_sh;
    bool el_required;
    bool el_failure_eof_sent;
""",
    )
    replace_once(
        root, "filters/f_output_chain.c",
        """static void output_chain_process(struct mp_filter *f)
{
    struct chain *p = f->priv;

""",
        """static void output_chain_process(struct mp_filter *f)
{
    struct chain *p = f->priv;

    if (p->el_required && !p->el_pair) {
        if (!p->el_failure_eof_sent && mp_pin_in_needs_data(f->ppins[1])) {
            MP_ERR(p, "Required Dolby Vision enhancement-layer pairing is "
                      "unavailable; refusing base-layer-only output.\\n");
            mp_pin_in_write(f->ppins[1], MP_EOF_FRAME);
            p->public.got_output_eof = true;
            p->el_failure_eof_sent = true;
        }
        return;
    }

""",
    )
    replace_once(
        root, "filters/f_output_chain.c",
        """    p->public.ao_needs_update = false;

    p->public.got_output_eof = false;
""",
        """    p->public.ao_needs_update = false;

    p->public.got_output_eof = false;
    p->el_failure_eof_sent = false;
""",
    )
    replace_once(
        root, "filters/f_output_chain.c",
        """void mp_output_chain_set_el_stream(struct mp_output_chain *c,
                                   struct sh_stream *el_sh)
{
    struct chain *p = c->f->priv;

    mp_assert(p->type == MP_OUTPUT_CHAIN_VIDEO);

    if (p->el_sh == el_sh && (!el_sh || p->el_pair))
        return;

    if (p->el_pair) {
        for (int n = 0; n < p->num_post_filters; n++) {
            if (p->post_filters[n] == p->el_pair) {
                MP_TARRAY_REMOVE_AT(p->post_filters, p->num_post_filters, n);
                break;
            }
        }
        talloc_free(p->el_pair->wrapper);
        p->el_pair = NULL;
        p->el_sh = NULL;
    }

    if (el_sh) {
        struct mp_user_filter *u = create_wrapper_filter(p);
        u->name = "el_pair";
        u->f = mp_enhancement_pair_create(u->wrapper, el_sh);
        if (!u->f) {
            MP_WARN(p, "Failed to set up enhancement-layer pairing.\\n");
            talloc_free(u->wrapper);
        } else {
            MP_TARRAY_APPEND(p, p->post_filters, p->num_post_filters, u);
            p->el_pair = u;
            p->el_sh = el_sh;
        }
    }

    relink_filter_list(p);
}
""",
        """void mp_output_chain_set_el_stream(struct mp_output_chain *c,
                                   struct sh_stream *el_sh, bool required)
{
    struct chain *p = c->f->priv;
    bool fail_closed = required || el_sh != NULL;

    mp_assert(p->type == MP_OUTPUT_CHAIN_VIDEO);

    if (p->el_sh == el_sh && p->el_required == fail_closed &&
        (!fail_closed || p->el_pair))
        return;

    if (p->el_pair) {
        for (int n = 0; n < p->num_post_filters; n++) {
            if (p->post_filters[n] == p->el_pair) {
                MP_TARRAY_REMOVE_AT(p->post_filters, p->num_post_filters, n);
                break;
            }
        }
        talloc_free(p->el_pair->wrapper);
        p->el_pair = NULL;
    }

    p->el_sh = el_sh;
    p->el_required = fail_closed;
    p->el_failure_eof_sent = false;

    if (el_sh || fail_closed) {
        struct mp_user_filter *u = create_wrapper_filter(p);
        if (u) {
            u->name = "el_pair";
            u->f = mp_enhancement_pair_create(u->wrapper, el_sh, fail_closed);
        }
        if (!u || !u->f) {
            MP_ERR(p, "Failed to create the required enhancement-layer "
                      "pairing filter; output will stop rather than use BL alone.\\n");
            if (u)
                talloc_free(u->wrapper);
        } else {
            MP_TARRAY_APPEND(p, p->post_filters, p->num_post_filters, u);
            p->el_pair = u;
        }
    }

    relink_filter_list(p);
}
""",
    )
    replace_once(
        root, "player/loadfile.c",
        """    struct track *track = mpctx->current_track[0][STREAM_VIDEO];
    mp_output_chain_set_el_stream(mpctx->vo_chain->filter,
        track ? sh_stream_dependent_sibling(track->stream) : NULL);
""",
        """    struct track *track = mpctx->current_track[0][STREAM_VIDEO];
    struct sh_stream *bl = track ? track->stream : NULL;
    struct sh_stream *el = bl ? sh_stream_dependent_sibling(bl) : NULL;
    bool el_required = bl && bl->codec && bl->codec->dv_el_present;
    mp_output_chain_set_el_stream(mpctx->vo_chain->filter, el, el_required);
""",
    )
    replace_once(
        root, "demux/demux_lavf.c",
        """    if (!el_sh || !bl_sh)
        return;

    // Group storage is attached to the BL so its lifetime tracks the demuxer.
""",
        """    if (!el_sh || !bl_sh || !bl_sh->codec)
        return;

    // This is a Dolby Vision layer group. Preserve the requirement on the BL
    // track so failures cannot be mistaken for an ordinary single-layer stream.
    bl_sh->codec->dv_el_present = true;

    // Group storage is attached to the BL so its lifetime tracks the demuxer.
""",
    )
    replace_once(
        root, "video/out/gpu_next/video.c",
        """        } else {
            MP_WARN(p, "Failed setting up enhancement layer; "
                    "rendering base layer only.\\n");
        }
""",
        """        } else {
            MP_ERR(p, "Failed setting up enhancement layer; "
                      "refusing base-layer-only output.\\n");
            for (int i = 0; i < MP_ARRAY_SIZE(fp->el_tex); i++) {
                if (fp->el_tex[i])
                    pl_tex_destroy(gpu, &fp->el_tex[i]);
            }
            talloc_free(mpi);
            return false;
        }
""",
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mpv_source", type=Path)
    args = parser.parse_args()
    apply(args.mpv_source)


if __name__ == "__main__":
    main()
