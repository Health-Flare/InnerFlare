#!/usr/bin/env bash
# Run once after cloning: ./scripts/setup_git_hooks.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

chmod +x .githooks/* scripts/*.sh
git config core.hooksPath .githooks

echo "Git hooks installed (core.hooksPath = .githooks)."
echo "  pre-commit: dart format check + flutter analyze + offline URL scan"
echo "  pre-push:   flutter test"
echo "Skip a check on a single commit/push with --no-verify."
