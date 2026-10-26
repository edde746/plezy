"""Small integer reference for ETSI GS CCM 001 v1.1.1 composer primitives.

This module accepts already-normalized composing metadata. It implements the
public polynomial/MMR base-layer mapping, EL NLQ_LINEAR_DZ inverse
quantization, and reconstruction rounding/clipping equations from clauses
5.4.2 and 5.4.3. It does not parse Dolby Vision RPU data or claim that a
Profile 7 CMv2.9/CMv4.0 RPU maps to this metadata model.

Specification: https://www.etsi.org/deliver/etsi_gs/CCM/001_099/001/01.01.01_60/gs_ccm001v010101p.pdf
"""

from collections.abc import Sequence


def _integer(name: str, value: int, minimum: int, maximum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValueError(f"{name} must be an integer")
    if not minimum <= value <= maximum:
        raise ValueError(f"{name} must be between {minimum} and {maximum}")
    return value


def _bit_depth(name: str, value: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value not in (8, 10):
        raise ValueError(f"{name} must be 8 or 10")
    return value


def _validate_coefficient_header(el_bit_depth: int, coefficient_log2_denom: int) -> None:
    _bit_depth("EL bit depth", el_bit_depth)
    _integer("coefficient_log2_denom", coefficient_log2_denom, el_bit_depth + 5, 32)


def derive_pivots(predicted_values: Sequence[int], bit_depth: int) -> tuple[int, ...]:
    """Expand the signalled first pivot and following pivot deltas."""
    _bit_depth("BL bit depth", bit_depth)
    if not isinstance(predicted_values, Sequence) or not 2 <= len(predicted_values) <= 17:
        raise ValueError("predicted_values must contain 2 to 17 pivot values")
    maximum = (1 << bit_depth) - 1
    pivots = []
    for index, value in enumerate(predicted_values):
        value = _integer(f"predicted_values[{index}]", value, 0, maximum)
        pivots.append(value if index == 0 else pivots[-1] + value)
    return tuple(pivots)


def pivot_index(sample: int, pivots: Sequence[int]) -> int:
    """Select the piecewise mapping segment for one BL sample."""
    if not isinstance(pivots, Sequence) or len(pivots) < 2:
        raise ValueError("pivots must contain at least two values")
    if any(isinstance(p, bool) or not isinstance(p, int) for p in pivots):
        raise ValueError("pivots must be integers")
    if any(left > right for left, right in zip(pivots, pivots[1:])):
        raise ValueError("pivots must be nondecreasing")
    _integer("sample", sample, -(1 << 63), (1 << 63) - 1)
    for index in range(len(pivots) - 1):
        if sample < pivots[index + 1]:
            return index
    return len(pivots) - 1


def polynomial_map_sample(
    sample: int,
    pivots: Sequence[int],
    coefficients: Sequence[int],
    *,
    bl_bit_depth: int,
    el_bit_depth: int,
    coefficient_log2_denom: int,
    mapping_index: int = 0,
) -> int:
    """Map one BL sample using normalized fixed-point polynomial coefficients."""
    _bit_depth("BL bit depth", bl_bit_depth)
    _validate_coefficient_header(el_bit_depth, coefficient_log2_denom)
    _integer("sample", sample, 0, (1 << bl_bit_depth) - 1)
    pivot_index(sample, pivots)
    mapping_index = _integer("mapping_index", mapping_index, 0, len(pivots) - 1)
    if not isinstance(coefficients, Sequence) or len(coefficients) not in (2, 3):
        raise ValueError("polynomial coefficients must describe degree one or two")
    if any(isinstance(c, bool) or not isinstance(c, int) for c in coefficients):
        raise ValueError("polynomial coefficients must be integers")

    value = min(max(sample, pivots[0]), pivots[-1])
    total = 0
    power = 1
    shift = 20
    for coefficient in coefficients:
        if shift < 0:
            raise ValueError("polynomial order exceeds the supported fixed-point range")
        total += coefficient * (power << shift)
        power *= value
        shift -= bl_bit_depth
    total = max(total, 0)
    return min(total >> (4 + coefficient_log2_denom), 0xFFFF)


def mmr_map_chroma_sample(
    samples: Sequence[int],
    pivot_ranges: Sequence[Sequence[int]],
    constant: int,
    coefficients: Sequence[Sequence[int]],
    *,
    bl_bit_depth: int,
    el_bit_depth: int,
    coefficient_log2_denom: int,
) -> int:
    """Map one aligned chroma sample using normalized MMR coefficients.

    `samples` contains (possibly downsampled) BL Y, Cb and Cr values. Spatial
    resampling is intentionally outside this per-sample arithmetic function.
    Each pivot sequence covers the full input range for its component; the
    caller selects the coefficients for the sample's pivot index first.
    Coefficient rows correspond to MMR orders 1..3, with seven terms per row.
    """
    _bit_depth("BL bit depth", bl_bit_depth)
    _validate_coefficient_header(el_bit_depth, coefficient_log2_denom)
    if not isinstance(samples, Sequence) or not isinstance(pivot_ranges, Sequence):
        raise ValueError("MMR samples and pivot ranges must be sequences")
    if len(samples) != 3 or len(pivot_ranges) != 3:
        raise ValueError("MMR mapping requires three samples and three pivot ranges")
    maximum = (1 << bl_bit_depth) - 1
    bounded = []
    for index, (sample, pivots) in enumerate(zip(samples, pivot_ranges)):
        _integer(f"samples[{index}]", sample, 0, maximum)
        if len(pivots) < 2 or any(not isinstance(p, int) or isinstance(p, bool) for p in pivots):
            raise ValueError("each pivot range must contain at least two integer values")
        if any(left > right for left, right in zip(pivots, pivots[1:])):
            raise ValueError("pivot ranges must be nondecreasing")
        bounded.append(min(max(sample, pivots[0]), pivots[-1]))
    if not isinstance(coefficients, Sequence) or not 1 <= len(coefficients) <= 3:
        raise ValueError("MMR coefficients must contain one to three order rows")
    if any(len(row) != 7 for row in coefficients):
        raise ValueError("each MMR order row must contain seven coefficients")
    if any(isinstance(c, bool) or not isinstance(c, int) for row in coefficients for c in row):
        raise ValueError("MMR coefficients must be integers")
    _integer("MMR constant", constant, -(1 << 63), (1 << 63) - 1)

    y, cb, cr = bounded
    terms = [0] * 22
    terms[0] = 1 << 20
    if len(coefficients) >= 1:
        terms[1:7] = [
            y << (20 - bl_bit_depth),
            cb << (20 - bl_bit_depth),
            cr << (20 - bl_bit_depth),
            (y * cb) << (20 - 2 * bl_bit_depth),
            (y * cr) << (20 - 2 * bl_bit_depth),
            (cb * cr) << (20 - 2 * bl_bit_depth),
        ]
        terms[7] = (terms[4] * terms[3]) >> 20
    if len(coefficients) >= 2:
        terms[8:15] = [
            (y * y) << (20 - 2 * bl_bit_depth),
            (cb * cb) << (20 - 2 * bl_bit_depth),
            (cr * cr) << (20 - 2 * bl_bit_depth),
            (terms[4] * terms[4]) >> 20,
            (terms[5] * terms[5]) >> 20,
            (terms[6] * terms[6]) >> 20,
            (terms[7] * terms[7]) >> 20,
        ]
    if len(coefficients) >= 3:
        terms[15:22] = [
            (terms[1] * terms[8]) >> 20,
            (terms[2] * terms[9]) >> 20,
            (terms[3] * terms[10]) >> 20,
            (terms[4] * terms[11]) >> 20,
            (terms[5] * terms[12]) >> 20,
            (terms[6] * terms[13]) >> 20,
            (terms[7] * terms[14]) >> 20,
        ]

    total = constant * terms[0]
    term_index = 1
    for row in coefficients:
        for coefficient in row:
            total += coefficient * terms[term_index]
            term_index += 1
    total = max(total, 0)
    return min(total >> (4 + coefficient_log2_denom), 0xFFFF)


def inverse_quantize_el_sample(
    sample: int,
    *,
    nlq_offset: int,
    linear_deadzone_threshold: int,
    linear_deadzone_slope: int,
    hdr_in_max: int,
    el_bit_depth: int,
    coefficient_log2_denom: int,
) -> int:
    """Apply the integer NLQ_LINEAR_DZ inverse quantization process to one EL sample."""
    _bit_depth("EL bit depth", el_bit_depth)
    _validate_coefficient_header(el_bit_depth, coefficient_log2_denom)
    maximum = (1 << el_bit_depth) - 1
    _integer("sample", sample, 0, maximum)
    _integer("nlq_offset", nlq_offset, 0, maximum)
    _integer("linear_deadzone_threshold", linear_deadzone_threshold, 0, (1 << 63) - 1)
    _integer("linear_deadzone_slope", linear_deadzone_slope, 0, (1 << 63) - 1)
    _integer("hdr_in_max", hdr_in_max, 0, (1 << 63) - 1)

    delta = sample - nlq_offset
    if delta == 0:
        return 0

    sign = -1 if delta < 0 else 1
    delta = ((delta << 1) - sign) << (10 - el_bit_depth)
    reconstructed = delta * linear_deadzone_slope
    reconstructed += (linear_deadzone_threshold << (11 - el_bit_depth)) * sign
    maximum_value = hdr_in_max << (11 - el_bit_depth)
    reconstructed = min(max(reconstructed, -maximum_value), maximum_value)
    return reconstructed >> (coefficient_log2_denom - 5 - el_bit_depth)


def reconstruct_sample(
    mapped_bl: int,
    inverse_quantized_el: int,
    *,
    disable_residual: bool,
    output_bit_depth: int,
) -> int:
    """Add an inverse-quantized EL residual, round, and clip one mapped BL sample."""
    _integer("mapped_bl", mapped_bl, 0, 0xFFFF)
    _integer("inverse_quantized_el", inverse_quantized_el, -(1 << 16), (1 << 16) - 1)
    if not isinstance(disable_residual, bool):
        raise ValueError("disable_residual must be a boolean")
    if output_bit_depth not in (10, 12, 14):
        raise ValueError("output_bit_depth must be 10, 12, or 14")

    value = mapped_bl + (0 if disable_residual else inverse_quantized_el)
    value += 1 << (15 - output_bit_depth)
    value >>= 16 - output_bit_depth
    return min(max(value, 0), (1 << output_bit_depth) - 1)
