#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-uncommitted}"
ROOT="$(cd "$(dirname "$0")" && pwd)"

CFG=("$ROOT/CODERABBIT_RULES.md")
[[ -f "$ROOT/AGENTS.md" ]] && CFG+=("$ROOT/AGENTS.md")
[[ -f "$ROOT/CLAUDE.md" ]] && CFG+=("$ROOT/CLAUDE.md")

exec coderabbit review --cwd "$ROOT" --type "$TYPE" --plain -c "${CFG[@]}"
