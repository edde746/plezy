"""Real-time display conversion options for the isolated libplacebo renderer.

No encoded intermediate, external LUT, or per-title analysis is needed. These
options describe the OUTPUT; they never retag the source or strip its RPU.
"""

from __future__ import annotations

import math


def render_options(target: str, *, peak_nits: float | None = None) -> list[str]:
    if target not in ("auto", "hdr10", "sdr"):
        raise ValueError("target must be auto, hdr10, or sdr")
    if peak_nits is not None:
        if isinstance(peak_nits, bool) or not isinstance(peak_nits, (int, float)):
            raise ValueError("peak must be a finite number")
        if not math.isfinite(peak_nits) or not 10 <= peak_nits <= 10000:
            raise ValueError("peak must be between 10 and 10000 nits")
        if target == "auto":
            raise ValueError("a peak override requires an explicit output target")
    options = ["--vo=gpu-next", "--tone-mapping=auto", "--gamut-mapping-mode=auto",
               "--hdr-compute-peak=auto"]
    if target == "auto":
        # Let the actual graphics context choose HDR versus SDR. Forcing PQ on
        # a gamma surface would be wrong even when the TV advertises HDR.
        return options + ["--target-colorspace-hint=auto", "--target-trc=auto",
                          "--target-prim=auto", "--target-peak=auto"]
    if target == "sdr":
        peak = 100 if peak_nits is None else peak_nits
        return options + ["--target-colorspace-hint=no", "--target-trc=srgb",
                          "--target-prim=bt.709", f"--target-peak={peak:g}", f"--sdr-peak={peak:g}"]
    peak = "auto" if peak_nits is None else f"{peak_nits:g}"
    # Explicit HDR is an operator request for a known HDR-capable output.
    # Auto peak leaves display mapping to the HDR sink; a supplied peak asks
    # libplacebo to map to that luminance instead.
    return options + ["--target-colorspace-hint=yes", "--target-trc=pq",
                      "--target-prim=bt.2020", f"--target-peak={peak}"]


def playback_arguments(forwarded: list[str], target: str | None,
                       peak_nits: float | None = None) -> list[str]:
    if target is None:
        if peak_nits is not None:
            raise ValueError("--peak-nits requires --target")
        return forwarded
    # A named target must not be silently undone by later mpv arguments.
    # Filters/profiles/configs can change the source representation too, so
    # this controlled path does not load them. Use the ordinary launcher for
    # custom shader/filter experiments.
    managed = ("vo", "config", "include", "profile", "vf", "lavfi-complex",
               "glsl-shaders", "lut", "icc-profile", "target-", "tone-mapping",
               "gamut-mapping", "hdr-compute-peak", "sdr-peak")
    for argument in forwarded:
        if argument == "--":
            break
        if not argument.startswith("--"):
            continue
        key = argument[2:].split("=", 1)[0]
        if key.startswith("no-"):
            key = key[3:]
        if any(key == name or key.startswith(name + "-") or
               (name.endswith("-") and key.startswith(name)) for name in managed):
            raise ValueError(f"{argument.split('=', 1)[0]} conflicts with managed output conversion")
    return ["--no-config", *render_options(target, peak_nits=peak_nits), *forwarded]
