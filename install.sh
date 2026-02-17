#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

# Determine project root
if [ -n "${1:-}" ]; then
  root="$(cd "$1" && pwd)"
elif [[ "$script_dir" == *node_modules* ]]; then
  root="${script_dir%%/node_modules/*}"
else
  # npm prep phase (cache dir) — skip silently
  exit 0
fi

echo "Installing claude-lens to $root/.claude/"

# Create target directories
mkdir -p "$root/.claude/skills"
mkdir -p "$root/.claude/canon"
mkdir -p "$root/.claude/phases"
mkdir -p "$root/.claude/rubric"
mkdir -p "$root/.claude/config"
mkdir -p "$root/.claude/scripts"

# --- Skills: always overwrite (get latest scanner + workflows) ---
skill_count=0
for d in "$script_dir"/skills/*/; do
  name=$(basename "$d")
  mkdir -p "$root/.claude/skills/$name"
  cp -r "$d"* "$root/.claude/skills/$name/"
  skill_count=$((skill_count + 1))
done

# --- Canon: always overwrite (teaching skills are upstream-owned) ---
canon_count=0
for d in "$script_dir"/canon/*/; do
  name=$(basename "$d")
  mkdir -p "$root/.claude/canon/$name"
  cp -r "$d"* "$root/.claude/canon/$name/"
  canon_count=$((canon_count + 1))
done

# --- Phases: always overwrite ---
phase_count=0
for d in "$script_dir"/phases/*/; do
  name=$(basename "$d")
  mkdir -p "$root/.claude/phases/$name"
  cp -r "$d"* "$root/.claude/phases/$name/"
  phase_count=$((phase_count + 1))
done

# --- Rubric: skip files with local edits ---
rubric_count=0
rubric_skipped=0
for f in "$script_dir"/rubric/*.md; do
  target="$root/.claude/rubric/$(basename "$f")"
  if [ -f "$target" ]; then
    if ! diff -q "$f" "$target" > /dev/null 2>&1; then
      echo "  skip rubric: $(basename "$f") (local changes)"
      rubric_skipped=$((rubric_skipped + 1))
      continue
    fi
  fi
  cp "$f" "$target"
  rubric_count=$((rubric_count + 1))
done

# --- Config: skip files with local edits ---
config_skipped=0
for f in "$script_dir"/config/*; do
  target="$root/.claude/config/$(basename "$f")"
  if [ -f "$target" ]; then
    if ! diff -q "$f" "$target" > /dev/null 2>&1; then
      echo "  skip config: $(basename "$f") (local changes)"
      config_skipped=$((config_skipped + 1))
      continue
    fi
  fi
  cp "$f" "$target"
done

# --- Scripts: always overwrite ---
cp "$script_dir"/scripts/* "$root/.claude/scripts/"

# --- Lessons: seed only if missing ---
if [ ! -f "$root/.claude/universal-lessons.md" ]; then
  cp "$script_dir/lessons.md" "$root/.claude/universal-lessons.md"
  echo "  seeded: universal-lessons.md"
else
  echo "  kept: universal-lessons.md (existing)"
fi

echo ""
echo "claude-lens installed to $root/.claude/"
echo "  skills:  $skill_count"
echo "  canon:   $canon_count"
echo "  phases:  $phase_count"
echo "  rubric:  $rubric_count installed, $rubric_skipped skipped"
echo "  config:  $(ls "$root/.claude/config/" 2>/dev/null | wc -l | tr -d ' ') files"
echo "  scripts: $(ls "$root/.claude/scripts/" 2>/dev/null | wc -l | tr -d ' ') files"
