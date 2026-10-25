from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

from luaparser import ast

ROOT = Path(__file__).resolve().parents[1]
FORBIDDEN_SUFFIXES = {
    ".exe", ".dll", ".lib", ".pdb", ".obj", ".exp", ".ilk",
    ".sdf", ".suo", ".tlog", ".idb", ".ipch", ".vdata", ".dmp",
    ".zip", ".7z", ".rar",
}
TRACKED_ROOTS = {"strategy", "config"}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    errors: list[str] = []
    lua_files = sorted((ROOT / "strategy").rglob("*.lua"))
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

    forbidden = [
        path.relative_to(ROOT).as_posix()
        for path in ROOT.rglob("*")
        if path.is_file() and path.suffix.lower() in FORBIDDEN_SUFFIXES
    ]
    if forbidden:
        errors.append("Forbidden binary/archive files: " + ", ".join(forbidden))

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
