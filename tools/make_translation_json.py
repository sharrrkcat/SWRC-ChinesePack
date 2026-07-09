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

SCRIPT_DIR = Path(__file__).resolve().parent
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


def read_text(path: Path, encoding: str) -> str:
    return path.read_text(encoding=encoding, errors="strict")


def public_rel_path(path: Path, start: Path = ROOT_DIR) -> str:
    return Path(os.path.relpath(path, start)).as_posix()


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
            else:
                out.append(nxt)
            i += 2
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def quote_unreal_raw(value: str) -> str:
    value = value.replace("\r\n", "\n").replace("\r", "\n").replace("\n", r"\n")
    value = value.replace('"', r"\"")
    return f'"{value}"'


def split_top_level(text: str, sep: str = ",") -> list[str]:
    parts = []
    start = 0
    depth = 0
    in_quote = False
    escape = False
    for index, ch in enumerate(text):
        if in_quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
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
    escape = False
    for index, ch in enumerate(text):
        if in_quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
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
    escape = False
    field_start = None
    value_start = None
    current_field = None
    index = 0
    while index < len(value):
        ch = value[index]
        if in_quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
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


def ensure_class_exports(package_names: set[str], package_case: dict[str, Path], audit: dict) -> None:
    exported = {}
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
        count = copy_tree_files(out_dir, target_dir, "*.uc")
        exported[package_file.stem] = {
            "package": public_rel_path(package_file, GAME_DATA),
            "package_arg": package_arg,
            "classes": count,
            "ucc_lines": len(output.splitlines()),
        }
    audit["class_exports"] = exported


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


def load_class_defaults():
    classes = {}
    for uc_path in sorted(EXPORT_DIR.glob("*/*.uc"), key=lambda p: p.as_posix().casefold()):
        class_name, parent, defaults = parse_uc_file(uc_path)
        classes[class_name.casefold()] = {
            "name": class_name,
            "parent": parent,
            "defaults": defaults,
            "path": uc_path.relative_to(ROOT_DIR).as_posix(),
        }
    return classes


def lookup_class_default(classes: dict, class_name: str, key: str, seen=None) -> SourceValue | None:
    if seen is None:
        seen = set()
    class_key = class_name.casefold()
    if class_key in seen:
        return None
    seen.add(class_key)
    info = classes.get(class_key)
    if not info:
        candidates = [
            candidate
            for candidate_key, candidate in classes.items()
            if len(candidate_key) >= 4 and class_key.startswith(candidate_key)
        ]
        if candidates:
            info = max(candidates, key=lambda item: len(item["name"]))
    if not info:
        return None
    normalized_key = normalize_uc_path(key)
    if normalized_key in info["defaults"]:
        return info["defaults"][normalized_key]
    parent = info.get("parent")
    if parent:
        return lookup_class_default(classes, parent, normalized_key, seen)
    return None


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
        payload = json.loads(TRANSLATION_JSON.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError:
        return None
    if payload.get("schema") != TRANSLATION_SCHEMA:
        return None
    return payload


def add_translation_entry(
    translation: OrderedDict,
    allocator: EntryAllocator,
    base_group: str,
    note: str,
    en: str,
    jp: str,
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
        stats["new_blank_zh_CN"] += 1
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
            ("zh_CN", zh_cn),
        ]
    )
    return f"{group}/{entry_id}"


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
        ref = add_translation_entry(
            translation,
            allocator,
            group,
            key,
            source.text or "",
            jp_text,
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
        if source.items is None:
            fail(f"{output_path} [{section}] {key}: tuple source missing items")
        if jp_items and len(jp_items) != len(source.items):
            fail(f"{output_path} [{section}] {key}: JP tuple item count mismatch")
        items = []
        for index, en_item in enumerate(source.items):
            note = f"{key}[{index}]"
            jp_item = jp_items[index] if index < len(jp_items) else ""
            ref = add_translation_entry(
                translation,
                allocator,
                group,
                note,
                en_item,
                jp_item,
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
            ref = add_translation_entry(
                translation,
                allocator,
                group,
                note,
                en_text,
                jp_text,
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
    return lookup_class_default(classes, obj["class"], normalized_key)


def source_from_package(row: IntRow, classes: dict) -> SourceValue | None:
    return lookup_class_default(classes, row.section, row.key)


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
        return pairs, text_by_index

    jp_pairs, jp_text_by_index = subtitle_pairs(jp_rows)
    jp_by_sound = defaultdict(list)
    for jp_index, sound_row, text_row in jp_pairs:
        jp_by_sound[unquote_unreal(sound_row.value)].append((jp_index, unquote_unreal(text_row.value)))

    en_pairs, _en_text_by_index = subtitle_pairs(en_rows)
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
        for candidate_ordinal, (candidate_index, candidate_text) in enumerate(jp_by_sound.get(sound, [])):
            pair_key = (sound, candidate_ordinal)
            if pair_key not in used_jp_pairs:
                jp_index = candidate_index
                jp_text = candidate_text
                used_jp_pairs.add(pair_key)
                break
        rows = catalog_files.setdefault(output_path, [])
        sound_catalog_row = OrderedDict([("section", sound_row.section), ("key", sound_row.key), ("type", "literal"), ("value", sound_row.value)])
        if duplicate_counts[(sound_row.section, sound_row.key)] > 1:
            sound_catalog_row["allow_duplicate"] = True
        rows.append(sound_catalog_row)
        source = source_from_int_row(text_row)
        ref = add_translation_entry(
            translation,
            allocator,
            get_group(file_stem, section),
            text_row.key,
            source.text or "",
            jp_text,
            index,
            "SubtitleText",
            stats,
            reset_translations,
        )
        rows.append(
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
            rows[-1]["allow_duplicate"] = True
        stats["subtitle_pairs"] += 1
        if jp_index is not None and jp_index != index:
            remap_count += 1
            remap_deltas[subtitle_index_delta(index, jp_index)] += 1

    for sound, pairs in jp_by_sound.items():
        if sound == "":
            continue
        for candidate_ordinal, (jp_index, _jp_text) in enumerate(pairs):
            if (sound, candidate_ordinal) not in used_jp_pairs:
                skipped.append(
                    {
                        "reason_code": "jp_subtitle_sound_missing",
                        "file": jp_info["path"].name,
                        "section": jp_rows[0].section if jp_rows else "",
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
            if item.get("zh_CN", None) != "":
                fail(f"{ref}: zh_CN must be empty in generated source JSON")
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
    proc = subprocess.run(
        [sys.executable, "-X", "utf8", str(ROOT_DIR / "tools" / "build_langpack.py"), "--json", str(temp_json), "--catalog", str(temp_catalog)],
        cwd=ROOT_DIR,
        text=True,
        encoding="utf-8",
        errors="replace",
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if proc.returncode != 0:
        fail(f"build_langpack.py validation failed:\n{proc.stdout[-4000:]}")
    build_dir = ROOT_DIR / "build"
    manifest_path = build_dir / "manifest.json"
    if not manifest_path.exists():
        fail("build_langpack.py validation did not produce build/manifest.json")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    files = manifest.get("files", [])
    summary = OrderedDict(
        [
            ("ok", True),
            ("generated_files", len(files)),
            ("total_entries", sum(int(item.get("entries", 0)) for item in files)),
            ("total_bytes", sum(int(item.get("bytes", 0)) for item in files)),
            ("untranslated_fallbacks", int(manifest.get("untranslated_fallbacks", 0))),
            ("stdout_lines", len(proc.stdout.splitlines())),
        ]
    )
    if build_dir.exists():
        shutil.rmtree(build_dir)
    return summary


def cleanup_temp_root() -> None:
    if TEMP_EXPORT_ROOT.exists() and TEMP_EXPORT_ROOT.name.startswith("swrc_"):
        shutil.rmtree(TEMP_EXPORT_ROOT)


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
    duplicate_keys = duplicate_keys_by_file(jp_ints)
    audit["pseudo_comment_keys"] = pseudo_comments
    audit["malformed_jp_rows"] = malformed_jp
    audit["malformed_en_rows"] = malformed_en

    package_case = build_package_case()
    map_case = {p.stem.casefold(): p for p in MAPS_DIR.glob("*.ctm")}
    needed_packages = collect_needed_packages(jp_ints, en_ints, package_case)
    ensure_class_exports(needed_packages, package_case, audit)
    classes = load_class_defaults()
    audit["class_count"] = len(classes)

    existing_translation = load_existing_translation()
    allocator = EntryAllocator(existing_translation)
    translation = OrderedDict([("schema", TRANSLATION_SCHEMA)])
    catalog_files = OrderedDict()
    t3d_cache = {}
    t3d_temp = TEMP_EXPORT_ROOT / "t3d"
    if t3d_temp.exists():
        shutil.rmtree(t3d_temp)
    t3d_temp.mkdir(parents=True, exist_ok=True)

    for name, jp_info in jp_ints.items():
        jp_path = jp_info["path"]
        en_info = en_ints.get(name)
        output_file_name = en_info["path"].name if en_info else jp_path.name
        output_path = f"GameData/System/{output_file_name}"
        file_stem = Path(output_file_name).stem

        if name.startswith("subtitles_") and en_info:
            process_subtitle_file(
                jp_info,
                en_info,
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
                source = source_from_map(row, t3d_cache[map_file.name], classes)
                source_origin = "map_t3d_or_default" if source else None

            if source is None and package_file is not None:
                source = source_from_package(row, classes)
                source_origin = "class_default" if source else None

            if source is None and row.section.casefold() == "levelsummary" and row.key == "Title":
                source = lookup_class_default(classes, "LevelInfo", "Title")
                source_origin = "levelinfo_default" if source else None

            if source is None:
                source = source_from_package(row, classes)
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
                emitted = emit_from_source(
                    catalog_files,
                    translation,
                    allocator,
                    output_path,
                    source_section,
                    source_key,
                    source,
                    row.value,
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
    for stat_key in ("preserved_zh_CN", "new_blank_zh_CN", "reset_zh_CN", "preserved_translation_with_jp_change"):
        audit["stats"].setdefault(stat_key, 0)
    audit["stats"]["skipped_policy"] = "allow-skipped" if args.allow_skipped else "strict"
    normalize_subtitle_remap_summary(audit)

    if skipped and not args.allow_skipped:
        fail(format_skipped_failure(skipped))

    validate_generated(translation, catalog)

    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    write_json(TRANSLATION_JSON, translation)
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
