#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "error: $*" >&2
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if repo_root="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  repo_root="$(cd "$script_dir/.." && pwd -P)"
fi

skills_dir="$repo_root/.agents/skills"
manifest="$skills_dir/.openspec-review-skills-manifest.json"
legacy_dir="$repo_root/.codex/skills"
vendor_dir="$repo_root/.agents/vendor/openspec-review-skills"

[ -d "$skills_dir" ] || fail "missing .agents/skills directory"

if [ -e "$vendor_dir" ] || [ -L "$vendor_dir" ]; then
  fail ".agents/vendor/openspec-review-skills exists; vendored rollout must not use a Git submodule"
fi

if [ -f "$repo_root/.gitmodules" ] && grep -Fq "openspec-review-skills" "$repo_root/.gitmodules"; then
  fail ".gitmodules references openspec-review-skills; remove the submodule and vendor real skill files instead"
fi

first_symlink="$(find "$skills_dir" -mindepth 1 -maxdepth 1 -type l -print -quit)"
if [ -n "$first_symlink" ]; then
  rel="${first_symlink#"$repo_root"/}"
  fail "$rel is a symlink; .agents/skills entries must be committed real files"
fi

if [ ! -f "$manifest" ]; then
  fail "missing .agents/skills/.openspec-review-skills-manifest.json; refresh vendored skills with install-skills.sh --codex-current"
fi

if command -v python3 >/dev/null 2>&1; then
  python_bin="python3"
else
  fail "python3 is required to read $manifest"
fi

"$python_bin" - "$repo_root" "$manifest" "$legacy_dir" <<'PY'
import hashlib
import json
import os
import re
import sys
from pathlib import Path, PurePosixPath

repo_root = Path(sys.argv[1])
manifest = Path(sys.argv[2])
legacy_dir = Path(sys.argv[3])
skills_dir = repo_root / ".agents" / "skills"


def rel(path: Path) -> str:
    return path.relative_to(repo_root).as_posix()


def checksum_skill(root: Path) -> str:
    digest = hashlib.sha256()
    for current, dirs, files in os.walk(root):
        dirs.sort()
        files.sort()
        current_path = Path(current)
        for dirname in list(dirs):
            path = current_path / dirname
            if path.is_symlink():
                raise ValueError(f"{rel(path)} is a symlink; managed skill trees must contain real files")
        for filename in files:
            path = current_path / filename
            if path.is_symlink():
                raise ValueError(f"{rel(path)} is a symlink; managed skill trees must contain real files")
            item_rel = path.relative_to(root).as_posix()
            digest.update(b"F\0")
            digest.update(item_rel.encode("utf-8"))
            digest.update(b"\0")
            digest.update(path.read_bytes())
            digest.update(b"\0")
    return digest.hexdigest()


try:
    data = json.loads(manifest.read_text(encoding="utf-8"))
except Exception as exc:
    raise SystemExit(f"error: could not read {rel(manifest)}: {exc}")

errors = []
if data.get("package") != "mgarvey/openspec-review-skills":
    errors.append(f"{rel(manifest)} package is not mgarvey/openspec-review-skills")

skills = data.get("skills")
if not isinstance(skills, list) or not skills:
    errors.append(f"{rel(manifest)} does not contain a non-empty skills list")
    skills = []

seen = set()
for entry in skills:
    if not isinstance(entry, dict):
        errors.append(f"{rel(manifest)} contains a non-object skill entry")
        continue

    name = entry.get("name")
    path = entry.get("path", name)
    expected_checksum = entry.get("checksum")

    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9._-]+", name):
        errors.append(f"invalid managed skill name in {rel(manifest)}: {name!r}")
        continue
    if name in seen:
        errors.append(f"duplicate managed skill name in {rel(manifest)}: {name}")
        continue
    seen.add(name)

    if not isinstance(path, str) or not re.fullmatch(r"[A-Za-z0-9._/-]+", path):
        errors.append(f"invalid path for managed skill {name}: {path!r}")
        continue
    posix_path = PurePosixPath(path)
    if posix_path.is_absolute() or ".." in posix_path.parts:
        errors.append(f"unsafe path for managed skill {name}: {path!r}")
        continue

    skill_dir = skills_dir / path
    skill_md = skill_dir / "SKILL.md"
    legacy_skill = legacy_dir / name

    if skill_dir.is_symlink():
        errors.append(f"{rel(skill_dir)} is a symlink; managed skills must be real directories")
        continue
    if not skill_dir.is_dir():
        errors.append(f"missing managed skill directory: {rel(skill_dir)}")
        continue
    if skill_md.is_symlink():
        errors.append(f"{rel(skill_md)} is a symlink; managed skill files must be real files")
    if not skill_md.is_file():
        errors.append(f"missing managed skill entrypoint: {rel(skill_md)}")

    if legacy_skill.exists() or legacy_skill.is_symlink():
        errors.append(f"{rel(legacy_skill)} exists; managed OpenSpec review skills must not be duplicated in .codex/skills")

    if isinstance(expected_checksum, str) and expected_checksum:
        try:
            actual_checksum = checksum_skill(skill_dir)
        except ValueError as exc:
            errors.append(str(exc))
        else:
            if actual_checksum != expected_checksum:
                errors.append(f"{rel(skill_dir)} checksum differs from {rel(manifest)}")

for error in errors:
    print(f"error: {error}", file=sys.stderr)
if errors:
    raise SystemExit(1)
PY

echo "OpenSpec review skills validation passed"
