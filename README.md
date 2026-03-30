# paperclip-instance-default

Local Paperclip instance repo for operational continuity and tooling.

## Scope
- This repo is intentionally scoped.
- Runtime and sensitive paths (DB, secrets, logs, data) are ignored.
- Root run/ops files are tracked for visibility and handoff.

## Tracked at root
- `AGENTS.md`
- `health-check.sh`
- `run-coderabbit.sh`
- `.gitignore`

## Purpose
- Keep a checkpointable baseline for Paperclip instance operations.
- Enable CodeRabbit and health-check workflows on safe, reviewable files.
