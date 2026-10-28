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
FALLBACK_MANIFEST = I18N / 'english_fallbacks.json'
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


def is_empty_fallback(value):
    """Return whether Slang's base-locale strategy will use English for value."""
    if value is None:
        return True
    if isinstance(value, str):
        return not value.strip()
    return is_plural(value) and all(
        isinstance(text, str) and not text.strip() for text in value.values()
    )


def uses_english_fallback(locale, base_locale, key, value, fallback_keys):
    return (
        locale != base_locale
        and key in fallback_keys
        and is_empty_fallback(value)
    )


def load_english_fallbacks(directory, base_locale, base_messages):
    """Load explicitly approved untranslated keys that use Slang's English fallback."""
    manifest_path = directory / 'english_fallbacks.json'
    if not manifest_path.exists():
        return set(), []
    try:
        manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    except (OSError, json.JSONDecodeError):
        return set(), ['english_fallbacks.json: invalid JSON']
    if not isinstance(manifest, dict):
        return set(), ['english_fallbacks.json: expected an object']
    if manifest.get('baseLocale') != base_locale:
        return set(), ['english_fallbacks.json: baseLocale must match locale_catalog.json']
    if not isinstance(manifest.get('reason'), str) or not manifest['reason'].strip():
        return set(), ['english_fallbacks.json: reason must explain the fallback']
    values = manifest.get('keys')
    if not isinstance(values, list) or any(not isinstance(key, str) or not key.strip() for key in values):
        return set(), ['english_fallbacks.json: keys must be a list of non-empty message keys']
    if len(values) != len(set(values)):
        return set(), ['english_fallbacks.json: keys must be unique']
    fallback_keys = set(values)
    errors = [f'english_fallbacks.json: unknown English message {key}' for key in sorted(fallback_keys - base_messages.keys())]
    config_path = directory.parent.parent / 'slang.yaml'
    try:
        config = config_path.read_text(encoding='utf-8')
    except OSError:
        config = ''
    if fallback_keys and not re.search(r'(?m)^fallback_strategy:\s*base_locale_empty_string\s*$', config):
        errors.append('english_fallbacks.json requires Slang fallback_strategy: base_locale_empty_string')
    return fallback_keys, errors


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
    fallback_keys, fallback_errors = load_english_fallbacks(directory, catalog['base'], base)
    errors.extend(fallback_errors)
    fallback_usage = Counter()
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
        fallback_count = 0
        for key, source in base.items():
            translation = target.get(key)
            if uses_english_fallback(tag, catalog['base'], key, translation, fallback_keys):
                fallback_count += 1
                fallback_usage[key] += 1
                continue
            errors.extend(validate_message(f'{tag}.{key}', source, translation))
        report[tag] = {'messages': len(base), 'inheritedFrom': parents.get(tag),
                       'sameAsEnglish': sum(target.get(k) == v for k, v in base.items()),
                       'englishFallbacks': fallback_count}
    errors.extend(
        f'english_fallbacks.json: {key} is no longer using the English fallback'
        for key in sorted(fallback_keys - fallback_usage.keys())
    )
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
    fallback_count = sum(locale.get('englishFallbacks', 0) for locale in report.values())
    print(
        f'Localization checks passed: {len(report)} locales, {len(base)} messages; '
        f'{fallback_count} explicitly allowlisted English fallback entries; '
        'placeholders and source hashes verified'
    )
    return 0

if __name__ == '__main__':
    sys.exit(main())
