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

manifest="$repo_root/.agents/vendor/openspec-review-skills/skills-manifest.json"
activation_dir="$repo_root/.agents/skills"
legacy_dir="$repo_root/.codex/skills"
vendor_target_prefix="../vendor/openspec-review-skills"

[ -d "$activation_dir" ] || fail "missing .agents/skills directory"

if [ ! -f "$manifest" ]; then
  fail "OpenSpec review skills submodule is not initialized. Run: git submodule update --init --recursive"
fi

if command -v python3 >/dev/null 2>&1; then
  python_bin="python3"
else
  fail "python3 is required to read $manifest"
fi

expected_entries="$("$python_bin" - "$manifest" <<'PY'
import json
import re
import sys
from pathlib import PurePosixPath, Path

manifest = Path(sys.argv[1])
data = json.loads(manifest.read_text(encoding="utf-8"))
if data.get("package") != "mgarvey/openspec-review-skills":
    raise SystemExit("skills-manifest.json package is not mgarvey/openspec-review-skills")
skills = data.get("skills")
if not isinstance(skills, list) or not skills:
    raise SystemExit("skills-manifest.json does not contain a non-empty skills list")

seen = set()
for entry in skills:
    if not isinstance(entry, dict):
        raise SystemExit("skills-manifest.json contains a non-object skill entry")
    name = entry.get("name")
    path = entry.get("path")
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9._-]+", name):
        raise SystemExit(f"invalid skill name in skills-manifest.json: {name!r}")
    if name in seen:
        raise SystemExit(f"duplicate skill name in skills-manifest.json: {name}")
    if not isinstance(path, str) or not path:
        raise SystemExit(f"missing path for skill {name}")
    if not re.fullmatch(r"[A-Za-z0-9._/-]+", path):
        raise SystemExit(f"invalid path for skill {name}: {path!r}")
    posix_path = PurePosixPath(path)
    if posix_path.is_absolute() or ".." in posix_path.parts:
        raise SystemExit(f"unsafe path for skill {name}: {path!r}")
    seen.add(name)
    print(f"{name}\t{path}")
PY
)" || fail "could not read expected skills from $manifest"

is_expected_skill() {
  local skill_name="$1"
  printf '%s\n' "$expected_entries" | awk -F '\t' -v name="$skill_name" '$1 == name { found = 1 } END { exit !found }'
}

expected_path_for() {
  local skill_name="$1"
  printf '%s\n' "$expected_entries" | awk -F '\t' -v name="$skill_name" '$1 == name { print $2; found = 1; exit } END { if (!found) exit 1 }'
}

while IFS="$(printf '\t')" read -r skill path; do
  [ -n "$skill" ] || continue
  link="$activation_dir/$skill"
  expected_target="$vendor_target_prefix/$path"

  [ -L "$link" ] || fail ".agents/skills/$skill must be a symlink to $expected_target"

  actual_target="$(readlink "$link")"
  if [ "$actual_target" != "$expected_target" ]; then
    fail ".agents/skills/$skill points to $actual_target; expected $expected_target"
  fi

  if [ ! -f "$link/SKILL.md" ]; then
    fail ".agents/skills/$skill does not resolve to SKILL.md. Run: git submodule update --init --recursive"
  fi

  if [ -e "$legacy_dir/$skill" ] || [ -L "$legacy_dir/$skill" ]; then
    fail ".codex/skills/$skill exists; managed review skills must not be duplicated in .codex/skills"
  fi
done <<EOF
$expected_entries
EOF

for link in "$activation_dir"/*; do
  [ -e "$link" ] || [ -L "$link" ] || continue
  [ -L "$link" ] || continue

  actual_target="$(readlink "$link")"
  case "$actual_target" in
    "$vendor_target_prefix"/*)
      skill="$(basename "$link")"
      if ! is_expected_skill "$skill"; then
        fail ".agents/skills/$skill is a stale managed-skill symlink not listed in skills-manifest.json"
      fi
      expected_path="$(expected_path_for "$skill")" || fail "could not read expected path for $skill"
      expected_target="$vendor_target_prefix/$expected_path"
      if [ "$actual_target" != "$expected_target" ]; then
        fail ".agents/skills/$skill points to $actual_target; expected $expected_target"
      fi
      ;;
  esac
done

echo "OpenSpec review skills validation passed"
