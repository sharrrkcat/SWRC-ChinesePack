# 《星球大战：共和国突击队》简体中文汉化包

## 介绍

本项目在 [Republic Commando Fix](https://www.moddb.com/mods/republic-commando-fix) 2.13 的基础上增加了 CJK 语言渲染，并提供简体中文界面与字幕。

Release 包已经集成修改后的 Fix 2.13、中文字体和汉化文件，**不需要单独安装 Fix 2.13**。后续 Fix 更新时，本项目也会同步适配。翻译纠正可以直接提交 Pull Request，或在 [Issues](https://github.com/sharrrkcat/SWRC-ChinesePack/issues) 中留言。

### 字体声明

发布包中的中文字体使用 Adobe [思源黑体（Source Han Sans CN Bold）](https://github.com/adobe-fonts/source-han-sans) 生成。思源黑体采用 [SIL Open Font License 1.1](https://openfontlicense.org/open-font-license-official-text/) 授权，字体版权归原作者所有。

## 使用方法

1. 备份以下原文件：
   - `GameData\Textures\orbitfonts.utx`
   - `GameData\System\SWRepublicCommando.exe`
2. 下载[最新 Release](https://github.com/sharrrkcat/SWRC-ChinesePack/releases/latest) 中的压缩包，解压到游戏根目录并覆盖同名文件。
3. 打开 `GameData\System\System.ini`，将 `Language` 修改为：

   ```ini
   Language=cht
   ```

4. 通过 Steam 启动游戏，或运行 `GameData\System\SWRepublicCommando.exe`。

如需切回英文，将配置改为 `Language=int`。

## 项目结构

| 路径 | 说明 |
| --- | --- |
| `translation.json` | 完整翻译表；提交译文纠正时，可在这里搜索原文或译文并修改对应的 `zh_CN` |
| `reference/glossary.md` | 术语表与翻译约定 |
| `reference/export/localization_catalog.json` | 本地化文件结构、键名和输出路径记录 |
| `tools/build_langpack.py` | 根据翻译表和 catalog 生成 `.cht` 汉化文件 |
| `docs/技术说明.md` | CJK 渲染、字体格式和本地化结构的技术说明 |
| `docs/高级用法.md` | 自定义字体、字号和译文的操作说明 |

在仓库根目录生成汉化文件：

```powershell
py -X utf8 tools/build_langpack.py --out build
```

默认读取 `translation.json` 和 `reference/export/localization_catalog.json`，输出到 `build`。使用其他输入时，可通过 `--json` 和 `--catalog` 指定路径。

## 生成过程

### 翻译文件

`tools/build_langpack.py` 根据 `localization_catalog.json` 记录的文件结构、区段和键名生成骨架，再填入 `translation.json` 中的中文翻译，最终生成 GBK 编码的 `.cht` 文件。

### 翻译过程

译文依次经过粗翻、校对、精翻和局部人工终校：粗翻使用 Opus，校对与精翻主要使用 Fable 5 和 GPT-5.6 Sol。整体风格以 PS4 官方中文翻译为基础，通过术语表统一各条目的表述，同时修正了部分官方译文中的错误。之后又结合实际游玩时的上下文，对译文进行了多轮调整。

本项目由一名维护者配合多种 AI 完成，人力有限，译文难免仍有疏漏。不过经过多轮校订和实机体验，整体效果已经较为自然。欢迎通过 Pull Request 或 [Issues](https://github.com/sharrrkcat/SWRC-ChinesePack/issues) 提出修改建议。

### 字体包文件

为了减小字体包体积，先通过 `tools/make_charset.py` 的常用字模式（`--slim`）生成字符集，再使用 `tools/font_gen.py` 的混合模式，将思源黑体中文字形与原版英文 ASCII 字形合并，最终生成 `orbitfonts.utx`。

### Mod 文件

本项目 fork 了 [SWRC-Modding/CT](https://github.com/SWRC-Modding/CT)，相关修改位于 [sharrrkcat/CT-cjk-text](https://github.com/sharrrkcat/CT-cjk-text)。在原 Fix 的基础上加入 CJK 渲染和其他修正后，生成与 Fix 2.13 文件结构相同的完整 Fix 包。由于没有主动重新生成或修改 `Mod.u`，理论上可以兼容大多数其他 Mod。具体实现与构建记录见 [`docs/技术说明.md`](docs/技术说明.md)。
