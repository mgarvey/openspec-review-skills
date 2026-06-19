#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
downstream_validator_template="$repo_root/templates/downstream-copy-workflow/scripts/validate-openspec-review-skills.sh"
ensure_bootstrapper="$repo_root/scripts/ensure-openspec-repo"

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

install_mock_openspec() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/openspec" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

[ "${1:-}" = "init" ] || {
  echo "unexpected openspec command: $*" >&2
  exit 2
}

mkdir -p openspec/changes openspec/specs
printf '# OpenSpec\n' > openspec/README.md
EOF
  chmod +x "$bin_dir/openspec"
}

write_legacy_codex_manifest() {
  local skills_root="$1"
  local name="$2"
  python3 - "$skills_root" "$name" <<'PY'
import hashlib
import json
import os
import sys
from pathlib import Path

skills_root = Path(sys.argv[1])
name = sys.argv[2]
skill_root = skills_root / name

h = hashlib.sha256()
for current, dirs, files in os.walk(skill_root):
    dirs.sort()
    files.sort()
    current_path = Path(current)
    for dirname in list(dirs):
        path = current_path / dirname
        rel = path.relative_to(skill_root).as_posix()
        if path.is_symlink():
            h.update(b"L\0")
            h.update(rel.encode("utf-8"))
            h.update(b"\0")
            h.update(os.readlink(path).encode("utf-8"))
            h.update(b"\0")
            dirs.remove(dirname)
    for filename in files:
        path = current_path / filename
        rel = path.relative_to(skill_root).as_posix()
        if path.is_symlink():
            h.update(b"L\0")
            h.update(rel.encode("utf-8"))
            h.update(b"\0")
            h.update(os.readlink(path).encode("utf-8"))
            h.update(b"\0")
        else:
            h.update(b"F\0")
            h.update(rel.encode("utf-8"))
            h.update(b"\0")
            h.update(path.read_bytes())
            h.update(b"\0")

manifest = {
    "schema_version": 1,
    "package": "mgarvey/openspec-review-skills",
    "installed_at": "2026-01-01T00:00:00Z",
    "source_commit": "older-managed-copy",
    "source_description": "https://github.com/mgarvey/openspec-review-skills",
    "skills": [
        {
            "name": name,
            "path": name,
            "checksum": h.hexdigest(),
        }
    ],
}
(skills_root / ".openspec-review-skills-manifest.json").write_text(
    json.dumps(manifest, indent=2) + "\n",
    encoding="utf-8",
)
PY
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
grep -Fq "https://github.com/mgarvey/openspec-review-skills" "$target/.openspec-review-skills-manifest.json" || fail "install manifest missing public source description"
! grep -Fq "$repo_root" "$target/.openspec-review-skills-manifest.json" || fail "install manifest leaked local source path"
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

mock_bin="$tmp_dir/bin"
install_mock_openspec "$mock_bin"
expected_source_commit="$(git -C "$repo_root" rev-parse HEAD)"

ensure_project="$tmp_dir/ensure-project"
mkdir -p "$ensure_project"
git -C "$ensure_project" init -q
(
  cd "$ensure_project"
  PATH="$mock_bin:$PATH" "$ensure_bootstrapper" --print-plan --force >/tmp/ensure-plan.out
  grep -q "initialize OpenSpec" /tmp/ensure-plan.out || fail "ensure print-plan did not include OpenSpec initialization"
  PATH="$mock_bin:$PATH" "$ensure_bootstrapper" --apply --force >/tmp/ensure-apply.out
  [ -d openspec ] || fail "ensure did not initialize openspec"
  [ -f .agents/skills/review-pr/SKILL.md ] || fail "ensure did not install review-pr"
  [ ! -L .agents/skills/review-pr ] || fail "ensure installed review-pr as a symlink"
  [ -f scripts/validate-openspec-review-skills.sh ] || fail "ensure did not install validator"
  [ -f .agents/skills/README.md ] || fail "ensure did not install skills README"
  [ -f .agents/skills/UPSTREAM.md ] || fail "ensure did not install upstream metadata"
  grep -Fq "Source repository: https://github.com/mgarvey/openspec-review-skills" .agents/skills/UPSTREAM.md || fail "ensure upstream metadata omitted source repository"
  grep -Fq "Source commit: $expected_source_commit" .agents/skills/UPSTREAM.md || fail "ensure upstream metadata omitted source commit"
  grep -Fq "Source exact tag:" .agents/skills/UPSTREAM.md || fail "ensure upstream metadata omitted source tag status"
  grep -Fq "Source tree state:" .agents/skills/UPSTREAM.md || fail "ensure upstream metadata omitted source tree state"
  "$ensure_bootstrapper" --check --force >/tmp/ensure-check.out
)

repair_project="$tmp_dir/ensure-repair-project"
mkdir -p "$repair_project"
git -C "$repair_project" init -q
(
  cd "$repair_project"
  PATH="$mock_bin:$PATH" "$ensure_bootstrapper" --apply --force >/dev/null
  mkdir -p .agents/vendor/openspec-review-skills
  cp "$repo_root/skills-manifest.json" .agents/vendor/openspec-review-skills/skills-manifest.json
  rm -rf .agents/skills/review-pr
  ln -s ../vendor/openspec-review-skills/skills/review-pr .agents/skills/review-pr
  mkdir -p .codex/skills
  cp -R "$repo_root/skills/review-pr" .codex/skills/review-pr
  cat > .gitmodules <<'EOF'
[submodule ".agents/vendor/openspec-review-skills"]
	path = .agents/vendor/openspec-review-skills
	url = https://github.com/mgarvey/openspec-review-skills
EOF
  PATH="$mock_bin:$PATH" "$ensure_bootstrapper" --apply --force >/tmp/ensure-repair.out
  [ ! -e .agents/vendor/openspec-review-skills ] || fail "ensure did not remove legacy vendor checkout"
  [ ! -L .agents/skills/review-pr ] || fail "ensure did not replace legacy review-pr symlink"
  [ -f .agents/skills/review-pr/SKILL.md ] || fail "ensure did not restore review-pr after symlink removal"
  [ ! -e .codex/skills/review-pr ] || fail "ensure did not remove managed .codex duplicate"
  [ ! -d .codex/skills ] || fail "ensure left empty legacy .codex/skills directory"
  ! grep -Fq "openspec-review-skills" .gitmodules || fail "ensure did not remove legacy .gitmodules section"
  bash scripts/validate-openspec-review-skills.sh >/tmp/ensure-repair-validate.out
)

uninitialized_vendor_project="$tmp_dir/ensure-uninitialized-vendor-project"
mkdir -p "$uninitialized_vendor_project/.agents/vendor/openspec-review-skills"
git -C "$uninitialized_vendor_project" init -q
(
  cd "$uninitialized_vendor_project"
  cat > .gitmodules <<'EOF'
[submodule ".agents/vendor/openspec-review-skills"]
	path = .agents/vendor/openspec-review-skills
	url = https://github.com/mgarvey/openspec-review-skills
EOF
  PATH="$mock_bin:$PATH" "$ensure_bootstrapper" --apply --force >/tmp/ensure-uninitialized-vendor.out
  [ ! -e .agents/vendor/openspec-review-skills ] || fail "ensure did not remove empty uninitialized legacy vendor directory"
  ! grep -Fq "openspec-review-skills" .gitmodules || fail "ensure did not remove uninitialized vendor .gitmodules section"
  [ -f .agents/skills/review-pr/SKILL.md ] || fail "ensure did not install review-pr after uninitialized vendor cleanup"
)

dirty_vendor_project="$tmp_dir/ensure-dirty-vendor-project"
mkdir -p "$dirty_vendor_project/.agents/vendor/openspec-review-skills"
git -C "$dirty_vendor_project" init -q
cp "$repo_root/skills-manifest.json" "$dirty_vendor_project/.agents/vendor/openspec-review-skills/skills-manifest.json"
printf 'local vendor content\n' > "$dirty_vendor_project/.agents/vendor/openspec-review-skills/LOCAL.txt"
(
  cd "$dirty_vendor_project"
  if PATH="$mock_bin:$PATH" "$ensure_bootstrapper" --print-plan --force >/tmp/ensure-dirty-vendor.out 2>&1; then
    fail "ensure allowed legacy vendor cleanup with local content"
  fi
  grep -Fq "contains local or untracked content" /tmp/ensure-dirty-vendor.out || fail "ensure did not explain dirty vendor refusal"
  [ -f .agents/vendor/openspec-review-skills/LOCAL.txt ] || fail "ensure removed dirty vendor local content"
)

legacy_manifest_codex_project="$tmp_dir/ensure-legacy-manifest-codex-project"
mkdir -p "$legacy_manifest_codex_project"
git -C "$legacy_manifest_codex_project" init -q
(
  cd "$legacy_manifest_codex_project"
  PATH="$mock_bin:$PATH" "$ensure_bootstrapper" --apply --force >/dev/null
  mkdir -p .codex/skills
  cp -R "$repo_root/skills/review-pr" .codex/skills/review-pr
  printf '\nolder managed copy\n' >> .codex/skills/review-pr/SKILL.md
  write_legacy_codex_manifest "$legacy_manifest_codex_project/.codex/skills" review-pr
  PATH="$mock_bin:$PATH" "$ensure_bootstrapper" --apply --force >/tmp/ensure-legacy-manifest-codex.out
  [ ! -e .codex/skills/review-pr ] || fail "ensure did not remove manifest-managed legacy .codex duplicate"
  [ ! -d .codex/skills ] || fail "ensure left legacy .codex/skills after removing manifest-managed duplicate"
)

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
