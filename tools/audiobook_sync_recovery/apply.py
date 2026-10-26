#!/usr/bin/env python3
"""Preflight/replay the audiobook implementation checkpoint in an isolated checkout."""
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
parser.add_argument("--apply", action="store_true", help="Write only after every transformation passes preflight")
args = parser.parse_args()
root = args.root.resolve()
bundle = json.loads(Path(__file__).with_name("changes.json").read_text())
if bundle["version"] != 1:
    raise SystemExit("Unsupported recovery bundle")

pending = {}
def target(name):
    path = (root / name).resolve()
    if root not in path.parents:
        raise SystemExit("Invalid recovery path: " + name)
    return path

for item in bundle["files"]:
    path = target(item["path"])
    if path.exists() and path.read_text() != item["content"]:
        raise SystemExit("New file already exists with different content: " + item["path"])
    pending[path] = item["content"]

for index, edit in enumerate(bundle["edits"], 1):
    path = target(edit["path"])
    if path not in pending:
        if not path.is_file():
            raise SystemExit("Missing source foundation prerequisite: " + edit["path"])
        pending[path] = path.read_text()
    text = pending[path]
    count = edit.get("count", 1)
    if text.count(edit["before"]) < count:
        raise SystemExit("Context mismatch at edit %d: %s; reconcile with the current foundation" % (index, edit["path"]))
    pending[path] = text.replace(edit["before"], edit["after"], count)

locale = target("lib/i18n/en.i18n.json")
data = json.loads(pending.get(locale, locale.read_text()))
if "audiobook" in data and data["audiobook"] != bundle["english"]:
    raise SystemExit("Existing audiobook translations require a deliberate merge")
data["audiobook"] = bundle["english"]
pending[locale] = json.dumps(data, ensure_ascii=False, indent=2) + "\n"

print("Preflight passed for %d files. Regenerate Slang, format, analyze and test after applying." % len(pending))
if args.apply:
    for path, text in pending.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
    print("Draft changes applied. These are unvalidated application edits, not a completed release.")
else:
    print("No files written. Use --apply only in the intended isolated checkout.")
