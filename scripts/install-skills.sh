#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <target-skills-directory>" >&2
  echo "Examples:" >&2
  echo "  $0 .agents/skills" >&2
  echo "  $0 .claude/skills" >&2
  exit 64
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo_root/skills"
target_dir="$1"

if [ ! -d "$source_dir" ]; then
  echo "Missing source skills directory: $source_dir" >&2
  exit 1
fi

mkdir -p "$target_dir"

for skill in "$source_dir"/*; do
  [ -d "$skill" ] || continue
  [ -f "$skill/SKILL.md" ] || continue
  name="$(basename "$skill")"
  rm -rf "$target_dir/$name"
  cp -R "$skill" "$target_dir/$name"
done

echo "Installed skills from $source_dir to $target_dir"
