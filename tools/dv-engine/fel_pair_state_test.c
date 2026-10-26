#include <float.h>
#include <math.h>
#include <stdio.h>

#include "filters/fel_pair_state.h"

static const double NO_PTS = -DBL_MAX;

static struct mp_fel_pair_input make_input(bool have_el, bool el_eof,
                                           double bl_pts, double el_pts,
                                           int bl_pending)
{
    return (struct mp_fel_pair_input) {
        .have_el = have_el,
        .el_eof = el_eof,
        .bl_pts = bl_pts,
        .el_pts = el_pts,
        .no_pts = NO_PTS,
        .bl_pending = bl_pending,
        .queue_max = 8,
    };
}

static int check(const char *name, struct mp_fel_pair_input input,
                 enum mp_fel_pair_action action,
                 enum mp_fel_pair_reason reason)
{
    struct mp_fel_pair_decision actual = mp_fel_pair_decide(input);
    if (actual.action != action || actual.reason != reason) {
        fprintf(stderr, "%s: got action=%d reason=%d; expected action=%d reason=%d\n",
                name, actual.action, actual.reason, action, reason);
        return 1;
    }
    return 0;
}

int main(void)
{
    int failures = 0;
    if (mp_fel_pts_cmp(1.0, 1.0, NO_PTS) != 0 ||
        mp_fel_pts_cmp(1.0 + 0.5e-6, 1.0, NO_PTS) != 0 ||
        mp_fel_pts_cmp(0.9, 1.0, NO_PTS) >= 0 ||
        mp_fel_pts_cmp(1.1, 1.0, NO_PTS) <= 0 ||
        mp_fel_pts_cmp(NO_PTS, 1.0, NO_PTS) != 2 ||
        mp_fel_pts_cmp(NAN, 1.0, NO_PTS) != 2 ||
        mp_fel_pts_cmp(INFINITY, 1.0, NO_PTS) != 2)
        failures++;

    failures += check("wait for EL", make_input(false, false, 1.0, NO_PTS, 1),
                      MP_FEL_PAIR_WAIT, MP_FEL_PAIR_REASON_NONE);
    failures += check("bounded queue drops BL", make_input(false, false, 1.0, NO_PTS, 8),
                      MP_FEL_PAIR_DROP_BL, MP_FEL_PAIR_REASON_QUEUE_FULL);
    failures += check("EL EOF fails closed", make_input(false, true, 1.0, NO_PTS, 1),
                      MP_FEL_PAIR_FAIL, MP_FEL_PAIR_REASON_EL_EOF);
    failures += check("PTS match", make_input(true, false, 1.0, 1.0 + 0.5e-6, 1),
                      MP_FEL_PAIR_MATCH, MP_FEL_PAIR_REASON_NONE);
    failures += check("stale EL is dropped", make_input(true, false, 1.0, 0.9, 1),
                      MP_FEL_PAIR_DROP_EL, MP_FEL_PAIR_REASON_NONE);
    failures += check("newer EL drops BL", make_input(true, false, 1.0, 1.1, 1),
                      MP_FEL_PAIR_DROP_BL, MP_FEL_PAIR_REASON_NEWER_EL_PTS);
    failures += check("unknown EL PTS fails", make_input(true, false, 1.0, NO_PTS, 1),
                      MP_FEL_PAIR_FAIL, MP_FEL_PAIR_REASON_UNKNOWN_PTS);
    failures += check("unknown BL PTS fails", make_input(true, false, NO_PTS, 1.0, 1),
                      MP_FEL_PAIR_FAIL, MP_FEL_PAIR_REASON_UNKNOWN_PTS);
    failures += check("non-finite BL PTS fails", make_input(true, false, NAN, 1.0, 1),
                      MP_FEL_PAIR_FAIL, MP_FEL_PAIR_REASON_UNKNOWN_PTS);
    failures += check("non-finite EL PTS fails", make_input(true, false, 1.0, INFINITY, 1),
                      MP_FEL_PAIR_FAIL, MP_FEL_PAIR_REASON_UNKNOWN_PTS);
    failures += check("EL EOF after newer PTS fails", make_input(true, true, 1.0, 1.1, 1),
                      MP_FEL_PAIR_FAIL, MP_FEL_PAIR_REASON_EL_EOF);

    if (failures) {
        fprintf(stderr, "%d FEL pair state checks failed\n", failures);
        return 1;
    }
    puts("11 FEL pair decision cases passed");
    return 0;
}
