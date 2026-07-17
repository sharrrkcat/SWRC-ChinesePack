#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Import PS4 Chinese translation pack into translation.json.

Reads PS4 .cht files, maps entries to translation.json via the localization
catalog, and fills zh_CN fields.  Does NOT do traditional→simplified conversion
(the PS4 pack is already simplified).  Glossary consistency is left as a
separate post-import step.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
from collections import OrderedDict, Counter, defaultdict
from pathlib import Path


def unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
        inner = value[1:-1]
    else:
        inner = value
    out = []
    i = 0
    while i < len(inner):
        if inner[i] == "\\" and i + 1 < len(inner):
            if inner[i + 1] == "n":
                out.append("\n")
                i += 2
                continue
        out.append(inner[i])
        i += 1
    return "".join(out)


def parse_quoted_tuple(value: str) -> list[str] | None:
    value = value.strip()
    if not (value.startswith("(") and value.endswith(")")):
        return None
    inner = value[1:-1]
    items = []
    in_quote = False
    start = 0
    for i, ch in enumerate(inner):
        if in_quote:
            if ch == '"':
                in_quote = False
        elif ch == '"':
            in_quote = True
        elif ch == ',':
            items.append(inner[start:i].strip())
            start = i + 1
    items.append(inner[start:].strip())
    result = []
    for item in items:
        if len(item) >= 2 and item[0] == '"' and item[-1] == '"':
            result.append(unquote(item))
        else:
            return None
    return result


STRUCT_TEXT_FIELDS = {"Caption", "Parent", "Text", "HelpText", "Objective"}


def extract_template_texts(value: str) -> dict[str, list[str]]:
    fields: dict[str, list[str]] = defaultdict(list)
    in_quote = False
    current_field = None
    value_start = None
    index = 0
    while index < len(value):
        ch = value[index]
        if in_quote:
            if ch == '"':
                cursor = index + 1
                while cursor < len(value) and value[cursor].isspace():
                    cursor += 1
                if cursor == len(value) or value[cursor] in (",", ")"):
                    raw = value[value_start:index + 1]
                    text = unquote(raw)
                    if current_field in STRUCT_TEXT_FIELDS and text != "":
                        fields[current_field].append(text)
                    in_quote = False
                    current_field = None
            index += 1
            continue
        if ch == "=":
            left = value[:index].rstrip()
            m = re.search(r"([A-Za-z_][A-Za-z0-9_]*)$", left)
            if m and index + 1 < len(value) and value[index + 1] == '"':
                current_field = m.group(1)
                value_start = index + 1
                in_quote = True
                index += 2
                continue
        index += 1
    return dict(fields)


def parse_cht(filepath: Path) -> list[tuple[str, str, str]]:
    content = filepath.read_text(encoding="utf-8")
    entries = []
    section = None
    for line in content.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if section is None or "=" not in line:
            continue
        key, value = line.split("=", 1)
        entries.append((section, key, value))
    return entries


def build_catalog_index(catalog: dict):
    """Build (filename_lower, section, key) -> entry mapping from catalog."""
    strict = {}     # (filename, section, key) -> entry info
    crossfile = {}  # (section, key) -> entry info (first match)

    for filepath, file_entries in catalog["files"].items():
        filename = Path(filepath).name.lower()
        for entry_def in file_entries:
            section = entry_def["section"]
            key = entry_def["key"]
            etype = entry_def["type"]

            if etype == "string":
                info = {"type": "string", "entry": entry_def["entry"]}
            elif etype == "template":
                parts = [p for p in entry_def.get("parts", [])
                         if isinstance(p, dict) and "entry" in p]
                if not parts:
                    continue
                field_names = []
                for p in entry_def.get("parts", []):
                    if isinstance(p, dict) and "entry" in p:
                        entry_ref = p["entry"]
                        group, eid = entry_ref.rsplit("/", 1)
                        field_names.append(entry_ref)
                info = {"type": "template", "entries": field_names}
            elif etype == "tuple":
                items = entry_def.get("items", [])
                info = {"type": "tuple",
                        "entries": [item["entry"] for item in items]}
            else:
                continue

            sk = (filename, section, key)
            if sk not in strict:
                strict[sk] = info
            sk2 = (section, key)
            if sk2 not in crossfile:
                crossfile[sk2] = info

    return strict, crossfile


def fill_entry(translation: dict, entry_id: str, zh_text: str,
               stats: Counter) -> bool:
    if not zh_text:
        return False
    group, eid = entry_id.rsplit("/", 1)
    if group not in translation or eid not in translation[group]:
        stats["entry_not_found"] += 1
        return False
    entry = translation[group][eid]
    existing = entry.get("zh_CN", "")
    if existing:
        if existing == zh_text:
            stats["already_same"] += 1
        else:
            stats["conflict"] += 1
        return False
    entry["zh_CN"] = zh_text
    stats["filled"] += 1
    return True


def resolve_template(info: dict, ps4_value: str, translation: dict,
                     stats: Counter):
    entry_ids = info["entries"]
    ps4_fields = extract_template_texts(ps4_value)

    catalog_field_map = {}
    for entry_id in entry_ids:
        group, eid = entry_id.rsplit("/", 1)
        if group in translation and eid in translation[group]:
            note = translation[group][eid].get("note", "")
            m = re.match(r"[^.]+\.(\w+)", note)
            if m:
                field_name = m.group(1)
                catalog_field_map.setdefault(field_name, []).append(entry_id)

    for field_name, texts in ps4_fields.items():
        targets = catalog_field_map.get(field_name, [])
        for i, text in enumerate(texts):
            if i < len(targets):
                fill_entry(translation, targets[i], text, stats)


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ps4-dir", type=Path, required=True, help="PS4 .cht 输入目录")
    parser.add_argument("--catalog", type=Path, required=True, help="localization_catalog.json 输入路径")
    parser.add_argument("--translation", type=Path, required=True, help="translation.json 输入路径")
    parser.add_argument("--out", type=Path, required=True, help="合并后的 translation.json 输出路径")
    parser.add_argument("--backup", type=Path, help="覆盖输入文件时必须指定的备份路径")
    parser.add_argument("--overwrite-backup", action="store_true", help="允许覆盖已存在的 --backup")
    parser.add_argument("--dry-run", action="store_true", help="只统计映射结果，不写输出或备份")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    ps4_dir = args.ps4_dir.resolve()
    catalog_json = args.catalog.resolve()
    translation_json = args.translation.resolve()
    output_json = args.out.resolve()
    backup_json = args.backup.resolve() if args.backup else None

    for path, label in (
        (ps4_dir, "PS4 input directory"),
        (catalog_json, "catalog"),
        (translation_json, "translation"),
    ):
        if not path.exists():
            raise SystemExit(f"{label} not found: {path}")
    if not output_json.parent.is_dir():
        raise SystemExit(f"output parent directory not found: {output_json.parent}")
    replacing_input = output_json == translation_json
    if replacing_input and not args.dry_run and backup_json is None:
        raise SystemExit("--backup is required when --out overwrites --translation")
    if backup_json is not None:
        if backup_json == translation_json or backup_json == output_json:
            raise SystemExit("--backup must differ from --translation and --out")
        if not backup_json.parent.is_dir():
            raise SystemExit(f"backup parent directory not found: {backup_json.parent}")
        if backup_json.exists() and not args.overwrite_backup:
            raise SystemExit(f"backup already exists (use --overwrite-backup): {backup_json}")

    with catalog_json.open("r", encoding="utf-8") as f:
        catalog = json.load(f)
    with translation_json.open("r", encoding="utf-8") as f:
        translation = json.load(f)

    strict_index, crossfile_index = build_catalog_index(catalog)
    stats = Counter()
    ps4_files = sorted(ps4_dir.glob("*.cht"))
    print(f"PS4 files: {len(ps4_files)}")

    for ps4_file in ps4_files:
        fname = ps4_file.name.lower()
        file_stats = Counter()

        for section, key, value in parse_cht(ps4_file):
            stats["ps4_total"] += 1

            lookup = (fname, section, key)
            info = strict_index.get(lookup)
            if info is None:
                info = crossfile_index.get((section, key))
                if info is not None:
                    stats["crossfile_match"] += 1

            if info is None:
                stats["no_match"] += 1
                continue

            stats["matched"] += 1

            if info["type"] == "string":
                text = unquote(value)
                if text:
                    fill_entry(translation, info["entry"], text, file_stats)
                else:
                    file_stats["empty_value"] += 1

            elif info["type"] == "tuple":
                items = parse_quoted_tuple(value)
                if items and len(items) == len(info["entries"]):
                    for item_text, entry_id in zip(items, info["entries"]):
                        fill_entry(translation, entry_id, item_text, file_stats)
                elif items:
                    file_stats["tuple_length_mismatch"] += 1
                else:
                    file_stats["tuple_parse_fail"] += 1

            elif info["type"] == "template":
                resolve_template(info, value, translation, file_stats)

        if file_stats["filled"]:
            print(f"  {ps4_file.name:40s} filled={file_stats['filled']}")
        stats.update(file_stats)

    total_entries = sum(len(g) for k, g in translation.items() if k != "schema")
    filled_total = sum(
        1 for k, g in translation.items() if k != "schema"
        for e in g.values() if e.get("zh_CN", "")
    )

    print()
    print("=" * 60)
    print(f"PS4 entries scanned:     {stats['ps4_total']}")
    print(f"Matched to catalog:      {stats['matched']}")
    print(f"  via cross-file:        {stats['crossfile_match']}")
    print(f"No match:                {stats['no_match']}")
    print()
    print(f"zh_CN filled:            {stats['filled']}")
    print(f"Already same:            {stats['already_same']}")
    print(f"Conflicts (skipped):     {stats['conflict']}")
    print(f"Empty values skipped:    {stats['empty_value']}")
    print(f"Entry not found:         {stats['entry_not_found']}")
    print(f"Tuple mismatches:        {stats['tuple_length_mismatch']}")
    print()
    print(f"translation.json total:  {total_entries}")
    print(f"zh_CN filled (total):    {filled_total}")
    print(f"Fill rate:               {filled_total/total_entries*100:.1f}%")

    if args.dry_run:
        print("\nDry run: no files written")
        return
    if backup_json is not None:
        shutil.copy2(translation_json, backup_json)
        print(f"\nBacked up to {backup_json}")

    output_json.write_text(
        json.dumps(translation, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {output_json}")


if __name__ == "__main__":
    main()
