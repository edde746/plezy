#!/usr/bin/env python3
"""Regenerates the DTS-HD MA packer fixtures (#1988).

FFmpeg has no DTS-HD MA encoder, so the access-unit fixture is synthesized: real
DTS core frames from FFmpeg's `dca` encoder, each followed by a hand-built
extension substream (EXSS) whose header fields are coherent enough for FFmpeg's
DCA parser to glue core+EXSS into one access unit. The IEC 61937 wrapping never
inspects EXSS payload bytes, only the sync word and size fields, so this pins
the same wire format genuine Master Audio does.

One mid-stream access unit is oversized so `ffmpeg -f spdif` overflows the
burst and strips to core-only for `dtshd_fallback_time` (60s, i.e. the rest of
the fixture) — the golden therefore also pins the strip-and-hold behavior.

Usage (from this directory):
    ffmpeg -y -f lavfi -i "aevalsrc=0.3*sin(2*PI*440*t)|0.3*sin(2*PI*554*t)|0.3*sin(2*PI*659*t)|0.2*sin(2*PI*220*t)|0.25*sin(2*PI*330*t)|0.25*sin(2*PI*392*t):s=48000:d=0.15" \
        -c:a dca -strict experimental -f dts /tmp/dts_core.dts
    python3 dtshd_fixture_generator.py /tmp/dts_core.dts
    ffmpeg -y -f dts -i dtshd_ma_access_units.bin -c:a copy \
        -f spdif -dtshd_rate 768000 dtshd_ma_iec61937_golden.bin
"""

import struct
import sys

CORE_SYNC = 0x7FFE8001
EXSS_SYNC = 0x64582025

# Payload bytes past which a 32768-byte burst (512 samples at 48kHz on the
# 768kHz HBR carrier) overflows: 32768 - 8 preamble - 12 start code/length.
BURST_CAPACITY = 32768 - 8 - 12
NORMAL_EXSS_SIZE = 2020
# Large enough that core (1884) + EXSS exceeds the burst capacity.
OVERSIZED_EXSS_SIZE = BURST_CAPACITY
OVERSIZED_AU_INDEX = 4


def build_exss(size: int) -> bytes:
    """A minimal EXSS frame: sync, then the narrow (bHeaderSizeType=0) header.

    Bit layout after the 32-bit sync: UserDefinedBits(8), nExtSSIndex(2),
    bHeaderSizeType(1), nuBits4Header(8) = header bytes - 1,
    nuBits4ExSSFsize(16) = frame bytes - 1. Everything else is padding the
    parser and packer never read.
    """
    header_size = 16
    bits = 0
    bits = (bits << 8) | 0          # UserDefinedBits
    bits = (bits << 2) | 0          # nExtSSIndex
    bits = (bits << 1) | 0          # bHeaderSizeType
    bits = (bits << 8) | (header_size - 1)
    bits = (bits << 16) | (size - 1)
    packed = bits.to_bytes(5, "big")  # 35 bits, left-aligned below
    body = bytearray(size)
    struct.pack_into(">I", body, 0, EXSS_SYNC)
    shifted = int.from_bytes(packed, "big") << (40 - 35)
    body[4:9] = shifted.to_bytes(5, "big")
    return bytes(body)


def main() -> None:
    core = open(sys.argv[1], "rb").read()
    out = bytearray()
    offset = 0
    index = 0
    while offset + 9 <= len(core):
        sync = struct.unpack_from(">I", core, offset)[0]
        assert sync == CORE_SYNC, hex(sync)
        b24 = (core[offset + 5] << 16) | (core[offset + 6] << 8) | core[offset + 7]
        fsize = ((b24 >> 4) & 0x3FFF) + 1
        out += core[offset : offset + fsize]
        exss_size = OVERSIZED_EXSS_SIZE if index == OVERSIZED_AU_INDEX else NORMAL_EXSS_SIZE
        out += build_exss(exss_size)
        offset += fsize
        index += 1
    open("dtshd_ma_access_units.bin", "wb").write(out)
    print(f"{index} access units, {len(out)} bytes")


if __name__ == "__main__":
    main()
