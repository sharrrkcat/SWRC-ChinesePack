#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从翻译 JSON + localization catalog 生成 SWRC 简中语言包文本产物。

在仓库根目录运行时可省略默认输入路径：
    py -X utf8 tools/build_langpack.py --out build

也可显式指定全部路径：
    py -X utf8 tools/build_langpack.py --json <translation.json> \
        --catalog <localization_catalog.json> --out <output-dir>

本工具只生成文件，不写入游戏目录，不做还原。
"""

import argparse
import hashlib
import json
import re
import sys
from collections import OrderedDict
from datetime import datetime, timezone
from pathlib import Path


TOOL_NAME = "build_langpack.py"
TRANSLATION_SCHEMA = 2
CATALOG_SCHEMA = 1
DEFAULT_JSON = "translation.json"
DEFAULT_CATALOG = "reference/export/localization_catalog.json"
SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
ROOT_DIR = SCRIPT_DIR.parent
SAFE_GROUP_RE = re.compile(r"^[A-Za-z0-9_.-]+$")
SAFE_ID_RE = re.compile(r"^[0-9]+$")
SAFE_INT_FILE_RE = re.compile(r"^[A-Za-z0-9_.-]+\.cht$", re.IGNORECASE)
PRINTF_RE = re.compile(
    r"%(?!%)(?:\d+\$)?[-+#0]*(?:\*|\d+)?(?:\.(?:\*|\d+))?"
    r"(?:hh|h|ll|l|L)?([A-Za-z])"
)
from localization_common import FALLBACK_REPLACEMENTS, normalize_fallback_text


class BuildError(Exception):
    pass


def fail(message):
    raise BuildError(message)


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def repo_relative(path):
    try:
        return path.resolve().relative_to(ROOT_DIR.resolve()).as_posix()
    except ValueError:
        return str(path)


def safe_build_path(output_root, rel_path):
    rel = Path(rel_path)
    if rel.is_absolute():
        fail(f"拒绝绝对输出路径: {rel_path}")
    if any(part in ("", ".", "..") for part in rel.parts):
        fail(f"拒绝不安全输出路径: {rel_path}")
    output_root = output_root.resolve()
    out = (output_root / rel).resolve()
    try:
        out.relative_to(output_root)
    except ValueError:
        fail(f"输出路径逃逸输出目录: {rel_path}")
    return out


def ensure_text(label, value, allow_empty=True, allow_newlines=False):
    if not isinstance(value, str):
        fail(f"{label} 必须是字符串")
    if not allow_empty and value == "":
        fail(f"{label} 不能为空")
    if "\0" in value or (not allow_newlines and ("\r" in value or "\n" in value)):
        fail(f"{label} 含非法控制字符")
    return value


def quote_unreal(value):
    value = value.replace("\r\n", "\n").replace("\r", "\n").replace("\n", r"\n")
    return f'"{value}"'


def quote_tuple(values):
    return "(" + ",".join(quote_unreal(value) for value in values) + ")"


def format_text_value(value, style, label):
    if style in (None, "quoted"):
        return quote_unreal(value)
    if style == "bare":
        if "\r" in value or "\n" in value or "\0" in value:
            fail(f"{label}: bare 文本含非法控制字符")
        if "=" in value:
            fail(f"{label}: bare 文本含 '='，请改用 quoted 或 template")
        return value
    fail(f"{label}: 未支持的文本输出样式 {style!r}")


def bare_needs_quoted(value):
    return (
        "=" in value
        or '"' in value
        or value != value.strip()
        or value.startswith("(")
        or value.startswith('"')
    )


def format_translation_value(value, style, label):
    upgraded = False
    if style == "bare" and bare_needs_quoted(value):
        style = "quoted"
        upgraded = True
    return format_text_value(value, style, label), upgraded


def printf_types(value):
    return PRINTF_RE.findall(value)


def normalize_untranslated_fallback(value):
    return normalize_fallback_text(value)


def load_json_file(path, label):
    try:
        text = path.read_text(encoding="utf-8-sig")
        return json.loads(text, object_pairs_hook=reject_duplicate_json_keys)
    except FileNotFoundError:
        fail(f"找不到{label}: {repo_relative(path)}")
    except json.JSONDecodeError as e:
        fail(f"{repo_relative(path)}: JSON 解析失败: {e}")
    except ValueError as e:
        fail(f"{repo_relative(path)}: JSON 解析失败: {e}")


def reject_duplicate_json_keys(pairs):
    result = OrderedDict()
    for key, value in pairs:
        if key in result:
            raise ValueError(f"重复 JSON key: {key!r}")
        result[key] = value
    return result


def parse_entry_ref(ref, label):
    if not isinstance(ref, str) or ref.count("/") != 1:
        fail(f"{label}: entry 必须形如 group/id")
    group, entry_id = ref.split("/", 1)
    if not SAFE_GROUP_RE.fullmatch(group):
        fail(f"{label}: 非法 group: {group!r}")
    if not SAFE_ID_RE.fullmatch(entry_id):
        fail(f"{label}: 非法 id: {entry_id!r}")
    return group, entry_id


def load_translation(json_path):
    payload = load_json_file(json_path, "翻译 JSON")
    if not isinstance(payload, dict):
        fail("翻译 JSON 顶层必须是对象")
    if payload.get("schema") != TRANSLATION_SCHEMA:
        fail(f"不支持的翻译 JSON schema: {payload.get('schema')!r}")

    entries = {}
    for group, group_payload in payload.items():
        if group == "schema":
            continue
        if not SAFE_GROUP_RE.fullmatch(group):
            fail(f"非法翻译分组名: {group!r}")
        if not isinstance(group_payload, dict):
            fail(f"{group}: 分组内容必须是对象")
        for entry_id, item in group_payload.items():
            if not SAFE_ID_RE.fullmatch(str(entry_id)):
                fail(f"{group}: 非法条目 id: {entry_id!r}")
            if not isinstance(item, dict):
                fail(f"{group}/{entry_id}: 条目必须是对象")
            note = ensure_text(f"{group}/{entry_id}: note", item.get("note", ""), allow_newlines=True)
            en = ensure_text(f"{group}/{entry_id}: en", item.get("en"), allow_empty=False, allow_newlines=True)
            jp = ensure_text(f"{group}/{entry_id}: jp", item.get("jp", ""), allow_newlines=True)
            zh = ensure_text(f"{group}/{entry_id}: zh_CN", item.get("zh_CN", ""), allow_newlines=True)
            ref = f"{group}/{entry_id}"
            if ref in entries:
                fail(f"重复翻译条目: {ref}")
            entries[ref] = {"note": note, "en": en, "jp": jp, "zh_CN": zh}
    if not entries:
        fail("翻译 JSON 没有可用条目")
    return payload, entries


def load_catalog(catalog_path):
    payload = load_json_file(catalog_path, "localization catalog")
    if not isinstance(payload, dict):
        fail("catalog 顶层必须是对象")
    if payload.get("schema") != CATALOG_SCHEMA:
        fail(f"不支持的 catalog schema: {payload.get('schema')!r}")
    files = payload.get("files")
    if not isinstance(files, dict) or not files:
        fail("catalog 缺少 files 对象")
    return payload, files


def validate_output_path(path_text):
    if not isinstance(path_text, str) or not path_text:
        fail("catalog 输出路径不能为空")
    if "\\" in path_text or "\0" in path_text:
        fail(f"catalog 输出路径含非法字符: {path_text!r}")
    rel = Path(path_text)
    if rel.is_absolute():
        fail(f"catalog 输出路径不能是绝对路径: {path_text}")
    if any(part in ("", ".", "..") for part in rel.parts):
        fail(f"catalog 输出路径不安全: {path_text}")
    parts = rel.parts
    if len(parts) != 3 or parts[0].casefold() != "gamedata" or parts[1].casefold() != "system":
        fail(f"catalog 输出路径必须位于 GameData/System: {path_text}")
    if not SAFE_INT_FILE_RE.fullmatch(parts[2]):
        fail(f"catalog 输出路径必须是安全 .cht 文件名: {path_text}")
    return "/".join(parts)


def validate_section_key(row_label, row):
    section = ensure_text(f"{row_label}: section", row.get("section"), allow_empty=False)
    key = ensure_text(f"{row_label}: key", row.get("key"), allow_empty=False)
    if "/" in section or "\\" in section or "[" in section or "]" in section:
        fail(f"{row_label}: 非法 section: {section!r}")
    if "/" in key or "\\" in key or "=" in key:
        fail(f"{row_label}: 非法 key: {key!r}")
    return section, key


def validate_printf_spec(spec, label):
    if spec is None:
        return []
    if not isinstance(spec, list) or any(not isinstance(item, str) for item in spec):
        fail(f"{label}: printf 必须是字符串数组")
    return spec


def resolve_translation(ref, expected_printf, translations, used_refs, allow_untranslated, label):
    if ref not in translations:
        fail(f"{label}: catalog 引用不存在的翻译条目 {ref}")
    item = translations[ref]
    text = item["zh_CN"]
    fallback = False
    if text == "":
        if not allow_untranslated:
            fail(f"{ref}: zh_CN 不能为空")
        text = normalize_untranslated_fallback(item["en"])
        fallback = True

    actual_printf = printf_types(text)
    if actual_printf != expected_printf:
        fail(f"{ref}: 占位符类型/顺序不一致 expected={expected_printf} actual={actual_printf}")
    try:
        text.encode("gbk")
    except UnicodeEncodeError as e:
        bad = e.object[e.start : e.end]
        fail(f"{ref}: 文本含 GBK 不可编码字符 {bad!r}")

    used_refs.add(ref)
    return text, fallback


def add_output_line(file_state, section, key, value, allow_duplicate=False):
    seen_key = (section, key)
    if seen_key in file_state["seen_keys"] and not (allow_duplicate or key.endswith("+")):
        fail(f"{file_state['path']}: 重复输出键 [{section}] {key}")
    file_state["seen_keys"].add(seen_key)
    section_lines = file_state["sections"].setdefault(section, [])
    section_lines.append((key, value))
    file_state["row_count"] += 1


def render_template_parts(parts, translations, used_refs, allow_untranslated, label):
    if not isinstance(parts, list) or not parts:
        fail(f"{label}: template 行缺少非空 parts")
    rendered = []
    fallback_count = 0
    bare_upgrade_count = 0
    for part_index, part in enumerate(parts):
        part_label = f"{label}.parts[{part_index}]"
        if isinstance(part, str):
            rendered.append(ensure_text(part_label, part, allow_empty=True, allow_newlines=True))
            continue
        if not isinstance(part, dict):
            fail(f"{part_label}: template part 必须是字符串或对象")
        if "literal" in part:
            rendered.append(ensure_text(f"{part_label}.literal", part["literal"], allow_empty=True, allow_newlines=True))
            continue
        ref = part.get("entry")
        parse_entry_ref(ref, part_label)
        expected_printf = validate_printf_spec(part.get("printf", []), part_label)
        text, fallback = resolve_translation(
            ref, expected_printf, translations, used_refs, allow_untranslated, part_label
        )
        rendered_value, upgraded = format_translation_value(text, part.get("style", "quoted"), part_label)
        rendered.append(rendered_value)
        if fallback:
            fallback_count += 1
        if upgraded:
            bare_upgrade_count += 1
    return "".join(rendered), fallback_count, bare_upgrade_count


def collect_outputs(catalog_files, translations, allow_untranslated):
    files = OrderedDict()
    used_refs = set()
    total_fallbacks = 0
    total_bare_upgrades = 0

    for raw_path, rows in catalog_files.items():
        rel_path = validate_output_path(raw_path)
        if not isinstance(rows, list) or not rows:
            fail(f"{rel_path}: catalog 文件条目必须是非空数组")
        file_state = files.setdefault(
            rel_path,
            {
                "path": rel_path,
                "sections": OrderedDict(),
                "seen_keys": set(),
                "row_count": 0,
                "fallback_count": 0,
                "bare_upgrade_count": 0,
            },
        )

        for index, row in enumerate(rows):
            row_label = f"{rel_path}[{index}]"
            if not isinstance(row, dict):
                fail(f"{row_label}: catalog 行必须是对象")
            section, key = validate_section_key(row_label, row)
            row_type = row.get("type")

            if row_type == "string":
                ref = row.get("entry")
                parse_entry_ref(ref, row_label)
                expected_printf = validate_printf_spec(row.get("printf", []), row_label)
                text, fallback = resolve_translation(
                    ref, expected_printf, translations, used_refs, allow_untranslated, row_label
                )
                value, upgraded = format_translation_value(text, row.get("style", "quoted"), row_label)
                if fallback:
                    file_state["fallback_count"] += 1
                    total_fallbacks += 1
                if upgraded:
                    file_state["bare_upgrade_count"] += 1
                    total_bare_upgrades += 1
                add_output_line(file_state, section, key, value, bool(row.get("allow_duplicate", False)))

            elif row_type == "tuple":
                items = row.get("items")
                if not isinstance(items, list) or not items:
                    fail(f"{row_label}: tuple 行缺少非空 items")
                values = []
                for item_index, item in enumerate(items):
                    item_label = f"{row_label}.items[{item_index}]"
                    if not isinstance(item, dict):
                        fail(f"{item_label}: tuple item 必须是对象")
                    ref = item.get("entry")
                    parse_entry_ref(ref, item_label)
                    expected_printf = validate_printf_spec(item.get("printf", []), item_label)
                    text, fallback = resolve_translation(
                        ref, expected_printf, translations, used_refs, allow_untranslated, item_label
                    )
                    values.append(text)
                    if fallback:
                        file_state["fallback_count"] += 1
                        total_fallbacks += 1
                add_output_line(file_state, section, key, quote_tuple(values), bool(row.get("allow_duplicate", False)))

            elif row_type == "literal":
                value = ensure_text(f"{row_label}: value", row.get("value"), allow_empty=True)
                add_output_line(file_state, section, key, value, bool(row.get("allow_duplicate", False)))

            elif row_type == "template":
                value, fallback_count, bare_upgrade_count = render_template_parts(
                    row.get("parts"), translations, used_refs, allow_untranslated, row_label
                )
                if fallback_count:
                    file_state["fallback_count"] += fallback_count
                    total_fallbacks += fallback_count
                if bare_upgrade_count:
                    file_state["bare_upgrade_count"] += bare_upgrade_count
                    total_bare_upgrades += bare_upgrade_count
                add_output_line(file_state, section, key, value, bool(row.get("allow_duplicate", False)))

            else:
                fail(f"{row_label}: 未支持的 catalog 行类型 {row_type!r}")

    unused_refs = sorted(set(translations) - used_refs)
    if unused_refs:
        fail(f"翻译 JSON 含 catalog 未引用条目: {', '.join(unused_refs[:20])}")

    outputs = []
    for rel_path, state in files.items():
        lines = []
        for section, values in state["sections"].items():
            if lines:
                lines.append("")
            lines.append(f"[{section}]")
            for key, value in values:
                lines.append(f"{key}={value}")
        text = "\r\n".join(lines) + "\r\n"
        try:
            data = text.encode("gbk")
        except UnicodeEncodeError as e:
            bad = e.object[e.start : e.end]
            fail(f"{rel_path}: 输出含 GBK 不可编码字符 {bad!r}")
        outputs.append(
            {
                "rel_path": rel_path,
                "type": "int",
                "text": text,
                "data": data,
                "entry_count": state["row_count"],
                "untranslated_fallbacks": state["fallback_count"],
                "bare_upgraded_to_quoted": state["bare_upgrade_count"],
            }
        )

    return outputs, total_fallbacks, total_bare_upgrades


def build_dir_has_content(output_root):
    return output_root.exists() and any(output_root.iterdir())


def prune_empty_dirs(output_root):
    if not output_root.exists():
        return
    dirs = [p for p in output_root.rglob("*") if p.is_dir()]
    for path in sorted(dirs, key=lambda p: len(p.parts), reverse=True):
        try:
            path.rmdir()
        except OSError:
            pass


def prepare_build_dir(output_root):
    if not output_root.exists():
        output_root.mkdir(parents=True)
        return
    manifest_path = output_root / "manifest.json"
    if not manifest_path.exists():
        if build_dir_has_content(output_root):
            fail(f"{repo_relative(output_root)} 已存在且没有 manifest.json，拒绝覆盖")
        return

    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"), object_pairs_hook=reject_duplicate_json_keys)
    except (json.JSONDecodeError, ValueError) as e:
        fail(f"{repo_relative(manifest_path)} 解析失败，拒绝清理: {e}")
    files = manifest.get("files")
    if not isinstance(files, list):
        fail(f"{repo_relative(manifest_path)} 缺少 files 列表，拒绝清理")
    for item in files:
        if not isinstance(item, dict) or "path" not in item:
            fail(f"{repo_relative(manifest_path)} 含非法文件记录，拒绝清理")
        path = safe_build_path(output_root, item["path"])
        if path.exists():
            if not path.is_file():
                fail(f"manifest 记录不是文件，拒绝删除: {repo_relative(path)}")
            path.unlink()
    manifest_path.unlink()
    prune_empty_dirs(output_root)


def write_outputs(outputs, json_path, catalog_path, output_root, allow_untranslated, total_fallbacks, total_bare_upgrades):
    manifest_files = []
    for output in outputs:
        out_path = safe_build_path(output_root, output["rel_path"])
        if out_path.exists():
            fail(f"输出文件已存在且不在旧 manifest 清理范围内: {repo_relative(out_path)}")
        out_path.parent.mkdir(parents=True, exist_ok=True)
        data = output["data"]
        out_path.write_bytes(data)
        manifest_files.append(
            {
                "path": output["rel_path"],
                "type": output["type"],
                "bytes": len(data),
                "sha256": sha256_bytes(data),
                "entries": output["entry_count"],
                "untranslated_fallbacks": output["untranslated_fallbacks"],
                "bare_upgraded_to_quoted": output["bare_upgraded_to_quoted"],
            }
        )

    json_bytes = json_path.read_bytes()
    catalog_bytes = catalog_path.read_bytes()
    manifest = {
        "tool": TOOL_NAME,
        "translation_schema": TRANSLATION_SCHEMA,
        "catalog_schema": CATALOG_SCHEMA,
        "built_at": datetime.now(timezone.utc).isoformat(),
        "flags": {
            "allow_untranslated": allow_untranslated,
        },
        "input": {
            "translation_json": {
                "path": repo_relative(json_path),
                "sha256": sha256_bytes(json_bytes),
            },
            "catalog": {
                "path": repo_relative(catalog_path),
                "sha256": sha256_bytes(catalog_bytes),
            },
        },
        "files": manifest_files,
        "untranslated_fallbacks": total_fallbacks,
        "bare_upgraded_to_quoted": total_bare_upgrades,
    }
    manifest_path = output_root / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return manifest


def parse_args(argv):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--json", default=DEFAULT_JSON, help=f"翻译 JSON 路径，默认 {DEFAULT_JSON}")
    ap.add_argument("--catalog", default=DEFAULT_CATALOG, help=f"机器 catalog 路径，默认 {DEFAULT_CATALOG}")
    ap.add_argument("--out", required=True, help="输出目录")
    ap.add_argument(
        "--allow-untranslated",
        action="store_true",
        help="允许空 zh_CN 回退英文 en；仅建议开发/抽样测试使用",
    )
    return ap.parse_args(argv)


def resolve_input_path(path_text):
    return Path(path_text).expanduser().resolve()


def resolve_output_path(path_text):
    return Path(path_text).expanduser().resolve()


def main(argv=None):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    json_path = resolve_input_path(args.json)
    catalog_path = resolve_input_path(args.catalog)
    output_root = resolve_output_path(args.out)

    _, translations = load_translation(json_path)
    _, catalog_files = load_catalog(catalog_path)
    outputs, total_fallbacks, total_bare_upgrades = collect_outputs(catalog_files, translations, args.allow_untranslated)
    if not outputs:
        fail("catalog 没有可生成的输出")
    prepare_build_dir(output_root)
    manifest = write_outputs(
        outputs,
        json_path,
        catalog_path,
        output_root,
        args.allow_untranslated,
        total_fallbacks,
        total_bare_upgrades,
    )
    print(f"已生成 {len(manifest['files'])} 个文件到 {repo_relative(output_root)}")
    for item in manifest["files"]:
        fallback = item.get("untranslated_fallbacks", 0)
        bare_upgrades = item.get("bare_upgraded_to_quoted", 0)
        suffix = f", {fallback} 条回退英文" if fallback else ""
        if bare_upgrades:
            suffix += f", {bare_upgrades} 条 bare 自动加引号"
        print(f"  {item['path']} ({item['entries']} 行, {item['bytes']} 字节{suffix})")


if __name__ == "__main__":
    try:
        main()
    except BuildError as e:
        print(f"错误: {e}", file=sys.stderr)
        sys.exit(1)
