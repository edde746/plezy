#!/usr/bin/env python3
"""Generate native locale declarations and permission text from the app catalog.
Run after editing translations. --check is read-only and used in CI.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[2]
I18N = ROOT / 'lib/i18n'
KEYS = {
    'NSLocalNetworkUsageDescription': 'localNetworkPermission',
    'NSLocationWhenInUseUsageDescription': 'locationPermission',
    'NSPhotoLibraryUsageDescription': 'photoLibraryPermission',
    'NSCameraUsageDescription': 'cameraPermission',
}

def identifier(text):
    return hashlib.sha256(('plezy-localization:' + text).encode()).hexdigest()[:24].upper()


def generated_outputs():
    catalog = json.loads((I18N / 'locale_catalog.json').read_text())
    locales = catalog['locales']
    parents = catalog['regionalParents']
    english = json.loads((I18N / 'en.i18n.json').read_text())['platform']
    values = {}
    for tag in locales:
        source = I18N / f'{tag}.i18n.json'
        values[tag] = json.loads(source.read_text()).get('platform', {}) if source.exists() else {}
    for tag, parent in parents.items():
        values[tag] = values[parent] | values[tag]
    # English remains the OS fallback when reviewing a new translation.
    values = {tag: english | {k: v for k, v in data.items() if v} for tag, data in values.items()}
    outputs = {}
    outputs['android/app/src/main/res/xml/locales_config.xml'] = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Generated from lib/i18n/locale_catalog.json. -->\n'
        '<locale-config xmlns:android="http://schemas.android.com/apk/res/android">\n'
        + ''.join(f'    <locale android:name="{escape(tag)}" />\n' for tag in locales)
        + '</locale-config>\n'
    )
    for platform in ('ios', 'macos'):
        for tag in locales:
            entries = KEYS if platform == 'ios' else {'NSLocalNetworkUsageDescription': 'localNetworkPermission'}
            outputs[f'{platform}/Runner/{tag}.lproj/InfoPlist.strings'] = (
                '// Generated from lib/i18n; edit the source catalog.\n'
                + ''.join(f'{json.dumps(key)} = {json.dumps(values[tag][name], ensure_ascii=False)};\n'
                          for key, name in entries.items())
            )
        plist_path = f'{platform}/Runner/Info.plist'
        plist = (ROOT / plist_path).read_text()
        plist = re.sub(r'\t<key>CFBundleLocalizations</key>\s*<array>.*?</array>\n', '', plist, flags=re.S)
        localized = '\t<key>CFBundleLocalizations</key>\n\t<array>\n' + ''.join(
            f'\t\t<string>{escape(tag)}</string>\n' for tag in locales) + '\t</array>\n'
        plist = plist.replace('\t<key>CFBundleDevelopmentRegion</key>', localized + '\t<key>CFBundleDevelopmentRegion</key>')
        for key, name in KEYS.items():
            plist = re.sub(r'(<key>' + key + r'</key>\s*<string>).*?(</string>)',
                           lambda m: m[1] + escape(english[name]) + m[2], plist, flags=re.S)
        outputs[plist_path] = plist
        project_path = f'{platform}/Runner.xcodeproj/project.pbxproj'
        project = (ROOT / project_path).read_text()
        project = re.sub(r'\n\t*/\* Begin GeneratedLocale[^\n]*\*/.*?/\* End GeneratedLocale[^\n]*\*/\n', '', project, flags=re.S)
        # Remove the two references that live in existing Xcode sections.
        project = re.sub(r'^\s*' + identifier(platform + ':group') + r' /\* InfoPlist.strings \*/,\n', '', project, flags=re.M)
        project = re.sub(r'^\s*' + identifier(platform + ':build') + r' /\* InfoPlist.strings in Resources \*/,\n', '', project, flags=re.M)
        project = re.sub(r'(knownRegions = \().*?(\n\t\t\t\);)',
                         lambda m: m[1] + ''.join(f'\n\t\t\t\t"{tag}",' for tag in ['Base', *locales]) + m[2], project, flags=re.S)
        group_id, build_id = identifier(platform + ':group'), identifier(platform + ':build')
        file_refs = ''.join(
            f'\t\t{identifier(platform + ":" + tag)} /* {tag} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = "{tag}"; path = "Runner/{tag}.lproj/InfoPlist.strings"; sourceTree = SOURCE_ROOT; }};\n'
            for tag in locales)
        sections = {
            'PBXBuildFile': f'\t\t{build_id} /* InfoPlist.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {group_id} /* InfoPlist.strings */; }};\n',
            'PBXFileReference': file_refs,
            'PBXVariantGroup': f'\t\t{group_id} /* InfoPlist.strings */ = {{\n\t\t\tisa = PBXVariantGroup;\n\t\t\tchildren = (\n'
                + ''.join(f'\t\t\t\t{identifier(platform + ":" + tag)} /* {tag} */,\n' for tag in locales)
                + '\t\t\t);\n\t\t\tname = InfoPlist.strings;\n\t\t\tsourceTree = "<group>";\n\t\t};\n',
        }
        for section, content in sections.items():
            marker = f'/* End {section} section */'
            block = f'\n/* Begin GeneratedLocale {section} */\n{content}/* End GeneratedLocale {section} */\n'
            project = project.replace(marker, block + marker)
        # The existing Info.plist group is the correct visible parent on each platform.
        project = re.sub(r'(^\s*\w+ /\* Info.plist \*/,\n)', lambda m: m[1] + f'\t\t\t\t{group_id} /* InfoPlist.strings */,\n', project, count=1, flags=re.M)
        anchor = 'Main.storyboard' if platform == 'ios' else 'MainMenu.xib'
        project = re.sub(r'(^\s*\w+ /\* ' + re.escape(anchor) + r' in Resources \*/,\n)',
                         lambda m: m[1] + f'\t\t\t\t{build_id} /* InfoPlist.strings in Resources */,\n', project, count=1, flags=re.M)
        outputs[project_path] = project
    return outputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    changed = []
    for name, text in generated_outputs().items():
        path = ROOT / name
        if not path.exists() or path.read_text() != text:
            changed.append(name)
            if not args.check:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text)
    if args.check and changed:
        print('Stale native localization files:\n' + '\n'.join(changed))
        return 1
    print(f'Native localization {"verified" if args.check else "generated"}: {len(changed)} changed files')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
