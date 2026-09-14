import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from check_workflow_action_pins import iter_uses_references, main, validate_reference

SHA = "0123456789abcdef0123456789abcdef01234567"


class WorkflowActionPinsTest(unittest.TestCase):
    def test_accepts_local_and_full_sha_references(self) -> None:
        self.assertIsNone(validate_reference("./.github/actions/local"))
        self.assertIsNone(validate_reference(f"actions/checkout@{SHA}"))
        self.assertIsNone(validate_reference(f"owner/repository/sub/action@{SHA}"))

    def test_rejects_mutable_dynamic_and_malformed_references(self) -> None:
        references = [
            "actions/checkout@v4",
            "owner/action@latest",
            "owner/action@main",
            "owner/action@0123456",
            "owner/action@${{ inputs.ref }}",
            "docker://alpine:3",
            "not-a-reference",
        ]
        for reference in references:
            with self.subTest(reference=reference):
                self.assertIsNotNone(validate_reference(reference))

    def test_parses_mapping_locations_without_comments_or_block_text(self) -> None:
        fixture = f'''\
name: policy
jobs:
  reusable:
    uses: "owner/workflows/.github/workflows/check.yml@{SHA}" # reviewed
  steps:
    runs-on: ubuntu-latest
    steps:
      # - uses: actions/checkout@v4
      - uses: 'actions/checkout@{SHA}' # v4
      - run: |
          echo "uses: owner/action@main"
'''
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "workflow.yaml"
            path.write_text(fixture, encoding="utf-8")
            references = list(iter_uses_references(path))

        self.assertEqual(
            references,
            [
                (4, f"owner/workflows/.github/workflows/check.yml@{SHA}"),
                (9, f"actions/checkout@{SHA}"),
            ],
        )

    def test_rejects_mutable_flow_style_reference(self) -> None:
        fixture = f"""\
jobs: {{ pinned: {{ uses: actions/checkout@{SHA} }}, mutable: {{ uses: owner/action@main }} }}
"""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "workflow.yaml"
            path.write_text(fixture, encoding="utf-8")
            references = list(iter_uses_references(path))
            stderr = io.StringIO()
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(stderr):
                status = main([str(path)])

        self.assertEqual(
            references,
            [
                (1, f"actions/checkout@{SHA}"),
                (1, "owner/action@main"),
            ],
        )
        self.assertEqual(status, 1)
        self.assertIn("owner/action@main", stderr.getvalue())


    def test_rejects_quoted_and_escaped_block_style_keys(self) -> None:
        fixture = f"""\
jobs:
  test:
    steps:
      - "uses": owner/action@main
      - "us\\x65s": owner/other@latest
      - "us\\u0065s": actions/checkout@{SHA}
      - 'uses': actions/checkout@{SHA}
"""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "workflow.yaml"
            path.write_text(fixture, encoding="utf-8")
            references = list(iter_uses_references(path))
            stderr = io.StringIO()
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(stderr):
                status = main([str(path)])

        self.assertEqual(
            references,
            [
                (4, "owner/action@main"),
                (5, "owner/other@latest"),
                (6, f"actions/checkout@{SHA}"),
                (7, f"actions/checkout@{SHA}"),
            ],
        )
        self.assertEqual(status, 1)
        self.assertIn("owner/action@main", stderr.getvalue())
        self.assertIn("owner/other@latest", stderr.getvalue())


    def test_parses_folded_and_literal_uses_scalars(self) -> None:
        fixture = f"""\
jobs:
  test:
    steps:
      - uses: >-
          owner/folded@main
      - uses: |
          owner/literal@latest
      - uses: >-
          actions/checkout@{SHA}
      - uses: |-
          actions/checkout@{SHA}
"""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "workflow.yaml"
            path.write_text(fixture, encoding="utf-8")
            references = list(iter_uses_references(path))
            stderr = io.StringIO()
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(stderr):
                status = main([str(path)])

        self.assertEqual(
            references,
            [
                (4, "owner/folded@main"),
                (6, "owner/literal@latest"),
                (8, f"actions/checkout@{SHA}"),
                (10, f"actions/checkout@{SHA}"),
            ],
        )
        self.assertEqual(status, 1)
        self.assertIn("owner/folded@main", stderr.getvalue())
        self.assertIn("owner/literal@latest", stderr.getvalue())


    def test_parses_explicit_mapping_uses_keys(self) -> None:
        fixture = f"""\
jobs:
  test:
    steps:
      - ? uses
        : owner/explicit@main
      - ? "us\\x65s"
        : actions/checkout@{SHA}
"""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "workflow.yaml"
            path.write_text(fixture, encoding="utf-8")
            references = list(iter_uses_references(path))
            stderr = io.StringIO()
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(stderr):
                status = main([str(path)])

        self.assertEqual(
            references,
            [
                (4, "owner/explicit@main"),
                (6, f"actions/checkout@{SHA}"),
            ],
        )
        self.assertEqual(status, 1)
        self.assertIn("owner/explicit@main", stderr.getvalue())

    def test_parses_flow_sequence_mapping_pairs(self) -> None:
        fixture = (
            f"steps: [uses: owner/sequence@main, uses: actions/checkout@{SHA}]\n"
        )
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "workflow.yaml"
            path.write_text(fixture, encoding="utf-8")
            references = list(iter_uses_references(path))
            stderr = io.StringIO()
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(stderr):
                status = main([str(path)])

        self.assertEqual(
            references,
            [
                (1, "owner/sequence@main"),
                (1, f"actions/checkout@{SHA}"),
            ],
        )
        self.assertEqual(status, 1)
        self.assertIn("owner/sequence@main", stderr.getvalue())


    def test_fails_closed_on_multiline_aliased_and_tagged_keys(self) -> None:
        fixture = """\
uses_key: &uses-key uses
jobs:
  test:
    steps:
      - "u\\
          ses": owner/multiline@main
      - *uses-key: owner/alias@main
      - !!str uses: owner/tagged@main
"""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "workflow.yaml"
            path.write_text(fixture, encoding="utf-8")
            references = list(iter_uses_references(path))
            stderr = io.StringIO()
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(stderr):
                status = main([str(path)])

        self.assertEqual(
            references,
            [
                (5, "<unsupported multiline, tagged, anchored, or aliased mapping key>"),
                (7, "<unsupported multiline, tagged, anchored, or aliased mapping key>"),
                (8, "<unsupported multiline, tagged, anchored, or aliased mapping key>"),
            ],
        )
        self.assertEqual(status, 1)
        self.assertIn("workflow.yaml:5", stderr.getvalue())
        self.assertIn("workflow.yaml:7", stderr.getvalue())
        self.assertIn("workflow.yaml:8", stderr.getvalue())


    def test_does_not_treat_github_expressions_as_yaml_flow_mappings(self) -> None:
        fixture = f"""\
if: ${{{{ always() && !contains(needs.*.result, 'failure') }}}}
steps:
  - uses: actions/checkout@{SHA}
"""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "workflow.yaml"
            path.write_text(fixture, encoding="utf-8")
            references = list(iter_uses_references(path))

        self.assertEqual(references, [(3, f"actions/checkout@{SHA}")])


    def test_block_scalar_ends_at_inferred_content_indentation(self) -> None:
        fixture = '''\
jobs:
  steps:
    runs-on: ubuntu-latest
    steps:
      - name: |
          Multiline step name
        uses: actions/checkout@v4
'''
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "workflow.yaml"
            path.write_text(fixture, encoding="utf-8")
            references = list(iter_uses_references(path))

        self.assertEqual(references, [(7, "actions/checkout@v4")])

    def test_cli_reports_all_violations_with_file_and_line(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            first = root / "first.yml"
            second = root / "second.yaml"
            first.write_text("steps:\n  - uses: actions/checkout@v4\n", encoding="utf-8")
            second.write_text("jobs:\n  call:\n    uses: owner/workflow@main\n", encoding="utf-8")
            stderr = io.StringIO()
            with contextlib.redirect_stderr(stderr):
                status = main([str(first), str(second)])

        self.assertEqual(status, 1)
        output = stderr.getvalue()
        self.assertIn("first.yml:2", output)
        self.assertIn("second.yaml:3", output)
        self.assertIn("actions/checkout@v4", output)
        self.assertIn("owner/workflow@main", output)


if __name__ == "__main__":
    unittest.main()
