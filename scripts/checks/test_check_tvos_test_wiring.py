#!/usr/bin/env python3

import importlib.util
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("check_tvos_test_wiring.py")
SPEC = importlib.util.spec_from_file_location("check_tvos_test_wiring", SCRIPT)
CHECKER = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(CHECKER)


class TvosTestWiringCheckerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.tests_path = self.root / "tvos/RunnerTests"
        self.tests_path.mkdir(parents=True)
        self.compiled_files = ["ExampleTests.swift", "WidgetTests.mm"]
        for name in self.compiled_files:
            (self.tests_path / name).write_text("// fixture\n", encoding="utf-8")
        self._write_project()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _entries(self, names: list[str], *, in_sources: bool = False) -> str:
        entries = []
        for index, name in enumerate(names, start=1):
            suffix = " in Sources" if in_sources else ""
            uuid = f"{index:024X}"
            entries.append(f"\t\t\t\t{uuid} /* {name}{suffix} */,")
        return "\n".join(entries)

    def _write_project(
        self,
        *,
        group_names: list[str] | None = None,
        source_names: list[str] | None = None,
    ) -> None:
        group_names = self.compiled_files if group_names is None else group_names
        source_names = self.compiled_files if source_names is None else source_names
        project_path = self.root / "tvos/Runner.xcodeproj/project.pbxproj"
        project_path.parent.mkdir(parents=True, exist_ok=True)
        project_path.write_text(
            "\n".join(
                [
                    "// !$*UTF8*$!",
                    "{",
                    "\tobjects = {",
                    "\t\tAAAAAAAAAAAAAAAAAAAAAAAA /* RunnerTests */ = {",
                    "\t\t\tisa = PBXGroup;",
                    "\t\t\tchildren = (",
                    self._entries(group_names),
                    "\t\t\t);",
                    "\t\t\tname = RunnerTests;",
                    "\t\t\tpath = RunnerTests;",
                    "\t\t\tsourceTree = \"<group>\";",
                    "\t\t};",
                    "\t\tBBBBBBBBBBBBBBBBBBBBBBBB /* RunnerTests */ = {",
                    "\t\t\tisa = PBXNativeTarget;",
                    "\t\t\tbuildPhases = (",
                    "\t\t\t\tCCCCCCCCCCCCCCCCCCCCCCCC /* Sources */,",
                    "\t\t\t);",
                    "\t\t\tname = RunnerTests;",
                    "\t\t};",
                    "\t\tCCCCCCCCCCCCCCCCCCCCCCCC /* Sources */ = {",
                    "\t\t\tisa = PBXSourcesBuildPhase;",
                    "\t\t\tfiles = (",
                    self._entries(source_names, in_sources=True),
                    "\t\t\t);",
                    "\t\t};",
                    "\t};",
                    "}",
                    "",
                ]
            ),
            encoding="utf-8",
        )

    def test_matching_group_and_sources_phase_pass(self) -> None:
        self.assertEqual([], CHECKER.validate(self.root))

    def test_missing_sources_entry_reports_file_on_disk(self) -> None:
        self._write_project(source_names=["WidgetTests.mm"])

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("Sources phase" in error and "ExampleTests.swift" in error for error in errors))

    def test_missing_group_entry_reports_file_on_disk(self) -> None:
        self._write_project(group_names=["WidgetTests.mm"])

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("PBXGroup" in error and "ExampleTests.swift" in error for error in errors))

    def test_new_swift_file_missing_from_project_is_reported(self) -> None:
        (self.tests_path / "UnwiredTests.swift").write_text("// fixture\n", encoding="utf-8")

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("PBXGroup" in error and "UnwiredTests.swift" in error for error in errors))
        self.assertTrue(any("Sources phase" in error and "UnwiredTests.swift" in error for error in errors))

    def test_non_compiled_sibling_is_required_only_in_group(self) -> None:
        (self.tests_path / "TestSupport.h").write_text("// fixture\n", encoding="utf-8")
        self._write_project(group_names=[*self.compiled_files, "TestSupport.h"])

        self.assertEqual([], CHECKER.validate(self.root))


if __name__ == "__main__":
    unittest.main()
