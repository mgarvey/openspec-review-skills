#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install-skills.sh [options] <target-skills-directory>

Options:
  --codex-current       Install into .agents/skills
  --codex-legacy        Install into .codex/skills and print a legacy warning
  --claude              Install into .claude/skills
  --skill <name[,name]> Install only selected skills; may be repeated
  --dry-run             Print actions without changing files
  --force               Allow unsafe targets and overwrite unrelated collisions
  --backup              Back up changed existing skill directories before replace
  --prune               Remove previously managed package skills no longer in source
  -h, --help            Show this help

Examples:
  ./scripts/install-skills.sh --codex-current
  ./scripts/install-skills.sh --claude --skill review-pr,review-evidence
  ./scripts/install-skills.sh --backup .agents/skills
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source_dir="$repo_root/skills"
target_arg=""
dry_run=0
force=0
backup=0
prune=0
requested_names=()

die() {
  echo "error: $*" >&2
  exit 64
}

warn() {
  echo "warning: $*" >&2
}

is_valid_name() {
  case "$1" in
    ""|*[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-]*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

contains_value() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

add_requested_name() {
  local raw="$1"
  local remaining="$raw"
  local part trimmed
  while :; do
    if [[ "$remaining" == *,* ]]; then
      part="${remaining%%,*}"
      remaining="${remaining#*,}"
    else
      part="$remaining"
      remaining=""
    fi
    trimmed="${part#"${part%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    if [ -n "$trimmed" ]; then
      is_valid_name "$trimmed" || die "invalid skill name: $trimmed"
      if ! contains_value "$trimmed" "${requested_names[@]}"; then
        requested_names+=("$trimmed")
      fi
    fi
    [ -n "$remaining" ] || break
  done
}

set_target_once() {
  local value="$1"
  if [ -n "$target_arg" ]; then
    die "target specified more than once: $target_arg and $value"
  fi
  target_arg="$value"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --codex-current)
      set_target_once ".agents/skills"
      ;;
    --codex-legacy)
      set_target_once ".codex/skills"
      ;;
    --claude)
      set_target_once ".claude/skills"
      ;;
    --dry-run)
      dry_run=1
      ;;
    --force)
      force=1
      ;;
    --backup)
      backup=1
      ;;
    --prune)
      prune=1
      ;;
    --skill)
      shift
      [ "$#" -gt 0 ] || die "--skill requires a value"
      add_requested_name "$1"
      ;;
    --skill=*)
      add_requested_name "${1#--skill=}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      set_target_once "$1"
      ;;
  esac
  shift
done

if [ "$#" -gt 0 ]; then
  die "unexpected arguments: $*"
fi

if [ ! -d "$source_dir" ]; then
  die "missing source skills directory: $source_dir"
fi

if [ -z "${target_arg//[[:space:]]/}" ]; then
  usage >&2
  die "target skills directory is required"
fi

resolve_path() {
  local input="$1"
  local path probe suffix base
  if [[ "$input" = /* ]]; then
    path="$input"
  else
    path="$PWD/$input"
  fi
  if [ "$path" != "/" ]; then
    path="${path%/}"
  fi
  if [ -e "$path" ]; then
    if [ -d "$path" ]; then
      (cd "$path" && pwd -P)
    else
      printf "%s/%s\n" "$(cd "$(dirname "$path")" && pwd -P)" "$(basename "$path")"
    fi
    return 0
  fi

  probe="$path"
  suffix=""
  while [ ! -e "$probe" ] && [ "$probe" != "/" ]; do
    suffix="/$(basename "$probe")$suffix"
    probe="$(dirname "$probe")"
  done
  base="$(cd "$probe" && pwd -P)"
  if [ "$base" = "/" ]; then
    printf "/%s\n" "${suffix#/}"
  else
    printf "%s%s\n" "$base" "$suffix"
  fi
}

target_dir="$(resolve_path "$target_arg")"
home_dir=""
if [ -n "${HOME:-}" ]; then
  home_dir="$(resolve_path "$HOME")"
fi
current_repo_root="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$current_repo_root" ]; then
  current_repo_root="$(cd "$current_repo_root" && pwd -P)"
fi

unsafe_reason=""
if [ "$target_dir" = "/" ]; then
  unsafe_reason="/"
elif [ -n "$home_dir" ] && [ "$target_dir" = "$home_dir" ]; then
  unsafe_reason="\$HOME"
elif [ "$target_dir" = "$repo_root" ]; then
  unsafe_reason="the source repository root"
elif [ -n "$current_repo_root" ] && [ "$target_dir" = "$current_repo_root" ]; then
  unsafe_reason="the current repository root"
fi

if [ -n "$unsafe_reason" ] && [ "$force" -ne 1 ]; then
  die "refusing to install into $unsafe_reason without --force"
fi

if [[ "$target_dir" = */.codex/skills ]]; then
  warn ".codex/skills is a legacy Codex install target; prefer .agents/skills"
fi

if [[ "$target_dir" = */.agents/skills ]]; then
  project_root="${target_dir%/.agents/skills}"
  if [ -d "$project_root/.codex/skills" ]; then
    warn "both .agents/skills and .codex/skills exist under $project_root; avoid installing both"
  fi
elif [[ "$target_dir" = */.codex/skills ]]; then
  project_root="${target_dir%/.codex/skills}"
  if [ -d "$project_root/.agents/skills" ]; then
    warn "both .agents/skills and .codex/skills exist under $project_root; avoid installing both"
  fi
fi

source_names=()
while IFS= read -r skill_path; do
  [ -f "$skill_path/SKILL.md" ] || continue
  source_names+=("$(basename "$skill_path")")
done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)

if [ "${#source_names[@]}" -eq 0 ]; then
  die "no source skills found in $source_dir"
fi

selected_names=()
if [ "${#requested_names[@]}" -eq 0 ]; then
  selected_names=("${source_names[@]}")
else
  for name in "${requested_names[@]}"; do
    if ! contains_value "$name" "${source_names[@]}"; then
      die "requested skill does not exist in source: $name"
    fi
    selected_names+=("$name")
  done
fi

package_name="mgarvey/openspec-review-skills"
manifest_file="$target_dir/.openspec-review-skills-manifest.json"
legacy_state_file="$target_dir/.openspec-review-skills-installed"

command -v python3 >/dev/null 2>&1 || die "python3 is required to manage the install manifest"

declare -A recorded_checksums=()
declare -A recorded_paths=()
declare -A updated_checksums=()
declare -A updated_paths=()
declare -A removed_names=()
previous_names=()

load_manifest_entries() {
  local manifest="$1"
  python3 - "$manifest" <<'PY'
import json
import sys
from pathlib import Path

manifest = Path(sys.argv[1])
data = json.loads(manifest.read_text(encoding="utf-8"))
for skill in data.get("skills", []):
    name = str(skill.get("name", ""))
    path = str(skill.get("path", name))
    checksum = str(skill.get("checksum", ""))
    if name and checksum:
        print(f"{name}\t{path}\t{checksum}")
PY
}

if [ -f "$manifest_file" ]; then
  while IFS=$'\t' read -r name path checksum; do
    [ -n "$name" ] || continue
    is_valid_name "$name" || die "invalid managed skill name in $manifest_file: $name"
    recorded_paths["$name"]="$path"
    recorded_checksums["$name"]="$checksum"
    if ! contains_value "$name" "${previous_names[@]}"; then
      previous_names+=("$name")
    fi
  done < <(load_manifest_entries "$manifest_file")
elif [ -f "$legacy_state_file" ]; then
  warn "legacy install state found at $legacy_state_file; safe replacement now requires $manifest_file"
fi

print_list() {
  local label="$1"
  shift
  echo "$label"
  if [ "$#" -eq 0 ]; then
    echo "  none"
    return
  fi
  local item
  for item in "$@"; do
    echo "  - $item"
  done
}

echo "Source: $source_dir"
echo "Target: $target_dir"
if [ "$dry_run" -eq 1 ]; then
  echo "Mode: dry run"
fi
print_list "Selected skills:" "${selected_names[@]}"

if [ "$dry_run" -eq 0 ]; then
  mkdir -p "$target_dir"
fi

backup_root="$target_dir/.backups/$(date +%Y%m%d%H%M%S)"
installed=()
skipped=()
backed_up=()
pruned=()
manifest_changed=0

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

skill_checksum() {
  local skill_path="$1"
  python3 - "$skill_path" <<'PY'
import hashlib
import os
import sys
from pathlib import Path

root = Path(sys.argv[1])
if root.is_symlink():
    root = root.resolve(strict=True)
if not root.is_dir():
    raise SystemExit(f"not a directory: {root}")

digest = hashlib.sha256()
for current, dirs, files in os.walk(root):
    dirs.sort()
    files.sort()
    current_path = Path(current)
    for dirname in list(dirs):
        path = current_path / dirname
        rel = path.relative_to(root).as_posix()
        if path.is_symlink():
            digest.update(b"L\0")
            digest.update(rel.encode("utf-8"))
            digest.update(b"\0")
            digest.update(os.readlink(path).encode("utf-8"))
            digest.update(b"\0")
            dirs.remove(dirname)
    for filename in files:
        path = current_path / filename
        rel = path.relative_to(root).as_posix()
        if path.is_symlink():
            digest.update(b"L\0")
            digest.update(rel.encode("utf-8"))
            digest.update(b"\0")
            digest.update(os.readlink(path).encode("utf-8"))
            digest.update(b"\0")
            continue
        digest.update(b"F\0")
        digest.update(rel.encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
print(digest.hexdigest())
PY
}

assert_target_child() {
  local path="$1"
  local parent base
  parent="$(cd "$(dirname "$path")" && pwd -P)"
  base="$(basename "$path")"
  if [ "$parent" != "$target_dir" ]; then
    die "refusing to modify path outside target directory: $path"
  fi
  is_valid_name "$base" || die "refusing to modify invalid skill path: $path"
}

remove_existing_path() {
  local path="$1"
  assert_target_child "$path"
  rm -rf "$path"
}

backup_existing_path() {
  local name="$1"
  local path="$2"
  local backup_dst="$backup_root/$name"
  assert_target_child "$path"
  echo "backup $name -> $backup_dst"
  backed_up+=("$name -> $backup_dst")
  if [ "$dry_run" -eq 0 ]; then
    mkdir -p "$backup_root"
    mv "$path" "$backup_dst"
  fi
}

mark_managed() {
  local name="$1"
  local path="$2"
  local checksum="$3"
  updated_paths["$name"]="$path"
  updated_checksums["$name"]="$checksum"
  if ! contains_value "$name" "${previous_names[@]}"; then
    previous_names+=("$name")
  fi
  manifest_changed=1
}

prepare_existing_for_install() {
  local name="$1"
  local dst="$2"
  local reason="$3"
  local default_allowed="$4"
  if [ "$backup" -eq 1 ]; then
    backup_existing_path "$name" "$dst"
    return 0
  fi
  if [ "$force" -eq 1 ]; then
    warn "force replacing $name ($reason)"
    echo "install $name (force replace existing)"
    if [ "$dry_run" -eq 0 ]; then
      remove_existing_path "$dst"
    fi
    return 0
  fi
  if [ "$default_allowed" -eq 1 ]; then
    echo "install $name (replace managed)"
    if [ "$dry_run" -eq 0 ]; then
      remove_existing_path "$dst"
    fi
    return 0
  fi
  die "refusing to overwrite $name ($reason); pass --backup to preserve it or --force to replace it"
}

copy_skill() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  cp -R "$src/." "$dst/"
}

for name in "${selected_names[@]}"; do
  src="$source_dir/$name"
  dst="$target_dir/$name"
  recorded_checksum="${recorded_checksums[$name]:-}"

  if path_exists "$dst"; then
    if diff -qr "$src" "$dst" >/dev/null 2>&1; then
      echo "skip $name (unchanged)"
      skipped+=("$name")
      if [ "$dry_run" -eq 0 ] && [ -z "$recorded_checksum" ]; then
        mark_managed "$name" "$name" "$(skill_checksum "$dst")"
      fi
      continue
    fi

    if [ -L "$dst" ]; then
      prepare_existing_for_install "$name" "$dst" "symlink collision" 0
    elif [ -n "$recorded_checksum" ]; then
      current_checksum="$(skill_checksum "$dst")"
      if [ "$current_checksum" = "$recorded_checksum" ]; then
        prepare_existing_for_install "$name" "$dst" "package-managed update" 1
      else
        prepare_existing_for_install "$name" "$dst" "package-managed skill has local modifications" 0
      fi
    else
      prepare_existing_for_install "$name" "$dst" "unmanaged same-name collision" 0
    fi
  else
    echo "install $name"
  fi

  installed+=("$name")
  if [ "$dry_run" -eq 0 ]; then
    copy_skill "$src" "$dst"
    mark_managed "$name" "$name" "$(skill_checksum "$dst")"
  fi
done

if [ "$prune" -eq 1 ]; then
  for name in "${previous_names[@]}"; do
    if contains_value "$name" "${source_names[@]}"; then
      continue
    fi
    dst="$target_dir/$name"
    if path_exists "$dst"; then
      recorded_checksum="${recorded_checksums[$name]:-}"
      if [ -n "$recorded_checksum" ] && [ ! -L "$dst" ] && [ "$(skill_checksum "$dst")" = "$recorded_checksum" ]; then
        echo "prune $name"
        pruned+=("$name")
        if [ "$dry_run" -eq 0 ]; then
          remove_existing_path "$dst"
        fi
      elif [ "$backup" -eq 1 ]; then
        echo "prune $name"
        pruned+=("$name")
        backup_existing_path "$name" "$dst"
      elif [ "$force" -eq 1 ]; then
        warn "force pruning $name"
        echo "prune $name"
        pruned+=("$name")
        if [ "$dry_run" -eq 0 ]; then
          remove_existing_path "$dst"
        fi
      else
        die "refusing to prune modified managed skill $name; pass --backup or --force"
      fi
    fi
    removed_names["$name"]=1
    manifest_changed=1
  done
fi

write_manifest() {
  local entries_file="$target_dir/.openspec-review-skills-manifest.entries.tmp"
  local source_commit source_description installed_at name path checksum
  source_commit="$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  source_description="https://github.com/mgarvey/openspec-review-skills"
  installed_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  : > "$entries_file"
  for name in "${previous_names[@]}"; do
    if [ -n "${removed_names[$name]+set}" ]; then
      continue
    fi
    if [ -n "${updated_checksums[$name]+set}" ]; then
      path="${updated_paths[$name]}"
      checksum="${updated_checksums[$name]}"
    else
      path="${recorded_paths[$name]:-$name}"
      checksum="${recorded_checksums[$name]:-}"
    fi
    [ -n "$checksum" ] || continue
    printf '%s\t%s\t%s\n' "$name" "$path" "$checksum" >> "$entries_file"
  done

  python3 - "$manifest_file" "$package_name" "$installed_at" "$source_commit" "$source_description" "$entries_file" <<'PY'
import json
import sys
from pathlib import Path

manifest = Path(sys.argv[1])
package = sys.argv[2]
installed_at = sys.argv[3]
source_commit = sys.argv[4]
source_description = sys.argv[5]
entries_file = Path(sys.argv[6])

skills = []
for raw in entries_file.read_text(encoding="utf-8").splitlines():
    name, path, checksum = raw.split("\t", 2)
    skills.append({"name": name, "path": path, "checksum": checksum})

skills.sort(key=lambda item: item["name"])
data = {
    "schema_version": 1,
    "package": package,
    "installed_at": installed_at,
    "source_commit": source_commit,
    "source_description": source_description,
    "skills": skills,
}
manifest.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
  rm -f "$entries_file"
}

if [ "$dry_run" -eq 0 ] && [ "$manifest_changed" -eq 1 ]; then
  write_manifest
fi

print_list "Installed:" "${installed[@]}"
print_list "Skipped:" "${skipped[@]}"
print_list "Backed up:" "${backed_up[@]}"
print_list "Pruned:" "${pruned[@]}"
echo "Done."
