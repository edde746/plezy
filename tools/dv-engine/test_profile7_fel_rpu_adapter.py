import copy
import json
import unittest
from pathlib import Path

from profile7_fel_rpu_adapter import parse_profile7_fel_rpu


FIXTURE = Path(__file__).with_name("testdata") / "profile7_fel_rpu_frame0.json"


def load_fixture():
    return json.loads(FIXTURE.read_text(encoding="utf-8"))


class Profile7FelRpuAdapterTest(unittest.TestCase):
    def test_mit_dovi_tool_frame_maps_into_the_ccm_model(self):
        metadata = parse_profile7_fel_rpu(load_fixture())

        self.assertEqual((metadata.bl_bit_depth, metadata.el_bit_depth), (10, 10))
        self.assertEqual((metadata.vdr_bit_depth, metadata.coefficient_log2_denom), (12, 23))
        self.assertEqual(metadata.curves[0].pivots, (0, 128, 256, 384, 512, 640, 768, 896, 1023))
        self.assertEqual(len(metadata.curves[0].pieces), 8)
        self.assertEqual(metadata.curves[0].pieces[0].polynomial_coefficients, (0, 1 << 23))
        self.assertEqual(metadata.curves[1].pieces[0].mmr_constant, 448998)
        self.assertEqual(
            metadata.curves[1].pieces[0].mmr_coefficients[0][0],
            -(1 << 23) + 7126552,
        )
        self.assertEqual(metadata.nlq[0].hdr_in_max, 1048576)
        self.assertEqual(metadata.nlq[0].linear_deadzone_slope, 2048)

    def test_p7_luma_sample_runs_mapping_nlq_and_reconstruction_equations(self):
        metadata = parse_profile7_fel_rpu(load_fixture())

        self.assertEqual(metadata.map_bl_sample(0, 512), 32768)
        self.assertEqual(metadata.inverse_quantize_el_sample(0, 513), 8)
        self.assertEqual(metadata.reconstruct_sample(0, 512, 513), 2049)

    def test_top_bl_code_selects_the_last_rpu_piece(self):
        metadata = parse_profile7_fel_rpu(load_fixture())
        curve = metadata.curves[0]

        self.assertEqual(curve.piece_index(1023), 7)
        self.assertEqual(metadata.map_bl_sample(0, 1023), 65472)

    def test_mmr_uses_the_component_curve_and_aligned_luma(self):
        rpu = load_fixture()
        cb = rpu["rpu_data_mapping"]["curves"][1]
        cb["mmr_order_minus1"] = [0]
        cb["mmr_constant_int"] = [0]
        cb["mmr_constant"] = [1 << 22]
        cb["mmr_coef_int"] = [[[0] * 7]]
        cb["mmr_coef"] = [[[0] * 7]]
        metadata = parse_profile7_fel_rpu(rpu)

        self.assertEqual(
            metadata.map_bl_sample(1, 500, aligned_bl_samples=(512, 500, 400)),
            32768,
        )

    def test_fraction_only_q32_coefficients_map_and_reconstruct(self):
        rpu = load_fixture()
        rpu["header"]["coefficient_data_type"] = 1
        rpu["header"]["coefficient_log2_denom"] = 0
        rpu["header"]["coefficient_log2_denom_length"] = 32
        for curve in rpu["rpu_data_mapping"]["curves"]:
            if curve["mapping_idc"] == "Polynomial":
                curve["poly_coef_int"] = [[] for _ in curve["poly_order_minus1"]]
                for coefficients in curve["poly_coef"]:
                    coefficients[:] = [0, 0xFFFFFFFF]
            else:
                curve["mmr_constant_int"] = []
                curve["mmr_coef_int"] = [
                    [[] for _ in range(order_minus1 + 1)]
                    for order_minus1 in curve["mmr_order_minus1"]
                ]

        nlq = rpu["rpu_data_mapping"]["nlq"]
        nlq["vdr_in_max_int"] = [0, 0, 0]
        nlq["vdr_in_max"] = [0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF]
        nlq["linear_deadzone_slope_int"] = [0, 0, 0]
        nlq["linear_deadzone_slope"] = [1 << 31, 1 << 31, 1 << 31]
        nlq["linear_deadzone_threshold_int"] = [0, 0, 0]
        nlq["linear_deadzone_threshold"] = [0, 0, 0]

        metadata = parse_profile7_fel_rpu(rpu)

        self.assertEqual(metadata.coefficient_log2_denom, 32)
        self.assertEqual(
            metadata.curves[0].pieces[0].polynomial_coefficients,
            (0, 0xFFFFFFFF),
        )
        self.assertEqual(metadata.map_bl_sample(0, 512), 32767)
        self.assertEqual(metadata.inverse_quantize_el_sample(0, 513), 16384)
        self.assertEqual(metadata.reconstruct_sample(0, 512, 513), 3072)

    def test_unsupported_rpu_modes_fail_closed(self):
        rpu = load_fixture()
        rpu["header"]["disable_residual_flag"] = True
        with self.assertRaises(ValueError):
            parse_profile7_fel_rpu(rpu)

        rpu = load_fixture()
        rpu["header"]["use_prev_vdr_rpu_flag"] = True
        with self.assertRaises(ValueError):
            parse_profile7_fel_rpu(rpu)

        rpu = load_fixture()
        rpu["header"]["reserved_zero_3bits"] = 1
        with self.assertRaisesRegex(ValueError, "compressed dynamic metadata"):
            parse_profile7_fel_rpu(rpu)

        rpu = load_fixture()
        rpu["rpu_data_mapping"]["curves"][0]["pivots"][-1] = 128
        with self.assertRaises(ValueError):
            parse_profile7_fel_rpu(rpu)

        rpu = load_fixture()
        rpu["rpu_data_mapping"]["curves"][0]["poly_coef"][0][1] = 1 << 23
        with self.assertRaises(ValueError):
            parse_profile7_fel_rpu(rpu)


if __name__ == "__main__":
    unittest.main()
