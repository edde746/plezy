#pragma once

#include <math.h>
#include <stdbool.h>

#define MP_FEL_PAIR_PTS_TOLERANCE 1e-6

enum mp_fel_pair_action {
    MP_FEL_PAIR_WAIT,
    MP_FEL_PAIR_DROP_EL,
    MP_FEL_PAIR_MATCH,
    MP_FEL_PAIR_DROP_BL,
    MP_FEL_PAIR_FAIL,
};

enum mp_fel_pair_reason {
    MP_FEL_PAIR_REASON_NONE,
    MP_FEL_PAIR_REASON_EL_EOF,
    MP_FEL_PAIR_REASON_UNKNOWN_PTS,
    MP_FEL_PAIR_REASON_NEWER_EL_PTS,
    MP_FEL_PAIR_REASON_QUEUE_FULL,
};

struct mp_fel_pair_input {
    bool have_el;
    bool el_eof;
    double bl_pts;
    double el_pts;
    double no_pts;
    int bl_pending;
    int queue_max;
};

struct mp_fel_pair_decision {
    enum mp_fel_pair_action action;
    enum mp_fel_pair_reason reason;
};

static inline int mp_fel_pts_cmp(double el_pts, double bl_pts, double no_pts)
{
    if (!isfinite(el_pts) || !isfinite(bl_pts) ||
        el_pts == no_pts || bl_pts == no_pts)
        return 2;
    if (el_pts < bl_pts - MP_FEL_PAIR_PTS_TOLERANCE)
        return -1;
    if (el_pts > bl_pts + MP_FEL_PAIR_PTS_TOLERANCE)
        return 1;
    return 0;
}

static inline struct mp_fel_pair_decision
mp_fel_pair_decide(struct mp_fel_pair_input input)
{
    struct mp_fel_pair_decision result = {
        .action = MP_FEL_PAIR_WAIT,
        .reason = MP_FEL_PAIR_REASON_NONE,
    };

    if (input.have_el) {
        int cmp = mp_fel_pts_cmp(input.el_pts, input.bl_pts, input.no_pts);
        if (cmp == 2) {
            result.action = MP_FEL_PAIR_FAIL;
            result.reason = MP_FEL_PAIR_REASON_UNKNOWN_PTS;
            return result;
        }
        if (cmp < 0) {
            result.action = MP_FEL_PAIR_DROP_EL;
            return result;
        }
        if (cmp == 0) {
            result.action = MP_FEL_PAIR_MATCH;
            return result;
        }
        if (input.el_eof) {
            result.action = MP_FEL_PAIR_FAIL;
            result.reason = MP_FEL_PAIR_REASON_EL_EOF;
            return result;
        }
        result.action = MP_FEL_PAIR_DROP_BL;
        result.reason = MP_FEL_PAIR_REASON_NEWER_EL_PTS;
        return result;
    }

    if (input.el_eof) {
        result.action = MP_FEL_PAIR_FAIL;
        result.reason = MP_FEL_PAIR_REASON_EL_EOF;
    } else if (input.bl_pending >= input.queue_max) {
        result.action = MP_FEL_PAIR_DROP_BL;
        result.reason = MP_FEL_PAIR_REASON_QUEUE_FULL;
    }
    return result;
}
