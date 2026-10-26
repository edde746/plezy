#!/usr/bin/env python3
"""Keep unit quantities grammatical using the committed Unicode CLDR patterns.

These messages are generated from locale_units.g.dart. Runtime plural
selection remains Slang's responsibility. Run after adding a locale.
"""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
I18N = ROOT / 'lib/i18n'

def format_plural_numbers(node):
    """Keep cardinal selection numeric and format its displayed numeral separately.

    The inline formatter reads the live regional preference on every call; a
    Slang cached @@type formatter would retain the previous region.
    """
    for key, value in node.items():
        if not isinstance(value, dict):
            continue
        if 'other' in value and set(value) <= {'zero', 'one', 'two', 'few', 'many', 'other'}:
            match = re.search(r'param=(\w+)', key)
            parameter = match.group(1) if match else 'n'
            pattern = re.compile(r'\$\{' + parameter + r'(?:\s*:[^}]+)?\}|\$' + parameter + r'\b')
            replacement = '${' + parameter + ': NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)}'
            for category, text in value.items():
                value[category] = pattern.sub(lambda _: replacement, text)
        else:
            format_plural_numbers(value)

def generate(check=False):
    data = (I18N / 'locale_units.g.dart').read_text()
    units = json.loads(data[data.index('{'):data.rindex('}') + 1])
    changed = []
    for file in sorted(I18N.glob('*.i18n.json')):
        tag = file.name.removesuffix('.i18n.json')
        original = file.read_text()
        catalog = json.loads(original)
        for group, key, parameter, unit in (
            ('settings', 'secondsUnit', 'seconds', 'second'),
            ('settings', 'minutesUnit', 'minutes', 'minute'),
            ('music', 'sleepTimerMinutes', 'n', 'minute'),
            ('fileSources', 'minutes', 'count', 'minute'),
        ):
            section = catalog.setdefault(group, {})
            forms = {category: text.replace('{value}', '${' + parameter + '}')
                     for category, text in units[tag][unit]['long'].items()}
            target = key if parameter == 'n' else f'{key}(param={parameter})'
            # Preserve the original position where possible.
            if key in section and target != key:
                catalog[group] = {target if k == key else k: forms if k == key else v for k, v in section.items()}
            else:
                section[target] = forms
        format_plural_numbers(catalog)
        # The hygiene pass orders plural forms to match the source. Equivalent
        # JSON ordering must not make the two generators fight each other.
        text = original if catalog == json.loads(original) else json.dumps(catalog, ensure_ascii=False, indent=2) + '\n'
        if text != original:
            changed.append(file.name)
            if not check:
                file.write_text(text)
    if check and changed:
        print('Stale quantity messages: ' + ', '.join(changed))
        return 1
    print(f'Localized quantities {"verified" if check else "generated"}: {len(changed)} changed catalogs')
    return 0

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    raise SystemExit(generate(parser.parse_args().check))
