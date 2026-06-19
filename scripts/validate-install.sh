#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
downstream_validator_template="$repo_root/templates/downstream-copy-workflow/scripts/validate-openspec-review-skills.sh"

fail() {
  echo "error: $*" >&2
  exit 1
}

assert_manifest_has() {
  local manifest="$1"
  local expected="$2"
  python3 - "$manifest" "$expected" <<'PY'
import json
import sys
from pathlib import Path

manifest = Path(sys.argv[1])
expected = sys.argv[2]
data = json.loads(manifest.read_text(encoding="utf-8"))
if data.get("package") != "mgarvey/openspec-review-skills":
    raise SystemExit("manifest package mismatch")
for skill in data.get("skills", []):
    if skill.get("name") == expected and skill.get("checksum"):
        raise SystemExit(0)
raise SystemExit(f"missing manifest entry for {expected}")
PY
}

install_downstream_validator() {
  local project="$1"
  mkdir -p "$project/scripts"
  cp "$downstream_validator_template" "$project/scripts/validate-openspec-review-skills.sh"
}

run_downstream_validator() {
  local project="$1"
  install_downstream_validator "$project"
  (
    cd "$project"
    bash scripts/validate-openspec-review-skills.sh
  )
}

expect_downstream_validator_failure() {
  local project="$1"
  local expected="$2"
  local output="$project/validator.out"
  install_downstream_validator "$project"
  if (
    cd "$project"
    bash scripts/validate-openspec-review-skills.sh
  ) >"$output" 2>&1; then
    fail "downstream validator unexpectedly passed for $project"
  fi
  if ! grep -Fq "$expected" "$output"; then
    cat "$output" >&2
    fail "downstream validator output did not contain: $expected"
  fi
}

target="$tmp_dir/project/.agents/skills"
mkdir -p "$tmp_dir/project"

(
  cd "$tmp_dir/project"
  bash "$repo_root/scripts/install-skills.sh" --codex-current
)

for skill in "$repo_root"/skills/*; do
  [ -d "$skill" ] || continue
  [ -f "$skill/SKILL.md" ] || continue
  name="$(basename "$skill")"
  [ -f "$target/$name/SKILL.md" ] || fail "missing installed SKILL.md for $name"
  diff -qr "$skill" "$target/$name" >/dev/null || fail "installed files differ for $name"
done
[ -f "$target/.openspec-review-skills-manifest.json" ] || fail "missing install manifest"
assert_manifest_has "$target/.openspec-review-skills-manifest.json" "review-pr"
run_downstream_validator "$tmp_dir/project"

symlink_project="$tmp_dir/symlink-project"
mkdir -p "$symlink_project"
(
  cd "$symlink_project"
  bash "$repo_root/scripts/install-skills.sh" --codex-current >/dev/null
)
rm -rf "$symlink_project/.agents/skills/review-pr"
ln -s "$repo_root/skills/review-pr" "$symlink_project/.agents/skills/review-pr"
expect_downstream_validator_failure "$symlink_project" "is a symlink"

vendor_project="$tmp_dir/vendor-project"
mkdir -p "$vendor_project"
(
  cd "$vendor_project"
  bash "$repo_root/scripts/install-skills.sh" --codex-current >/dev/null
)
mkdir -p "$vendor_project/.agents/vendor/openspec-review-skills"
expect_downstream_validator_failure "$vendor_project" ".agents/vendor/openspec-review-skills exists"

gitmodules_project="$tmp_dir/gitmodules-project"
mkdir -p "$gitmodules_project"
(
  cd "$gitmodules_project"
  bash "$repo_root/scripts/install-skills.sh" --codex-current >/dev/null
)
cat > "$gitmodules_project/.gitmodules" <<'EOF'
[submodule ".agents/vendor/openspec-review-skills"]
	path = .agents/vendor/openspec-review-skills
	url = https://github.com/mgarvey/openspec-review-skills
EOF
expect_downstream_validator_failure "$gitmodules_project" ".gitmodules references openspec-review-skills"

missing_project="$tmp_dir/missing-project"
mkdir -p "$missing_project"
(
  cd "$missing_project"
  bash "$repo_root/scripts/install-skills.sh" --codex-current >/dev/null
)
rm -rf "$missing_project/.agents/skills/review-pr"
expect_downstream_validator_failure "$missing_project" "missing managed skill directory: .agents/skills/review-pr"

legacy_project="$tmp_dir/legacy-project"
mkdir -p "$legacy_project"
(
  cd "$legacy_project"
  bash "$repo_root/scripts/install-skills.sh" --codex-current >/dev/null
)
mkdir -p "$legacy_project/.codex/skills"
cp -R "$repo_root/skills/review-pr" "$legacy_project/.codex/skills/review-pr"
expect_downstream_validator_failure "$legacy_project" ".codex/skills/review-pr exists"

(
  cd "$tmp_dir/project"
  bash "$repo_root/scripts/install-skills.sh" --codex-current >/dev/null
)
[ -f "$target/review-pr/SKILL.md" ] || fail "reinstall omitted review-pr"

modified_target="$tmp_dir/modified-managed-skills"
bash "$repo_root/scripts/install-skills.sh" --skill review-pr "$modified_target" >/dev/null
printf '\nlocal modification\n' >> "$modified_target/review-pr/SKILL.md"
if bash "$repo_root/scripts/install-skills.sh" --skill review-pr "$modified_target" >/dev/null 2>&1; then
  fail "modified managed skill was overwritten without --force or --backup"
fi
grep -q 'local modification' "$modified_target/review-pr/SKILL.md" || fail "modified managed skill was not preserved after refusal"

subset_target="$tmp_dir/subset-skills"
bash "$repo_root/scripts/install-skills.sh" --skill review-pr,review-security "$subset_target" >/dev/null
[ -f "$subset_target/review-pr/SKILL.md" ] || fail "subset install omitted review-pr"
[ -f "$subset_target/review-security/SKILL.md" ] || fail "subset install omitted review-security"
[ ! -e "$subset_target/review-code" ] || fail "subset install included unrequested review-code"

collision_target="$tmp_dir/collision-skills"
mkdir -p "$collision_target/review-pr"
printf 'local sentinel\n' > "$collision_target/review-pr/LOCAL.txt"
if bash "$repo_root/scripts/install-skills.sh" --skill review-pr "$collision_target" >/dev/null 2>&1; then
  fail "unmanaged collision was overwritten without --force or --backup"
fi
[ -f "$collision_target/review-pr/LOCAL.txt" ] || fail "unmanaged collision was not preserved after refusal"

backup_target="$tmp_dir/backup-skills"
mkdir -p "$backup_target/review-pr"
printf 'local sentinel\n' > "$backup_target/review-pr/LOCAL.txt"
bash "$repo_root/scripts/install-skills.sh" --backup --skill review-pr "$backup_target" >/dev/null
[ -f "$backup_target/review-pr/SKILL.md" ] || fail "backup install omitted review-pr"
find "$backup_target/.backups" -name LOCAL.txt -print -quit | grep -q . || fail "backup install did not preserve LOCAL.txt"

force_target="$tmp_dir/force-skills"
mkdir -p "$force_target/review-pr"
printf 'local sentinel\n' > "$force_target/review-pr/LOCAL.txt"
bash "$repo_root/scripts/install-skills.sh" --force --skill review-pr "$force_target" >/dev/null
[ -f "$force_target/review-pr/SKILL.md" ] || fail "force install omitted review-pr"
[ ! -e "$force_target/review-pr/LOCAL.txt" ] || fail "force install preserved unmanaged LOCAL.txt"

dry_target="$tmp_dir/dry-run-skills"
bash "$repo_root/scripts/install-skills.sh" --dry-run "$dry_target" >/dev/null
[ ! -e "$dry_target" ] || fail "dry run created target directory"

dry_existing_target="$tmp_dir/dry-run-existing-skills"
mkdir -p "$dry_existing_target/review-pr"
printf 'local sentinel\n' > "$dry_existing_target/review-pr/LOCAL.txt"
bash "$repo_root/scripts/install-skills.sh" --dry-run --backup --skill review-pr "$dry_existing_target" >/dev/null
[ -f "$dry_existing_target/review-pr/LOCAL.txt" ] || fail "dry run modified existing local file"
[ ! -f "$dry_existing_target/review-pr/SKILL.md" ] || fail "dry run installed files"

prune_target="$tmp_dir/prune-skills"
mkdir -p "$prune_target/local-skill"
printf 'local sentinel\n' > "$prune_target/local-skill/LOCAL.txt"
bash "$repo_root/scripts/install-skills.sh" --prune --skill review-pr "$prune_target" >/dev/null
[ -f "$prune_target/review-pr/SKILL.md" ] || fail "prune install omitted selected skill"
[ -f "$prune_target/local-skill/LOCAL.txt" ] || fail "prune removed unmanaged local skill"

echo "install validation passed"
