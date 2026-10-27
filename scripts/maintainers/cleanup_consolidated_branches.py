"""One-time, atomic deletion of reviewed branches whose history is preserved."""
import argparse
import base64
import json
import os
import re
import subprocess
import tempfile

REPOSITORY = 'snapetech-org/PlezyNG'
PROTECTED = {'main', 'master'}
MANIFEST = 'docs/maintainers/branch-consolidation-2026-10-27.json'
SHA = re.compile(r'^[0-9a-f]{40}$')


def deletion_plan(manifest, heads, run_sha, anchor, ancestor):
    if manifest.get('repository') != REPOSITORY:
        raise ValueError('Unexpected repository')
    if manifest.get('integration_commit') != anchor or not SHA.fullmatch(anchor):
        raise ValueError('Unexpected integration anchor')
    if heads.get('main') != run_sha:
        raise ValueError('Main moved; review the newer head before retrying')
    entries = manifest.get('branches', [])
    indexed = {}
    for entry in entries:
        name, sha = entry['name'], entry['sha']
        if name in indexed or not SHA.fullmatch(sha):
            raise ValueError('Invalid or duplicate manifest entry')
        if name in PROTECTED:
            if entry['action'] != 'keep':
                raise ValueError('Protected branch cannot be deleted')
        elif entry['action'] != 'delete-after-integration':
            raise ValueError('Branch has no explicit deletion authorization')
        indexed[name] = entry
    if set(heads) - set(indexed) - PROTECTED:
        raise ValueError('New branches appeared; review them before cleanup')
    plan = []
    for name, entry in indexed.items():
        if name in PROTECTED or name not in heads:
            continue
        if heads[name] != entry['sha']:
            raise ValueError(f'Branch moved: {name}')
        if not ancestor(entry['sha'], anchor):
            raise ValueError(f'Head is not preserved in integration history: {name}')
        plan.append((name, entry['sha']))
    return plan


def push_arguments(plan):
    return (['push', '--atomic']
            + [f'--force-with-lease=refs/heads/{name}:{sha}' for name, sha in plan]
            + ['origin'] + [f':refs/heads/{name}' for name, _ in plan])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true', help='Delete the verified branch names; default only previews.')
    args = parser.parse_args()
    env = dict(os.environ)
    env.update({'GIT_TERMINAL_PROMPT': '0', 'GIT_TRACE': '0', 'GIT_CURL_VERBOSE': '0', 'GIT_TRACE_CURL': '0'})
    # Use normal configured Git authentication. In Actions or other automation,
    # GH_TOKEN may supply a short-lived contents-write token without persistence.
    token = os.environ.get('GH_TOKEN')
    if token:
        env.update({
            'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': os.devnull,
            'GIT_CONFIG_COUNT': '1', 'GIT_CONFIG_KEY_0': 'http.https://github.com/.extraheader',
            'GIT_CONFIG_VALUE_0': 'AUTHORIZATION: basic ' + base64.b64encode(('x-access-token:' + token).encode()).decode(),
        })
    with tempfile.TemporaryDirectory(prefix='plezyng-branch-cleanup-') as directory:
        def git(*arguments, check=True):
            return subprocess.run(['git', *arguments], cwd=directory, env=env, check=check, capture_output=True, text=True)
        git('init', '--quiet')
        git('remote', 'add', 'origin', f'https://github.com/{REPOSITORY}.git')
        def remote_heads():
            return {ref.removeprefix('refs/heads/'): sha for sha, ref in
                    (row.split('\t', 1) for row in git('ls-remote', '--heads', 'origin').stdout.splitlines())}
        run_sha = remote_heads()['main']
        if not SHA.fullmatch(run_sha):
            raise ValueError('Invalid main commit')
        # Fetch commit/tree history and the one manifest blob, not app assets.
        git('fetch', '--quiet', '--filter=blob:none', '--no-tags', 'origin', run_sha)
        raw = git('show', f'{run_sha}:{MANIFEST}').stdout
        manifest = json.loads(raw)
        anchor = manifest['integration_commit']
        if not SHA.fullmatch(anchor):
            raise ValueError('Invalid integration anchor')
        def ancestor(sha, target):
            return git('merge-base', '--is-ancestor', sha, target, check=False).returncode == 0
        if not ancestor(anchor, run_sha):
            raise ValueError('Main does not preserve the integration commit')
        plan = deletion_plan(manifest, remote_heads(), run_sha, anchor, ancestor)
        for name, _ in plan:
            git('check-ref-format', 'refs/heads/' + name)
        print(f'Verified {len(plan)} unchanged branch heads preserved by {anchor}.', flush=True)
        for name, sha in plan:
            print(f'{name} {sha}')
        if not args.apply:
            print('Preview only. Use --apply with authenticated Git access to remove these branch names.')
            return
        if plan:
            # Leases reject concurrently updated branches. Atomic push removes
            # all reviewed names together or none; main/master are never pushed.
            result = git(*push_arguments(plan))
            print(result.stdout, end='')
            print(result.stderr, end='')
        remaining = remote_heads()
        if set(remaining) - PROTECTED:
            raise ValueError('Additional branches remain; review before retrying')
        print('Remaining branches: ' + ', '.join(sorted(remaining)), flush=True)


if __name__ == '__main__':
    main()
