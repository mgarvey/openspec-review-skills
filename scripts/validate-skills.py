#!/usr/bin/env python3
"""Validate the portable review skill package without third-party packages."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SKILLS_DIR = REPO_ROOT / "skills"
MANIFEST_PATH = REPO_ROOT / "skills-manifest.json"
PACKAGE_NAME = "mgarvey/openspec-review-skills"
MAX_DESCRIPTION_LENGTH = 240

SENSITIVE_PATTERNS = [
    (
        "secret-looking assignment",
        re.compile(
            r"(?i)\b(?:password|passwd|api[_-]?key|token|secret|client[_-]?secret)"
            r"\s*[:=]\s*['\"]?[A-Za-z0-9_./+=-]{12,}"
        ),
    ),
    ("private key block", re.compile(r"-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----")),
    ("AWS access key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("GitHub token", re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b")),
    ("Slack token", re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{20,}\b")),
    (
        "private absolute path",
        re.compile(r"(?<![A-Za-z0-9_./-])(?:/Users|/Volumes|/home)/[A-Za-z0-9._-]+"),
    ),
    (
        "private IPv4 address",
        re.compile(r"\b(?:10|192\.168|172\.(?:1[6-9]|2[0-9]|3[0-1]))\.\d{1,3}\.\d{1,3}\b"),
    ),
    (
        "internal-looking hostname",
        re.compile(r"\b[a-z0-9-]+(?:\.[a-z0-9-]+)*\.(?:internal|corp|lan|local)\b", re.I),
    ),
    ("12 digit account id", re.compile(r"\b\d{12}\b")),
]


class Validation:
    def __init__(self) -> None:
        self.errors: list[str] = []

    def fail(self, message: str) -> None:
        self.errors.append(message)

    def finish(self) -> None:
        if self.errors:
            for error in self.errors:
                print(f"error: {error}", file=sys.stderr)
            raise SystemExit(1)


def parse_frontmatter(path: Path, validation: Validation) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        validation.fail(f"{path.relative_to(REPO_ROOT)} missing YAML frontmatter")
        return {}

    end = None
    for index, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            end = index
            break
    if end is None:
        validation.fail(f"{path.relative_to(REPO_ROOT)} has unterminated YAML frontmatter")
        return {}

    fields: dict[str, str] = {}
    for raw in lines[1:end]:
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if ":" not in raw:
            validation.fail(f"{path.relative_to(REPO_ROOT)} has unsupported frontmatter line: {raw}")
            continue
        key, value = raw.split(":", 1)
        key = key.strip()
        value = value.strip()
        if (value.startswith('"') and value.endswith('"')) or (
            value.startswith("'") and value.endswith("'")
        ):
            value = value[1:-1]
        fields[key] = value
    return fields


def skill_dirs() -> list[Path]:
    if not SKILLS_DIR.is_dir():
        return []
    return sorted(
        path for path in SKILLS_DIR.iterdir() if path.is_dir() and (path / "SKILL.md").is_file()
    )


def validate_skill_frontmatter(validation: Validation) -> dict[str, Path]:
    names: dict[str, Path] = {}
    for skill_dir in skill_dirs():
        skill_md = skill_dir / "SKILL.md"
        fields = parse_frontmatter(skill_md, validation)
        name = fields.get("name", "").strip()
        description = fields.get("description", "").strip()
        rel = skill_md.relative_to(REPO_ROOT)

        if not name:
            validation.fail(f"{rel} missing required name")
        elif name in names:
            validation.fail(f"duplicate skill name {name}: {rel} and {names[name].relative_to(REPO_ROOT)}")
        else:
            names[name] = skill_dir

        if not description:
            validation.fail(f"{rel} missing required description")
        elif len(description) > MAX_DESCRIPTION_LENGTH:
            validation.fail(
                f"{rel} description is {len(description)} characters; max is {MAX_DESCRIPTION_LENGTH}"
            )
    return names


def validate_openai_metadata(names: dict[str, Path], validation: Validation) -> None:
    for name, skill_dir in names.items():
        metadata = skill_dir / "agents" / "openai.yaml"
        rel = metadata.relative_to(REPO_ROOT)
        if not metadata.is_file():
            validation.fail(f"{name} missing {rel}")
            continue

        text = metadata.read_text(encoding="utf-8")
        if "display_name:" not in text or "short_description:" not in text:
            validation.fail(f"{rel} missing interface display metadata")

        has_false = re.search(r"(?im)^\s*allow_implicit_invocation:\s*false\s*$", text) is not None
        if name == "review-code":
            if not has_false:
                validation.fail("review-code must set policy.allow_implicit_invocation: false")
        elif has_false:
            validation.fail(f"{name} should not disable implicit invocation")


def validate_activation_mirrors(validation: Validation) -> None:
    for mirror in (REPO_ROOT / ".agents" / "skills", REPO_ROOT / ".codex" / "skills"):
        if mirror.exists():
            validation.fail(f"activation mirror must not be checked in: {mirror.relative_to(REPO_ROOT)}")


def iter_repo_files() -> list[Path]:
    ignored_parts = {".git", "__pycache__"}
    files: list[Path] = []
    for path in REPO_ROOT.rglob("*"):
        if not path.is_file():
            continue
        if any(part in ignored_parts for part in path.relative_to(REPO_ROOT).parts):
            continue
        files.append(path)
    return sorted(files)


def validate_public_safety(validation: Validation) -> None:
    for path in iter_repo_files():
        data = path.read_bytes()
        if b"\0" in data:
            continue
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            continue
        for label, pattern in SENSITIVE_PATTERNS:
            match = pattern.search(text)
            if match:
                rel = path.relative_to(REPO_ROOT)
                validation.fail(f"{rel} contains {label}: {match.group(0)!r}")
                break


def validate_routing_cases(names: dict[str, Path], validation: Validation) -> None:
    fixture = REPO_ROOT / "tests" / "routing-cases.yml"
    if not fixture.is_file():
        validation.fail("missing tests/routing-cases.yml")
        return

    text = fixture.read_text(encoding="utf-8")
    found = False
    for key in ("expected_skill", "forbidden_skill"):
        for match in re.finditer(rf"(?m)^\s*{key}:\s*([A-Za-z0-9._-]+)\s*$", text):
            found = True
            name = match.group(1)
            if name not in names:
                validation.fail(f"tests/routing-cases.yml references unknown {key}: {name}")
    if not found:
        validation.fail("tests/routing-cases.yml does not contain expected_skill or forbidden_skill entries")


def hash_skill_dir(skill_dir: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(p for p in skill_dir.rglob("*") if p.is_file()):
        rel = path.relative_to(skill_dir).as_posix()
        digest.update(rel.encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def build_manifest(names: dict[str, Path]) -> dict[str, object]:
    skills = []
    for name in sorted(names):
        skill_dir = names[name]
        skills.append(
            {
                "name": name,
                "path": skill_dir.relative_to(REPO_ROOT).as_posix(),
                "sha256": hash_skill_dir(skill_dir),
            }
        )
    return {"schema_version": 1, "package": PACKAGE_NAME, "skills": skills}


def validate_manifest(manifest: dict[str, object], write_manifest: bool, validation: Validation) -> None:
    rendered = json.dumps(manifest, indent=2, sort_keys=False) + "\n"
    if write_manifest:
        MANIFEST_PATH.write_text(rendered, encoding="utf-8")
        return

    if not MANIFEST_PATH.is_file():
        validation.fail("missing skills-manifest.json; run scripts/validate-skills.py --write-manifest")
        return
    current = MANIFEST_PATH.read_text(encoding="utf-8")
    if current != rendered:
        validation.fail("skills-manifest.json is stale; run scripts/validate-skills.py --write-manifest")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-manifest", action="store_true", help="write skills-manifest.json")
    args = parser.parse_args()

    validation = Validation()
    names = validate_skill_frontmatter(validation)
    validate_openai_metadata(names, validation)
    validate_activation_mirrors(validation)
    validate_routing_cases(names, validation)
    validate_public_safety(validation)
    manifest = build_manifest(names)
    validate_manifest(manifest, args.write_manifest, validation)
    validation.finish()
    print("skill validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
