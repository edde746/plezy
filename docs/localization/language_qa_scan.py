#!/usr/bin/env python3
"""Reproduce the bounded language-QA candidate scan; never approve fluency.

--baseline reconstructs original message values from the correction ledger.
The manifest identifies the published input and reviewed output by SHA-256.
"""
from __future__ import annotations

import argparse
from collections import Counter
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts/checks'))
from check_localizations import merge, message_key, messages  # noqa: E402

DOCS = ROOT / 'docs/localization'
PAIRS = [
    ('common.yes', 'common.no'),
    ('common.play', 'common.pause'),
    ('fileSources.leftToRight', 'fileSources.rightToLeft'),
    ('fileSources.previousPage', 'fileSources.nextPage'),
    ('lending.borrow', 'lending.returnBook'),
]


def restore_message(catalog, path, value):
    node = catalog
    segments = path.split('.')
    for segment in segments[:-1]:
        node = node[next(key for key in node if message_key(key) == segment)]
    key = next(key for key in node if message_key(key) == segments[-1])
    node[key] = value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', action='store_true')
    parser.add_argument('--check-reviewed-hashes', action='store_true')
    parser.add_argument('--check-findings-resolved', action='store_true')
    args = parser.parse_args()
    manifest = json.loads((DOCS / 'language_qa_manifest.json').read_text())
    fixes = json.loads((DOCS / 'language_qa_fixes.json').read_text())['fixes']
    catalog = json.loads((ROOT / 'lib/i18n/locale_catalog.json').read_text())
    tags = catalog['locales']
    raw = {tag: json.loads((ROOT / f'lib/i18n/{tag}.i18n.json').read_text()) for tag in tags}
    fix_by_key = {(fix['locale'], fix['key']): fix for fix in fixes}
    if len(fix_by_key) != len(fixes):
        raise SystemExit('Duplicate correction ledger entries')
    if args.check_reviewed_hashes:
        for tag, info in manifest['locales'].items():
            path = ROOT / info['catalogPath']
            if hashlib.sha256(path.read_bytes()).hexdigest() != info['afterSha256']:
                raise SystemExit(f'Reviewed output hash changed: {path.relative_to(ROOT)}')
        source = ROOT / 'lib/i18n/en.i18n.json'
        if hashlib.sha256(source.read_bytes()).hexdigest() != manifest['englishAfterSha256']:
            raise SystemExit('Reviewed English source hash changed')
        for fix in fixes:
            if messages(raw[fix['locale']])[fix['key']] != fix['corrected']:
                raise SystemExit(f"Correction ledger mismatch: {fix['locale']}.{fix['key']}")
        print(f'Reviewed hashes and all {len(fixes)} correction records match.')
    if args.check_findings_resolved:
        if args.baseline:
            raise SystemExit('Check final findings separately from --baseline')
        unresolved = sum(len(info['needsNativeReviewKeys']) for info in manifest['locales'].values())
        residuals = {(tag, key) for tag, info in manifest['locales'].items()
                     for key in info['firstPassNeedsNativeReviewKeys']}
        if unresolved or len(residuals) != manifest['coverage']['originalResidualFindingsCorrected']:
            raise SystemExit('Residual finding counts do not match the completed review')
        for pair in residuals:
            fix = fix_by_key.get(pair)
            if not fix or fix['correctionPass'] != 2 or fix['original'] == fix['corrected']:
                raise SystemExit(f'Historical finding has no actual follow-up correction: {pair}')
        for fix in fixes:
            if fix['original'] == fix['corrected'] or messages(raw[fix['locale']])[fix['key']] != fix['corrected']:
                raise SystemExit(f"Invalid correction: {fix['locale']}.{fix['key']}")
        dispositions = {(item['locale'], item['key']): item for item in manifest['candidateDispositions']}
        if len(dispositions) != len(manifest['candidateDispositions']):
            raise SystemExit('Duplicate candidate dispositions')
        for pair, disposition in dispositions.items():
            if disposition['status'] not in {'corrected', 'verified-adequate'} or not disposition['reason']:
                raise SystemExit(f'Missing concrete candidate disposition: {pair}')
            if disposition['status'] == 'corrected' and pair not in fix_by_key:
                raise SystemExit(f'Candidate marked corrected without ledger entry: {pair}')
        direct = sum(len(info['directReviewedKeys']) for info in manifest['locales'].values())
        inherited = sum(len(info['inheritedReviewedKeys']) for info in manifest['locales'].values())
        coverage = manifest['coverage']
        if (direct != coverage['directUniqueNonEnglishLocaleMessages'] or
                inherited != coverage['inheritedEffectiveLocaleMessages'] or
                direct + inherited != coverage['effectiveSemanticLocaleMessages'] or
                len(fixes) != coverage['correctedMessages']):
            raise SystemExit('Coverage totals do not match exact manifest paths')
        print(f'All {len(residuals)} historical residual findings have real follow-up corrections; '
              f'{len(dispositions)} original heuristic candidates have concrete dispositions.')
    if args.baseline:
        raw = deepcopy(raw)
        for fix in fixes:
            restore_message(raw[fix['locale']], fix['key'], fix['original'])
        for tag, value in raw.items():
            restored_hash = hashlib.sha256((json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode()).hexdigest()
            expected_hash = (manifest['englishBeforeSha256'] if tag == 'en'
                             else manifest['locales'][tag]['beforeSha256'])
            if restored_hash != expected_hash:
                raise SystemExit(f'Reconstructed published-input hash differs: {tag}')
    resolved = {}

    def resolve(tag):
        if tag not in resolved:
            parent = catalog.get('regionalParents', {}).get(tag)
            resolved[tag] = merge(resolve(parent), raw[tag]) if parent else raw[tag]
        return resolved[tag]

    english = messages(raw['en'])
    summary = Counter()
    by_locale = {}
    for tag in tags:
        if tag == 'en':
            continue
        flat = messages(resolve(tag))
        counts = Counter()
        for key, value in flat.items():
            source = english[key]
            if not isinstance(value, str) or not isinstance(source, str):
                continue
            if re.search('[\u2047\ufffd]', value):
                counts['corrupt_symbol'] += 1
            if len(source) > 80 and len(value) < len(source) * 0.3:
                counts['short_translation'] += 1
            if re.search(r'(\b\w+\b)(?:[ ,]+\1){3}', value, re.I):
                counts['repeated_word'] += 1
            if value == source:
                counts['same_as_english'] += 1
            if args.check_findings_resolved:
                disposition = dispositions.get((tag, key))
                if re.search('[\u2047\ufffd]', value) or re.search(r'(\b\w+\b)(?:[ ,]+\1){3}', value, re.I):
                    raise SystemExit(f'Unresolved corruption/repetition candidate: {tag}.{key}')
                if len(source) > 80 and len(value) < len(source) * 0.3:
                    if not disposition or disposition['finalCandidateKinds'] != ['short_translation']:
                        raise SystemExit(f'Short candidate lacks an explicit adequate-text disposition: {tag}.{key}')
        for left, right in PAIRS:
            if flat[left] == flat[right]:
                counts['opposite_labels_identical'] += 1
        by_locale[tag] = dict(sorted(counts.items()))
        summary.update(counts)
    result = {'snapshot': 'baseline' if args.baseline else 'reviewed-output',
              'resolvedNonEnglishMessages': len(english) * (len(tags) - 1),
              'candidateScalarComparisons': sum(isinstance(v, str) for v in english.values()) * (len(tags) - 1),
              'candidateCounts': dict(sorted(summary.items())), 'locales': by_locale}
    if args.baseline and dict(summary) != manifest['automatedBaseline']:
        raise SystemExit('Baseline candidate counts no longer match the review manifest')
    if args.check_findings_resolved and dict(summary) != manifest['automatedAfter']:
        raise SystemExit('Final candidate counts no longer match the review manifest')
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    sys.exit(main())
