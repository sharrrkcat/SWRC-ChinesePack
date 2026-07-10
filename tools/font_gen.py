#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""SWRC 中文字体包生成器: TTF/OTF → orbitfonts.utx (包版本 159, RC 定制布局)

管线: Pillow 渲染灰度字形 → 打包贴图页 (512 宽) → DXT5 编码 (RGB=A=灰度)
     → 写 .utx (5 字号 UFont + 贴图页, CharRemap 键=GBK 双字节码, IsRemapped=1)
可选: --latin-source 从英文版 orbitfonts.utx 复用 0x20-0x7E ASCII glyph。

格式依据: docs/README-汉化技术文档.md §4 (导出表 RC 布局 / UFont / 贴图对象 DXT5)。
字号→行高映射取自官方日文版实测 (局内验证过的度量)。

用法:
    py -X utf8 font_gen.py --font ../fonts/SourceHanSansCN-Bold.otf \
        --charset charset.txt --out orbitfonts.utx
"""
import argparse, importlib.util, struct, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

# 字号→字形行高 (px), 官方日文版实测值
CELL_HEIGHTS = {24: 29, 18: 24, 15: 20, 12: 16, 8: 13}
FONT_ORDER = [24, 18, 15, 12, 8]     # 美/日版包内导出顺序
PAGE_W = 512
PAGE_H_MAX = 512
PAD = 1                              # 字形间距, 防 DXT 块内串色
NAME_FLAGS = 0x4070490               # 美版名称表旗标实测值
GUID = bytes.fromhex('11c5a2e5a0b34f748b15dd940c135d2b')
LATIN_RANGE = range(0x20, 0x7F)

# ---------------- DXT5 编码 (numpy 向量化) ----------------

def dxt5_encode_gray(gray):
    """灰度页 → DXT5 字节串。RGB=A=灰度 (复现原版字形像素构成, 文档 §4.6)。
    gray: (h, w) uint8, h/w 为 4 的倍数。"""
    h, w = gray.shape
    assert h % 4 == 0 and w % 4 == 0
    # 切 4×4 块 → (nb, 16)
    b = gray.reshape(h // 4, 4, w // 4, 4).transpose(0, 2, 1, 3).reshape(-1, 16).astype(np.int32)
    nb = b.shape[0]
    amax, amin = b.max(1), b.min(1)

    # --- alpha 块: a0=max, a1=min (8 值内插模式, a0>a1) ---
    a0, a1 = amax, amin
    flat = a0 == a1
    # 8 级调色板 (nb, 8): [a0, a1, (6a0+a1)/7 ... (a0+6a1)/7]
    wts = np.array([[7, 0], [0, 7], [6, 1], [5, 2], [4, 3], [3, 4], [2, 5], [1, 6]])
    pal = (a0[:, None] * wts[:, 0] + a1[:, None] * wts[:, 1] + 3) // 7   # (nb,8)
    idx = np.abs(b[:, :, None] - pal[:, None, :]).argmin(2)             # (nb,16) 3bit 码
    idx[flat] = 0
    # 16×3bit 打包成 48bit 小端
    shifts = (np.arange(16, dtype=np.uint64) * 3)
    bits = (idx.astype(np.uint64) << shifts).sum(1, dtype=np.uint64)    # 48 bit
    alpha_blk = np.zeros((nb, 8), np.uint8)
    alpha_blk[:, 0] = a0; alpha_blk[:, 1] = a1
    for i in range(6):
        alpha_blk[:, 2 + i] = (bits >> np.uint64(8 * i)).astype(np.uint8)

    # --- 颜色块: 灰度端点 c0=max, c1=min (4 色模式需 c0>c1) ---
    g565 = lambda g: ((g >> 3) << 11) | ((g >> 2) << 5) | (g >> 3)
    c0v, c1v = g565(amax), g565(amin)
    cflat = c0v <= c1v
    # 4 级灰度调色板 [max, min, (2max+min)/3, (max+2min)/3]
    cw = np.array([[3, 0], [0, 3], [2, 1], [1, 2]])
    cpal = (amax[:, None] * cw[:, 0] + amin[:, None] * cw[:, 1] + 1) // 3
    cidx = np.abs(b[:, :, None] - cpal[:, None, :]).argmin(2)           # (nb,16) 2bit 码
    cidx[cflat] = 0
    cshifts = (np.arange(16, dtype=np.uint64) * 2)
    cbits = (cidx.astype(np.uint64) << cshifts).sum(1, dtype=np.uint64) # 32 bit
    color_blk = np.zeros((nb, 8), np.uint8)
    color_blk[:, 0] = c0v & 0xFF;  color_blk[:, 1] = c0v >> 8
    color_blk[:, 2] = c1v & 0xFF;  color_blk[:, 3] = c1v >> 8
    for i in range(4):
        color_blk[:, 4 + i] = (cbits >> np.uint64(8 * i)).astype(np.uint8)

    return np.concatenate([alpha_blk, color_blk], 1).tobytes()

def _pack_alpha_blocks(alpha):
    b = alpha.reshape(alpha.shape[0] // 4, 4, alpha.shape[1] // 4, 4).transpose(0, 2, 1, 3).reshape(-1, 16).astype(np.int32)
    amax, amin = b.max(1), b.min(1)
    flat = amax == amin
    wts = np.array([[7, 0], [0, 7], [6, 1], [5, 2], [4, 3], [3, 4], [2, 5], [1, 6]])
    pal = (amax[:, None] * wts[:, 0] + amin[:, None] * wts[:, 1] + 3) // 7
    idx = np.abs(b[:, :, None] - pal[:, None, :]).argmin(2)
    idx[flat] = 0
    shifts = np.arange(16, dtype=np.uint64) * 3
    bits = (idx.astype(np.uint64) << shifts).sum(1, dtype=np.uint64)
    out = np.zeros((b.shape[0], 8), np.uint8)
    out[:, 0] = amax
    out[:, 1] = amin
    for i in range(6):
        out[:, 2 + i] = (bits >> np.uint64(8 * i)).astype(np.uint8)
    return out

def _rgb_to_565(rgb):
    r = rgb[..., 0].astype(np.int32)
    g = rgb[..., 1].astype(np.int32)
    b = rgb[..., 2].astype(np.int32)
    return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)

def _rgb_from_565(c):
    c = c.astype(np.int32)
    return np.stack([
        ((c >> 11) & 0x1F) * 255 // 31,
        ((c >> 5) & 0x3F) * 255 // 63,
        (c & 0x1F) * 255 // 31,
    ], axis=-1).astype(np.int32)

def _pack_color_blocks(rgb):
    blocks = rgb.reshape(rgb.shape[0] // 4, 4, rgb.shape[1] // 4, 4, 3).transpose(0, 2, 1, 3, 4).reshape(-1, 16, 3).astype(np.int32)
    lum = (blocks[:, :, 0] * 77 + blocks[:, :, 1] * 150 + blocks[:, :, 2] * 29) // 256
    imax = lum.argmax(1)
    imin = lum.argmin(1)
    row = np.arange(blocks.shape[0])
    c0 = _rgb_to_565(blocks[row, imax])
    c1 = _rgb_to_565(blocks[row, imin])
    swap = c0 <= c1
    c0, c1 = np.where(swap, c1, c0), np.where(swap, c0, c1)
    p0 = _rgb_from_565(c0)
    p1 = _rgb_from_565(c1)
    pal = np.stack([p0, p1, (2 * p0 + p1) // 3, (p0 + 2 * p1) // 3], axis=1)
    dist = ((blocks[:, :, None, :] - pal[:, None, :, :]) ** 2).sum(3)
    idx = dist.argmin(2).astype(np.uint64)
    shifts = np.arange(16, dtype=np.uint64) * 2
    bits = (idx << shifts).sum(1, dtype=np.uint64)
    out = np.zeros((blocks.shape[0], 8), np.uint8)
    out[:, 0] = c0 & 0xFF
    out[:, 1] = c0 >> 8
    out[:, 2] = c1 & 0xFF
    out[:, 3] = c1 >> 8
    for i in range(4):
        out[:, 4 + i] = (bits >> np.uint64(8 * i)).astype(np.uint8)
    return out

def dxt5_encode_rgba(rgba):
    """RGBA 页 → DXT5 字节串。用于混合模式保留英文原版 RGB/Alpha 关系。"""
    h, w, c = rgba.shape
    assert c == 4 and h % 4 == 0 and w % 4 == 0
    alpha_blk = _pack_alpha_blocks(rgba[:, :, 3])
    color_blk = _pack_color_blocks(rgba[:, :, :3])
    return np.concatenate([alpha_blk, color_blk], 1).tobytes()

# ---------------- 字形渲染与打包 ----------------

def render_size(ttf_path, chars, cell_h):
    """渲染一个字号的全部字形。返回 (pages[灰度ndarray], glyphs[(u,v,w,h,page)])。
    glyphs[0] 为回落空白字形 (CharRemap 查不到的键落到索引 0)。"""
    # 字号 = 行高: 全角字形恰为 cell_h × cell_h (与日版度量一致)。
    # 基线锚在 0.88em (CJK em 框: 上 0.88 / 下 0.12), 不用 hhea 度量 (思源 asc+desc≈1.48em, 会把字渲染得过小)
    font = ImageFont.truetype(ttf_path, cell_h)
    baseline = round(cell_h * 0.88)

    pages, glyphs = [], []
    img = Image.new('L', (PAGE_W, PAGE_H_MAX), 0)
    draw = ImageDraw.Draw(img)
    x = y = 0
    used_h = 0

    def flush():
        nonlocal img, draw, x, y, used_h
        vh = 16
        while vh < used_h: vh *= 2                   # 页高向上取 2 的幂
        pages.append(np.asarray(img.crop((0, 0, PAGE_W, min(vh, PAGE_H_MAX))), np.uint8))
        img = Image.new('L', (PAGE_W, PAGE_H_MAX), 0)
        draw = ImageDraw.Draw(img)
        x = y = used_h = 0

    def alloc(w):
        nonlocal x, y, used_h
        if x + w > PAGE_W:
            x = 0; y += cell_h + PAD
        if y + cell_h > PAGE_H_MAX:
            flush()
        pos = (x, y)
        x += w + PAD
        used_h = max(used_h, y + cell_h)
        return pos

    # 索引 0: 回落空白字形
    w0 = max(2, cell_h // 3)
    gx, gy = alloc(w0)
    glyphs.append((gx, gy, w0, cell_h, len(pages)))

    for ch in chars:
        w = max(1, int(round(draw.textlength(ch, font=font))))
        w = min(w, PAGE_W)
        gx, gy = alloc(w)
        draw.text((gx, gy + baseline), ch, font=font, fill=255, anchor='ls')
        glyphs.append((gx, gy, w, cell_h, len(pages)))
    flush()
    assert len(pages) <= 256, 'TextureIndex 为 u8, 页数超限'
    return pages, glyphs

def _load_swrc_package_module():
    path = Path(__file__).with_name('swrc_package.py')
    spec = importlib.util.spec_from_file_location('swrc_package_for_font_gen', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def load_latin_source(path):
    """读取英文版 orbitfonts.utx 的 0x20-0x7E glyph。返回 size -> codepoint -> RGBA ndarray。"""
    swrc_package = _load_swrc_package_module()
    pkg = swrc_package.Package(path)
    result = {}
    for size in FONT_ORDER:
        font_name = f'OrbitBold{size}'
        font = pkg.decode_font(font_name)
        if font['is_remapped'] != 0:
            raise SystemExit(f'{path}: {font_name} 必须是英文版直查字体 (IsRemapped=0)')
        if len(font['characters']) < 0x80:
            raise SystemExit(f'{path}: {font_name} 字形数不足, 无法读取 ASCII')
        page_images = []
        for page_name in font['pages']:
            _props, mips = pkg.decode_texture(page_name)
            mip = mips[0]
            page_images.append(np.array(Image.frombytes('RGBA', (mip['usize'], mip['vsize']), mip['data'], 'bcn', 3), np.uint8))
        glyphs = {}
        for cp in LATIN_RANGE:
            u, v, gw, gh, tp = font['characters'][cp]
            if gw <= 0 or gh <= 0:
                raise SystemExit(f'{path}: {font_name} ASCII 0x{cp:02X} glyph 尺寸无效: {gw}x{gh}')
            if tp >= len(page_images):
                raise SystemExit(f'{path}: {font_name} ASCII 0x{cp:02X} TextureIndex 越界: {tp}')
            page = page_images[tp]
            if u < 0 or v < 0 or u + gw > page.shape[1] or v + gh > page.shape[0]:
                raise SystemExit(f'{path}: {font_name} ASCII 0x{cp:02X} glyph 越出贴图页')
            glyphs[cp] = page[v:v + gh, u:u + gw, :].copy()
        result[size] = glyphs
    return result

def _render_cjk_rgba(font, ch, cell_h, baseline, target_h=None):
    gray = Image.new('L', (cell_h, cell_h), 0)
    ImageDraw.Draw(gray).text((0, baseline), ch, font=font, fill=255, anchor='ls')
    g = np.asarray(gray, np.uint8)
    glyph = np.repeat(g[:, :, None], 4, axis=2)
    target_h = target_h or cell_h
    if target_h <= cell_h:
        return glyph
    out = np.zeros((target_h, cell_h, 4), np.uint8)
    y = max(0, (target_h - cell_h) // 2)
    out[y:y + cell_h, :, :] = glyph
    return out

def render_size_mixed(ttf_path, chars, cell_h, latin_glyphs):
    """混合模式: ASCII 复用英文版 RGBA glyph, 其他字符由 TTF 渲染为 RGBA。"""
    font = ImageFont.truetype(ttf_path, cell_h)
    baseline = round(cell_h * 0.88)
    latin_line_h = max(g.shape[0] for g in latin_glyphs.values())
    mixed_line_h = max(cell_h, latin_line_h)

    pages, glyphs = [], []
    img = np.zeros((PAGE_H_MAX, PAGE_W, 4), np.uint8)
    x = y = row_h = used_h = 0

    def flush():
        nonlocal img, x, y, row_h, used_h
        vh = 16
        while vh < used_h: vh *= 2
        pages.append(img[:min(vh, PAGE_H_MAX), :, :].copy())
        img = np.zeros((PAGE_H_MAX, PAGE_W, 4), np.uint8)
        x = y = row_h = used_h = 0

    def alloc(w, h):
        nonlocal x, y, row_h, used_h
        if w > PAGE_W:
            raise SystemExit(f'字形宽度 {w}px 超过贴图页宽度 {PAGE_W}px')
        if x + w > PAGE_W:
            x = 0
            y += row_h + PAD
            row_h = 0
        if y + h > PAGE_H_MAX:
            flush()
        pos = (x, y)
        x += w + PAD
        row_h = max(row_h, h)
        used_h = max(used_h, y + h)
        return pos

    w0 = max(2, cell_h // 3)
    gx, gy = alloc(w0, mixed_line_h)
    glyphs.append((gx, gy, w0, mixed_line_h, len(pages)))

    for ch in chars:
        cp = ord(ch)
        if cp in LATIN_RANGE:
            glyph = latin_glyphs[cp]
        else:
            glyph = _render_cjk_rgba(font, ch, cell_h, baseline, mixed_line_h)
        gh, gw = glyph.shape[:2]
        gx, gy = alloc(gw, gh)
        img[gy:gy + gh, gx:gx + gw, :] = glyph
        glyphs.append((gx, gy, gw, gh, len(pages)))
    flush()
    assert len(pages) <= 256, 'TextureIndex 为 u8, 页数超限'
    return pages, glyphs

def build_remap(chars):
    """CharRemap: ASCII → 单字节键; 其余 → GBK 双字节键 (lead<<8)|trail (匹配 CJKText 钩子)。
    控制字符键 0x00-0x1F 显式映射到回落字形 0。字形索引 = 字符在 chars 中位置 + 1。"""
    remap = {k: 0 for k in range(0x20)}
    for i, ch in enumerate(chars):
        cp = ord(ch)
        if cp < 0x80:
            key = cp
        else:
            try:
                bs = ch.encode('gbk')
            except UnicodeEncodeError:
                raise SystemExit(f'字符 {ch!r} (U+{cp:04X}) 不在 GBK 内, 无法编码为键')
            assert len(bs) == 2 and 0x81 <= bs[0] <= 0xFE and 0x40 <= bs[1] <= 0xFE and bs[1] != 0x7F, \
                f'{ch!r} 的 GBK 码 {bs.hex()} 不符合钩子的 DBCS 配对规则'
            key = (bs[0] << 8) | bs[1]
        assert key not in remap or remap[key] == 0, f'键冲突: {key:#x}'
        remap[key] = i + 1
    return remap

# ---------------- .utx 写出 (RC 定制布局, 文档 §4) ----------------

def ci(v):
    """紧凑索引编码"""
    neg = v < 0
    v = -v if neg else v
    b0 = (0x80 if neg else 0) | (v & 0x3F)
    v >>= 6
    out = [b0 | (0x40 if v else 0)]
    while v:
        b = v & 0x7F; v >>= 7
        out.append(b | (0x80 if v else 0))
    return bytes(out)

class Writer:
    def __init__(self):
        self.names = []
        self._nidx = {}

    def name(self, s):
        if s not in self._nidx:
            self._nidx[s] = len(self.names)
            self.names.append(s)
        return self._nidx[s]

    def prop_bytes(self, props):
        """贴图属性表: (名称, 类型, 值)×N + None。类型: bool 载荷 1B (RC 特有), byte 1B, int 4B"""
        out = b''
        for nm, t, v in props:
            out += ci(self.name(nm))
            if t == 'bool':
                out += b'\xd3' + bytes([v])
            elif t == 'byte':
                out += b'\x01' + bytes([v])
            elif t == 'int':
                out += b'\x22' + struct.pack('<i', v)
        return out + ci(self.name('None'))

def build_package(ttf_path, chars, out_path, latin_source=None):
    w = Writer()
    # 名称表顺序模仿美版: None 与属性名在前
    for n in ['None', 'Core', 'Engine', 'Package', 'Class', 'Texture',
              'USize', 'VSize', 'Font', 'VClamp', 'VBits', 'UClamp', 'UBits',
              'bNoRawData', 'LODSet', 'bAlphaTexture', 'Format', 'OrbitFonts']:
        w.name(n)

    remap = build_remap(chars)
    latin_sets = load_latin_source(latin_source) if latin_source else None

    # 逐字号渲染并组装导出项 (页贴图在前, Font 对象在后, 与美版一致)
    exports = []       # dict: cls(-3 Tex/-4 Font), outer, x, name, flags, data(bytes 占位)
    for size in FONT_ORDER:
        cell = CELL_HEIGHTS[size]
        if latin_sets:
            pages, glyphs = render_size_mixed(ttf_path, chars, cell, latin_sets[size])
        else:
            pages, glyphs = render_size(ttf_path, chars, cell)
        print(f'OrbitBold{size}: 行高 {cell}px, 字形 {len(glyphs)}, 页数 {len(pages)}')
        font_exp_idx = len(exports) + 1 + len(pages)     # 1 基
        first_page_idx = len(exports) + 1
        page_refs = []
        for pi, pg in enumerate(pages):
            ph, pw = pg.shape[:2]
            props = w.prop_bytes([
                ('bAlphaTexture', 'bool', 0), ('bNoRawData', 'bool', 0),
                ('LODSet', 'byte', 0), ('Format', 'byte', 8),          # 8 = TEXF_DXT5
                ('UBits', 'byte', pw.bit_length() - 1), ('VBits', 'byte', ph.bit_length() - 1),
                ('USize', 'int', pw), ('VSize', 'int', ph),
                ('UClamp', 'int', pw), ('VClamp', 'int', ph)])
            dxt = dxt5_encode_rgba(pg) if pg.ndim == 3 else dxt5_encode_gray(pg)
            # u8 mip数 | u32 数据尾绝对偏移(后补) | CI 大小 | 数据 | i32 US/VS | u8 UB/VB
            native = (b'\x01', dxt,                                    # posafter 写出时回填
                      struct.pack('<ii', pw, ph) + bytes([pw.bit_length() - 1, ph.bit_length() - 1]))
            exports.append(dict(cls=-3, outer=font_exp_idx, x=0,
                                name=w.name(f'OrbitBold{size}_Page{pi:02d}'),
                                flags=0x70000, tex=(props, native)))
            page_refs.append(len(exports))               # 1 基导出索引
        # UFont 序列化 (§4.5)
        fo = ci(w.name('None')) + ci(len(glyphs))
        for (u, v, gw, gh, tp) in glyphs:
            fo += struct.pack('<4iB', u, v, gw, gh, tp)
        fo += ci(len(page_refs))
        for r in page_refs:
            fo += ci(r)
        fo += struct.pack('<i', 1)                        # Kerning
        fo += ci(len(remap))
        for k in sorted(remap):
            fo += struct.pack('<HH', k, remap[k])
        fo += struct.pack('<I', 1)                        # IsRemapped
        exports.append(dict(cls=-4, outer=0, x=first_page_idx,
                            name=w.name(f'OrbitBold{size}'), flags=0xF0004, data=fo))

    # ---- 布局: 头(64) | 名称表 | 导入表 | 导出表 | 对象数据 ----
    names_blob = b''.join(ci(len(n) + 1) + n.encode('ascii') + b'\0' + struct.pack('<I', NAME_FLAGS)
                          for n in w.names)
    imports = [('Core', 'Package', 0, 'OrbitFonts'), ('Core', 'Package', 0, 'Engine'),
               ('Core', 'Class', -2, 'Texture'), ('Core', 'Class', -2, 'Font')]
    imports_blob = b''.join(ci(w.name(cp)) + ci(w.name(cn)) + struct.pack('<i', o) + ci(w.name(nm))
                            for cp, cn, o, nm in imports)

    # 先算每个导出项的数据大小
    for e in exports:
        if 'tex' in e:
            props, (pre, dxt, tail) = e['tex']
            e['size'] = len(props) + 1 + 4 + len(ci(len(dxt))) + len(dxt) + len(tail)
        else:
            e['size'] = len(e['data'])
    # 导出表本身 (offset 占位后回填, 长度不受值影响: i32 定长)
    def export_entry(e, off):
        return (ci(e['cls']) + ci(0) + struct.pack('<i', e['outer']) + ci(e['x']) +
                ci(e['name']) + struct.pack('<Iii', e['flags'], e['size'], off))
    table_len = sum(len(export_entry(e, 0)) for e in exports)
    no = 64
    io = no + len(names_blob)
    eo = io + len(imports_blob)
    data0 = eo + table_len

    # 对象数据 (贴图的 posafter = 数据本体尾的绝对偏移)
    data_blob = b''
    off = data0
    for e in exports:
        e['offset'] = off
        if 'tex' in e:
            props, (pre, dxt, tail) = e['tex']
            szci = ci(len(dxt))
            posafter = off + len(props) + 1 + 4 + len(szci) + len(dxt)
            blob = props + pre + struct.pack('<I', posafter) + szci + dxt + tail
        else:
            blob = e['data']
        assert len(blob) == e['size']
        data_blob += blob
        off += len(blob)

    table_blob = b''.join(export_entry(e, e['offset']) for e in exports)
    header = struct.pack('<IHHIIIIIII', 0x9E2A83C1, 159, 1, 1,
                         len(w.names), no, len(exports), eo, len(imports), io)
    header += GUID + struct.pack('<III', 1, len(exports), len(w.names))
    assert len(header) == 64
    out = header + names_blob + imports_blob + table_blob + data_blob
    with open(out_path, 'wb') as f:
        f.write(out)
    print(f'{out_path}: {len(out)} 字节, 名称 {len(w.names)}, 导出 {len(exports)}')

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--font', required=True, help='TTF/OTF 字体文件 (需含 GBK 覆盖的 CJK 字形)')
    ap.add_argument('--charset', required=True, help='字符集文件 (UTF-8, make_charset.py 产出或译文扫描子集)')
    ap.add_argument('--out', default='orbitfonts.utx')
    ap.add_argument('--cells', default=None,
                    help='字号→行高覆盖, 如 "24=29,18=24,15=20,12=16,8=13" (默认=官方日版度量; '
                         '行高越大字越大, 但注意 UI 布局按行高排版, 偏离过多会挤压/溢出)')
    ap.add_argument('--latin-source', default=None,
                    help='可选: 从英文版 orbitfonts.utx 复用 ASCII 0x20-0x7E glyph, 中文仍由 --font 渲染')
    a = ap.parse_args()
    if a.cells:
        for kv in a.cells.split(','):
            k, v = kv.split('=')
            assert int(k) in CELL_HEIGHTS, f'未知字号 {k} (必须是 8/12/15/18/24)'
            CELL_HEIGHTS[int(k)] = int(v)
    chars = open(a.charset, encoding='utf-8').read()
    chars = ''.join(dict.fromkeys(c for c in chars if not c.isspace() or c == ' '))
    print(f'字符集: {len(chars)} 字符')
    build_package(a.font, chars, a.out, a.latin_source)
