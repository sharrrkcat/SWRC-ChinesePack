#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from collections import Counter, OrderedDict
from pathlib import Path

import numpy as np
from PIL import Image


ROOT_DIR = Path(__file__).resolve().parent.parent
TOOLS_DIR = ROOT_DIR / "tools"


def load_tool(name):
    path = TOOLS_DIR / f"{name}.py"
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


mtj = load_tool("make_translation_json")
blp = load_tool("build_langpack")
fg = load_tool("font_gen")
swrc = load_tool("swrc_package")


def parse_int_semantics(path, encoding):
    rows = []
    section = None
    for raw_line in path.read_text(encoding=encoding).splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if section is None or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if key.startswith("//"):
            continue
        rows.append((section, key, canonical_value(value.strip())))
    return rows


def canonical_value(value):
    tuple_items = mtj.parse_quoted_tuple(value)
    if tuple_items is not None:
        return tuple(mtj.normalize_fallback_text(item) for item in tuple_items)
    if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
        return mtj.normalize_fallback_text(mtj.unquote_unreal(value))
    return mtj.normalize_fallback_text(value)


class LocalizationToolTests(unittest.TestCase):
    def font_fixture_paths(self):
        font_path = ROOT_DIR.parent / "fonts" / "SourceHanSansCN-Bold.otf"
        latin_source = ROOT_DIR.parent.parent / ".originalbackup" / "GameData" / "Textures" / "orbitfonts.utx"
        if not font_path.exists() or not latin_source.exists():
            self.skipTest("font generation fixtures are missing")
        return font_path, latin_source

    def build_test_font(self, temp_root, chars, latin_source=None):
        font_path, _default_latin_source = self.font_fixture_paths()
        out_path = temp_root / "orbitfonts-test.utx"
        fg.build_package(str(font_path), chars, str(out_path), str(latin_source) if latin_source else None)
        return swrc.Package(str(out_path))

    def decoded_page_alpha(self, pkg, page_name):
        _props, mips = pkg.decode_texture(page_name)
        mip = mips[0]
        return np.array(Image.frombytes("RGBA", (mip["usize"], mip["vsize"]), mip["data"], "bcn", 3), np.uint8)[:, :, 3]

    def glyph_alpha_bbox(self, pkg, font, glyph):
        u, v, w, h, tp = glyph
        alpha = self.decoded_page_alpha(pkg, font["pages"][tp])
        rect = alpha[v:v + h, u:u + w]
        ys, xs = np.where(rect > 8)
        if len(ys) == 0:
            return None
        return (int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1))

    def test_font_gen_default_keeps_ttf_ascii_metrics(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            pkg = self.build_test_font(Path(temp_dir), " S,中")
            font = pkg.decode_font("OrbitBold15")
            self.assertEqual(font["characters"][font["remap"][ord("S")]][3], fg.CELL_HEIGHTS[15])
            self.assertEqual(font["characters"][font["remap"][0xD6D0]][3], fg.CELL_HEIGHTS[15])

    def test_font_gen_latin_source_reuses_ascii_metrics_and_aligns_cjk_to_latin_line_height(self):
        _font_path, latin_source = self.font_fixture_paths()
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            mixed_pkg = self.build_test_font(temp_root, " S,g中", latin_source)
            source_pkg = swrc.Package(str(latin_source))
            mixed_font = mixed_pkg.decode_font("OrbitBold15")
            source_font = source_pkg.decode_font("OrbitBold15")

            for ch in "S,g":
                mixed_glyph = mixed_font["characters"][mixed_font["remap"][ord(ch)]]
                source_glyph = source_font["characters"][ord(ch)]
                self.assertEqual(mixed_glyph[2:4], source_glyph[2:4])

            latin_line_h = max(source_font["characters"][cp][3] for cp in fg.LATIN_RANGE)
            cjk_key = int.from_bytes("中".encode("gbk"), "big")
            cjk_glyph = mixed_font["characters"][mixed_font["remap"][cjk_key]]
            self.assertEqual(cjk_glyph[3], latin_line_h)
            self.assertEqual(mixed_font["is_remapped"], 1)
            self.assertIn(cjk_key, mixed_font["remap"])
            self.assertGreater(self.glyph_alpha_bbox(mixed_pkg, mixed_font, cjk_glyph)[1], 0)

            s_glyph = mixed_font["characters"][mixed_font["remap"][ord("S")]]
            alpha = self.decoded_page_alpha(mixed_pkg, mixed_font["pages"][s_glyph[4]])
            u, v, w, _h, _tp = s_glyph
            self.assertFalse((alpha[v:v + 3, u:u + w] > 8).any())

    def test_unreal_string_parser_preserves_official_forms(self):
        self.assertEqual(
            mtj.parse_quoted_tuple('("プレイしない","プレイ可能\\","---")'),
            ["プレイしない", "プレイ可能\\", "---"],
        )
        self.assertEqual(mtj.parse_quoted_tuple('("A\\","B")'), ["A\\", "B"])
        self.assertEqual(mtj.parse_quoted_tuple('("A\\n","B")'), ["A\n", "B"])
        self.assertEqual(mtj.unquote_unreal('"A\\qB"'), "A\\qB")
        self.assertEqual(blp.quote_unreal('MICHAEL "MOOSE" MUSSELLAM'), '"MICHAEL "MOOSE" MUSSELLAM"')

    def test_duplicate_json_key_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "dup.json"
            path.write_text('{"schema":2,"g":{"1":{},"1":{}}}', encoding="utf-8")
            with self.assertRaises(blp.BuildError):
                blp.load_json_file(path, "test JSON")

    def test_existing_translation_parse_errors_are_hard_failures(self):
        old_translation_json = mtj.TRANSLATION_JSON
        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                path = Path(temp_dir) / "translation.json"
                mtj.TRANSLATION_JSON = path

                path.write_text('{"schema":2,', encoding="utf-8")
                with self.assertRaisesRegex(mtj.GenerateError, "JSON parse failed"):
                    mtj.load_existing_translation()

                path.write_text('{"schema":1}', encoding="utf-8")
                with self.assertRaisesRegex(mtj.GenerateError, "unsupported schema"):
                    mtj.load_existing_translation()

                path.write_text('[]', encoding="utf-8")
                with self.assertRaisesRegex(mtj.GenerateError, "top-level JSON value"):
                    mtj.load_existing_translation()
        finally:
            mtj.TRANSLATION_JSON = old_translation_json

    def test_existing_translation_must_be_utf8(self):
        old_translation_json = mtj.TRANSLATION_JSON
        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                path = Path(temp_dir) / "translation.json"
                mtj.TRANSLATION_JSON = path
                path.write_bytes('{"schema":2,"g":"中文"}'.encode("gbk"))
                with self.assertRaisesRegex(mtj.GenerateError, "must be saved as UTF-8"):
                    mtj.load_existing_translation()
        finally:
            mtj.TRANSLATION_JSON = old_translation_json

    def test_translation_write_backs_up_existing_file(self):
        old_translation_json = mtj.TRANSLATION_JSON
        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                path = Path(temp_dir) / "translation.json"
                mtj.TRANSLATION_JSON = path
                path.write_text('{"schema":2,"g":{"1":{"zh_CN":"old"}}}', encoding="utf-8")
                mtj.write_translation_json(OrderedDict([("schema", 2)]))
                self.assertEqual((Path(temp_dir) / "translation.json.bak").read_text(encoding="utf-8"), '{"schema":2,"g":{"1":{"zh_CN":"old"}}}')
                self.assertEqual(json.loads(path.read_text(encoding="utf-8"))["schema"], 2)
        finally:
            mtj.TRANSLATION_JSON = old_translation_json

    def test_bad_translation_does_not_overwrite_existing_backup(self):
        old_translation_json = mtj.TRANSLATION_JSON
        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                path = Path(temp_dir) / "translation.json"
                backup = Path(temp_dir) / "translation.json.bak"
                mtj.TRANSLATION_JSON = path
                path.write_text('{"schema":2,', encoding="utf-8")
                backup.write_text("known-good", encoding="utf-8")
                with self.assertRaises(mtj.GenerateError):
                    mtj.load_existing_translation()
                self.assertEqual(backup.read_text(encoding="utf-8"), "known-good")
        finally:
            mtj.TRANSLATION_JSON = old_translation_json

    def test_translation_backup_is_gitignored(self):
        proc = subprocess.run(
            ["git", "check-ignore", "translation.json.bak"],
            cwd=ROOT_DIR,
            text=True,
            encoding="utf-8",
            errors="replace",
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        self.assertEqual(proc.returncode, 0, proc.stdout)

    def test_fallback_replacements_are_shared(self):
        self.assertIs(mtj.FALLBACK_REPLACEMENTS, blp.FALLBACK_REPLACEMENTS)

    def test_build_out_does_not_touch_default_build_dir(self):
        real_build = ROOT_DIR / "build"
        real_build.mkdir(exist_ok=True)
        sentinel = real_build / "__codex_out_regression_sentinel.tmp"
        sentinel.write_text("keep", encoding="utf-8")
        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                temp_root = Path(temp_dir)
                translation = OrderedDict(
                    [
                        ("schema", 2),
                        (
                            "sample.Group",
                            OrderedDict(
                                [
                                    (
                                        "1",
                                        OrderedDict(
                                            [
                                                ("note", "Greeting"),
                                                ("en", "Hello"),
                                                ("jp", "Hello"),
                                                ("zh_CN", "Hello"),
                                            ]
                                        ),
                                    )
                                ]
                            ),
                        ),
                    ]
                )
                catalog = OrderedDict(
                    [
                        ("schema", 1),
                        ("files", OrderedDict([("GameData/System/sample.int", [OrderedDict([("section", "S"), ("key", "Greeting"), ("type", "string"), ("entry", "sample.Group/1"), ("printf", [])])])])),
                    ]
                )
                json_path = temp_root / "translation.json"
                catalog_path = temp_root / "catalog.json"
                out_dir = temp_root / "out"
                json_path.write_text(json.dumps(translation, ensure_ascii=False), encoding="utf-8")
                catalog_path.write_text(json.dumps(catalog, ensure_ascii=False), encoding="utf-8")
                proc = subprocess.run(
                    [
                        sys.executable,
                        "-X",
                        "utf8",
                        str(TOOLS_DIR / "build_langpack.py"),
                        "--json",
                        str(json_path),
                        "--catalog",
                        str(catalog_path),
                        "--out",
                        str(out_dir),
                    ],
                    cwd=ROOT_DIR,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                )
                self.assertEqual(proc.returncode, 0, proc.stdout)
                self.assertTrue((out_dir / "manifest.json").exists())
                self.assertTrue(sentinel.exists())
        finally:
            sentinel.unlink(missing_ok=True)

    def test_bare_values_upgrade_to_quoted_and_count(self):
        translations = {
            "g/1": {"note": "n", "en": "A=B", "jp": "", "zh_CN": "A=B"},
            "g/2": {"note": "n", "en": 'A"B', "jp": "", "zh_CN": 'A"B'},
            "g/3": {"note": "n", "en": " lead", "jp": "", "zh_CN": " lead"},
            "g/4": {"note": "n", "en": "(A)", "jp": "", "zh_CN": "(A)"},
        }
        catalog = OrderedDict(
            [
                (
                    "GameData/System/bare.int",
                    [
                        OrderedDict([("section", "S"), ("key", f"K{i}"), ("type", "string"), ("entry", f"g/{i}"), ("style", "bare"), ("printf", [])])
                        for i in range(1, 5)
                    ],
                )
            ]
        )
        outputs, _fallbacks, upgrades = blp.collect_outputs(catalog, translations, allow_untranslated=False)
        self.assertEqual(upgrades, 4)
        self.assertIn('K1="A=B"', outputs[0]["text"])
        self.assertIn('K2="A"B"', outputs[0]["text"])

    def test_passthrough_literal_normalizes_and_covers_en_only_rows(self):
        catalog_files = OrderedDict([("GameData/System/sample.int", [])])
        stats = Counter()
        audit = {}
        rows = [
            mtj.IntRow("sample.int", 1, "S", "Copyright", '"© LUCAS"', 'Copyright="© LUCAS"'),
            mtj.IntRow("sample.int", 2, "S", "Plain", '"Plain"', 'Plain="Plain"'),
        ]
        mtj.append_en_passthrough_rows("GameData/System/sample.int", rows, catalog_files, stats, audit)
        self.assertEqual(stats["en_passthrough_literal_rows"], 2)
        self.assertEqual(stats["passthrough_literal_normalized"], 1)
        self.assertEqual(catalog_files["GameData/System/sample.int"][0]["value"], '"(C) LUCAS"')
        mtj.validate_catalog_covers_en_runtime(catalog_files, {"GameData/System/sample.int": rows}, audit)
        self.assertEqual(audit["catalog_en_runtime_coverage"]["missing_rows"], 0)

    def test_subtitle_empty_english_source_becomes_skipped(self):
        jp_info = {
            "path": Path("subtitles_test.int"),
            "rows": [
                mtj.IntRow("subtitles_test.int", 1, "Subtitles", "SubtitleSound[0]", '"snd"', ""),
                mtj.IntRow("subtitles_test.int", 2, "Subtitles", "SubtitleText[0]", '"JP"', ""),
            ],
        }
        en_info = {
            "path": Path("subtitles_test.int"),
            "rows": [
                mtj.IntRow("subtitles_test.int", 1, "Subtitles", "SubtitleSound[0]", '"snd"', ""),
                mtj.IntRow("subtitles_test.int", 2, "Subtitles", "SubtitleText[0]", '""', ""),
            ],
        }
        catalog_files = OrderedDict()
        translation = OrderedDict([("schema", 2)])
        skipped = []
        stats = Counter()
        mtj.process_subtitle_file(
            jp_info,
            en_info,
            "GameData/System/subtitles_test.int",
            catalog_files,
            translation,
            mtj.EntryAllocator(None),
            skipped,
            {},
            stats,
            False,
        )
        self.assertEqual(skipped[0]["reason_code"], "empty_english_source")
        rows = catalog_files["GameData/System/subtitles_test.int"]
        self.assertEqual([row["type"] for row in rows], ["literal", "literal"])
        self.assertEqual(stats["subtitle_passthrough_literal_rows"], 2)
        mtj.validate_catalog_covers_en_runtime(catalog_files, {"GameData/System/subtitles_test.int": en_info["rows"]}, {})

    def test_credits_and_empty_english_literals_are_normalized(self):
        catalog_files = OrderedDict()
        stats = Counter()
        emitted = mtj.emit_from_source(
            catalog_files,
            OrderedDict([("schema", 2)]),
            mtj.EntryAllocator(None),
            "GameData/System/credits.int",
            "Credits",
            "CreditsLine[0]",
            mtj.SourceValue(kind="string", raw='"© É"', text="© É", style="quoted"),
            '"© É"',
            "credits",
            stats,
            False,
        )
        self.assertEqual(emitted, "literal")
        self.assertEqual(catalog_files["GameData/System/credits.int"][0]["value"], '"(C) E"')
        self.assertEqual(stats["passthrough_literal_normalized"], 1)

        with self.assertRaisesRegex(mtj.GenerateError, "passthrough literal contains non-GBK text"):
            mtj.emit_from_source(
                OrderedDict(),
                OrderedDict([("schema", 2)]),
                mtj.EntryAllocator(None),
                "GameData/System/sample.int",
                "S",
                "Empty",
                mtj.SourceValue(kind="string", raw='"😀"', text="", style="quoted"),
                '"JP"',
                "sample",
                Counter(),
                False,
            )

    def test_translation_preservation_and_shared_restore(self):
        existing = {
            "schema": 2,
            "g": {
                "7": {"note": "Normal", "en": "Hello", "jp": "JP", "zh_CN": "你好"},
                "9": {"note": "Natural", "en": "Door", "jp": "Door", "zh_CN": "门"},
            },
            "shared.enjp": {
                "100001": {"note": "Merged", "en": "Shared", "jp": "共有", "zh_CN": "共享"}
            },
        }
        allocator = mtj.EntryAllocator(existing)
        translation = OrderedDict([("schema", 2)])
        stats = Counter()
        ref1 = mtj.add_translation_entry(translation, allocator, "g", "Normal", "Hello", "JP", None, None, stats, False)
        ref2 = mtj.add_translation_entry(translation, allocator, "g", "Natural", "Door", "Door", "9", "Door", stats, False)
        ref3 = mtj.add_translation_entry(translation, allocator, "other", "Split", "Shared", "共有", None, None, stats, False)
        self.assertEqual(ref1, "g/7")
        self.assertEqual(ref2, "g/9")
        self.assertEqual(translation["g"]["7"]["zh_CN"], "你好")
        self.assertEqual(translation["other"]["1"]["zh_CN"], "共享")
        self.assertEqual(stats["restored_from_shared"], 1)

    def test_identity_golden_matches_english_runtime_semantics(self):
        translation_path = ROOT_DIR / "translation.json"
        catalog_path = ROOT_DIR / "reference" / "export" / "localization_catalog.json"
        if not translation_path.exists() or not catalog_path.exists():
            self.skipTest("generated translation/catalog files are missing")

        translation = json.loads(translation_path.read_text(encoding="utf-8-sig"))
        for group, payload in translation.items():
            if group == "schema":
                continue
            for item in payload.values():
                item["zh_CN"] = mtj.normalize_fallback_text(item["en"])

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            identity_path = temp_root / "identity_translation.json"
            out_dir = temp_root / "identity_out"
            identity_path.write_text(json.dumps(translation, ensure_ascii=False), encoding="utf-8")
            proc = subprocess.run(
                [
                    sys.executable,
                    "-X",
                    "utf8",
                    str(TOOLS_DIR / "build_langpack.py"),
                    "--json",
                    str(identity_path),
                    "--catalog",
                    str(catalog_path),
                    "--out",
                    str(out_dir),
                ],
                cwd=ROOT_DIR,
                text=True,
                encoding="utf-8",
                errors="replace",
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
            )
            self.assertEqual(proc.returncode, 0, proc.stdout)

            game_system = ROOT_DIR.parent.parent / "GameData" / "System"
            generated_system = out_dir / "GameData" / "System"
            compared = 0
            for generated_path in generated_system.glob("*.int"):
                en_path = game_system / generated_path.name
                if not en_path.exists():
                    continue
                en_rows = parse_int_semantics(en_path, "cp1252")
                generated_rows = parse_int_semantics(generated_path, "gbk")
                self.assertGreaterEqual(
                    Counter(generated_rows),
                    Counter(en_rows),
                    f"{generated_path.name} identity build does not preserve EN runtime semantics",
                )
                compared += 1
            self.assertGreater(compared, 0)


if __name__ == "__main__":
    unittest.main()
