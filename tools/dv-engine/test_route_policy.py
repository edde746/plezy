import unittest

from route_policy import FEL_EVIDENCE, choose


SOURCE = {"dv_configuration": {"dv_profile": 7, "el_present_flag": 1},
          "base_layer_compatibility": "hdr10", "issues": []}


def adapter(kind, **changes):
    return {"id": kind, "route": kind, "profiles": [7], "available": True,
            "fingerprint": "device/driver/display/engine", "output": "hdr10", **changes}


def select(*adapters, source=SOURCE, mode="auto", failed=()):
    return choose(source, list(adapters), fingerprint="device/driver/display/engine", mode=mode, failed=failed)


class RoutePolicyTest(unittest.TestCase):
    def test_full_fel_requires_evidence_and_experimental_opt_in(self):
        full, fallback = adapter("local-fel"), adapter("p81")
        self.assertEqual(select(full, fallback)["route"], "p81")
        report = select(full, fallback, mode="experimental")
        self.assertEqual(report["enhancement"], "experimental_unverified")
        self.assertFalse(report["physical_dv_verified"])
        self.assertIsNone(select(full, fallback, mode="strict-fel")["route"])

    def test_independent_output_evidence(self):
        full = adapter("local-fel", evidence=dict.fromkeys(FEL_EVIDENCE, True))
        self.assertEqual(select(full, mode="strict-fel")["enhancement"], "reconstructed")
        self.assertFalse(select(full)["physical_dv_verified"])
        full["output"] = "dolby-vision"
        full["evidence"]["physical_dv"] = True
        self.assertTrue(select(full)["physical_dv_verified"])

    def test_fallback_is_bounded_and_compatibility_is_a_first_class_choice(self):
        full = adapter("native-fel", evidence=dict.fromkeys(FEL_EVIDENCE, True))
        p81, base = adapter("p81"), adapter("base")
        self.assertEqual(select(full, p81, base, mode="compatibility")["route"], "p81")
        self.assertEqual(select(full, p81, base, failed=("native-fel", "p81"))["route"], "base")
        self.assertIsNone(select(base, failed=("base",))["route"])

    def test_p5_never_becomes_plain_hdr10(self):
        p5 = {"dv_configuration": {"dv_profile": 5}, "base_layer_compatibility": "none", "issues": []}
        for route in ("base", "p81", "local-fel"):
            self.assertIsNone(select(adapter(route, profiles=[5]), source=p5, mode="experimental")["route"])
        self.assertEqual(select(adapter("reshape", profiles=[5], output="sdr"), source=p5)["route"], "reshape")

    def test_unknown_profile_compatibility_and_conflicting_records_fail_closed(self):
        self.assertIsNone(select(adapter("base"), source={**SOURCE, "issues": ["conflicting"]})["route"])
        self.assertIsNone(select(adapter("base"), source={**SOURCE, "base_layer_compatibility": "unknown"})["route"])

    def test_device_change_and_pending_companion_do_not_stall_fallback(self):
        stale = adapter("native-fel", fingerprint="old-display", evidence=dict.fromkeys(FEL_EVIDENCE, True))
        self.assertEqual(select(stale, adapter("companion", ready=False), adapter("base"))["route"], "base")

    def test_ready_derived_companion_retains_different_fidelity_label(self):
        companion = adapter("companion", ready=True, evidence=dict.fromkeys(FEL_EVIDENCE, True))
        self.assertEqual(select(companion, adapter("p81"))["enhancement"], "derived")

    def test_duplicate_adapter_and_unknown_mode_are_rejected(self):
        with self.assertRaises(ValueError):
            select(adapter("base"), adapter("base"))
        with self.assertRaises(ValueError):
            select(adapter("base"), mode="anything")

    def test_malformed_capabilities_are_rejected(self):
        for invalid in (None, {"profiles": None}, adapter("base", evidence=[])):
            with self.assertRaises(ValueError):
                select(invalid)

    def test_strict_mode_accepts_qualified_experimental_route(self):
        full = adapter("local-fel", experimental=True, evidence=dict.fromkeys(FEL_EVIDENCE, True))
        self.assertEqual(select(full, mode="strict-fel")["enhancement"], "reconstructed")


if __name__ == "__main__":
    unittest.main()
