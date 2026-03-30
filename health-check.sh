#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

FAILS=0
SKIPS=0

log() { printf "%s\n" "$*"; }
section() { printf "\n== %s ==\n" "$*"; }
pass() { printf "[PASS] %s\n" "$*"; }
skip() { printf "[SKIP] %s\n" "$*"; SKIPS=$((SKIPS+1)); }
fail() { printf "[FAIL] %s\n" "$*"; FAILS=$((FAILS+1)); }

run_step() {
  local name="$1"; shift
  if "$@"; then
    pass "$name"
  else
    fail "$name"
  fi
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

section "Repository Basics"
run_step "inside git repo" bash -lc "git rev-parse --is-inside-work-tree >/dev/null"
run_step "git object integrity (fsck)" bash -lc "git fsck --no-reflogs --no-progress >/dev/null"
run_step "no whitespace merge/conflict artifacts in diff" git diff --check -- .

section "Filesystem Integrity"
if find . -xtype l -print -quit | grep -q .; then
  find . -xtype l -print | sed 's/^/[BROKEN LINK] /'
  fail "broken symlink check"
else
  pass "broken symlink check"
fi

section "Tracked JSON Syntax"
if has_cmd python3; then
  mapfile -t JSON_FILES < <(git ls-files '*.json')
  if [ "${#JSON_FILES[@]}" -eq 0 ]; then
    skip "no tracked json files"
  else
    if python3 - <<'PY'
import json,sys,subprocess
files=subprocess.check_output(["git","ls-files","*.json"], text=True).splitlines()
errs=[]
for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as h:
            json.load(h)
    except Exception as e:
        errs.append((f,str(e)))
if errs:
    for f,e in errs:
        print(f"[INVALID JSON] {f}: {e}")
    sys.exit(1)
print(f"validated {len(files)} json file(s)")
PY
    then
      pass "json parse check"
    else
      fail "json parse check"
    fi
  fi
else
  skip "python3 not available for json parse check"
fi

section "Stack-Specific Checks (if detected at repo root)"
if [ -f package.json ]; then
  if has_cmd npm; then
    run_step "npm lint (if present)" npm run lint --if-present
    run_step "npm typecheck (if present)" npm run typecheck --if-present
    run_step "npm tests (if present)" npm test --if-present
    run_step "npm build (if present)" npm run build --if-present
  else
    skip "package.json found but npm missing"
  fi
else
  skip "no package.json at repo root"
fi

if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  if has_cmd ruff; then run_step "ruff" ruff check .; else skip "ruff not installed"; fi
  if has_cmd mypy; then run_step "mypy" mypy .; else skip "mypy not installed"; fi
  if has_cmd pytest; then run_step "pytest" pytest -q; else skip "pytest not installed"; fi
else
  skip "no python project manifest at repo root"
fi

if [ -f go.mod ]; then
  if has_cmd go; then
    run_step "go test" go test ./...
    if has_cmd golangci-lint; then run_step "golangci-lint" golangci-lint run; else skip "golangci-lint not installed"; fi
    if has_cmd govulncheck; then run_step "govulncheck" govulncheck ./...; else skip "govulncheck not installed"; fi
  else
    skip "go.mod found but go missing"
  fi
else
  skip "no go.mod at repo root"
fi

section "Summary"
log "root: $ROOT"
log "fails: $FAILS"
log "skips: $SKIPS"

if [ "$FAILS" -gt 0 ]; then
  exit 1
fi
