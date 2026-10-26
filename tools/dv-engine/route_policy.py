#!/usr/bin/env python3
"""Portable route selection for experimental adapters; never an OS capability guess.

Input source is one video_streams entry from scripts/dv_lab.py inspect. Adapter
capabilities are session-local observations for an exact device/driver/display/
engine fingerprint. They are not downloaded code or permission to install it.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROUTES = ("native-fel", "local-fel", "companion", "native", "p81", "reshape", "tone-map", "base")
FEL_EVIDENCE = frozenset(("bl_decode", "el_decode", "residual", "pairing", "reference_pixels"))
BASE_OUTPUTS = {"hdr10": "hdr10", "hlg": "hlg", "sdr": "sdr"}


def choose(source: dict, adapters: list[dict], *, fingerprint: str,
           mode: str = "auto", failed: tuple[str, ...] = (),
           display_outputs: tuple[str, ...] | None = None, target: str = "auto") -> dict:
    if mode not in ("auto", "compatibility", "experimental", "strict-fel"):
        raise ValueError("unknown playback mode")
    if not isinstance(source, dict) or not isinstance(adapters, list):
        raise ValueError("source must be an object and adapters a list")
    if not isinstance(fingerprint, str) or not fingerprint or len(adapters) > 64:
        raise ValueError("a current fingerprint and at most 64 adapters are required")
    outputs = {"dolby-vision", "hdr10", "hlg", "edr", "scrgb", "sdr"}
    if target not in ("auto", "hdr10", "sdr"):
        raise ValueError("unknown output target")
    if display_outputs is not None and (
            not isinstance(display_outputs, (list, tuple)) or not display_outputs or
            any(not isinstance(value, str) or value not in outputs for value in display_outputs)):
        raise ValueError("display_outputs must contain recognized output formats")
    cfg = source.get("dv_configuration") or {}
    if not isinstance(cfg, dict):
        raise ValueError("dv_configuration must be an object")
    profile = cfg.get("dv_profile")
    if source.get("issues") or type(profile) is not int:
        return {"route": None, "reason": "source_requires_inspection", "rejected": []}
    base = source.get("base_layer_compatibility", "unknown")
    # A caller's incorrect compatibility label must never make P5 plain HDR10.
    valid_base = base in BASE_OUTPUTS and profile != 5
    if profile == 7:
        valid_base = base == "hdr10"
    if profile == 8 and "dv_bl_signal_compatibility_id" in cfg:
        valid_base = base == {1: "hdr10", 2: "sdr", 4: "hlg"}.get(cfg["dv_bl_signal_compatibility_id"])

    accepted, rejected = [], []
    seen = set()
    for adapter in adapters:
        if (not isinstance(adapter, dict) or not isinstance(adapter.get("profiles", []), list)
                or not isinstance(adapter.get("evidence", {}), dict)):
            raise ValueError("adapter, profiles or evidence has an invalid type")
        identity, kind = adapter.get("id"), adapter.get("route")
        reason = None
        if not isinstance(identity, str) or not identity or identity in seen:
            raise ValueError("adapter ids must be unique nonempty strings")
        seen.add(identity)
        if kind not in ROUTES:
            reason = "unknown_route"
        elif identity in failed:
            reason = "already_failed_this_session"
        elif adapter.get("fingerprint") != fingerprint:
            reason = "stale_capability"
        elif adapter.get("available") is not True or profile not in adapter.get("profiles", []):
            reason = "unavailable_for_source"
        elif adapter.get("output") not in outputs:
            reason = "output_unspecified"
        elif display_outputs is not None and adapter["output"] not in display_outputs:
            reason = "display_output_unsupported"
        elif target != "auto" and adapter["output"] != target:
            reason = "requested_output_mismatch"
        elif kind == "reshape" and (profile not in (5, 7, 8) or cfg.get("rpu_present_flag") != 1):
            reason = "reshaping_requires_supported_profile_and_rpu"
        elif kind == "tone-map" and (not valid_base or adapter.get("evidence", {}).get("color_conversion") is not True):
            reason = "conversion_requires_compatible_base_and_renderer"
        elif kind == "p81" and (profile != 7 or base != "hdr10"):
            reason = "p81_requires_hdr10_compatible_p7"
        elif kind == "base" and (not valid_base or adapter["output"] != base):
            reason = "base_is_not_a_valid_output"
        elif kind == "companion" and adapter.get("ready") is not True:
            reason = "companion_not_ready"

        evidence = adapter.get("evidence", {})
        qualified_fel = (profile == 7 and cfg.get("el_present_flag") == 1 and
                         all(evidence.get(key) is True for key in FEL_EVIDENCE))
        full = kind in ("native-fel", "local-fel")
        derived = kind == "companion" and qualified_fel
        if not reason and full and (profile != 7 or cfg.get("el_present_flag") != 1):
            reason = "no_p7_enhancement_layer"
        if not reason and mode == "strict-fel" and not (qualified_fel and (full or derived)):
            reason = "fel_not_qualified"
        if not reason and mode == "compatibility" and full:
            reason = "compatibility_selected"
        if not reason and (adapter.get("experimental") is True or (full and not qualified_fel)):
            if mode not in ("experimental", "strict-fel"):
                reason = "experiment_requires_opt_in"
        if reason:
            rejected.append({"id": identity, "reason": reason})
            continue
        # Qualified/local reconstructions precede a native route that cannot
        # establish residual use. An unfinished companion never delays play.
        rank = ROUTES.index(kind)
        if kind == "companion" and not derived:
            rank = ROUTES.index("base")
        accepted.append((rank, identity, {
            "adapter": identity, "route": kind, "output": adapter["output"],
            "enhancement": "reconstructed" if full and qualified_fel else
                           "derived" if derived else
                           "experimental_unverified" if full else
                           "discarded" if profile == 7 and kind in ("p81", "base", "tone-map", "reshape") else "unknown",
            "physical_dv_verified": adapter["output"] == "dolby-vision" and
                                    evidence.get("physical_dv") is True,
        }))
    if not accepted:
        return {"route": None, "reason": "no_safe_available_route", "rejected": rejected}
    accepted.sort(key=lambda item: (item[0], item[1]))
    return {**accepted[0][2], "reason": "selected", "rejected": rejected,
            "alternatives": [item[2]["adapter"] for item in accepted[1:]]}


def read_report(path: Path) -> dict:
    with path.open("rb") as stream:
        raw = stream.read(1024 * 1024 + 1)
    if len(raw) > 1024 * 1024:
        raise ValueError("report exceeds 1 MiB")
    result = json.loads(raw)
    if not isinstance(result, dict):
        raise ValueError("report must be an object")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path, help="source, adapters and fingerprint JSON")
    parser.add_argument("--mode", choices=("auto", "compatibility", "experimental", "strict-fel"), default="auto")
    parser.add_argument("--target", choices=("auto", "hdr10", "sdr"), default="auto")
    parser.add_argument("--failed", action="append", default=[])
    args = parser.parse_args()
    try:
        report = read_report(args.report)
        result = choose(report["source"], report["adapters"], fingerprint=report["fingerprint"],
                        mode=args.mode, failed=tuple(args.failed),
                        display_outputs=report.get("display_outputs"), target=args.target)
    except (KeyError, TypeError, ValueError) as error:
        parser.error(str(error))
    print(json.dumps(result, indent=2))
    return 0 if result["route"] else 2


if __name__ == "__main__":
    raise SystemExit(main())

