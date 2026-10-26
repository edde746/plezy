"""Normalize one dovi_tool Profile 7 FEL RPU into CCM reference inputs.

This adapter covers RPU inverse-mapping curves and NLQ residual parameters.
It does not implement Dolby display management, RGB conversion, spatial
resampling, frame pairing, or the platform renderer.
"""

from collections.abc import Mapping, Sequence
from dataclasses import dataclass

from ccm_reference import (
    derive_pivots,
    inverse_quantize_el_sample,
    mmr_map_chroma_sample,
    polynomial_map_sample,
    reconstruct_sample as reconstruct_ccm_sample,
    rpu_mapping_piece_index,
)


def _mapping(name: str, value: object) -> Mapping[str, object]:
    if not isinstance(value, Mapping):
        raise ValueError(f"{name} must be an object")
    return value


def _array(name: str, value: object) -> Sequence[object]:
    if not isinstance(value, (list, tuple)):
        raise ValueError(f"{name} must be an array")
    return value


def _integer(name: str, value: object, minimum: int, maximum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValueError(f"{name} must be an integer")
    if not minimum <= value <= maximum:
        raise ValueError(f"{name} must be between {minimum} and {maximum}")
    return value


def _boolean(name: str, value: object) -> bool:
    if not isinstance(value, bool):
        raise ValueError(f"{name} must be a boolean")
    return value


def _integer_array(name: str, value: object, count: int) -> tuple[int, ...]:
    array = _array(name, value)
    if len(array) != count:
        raise ValueError(f"{name} must contain {count} values")
    return tuple(_integer(f"{name}[{i}]", item, -(1 << 63), (1 << 63) - 1) for i, item in enumerate(array))


def _fraction_array(name: str, value: object, count: int, denominator: int) -> tuple[int, ...]:
    array = _array(name, value)
    if len(array) != count:
        raise ValueError(f"{name} must contain {count} values")
    maximum = (1 << denominator) - 1
    return tuple(_integer(f"{name}[{i}]", item, 0, maximum) for i, item in enumerate(array))


def _fixed_coefficients(
    name: str,
    integer_values: object,
    fractional_values: object,
    count: int,
    denominator: int,
    *,
    coefficient_data_type: int,
    signed_integer: bool,
) -> tuple[int, ...]:
    fractions = _fraction_array(
        f"{name} fractions", fractional_values, count, denominator
    )
    integer_array = _array(f"{name} integer parts", integer_values)
    if coefficient_data_type == 0:
        if len(integer_array) != count:
            raise ValueError(f"{name} must contain {count} integer parts")
        minimum = -(1 << 63) if signed_integer else 0
        integers = tuple(
            _integer(f"{name} integer part[{i}]", item, minimum, (1 << 63) - 1)
            for i, item in enumerate(integer_array)
        )
    else:
        if len(integer_array) not in (0, count):
            raise ValueError(f"{name} integer parts must be absent or zero for coefficient type 1")
        if any(
            _integer(f"{name} integer part[{i}]", item, 0, 0)
            for i, item in enumerate(integer_array)
        ):
            raise ValueError(f"{name} integer parts must be absent or zero for coefficient type 1")
        integers = (0,) * count
    scale = 1 << denominator
    return tuple(integer * scale + fraction for integer, fraction in zip(integers, fractions))


@dataclass(frozen=True)
class MappingPiece:
    method: str
    polynomial_coefficients: tuple[int, ...] = ()
    mmr_constant: int = 0
    mmr_coefficients: tuple[tuple[int, ...], ...] = ()


@dataclass(frozen=True)
class ReshapingCurve:
    pivots: tuple[int, ...]
    pieces: tuple[MappingPiece, ...]

    def piece_index(self, sample: int) -> int:
        return rpu_mapping_piece_index(sample, self.pivots, len(self.pieces))


@dataclass(frozen=True)
class NlqParameters:
    offset: int
    hdr_in_max: int
    linear_deadzone_slope: int
    linear_deadzone_threshold: int


@dataclass(frozen=True)
class Profile7FelCcm:
    bl_bit_depth: int
    el_bit_depth: int
    vdr_bit_depth: int
    coefficient_log2_denom: int
    curves: tuple[ReshapingCurve, ReshapingCurve, ReshapingCurve]
    nlq: tuple[NlqParameters, NlqParameters, NlqParameters]

    def map_bl_sample(
        self,
        component_index: int,
        sample: int,
        *,
        aligned_bl_samples: Sequence[int] | None = None,
    ) -> int:
        """Map one BL sample; MMR requires already aligned (Y, Cb, Cr) codes."""
        component_index = _integer("component_index", component_index, 0, 2)
        curve = self.curves[component_index]
        piece_index = curve.piece_index(sample)
        piece = curve.pieces[piece_index]
        if piece.method == "Polynomial":
            return polynomial_map_sample(
                sample,
                curve.pivots,
                piece.polynomial_coefficients,
                bl_bit_depth=self.bl_bit_depth,
                el_bit_depth=self.el_bit_depth,
                coefficient_log2_denom=self.coefficient_log2_denom,
                mapping_index=piece_index,
                mapping_piece_count=len(curve.pieces),
            )
        if piece.method == "MMR":
            if aligned_bl_samples is None:
                raise ValueError("MMR mapping requires aligned BL (Y, Cb, Cr) samples")
            samples = _array("aligned_bl_samples", aligned_bl_samples)
            if len(samples) != 3:
                raise ValueError("aligned_bl_samples must contain Y, Cb, and Cr")
            if samples[component_index] != sample:
                raise ValueError("sample must match its component in aligned_bl_samples")
            return mmr_map_chroma_sample(
                samples,
                tuple(item.pivots for item in self.curves),
                piece.mmr_constant,
                piece.mmr_coefficients,
                component_index=component_index,
                mapping_index=piece_index,
                bl_bit_depth=self.bl_bit_depth,
                el_bit_depth=self.el_bit_depth,
                coefficient_log2_denom=self.coefficient_log2_denom,
                mapping_piece_count=len(curve.pieces),
            )
        raise ValueError(f"unsupported mapping method: {piece.method}")

    def inverse_quantize_el_sample(self, component_index: int, sample: int) -> int:
        component_index = _integer("component_index", component_index, 0, 2)
        params = self.nlq[component_index]
        return inverse_quantize_el_sample(
            sample,
            nlq_offset=params.offset,
            linear_deadzone_threshold=params.linear_deadzone_threshold,
            linear_deadzone_slope=params.linear_deadzone_slope,
            hdr_in_max=params.hdr_in_max,
            el_bit_depth=self.el_bit_depth,
            coefficient_log2_denom=self.coefficient_log2_denom,
        )

    def reconstruct_sample(
        self,
        component_index: int,
        bl_sample: int,
        el_sample: int,
        *,
        aligned_bl_samples: Sequence[int] | None = None,
        output_bit_depth: int | None = None,
    ) -> int:
        """Run the mapped-BL + inverse-quantized-EL sample equations.

        The caller supplies BT.1886 reconstruction at 14 bits explicitly;
        PQ reconstruction defaults to the RPU's VDR output depth.
        """
        mapped_bl = self.map_bl_sample(
            component_index, bl_sample, aligned_bl_samples=aligned_bl_samples
        )
        residual = self.inverse_quantize_el_sample(component_index, el_sample)
        return reconstruct_ccm_sample(
            mapped_bl,
            residual,
            disable_residual=False,
            output_bit_depth=(self.vdr_bit_depth if output_bit_depth is None else output_bit_depth),
        )


def _parse_curve(
    raw_curve: object,
    component_index: int,
    bl_bit_depth: int,
    coefficient_log2_denom: int,
    coefficient_data_type: int,
) -> ReshapingCurve:
    curve = _mapping(f"curves[{component_index}]", raw_curve)
    pivots_minus2 = _integer(
        f"curves[{component_index}].num_pivots_minus2", curve.get("num_pivots_minus2"), 0, 7
    )
    pivot_count = pivots_minus2 + 2
    predicted = _array(f"curves[{component_index}].pivots", curve.get("pivots"))
    if len(predicted) != pivot_count:
        raise ValueError(f"curves[{component_index}].pivots has an invalid length")
    pivots = derive_pivots(predicted, bl_bit_depth)
    piece_count = pivot_count - 1
    method = curve.get("mapping_idc")

    if method == "Polynomial":
        orders = _array(f"curves[{component_index}].poly_order_minus1", curve.get("poly_order_minus1"))
        linear_flags = _array(f"curves[{component_index}].linear_interp_flag", curve.get("linear_interp_flag"))
        integer_rows = _array(f"curves[{component_index}].poly_coef_int", curve.get("poly_coef_int"))
        fraction_rows = _array(f"curves[{component_index}].poly_coef", curve.get("poly_coef"))
        if any(len(values) != piece_count for values in (orders, linear_flags, integer_rows, fraction_rows)):
            raise ValueError(f"curves[{component_index}] polynomial piece arrays disagree")
        pieces = []
        for index in range(piece_count):
            order_minus1 = _integer(
                f"curves[{component_index}].poly_order_minus1[{index}]", orders[index], 0, 1
            )
            if _boolean(
                f"curves[{component_index}].linear_interp_flag[{index}]", linear_flags[index]
            ):
                raise ValueError("linear-interpolation polynomial curves are unsupported")
            coefficient_count = order_minus1 + 2
            coefficients = _fixed_coefficients(
                f"curves[{component_index}].poly_coef[{index}]",
                integer_rows[index],
                fraction_rows[index],
                coefficient_count,
                coefficient_log2_denom,
                coefficient_data_type=coefficient_data_type,
                signed_integer=True,
            )
            pieces.append(MappingPiece("Polynomial", polynomial_coefficients=coefficients))
        return ReshapingCurve(pivots, tuple(pieces))

    if method == "MMR":
        if component_index == 0:
            raise ValueError("Profile 7 luma MMR curves are unsupported by this reference")
        orders = _array(f"curves[{component_index}].mmr_order_minus1", curve.get("mmr_order_minus1"))
        constant_integers = _array(
            f"curves[{component_index}].mmr_constant_int", curve.get("mmr_constant_int")
        )
        constants = _array(f"curves[{component_index}].mmr_constant", curve.get("mmr_constant"))
        integer_rows = _array(f"curves[{component_index}].mmr_coef_int", curve.get("mmr_coef_int"))
        fraction_rows = _array(f"curves[{component_index}].mmr_coef", curve.get("mmr_coef"))
        if len(orders) != piece_count or len(constants) != piece_count or len(fraction_rows) != piece_count:
            raise ValueError(f"curves[{component_index}] MMR piece arrays disagree")
        if coefficient_data_type == 0 and len(constant_integers) != piece_count:
            raise ValueError(f"curves[{component_index}].mmr_constant_int has an invalid length")
        if coefficient_data_type == 1 and len(constant_integers) != 0:
            raise ValueError("MMR constant integer parts must be absent for coefficient type 1")
        if len(integer_rows) != piece_count:
            raise ValueError(f"curves[{component_index}].mmr_coef_int has an invalid length")
        pieces = []
        for index in range(piece_count):
            order_minus1 = _integer(
                f"curves[{component_index}].mmr_order_minus1[{index}]", orders[index], 0, 2
            )
            order_count = order_minus1 + 1
            constant_integer = (
                _integer(
                    f"curves[{component_index}].mmr_constant_int[{index}]",
                    constant_integers[index],
                    -(1 << 63),
                    (1 << 63) - 1,
                )
                if coefficient_data_type == 0
                else 0
            )
            constant = _fixed_coefficients(
                f"curves[{component_index}].mmr_constant[{index}]",
                (constant_integer,),
                (constants[index],),
                1,
                coefficient_log2_denom,
                coefficient_data_type=coefficient_data_type,
                signed_integer=True,
            )[0]
            raw_integer_orders = _array(
                f"curves[{component_index}].mmr_coef_int[{index}]", integer_rows[index]
            )
            raw_fraction_orders = _array(
                f"curves[{component_index}].mmr_coef[{index}]", fraction_rows[index]
            )
            if len(raw_integer_orders) != order_count or len(raw_fraction_orders) != order_count:
                raise ValueError(f"curves[{component_index}] MMR order arrays disagree")
            coefficient_orders = []
            for order_index in range(order_count):
                fractions = _array(
                    f"curves[{component_index}].mmr_coef[{index}][{order_index}]",
                    raw_fraction_orders[order_index],
                )
                if len(fractions) != 7:
                    raise ValueError("each MMR order must contain seven fractional coefficients")
                integer_order = _array(
                    f"curves[{component_index}].mmr_coef_int[{index}][{order_index}]",
                    raw_integer_orders[order_index],
                )
                if coefficient_data_type == 0 and len(integer_order) != 7:
                    raise ValueError("each MMR order must contain seven integer coefficients")
                if coefficient_data_type == 1 and len(integer_order) != 0:
                    raise ValueError("MMR coefficient integer parts must be absent for type 1")
                coefficients = _fixed_coefficients(
                    f"curves[{component_index}].mmr_coef[{index}][{order_index}]",
                    integer_order,
                    fractions,
                    7,
                    coefficient_log2_denom,
                    coefficient_data_type=coefficient_data_type,
                    signed_integer=True,
                )
                coefficient_orders.append(coefficients)
            pieces.append(
                MappingPiece(
                    "MMR",
                    mmr_constant=constant,
                    mmr_coefficients=tuple(coefficient_orders),
                )
            )
        return ReshapingCurve(pivots, tuple(pieces))

    raise ValueError(f"curves[{component_index}].mapping_idc is unsupported")


def parse_profile7_fel_rpu(
    rpu: Mapping[str, object], *, container_dv_md_compression: int
) -> Profile7FelCcm:
    """Parse one dovi_tool RPU with its demuxed container compression mode.

    The container mode is required because it is not part of RPU JSON. The
    sample reference accepts only uncompressed Profile 7 metadata.
    """
    container_dv_md_compression = _integer(
        "container.dv_md_compression", container_dv_md_compression, 0, 3
    )
    if container_dv_md_compression != 0:
        raise ValueError("container metadata compression is unsupported for Profile 7 FEL")

    rpu = _mapping("RPU", rpu)
    _integer("dovi_profile", rpu.get("dovi_profile"), 7, 7)
    if rpu.get("el_type") != "FEL":
        raise ValueError("RPU must describe a Profile 7 FEL stream")

    header = _mapping("header", rpu.get("header"))
    _integer("header.rpu_type", header.get("rpu_type"), 2, 2)
    rpu_format = _integer("header.rpu_format", header.get("rpu_format"), 0, 0x7FF)
    if rpu_format & 0x700:
        raise ValueError("extended RPU formats are unsupported")
    _integer("header.vdr_rpu_profile", header.get("vdr_rpu_profile"), 1, 1)
    _integer("header.vdr_rpu_level", header.get("vdr_rpu_level"), 0, 0)
    bl_bit_depth = _integer("header.bl_bit_depth_minus8", header.get("bl_bit_depth_minus8"), 2, 2) + 8
    el_bit_depth = _integer("header.el_bit_depth_minus8", header.get("el_bit_depth_minus8"), 2, 2) + 8
    vdr_bit_depth = _integer("header.vdr_bit_depth_minus8", header.get("vdr_bit_depth_minus8"), 4, 4) + 8
    _boolean("header.el_spatial_resampling_filter_flag", header.get("el_spatial_resampling_filter_flag"))
    if not header["el_spatial_resampling_filter_flag"]:
        raise ValueError("RPU does not signal the Profile 7 EL resampling path")
    _boolean("header.disable_residual_flag", header.get("disable_residual_flag"))
    if header["disable_residual_flag"]:
        raise ValueError("RPU disables EL residual reconstruction")
    # dovi_tool retains the field's reserved_zero_3bits name; FFmpeg parses it
    # as dm_compression. This reference only accepts the uncompressed value.
    dm_compression = _integer(
        "header.reserved_zero_3bits", header.get("reserved_zero_3bits"), 0, 7
    )
    if dm_compression != 0:
        raise ValueError("compressed dynamic metadata is unsupported for Profile 7 FEL")
    if _boolean("header.use_prev_vdr_rpu_flag", header.get("use_prev_vdr_rpu_flag")):
        raise ValueError("previous-RPU mapping reuse is unsupported for Profile 7 FEL")

    coefficient_data_type = _integer(
        "header.coefficient_data_type", header.get("coefficient_data_type"), 0, 1
    )
    if coefficient_data_type == 0:
        coefficient_log2_denom = _integer(
            "header.coefficient_log2_denom", header.get("coefficient_log2_denom"),
            el_bit_depth + 5, 23,
        )
        expected_length = coefficient_log2_denom
    else:
        coefficient_log2_denom = 32
        expected_length = 32
    if "coefficient_log2_denom_length" in header:
        actual_length = _integer(
            "header.coefficient_log2_denom_length",
            header["coefficient_log2_denom_length"],
            0,
            32,
        )
        if actual_length != expected_length:
            raise ValueError("coefficient denominator length disagrees with its data type")

    mapping = _mapping("rpu_data_mapping", rpu.get("rpu_data_mapping"))
    for field in (
        "mapping_color_space",
        "mapping_chroma_format_idc",
        "num_x_partitions_minus1",
        "num_y_partitions_minus1",
    ):
        if _integer(f"rpu_data_mapping.{field}", mapping.get(field), 0, 0) != 0:
            raise ValueError(f"rpu_data_mapping.{field} is unsupported")
    raw_curves = _array("rpu_data_mapping.curves", mapping.get("curves"))
    if len(raw_curves) != 3:
        raise ValueError("Profile 7 mapping must contain Y, Cb, and Cr curves")
    curves = tuple(
        _parse_curve(raw, component_index, bl_bit_depth, coefficient_log2_denom, coefficient_data_type)
        for component_index, raw in enumerate(raw_curves)
    )

    if mapping.get("nlq_method_idc") != "LinearDeadzone":
        raise ValueError("only NLQ LinearDeadzone is supported")
    if _integer("nlq_num_pivots_minus2", mapping.get("nlq_num_pivots_minus2"), 0, 0) != 0:
        raise ValueError("NLQ mappings with multiple pivots are unsupported")
    nlq_pivots = derive_pivots(
        _array("nlq_pred_pivot_value", mapping.get("nlq_pred_pivot_value")), bl_bit_depth
    )
    if nlq_pivots != (0, (1 << bl_bit_depth) - 1):
        raise ValueError("NLQ pivots do not span the Profile 7 BL code range")

    nlq = _mapping("rpu_data_mapping.nlq", mapping.get("nlq"))
    offsets = _array("nlq.nlq_offset", nlq.get("nlq_offset"))
    if len(offsets) != 3:
        raise ValueError("nlq.nlq_offset must contain three values")
    hdr_max_int = _integer_array("nlq.vdr_in_max_int", nlq.get("vdr_in_max_int"), 3)
    hdr_max_fraction = _fraction_array(
        "nlq.vdr_in_max", nlq.get("vdr_in_max"), 3, coefficient_log2_denom
    )
    slope_int = _integer_array(
        "nlq.linear_deadzone_slope_int", nlq.get("linear_deadzone_slope_int"), 3
    )
    slope_fraction = _fraction_array(
        "nlq.linear_deadzone_slope", nlq.get("linear_deadzone_slope"), 3,
        coefficient_log2_denom,
    )
    threshold_int = _integer_array(
        "nlq.linear_deadzone_threshold_int",
        nlq.get("linear_deadzone_threshold_int"),
        3,
    )
    threshold_fraction = _fraction_array(
        "nlq.linear_deadzone_threshold", nlq.get("linear_deadzone_threshold"), 3,
        coefficient_log2_denom,
    )
    maximum_el_code = (1 << el_bit_depth) - 1
    nlq_components = []
    for index in range(3):
        offset = _integer(f"nlq.nlq_offset[{index}]", offsets[index], 0, maximum_el_code)
        for name, integer_part in (
            ("vdr_in_max_int", hdr_max_int[index]),
            ("linear_deadzone_slope_int", slope_int[index]),
            ("linear_deadzone_threshold_int", threshold_int[index]),
        ):
            _integer(f"nlq.{name}[{index}]", integer_part, 0, (1 << 63) - 1)
        scale = 1 << coefficient_log2_denom
        nlq_components.append(
            NlqParameters(
                offset,
                hdr_max_int[index] * scale + hdr_max_fraction[index],
                slope_int[index] * scale + slope_fraction[index],
                threshold_int[index] * scale + threshold_fraction[index],
            )
        )

    return Profile7FelCcm(
        bl_bit_depth,
        el_bit_depth,
        vdr_bit_depth,
        coefficient_log2_denom,
        curves,
        tuple(nlq_components),
    )
