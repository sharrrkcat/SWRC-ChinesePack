#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成字符集文件 (charset.txt)。

默认 (全集): ASCII 可打印 + GB2312 符号区 + 一二级汉字 (~7500 字符, 开发期全覆盖)。
--slim (瘦身): ASCII 可打印 + GB2312 一级字 ∪ translation.json 用字 ∪ 常用中文标点 (~4200 字符)。

用法:
  py -X utf8 make_charset.py [charset.txt]
  py -X utf8 make_charset.py --slim [charset.txt]
  py -X utf8 make_charset.py --slim --translation path/to/translation.json [charset.txt]
"""
import argparse
import json
import os

COMMON_PUNCT = set('，。、！？：；（）《》“”‘’—…·【】「」〈〉～‖')


def _gb2312_range(lead_lo, lead_hi):
    """遍历 GB2312 双字节区指定 lead 范围, 返回有效字符列表 (GBK 字节序)。"""
    chars = []
    for lead in range(lead_lo, lead_hi + 1):
        for trail in range(0xA1, 0xFF):
            try:
                ch = bytes([lead, trail]).decode('gbk')
            except UnicodeDecodeError:
                continue
            chars.append(ch)
    return chars


def _translation_chars(path):
    """从 translation.json 的 zh_CN 字段提取非 ASCII 字符集。"""
    t = json.load(open(path, encoding='utf-8'))
    chars = set()
    for gk, g in t.items():
        if gk == 'schema':
            continue
        if not isinstance(g, dict):
            continue
        for e in g.values():
            zh = e.get('zh_CN', '') if isinstance(e, dict) else ''
            if zh:
                chars.update(c for c in zh if ord(c) >= 0x80)
    return chars


def build_full():
    """ASCII + GB2312 全集 (符号区 01-09 + 一级字 16-55 + 二级字 56-87)。"""
    chars = [chr(c) for c in range(0x20, 0x7F)]
    chars.extend(_gb2312_range(0xA1, 0xF7))
    return ''.join(chars)


def build_slim(translation_path=None):
    """ASCII + GB2312 一级字 ∪ translation.json 用字 ∪ 常用标点。"""
    chars = [chr(c) for c in range(0x20, 0x7F)]
    cjk = set(_gb2312_range(0xB0, 0xD7))
    cjk |= COMMON_PUNCT
    if translation_path:
        cjk |= _translation_chars(translation_path)

    def _gbk_key(c):
        try:
            return c.encode('gbk')
        except UnicodeEncodeError:
            return b'\xff\xff'

    chars.extend(sorted(cjk, key=_gbk_key))
    return ''.join(chars)


def _stats(s):
    ascii_n = sum(1 for c in s if ord(c) < 0x80)
    hanzi_n = sum(1 for c in s if '一' <= c <= '鿿' or '㐀' <= c <= '䶿')
    sym_n = len(s) - ascii_n - hanzi_n
    return ascii_n, hanzi_n, sym_n


if __name__ == '__main__':
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('output', nargs='?', default='charset.txt',
                    help='输出文件 (默认 charset.txt)')
    ap.add_argument('--slim', action='store_true',
                    help='瘦身模式: GB2312 一级字 ∪ translation.json 用字 ∪ 常用标点')
    ap.add_argument('--translation', default=None,
                    help='translation.json 路径 (--slim 默认自动定位上级目录)')
    a = ap.parse_args()

    if a.slim:
        tj = a.translation
        if not tj:
            default = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                   '..', 'translation.json')
            if os.path.isfile(default):
                tj = default
        s = build_slim(tj)
        mode = '瘦身'
    else:
        s = build_full()
        mode = '全集'

    open(a.output, 'w', encoding='utf-8').write(s)
    ascii_n, hanzi_n, sym_n = _stats(s)
    print(f'{a.output}: {len(s)} 字符 ({mode}, ASCII {ascii_n}, 汉字 {hanzi_n}, 符号 {sym_n})')
    if a.slim and tj:
        print(f'  含 translation.json 用字: {tj}')
    elif a.slim:
        print(f'  未找到 translation.json, 仅 GB2312 一级字 + 常用标点')
