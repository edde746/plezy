#!/usr/bin/env python3
"""Launch only the explicitly selected experimental engine or app process."""

import argparse
import json
import os
from pathlib import Path

from output_target import playback_arguments


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--app", type=Path, help="A PlezyNG build containing the experimental API selector")
    parser.add_argument("--render-api", choices=("opengl", "opengl-next"),
                        help="Strict app-only override; otherwise the in-app settings choose the renderer")
    parser.add_argument("--tool", choices=("mpv", "ffmpeg", "ffprobe"), default="mpv")
    parser.add_argument("--target", choices=("auto", "hdr10", "sdr"),
                        help="Real-time standalone mpv output conversion; preserves DV reconstruction metadata")
    parser.add_argument("--peak-nits", type=float,
                        help="Known output peak (10..10000); requires an explicit hdr10 or sdr target")
    parser.add_argument("args", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.render_api and not args.app:
        parser.error("--render-api requires --app")
    if (args.target is not None or args.peak_nits is not None) and (args.app or args.tool != "mpv"):
        parser.error("output conversion is for standalone mpv; the app owns its surface color negotiation")
    forwarded = args.args[1:] if args.args[:1] == ["--"] else args.args
    try:
        forwarded = playback_arguments(forwarded, args.target, args.peak_nits)
    except ValueError as error:
        parser.error(str(error))
    root = args.engine.resolve(strict=True)
    lock = json.loads((root / "engine.lock.json").read_text())
    report = json.loads((root / "feature-report.json").read_text())
    if lock.get("render_api") != "opengl-next" or report.get("embedded_api") != "opengl-next":
        parser.error("The directory is not a built, matching experimental engine")
    library = root / "lib/libmpv.so.2"
    if not library.is_file():
        parser.error("Missing experimental libmpv.so.2")
    executable = args.app.resolve(strict=True) if args.app else root / "bin" / args.tool
    env = os.environ.copy()
    # Process-scoped; do not overwrite a production engine or change system paths.
    env["LD_LIBRARY_PATH"] = str(root / "lib") + (
        ":" + env["LD_LIBRARY_PATH"] if env.get("LD_LIBRARY_PATH") else ""
    )
    if args.app:
        # Some app packages use DT_RPATH. Preloading the selected SONAME avoids
        # silently retaining their bundled legacy libmpv. This is experimental.
        env["LD_PRELOAD"] = str(library) + (":" + env["LD_PRELOAD"] if env.get("LD_PRELOAD") else "")
        if args.render_api:
            env["PLEZYNG_EXPERIMENTAL_RENDER_API"] = args.render_api
    os.execve(executable, [str(executable), *forwarded], env)


if __name__ == "__main__":
    main()

