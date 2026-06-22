#!/usr/bin/env python3
"""Validate the Codex plugin manifest without third-party packages."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PLUGIN_PATH = REPO_ROOT / ".codex-plugin" / "plugin.json"
SEMVER_RE = re.compile(
    r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
    r"(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$"
)


class Validation:
    def __init__(self) -> None:
        self.errors: list[str] = []

    def fail(self, message: str) -> None:
        self.errors.append(message)

    def require_string(self, payload: dict[str, object], key: str, prefix: str = "") -> str:
        value = payload.get(key)
        field = f"{prefix}.{key}" if prefix else key
        if not isinstance(value, str) or not value.strip():
            self.fail(f"plugin.json field {field!r} must be a non-empty string")
            return ""
        return value

    def finish(self) -> None:
        if self.errors:
            for error in self.errors:
                print(f"error: {error}", file=sys.stderr)
            raise SystemExit(1)


def load_manifest(validation: Validation) -> dict[str, object]:
    if not PLUGIN_PATH.is_file():
        validation.fail("missing .codex-plugin/plugin.json")
        return {}
    try:
        data = json.loads(PLUGIN_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        validation.fail(f".codex-plugin/plugin.json is not valid JSON: {exc}")
        return {}
    if not isinstance(data, dict):
        validation.fail(".codex-plugin/plugin.json must contain a JSON object")
        return {}
    return data


def validate_manifest(data: dict[str, object], validation: Validation) -> None:
    name = validation.require_string(data, "name")
    if name and not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name):
        validation.fail("plugin.json field 'name' must be lowercase kebab-case")

    version = validation.require_string(data, "version")
    if version and not SEMVER_RE.fullmatch(version):
        validation.fail("plugin.json field 'version' must be semver")

    validation.require_string(data, "description")

    author = data.get("author")
    if not isinstance(author, dict):
        validation.fail("plugin.json field 'author' must be an object")
    else:
        validation.require_string(author, "name", "author")

    skills = validation.require_string(data, "skills")
    if skills != "./skills/":
        validation.fail("plugin.json field 'skills' must be './skills/'")
    elif not (REPO_ROOT / "skills").is_dir():
        validation.fail("plugin.json points to missing skills directory")

    interface = data.get("interface")
    if not isinstance(interface, dict):
        validation.fail("plugin.json field 'interface' must be an object")
        return

    for key in (
        "displayName",
        "shortDescription",
        "longDescription",
        "developerName",
        "category",
    ):
        validation.require_string(interface, key, "interface")

    capabilities = interface.get("capabilities")
    if not isinstance(capabilities, list) or not capabilities:
        validation.fail("plugin.json field 'interface.capabilities' must be a non-empty array")
    elif not all(isinstance(value, str) and value.strip() for value in capabilities):
        validation.fail("plugin.json field 'interface.capabilities' must contain strings")

    default_prompt = interface.get("defaultPrompt")
    if not isinstance(default_prompt, list) or not default_prompt:
        validation.fail("plugin.json field 'interface.defaultPrompt' must be a non-empty array")
    elif not all(isinstance(value, str) and value.strip() for value in default_prompt):
        validation.fail("plugin.json field 'interface.defaultPrompt' must contain strings")


def main() -> int:
    validation = Validation()
    data = load_manifest(validation)
    if data:
        validate_manifest(data, validation)
    validation.finish()
    print("plugin validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
