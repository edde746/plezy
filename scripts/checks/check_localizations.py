#!/usr/bin/env python3
"""Validate locale coverage, placeholders, native resources and source freshness.

Translations inherit only through locale_catalog.json's explicit regional parents.
A source snapshot makes changed English copy visible instead of silently treating
an old translation as complete. --record-source updates that review checkpoint.
It never fills, translates, or marks a locale as language-reviewed.
"""
from __future__ import annotations
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
I18N = ROOT / 'lib/i18n'
SNAPSHOT = I18N / 'source_snapshot.json'
PLURALS = {'zero', 'one', 'two', 'few', 'many', 'other'}
INTERPOLATION = re.compile(r'\$\{\s*([a-zA-Z_]\w*)(?:\s*:[^}]+)?\s*\}|\$([a-zA-Z_]\w*(?:\.\w+)*)')
BIDI_EMBEDDINGS = re.compile('[\u202a-\u202e]')


def message_key(key):
    return re.sub(r'\([^)]*\)$', '', key)


def is_plural(value):
    return isinstance(value, dict) and 'other' in value and set(value) <= PLURALS


def messages(node, prefix=''):
    result = {}
    for key, value in node.items():
        if key.startswith('@'):
            continue
        full = prefix + message_key(key)
        if isinstance(value, dict) and not is_plural(value):
            result.update(messages(value, full + '.'))
        else:
            result[full] = value
    return result


def merge(parent, overrides):
    result = dict(parent)
    for key, value in overrides.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merge(result[key], value)
        else:
            result[key] = value
    return result


def parameters(value):
    return Counter(a or b for a, b in INTERPOLATION.findall(value))


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True).encode()).hexdigest()[:16]


def validate_message(path, source, target):
    errors = []
    if is_plural(source):
        if not is_plural(target):
            return [f'{path}: expected plural forms including other']
        expected = set().union(*(set(parameters(text)) for text in source.values()))
        # Zero, singular and dual forms can express the count without a numeral.
        count_parameters = expected & {'n', 'count', 'seconds', 'minutes'}
        for form, text in target.items():
            if not isinstance(text, str) or not text.strip():
                errors.append(f'{path}.{form}: empty translation')
                continue
            actual = set(parameters(text))
            required = expected - count_parameters if form in {'zero', 'one', 'two'} else expected
            if not required <= actual or not actual <= expected:
                errors.append(f'{path}.{form}: placeholder mismatch ({sorted(actual)} vs {sorted(expected)})')
            if BIDI_EMBEDDINGS.search(text):
                errors.append(f'{path}.{form}: use isolates instead of bidi embeddings/overrides')
        return errors
    if not isinstance(target, str) or not target.strip():
        return [f'{path}: missing or empty translation']
    if parameters(source) != parameters(target):
        errors.append(f'{path}: placeholder mismatch ({dict(parameters(target))} vs {dict(parameters(source))})')
    if BIDI_EMBEDDINGS.search(target):
        errors.append(f'{path}: use isolates instead of bidi embeddings/overrides')
    if re.search(r'8765\d{3}|ZXQ\d+', target):
        errors.append(f'{path}: unresolved translation sentinel')
    return errors


def check(directory=I18N):
    catalog = json.loads((directory / 'locale_catalog.json').read_text())
    locales = catalog['locales']
    parents = catalog.get('regionalParents', {})
    errors, raw = [], {}
    if len(locales) != len(set(locales)):
        errors.append('duplicate locale identifier')
    files = {p.name.removesuffix('.i18n.json'): p for p in directory.glob('*.i18n.json')}
    for tag in sorted(set(files) ^ set(locales)):
        errors.append(f'{tag}: catalog and translation file list disagree')
    for tag in locales:
        if tag in files:
            raw[tag] = json.loads(files[tag].read_text())
    base = messages(raw.get(catalog['base'], {}))
    if not base:
        errors.append('base catalog is empty')
    resolved = {}
    def resolve(tag, ancestors=()):
        if tag in ancestors:
            raise ValueError(f'inheritance cycle: {ancestors} -> {tag}')
        if tag not in raw:
            raise ValueError(f'missing parent/catalog: {tag}')
        if tag not in resolved:
            resolved[tag] = merge(resolve(parents[tag], (*ancestors, tag)), raw[tag]) if tag in parents else raw[tag]
        return resolved[tag]
    report = {}
    for tag in locales:
        try:
            target = messages(resolve(tag))
        except ValueError as error:
            errors.append(str(error))
            continue
        for key in target.keys() - base.keys():
            errors.append(f'{tag}.{key}: unknown message')
        for key, source in base.items():
            errors.extend(validate_message(f'{tag}.{key}', source, target.get(key)))
        report[tag] = {'messages': len(base), 'inheritedFrom': parents.get(tag),
                       'sameAsEnglish': sum(target.get(k) == v for k, v in base.items())}
    return errors, base, report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--record-source', action='store_true', help='Record English source hashes after translation review')
    parser.add_argument('--report', type=Path, help='Write a machine-readable coverage report')
    args = parser.parse_args()
    errors, base, report = check()
    hashes = {key: digest(value) for key, value in base.items()}
    previous = json.loads(SNAPSHOT.read_text()) if SNAPSHOT.exists() else {}
    changed = sorted(key for key in set(hashes) | set(previous) if hashes.get(key) != previous.get(key))
    if args.record_source and not errors:
        SNAPSHOT.write_text(json.dumps(hashes, ensure_ascii=False, indent=2) + '\n')
    elif changed:
        errors.append(f'English source changed: {len(changed)} messages need translation review. Run --record-source after review.')
        errors.extend('  source: ' + key for key in changed[:20])
    if args.report:
        args.report.write_text(json.dumps({'locales': report, 'errors': errors}, ensure_ascii=False, indent=2) + '\n')
    if errors:
        print('\n'.join(errors[:100]))
        print(f'Localization checks failed: {len(errors)} issues')
        return 1
    print(f'Localization checks passed: {len(report)} locales, {len(base)} messages; placeholders and source hashes verified')
    return 0

if __name__ == '__main__':
    sys.exit(main())
