from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET

from luaparser import ast

ROOT = Path(__file__).resolve().parents[1]
TRACKED_ROOTS = {"strategy", "config"}
ALLOWED_SOURCE_SUFFIXES = {".lua", ".json", ".xml", ".cfg"}
ALLOWED_REPOSITORY_FILES = {
    ".gitattributes", ".gitignore", "NOTICE.md", "README.md",
    "SOURCE_MANIFEST.json", "requirements-dev.txt",
    "scripts/validate_repository.py",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    errors: list[str] = []
    lua_files = sorted(
        path for root_name in TRACKED_ROOTS
        for path in (ROOT / root_name).rglob("*.lua")
    )
    json_files = sorted(ROOT.rglob("*.json"))
    xml_files = sorted(ROOT.rglob("*.xml"))

    for path in lua_files:
        try:
            ast.parse(path.read_text(encoding="utf-8-sig"))
        except Exception as exc:
            errors.append(f"Lua parse failed: {path.relative_to(ROOT)}: {exc}")

    for path in json_files:
        if path.name == "SOURCE_MANIFEST.json":
            continue
        try:
            json.loads(path.read_text(encoding="utf-8-sig"))
        except Exception as exc:
            errors.append(f"JSON parse failed: {path.relative_to(ROOT)}: {exc}")

    for path in xml_files:
        try:
            ET.parse(path)
        except Exception as exc:
            errors.append(f"XML parse failed: {path.relative_to(ROOT)}: {exc}")

    tracked = subprocess.check_output(
        ["git", "ls-files", "-z"], cwd=ROOT
    ).decode("utf-8").split("\0")
    repository_files = [ROOT / rel for rel in tracked if rel]
    unexpected: list[str] = []
    for path in repository_files:
        rel = path.relative_to(ROOT).as_posix()
        if path.is_symlink():
            unexpected.append(f"symlink:{rel}")
            continue
        if rel in ALLOWED_REPOSITORY_FILES:
            continue
        if rel.split("/", 1)[0] in TRACKED_ROOTS and path.suffix.lower() in ALLOWED_SOURCE_SUFFIXES:
            if b"\x00" in path.read_bytes():
                unexpected.append(f"binary-content:{rel}")
            continue
        unexpected.append(rel)
    if unexpected:
        errors.append("Files outside the source-only allowlist: " + ", ".join(unexpected))

    manifest = json.loads((ROOT / "SOURCE_MANIFEST.json").read_text(encoding="utf-8"))
    expected = {item["path"]: item for item in manifest["files"]}
    actual = {
        path.relative_to(ROOT).as_posix(): path
        for root_name in TRACKED_ROOTS
        for path in (ROOT / root_name).rglob("*")
        if path.is_file()
    }
    if set(expected) != set(actual):
        errors.append("Manifest path set does not match strategy/config files")
    for rel, path in actual.items():
        item = expected.get(rel)
        if item and (item["size"] != path.stat().st_size or item["sha256"] != sha256(path)):
            errors.append(f"Manifest mismatch: {rel}")

    if errors:
        print("VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        f"PASS: {len(lua_files)} Lua files, {len(json_files) - 1} JSON configs, "
        f"{len(xml_files)} XML configs; source-only boundary and manifest verified."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
