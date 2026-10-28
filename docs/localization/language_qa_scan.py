#!/usr/bin/env python3
"""Reproduce the bounded language-QA candidate scan; never approve fluency.

--baseline reconstructs original message values from the correction ledger.
The manifest identifies the published input and reviewed output by SHA-256.
An integration manifest verifies the complete reviewed catalog; the 2.25.0
overlay verifies later catalog additions without rewriting frozen audit records.
The historical projection reverses its correction ledger and retains the exact
original key/order shape. Machine-drafted additions are scanned separately, and
automatic scanning does not imply native-speaker review.
"""
from __future__ import annotations

import argparse
from collections import Counter
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import re
import subprocess
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


def _flat_message_changes(before, after):
    old = messages(before)
    new = messages(after)
    return set(new) - set(old), {key for key in old.keys() & new.keys() if old[key] != new[key]}


def verify_2_25_catalog_overlay(raw, tags, overlay, merge_overlay):
    """Validate current catalogs and recover the frozen QA snapshot from git."""
    if overlay['schemaVersion'] != 1 or set(overlay['catalogs']) != set(tags):
        raise SystemExit('Unexpected 2.25.0 catalog-overlay inventory')
    if overlay['baseMergeOverlaySha256'] != hashlib.sha256((DOCS / 'language_qa_merge_overlay.json').read_bytes()).hexdigest():
        raise SystemExit('The frozen merge-overlay audit changed')
    if overlay['baseIntegrationManifestSha256'] != hashlib.sha256((DOCS / 'language_qa_integration.json').read_bytes()).hexdigest():
        raise SystemExit('The frozen integration manifest changed')

    base_raw = {}
    base_hashes = {}
    additions = {}
    changes = {}
    feature_keys = set(overlay.get('additionalFeatureMessageKeys', []))
    feature_changed_keys = set(overlay.get('additionalFeatureChangedMessageKeys', []))
    if len(feature_keys) != overlay.get('additionalFeatureMessagesPerBaseLocale', len(feature_keys)):
        raise SystemExit('Additional feature-message inventory count differs')
    if feature_keys & feature_changed_keys:
        raise SystemExit('Additional feature additions overlap changed feature messages')
    for tag in tags:
        info = overlay['catalogs'][tag]
        path = info['catalogPath']
        expected_path = f'lib/i18n/{tag}.i18n.json'
        if path != expected_path:
            raise SystemExit(f'Unexpected 2.25.0 catalog path: {tag}')
        current_path = ROOT / path
        if hashlib.sha256(current_path.read_bytes()).hexdigest() != info['currentSha256']:
            raise SystemExit(f'2.25.0 catalog hash changed: {path}')
        try:
            result = subprocess.run(
                ['git', 'show', f"{overlay['baseCommit']}:{path}"],
                cwd=ROOT,
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError as error:
            raise SystemExit(f"QA base commit is unavailable: {overlay['baseCommit']}") from error
        base_bytes = result.stdout
        base_hash = hashlib.sha256(base_bytes).hexdigest()
        if base_hash != info['preOverlaySha256'] or base_hash != merge_overlay['catalogs'][tag]['currentSha256']:
            raise SystemExit(f'Frozen QA base hash differs: {path}')
        base_raw[tag] = json.loads(base_bytes)
        base_hashes[tag] = base_hash
        added, changed = _flat_message_changes(base_raw[tag], raw[tag])
        is_base_locale = tag in set(overlay['baseLocales']) | {'en'}
        feature_additions = feature_keys if is_base_locale else set()
        feature_changes = feature_changed_keys if is_base_locale else set()
        if (not feature_additions <= added or
                not feature_changes <= changed or
                len(added - feature_additions) != info['addedMessageCount'] or
                len(changed - feature_changes) != info['changedMessageCount']):
            raise SystemExit(f'2.25.0 catalog delta count changed: {path}')
        additions[tag] = added
        changes[tag] = changed

    source = messages(raw['en'])
    new_keys = set(overlay['newDraftMessageKeys'])
    fallback_keys = set(overlay.get('englishFallbackMessageKeys', []))
    if feature_keys & (new_keys | fallback_keys):
        raise SystemExit('Additional feature messages overlap the 2.25.0 draft inventory')
    if len(new_keys) != overlay['newDraftMessagesPerBaseLocale']:
        raise SystemExit('2.25.0 draft-message inventory count differs')
    if len(fallback_keys) != overlay.get('englishFallbackMessagesPerBaseLocale', 0):
        raise SystemExit('2.25.0 English-fallback inventory count differs')
    if not (new_keys | fallback_keys | feature_keys) <= set(source):
        raise SystemExit('A 2.25.0 translation has no English source message')
    if len(additions['en'] - feature_keys) != overlay['sourceMessagesAddedSinceReviewedSnapshot']:
        raise SystemExit('English source addition count differs from the 2.25.0 overlay')

    base_locales = set(overlay['baseLocales'])
    if len(base_locales) != 32 or not base_locales <= set(tags):
        raise SystemExit('Unexpected 2.25.0 base-locale inventory')
    catalog_additions = new_keys | fallback_keys
    for tag in base_locales:
        if not feature_keys <= additions[tag]:
            raise SystemExit(f'Additional feature messages are missing from {tag}')
        if not catalog_additions <= additions[tag]:
            raise SystemExit(f'New 2.25.0 messages are missing from {tag}')
        if len(additions[tag] - catalog_additions - feature_keys) != overlay['retainedMainNewTranslationKeys']:
            raise SystemExit(f'Retained main translation count differs: {tag}')

    sources = json.loads((DOCS / 'sources.json').read_text())
    batch = sources['draftModel']['latestBatch']
    if (batch['messagesPerBaseLocale'] != overlay['newDraftMessagesPerBaseLocale'] or
            batch['baseLocales'] != len(base_locales) or
            batch['targetedCorrectionCount'] != overlay['targetedCorrectionCount'] or
            sorted(batch['targetedCorrectionLocales']) != sorted(overlay['targetedCorrectionLocales'])):
        raise SystemExit('2.25.0 source-batch metadata differs')
    fallback_metadata = sources.get('intentionalEnglishFallbacks', {})
    if (fallback_metadata.get('messagesPerBaseLocale') != len(fallback_keys) or
            fallback_metadata.get('keys') != sorted(fallback_keys) or
            fallback_metadata.get('release') != overlay['release']):
        raise SystemExit('2.25.0 intentional English-fallback metadata differs')
    if hashlib.sha256((DOCS / 'sources.json').read_bytes()).hexdigest() != overlay['sourcesSha256']:
        raise SystemExit('2.25.0 source metadata hash changed')
    if hashlib.sha256((DOCS / 'translation-provenance.json').read_bytes()).hexdigest() != overlay['translationProvenanceSha256']:
        raise SystemExit('2.25.0 aggregate provenance hash changed')

    provenance = json.loads((DOCS / 'translation-provenance.json').read_text())
    if set(provenance['locales']) != set(tags):
        raise SystemExit('Translation-provenance locale inventory differs')
    per_locale = {}
    for tag in tags:
        entry = provenance['locales'][tag]
        detail_path = DOCS / entry['detail']
        detail = json.loads(detail_path.read_text())
        flat = messages(raw[tag])
        if (detail['catalogSha256'] != hashlib.sha256((ROOT / f'lib/i18n/{tag}.i18n.json').read_bytes()).hexdigest() or
                set(detail['messages']) != set(flat) or entry['catalogSha256'] != detail['catalogSha256']):
            raise SystemExit(f'Per-message provenance does not match {tag}')
        per_locale[tag] = detail['messages']

    correction_path = DOCS / overlay['correctionLedger']
    if hashlib.sha256(correction_path.read_bytes()).hexdigest() != overlay['correctionLedgerSha256']:
        raise SystemExit('2.25.0 correction ledger hash changed')
    corrections = json.loads(correction_path.read_text())
    correction_pairs = {(tag, key) for tag, values in corrections.items() for key in values}
    if len(correction_pairs) != overlay['targetedCorrectionCount']:
        raise SystemExit('2.25.0 correction count differs from the ledger')
    for tag, values in corrections.items():
        current = messages(raw[tag])
        english = messages(raw['en'])
        for key, item in values.items():
            if (item['english'] != english.get(key) or item['corrected'] != current.get(key) or
                    per_locale[tag].get(key) != 'targeted-ai-review'):
                raise SystemExit(f'2.25.0 correction/provenance mismatch: {tag}.{key}')

    for tag in base_locales:
        origins = per_locale[tag]
        for key in new_keys:
            if origins.get(key) not in {'m2m100-draft', 'targeted-ai-review', 'assistant-generated-draft'}:
                raise SystemExit(f'Unexpected draft provenance: {tag}.{key}')
            if (tag, key) in correction_pairs and origins[key] != 'targeted-ai-review':
                raise SystemExit(f'Correction provenance missing: {tag}.{key}')
        for key in fallback_keys:
            if origins.get(key) != 'english-fallback':
                raise SystemExit(f'English-fallback provenance missing: {tag}.{key}')

    regional = json.loads((ROOT / 'lib/i18n/locale_catalog.json').read_text()).get('regionalParents', {})
    resolved = {}

    def resolve(tag):
        if tag not in resolved:
            resolved[tag] = merge(resolve(regional[tag]), raw[tag]) if tag in regional else raw[tag]
        return resolved[tag]

    candidate_counts = Counter()
    candidates = {}
    english = messages(raw['en'])
    for tag in tags:
        if tag == 'en':
            continue
        flat = messages(resolve(tag))
        for key in catalog_additions:
            value = flat.get(key)
            source_text = english[key]
            if not isinstance(value, str) or not isinstance(source_text, str):
                continue
            kinds = []
            if re.search('[\u2047\ufffd]', value):
                kinds.append('corrupt_symbol')
            if len(source_text) > 80 and len(value) < len(source_text) * 0.3:
                kinds.append('short_translation')
            if re.search(r'(\b\w+\b)(?:[ ,]+\1){3}', value, re.I):
                kinds.append('repeated_word')
            if value == source_text:
                kinds.append('same_as_english')
            if kinds:
                candidates[(tag, key)] = kinds
                candidate_counts.update(kinds)
    actual_counts = dict(sorted((key, value) for key, value in candidate_counts.items() if value))
    if actual_counts != overlay['additionCandidateCounts']:
        raise SystemExit('2.25.0 draft candidate counts differ from the overlay')
    if any(any(kind in {'corrupt_symbol', 'repeated_word'} for kind in kinds) for kinds in candidates.values()):
        raise SystemExit('2.25.0 drafts contain unresolved corruption or repeated-word candidates')
    declared = {(item['locale'], item['key']): item for item in overlay['candidateDispositions']}
    actual_short = {pair for pair, kinds in candidates.items() if 'short_translation' in kinds}
    if set(declared) != actual_short or len(declared) != len(overlay['candidateDispositions']):
        raise SystemExit('2.25.0 short-translation dispositions differ from the scan')
    for pair, disposition in declared.items():
        if (disposition['status'] != 'verified-adequate' or
                disposition['finalCandidateKinds'] != candidates[pair] or not disposition['reason']):
            raise SystemExit(f'2.25.0 candidate lacks a specific disposition: {pair}')

    return base_raw, base_hashes, {
        'newDraftMessagesPerBaseLocale': len(new_keys),
        'englishFallbackMessagesPerBaseLocale': len(fallback_keys),
        'targetedCorrections': len(correction_pairs),
        'candidateCounts': actual_counts,
        'candidateDispositions': len(declared),
    }


def verify_merge_overlay(raw, tags, overlay, integration, current_hashes=None):
    """Verify the exact later merge and reconstruct the prior integration."""
    for filename, field in [('language_qa_integration.json', 'preMergeIntegrationManifestSha256'),
                            ('LANGUAGE_QA_INTEGRATION.md', 'preMergeIntegrationReportSha256')]:
        if hashlib.sha256((DOCS / filename).read_bytes()).hexdigest() != overlay[field]:
            raise SystemExit(f'Pre-merge audit artifact changed: {filename}')
    if overlay['schemaVersion'] != 1 or set(overlay['catalogs']) != set(tags):
        raise SystemExit('Unexpected merge-overlay inventory')
    key = overlay['reviewedKey']
    if key != 'discover.findNext.swipeHint' or overlay['knownUnaddressedFindings']:
        raise SystemExit('Unexpected merge-overlay semantic scope')
    source = messages(raw['en'])
    if source[key] != overlay['reviewedEnglish']:
        raise SystemExit('Reviewed merge-overlay English changed')
    for added_key, value in overlay['unreviewedNewSourceMessages'].items():
        if source.get(added_key) != value:
            raise SystemExit(f'Unreviewed new-source inventory changed: {added_key}')
    prior = deepcopy(raw)

    def node_at(value, path):
        for segment in path.split('.') if path else []:
            value = value[next(k for k in value if message_key(k) == segment)]
        return value

    def remove(value, path):
        parts = path.split('.')
        node = node_at(value, '.'.join(parts[:-1]))
        del node[next(k for k in node if message_key(k) == parts[-1])]

    for tag in tags:
        info = overlay['catalogs'][tag]
        path = f'lib/i18n/{tag}.i18n.json'
        actual_hash = (current_hashes[tag] if current_hashes is not None else
                       hashlib.sha256((ROOT / path).read_bytes()).hexdigest())
        if info['catalogPath'] != path or actual_hash != info['currentSha256']:
            raise SystemExit(f'Merge-overlay catalog hash changed: {tag}')
        flat = messages(raw[tag])
        if tag != 'en' and flat.get(key) != overlay['reviewedTranslations'].get(tag):
            raise SystemExit(f'Reviewed cover/arrow hint changed: {tag}')
        for changed_key, values in info['changedValues'].items():
            if changed_key != key or flat.get(changed_key) != values['after']:
                raise SystemExit(f'Unexpected merge-overlay text change: {tag}.{changed_key}')
            restore_message(prior[tag], changed_key, values['before'])
        for added_key in info['addedPhysicalKeys']:
            if added_key not in overlay['unreviewedNewSourceMessages'] and added_key != key:
                raise SystemExit(f'Unenumerated merge-overlay addition: {tag}.{added_key}')
            remove(prior[tag], added_key)
        for container in info['addedContainerPaths']:
            if node_at(prior[tag], container):
                raise SystemExit(f'Added container still contains unenumerated values: {tag}.{container}')
            remove(prior[tag], container)
        for container, order in info['keyOrderRestorations'].items():
            node = node_at(prior[tag], container)
            if set(order) != set(node):
                raise SystemExit(f'Unexpected pre-merge key order inventory: {tag}.{container}')
            values = {item: node[item] for item in order}
            node.clear()
            node.update(values)
        if (catalog_hash(prior[tag]) != info['preMergeSha256'] or
                info['preMergeSha256'] != integration['catalogs'][tag]['currentSha256']):
            raise SystemExit(f'Pre-merge integration hash differs: {tag}')
        if sorted(set(flat) - set(messages(prior[tag]))) != info['addedPhysicalKeys']:
            raise SystemExit(f'Merge-overlay added-key inventory differs: {tag}')
    for tag, parent in overlay['regionalPhysicalOverrides'].items():
        if overlay['reviewedTranslations'][tag] != overlay['reviewedTranslations'][parent]:
            raise SystemExit(f'Regional cover/arrow hint no longer matches reviewed parent: {tag}')
    for fix in overlay['corrections']:
        if fix['original'] == fix['corrected'] or messages(raw[fix['locale']])[fix['key']] != fix['corrected']:
            raise SystemExit('Invalid merge-overlay correction')
    return prior


def verify_integration_and_project(raw, tags, historical, integration, projected_input=False):
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
        actual_hash = (catalog_hash(raw[tag]) if projected_input else
                       hashlib.sha256((ROOT / expected_path).read_bytes()).hexdigest())
        if actual_hash != info['currentSha256']:
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
    overlay_path = DOCS / 'language_qa_merge_overlay.json'
    overlay = json.loads(overlay_path.read_text()) if overlay_path.exists() else None
    update_path = DOCS / 'language_qa_2_25_0_overlay.json'
    update = json.loads(update_path.read_text()) if update_path.exists() else None
    update_snapshot, update_hashes, update_result = (
        verify_2_25_catalog_overlay(raw, tags, update, overlay) if update else (raw, None, None)
    )
    integration_raw = (verify_merge_overlay(update_snapshot, tags, overlay, integration, update_hashes)
                       if overlay else update_snapshot)
    historical_raw = (verify_integration_and_project(integration_raw, tags, manifest, integration, bool(overlay))
                      if integration else raw)
    fix_by_key = {(fix['locale'], fix['key']): fix for fix in fixes}
    if len(fix_by_key) != len(fixes):
        raise SystemExit('Duplicate correction ledger entries')
    if args.check_reviewed_hashes:
        for tag, info in manifest['locales'].items():
            path = ROOT / info['catalogPath']
            expected = (update['catalogs'][tag]['currentSha256'] if update else
                        overlay['catalogs'][tag]['currentSha256'] if overlay else
                        integration['catalogs'][tag]['currentSha256'] if integration else info['afterSha256'])
            if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
                raise SystemExit(f'Reviewed output hash changed: {path.relative_to(ROOT)}')
        source = ROOT / 'lib/i18n/en.i18n.json'
        expected = (update['catalogs']['en']['currentSha256'] if update else
                    overlay['catalogs']['en']['currentSha256'] if overlay else
                    integration['catalogs']['en']['currentSha256'] if integration
                    else manifest['englishAfterSha256'])
        if hashlib.sha256(source.read_bytes()).hexdigest() != expected:
            raise SystemExit('Reviewed English source hash changed')
        for fix in fixes:
            if messages(update_snapshot[fix['locale']])[fix['key']] != fix['corrected']:
                raise SystemExit(f"Correction ledger mismatch: {fix['locale']}.{fix['key']}")
        print(f'Reviewed hashes and all {len(fixes)} correction records match.')
        if integration:
            count = integration['coverage']['integrationDirectUniqueLocaleMessages']
            layer = 'Pre-merge integration' if overlay else 'Current integration'
            print(f'{layer} hashes and all {count} directly reviewed values reproduce; '
                  'all 37 historical reviewed hashes are reproduced by the exact key/order projection.')
        if overlay:
            print('Merge overlay: 36 reviewed physical cover/arrow hints match; 19 new source paths '
                  'remain explicitly outside semantic review; all 37 pre-merge integration hashes reproduce.')
        if update_result:
            print(f"PlezyNG 2.25.0 catalog overlay: {update_result['newDraftMessagesPerBaseLocale']} "
                  f"draft messages per base locale, {update_result['targetedCorrections']} targeted AI corrections; "
                  f"candidate counts {update_result['candidateCounts']} with "
                  f"{update_result['candidateDispositions']} concise-text dispositions.")
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
            if fix['original'] == fix['corrected'] or messages(update_snapshot[fix['locale']])[fix['key']] != fix['corrected']:
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
        scan_raw = deepcopy(historical_raw)
        for fix in fixes:
            restore_message(scan_raw[fix['locale']], fix['key'], fix['original'])
        for tag, value in scan_raw.items():
            restored_hash = catalog_hash(value)
            expected_hash = (manifest['englishBeforeSha256'] if tag == 'en'
                             else manifest['locales'][tag]['beforeSha256'])
            if restored_hash != expected_hash:
                raise SystemExit(f'Reconstructed published-input hash differs: {tag}')
    else:
        scan_raw = update_snapshot
    resolved = {}

    def resolve(tag):
        if tag not in resolved:
            parent = catalog.get('regionalParents', {}).get(tag)
            resolved[tag] = merge(resolve(parent), scan_raw[tag]) if parent else scan_raw[tag]
        return resolved[tag]

    english = messages(scan_raw['en'])
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
                          'merge-overlay-output' if overlay else
                          'integrated-output' if integration else 'reviewed-output'),
              'resolvedNonEnglishMessages': len(english) * (len(tags) - 1),
              'candidateScalarComparisons': sum(isinstance(v, str) for v in english.values()) * (len(tags) - 1),
              'candidateCounts': dict(sorted(summary.items())), 'locales': by_locale}
    if args.baseline and dict(summary) != manifest['automatedBaseline']:
        raise SystemExit('Baseline candidate counts no longer match the review manifest')
    expected_after = (overlay['automatedAfter'] if overlay else
                      integration['automatedAfter'] if integration else manifest['automatedAfter'])
    if args.check_findings_resolved and dict(summary) != expected_after:
        raise SystemExit('Final candidate counts no longer match the review manifest')
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    sys.exit(main())
