#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成字符集文件 (charset.txt): ASCII 可打印区 + GB2312 全集 (符号区+一二级汉字)。
最终发布前应换成"译文扫描子集" (文档 §8 步骤 1), 本文件用于开发期全覆盖测试。

用法: py -X utf8 make_charset.py [输出文件=charset.txt]
"""
import sys

def build():
    chars = [chr(c) for c in range(0x20, 0x7F)]         # ASCII 可打印
    for lead in range(0xA1, 0xF8):                      # GB2312 双字节区
        for trail in range(0xA1, 0xFF):
            try:
                ch = bytes([lead, trail]).decode('gbk')   # 用 gbk 解码保证与 font_gen 的键编码往返一致
            except UnicodeDecodeError:
                continue
            chars.append(ch)
    return ''.join(chars)

if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else 'charset.txt'
    s = build()
    open(out, 'w', encoding='utf-8').write(s)
    print(f'{out}: {len(s)} 字符 (ASCII {sum(1 for c in s if ord(c)<0x80)}, CJK/全角 {sum(1 for c in s if ord(c)>0x80)})')
