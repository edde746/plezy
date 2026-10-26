#!/usr/bin/env python3
"""Reproduce the bounded language-QA candidate scan; never approve fluency.

--baseline reconstructs original message values from the correction ledger.
The manifest identifies the published input and reviewed output by SHA-256.
An integration manifest verifies the complete current catalog separately. The
historical projection reverses its separate correction ledger and retains the
exact original key/order shape. All excluded additions are explicitly listed;
automatic scanning of an addition does not imply semantic review.
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


def catalog_hash(value):
    serialized = json.dumps(value, ensure_ascii=False, indent=2) + '\n'
    return hashlib.sha256(serialized.encode()).hexdigest()


def verify_integration_and_project(raw, tags, historical, integration):
    """Verify the complete current snapshot, then derive the exact old layer."""
    if integration['schemaVersion'] != 2 or integration['knownUnaddressedFindings']:
        raise SystemExit('Unexpected or unfinished integration review')
    for filename, field in [('language_qa_manifest.json', 'historicalManifestSha256'),
                            ('language_qa_fixes.json', 'historicalCorrectionsSha256'),
                            ('LANGUAGE_QA.md', 'historicalReportSha256'),
                            ('language_qa_historical_shape.json', 'historicalShapeSha256'),
                            ('language_qa_integration_fixes.json', 'additionalCorrectionsSha256'),
                            ('language_qa_source_setup_review_fixes.json', 'sourceSetupDraftCorrectionsSha256')]:
        if hashlib.sha256((DOCS / filename).read_bytes()).hexdigest() != integration[field]:
            raise SystemExit(f'Audit artifact hash changed: {filename}')
    if set(integration['catalogs']) != set(tags):
        raise SystemExit('Integration catalog inventory differs from locale catalog')
    source = integration['reviewedSourceMessages']
    translations = integration['reviewedTranslations']
    regional = integration['regionalInheritance']
    catalog = json.loads((ROOT / 'lib/i18n/locale_catalog.json').read_text())
    if (regional != catalog['regionalParents'] or
            set(translations) | set(regional) | {'en'} != set(tags)):
        raise SystemExit('Integration locale inheritance differs')
    resolved = {}

    def resolve(tag):
        if tag not in resolved:
            parent = regional.get(tag)
            resolved[tag] = merge(resolve(parent), raw[tag]) if parent else raw[tag]
        return resolved[tag]

    english = messages(raw['en'])
    if set(source) != set().union(*(set(values) for values in translations.values())):
        raise SystemExit('Reviewed English/translation key inventories differ')
    for key, value in source.items():
        if english.get(key) != value:
            raise SystemExit(f'Reviewed integration source changed: {key}')
    direct = set()
    inherited = set()
    for tag in tags:
        info = integration['catalogs'][tag]
        expected_path = f'lib/i18n/{tag}.i18n.json'
        if info['catalogPath'] != expected_path:
            raise SystemExit(f'Unexpected integration catalog path: {tag}')
        if hashlib.sha256((ROOT / expected_path).read_bytes()).hexdigest() != info['currentSha256']:
            raise SystemExit(f'Integrated output hash changed: {expected_path}')
        flat = messages(raw[tag])
        effective = messages(resolve(tag))
        if len(flat) != info['physicalMessages'] or len(effective) != info['resolvedMessages']:
            raise SystemExit(f'Current message counts differ: {tag}')
        expected = source if tag == 'en' else translations.get(tag, {})
        if set(expected) != set(info['integrationDirectReviewedKeys']):
            raise SystemExit(f'Direct semantic inventory differs: {tag}')
        for key, value in expected.items():
            if flat.get(key) != value:
                raise SystemExit(f'Reviewed integration value changed: {tag}.{key}')
            if isinstance(value, str):
                if not value.strip() or Counter(re.findall(r'\$\{[^}]+\}', value)) != Counter(re.findall(r'\$\{[^}]+\}', source[key])):
                    raise SystemExit(f'Integration placeholder/empty-text mismatch: {tag}.{key}')
            if tag != 'en':
                direct.add((tag, key))
        for key in info['integrationInheritedReviewedKeys']:
            parent = regional.get(tag)
            if not parent or key in flat or key not in translations[parent] or effective[key] != translations[parent][key]:
                raise SystemExit(f'Reviewed inheritance mismatch: {tag}.{key}')
            inherited.add((tag, key))

    historical_fixes = json.loads((DOCS / 'language_qa_fixes.json').read_text())['fixes']
    additions = json.loads((DOCS / 'language_qa_integration_fixes.json').read_text())['fixes']
    historic_pairs = {(fix['locale'], fix['key']) for fix in historical_fixes}
    additional_pairs = {(fix['locale'], fix['key']) for fix in additions}
    if len(additional_pairs) != len(additions) or historic_pairs & additional_pairs:
        raise SystemExit('Additional correction ledger duplicates or overlaps historical records')
    prior = deepcopy(raw)
    for fix in additions:
        if fix['original'] == fix['corrected'] or messages(raw[fix['locale']]).get(fix['key']) != fix['corrected']:
            raise SystemExit(f"Additional correction mismatch: {fix['locale']}.{fix['key']}")
        restore_message(prior[fix['locale']], fix['key'], fix['original'])
    draft_fixes = json.loads((DOCS / 'language_qa_source_setup_review_fixes.json').read_text())['fixes']
    for fix in draft_fixes:
        if fix['original'] == fix['corrected'] or messages(raw[fix['locale']]).get(fix['key']) != fix['corrected']:
            raise SystemExit(f"Draft-review correction mismatch: {fix['locale']}.{fix['key']}")

    shape = json.loads((DOCS / 'language_qa_historical_shape.json').read_text())
    if set(shape['roots']) != set(tags) or shape['reviewedPublishedHead'] != historical['reviewedHead']:
        raise SystemExit('Historical projection shape belongs to another snapshot')

    def project(value, node_id):
        if node_id is None:
            return value
        return {key: project(value[key], child) for key, child in shape['nodes'][node_id]}

    projected = {}
    for tag in tags:
        try:
            projected[tag] = project(prior[tag], shape['roots'][tag])
        except (KeyError, TypeError, IndexError) as error:
            raise SystemExit(f'Historical projection key/shape missing: {tag}: {error}') from error
        info = integration['catalogs'][tag]
        added = sorted(set(messages(raw[tag])) - set(messages(projected[tag])))
        expected_added = integration['addedMessageKeySets'][info['addedMessageKeySet']]
        if added != expected_added or len(added) != info['addedOutsideHistoricalReviewKeysCount']:
            raise SystemExit(f'Unenumerated integration addition: {tag}')
        if sorted(set(added) - set(info['integrationDirectReviewedKeys'])) != info['addedOutsideSemanticReviewKeys']:
            raise SystemExit(f'Outside-semantic-scope addition inventory differs: {tag}')
    for tag, value in projected.items():
        expected = (historical['englishAfterSha256'] if tag == 'en'
                    else historical['locales'][tag]['afterSha256'])
        if (integration['catalogs'][tag]['historicalReviewedSha256'] != expected or
                catalog_hash(value) != expected):
            raise SystemExit(f'Historical reviewed projection hash differs: {tag}')
    old_direct = {(tag, key) for tag, info in historical['locales'].items() for key in info['directReviewedKeys']}
    old_inherited = {(tag, key) for tag, info in historical['locales'].items() for key in info['inheritedReviewedKeys']}
    coverage = integration['coverage']
    checks = {
        'integrationDirectUniqueLocaleMessages': len(direct),
        'integrationInheritedLocaleMessages': len(inherited),
        'integrationEffectiveLocaleMessages': len(direct | inherited),
        'historicalOverlapDirectLocaleMessages': len(direct & old_direct),
        'combinedDirectUniqueLocaleMessages': len(direct | old_direct),
        'combinedInheritedLocaleMessages': len(inherited | old_inherited),
        'combinedEffectiveLocaleMessages': len(direct | inherited | old_direct | old_inherited),
        'additionalMessageCorrections': len(additions),
        'allCatalogMessageCorrections': len(additions) + len(historical_fixes),
    }
    if any(coverage[key] != value for key, value in checks.items()):
        raise SystemExit('Integration coverage differs from exact key inventories')
    if coverage['sourceSetup']['draftReviewCorrections'] != len(draft_fixes):
        raise SystemExit('SourceSetup draft-review count differs')
    groups = integration['reviewGroups']
    group_pairs = {
        name: {(tag, key) for tag in group['locales'] for key in group['keys']}
        for name, group in groups.items() if name != 'additionalCandidates'
    }
    candidates = {(item['locale'], item['key']) for item in groups['additionalCandidates']}
    if set().union(*group_pairs.values(), candidates) != direct:
        raise SystemExit('Declared semantic review groups differ from reviewed values')
    grouped_counts = [
        (coverage['discovery']['authorSelfReviewedMessages'], len(group_pairs['discovery'])),
        (coverage['smb']['independentlyReviewedMessages'], len(group_pairs['smb'])),
        (coverage['sourceSetup']['authorSelfReviewedMessages'], len(group_pairs['sourceSetupSelf'])),
        (coverage['sourceSetup']['independentlyReviewedMessages'], len(group_pairs['sourceSetupIndependent'])),
        (coverage['italianFollowup']['directReviewedMessages'], len(group_pairs['italianFollowup'])),
        (coverage['newlyMergedCandidateReview']['correctedMessages'], len(candidates)),
    ]
    if any(declared != actual for declared, actual in grouped_counts):
        raise SystemExit('Independent/self-review group counts differ')
    setup_groups = [groups['sourceSetupSelf'], groups['sourceSetupIndependent']]
    if (set(setup_groups[0]['locales']) & set(setup_groups[1]['locales']) or
            set(setup_groups[0]['locales']) | set(setup_groups[1]['locales']) != set(translations) or
            set(setup_groups[0]['keys']) != set(setup_groups[1]['keys'])):
        raise SystemExit('SourceSetup independent/self-review inventories overlap or are incomplete')
    occurrences = sum(len(re.findall(r'\$\{[^}]+\}', source[key])) for key in setup_groups[0]['keys']) * len(translations)
    if occurrences != coverage['sourceSetup']['placeholderOccurrencesChecked']:
        raise SystemExit('SourceSetup placeholder occurrence count differs')
    return projected


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
    integration_path = DOCS / 'language_qa_integration.json'
    integration = json.loads(integration_path.read_text()) if integration_path.exists() else None
    historical_raw = (verify_integration_and_project(raw, tags, manifest, integration)
                      if integration else raw)
    fix_by_key = {(fix['locale'], fix['key']): fix for fix in fixes}
    if len(fix_by_key) != len(fixes):
        raise SystemExit('Duplicate correction ledger entries')
    if args.check_reviewed_hashes:
        for tag, info in manifest['locales'].items():
            path = ROOT / info['catalogPath']
            expected = integration['catalogs'][tag]['currentSha256'] if integration else info['afterSha256']
            if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
                raise SystemExit(f'Reviewed output hash changed: {path.relative_to(ROOT)}')
        source = ROOT / 'lib/i18n/en.i18n.json'
        expected = (integration['catalogs']['en']['currentSha256'] if integration
                    else manifest['englishAfterSha256'])
        if hashlib.sha256(source.read_bytes()).hexdigest() != expected:
            raise SystemExit('Reviewed English source hash changed')
        for fix in fixes:
            if messages(raw[fix['locale']])[fix['key']] != fix['corrected']:
                raise SystemExit(f"Correction ledger mismatch: {fix['locale']}.{fix['key']}")
        print(f'Reviewed hashes and all {len(fixes)} correction records match.')
        if integration:
            count = integration['coverage']['integrationDirectUniqueLocaleMessages']
            print(f'Current integration hashes and all {count} directly reviewed values match; '
                  'all 37 historical reviewed hashes are reproduced by the exact key/order projection.')
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
        if integration:
            additional_fixes = json.loads((DOCS / 'language_qa_integration_fixes.json').read_text())['fixes']
            additional_pairs = {(item['locale'], item['key']) for item in additional_fixes}
            extra = integration['candidateDispositions']
            extra_pairs = {(item['locale'], item['key']) for item in extra}
            if len(extra_pairs) != len(extra) or extra_pairs & set(dispositions):
                raise SystemExit('Duplicate integration candidate dispositions')
            for item in extra:
                pair = (item['locale'], item['key'])
                if not item['reason'] or item['status'] not in {'corrected', 'verified-adequate'}:
                    raise SystemExit(f'Integration candidate lacks concrete disposition: {pair}')
                if item['status'] == 'corrected' and pair not in additional_pairs:
                    raise SystemExit(f'Integration candidate lacks actual correction: {pair}')
                dispositions[pair] = item
            print(f'All {len(additional_fixes)} additional corrections and {len(extra)} integration candidate dispositions match.')
    if args.baseline:
        raw = deepcopy(historical_raw)
        for fix in fixes:
            restore_message(raw[fix['locale']], fix['key'], fix['original'])
        for tag, value in raw.items():
            restored_hash = catalog_hash(value)
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
    result = {'snapshot': ('baseline' if args.baseline else
                          'integrated-output' if integration else 'reviewed-output'),
              'resolvedNonEnglishMessages': len(english) * (len(tags) - 1),
              'candidateScalarComparisons': sum(isinstance(v, str) for v in english.values()) * (len(tags) - 1),
              'candidateCounts': dict(sorted(summary.items())), 'locales': by_locale}
    if args.baseline and dict(summary) != manifest['automatedBaseline']:
        raise SystemExit('Baseline candidate counts no longer match the review manifest')
    expected_after = integration['automatedAfter'] if integration else manifest['automatedAfter']
    if args.check_findings_resolved and dict(summary) != expected_after:
        raise SystemExit('Final candidate counts no longer match the review manifest')
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    sys.exit(main())
