#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate translation.json and localization_catalog.json from JP/EN SWRC assets.

The generated translation JSON intentionally contains no Chinese translation:
every user-editable ``zh_CN`` field is left blank.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from collections import Counter, OrderedDict, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


TRANSLATION_SCHEMA = 2
CATALOG_SCHEMA = 1
TOOL_NAME = "make_translation_json.py"
SHARED_GROUP = "shared.enjp"
SHARED_ID_START = 100001
OUTPUT_EXT = ".cht"

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
ROOT_DIR = SCRIPT_DIR.parent
LANG_DIR = ROOT_DIR.parent
GAME_ROOT = LANG_DIR.parent
GAME_DATA = GAME_ROOT / "GameData"
SYSTEM_DIR = GAME_DATA / "System"
PROPERTIES_DIR = GAME_DATA / "Properties"
MAPS_DIR = GAME_DATA / "Maps"
JP_SYSTEM_DIR = LANG_DIR / "JapanesePack" / "System"
EXPORT_DIR = ROOT_DIR / "reference" / "export"

TRANSLATION_JSON = ROOT_DIR / "translation.json"
CATALOG_JSON = EXPORT_DIR / "localization_catalog.json"
AUDIT_JSON = EXPORT_DIR / "localization_audit.json"
JP_ONLY_SKIPPED_JSON = EXPORT_DIR / "localization_jp_only_skipped.json"

SUPPLEMENTARY_EN_DIR = LANG_DIR / "TranslationPackFormOnline" / "English Files"
DE_SYSTEM_DIR = LANG_DIR / "TranslationPackFormOnline" / "German Files"

SUPPLEMENTARY_MENU_SECTIONS = {
    "CTControllerOptionsPSMenu",
    "CTControllerOptionsRemapPSMenu",
    "CTGameOptionsPSMenu",
    "CTHUDOptionsPSMenu",
    "CTIncapLoadConfirmMenu",
    "CTMissingContentMenu",
    "CTOptionsPSMenu",
    "CTPauseHintText",
    "CTPausePSMenu",
    "CTSoundGraphicsOptionsPSMenu",
    "CTStartPCMenu",
    "CTStartPSMenu",
    "CT_PCDemo_Splash",
}

TEMP_EXPORT_ROOT = Path(os.environ.get("SWRC_EXPORT_TMP", "D:/swrc_localization_export_tmp"))

PRINTF_RE = re.compile(
    r"%(?!%)(?:\d+\$)?[-+#0]*(?:\*|\d+)?(?:\.(?:\*|\d+))?"
    r"(?:hh|h|ll|l|L)?([A-Za-z])"
)
SAFE_GROUP_RE = re.compile(r"^[A-Za-z0-9_.-]+$")
ARRAY_KEY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\[(\d+)\](?:\.(.*))?$")
UC_ARRAY_RE = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)\((\d+)\)")
BEGIN_OBJECT_RE = re.compile(r"^Begin\s+(?:Actor|Object)\s+.*?\bClass=([^\s]+)\s+.*?\bName=([^\s]+)", re.IGNORECASE)
CLASS_RE = re.compile(r"^\s*class\s+([A-Za-z_][A-Za-z0-9_]*)\s+extends\s+([A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)
STRUCT_TEXT_FIELDS = {"Caption", "Parent", "Text", "HelpText", "Objective"}
from localization_common import FALLBACK_REPLACEMENTS, normalize_fallback_text


class GenerateError(Exception):
    pass


@dataclass
class IntRow:
    file_name: str
    line_no: int
    section: str
    key: str
    value: str
    raw: str


@dataclass
class SourceValue:
    kind: str
    raw: str
    text: str | None = None
    style: str = "quoted"
    items: list[str] | None = None
    template_fields: list[tuple[str, str, str, str]] | None = None


@dataclass
class AllocationResult:
    group: str
    entry_id: str
    previous: dict | None = None


def fail(message: str) -> None:
    raise GenerateError(message)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def reject_duplicate_json_keys(pairs):
    result = OrderedDict()
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key!r}")
        result[key] = value
    return result


def load_json_text(text: str):
    return json.loads(text, object_pairs_hook=reject_duplicate_json_keys)


def read_text(path: Path, encoding: str) -> str:
    return path.read_text(encoding=encoding, errors="strict")


def public_rel_path(path: Path, start: Path = ROOT_DIR) -> str:
    try:
        return Path(os.path.relpath(path, start)).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def safe_group(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_.-]+", "_", value)
    cleaned = cleaned.strip("._")
    return cleaned or "unnamed"


def normalize_uc_path(path: str) -> str:
    return UC_ARRAY_RE.sub(lambda m: f"{m.group(1)}[{m.group(2)}]", path)


def unquote_unreal(value: str) -> str:
    if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
        inner = value[1:-1]
    else:
        inner = value
    out = []
    i = 0
    while i < len(inner):
        ch = inner[i]
        if ch == "\\" and i + 1 < len(inner):
            nxt = inner[i + 1]
            if nxt == "n":
                out.append("\n")
                i += 2
            else:
                out.append(ch)
                i += 1
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def quote_unreal_raw(value: str) -> str:
    value = value.replace("\r\n", "\n").replace("\r", "\n").replace("\n", r"\n")
    return f'"{value}"'


def normalize_passthrough_literal(value: str, label: str, stats: Counter) -> str:
    normalized = normalize_fallback_text(value)
    if normalized != value:
        stats["passthrough_literal_normalized"] += 1
    try:
        normalized.encode("gbk")
    except UnicodeEncodeError as exc:
        bad = exc.object[exc.start : exc.end]
        fail(f"{label}: passthrough literal contains non-GBK text {bad!r}")
    return normalized


def make_literal_row(
    section: str,
    key: str,
    value: str,
    label: str,
    stats: Counter,
    allow_duplicate: bool = False,
) -> OrderedDict:
    row = OrderedDict(
        [
            ("section", section),
            ("key", key),
            ("type", "literal"),
            ("value", normalize_passthrough_literal(value, label, stats)),
        ]
    )
    if allow_duplicate:
        row["allow_duplicate"] = True
    return row


def is_closing_quote(text: str, index: int, terminators: set[str]) -> bool:
    cursor = index + 1
    while cursor < len(text) and text[cursor].isspace():
        cursor += 1
    return cursor == len(text) or text[cursor] in terminators


def split_top_level(text: str, sep: str = ",") -> list[str]:
    parts = []
    start = 0
    depth = 0
    in_quote = False
    for index, ch in enumerate(text):
        if in_quote:
            if ch == '"' and is_closing_quote(text, index, {sep, ")"}):
                in_quote = False
            continue
        if ch == '"':
            in_quote = True
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == sep and depth == 0:
            parts.append(text[start:index].strip())
            start = index + 1
    parts.append(text[start:].strip())
    return parts


def split_assignment(text: str) -> tuple[str, str] | None:
    depth = 0
    in_quote = False
    for index, ch in enumerate(text):
        if in_quote:
            if ch == '"' and is_closing_quote(text, index, {",", ")"}):
                in_quote = False
            continue
        if ch == '"':
            in_quote = True
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == "=" and depth == 0:
            return text[:index].strip(), text[index + 1 :].strip()
    return None


def parse_quoted_tuple(value: str) -> list[str] | None:
    value = value.strip()
    if not (value.startswith("(") and value.endswith(")")):
        return None
    parts = split_top_level(value[1:-1])
    if not parts:
        return None
    items = []
    for part in parts:
        if not (len(part) >= 2 and part[0] == '"' and part[-1] == '"'):
            return None
        items.append(unquote_unreal(part))
    return items


def flatten_value(prefix: str, value: str, out: dict[str, SourceValue]) -> None:
    value = value.strip()
    tuple_items = parse_quoted_tuple(value)
    if tuple_items is not None:
        out[prefix] = SourceValue(kind="tuple", raw=value, items=tuple_items)
        return

    if value.startswith("(") and value.endswith(")"):
        assignments = []
        for part in split_top_level(value[1:-1]):
            assignment = split_assignment(part)
            if assignment is None:
                assignments = []
                break
            assignments.append(assignment)
        if assignments:
            out[prefix] = classify_value(value, "")
            for field, field_value in assignments:
                field = normalize_uc_path(field)
                flatten_value(f"{prefix}.{field}", field_value, out)
            return

    out[prefix] = classify_value(value, "")


def extract_template_fields(value: str) -> list[tuple[str, str, str, str]]:
    fields = []
    in_quote = False
    field_start = None
    value_start = None
    current_field = None
    index = 0
    while index < len(value):
        ch = value[index]
        if in_quote:
            if ch == '"' and is_closing_quote(value, index, {",", ")"}):
                raw = value[value_start : index + 1]
                text = unquote_unreal(raw)
                if current_field in STRUCT_TEXT_FIELDS and text != "":
                    fields.append((current_field, field_start, index + 1, text))
                in_quote = False
                current_field = None
            index += 1
            continue

        if ch == "=":
            left = value[:index].rstrip()
            m = re.search(r"([A-Za-z_][A-Za-z0-9_]*)$", left)
            if m and index + 1 < len(value) and value[index + 1] == '"':
                current_field = m.group(1)
                field_start = index + 1
                value_start = index + 1
                in_quote = True
                index += 2
                continue
        index += 1
    return fields


def classify_value(value: str, key: str) -> SourceValue:
    raw = value.strip()
    if key.startswith("SubtitleSound"):
        return SourceValue(kind="literal", raw=raw)
    if key.endswith("Time") or key.startswith(("FadeIn", "FadeOut", "FullOn")):
        if re.fullmatch(r"-?\d+(?:\.\d+)?", raw):
            return SourceValue(kind="literal", raw=raw)
    if raw.lower() in {"true", "false"} or re.fullmatch(r"-?\d+(?:\.\d+)?", raw):
        return SourceValue(kind="literal", raw=raw)
    if key == "Object+":
        return SourceValue(kind="literal", raw=raw)

    tuple_items = parse_quoted_tuple(raw)
    if tuple_items is not None:
        return SourceValue(kind="tuple", raw=raw, items=tuple_items)

    if key.endswith("+") and raw.startswith("(") and raw.endswith(")"):
        fields = extract_template_fields(raw)
        if fields:
            return SourceValue(kind="template", raw=raw, template_fields=fields)
        return SourceValue(kind="literal", raw=raw)

    if len(raw) >= 2 and raw[0] == '"' and raw[-1] == '"':
        text = unquote_unreal(raw)
        if key.startswith("CreditsLine") and (text.strip() == "" or text.startswith("Scale=")):
            return SourceValue(kind="literal", raw=raw)
        return SourceValue(kind="string", raw=raw, text=text, style="quoted")

    if raw.startswith("(") and raw.endswith(")"):
        fields = extract_template_fields(raw)
        if fields:
            return SourceValue(kind="template", raw=raw, template_fields=fields)
        return SourceValue(kind="literal", raw=raw)

    return SourceValue(kind="string", raw=raw, text=raw, style="bare")


def parse_int_file(path: Path, encoding: str):
    rows: list[IntRow] = []
    pseudo_comments = []
    malformed = []
    section = None
    for line_no, raw_line in enumerate(read_text(path, encoding).splitlines(), 1):
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if section is None or "=" not in line:
            malformed.append({"file": path.name, "line": line_no, "raw": raw_line, "reason": "no section or no equals"})
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if key.startswith("//"):
            pseudo_comments.append({"file": path.name, "line": line_no, "section": section, "key": key, "value": value})
            continue
        if key.startswith("("):
            malformed.append({"file": path.name, "line": line_no, "section": section, "key": key, "value": value, "reason": "malformed key"})
            continue
        rows.append(IntRow(path.name, line_no, section, key, value, raw_line))
    return rows, pseudo_comments, malformed


def parse_all_ints(path: Path, encoding: str):
    by_file = OrderedDict()
    pseudo = []
    malformed = []
    for int_path in sorted(path.glob("*.int"), key=lambda p: p.name.casefold()):
        rows, file_pseudo, file_malformed = parse_int_file(int_path, encoding)
        by_file[int_path.name.casefold()] = {"path": int_path, "rows": rows}
        pseudo.extend(file_pseudo)
        malformed.extend(file_malformed)
    return by_file, pseudo, malformed


def build_row_index(rows: list[IntRow]):
    index = defaultdict(list)
    for row in rows:
        index[(row.section.casefold(), row.key)].append(row)
    return index


def copy_tree_files(src: Path, dst: Path, pattern: str) -> int:
    dst.mkdir(parents=True, exist_ok=True)
    count = 0
    for path in sorted(src.glob(pattern), key=lambda p: p.name.casefold()):
        shutil.copy2(path, dst / path.name)
        count += 1
    return count


def build_package_case() -> dict[str, Path]:
    package_case = {p.stem.casefold(): p for p in PROPERTIES_DIR.glob("*.u")}
    package_case.update({p.stem.casefold(): p for p in SYSTEM_DIR.glob("*.u")})
    return package_case


def package_arg_for_ucc(package_file: Path) -> str:
    return os.path.relpath(package_file, SYSTEM_DIR).replace(os.sep, "\\")


def run_ucc_batchexport(package_arg: str, class_name: str, ext: str, out_dir: Path) -> str:
    out_dir.mkdir(parents=True, exist_ok=True)
    ucc = SYSTEM_DIR / "UCC.exe"
    proc = subprocess.run(
        [str(ucc), "batchexport", package_arg, class_name, ext, str(out_dir)],
        cwd=SYSTEM_DIR,
        text=True,
        encoding="utf-8",
        errors="replace",
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    output = proc.stdout
    if "Success - 0 error(s)" not in output:
        fail(f"UCC batchexport failed for {package_arg} {class_name} {ext}:\n{output[-4000:]}")
    return output


def ensure_class_exports(package_names: set[str], package_case: dict[str, Path], audit: dict) -> set[str]:
    exported = {}
    exported_packages = set()
    temp_root = TEMP_EXPORT_ROOT / "uc"
    if temp_root.exists():
        shutil.rmtree(temp_root)
    temp_root.mkdir(parents=True, exist_ok=True)

    for package_name in sorted(package_names, key=str.casefold):
        package_file = package_case.get(package_name.casefold())
        if package_file is None:
            continue
        out_dir = temp_root / package_file.stem
        package_arg = package_arg_for_ucc(package_file)
        output = run_ucc_batchexport(package_arg, "Class", "uc", out_dir)
        target_dir = EXPORT_DIR / package_file.stem
        if target_dir.exists():
            shutil.rmtree(target_dir)
        count = copy_tree_files(out_dir, target_dir, "*.uc")
        exported_packages.add(package_file.stem)
        exported[package_file.stem] = {
            "package": public_rel_path(package_file, GAME_DATA),
            "package_arg": package_arg,
            "classes": count,
            "ucc_lines": len(output.splitlines()),
        }
    audit["class_exports"] = exported
    return exported_packages


def parse_uc_file(path: Path):
    try:
        text = read_text(path, "utf-8")
    except UnicodeDecodeError:
        text = read_text(path, "cp1252")
    class_name = path.stem
    parent = None
    defaults: dict[str, SourceValue] = {}
    in_defaults = False
    depth = 0
    for line in text.splitlines():
        m = CLASS_RE.match(line)
        if m:
            class_name = m.group(1)
            parent = m.group(2)
        stripped = line.strip()
        if not in_defaults:
            if stripped.lower().startswith("defaultproperties"):
                in_defaults = True
            continue
        if stripped == "{":
            depth += 1
            continue
        if stripped == "}":
            depth -= 1
            if depth <= 0:
                break
            continue
        if depth <= 0 or not stripped or "=" not in stripped:
            continue
        assignment = split_assignment(stripped)
        if assignment is None:
            continue
        key, value = assignment
        flatten_value(normalize_uc_path(key), value, defaults)
    return class_name, parent, defaults


def load_class_defaults(package_stems: set[str], audit: dict):
    classes = {}
    loaded_packages = []
    for package_stem in sorted(package_stems, key=str.casefold):
        package_dir = EXPORT_DIR / package_stem
        if not package_dir.exists():
            continue
        loaded_packages.append(package_stem)
        for uc_path in sorted(package_dir.glob("*.uc"), key=lambda p: p.as_posix().casefold()):
            class_name, parent, defaults = parse_uc_file(uc_path)
            classes[class_name.casefold()] = {
                "name": class_name,
                "parent": parent,
                "defaults": defaults,
                "path": uc_path.relative_to(ROOT_DIR).as_posix(),
            }
    audit["loaded_class_packages"] = loaded_packages
    audit["loaded_class_count"] = len(classes)
    return classes


def lookup_class_default_exact(classes: dict, class_name: str, key: str, seen=None) -> tuple[SourceValue | None, dict | None]:
    if seen is None:
        seen = set()
    class_key = class_name.casefold()
    if class_key in seen:
        return None, None
    seen.add(class_key)
    info = classes.get(class_key)
    if not info:
        return None, None
    normalized_key = normalize_uc_path(key)
    if normalized_key in info["defaults"]:
        return info["defaults"][normalized_key], info
    parent = info.get("parent")
    if parent:
        return lookup_class_default_exact(classes, parent, normalized_key, seen)
    return None, None


def lookup_class_default(
    classes: dict,
    class_name: str,
    key: str,
    audit: dict | None = None,
    context: dict | None = None,
    allow_prefix: bool = True,
) -> SourceValue | None:
    value, _matched_info = lookup_class_default_exact(classes, class_name, key)
    if value is not None:
        return value
    if not allow_prefix:
        return None

    class_key = class_name.casefold()
    normalized_key = normalize_uc_path(key)
    candidates = []
    for candidate_key, candidate in classes.items():
        if len(candidate_key) < 4 or not class_key.startswith(candidate_key):
            continue
        candidate_value, resolved_info = lookup_class_default_exact(classes, candidate["name"], normalized_key)
        if candidate_value is not None:
            candidates.append((candidate, resolved_info, candidate_value))

    if not candidates:
        return None
    if len(candidates) > 1:
        fail(
            f"ambiguous class default prefix fallback for {class_name}.{normalized_key}: "
            + ", ".join(f"{candidate['name']}->{resolved['name'] if resolved else '?'}" for candidate, resolved, _value in candidates[:8])
        )

    candidate, resolved_info, candidate_value = candidates[0]
    if audit is not None:
        audit.setdefault("class_default_prefix_fallbacks", []).append(
            OrderedDict(
                [
                    ("requested_class", class_name),
                    ("matched_class", candidate["name"]),
                    ("resolved_class", resolved_info["name"] if resolved_info else candidate["name"]),
                    ("key", normalized_key),
                    ("class_path", candidate.get("path", "")),
                    ("resolved_class_path", resolved_info.get("path", "") if resolved_info else ""),
                    ("context", context or OrderedDict()),
                ]
            )
        )
    return candidate_value


def parse_t3d_file(path: Path):
    objects = {}
    stack = []
    for raw_line in read_text(path, "cp1252").splitlines():
        stripped = raw_line.strip()
        m = BEGIN_OBJECT_RE.match(stripped)
        if m:
            stack.append({"class": m.group(1), "name": m.group(2), "props": {}})
            continue
        if stripped.startswith("End ") and stack:
            obj = stack.pop()
            objects[obj["name"].casefold()] = obj
            continue
        if not stack or "=" not in stripped or stripped.startswith("Begin "):
            continue
        assignment = split_assignment(stripped)
        if assignment is None:
            continue
        key, value = assignment
        flatten_value(normalize_uc_path(key), value, stack[-1]["props"])
    return objects


def export_level_t3d(map_file: Path, temp_root: Path, audit: dict):
    out_dir = temp_root / map_file.stem
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    output = run_ucc_batchexport(f"..\\Maps\\{map_file.name}", "Level", "t3d", out_dir)
    files = list(out_dir.glob("*.t3d"))
    if len(files) != 1:
        fail(f"{map_file.name}: expected one Level t3d, got {len(files)}")
    audit.setdefault("map_exports", {})[map_file.name] = {
        "t3d_bytes": files[0].stat().st_size,
        "ucc_lines": len(output.splitlines()),
    }
    return parse_t3d_file(files[0])


class EntryAllocator:
    def __init__(self, existing: dict | None = None):
        self.existing_by_sig = defaultdict(list)
        self.existing_shared_by_ref_langs = {}
        self.reserved = defaultdict(set)
        self.used = defaultdict(set)
        self.next_id = defaultdict(lambda: 1)
        if existing:
            for group, payload in existing.items():
                if group == "schema" or not isinstance(payload, dict):
                    continue
                for entry_id, item in payload.items():
                    if not isinstance(item, dict):
                        continue
                    sig = (group, item.get("note", ""), item.get("en", ""))
                    self.existing_by_sig[sig].append({"id": str(entry_id), "item": item})
                    if group == SHARED_GROUP:
                        en = item.get("en", "")
                        jp = item.get("jp", "")
                        de = item.get("de", "")
                        if isinstance(en, str) and (jp or de):
                            self.existing_shared_by_ref_langs.setdefault((en, jp, de), item)
                    if str(entry_id).isdigit():
                        self.reserved[group].add(str(entry_id))
                        self.next_id[group] = max(self.next_id[group], int(entry_id) + 1)

    def allocate(self, group: str, note: str, en: str, natural: str | None, base: str | None):
        sig = (group, note, en)
        for previous in self.existing_by_sig.get(sig, []):
            entry_id = previous["id"]
            if entry_id not in self.used[group]:
                self.used[group].add(entry_id)
                return AllocationResult(group, entry_id, previous["item"])

        target_group = group
        if natural and natural in self.used[target_group] and base:
            target_group = f"{group}.{safe_group(base)}"
            sig = (target_group, note, en)
            for previous in self.existing_by_sig.get(sig, []):
                entry_id = previous["id"]
                if entry_id not in self.used[target_group]:
                    self.used[target_group].add(entry_id)
                    return AllocationResult(target_group, entry_id, previous["item"])

        unavailable = self.used[target_group] | self.reserved[target_group]
        if natural and natural not in unavailable:
            entry_id = natural
        else:
            while str(self.next_id[target_group]) in unavailable:
                self.next_id[target_group] += 1
            entry_id = str(self.next_id[target_group])
            self.next_id[target_group] += 1
        self.used[target_group].add(entry_id)
        return AllocationResult(target_group, entry_id)


def natural_id_from_key(key: str):
    m = ARRAY_KEY_RE.match(key)
    if not m:
        return None, None
    return m.group(2), m.group(1)


def load_existing_translation():
    if not TRANSLATION_JSON.exists():
        return None
    try:
        payload = load_json_text(TRANSLATION_JSON.read_text(encoding="utf-8-sig"))
    except UnicodeDecodeError as exc:
        fail(f"{public_rel_path(TRANSLATION_JSON)}: must be saved as UTF-8: {exc}")
    except json.JSONDecodeError as exc:
        fail(f"{public_rel_path(TRANSLATION_JSON)}: JSON parse failed: {exc}")
    except ValueError as exc:
        fail(f"{public_rel_path(TRANSLATION_JSON)}: JSON parse failed: {exc}")
    if not isinstance(payload, dict):
        fail(f"{public_rel_path(TRANSLATION_JSON)}: top-level JSON value must be an object")
    if payload.get("schema") != TRANSLATION_SCHEMA:
        fail(
            f"{public_rel_path(TRANSLATION_JSON)}: unsupported schema "
            f"{payload.get('schema')!r}, expected {TRANSLATION_SCHEMA}"
        )
    return payload


def backup_existing_translation_json() -> None:
    if not TRANSLATION_JSON.exists():
        return
    backup_path = TRANSLATION_JSON.with_name(f"{TRANSLATION_JSON.name}.bak")
    try:
        shutil.copy2(TRANSLATION_JSON, backup_path)
    except OSError as exc:
        fail(f"{public_rel_path(backup_path)}: failed to back up existing translation.json: {exc}")


def write_translation_json(payload) -> None:
    backup_existing_translation_json()
    write_json(TRANSLATION_JSON, payload)


def add_translation_entry(
    translation: OrderedDict,
    allocator: EntryAllocator,
    base_group: str,
    note: str,
    en: str,
    jp: str,
    de: str,
    natural: str | None,
    natural_base: str | None,
    stats: Counter,
    reset_translations: bool,
):
    if en == "":
        fail(f"{base_group}/{note}: English source is empty")
    allocation = allocator.allocate(base_group, note, en, natural, natural_base)
    group = allocation.group
    entry_id = allocation.entry_id
    if not SAFE_GROUP_RE.fullmatch(group):
        fail(f"unsafe generated group: {group}")
    if group not in translation:
        translation[group] = OrderedDict()
    if entry_id in translation[group]:
        fail(f"duplicate generated translation id: {group}/{entry_id}")

    previous = allocation.previous if isinstance(allocation.previous, dict) else None
    zh_cn = ""
    if previous is None:
        old_shared = allocator.existing_shared_by_ref_langs.get((en, jp, de))
        old_zh = old_shared.get("zh_CN", "") if isinstance(old_shared, dict) else ""
        if not reset_translations and isinstance(old_zh, str) and old_zh:
            zh_cn = old_zh
            stats["restored_from_shared"] += 1
        else:
            stats["new_blank_zh_CN"] += 1
            if reset_translations and isinstance(old_zh, str) and old_zh:
                stats["reset_zh_CN"] += 1
    else:
        old_zh = previous.get("zh_CN", "")
        old_jp = previous.get("jp", "")
        if not isinstance(old_zh, str):
            old_zh = ""
        if not isinstance(old_jp, str):
            old_jp = ""
        if reset_translations:
            if old_zh:
                stats["reset_zh_CN"] += 1
        else:
            zh_cn = old_zh
            if old_zh:
                stats["preserved_zh_CN"] += 1
                if old_jp != jp:
                    stats["preserved_translation_with_jp_change"] += 1

    translation[group][entry_id] = OrderedDict(
        [
            ("note", note),
            ("en", en),
            ("jp", jp),
            ("de", de),
            ("zh_CN", zh_cn),
        ]
    )
    return f"{group}/{entry_id}"


def iter_translation_entries(translation: OrderedDict):
    for group, payload in translation.items():
        if group == "schema":
            continue
        for entry_id, item in payload.items():
            yield f"{group}/{entry_id}", group, entry_id, item


def iter_catalog_entry_refs(catalog_files: OrderedDict):
    for rows in catalog_files.values():
        for row in rows:
            row_type = row.get("type")
            if row_type == "string":
                yield row, "entry"
            elif row_type == "tuple":
                for item in row.get("items", []):
                    yield item, "entry"
            elif row_type == "template":
                for part in row.get("parts", []):
                    if isinstance(part, dict) and "entry" in part:
                        yield part, "entry"


def build_existing_shared_index(existing: dict | None) -> tuple[dict[tuple[str, str, str], tuple[str, dict]], set[str]]:
    by_key = {}
    reserved = set()
    if not existing:
        return by_key, reserved
    payload = existing.get(SHARED_GROUP)
    if not isinstance(payload, dict):
        return by_key, reserved
    for entry_id, item in payload.items():
        entry_id = str(entry_id)
        if not entry_id.isdigit() or not isinstance(item, dict):
            continue
        reserved.add(entry_id)
        en = item.get("en", "")
        jp = item.get("jp", "")
        de = item.get("de", "")
        if isinstance(en, str) and (jp or de):
            by_key.setdefault((en, jp, de), (entry_id, item))
    return by_key, reserved


def choose_shared_note(items: list[dict]) -> str:
    counts = Counter()
    first_seen = {}
    for index, item in enumerate(items):
        note = item.get("note", "")
        if not isinstance(note, str):
            note = ""
        counts[note] += 1
        first_seen.setdefault(note, index)
    note = min(counts, key=lambda value: (-counts[value], first_seen[value]))
    note = note or "merged"
    return f"{note} / {len(items)} occurrences"


def merge_shared_en_jp_entries(
    translation: OrderedDict,
    catalog_files: OrderedDict,
    existing_translation: dict | None,
    stats: Counter,
    reset_translations: bool,
    audit: dict,
) -> OrderedDict:
    entries = list(iter_translation_entries(translation))
    clusters = OrderedDict()
    for ref, _group, _entry_id, item in entries:
        en = item.get("en", "")
        jp = item.get("jp", "")
        de = item.get("de", "")
        if isinstance(en, str) and (jp or de):
            clusters.setdefault((en, jp, de), []).append((ref, item))
    clusters = OrderedDict((key, value) for key, value in clusters.items() if len(value) > 1)

    existing_shared, reserved_shared_ids = build_existing_shared_index(existing_translation)
    used_shared_ids = set()
    next_shared_id = SHARED_ID_START
    if reserved_shared_ids:
        next_shared_id = max(next_shared_id, max(int(value) for value in reserved_shared_ids) + 1)

    def allocate_shared_id(key: tuple[str, str, str]) -> str:
        nonlocal next_shared_id
        existing = existing_shared.get(key)
        if existing:
            entry_id = existing[0]
            if entry_id in used_shared_ids:
                fail(f"duplicate existing shared id reused: {SHARED_GROUP}/{entry_id}")
            used_shared_ids.add(entry_id)
            return entry_id
        while str(next_shared_id) in used_shared_ids or str(next_shared_id) in reserved_shared_ids:
            next_shared_id += 1
        entry_id = str(next_shared_id)
        used_shared_ids.add(entry_id)
        next_shared_id += 1
        return entry_id

    merged_ref_by_old_ref = {}
    shared_payload = OrderedDict()
    merge_samples = []
    conflict_reports = []

    for key, refs_and_items in clusters.items():
        en, jp, de = key
        shared_id = allocate_shared_id(key)
        shared_ref = f"{SHARED_GROUP}/{shared_id}"
        zh_sources = []
        for ref, item in refs_and_items:
            zh = item.get("zh_CN", "")
            if isinstance(zh, str) and zh:
                zh_sources.append((ref, zh))
        old_shared = existing_shared.get(key)
        if old_shared and not reset_translations:
            old_zh = old_shared[1].get("zh_CN", "")
            if isinstance(old_zh, str) and old_zh:
                zh_sources.append((shared_ref, old_zh))
        elif old_shared and reset_translations:
            old_zh = old_shared[1].get("zh_CN", "")
            if isinstance(old_zh, str) and old_zh:
                stats["reset_zh_CN"] += 1

        unique_zh = []
        for _source_ref, zh in zh_sources:
            if zh not in unique_zh:
                unique_zh.append(zh)
        if len(unique_zh) > 1:
            conflict_reports.append(
                OrderedDict(
                    [
                        ("entry", shared_ref),
                        ("en", en),
                        ("jp", jp),
                        ("sources", [ref for ref, _zh in zh_sources[:8]]),
                    ]
                )
            )
            continue

        zh_cn = unique_zh[0] if unique_zh else ""
        if zh_cn and all(source_ref == shared_ref for source_ref, _zh in zh_sources):
            stats["preserved_zh_CN"] += 1
        note = choose_shared_note([item for _ref, item in refs_and_items])
        shared_payload[shared_id] = OrderedDict(
            [
                ("note", note),
                ("en", en),
                ("jp", jp),
                ("de", de),
                ("zh_CN", zh_cn),
            ]
        )
        for ref, _item in refs_and_items:
            merged_ref_by_old_ref[ref] = shared_ref
        merge_samples.append(
            OrderedDict(
                [
                    ("entry", shared_ref),
                    ("count", len(refs_and_items)),
                    ("sample_refs", [ref for ref, _item in refs_and_items[:3]]),
                    ("note", note),
                ]
            )
        )

    if conflict_reports:
        audit["merge_conflicts"] = conflict_reports
        write_json(AUDIT_JSON, audit)
        fail(
            "conflicting zh_CN values while merging shared (en, jp) entries: "
            + "; ".join(f"{item['entry']} sources={item['sources']}" for item in conflict_reports[:5])
        )

    for holder, key in iter_catalog_entry_refs(catalog_files):
        old_ref = holder[key]
        if old_ref in merged_ref_by_old_ref:
            holder[key] = merged_ref_by_old_ref[old_ref]

    new_translation = OrderedDict([("schema", TRANSLATION_SCHEMA)])
    if shared_payload:
        new_translation[SHARED_GROUP] = shared_payload
    for ref, group, entry_id, item in entries:
        if ref in merged_ref_by_old_ref:
            continue
        if group not in new_translation:
            new_translation[group] = OrderedDict()
        new_translation[group][entry_id] = item

    merged_entries = sum(len(value) for value in clusters.values())
    stats["merged_en_jp_groups"] += len(clusters)
    stats["merged_translation_entries"] += merged_entries
    stats["merge_saved_entries"] += sum(len(value) - 1 for value in clusters.values())
    stats["shared_translation_entries"] += len(shared_payload)
    stats["merge_conflicts"] += 0
    audit["shared_en_jp_merge"] = OrderedDict(
        [
            ("group", SHARED_GROUP),
            ("merged_groups", len(clusters)),
            ("merged_entries", merged_entries),
            ("saved_entries", sum(len(value) - 1 for value in clusters.values())),
            ("shared_entries", len(shared_payload)),
            ("sample_groups", merge_samples[:50]),
        ]
    )
    return new_translation


def get_group(file_stem: str, section: str) -> str:
    return f"{safe_group(file_stem)}.{safe_group(section)}"


def parse_template_texts(value: str):
    result = defaultdict(list)
    for field, _start, _end, text in extract_template_fields(value):
        result[field].append(text)
    return result


def emit_from_source(
    catalog_files: OrderedDict,
    translation: OrderedDict,
    allocator: EntryAllocator,
    output_path: str,
    section: str,
    key: str,
    source: SourceValue,
    jp_value: str,
    de_value: str,
    file_stem: str,
    stats: Counter,
    reset_translations: bool,
    force_allow_duplicate: bool = False,
):
    rows = catalog_files.setdefault(output_path, [])
    group = get_group(file_stem, section)
    natural, natural_base = natural_id_from_key(key)
    allow_duplicate = force_allow_duplicate or key.endswith("+")

    if source.kind == "literal":
        row = OrderedDict([("section", section), ("key", key), ("type", "literal"), ("value", source.raw)])
        if allow_duplicate:
            row["allow_duplicate"] = True
        rows.append(row)
        stats["literal_rows"] += 1
        return "literal"

    if source.kind == "string":
        jp_text = unquote_unreal(jp_value) if jp_value.startswith('"') and jp_value.endswith('"') else jp_value
        de_text = unquote_unreal(de_value) if de_value.startswith('"') and de_value.endswith('"') else de_value
        if source.text == "":
            row = make_literal_row(
                section,
                key,
                source.raw,
                f"{output_path} [{section}] {key}",
                stats,
                allow_duplicate,
            )
            rows.append(row)
            stats["empty_english_literal_rows"] += 1
            return "literal"
        if key.startswith("CreditsLine") and jp_text == source.text:
            row = make_literal_row(
                section,
                key,
                source.raw,
                f"{output_path} [{section}] {key}",
                stats,
                allow_duplicate,
            )
            rows.append(row)
            stats["credits_jp_en_literal_rows"] += 1
            return "literal"
        ref = add_translation_entry(
            translation,
            allocator,
            group,
            key,
            source.text or "",
            jp_text,
            de_text,
            natural,
            natural_base,
            stats,
            reset_translations,
        )
        row = OrderedDict(
            [
                ("section", section),
                ("key", key),
                ("type", "string"),
                ("entry", ref),
                ("printf", PRINTF_RE.findall(source.text or "")),
            ]
        )
        if source.style != "quoted":
            row["style"] = source.style
        if allow_duplicate:
            row["allow_duplicate"] = True
        rows.append(row)
        stats["string_entries"] += 1
        return "string"

    if source.kind == "tuple":
        jp_items = parse_quoted_tuple(jp_value) or []
        de_items = parse_quoted_tuple(de_value) or []
        if source.items is None:
            fail(f"{output_path} [{section}] {key}: tuple source missing items")
        if jp_items and len(jp_items) != len(source.items):
            fail(f"{output_path} [{section}] {key}: JP tuple item count mismatch")
        items = []
        for index, en_item in enumerate(source.items):
            note = f"{key}[{index}]"
            jp_item = jp_items[index] if index < len(jp_items) else ""
            de_item = de_items[index] if index < len(de_items) else ""
            ref = add_translation_entry(
                translation,
                allocator,
                group,
                note,
                en_item,
                jp_item,
                de_item,
                None,
                None,
                stats,
                reset_translations,
            )
            items.append(OrderedDict([("entry", ref), ("printf", PRINTF_RE.findall(en_item))]))
        row = OrderedDict([("section", section), ("key", key), ("type", "tuple"), ("items", items)])
        if allow_duplicate:
            row["allow_duplicate"] = True
        rows.append(row)
        stats["tuple_entries"] += len(items)
        return "tuple"

    if source.kind == "template":
        if not source.template_fields:
            fail(f"{output_path} [{section}] {key}: template source missing fields")
        jp_fields = parse_template_texts(jp_value)
        de_fields = parse_template_texts(de_value)
        source_field_counts = Counter(field for field, _start, _end, _text in source.template_fields)
        source_field_seen = Counter()
        parts = []
        cursor = 0
        for field, start, end, en_text in source.template_fields:
            parts.append(source.raw[cursor:start])
            field_index = source_field_seen[field]
            source_field_seen[field] += 1
            note = f"{key}.{field}"
            if source_field_counts[field] > 1:
                note = f"{note}[{field_index}]"
            jp_values = jp_fields.get(field, [])
            jp_text = jp_values[field_index] if field_index < len(jp_values) else ""
            de_values = de_fields.get(field, [])
            de_text_val = de_values[field_index] if field_index < len(de_values) else ""
            ref = add_translation_entry(
                translation,
                allocator,
                group,
                note,
                en_text,
                jp_text,
                de_text_val,
                None,
                None,
                stats,
                reset_translations,
            )
            parts.append(OrderedDict([("entry", ref), ("style", "quoted"), ("printf", PRINTF_RE.findall(en_text))]))
            cursor = end
        parts.append(source.raw[cursor:])
        row = OrderedDict([("section", section), ("key", key), ("type", "template"), ("parts", parts)])
        if allow_duplicate:
            row["allow_duplicate"] = True
        rows.append(row)
        stats["template_entries"] += len(source.template_fields)
        return "template"

    fail(f"{output_path} [{section}] {key}: unsupported source kind {source.kind}")


def source_from_int_row(row: IntRow) -> SourceValue:
    return classify_value(row.value, row.key)


def map_file_for_int(int_name: str, map_case: dict[str, Path]) -> Path | None:
    stem = Path(int_name).stem.casefold()
    return map_case.get(stem)


def package_for_int(int_name: str, package_case: dict[str, Path]) -> Path | None:
    stem = Path(int_name).stem.casefold()
    return package_case.get(stem)


def source_from_map(
    row: IntRow,
    map_objects: dict,
    classes: dict,
    audit: dict,
) -> SourceValue | None:
    obj = map_objects.get(row.section.casefold())
    if not obj:
        return None
    normalized_key = normalize_uc_path(row.key)
    if normalized_key in obj["props"]:
        return obj["props"][normalized_key]
    if normalized_key == "MissionObj":
        objectives = []
        for prop_key, prop_value in obj["props"].items():
            m = re.fullmatch(r"MissionObj\[(\d+)\]\.Objective", prop_key)
            if m and prop_value.kind == "string":
                objectives.append((int(m.group(1)), prop_value.text or ""))
        if objectives:
            objectives.sort()
            raw = "(" + ",".join(f"(Objective={quote_unreal_raw(text)})" for _idx, text in objectives) + ")"
            return SourceValue(kind="template", raw=raw, template_fields=extract_template_fields(raw))
    return lookup_class_default(
        classes,
        obj["class"],
        normalized_key,
        audit,
        OrderedDict(
            [
                ("origin", "map_t3d_or_default"),
                ("file", row.file_name),
                ("section", row.section),
                ("key", row.key),
                ("object_class", obj["class"]),
                ("object_name", obj["name"]),
            ]
        ),
    )


def source_from_package(row: IntRow, classes: dict, audit: dict, origin: str) -> SourceValue | None:
    return lookup_class_default(
        classes,
        row.section,
        row.key,
        audit,
        OrderedDict(
            [
                ("origin", origin),
                ("file", row.file_name),
                ("section", row.section),
                ("key", row.key),
            ]
        ),
    )


def subtitle_index_delta(en_index: str, jp_index: str) -> str:
    try:
        delta = int(jp_index) - int(en_index)
    except ValueError:
        return "non_numeric"
    return f"{delta:+d}"


def record_subtitle_remap_summary(audit: dict, file_name: str, remap_count: int, delta_counts: Counter) -> None:
    summary = audit.setdefault(
        "subtitle_remap_summary",
        OrderedDict(
            [
                ("subtitle_files", 0),
                ("files_with_remaps", 0),
                ("total_remaps", 0),
                ("index_delta_counts", OrderedDict()),
                ("files", OrderedDict()),
            ]
        ),
    )
    summary["subtitle_files"] += 1
    summary["total_remaps"] += remap_count
    if remap_count:
        summary["files_with_remaps"] += 1
    for delta, count in delta_counts.items():
        summary["index_delta_counts"][delta] = summary["index_delta_counts"].get(delta, 0) + count
    summary["files"][file_name] = OrderedDict(
        [
            ("remap_count", remap_count),
            ("index_delta_counts", OrderedDict(sorted(delta_counts.items()))),
        ]
    )


def normalize_subtitle_remap_summary(audit: dict) -> None:
    summary = audit.get("subtitle_remap_summary")
    if not summary:
        return
    summary["index_delta_counts"] = OrderedDict(sorted(summary["index_delta_counts"].items()))


def process_subtitle_file(
    jp_info,
    en_info,
    de_index: dict,
    output_path: str,
    catalog_files: OrderedDict,
    translation: OrderedDict,
    allocator: EntryAllocator,
    skipped: list,
    audit: dict,
    stats: Counter,
    reset_translations: bool,
):
    jp_rows = jp_info["rows"]
    en_rows = en_info["rows"]

    def subtitle_pairs(rows):
        pending_sound = defaultdict(list)
        pairs = []
        text_by_index = {}
        text_without_sound = []
        for row in rows:
            m = ARRAY_KEY_RE.match(row.key)
            if not m:
                continue
            base, index = m.group(1), m.group(2)
            if base == "SubtitleSound":
                pending_sound[index].append(row)
            elif base == "SubtitleText":
                text_by_index[index] = unquote_unreal(row.value)
                if pending_sound[index]:
                    sound_row = pending_sound[index].pop(0)
                    pairs.append((index, sound_row, row))
                else:
                    text_without_sound.append(row)
        sound_without_text = [row for pending in pending_sound.values() for row in pending]
        return pairs, text_by_index, sound_without_text, text_without_sound

    jp_pairs, jp_text_by_index, jp_sound_without_text, jp_text_without_sound = subtitle_pairs(jp_rows)
    jp_by_sound = defaultdict(list)
    for jp_index, sound_row, text_row in jp_pairs:
        jp_by_sound[unquote_unreal(sound_row.value)].append((jp_index, unquote_unreal(text_row.value), sound_row))

    en_pairs, _en_text_by_index, en_sound_without_text, en_text_without_sound = subtitle_pairs(en_rows)
    audit.setdefault("subtitle_pairing", OrderedDict())[jp_info["path"].name] = OrderedDict(
        [
            ("en_sound_without_text", len(en_sound_without_text)),
            ("en_text_without_sound", len(en_text_without_sound)),
            ("jp_sound_without_text", len(jp_sound_without_text)),
            ("jp_text_without_sound", len(jp_text_without_sound)),
        ]
    )
    if en_text_without_sound:
        fail(f"{jp_info['path'].name}: {len(en_text_without_sound)} EN SubtitleText rows have no preceding matching SubtitleSound")
    duplicate_counts = Counter((row.section, row.key) for _index, sound_row, text_row in en_pairs for row in (sound_row, text_row))

    remap_count = 0
    remap_deltas = Counter()
    used_jp_pairs = set()
    file_stem = Path(output_path).stem
    for pair_ordinal, (index, sound_row, text_row) in enumerate(en_pairs):
        section = text_row.section
        sound = unquote_unreal(sound_row.value)
        jp_index = None
        jp_text = ""
        for candidate_ordinal, (candidate_index, candidate_text, _candidate_sound_row) in enumerate(jp_by_sound.get(sound, [])):
            pair_key = (sound, candidate_ordinal)
            if pair_key not in used_jp_pairs:
                jp_index = candidate_index
                jp_text = candidate_text
                used_jp_pairs.add(pair_key)
                break
        sound_catalog_row = make_literal_row(
            sound_row.section,
            sound_row.key,
            sound_row.value,
            f"{output_path} [{sound_row.section}] {sound_row.key}",
            stats,
            duplicate_counts[(sound_row.section, sound_row.key)] > 1,
        )
        source = source_from_int_row(text_row)
        de_sub_value = de_index.get((file_stem.casefold(), text_row.section.casefold(), text_row.key), "")
        de_text = unquote_unreal(de_sub_value) if de_sub_value.startswith('"') and de_sub_value.endswith('"') else de_sub_value
        try:
            ref = add_translation_entry(
                translation,
                allocator,
                get_group(file_stem, section),
                text_row.key,
                source.text or "",
                jp_text,
                de_text,
                index,
                "SubtitleText",
                stats,
                reset_translations,
            )
        except GenerateError as exc:
            skipped.append(
                {
                    "reason_code": emit_error_reason_code(str(exc)),
                    "file": en_info["path"].name,
                    "line": text_row.line_no,
                    "section": text_row.section,
                    "key": text_row.key,
                    "jp_value": jp_text,
                    "reason": str(exc),
                }
            )
            stats["skipped_emit_error"] += 1
            rows = catalog_files.setdefault(output_path, [])
            rows.append(sound_catalog_row)
            rows.append(
                make_literal_row(
                    section,
                    text_row.key,
                    text_row.value,
                    f"{output_path} [{section}] {text_row.key}",
                    stats,
                    duplicate_counts[(section, text_row.key)] > 1,
                )
            )
            stats["subtitle_passthrough_literal_rows"] += 2
            continue
        rows = catalog_files.setdefault(output_path, [])
        rows.append(sound_catalog_row)
        text_catalog_row = (
            OrderedDict(
                [
                    ("section", section),
                    ("key", text_row.key),
                    ("type", "string"),
                    ("entry", ref),
                    ("printf", PRINTF_RE.findall(source.text or "")),
                ]
            )
        )
        if duplicate_counts[(section, text_row.key)] > 1:
            text_catalog_row["allow_duplicate"] = True
        rows.append(text_catalog_row)
        stats["subtitle_pairs"] += 1
        if jp_index is not None and jp_index != index:
            remap_count += 1
            remap_deltas[subtitle_index_delta(index, jp_index)] += 1

    for sound, pairs in jp_by_sound.items():
        if sound == "":
            continue
        for candidate_ordinal, (jp_index, _jp_text, jp_sound_row) in enumerate(pairs):
            if (sound, candidate_ordinal) not in used_jp_pairs:
                skipped.append(
                    {
                        "reason_code": "jp_subtitle_sound_missing",
                        "file": jp_info["path"].name,
                        "line": jp_sound_row.line_no,
                        "section": jp_sound_row.section,
                        "key": f"SubtitleSound[{jp_index}]",
                        "jp_value": sound,
                        "reason": "JP subtitle sound not present in EN runtime file",
                    }
                )
    record_subtitle_remap_summary(audit, jp_info["path"].name, remap_count, remap_deltas)


def collect_needed_packages(jp_ints, en_ints, package_case: dict[str, Path]):
    needed = {"Engine", "CTGame", "XInterfaceCTMenus"}
    for name in jp_ints:
        stem = Path(name).stem.casefold()
        if stem in package_case:
            needed.add(package_case[stem].stem)
    for name, info in jp_ints.items():
        if name in en_ints:
            en_index = build_row_index(en_ints[name]["rows"])
            for row in info["rows"]:
                if (row.section.casefold(), row.key) not in en_index:
                    stem = Path(name).stem.casefold()
                    if stem in package_case:
                        needed.add(package_case[stem].stem)
                    if stem == "engine":
                        needed.add("Engine")
    return needed


def duplicate_keys_by_file(jp_ints):
    result = {}
    for name, info in jp_ints.items():
        counts = Counter((row.section.casefold(), row.key) for row in info["rows"])
        result[name] = {key for key, count in counts.items() if count > 1}
    return result


def catalog_row_counts(rows: list[dict]) -> Counter:
    return Counter((row.get("section", "").casefold(), row.get("key", "")) for row in rows)


def append_en_passthrough_rows(
    output_path: str,
    en_rows: list[IntRow],
    catalog_files: OrderedDict,
    stats: Counter,
    audit: dict,
) -> None:
    rows = catalog_files.setdefault(output_path, [])
    remaining_output = catalog_row_counts(rows)
    en_counts = Counter((row.section.casefold(), row.key) for row in en_rows)
    added = []
    for en_row in en_rows:
        key_pair = (en_row.section.casefold(), en_row.key)
        if remaining_output[key_pair] > 0:
            remaining_output[key_pair] -= 1
            continue
        row = make_literal_row(
            en_row.section,
            en_row.key,
            en_row.value,
            f"{output_path} [{en_row.section}] {en_row.key}",
            stats,
            en_counts[key_pair] > 1 or catalog_row_counts(rows)[key_pair] > 0,
        )
        rows.append(row)
        added.append(
            OrderedDict(
                [
                    ("section", en_row.section),
                    ("key", en_row.key),
                    ("line", en_row.line_no),
                ]
            )
        )
        stats["en_passthrough_literal_rows"] += 1
    if added:
        audit.setdefault("en_passthrough_literals", OrderedDict())[output_path] = added


def validate_catalog_covers_en_runtime(catalog_files: OrderedDict, en_outputs: dict[str, list[IntRow]], audit: dict) -> None:
    coverage = OrderedDict()
    missing_total = 0
    for output_path, en_rows in sorted(en_outputs.items()):
        expected = Counter((row.section.casefold(), row.key) for row in en_rows)
        actual = catalog_row_counts(catalog_files.get(output_path, []))
        missing = []
        for key_pair, count in sorted(expected.items()):
            gap = count - actual.get(key_pair, 0)
            if gap > 0:
                missing_total += gap
                section_key = next((row for row in en_rows if (row.section.casefold(), row.key) == key_pair), None)
                missing.append(
                    OrderedDict(
                        [
                            ("section", section_key.section if section_key else key_pair[0]),
                            ("key", section_key.key if section_key else key_pair[1]),
                            ("missing_occurrences", gap),
                        ]
                    )
                )
        coverage[output_path] = OrderedDict(
            [
                ("en_rows", sum(expected.values())),
                ("catalog_rows", sum(actual.values())),
                ("missing_rows", sum(item["missing_occurrences"] for item in missing)),
                ("missing", missing[:50]),
            ]
        )
    audit["catalog_en_runtime_coverage"] = OrderedDict(
        [
            ("files", len(coverage)),
            ("missing_rows", missing_total),
            ("by_file", coverage),
        ]
    )
    if missing_total:
        fail(f"catalog output misses {missing_total} EN runtime row occurrences; see catalog_en_runtime_coverage")


def emit_error_reason_code(message: str) -> str:
    if "JP tuple item count mismatch" in message:
        return "jp_tuple_item_count_mismatch"
    if "English source is empty" in message:
        return "empty_english_source"
    return "emit_error"


def skipped_summary(entries: list[dict]) -> OrderedDict:
    by_reason_code = Counter(item.get("reason_code", "unknown") for item in entries)
    by_file = Counter(item.get("file", "") for item in entries)
    return OrderedDict(
        [
            ("total", len(entries)),
            ("by_reason_code", OrderedDict(sorted(by_reason_code.items()))),
            ("by_file", OrderedDict(sorted(by_file.items()))),
        ]
    )


def format_skipped_failure(entries: list[dict]) -> str:
    summary = skipped_summary(entries)
    reason_bits = ", ".join(f"{key}={value}" for key, value in summary["by_reason_code"].items())
    file_bits = ", ".join(f"{key}={value}" for key, value in list(summary["by_file"].items())[:8])
    return (
        f"generation produced {summary['total']} skipped entries ({reason_bits}). "
        "Refusing to write JSON by default; fix the skipped entries or rerun with --allow-skipped. "
        f"Top files: {file_bits}"
    )


def validate_generated(translation, catalog):
    refs = set()
    for path, rows in catalog["files"].items():
        if "\\" in path or ".." in Path(path).parts or not path.startswith("GameData/System/"):
            fail(f"unsafe catalog path: {path}")
        seen_non_additive = set()
        for row in rows:
            key_pair = (row["section"], row["key"])
            if key_pair in seen_non_additive and not (row["key"].endswith("+") or row.get("allow_duplicate")):
                fail(f"duplicate catalog key: {path} {key_pair}")
            seen_non_additive.add(key_pair)
            row_type = row["type"]
            if row_type == "string":
                refs.add(row["entry"])
            elif row_type == "tuple":
                for item in row["items"]:
                    refs.add(item["entry"])
            elif row_type == "template":
                for part in row["parts"]:
                    if isinstance(part, dict) and "entry" in part:
                        refs.add(part["entry"])
            elif row_type == "literal":
                pass
            else:
                fail(f"unsupported catalog type during validation: {row_type}")

    translation_refs = set()
    for group, payload in translation.items():
        if group == "schema":
            continue
        if not SAFE_GROUP_RE.fullmatch(group):
            fail(f"unsafe translation group: {group}")
        for entry_id, item in payload.items():
            ref = f"{group}/{entry_id}"
            translation_refs.add(ref)
            if not item.get("en"):
                fail(f"{ref}: empty en")
            if not isinstance(item.get("zh_CN", ""), str):
                fail(f"{ref}: zh_CN must be a string")
    missing = refs - translation_refs
    extra = translation_refs - refs
    if missing:
        fail(f"catalog references missing translation entries: {sorted(missing)[:10]}")
    if extra:
        fail(f"translation has uncataloged entries: {sorted(extra)[:10]}")


def make_validation_translation(translation):
    cloned = json.loads(json.dumps(translation, ensure_ascii=False))
    for group, payload in cloned.items():
        if group == "schema":
            continue
        for item in payload.values():
            placeholders = [f"%{kind}" for kind in PRINTF_RE.findall(item["en"])]
            item["zh_CN"] = "TEST" + ((" " + " ".join(placeholders)) if placeholders else "")
    return cloned


def run_build_validation(temp_json: Path, temp_catalog: Path):
    validation_out = TEMP_EXPORT_ROOT / "build_validation"
    if validation_out.exists():
        shutil.rmtree(validation_out)
    proc = subprocess.run(
        [
            sys.executable,
            "-X",
            "utf8",
            str(ROOT_DIR / "tools" / "build_langpack.py"),
            "--json",
            str(temp_json),
            "--catalog",
            str(temp_catalog),
            "--out",
            str(validation_out),
        ],
        cwd=ROOT_DIR,
        text=True,
        encoding="utf-8",
        errors="replace",
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if proc.returncode != 0:
        fail(f"build_langpack.py validation failed:\n{proc.stdout[-4000:]}")
    manifest_path = validation_out / "manifest.json"
    if not manifest_path.exists():
        fail("build_langpack.py validation did not produce validation manifest.json")
    manifest = load_json_text(manifest_path.read_text(encoding="utf-8"))
    files = manifest.get("files", [])
    summary = OrderedDict(
        [
            ("ok", True),
            ("generated_files", len(files)),
            ("total_entries", sum(int(item.get("entries", 0)) for item in files)),
            ("total_bytes", sum(int(item.get("bytes", 0)) for item in files)),
            ("untranslated_fallbacks", int(manifest.get("untranslated_fallbacks", 0))),
            ("bare_upgraded_to_quoted", int(manifest.get("bare_upgraded_to_quoted", 0))),
            ("stdout_lines", len(proc.stdout.splitlines())),
        ]
    )
    if validation_out.exists():
        shutil.rmtree(validation_out)
    return summary


def cleanup_temp_root() -> None:
    if TEMP_EXPORT_ROOT.exists() and TEMP_EXPORT_ROOT.name.startswith("swrc_"):
        shutil.rmtree(TEMP_EXPORT_ROOT)


def process_supplementary_sources(
    catalog_files,
    translation,
    allocator,
    en_outputs,
    de_index,
    stats,
    reset_translations,
    audit,
):
    """Add supplementary EN sources beyond the JP index (forum language packs)."""
    if not SUPPLEMENTARY_EN_DIR.exists():
        return

    def parse_supplementary_int(path):
        try:
            return parse_int_file(path, "utf-8")
        except UnicodeDecodeError:
            return parse_int_file(path, "cp1252")

    supp_stats = OrderedDict()

    # 1. ctmarkers.int — new file (Marker/Charge prompt texts)
    ctmarkers_path = SUPPLEMENTARY_EN_DIR / "ctmarkers.int"
    if ctmarkers_path.exists():
        rows, _, _ = parse_supplementary_int(ctmarkers_path)
        output_path = f"GameData/System/ctmarkers{OUTPUT_EXT}"
        file_stem = "ctmarkers"
        count = 0
        for row in rows:
            source = source_from_int_row(row)
            de_val = de_index.get((file_stem.casefold(), row.section.casefold(), row.key), "")
            emit_from_source(
                catalog_files, translation, allocator,
                output_path, row.section, row.key, source,
                "", de_val, file_stem, stats, reset_translations,
            )
            count += 1
        en_outputs[output_path] = rows
        supp_stats["ctmarkers"] = count

    # 2. credits.int — extra CreditsLine entries beyond JP/Steam coverage
    credits_path = SUPPLEMENTARY_EN_DIR / "credits.int"
    credits_output = f"GameData/System/credits{OUTPUT_EXT}"
    if credits_path.exists() and credits_output in catalog_files:
        existing_keys = {
            (row.get("section", ""), row.get("key", ""))
            for row in catalog_files[credits_output]
        }
        supp_rows, _, _ = parse_supplementary_int(credits_path)
        count = 0
        for row in supp_rows:
            if not row.key.startswith("CreditsLine"):
                continue
            if (row.section, row.key) in existing_keys:
                continue
            catalog_files[credits_output].append(
                make_literal_row(
                    row.section, row.key, row.value,
                    f"{credits_output} [{row.section}] {row.key}",
                    stats,
                )
            )
            existing_keys.add((row.section, row.key))
            count += 1
        if credits_output in en_outputs:
            en_existing = {(r.section, r.key) for r in en_outputs[credits_output]}
            en_outputs[credits_output].extend(
                r for r in supp_rows
                if r.key.startswith("CreditsLine") and (r.section, r.key) not in en_existing
            )
        supp_stats["credits_extra_lines"] = count

    # 3. xinterfacectmenus.int — PS/Demo/PC sections not in JP index
    menus_path = SUPPLEMENTARY_EN_DIR / "xinterfacectmenus.int"
    menus_output = f"GameData/System/XinterfaceCtmenus{OUTPUT_EXT}"
    if menus_path.exists():
        supp_rows, _, _ = parse_supplementary_int(menus_path)
        file_stem = "XinterfaceCtmenus"
        count = 0
        extra_en = []
        for row in supp_rows:
            if row.section not in SUPPLEMENTARY_MENU_SECTIONS:
                continue
            source = source_from_int_row(row)
            de_val = de_index.get(("xinterfacectmenus", row.section.casefold(), row.key), "")
            emit_from_source(
                catalog_files, translation, allocator,
                menus_output, row.section, row.key, source,
                "", de_val, file_stem, stats, reset_translations,
            )
            extra_en.append(row)
            count += 1
        if menus_output in en_outputs:
            en_outputs[menus_output].extend(extra_en)
        else:
            en_outputs[menus_output] = extra_en
        supp_stats["menu_ps_demo"] = count

    audit["supplementary_sources"] = supp_stats


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skip-build-validation", action="store_true", help="只生成 JSON，不运行 build_langpack.py 临时校验")
    parser.add_argument("--allow-skipped", action="store_true", help="允许生成包含 skipped 项的 JSON（过渡/审查用）")
    parser.add_argument("--reset-translations", action="store_true", help="重新生成时清空已有 zh_CN 译文")
    args = parser.parse_args(argv)

    for required in (JP_SYSTEM_DIR, SYSTEM_DIR, PROPERTIES_DIR, MAPS_DIR):
        if not required.exists():
            fail(f"required path not found: {required}")

    audit = OrderedDict(
        [
            ("tool", TOOL_NAME),
            ("generated_at", utc_now()),
            (
                "input_roots",
                OrderedDict(
                    [
                        ("english_system", public_rel_path(SYSTEM_DIR)),
                        ("english_properties", public_rel_path(PROPERTIES_DIR)),
                        ("english_maps", public_rel_path(MAPS_DIR)),
                        ("japanese_system", public_rel_path(JP_SYSTEM_DIR)),
                    ]
                ),
            ),
            ("stats", OrderedDict()),
        ]
    )
    skipped = []
    stats = Counter()

    jp_ints, pseudo_comments, malformed_jp = parse_all_ints(JP_SYSTEM_DIR, "cp932")
    en_ints, _en_pseudo, malformed_en = parse_all_ints(SYSTEM_DIR, "cp1252")
    de_index = {}
    if DE_SYSTEM_DIR.exists():
        for det_path in sorted(DE_SYSTEM_DIR.glob("*.det"), key=lambda p: p.name.casefold()):
            try:
                rows, _, _ = parse_int_file(det_path, "utf-8")
            except UnicodeDecodeError:
                rows, _, _ = parse_int_file(det_path, "cp1252")
            stem = det_path.stem.casefold()
            for row in rows:
                de_index[(stem, row.section.casefold(), row.key)] = row.value
        stats["de_files"] = len(set(k[0] for k in de_index))
        stats["de_entries"] = len(de_index)
    duplicate_keys = duplicate_keys_by_file(jp_ints)
    audit["pseudo_comment_keys"] = pseudo_comments
    audit["malformed_jp_rows"] = malformed_jp
    audit["malformed_en_rows"] = malformed_en

    package_case = build_package_case()
    map_case = {p.stem.casefold(): p for p in MAPS_DIR.glob("*.ctm")}
    needed_packages = collect_needed_packages(jp_ints, en_ints, package_case)
    exported_packages = ensure_class_exports(needed_packages, package_case, audit)
    classes = load_class_defaults(exported_packages, audit)
    audit["class_count"] = len(classes)

    existing_translation = load_existing_translation()
    allocator = EntryAllocator(existing_translation)
    translation = OrderedDict([("schema", TRANSLATION_SCHEMA)])
    catalog_files = OrderedDict()
    en_outputs = OrderedDict()
    t3d_cache = {}
    t3d_temp = TEMP_EXPORT_ROOT / "t3d"
    if t3d_temp.exists():
        shutil.rmtree(t3d_temp)
    t3d_temp.mkdir(parents=True, exist_ok=True)

    for name, jp_info in jp_ints.items():
        jp_path = jp_info["path"]
        en_info = en_ints.get(name)
        output_file_name = en_info["path"].name if en_info else jp_path.name
        output_stem = Path(output_file_name).stem
        output_path = f"GameData/System/{output_stem}{OUTPUT_EXT}"
        file_stem = output_stem
        if en_info:
            en_outputs[output_path] = en_info["rows"]

        if name.startswith("subtitles_") and en_info:
            process_subtitle_file(
                jp_info,
                en_info,
                de_index,
                output_path,
                catalog_files,
                translation,
                allocator,
                skipped,
                audit,
                stats,
                args.reset_translations,
            )
            continue

        en_index = build_row_index(en_info["rows"]) if en_info else {}
        en_counters = Counter()
        map_file = map_file_for_int(jp_path.name, map_case)
        package_file = package_for_int(jp_path.name, package_case)

        for row in jp_info["rows"]:
            source = None
            source_origin = None
            source_section = row.section
            source_key = row.key
            direct_rows = en_index.get((row.section.casefold(), row.key))
            if direct_rows:
                ordinal_key = (row.section.casefold(), row.key)
                ordinal = en_counters[ordinal_key]
                en_counters[ordinal_key] += 1
                if ordinal < len(direct_rows):
                    en_row = direct_rows[ordinal]
                    source = source_from_int_row(en_row)
                    source_section = en_row.section
                    source_key = en_row.key
                    source_origin = "english_int"

            if source is None and map_file is not None:
                if map_file.name not in t3d_cache:
                    t3d_cache[map_file.name] = export_level_t3d(map_file, t3d_temp, audit)
                source = source_from_map(row, t3d_cache[map_file.name], classes, audit)
                source_origin = "map_t3d_or_default" if source else None

            if source is None and package_file is not None:
                source = source_from_package(row, classes, audit, "class_default")
                source_origin = "class_default" if source else None

            if source is None and row.section.casefold() == "levelsummary" and row.key == "Title":
                source = lookup_class_default(
                    classes,
                    "LevelInfo",
                    "Title",
                    audit,
                    OrderedDict(
                        [
                            ("origin", "levelinfo_default"),
                            ("file", row.file_name),
                            ("section", row.section),
                            ("key", row.key),
                        ]
                    ),
                    allow_prefix=False,
                )
                source_origin = "levelinfo_default" if source else None

            if source is None:
                source = source_from_package(row, classes, audit, "class_default_by_section")
                source_origin = "class_default_by_section" if source else None

            if source is None:
                skipped.append(
                    {
                        "reason_code": "no_english_runtime_source",
                        "file": jp_path.name,
                        "line": row.line_no,
                        "section": row.section,
                        "key": row.key,
                        "jp_value": row.value,
                        "reason": "no English runtime source found",
                    }
                )
                stats["skipped_no_source"] += 1
                continue

            try:
                de_val = de_index.get((file_stem.casefold(), source_section.casefold(), source_key), "")
                emitted = emit_from_source(
                    catalog_files,
                    translation,
                    allocator,
                    output_path,
                    source_section,
                    source_key,
                    source,
                    row.value,
                    de_val,
                    file_stem,
                    stats,
                    args.reset_translations,
                    (row.section.casefold(), row.key) in duplicate_keys.get(name, set()),
                )
                stats[f"source_{source_origin}"] += 1
                stats[f"emit_{emitted}"] += 1
            except GenerateError as exc:
                message = str(exc)
                skipped.append(
                    {
                        "reason_code": emit_error_reason_code(message),
                        "file": jp_path.name,
                        "line": row.line_no,
                        "section": row.section,
                        "key": row.key,
                        "jp_value": row.value,
                        "reason": message,
                    }
                )
                stats["skipped_emit_error"] += 1

        if en_info:
            append_en_passthrough_rows(output_path, en_info["rows"], catalog_files, stats, audit)

    process_supplementary_sources(
        catalog_files, translation, allocator, en_outputs,
        de_index, stats, args.reset_translations, audit,
    )

    translation = merge_shared_en_jp_entries(
        translation,
        catalog_files,
        existing_translation,
        stats,
        args.reset_translations,
        audit,
    )
    validate_catalog_covers_en_runtime(catalog_files, en_outputs, audit)

    catalog = OrderedDict(
        [
            ("schema", CATALOG_SCHEMA),
            ("generated_by", TOOL_NAME),
            ("generated_at", utc_now()),
            ("files", catalog_files),
        ]
    )
    audit["stats"].update(OrderedDict(sorted(stats.items())))
    audit["stats"]["jp_files"] = len(jp_ints)
    audit["stats"]["en_files"] = len(en_ints)
    audit["stats"]["catalog_files"] = len(catalog_files)
    audit["stats"]["translation_groups"] = len(translation) - 1
    audit["stats"]["translation_entries"] = sum(len(v) for k, v in translation.items() if k != "schema")
    audit["stats"]["skipped_entries"] = len(skipped)
    for stat_key in (
        "preserved_zh_CN",
        "new_blank_zh_CN",
        "reset_zh_CN",
        "preserved_translation_with_jp_change",
        "restored_from_shared",
        "en_passthrough_literal_rows",
        "passthrough_literal_normalized",
        "empty_english_literal_rows",
        "credits_jp_en_literal_rows",
        "subtitle_passthrough_literal_rows",
    ):
        audit["stats"].setdefault(stat_key, 0)
    audit["stats"]["skipped_policy"] = "allow-skipped" if args.allow_skipped else "strict"
    normalize_subtitle_remap_summary(audit)

    if skipped and not args.allow_skipped:
        fail(format_skipped_failure(skipped))

    validate_generated(translation, catalog)

    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    write_translation_json(translation)
    write_json(CATALOG_JSON, catalog)
    write_json(
        JP_ONLY_SKIPPED_JSON,
        OrderedDict(
            [
                ("generated_at", utc_now()),
                ("summary", skipped_summary(skipped)),
                ("entries", skipped),
            ]
        ),
    )

    if not args.skip_build_validation:
        temp_json = TEMP_EXPORT_ROOT / "identity_translation.json"
        temp_catalog = TEMP_EXPORT_ROOT / "identity_catalog.json"
        temp_json.parent.mkdir(parents=True, exist_ok=True)
        write_json(temp_json, make_validation_translation(translation))
        write_json(temp_catalog, catalog)
        audit["build_validation"] = run_build_validation(temp_json, temp_catalog)

    write_json(AUDIT_JSON, audit)
    cleanup_temp_root()
    print(f"wrote {TRANSLATION_JSON.relative_to(ROOT_DIR)}")
    print(f"wrote {CATALOG_JSON.relative_to(ROOT_DIR)}")
    print(f"translation entries: {audit['stats']['translation_entries']}")
    print(f"catalog files: {audit['stats']['catalog_files']}")
    print(f"skipped entries: {len(skipped)}")


if __name__ == "__main__":
    try:
        main()
    except GenerateError as exc:
        print(f"错误: {exc}", file=sys.stderr)
        sys.exit(1)
