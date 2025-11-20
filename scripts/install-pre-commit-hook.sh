#!/bin/bash
# Script to install the pre-commit hook

set -e

# Get the root directory of the git repository
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$REPO_ROOT" ]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

HOOK_SOURCE="$REPO_ROOT/scripts/pre-commit"
HOOK_TARGET="$REPO_ROOT/.git/hooks/pre-commit"

if [ ! -f "$HOOK_SOURCE" ]; then
    echo "❌ Error: pre-commit hook script not found at $HOOK_SOURCE"
    exit 1
fi

# Check if hook already exists
if [ -f "$HOOK_TARGET" ]; then
    echo "⚠️  Pre-commit hook already exists at $HOOK_TARGET"
    read -p "Do you want to overwrite it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Installation cancelled"
        exit 1
    fi
    rm "$HOOK_TARGET"
fi

# Copy the hook
cp "$HOOK_SOURCE" "$HOOK_TARGET"
chmod +x "$HOOK_TARGET"

echo "✅ Pre-commit hook installed successfully!"
echo ""
echo "The hook will run flutter analyze and dart format checks before each commit."
echo "To bypass the hook (not recommended), use: git commit --no-verify"
