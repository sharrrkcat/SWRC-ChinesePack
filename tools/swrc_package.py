#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""SWRC (Star Wars Republic Commando) Unreal 包解析器
包版本 159 / licensee 1 专用。格式细节见 ../README-汉化技术文档.md §4。

用法:
    py -X utf8 swrc_package.py <package>              # 概览: 头/名称/导入/导出表
    py -X utf8 swrc_package.py <package> font <名字>  # 解码 UFont 对象 (字形/贴图页/CharRemap)
    py -X utf8 swrc_package.py <package> tex <名字> [输出.png]  # 解码贴图对象 (DXT5, 需 Pillow)

注意: 导出表为 RC 定制布局 (含 X 字节, Size/Offset 为定长 i32), 与标准 UE2 不同。
"""
import struct, sys, collections

SIG = 0x9E2A83C1

def read_ci(buf, p):
    """Unreal 紧凑索引: 首字节 bit7=负号 bit6=后续 bit0-5=值; 后续字节 bit7=后续 bit0-6=值"""
    b0 = buf[p]; p += 1
    v = b0 & 0x3F; sh = 6; more = b0 & 0x40
    while more:
        b = buf[p]; p += 1
        v |= (b & 0x7F) << sh; sh += 7; more = b & 0x80
    return (-v if (b0 & 0x80) else v), p


class Package:
    def __init__(self, path):
        self.path = path
        with open(path, 'rb') as f:
            self.d = f.read()
        d = self.d
        sig, self.ver, self.lic = struct.unpack_from('<IHH', d, 0)
        assert sig == SIG, f'非 Unreal 包: {hex(sig)}'
        (self.flags, nc, no, ec, eo, ic, io) = struct.unpack_from('<IIIIIII', d, 8)
        # 名称表: CI长度(含\0) + 字节串 + u32旗标
        self.names = []; p = no
        for _ in range(nc):
            ln, p = read_ci(d, p)
            self.names.append(d[p:p+ln-1].decode('latin-1')); p += ln + 4
        # 导入表 (标准布局)
        self.imports = []; p = io
        for _ in range(ic):
            cp, p = read_ci(d, p); cn, p = read_ci(d, p)
            outer, = struct.unpack_from('<i', d, p); p += 4
            nm, p = read_ci(d, p)
            self.imports.append(dict(class_package=self.names[cp], class_name=self.names[cn],
                                     outer=outer, name=self.names[nm]))
        # 导出表 (RC 定制布局!)
        self.exports = []; p = eo
        for _ in range(ec):
            cls, p = read_ci(d, p)
            sup, p = read_ci(d, p)
            pkg, = struct.unpack_from('<i', d, p); p += 4
            x, p = read_ci(d, p)                      # RC 特有字段
            nm, p = read_ci(d, p)
            fl, = struct.unpack_from('<I', d, p); p += 4
            sz, off = struct.unpack_from('<ii', d, p); p += 8
            self.exports.append(dict(cls=cls, super=sup, outer=pkg, x=x,
                                     name=self.names[nm], flags=fl, size=sz, offset=off))

    def obj_name(self, ref):
        """对象引用: >0 导出表(1基) / <0 导入表 / 0 None"""
        if ref == 0: return 'None'
        if ref > 0: return self.exports[ref-1]['name']
        return self.imports[-ref-1]['name']

    def find_export(self, name):
        for e in self.exports:
            if e['name'].lower() == name.lower(): return e
        raise KeyError(name)

    def dump(self):
        print(f'{self.path}: ver={self.ver} lic={self.lic} '
              f'names={len(self.names)} imports={len(self.imports)} exports={len(self.exports)}')
        for i, im in enumerate(self.imports):
            print(f'  imp[-{i+1}] {im["class_package"]}.{im["class_name"]} {im["name"]} (outer={im["outer"]})')
        for i, e in enumerate(self.exports):
            print(f'  exp[{i+1}] class={self.obj_name(e["cls"]):10s} {e["name"]:24s} '
                  f'outer={e["outer"]} X={e["x"]} flags={e["flags"]:#x} size={e["size"]} off={e["offset"]}')

    # ---- UFont 解码 (§4.5): None属性 | CI字形数 | 17B字形× | CI页数 | CI引用× | i32 Kerning | CI映射数 | 4B对× | u32 IsRemapped
    def decode_font(self, name):
        e = self.find_export(name)
        o = self.d[e['offset']:e['offset']+e['size']]
        assert o[0] == 0, '预期空属性表(None)'
        n, p = read_ci(o, 1)
        chars = [struct.unpack_from('<4iB', o, p + i*17) for i in range(n)]  # U,V,US,VS,TexIdx
        p += n * 17
        tc, p = read_ci(o, p)
        pages = []
        for _ in range(tc):
            r, p = read_ci(o, p); pages.append(self.obj_name(r))
        kerning, = struct.unpack_from('<i', o, p); p += 4
        mc, p = read_ci(o, p)
        remap = dict(struct.unpack_from('<HH', o, p + i*4) for i in range(mc))
        p += mc * 4
        isremapped, = struct.unpack_from('<I', o, p); p += 4
        assert p == len(o), f'尾部未对齐: {p} != {len(o)}'
        return dict(characters=chars, pages=pages, kerning=kerning,
                    remap=remap, is_remapped=isremapped)

    # ---- 属性表解析 (贴图对象用; 信息字节低4位=类型: 1=byte 2=int 3=bool, 载荷分别 1/4/1 字节)
    def parse_props(self, d, p=0):
        props = {}
        while True:
            ni, p = read_ci(d, p)
            if self.names[ni] == 'None': return props, p
            t = d[p] & 0xF; p += 1
            if t == 2:
                props[self.names[ni]], = struct.unpack_from('<i', d, p); p += 4
            elif t in (1, 3):
                props[self.names[ni]] = d[p]; p += 1
            else:
                raise ValueError(f'未支持的属性类型 {t} @ {self.names[ni]}')

    # ---- 贴图解码 (§4.6): 属性表 | u8 mip数 | 每mip: u32 数据尾绝对偏移 + CI 大小 + 数据 + i32 USize + i32 VSize + u8 UBits + u8 VBits
    # Format=8 (TEXF_DXT5, 1字节/像素, 4×4块16B, 行数上取整到4)
    def decode_texture(self, name):
        e = self.find_export(name)
        d = self.d[e['offset']:e['offset']+e['size']]
        props, p = self.parse_props(d)
        mips = d[p]; p += 1
        out = []
        for _ in range(mips):
            p += 4  # 数据尾绝对偏移(冗余,可由大小推出)
            dsz, p = read_ci(d, p)
            data = d[p:p+dsz]; p += dsz
            us, vs = struct.unpack_from('<ii', d, p); p += 8
            p += 2  # UBits, VBits
            out.append(dict(data=data, usize=us, vsize=vs))
        assert p == len(d), f'尾部未对齐: {p} != {len(d)}'
        return props, out


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(1)
    pkg = Package(sys.argv[1])
    if len(sys.argv) >= 4 and sys.argv[2] == 'tex':
        props, mips = pkg.decode_texture(sys.argv[3])
        print(f'{sys.argv[3]}: {props} mips={len(mips)}')
        for m in mips:
            print(f"  {m['usize']}x{m['vsize']} 数据 {len(m['data'])} 字节")
        if len(sys.argv) >= 5:
            from PIL import Image
            m = mips[0]
            Image.frombytes('RGBA', (m['usize'], m['vsize']), m['data'], 'bcn', 3).save(sys.argv[4])
            print('已写出', sys.argv[4])
    elif len(sys.argv) >= 4 and sys.argv[2] == 'font':
        f = pkg.decode_font(sys.argv[3])
        print(f'{sys.argv[3]}: 字形={len(f["characters"])} 页={len(f["pages"])} '
              f'kerning={f["kerning"]} 映射={len(f["remap"])} IsRemapped={f["is_remapped"]}')
        print('贴图页:', f['pages'])
        zones = collections.Counter()
        for k in f['remap']:
            zones['ASCII(<0x80)' if k < 0x80 else 'Latin(0x80-FF)' if k < 0x100 else 'DBCS/CJK(>0xFF)'] += 1
        print('键分布:', dict(zones))
        per_page = collections.Counter(f['characters'][g][4] for g in f['remap'].values()
                                       if g < len(f['characters']))
        print('各页字形引用数:', dict(sorted(per_page.items())))
    else:
        pkg.dump()
