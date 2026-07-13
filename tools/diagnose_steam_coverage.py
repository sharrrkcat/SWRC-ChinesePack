#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Compare a SWRC language catalog/build with an original Steam installation.

The package-level pass consumes ``.uc`` files produced by UCC ``batchexport``.
It deliberately separates explicit/declared localized fields from heuristic
display-text candidates so that likely development-only strings do not look
like proven runtime omissions.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, OrderedDict, defaultdict
from datetime import datetime, timezone
from pathlib import Path

import make_translation_json as mtj


IGNORE_FILE_RE = re.compile(
    r"^(?:geo_|ras_|yyy_|subtitles_(?:geo|ras|yyy)_)", re.IGNORECASE
)
STRING_NAMES_RE = re.compile(r"\bstring\b\s+([^;]+);", re.IGNORECASE | re.DOTALL)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def ignored_stem(stem: str) -> bool:
    return bool(IGNORE_FILE_RE.match(stem))


def row_id(section: str, key: str) -> tuple[str, str]:
    return section.casefold(), key.casefold()


def rows_counter(rows) -> Counter:
    return Counter(row_id(r.section, r.key) for r in rows)


def catalog_counter(rows: list[dict]) -> Counter:
    return Counter(row_id(r.get("section", ""), r.get("key", "")) for r in rows)


def missing_rows(expected_rows, actual: Counter) -> list[dict]:
    remaining = Counter(actual)
    missing = []
    for row in expected_rows:
        ident = row_id(row.section, row.key)
        if remaining[ident]:
            remaining[ident] -= 1
            continue
        missing.append(
            OrderedDict(
                line=row.line_no,
                section=row.section,
                key=row.key,
                original_value=row.value,
            )
        )
    return missing


def load_build(build_system: Path) -> dict[str, dict]:
    result = {}
    for path in sorted(build_system.glob("*.cht"), key=lambda p: p.name.casefold()):
        rows, pseudo, malformed = mtj.parse_int_file(path, "gbk")
        result[path.stem.casefold()] = {
            "path": path,
            "rows": rows,
            "counter": rows_counter(rows),
            "pseudo": pseudo,
            "malformed": malformed,
        }
    return result


def catalog_by_stem(catalog: dict) -> dict[str, dict]:
    result = {}
    for output_path, rows in catalog["files"].items():
        stem = Path(output_path).stem.casefold()
        result[stem] = {"path": output_path, "rows": rows, "counter": catalog_counter(rows)}
    return result


def explicit_int_pass(original_system: Path, catalog_index: dict, build_index: dict) -> dict:
    result = OrderedDict()
    totals = Counter()
    for path in sorted(original_system.glob("*.int"), key=lambda p: p.name.casefold()):
        if ignored_stem(path.stem):
            totals["ignored_files"] += 1
            continue
        rows, pseudo, malformed = mtj.parse_int_file(path, "cp1252")
        cat = catalog_index.get(path.stem.casefold())
        built = build_index.get(path.stem.casefold())
        cat_missing = missing_rows(rows, cat["counter"] if cat else Counter())
        build_missing = missing_rows(rows, built["counter"] if built else Counter())
        result[path.name] = OrderedDict(
            original_rows=len(rows),
            catalog_file=cat["path"] if cat else None,
            build_file=str(built["path"]) if built else None,
            missing_from_catalog=cat_missing,
            missing_from_build=build_missing,
            pseudo_comment_rows=pseudo,
            malformed_rows=malformed,
        )
        totals["checked_files"] += 1
        totals["original_rows"] += len(rows)
        totals["missing_catalog_rows"] += len(cat_missing)
        totals["missing_build_rows"] += len(build_missing)
        totals["missing_catalog_files"] += int(cat is None)
        totals["missing_build_files"] += int(built is None)
    return OrderedDict(totals=OrderedDict(sorted(totals.items())), by_file=result)


def catalog_build_pass(catalog_index: dict, build_index: dict) -> dict:
    missing_files = []
    missing_rows_by_file = OrderedDict()
    extra_build_files = []
    for stem, cat in sorted(catalog_index.items()):
        if ignored_stem(stem):
            continue
        built = build_index.get(stem)
        if built is None:
            missing_files.append(cat["path"])
            continue
        gaps = cat["counter"] - built["counter"]
        if gaps:
            missing_rows_by_file[cat["path"]] = [
                {"section": section, "key": key, "missing_occurrences": count}
                for (section, key), count in sorted(gaps.items())
            ]
    for stem, built in sorted(build_index.items()):
        if not ignored_stem(stem) and stem not in catalog_index:
            extra_build_files.append(str(built["path"]))
    return OrderedDict(
        missing_build_files=missing_files,
        catalog_rows_missing_from_build=missing_rows_by_file,
        extra_build_files=extra_build_files,
    )


def parse_localized_roots(path: Path) -> set[str]:
    text = path.read_text(encoding="cp1252", errors="replace")
    text = text.split("defaultproperties", 1)[0]
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    text = re.sub(r"//.*?$", "", text, flags=re.MULTILINE)
    roots = set()
    top_level = []
    depth = 0
    pending = ""
    for line in text.splitlines():
        stripped = line.strip()
        if depth == 0 and (pending or re.match(r"^var\b", stripped, re.IGNORECASE)):
            pending = f"{pending} {stripped}".strip()
            if ";" in pending:
                top_level.append(pending.split(";", 1)[0] + ";")
                pending = ""
        depth += line.count("{") - line.count("}")
    for statement in top_level:
        if not re.search(r"\blocalized\b", statement, re.IGNORECASE):
            continue
        names_match = STRING_NAMES_RE.search(statement)
        if names_match is None:
            continue
        for raw_name in names_match.group(1).split(","):
            name = raw_name.strip().split("=")[0].strip()
            name = re.sub(r"\s*\[[^]]*\]\s*$", "", name)
            if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
                roots.add(name.casefold())
    return roots


def default_root(key: str) -> str:
    root = key.split(".", 1)[0]
    return re.sub(r"\[\d+\]", "", root).casefold()


def package_pass(exports_root: Path, catalog_index: dict, build_index: dict) -> dict:
    classes = {}
    package_classes = defaultdict(list)
    for package_dir in sorted((p for p in exports_root.iterdir() if p.is_dir()), key=lambda p: p.name.casefold()):
        for uc_path in sorted(package_dir.glob("*.uc"), key=lambda p: p.name.casefold()):
            class_name, parent, defaults = mtj.parse_uc_file(uc_path)
            info = {
                "package": package_dir.name,
                "name": class_name,
                "parent": parent,
                "defaults": defaults,
                "localized_roots": parse_localized_roots(uc_path),
                "path": uc_path,
            }
            classes[class_name.casefold()] = info
            package_classes[package_dir.name.casefold()].append(info)

    def inherited_roots(info, seen=None):
        seen = set() if seen is None else seen
        key = info["name"].casefold()
        if key in seen:
            return set(info["localized_roots"])
        seen.add(key)
        result = set(info["localized_roots"])
        parent = classes.get((info.get("parent") or "").casefold())
        if parent:
            result.update(inherited_roots(parent, seen))
        return result

    definite = []
    probable = []
    all_catalog_rows = Counter()
    all_build_rows = Counter()
    for item in catalog_index.values():
        all_catalog_rows.update(item["counter"])
    for item in build_index.values():
        all_build_rows.update(item["counter"])
    excluded_nonretail = 0
    examined_defaults = 0
    for package, infos in sorted(package_classes.items()):
        for info in infos:
            section = info["name"][:-8] if info["name"].endswith("Defaults") else info["name"]
            target_package = package
            if info["name"].endswith("Defaults"):
                # Property override containers can localize either through the
                # Properties output or the concrete class package.  Treat an
                # exact section/key in either output as coverage.
                target_package = "<property-default-resolution>"
                cat_count = all_catalog_rows
                build_count = all_build_rows
            else:
                cat = catalog_index.get(target_package)
                built = build_index.get(target_package)
                cat_count = cat["counter"] if cat else Counter()
                build_count = built["counter"] if built else Counter()
            if section.startswith(mtj.NON_RETAIL_CLASS_PREFIXES):
                excluded_nonretail += 1
                continue
            localized_roots = inherited_roots(info)
            for key, source in sorted(info["defaults"].items()):
                examined_defaults += 1
                is_text = source.kind == "string" and bool(source.text)
                is_tuple = source.kind == "tuple" and key.casefold().endswith(".items")
                if not (is_text or is_tuple):
                    continue
                declared = default_root(key) in localized_roots
                heuristic = mtj._is_localizable_default_key(key) or is_tuple
                if not (declared or heuristic):
                    continue
                ident = row_id(section, key)
                item = OrderedDict(
                    package=info["package"],
                    target_package=target_package,
                    section=section,
                    key=key,
                    original_value=source.raw,
                    source=str(info["path"]),
                    declared_localized=declared,
                    missing_from_catalog=cat_count[ident] == 0,
                    missing_from_build=build_count[ident] == 0,
                )
                if item["missing_from_catalog"] or item["missing_from_build"]:
                    (definite if declared else probable).append(item)

    def summarize(items):
        by_package = Counter(item["package"] for item in items)
        return OrderedDict(
            total=len(items),
            missing_catalog=sum(item["missing_from_catalog"] for item in items),
            missing_build=sum(item["missing_from_build"] for item in items),
            by_package=OrderedDict(sorted(by_package.items(), key=lambda x: (-x[1], x[0].casefold()))),
            entries=items,
        )

    return OrderedDict(
        exported_packages=len(package_classes),
        exported_classes=len(classes),
        examined_default_leaves=examined_defaults,
        excluded_nonretail_classes=excluded_nonretail,
        definite_declared_localized_gaps=summarize(definite),
        probable_display_text_gaps=summarize(probable),
    )


def write_markdown(report: dict, path: Path) -> None:
    explicit = report["explicit_int_coverage"]
    package = report["package_default_coverage"]
    definite = package["definite_declared_localized_gaps"]
    probable = package["probable_display_text_gaps"]
    lines = [
        "# Steam 原版本地化覆盖诊断",
        "",
        f"> 生成时间：{report['generated_at']}",
        "",
        "## 摘要",
        "",
        f"- 非地图原版 `.int`：{explicit['totals'].get('checked_files', 0)} 个文件，"
        f"{explicit['totals'].get('original_rows', 0)} 行；catalog 缺 "
        f"{explicit['totals'].get('missing_catalog_rows', 0)} 行，build 缺 "
        f"{explicit['totals'].get('missing_build_rows', 0)} 行。",
        f"- 原包脚本：导出 {package['exported_packages']} 个包、{package['exported_classes']} 个类。",
        f"- 明确声明为 localized 的缺口候选：{definite['total']} 项。",
        f"- 按字段名识别的显示文本缺口候选：{probable['total']} 项（需人工排除开发/未使用路径）。",
        "",
        "## 原版 .int 缺口",
        "",
    ]
    any_explicit = False
    for name, info in explicit["by_file"].items():
        if not info["missing_from_catalog"] and not info["missing_from_build"]:
            continue
        any_explicit = True
        lines.append(f"### {name}")
        lines.append("")
        for item in info["missing_from_catalog"]:
            lines.append(f"- catalog 缺：`[{item['section']}] {item['key']}`（原文件第 {item['line']} 行）")
        for item in info["missing_from_build"]:
            if item not in info["missing_from_catalog"]:
                lines.append(f"- build 缺：`[{item['section']}] {item['key']}`（原文件第 {item['line']} 行）")
        lines.append("")
    if not any_explicit:
        lines.extend(["未发现。", ""])

    for title, bucket in (
        ("明确 localized 缺口候选", definite),
        ("启发式显示文本缺口候选", probable),
    ):
        lines.extend([f"## {title}", ""])
        if not bucket["entries"]:
            lines.extend(["未发现。", ""])
            continue
        for item in bucket["entries"]:
            targets = []
            if item["missing_from_catalog"]:
                targets.append("catalog")
            if item["missing_from_build"]:
                targets.append("build")
            lines.append(
                f"- `{item['package']}.u [{item['section']}] {item['key']}` — 缺于 {', '.join(targets)}；"
                f"原值 `{item['original_value']}`"
            )
        lines.append("")

    lines.extend([
        "## 范围与限制",
        "",
        "- 已按要求忽略 `GEO_/RAS_/YYY_*` 与 `subtitles_geo/ras/yyy_*` 文件。",
        "- `.int` 缺口是确定的键覆盖差异；包内启发式候选不等同于运行时必达字段。",
        "- 无脚本类或 UCC 无法导出的纯数据包不能通过本方法证明完整性。",
        "",
    ])
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--original", type=Path, required=True)
    parser.add_argument("--exports", type=Path, required=True)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--out-json", type=Path, required=True)
    parser.add_argument("--out-md", type=Path, required=True)
    args = parser.parse_args()

    catalog = json.loads(args.catalog.read_text(encoding="utf-8-sig"))
    cat_index = catalog_by_stem(catalog)
    build_index = load_build(args.build / "GameData" / "System")
    report = OrderedDict(
        generated_at=utc_now(),
        inputs=OrderedDict(
            original=str(args.original), exports=str(args.exports), catalog=str(args.catalog), build=str(args.build)
        ),
        ignored_patterns=["GEO_*", "RAS_*", "YYY_*", "subtitles_geo_*", "subtitles_ras_*", "subtitles_yyy_*"],
        explicit_int_coverage=explicit_int_pass(args.original / "GameData" / "System", cat_index, build_index),
        catalog_build_consistency=catalog_build_pass(cat_index, build_index),
        package_default_coverage=package_pass(args.exports, cat_index, build_index),
    )
    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    write_markdown(report, args.out_md)
    print(f"wrote {args.out_json}")
    print(f"wrote {args.out_md}")


if __name__ == "__main__":
    main()
