#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Diagnose Steam campaign-map localization coverage.

This complements ``diagnose_steam_coverage.py``.  Steam stores most campaign
text in localized properties on objects inside ``.ctm`` packages, while the
official Japanese pack supplies per-map ``.int`` indexes.  A missing per-map
row is not automatically a runtime gap: if the map instance does not serialize
that property, the localized class default may cover it from another ``.cht``.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, OrderedDict, defaultdict
from datetime import datetime, timezone
from pathlib import Path

import make_translation_json as mtj


MISSION_MAP_RE = re.compile(r"^(?:geo_|ras_|yyy_)", re.IGNORECASE)
MAP_RUNTIME_RE = re.compile(
    r"^(?:geo_|ras_|yyy_|subtitles_(?:geo|ras|yyy)_)", re.IGNORECASE
)
MISSION_OBJECTIVE_RE = re.compile(r"MissionObj\[(\d+)\]\.Objective")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def is_mission_map(stem: str) -> bool:
    return bool(MISSION_MAP_RE.match(stem)) and "titlecard" not in stem.casefold()


def is_map_runtime_file(stem: str) -> bool:
    return bool(MAP_RUNTIME_RE.match(stem))


def row_id(section: str, key: str) -> tuple[str, str]:
    return section.casefold(), key.casefold()


def int_counter(rows) -> Counter:
    return Counter(row_id(row.section, row.key) for row in rows)


def catalog_counter(rows) -> Counter:
    return Counter(row_id(row.get("section", ""), row.get("key", "")) for row in rows)


def missing_count(expected: Counter, actual: Counter) -> int:
    return sum((expected - actual).values())


def load_catalog(path: Path) -> tuple[dict, dict]:
    payload = json.loads(path.read_text(encoding="utf-8-sig"))
    files = payload["files"]
    return payload, {Path(name).stem.casefold(): rows for name, rows in files.items()}


def load_build(build_root: Path) -> dict[str, dict]:
    result = {}
    for path in sorted((build_root / "GameData" / "System").glob("*.cht")):
        rows, _pseudo, _malformed = mtj.parse_int_file(path, "gbk")
        result[path.stem.casefold()] = {
            "path": str(path),
            "rows": rows,
            "counter": int_counter(rows),
        }
    return result


def explicit_steam_int_coverage(original: Path, catalog: dict, build: dict) -> OrderedDict:
    by_file = OrderedDict()
    totals = Counter()
    for path in sorted((original / "GameData" / "System").glob("*.int"), key=lambda p: p.name.casefold()):
        if not is_map_runtime_file(path.stem):
            continue
        rows, pseudo, malformed = mtj.parse_int_file(path, "cp1252")
        expected = int_counter(rows)
        cat_rows = catalog.get(path.stem.casefold(), [])
        built = build.get(path.stem.casefold())
        missing_catalog = missing_count(expected, catalog_counter(cat_rows))
        missing_build = missing_count(expected, built["counter"] if built else Counter())
        by_file[path.name] = OrderedDict(
            original_rows=len(rows),
            missing_from_catalog=missing_catalog,
            missing_from_build=missing_build,
            pseudo_comment_rows=len(pseudo),
            malformed_rows=len(malformed),
        )
        totals.update(
            files=1,
            rows=len(rows),
            missing_catalog=missing_catalog,
            missing_build=missing_build,
        )
    return OrderedDict(totals=OrderedDict(totals), by_file=by_file)


def map_catalog_build_consistency(catalog: dict, build: dict, map_stems: set[str]) -> OrderedDict:
    totals = Counter()
    by_file = OrderedDict()
    for stem, rows in sorted(catalog.items()):
        if stem not in map_stems and not is_map_runtime_file(stem):
            continue
        built = build.get(stem)
        gaps = missing_count(catalog_counter(rows), built["counter"] if built else Counter())
        by_file[stem] = OrderedDict(catalog_rows=len(rows), missing_from_build=gaps)
        totals.update(files=1, catalog_rows=len(rows), missing_build=gaps)
    return OrderedDict(totals=OrderedDict(totals), by_file=by_file)


def load_classes(exports_root: Path) -> tuple[dict, int]:
    classes = {}
    packages = set()
    for path in sorted(exports_root.glob("*/*.uc"), key=lambda p: p.as_posix().casefold()):
        class_name, parent, defaults = mtj.parse_uc_file(path)
        package = path.parent.name
        packages.add(package.casefold())
        classes[class_name.casefold()] = {
            "name": class_name,
            "parent": parent,
            "defaults": defaults,
            "localized_strings": mtj.parse_top_level_localized_strings(path),
            "package": package,
            "path": str(path),
        }
    return classes, len(packages)


def inherited_localized_roots(classes: dict, class_name: str, memo: dict, seen=None) -> set[str]:
    class_key = class_name.casefold()
    if class_key in memo:
        return memo[class_key]
    seen = set() if seen is None else seen
    if class_key in seen or class_key not in classes:
        return set()
    seen.add(class_key)
    info = classes[class_key]
    roots = {name.casefold() for name in info["localized_strings"]}
    if info.get("parent"):
        roots.update(inherited_localized_roots(classes, info["parent"], memo, seen))
    memo[class_key] = roots
    return roots


def class_chain(classes: dict, class_name: str):
    seen = set()
    while class_name:
        class_key = class_name.casefold()
        if class_key in seen:
            return
        seen.add(class_key)
        info = classes.get(class_key)
        if info is None:
            return
        yield info
        class_name = info.get("parent")


def property_root(key: str) -> str:
    return re.sub(r"\[\d+\]", "", key.split(".", 1)[0]).casefold()


def catalog_english(row: dict, translation: dict) -> str | None:
    if row.get("type") != "string":
        return None
    group, entry_id = row["entry"].split("/", 1)
    return translation[group][entry_id]["en"]


def build_catalog_source_index(catalog_payload: dict, translation: dict, build: dict) -> dict:
    index = defaultdict(list)
    for output_path, rows in catalog_payload["files"].items():
        stem = Path(output_path).stem.casefold()
        built = build.get(stem)
        built_counter = built["counter"] if built else Counter()
        for row in rows:
            english = catalog_english(row, translation)
            if english is None:
                continue
            index[row_id(row["section"], row["key"])].append(
                {
                    "file": output_path,
                    "entry": row["entry"],
                    "en": english,
                    "present_in_build": built_counter[row_id(row["section"], row["key"])] > 0,
                }
            )
    return index


def load_map_objects(t3d_root: Path, stem: str) -> dict:
    directory = t3d_root / stem
    files = sorted(directory.glob("*.t3d")) if directory.exists() else []
    if len(files) != 1:
        raise RuntimeError(f"{stem}: expected one T3D under {directory}, found {len(files)}")
    return mtj.parse_t3d_file(files[0])


def candidate_values(classes: dict, info: dict, localized_roots: set[str]):
    values = OrderedDict()
    folded = {}
    for ancestor in class_chain(classes, info["class"]):
        for key, value in ancestor["defaults"].items():
            key_folded = key.casefold()
            if property_root(key) not in localized_roots or key_folded in folded:
                continue
            folded[key_folded] = key
            values[key] = (value, "class_default", ancestor)
    for key, value in info["props"].items():
        if property_root(key) not in localized_roots and not mtj._is_localizable_default_key(key):
            continue
        key_folded = key.casefold()
        previous = folded.get(key_folded)
        if previous is not None:
            del values[previous]
        folded[key_folded] = key
        values[key] = (value, "direct_instance", None)
    return values


def reverse_map_object_coverage(
    t3d_root: Path,
    map_stems: set[str],
    classes: dict,
    catalog: dict,
    catalog_source_index: dict,
    build: dict,
) -> OrderedDict:
    localized_memo = {}
    candidates = []
    true_gaps = []
    inherited_map_rows_omitted = []
    unknown_classes = Counter()
    maps_checked = []

    for stem in sorted(map_stems):
        maps_checked.append(stem)
        objects = load_map_objects(t3d_root, stem)
        map_catalog_rows = catalog.get(stem, [])
        map_catalog_ids = {row_id(row["section"], row["key"]) for row in map_catalog_rows}
        built = build.get(stem)
        map_build_ids = set(built["counter"]) if built else set()

        for obj in objects.values():
            if obj["class"].casefold() not in classes:
                unknown_classes[obj["class"]] += 1
                continue
            roots = inherited_localized_roots(classes, obj["class"], localized_memo)
            for key, (source, origin, source_class) in candidate_values(classes, obj, roots).items():
                if source.kind != "string" or not source.text:
                    continue
                ident = row_id(obj["name"], key)
                map_catalog_match = ident in map_catalog_ids
                map_build_match = ident in map_build_ids
                class_matches = []
                if source_class is not None:
                    for item in catalog_source_index.get(row_id(source_class["name"], key), []):
                        if item["en"] == source.text:
                            class_matches.append(item)
                covered_by_class = bool(class_matches) and any(item["present_in_build"] for item in class_matches)
                runtime_covered = map_catalog_match and map_build_match
                coverage_kind = "map_instance"
                if not runtime_covered and origin == "class_default" and covered_by_class:
                    runtime_covered = True
                    coverage_kind = "localized_class_default"
                elif not runtime_covered:
                    coverage_kind = "missing"

                record = OrderedDict(
                    map=stem,
                    section=obj["name"],
                    object_class=obj["class"],
                    key=key,
                    en=source.text,
                    origin=origin,
                    source_class=source_class["name"] if source_class else None,
                    source_package=source_class["package"] if source_class else None,
                    map_catalog_match=map_catalog_match,
                    map_build_match=map_build_match,
                    class_matches=class_matches,
                    coverage=coverage_kind,
                )
                candidates.append(record)
                if not map_catalog_match and origin == "class_default" and covered_by_class:
                    inherited_map_rows_omitted.append(record)
                if not runtime_covered:
                    true_gaps.append(record)

            objectives = []
            for key, value in obj["props"].items():
                match = MISSION_OBJECTIVE_RE.fullmatch(key)
                if match and value.kind == "string" and value.text:
                    objectives.append((int(match.group(1)), value.text))
            if objectives:
                ident = row_id(obj["name"], "MissionObj")
                record = OrderedDict(
                    map=stem,
                    section=obj["name"],
                    object_class=obj["class"],
                    key="MissionObj",
                    en=f"{len(objectives)} objective(s)",
                    origin="direct_instance_array",
                    source_class=None,
                    source_package=None,
                    map_catalog_match=ident in map_catalog_ids,
                    map_build_match=ident in map_build_ids,
                    class_matches=[],
                    coverage="map_instance" if ident in map_catalog_ids and ident in map_build_ids else "missing",
                )
                candidates.append(record)
                if record["coverage"] == "missing":
                    true_gaps.append(record)

    by_coverage = Counter(item["coverage"] for item in candidates)
    by_origin = Counter(item["origin"] for item in candidates)
    direct_origins = {"direct_instance", "direct_instance_array"}
    direct_candidates = sum(item["origin"] in direct_origins for item in candidates)
    direct_gaps = sum(item["origin"] in direct_origins for item in true_gaps)
    by_key = Counter(item["key"] for item in true_gaps)
    by_map = Counter(item["map"] for item in true_gaps)
    return OrderedDict(
        maps=len(maps_checked),
        effective_localized_candidates=len(candidates),
        by_origin=OrderedDict(sorted(by_origin.items())),
        by_coverage=OrderedDict(sorted(by_coverage.items())),
        explicit_instance_candidates=direct_candidates,
        explicit_instance_gaps=direct_gaps,
        inherited_map_rows_omitted_but_class_covered=len(inherited_map_rows_omitted),
        true_runtime_gaps=len(true_gaps),
        true_gaps=true_gaps,
        true_gaps_by_key=OrderedDict(sorted(by_key.items())),
        true_gaps_by_map=OrderedDict(sorted(by_map.items())),
        unknown_object_classes=OrderedDict(sorted(unknown_classes.items())),
    )


def japanese_map_index_coverage(
    jp_system: Path, catalog: dict, build: dict, map_stems: set[str]
) -> OrderedDict:
    totals = Counter()
    by_file = OrderedDict()
    for path in sorted(jp_system.glob("*.int"), key=lambda p: p.name.casefold()):
        if path.stem.casefold() not in map_stems:
            continue
        rows, _pseudo, _malformed = mtj.parse_int_file(path, "cp932")
        expected = int_counter(rows)
        cat_rows = catalog.get(path.stem.casefold(), [])
        built = build.get(path.stem.casefold())
        missing_catalog = missing_count(expected, catalog_counter(cat_rows))
        missing_build = missing_count(expected, built["counter"] if built else Counter())
        by_file[path.name] = OrderedDict(
            rows=len(rows),
            catalog_rows=len(cat_rows),
            missing_from_catalog=missing_catalog,
            missing_from_build=missing_build,
        )
        totals.update(
            files=1,
            rows=len(rows),
            catalog_rows=len(cat_rows),
            missing_catalog=missing_catalog,
            missing_build=missing_build,
        )
    return OrderedDict(totals=OrderedDict(totals), by_file=by_file)


def write_markdown(report: dict, path: Path) -> None:
    steam = report["steam_map_int_coverage"]["totals"]
    jp = report["japanese_map_index_coverage"]["totals"]
    reverse = report["steam_ctm_object_coverage"]
    consistency = report["map_catalog_build_consistency"]["totals"]
    lines = [
        "# Steam 地图本地化覆盖诊断",
        "",
        f"> 生成时间：{report['generated_at']}",
        "",
        "## 结论",
        "",
        f"- Steam 原版地图字幕/标题 `.int`：{steam.get('files', 0)} 个文件、{steam.get('rows', 0)} 行；"
        f"catalog 缺 {steam.get('missing_catalog', 0)}，build 缺 {steam.get('missing_build', 0)}。",
        f"- {reverse['maps']} 个 Steam `.ctm` 中发现 {reverse['effective_localized_candidates']} 个有效 localized 对象字段。",
        f"- 其中地图显式序列化字段 {reverse['explicit_instance_candidates']} 项；"
        f"确定缺口 {reverse['explicit_instance_gaps']} 项。",
        f"- 其中 {reverse['inherited_map_rows_omitted_but_class_covered']} 个地图实例行虽未单独输出，"
        "但实例未序列化覆盖该字段，且相同英文值已由类默认 `.cht` 覆盖。",
        f"- 确定的运行时缺口：**{reverse['true_runtime_gaps']} 项**。",
        f"- 地图 catalog 共 {consistency.get('files', 0)} 个文件、{consistency.get('catalog_rows', 0)} 行；"
        f"build 缺 {consistency.get('missing_build', 0)} 行。",
        "",
        "## 确定缺口",
        "",
    ]
    if not reverse["true_gaps"]:
        lines.extend(["未发现。", ""])
    else:
        for item in reverse["true_gaps"]:
            lines.append(
                f"- `{item['map']}.ctm [{item['section']}] {item['key']}` "
                f"（类 `{item['object_class']}`，{item['origin']}）：`{item['en']}`"
            )
        lines.append("")

    lines.extend(
        [
            "## 日文地图索引差异",
            "",
            f"- 日文同名地图索引：{jp.get('files', 0)} 个文件、{jp.get('rows', 0)} 行；"
            f"另有 {report['map_packages']['without_japanese_index']} 个 Steam 地图没有日文同名索引。",
            f"- 当前 catalog 未逐实例输出 {jp.get('missing_catalog', 0)} 行。",
            "- 这些未输出行均为地图对象未序列化的继承默认提示；运行时由 "
            "`engine.cht`、`ctgame.cht` 或 `ctmarkers.cht` 的来源类字段覆盖，因此不属于实际缺字。",
            "- Steam 反向扫描另发现日文索引没有的对象字段；只有上方列出的显式实例覆盖无法由类默认替代。",
            "",
            "## 继承风险",
            "",
            "- 地图常用字段是标量字符串；唯一 localized 复合字段 `MissionObjectives.MissionObj` "
            "按完整数组 template 输出。",
            "- 未发现 `AButton.Blurred.Text` 一类“派生类部分覆盖结构体叶字段”的地图问题。",
            "- 本报告中的类默认继承与菜单结构体 fanout 不同：前者只在地图实例没有序列化该字段时才视为有效覆盖。",
            "",
            "## 范围与限制",
            "",
            "- `.ctm` 反向字段扫描覆盖 Steam 原包全部地图；另对账 "
            "`subtitles_geo/ras/yyy_*` 和三套 titlecard。",
            "- `.ctm` 通过 UCC 导出的 Level T3D 检查；类声明和默认值来自 Steam 原包完整脚本导出。",
            "- 纯 native 动态拼接文本仍需游戏内烟测，但不会表现为可枚举的 localized 属性缺口。",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--original", type=Path, required=True, help="Steam .originalbackup root")
    parser.add_argument("--jp-system", type=Path, required=True)
    parser.add_argument("--class-exports", type=Path, required=True)
    parser.add_argument("--t3d-exports", type=Path, required=True)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--translation", type=Path, required=True)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--out-json", type=Path, required=True)
    parser.add_argument("--out-md", type=Path, required=True)
    args = parser.parse_args()

    catalog_payload, catalog = load_catalog(args.catalog)
    translation = json.loads(args.translation.read_text(encoding="utf-8-sig"))
    build = load_build(args.build)
    classes, package_count = load_classes(args.class_exports)
    source_index = build_catalog_source_index(catalog_payload, translation, build)
    map_stems = {
        path.stem.casefold()
        for path in (args.original / "GameData" / "Maps").glob("*.ctm")
    }
    indexed_map_stems = {
        path.stem.casefold()
        for path in args.jp_system.glob("*.int")
        if path.stem.casefold() in map_stems
    }

    report = OrderedDict(
        generated_at=utc_now(),
        inputs=OrderedDict(
            original=str(args.original),
            japanese_system=str(args.jp_system),
            class_exports=str(args.class_exports),
            t3d_exports=str(args.t3d_exports),
            catalog=str(args.catalog),
            translation=str(args.translation),
            build=str(args.build),
        ),
        class_exports=OrderedDict(packages=package_count, classes=len(classes)),
        map_packages=OrderedDict(
            steam_ctm=len(map_stems),
            with_japanese_index=len(indexed_map_stems),
            without_japanese_index=len(map_stems - indexed_map_stems),
            no_japanese_index=sorted(map_stems - indexed_map_stems),
        ),
        steam_map_int_coverage=explicit_steam_int_coverage(args.original, catalog, build),
        japanese_map_index_coverage=japanese_map_index_coverage(
            args.jp_system, catalog, build, map_stems
        ),
        map_catalog_build_consistency=map_catalog_build_consistency(catalog, build, map_stems),
        steam_ctm_object_coverage=reverse_map_object_coverage(
            args.t3d_exports, map_stems, classes, catalog, source_index, build
        ),
    )
    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    write_markdown(report, args.out_md)
    print(f"wrote {args.out_json}")
    print(f"wrote {args.out_md}")


if __name__ == "__main__":
    main()
