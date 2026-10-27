import unittest

from ccm_reference import (
    derive_pivots,
    inverse_quantize_el_sample,
    mmr_map_chroma_sample,
    polynomial_map_sample,
    pivot_index,
    reconstruct_sample,
    rpu_mapping_piece_index,
)


class CcmReferenceTest(unittest.TestCase):
    def test_predicted_pivots_are_accumulated_and_boundaries_select_next_segment(self):
        pivots = derive_pivots((12, 30, 100), 8)
        self.assertEqual(pivots, (12, 42, 142))
        self.assertEqual(pivot_index(11, pivots), 0)
        self.assertEqual(pivot_index(42, pivots), 1)
        self.assertEqual(pivot_index(142, pivots), 2)
        self.assertEqual(rpu_mapping_piece_index(142, pivots, 2), 1)

    def test_cumulative_pivots_cannot_exceed_the_bl_code_range(self):
        with self.assertRaises(ValueError):
            derive_pivots((200, 100), 8)

    def test_rpu_curve_saturates_the_top_code_into_its_last_encoded_piece(self):
        self.assertEqual(rpu_mapping_piece_index(255, (0, 255), 1), 0)
        with self.assertRaises(ValueError):
            rpu_mapping_piece_index(255, (0, 255), 2)

    def test_polynomial_mapping_clamps_and_produces_hand_calculated_8_to_16_bit_ramp(self):
        coefficients = (0, 32_896)  # 257x scale after the normative fixed-point shifts.
        kwargs = dict(
            pivots=(0, 255), coefficients=coefficients, bl_bit_depth=8,
            el_bit_depth=10, coefficient_log2_denom=15,
        )
        self.assertEqual(polynomial_map_sample(37, **kwargs), 9_509)
        self.assertEqual(polynomial_map_sample(255, mapping_index=1, **kwargs), 65_535)

    def test_mmr_order_one_maps_the_aligned_luma_term(self):
        result = mmr_map_chroma_sample(
            (127, 42, 99), ((0, 255), (0, 255), (0, 255)), 0,
            ((1 << 15, 0, 0, 0, 0, 0, 0),),
            component_index=1, mapping_index=0,
            bl_bit_depth=8, el_bit_depth=10, coefficient_log2_denom=15,
        )
        self.assertEqual(result, 32_512)

        cubic = mmr_map_chroma_sample(
            (127, 3, 2), ((0, 255), (0, 255), (0, 255)), 0,
            ((0, 0, 0, 0, 0, 0, 1 << 15),),
            component_index=1, mapping_index=0,
            bl_bit_depth=8, el_bit_depth=10, coefficient_log2_denom=15,
        )
        self.assertEqual(cubic, 2)

    def test_nlq_inverse_quantization_handles_zero_and_signed_residuals(self):
        common = dict(
            nlq_offset=512, linear_deadzone_threshold=0,
            linear_deadzone_slope=1 << 15, hdr_in_max=1 << 15,
            el_bit_depth=10, coefficient_log2_denom=15,
        )
        self.assertEqual(inverse_quantize_el_sample(512, **common), 0)
        self.assertEqual(inverse_quantize_el_sample(513, **common), 32_768)
        self.assertEqual(inverse_quantize_el_sample(511, **common), -32_768)

    def test_reconstruction_adds_residual_rounds_and_clips(self):
        self.assertEqual(reconstruct_sample(4_096, 16, disable_residual=False, output_bit_depth=12), 257)
        self.assertEqual(reconstruct_sample(4_096, 16, disable_residual=True, output_bit_depth=12), 256)
        self.assertEqual(reconstruct_sample(0, -65_536, disable_residual=False, output_bit_depth=12), 0)
        self.assertEqual(reconstruct_sample(65_535, 65_535, disable_residual=False, output_bit_depth=12), 4_095)

    def test_invalid_depths_and_metadata_fail_closed(self):
        with self.assertRaises(ValueError):
            derive_pivots((0, 255), 9)
        with self.assertRaises(ValueError):
            polynomial_map_sample(
                1, (0, 255), (0, 1), bl_bit_depth=8, el_bit_depth=10,
                coefficient_log2_denom=14,
            )
        with self.assertRaises(ValueError):
            polynomial_map_sample(
                255, pivots=(0, 255), coefficients=(0, 32_896),
                bl_bit_depth=8, el_bit_depth=10, coefficient_log2_denom=15,
            )
        with self.assertRaises(ValueError):
            reconstruct_sample(1, 0, disable_residual=1, output_bit_depth=12)


if __name__ == "__main__":
    unittest.main()
