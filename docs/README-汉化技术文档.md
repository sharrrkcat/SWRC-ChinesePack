# 星球大战：共和国突击队（SWRC）中文本地化 — 技术文档

> 最后更新：2026-07-11（文档审查后） ｜ 状态：**CJK 渲染、DXT5 贴图解码、中文字体生成器、中文字体局内实测均已完成**。代码在 fork `sharrrkcat/CT-cjk-text` 分支 `cjk-text`。当前重点：基于已生成的翻译 JSON/catalog 进入正式译文生产（§7.5、§8）
> 工作目录：`.lang\`；本文档在汉化包仓库 `.lang\SWRC-ChinesePack\docs\`（github.com/sharrrkcat/SWRC-ChinesePack）；游戏数据：`GameData\`；完整原版备份：`.originalbackup\`

---

## 1. 项目概述

目标：为 Steam 版 SWRC（虚幻引擎 2.5 定制分支，包版本 159 / licensee 1）制作简体中文本地化，包括字幕、界面、菜单。语音保留英文原声。

当前进度：
- ✅ 文本存放位置、格式、注入机制全部查明并验证（`.int` 可直接新增覆盖，菜单 `XinterfaceCtmenus.int` 已验证可生效）
- ✅ 字体包二进制格式完全破解（UFont、CharRemap、DXT5 贴图页均可解析/写出）
- ✅ 官方日文版的实现方式已解剖（作为参照系）
- ✅ **CJK 渲染全线打通**（2026-07-07）：根因=引擎 ANSI 构建逐字节查表；解法=自编译 Mod.dll detour 四个文本函数做 DBCS 配对（§6、§7）。菜单 + 标题卡/加载画面/提示/简报字幕/局内字幕五处场景全部实证显示汉字。代码：fork `sharrrkcat/CT-cjk-text`,分支 `cjk-text`
- ✅ **中文字体生成器完成并局内实测通过**（2026-07-08）：`tools\font_gen.py` 生成 `orbitfonts-cn.utx`，GB2312 全集测试包菜单/局内字幕无缺字错位。`make_charset.py` 支持 `--slim` 瘦身模式（一级字 ∪ 译文用字 ∪ 常用标点，约 3900 字 / 约 10MB，发布推荐）
- ⏳ 当前阶段：catalog 已生成并经过多轮工具修正，下一步是正式译文生产（§8）；剩余 skipped 项需在正式发布前继续归因或明确白名单化

## 2. 事实速查卡

| 项 | 值 |
|---|---|
| 引擎 | Unreal Engine 2.5 定制（"CT"分支），包版本 **159**，licensee 1 |
| 主程序 | `GameData\System\SWRepublicCommando.exe`（唯一导入 `_ismbblead` 的模块） |
| 文本语言机制 | `System.ini [Core.System] Language=int`；官方日版**不改语言代码，直接覆盖 .int**；Steam 缺失的 `.int` 可新增覆盖包内默认值 |
| 字幕/UI 字体 | 仅 `GameData\Textures\orbitfonts.utx`（5 个字体对象：OrbitBold8/12/15/18/24）；`warfarefonts.utx` 与本地化无关 |
| 必装 mod | Republic Commando Fix 2.13（SWRC-Modding/CT），提供 UCC.exe / ModEd.dll / PropertyOverrides；中文包需含 CJK 渲染支持的 Mod.dll |
| 引擎头文件参考 | `.lang\CT-headers\`（github.com/SWRC-Modding/CT 的克隆） |
| 日文参照包 | `.lang\JapanesePack\`（ModDB "Japanese Patch"，官方日版零售提取） |
| 开发机注意 | 系统 ACP 必须为 936（GBK）。曾开启"Beta: UTF-8 全球语言支持"（ACP=65001），已关闭 |

## 3. 本地化架构

### 3.1 文本分布

| 类别 | 文件 | 规模 | 注入方式 |
|---|---|---|---|
| 剧情字幕 | `System\subtitles_*.int`（25 个） | ~6,300 行 | 直接覆盖 .int；注意日文包编号可能与英文运行时 key 偏移 |
| 关卡目标/提示 | `GEO_/RAS_/YYY_/PRO/DM_/CTF_*.int`（40+ 个） | ~2,000 行 | 直接覆盖 .int；Steam 缺失文件可新增 |
| 加载画面 | `levelloadinginfo.int`、`hints.int` | ~140 行 | 直接覆盖 .int |
| 游戏性文本 | `engine.int`、`ctgame.int`、`ctinventory.int`、`mpgame.int`、`gameplay.int`、`properties.int`、`voicepacks.int` 等 | ~900 行 | 直接覆盖 .int（Steam 版缺的文件可新建，.int 覆盖 .u 内默认值） |
| **菜单文字** | `System\XinterfaceCtmenus.int`（官方日文包已提供） | ~500 条键值 | **直接覆盖 .int**（已实测可替代 PropertyOverrides），无需改 .u |
| 过场视频 | `Movies\*.bik` | — | 可选：RAD Video Tools 压制内嵌字幕版 |

菜单类源码仍保留在仓库 `reference\export\XInterfaceCTMenus\*.uc`（53 个类），用于追溯英文 source、理解运行时结构和必要时生成 fallback。实际发布路线优先生成 `XinterfaceCtmenus.int`，例如：

```ini
[CTAcceptSettingsTimedMenu]
Label.Text="Use these settings?"
ALabel.Text="Yes :"

[CTGraphicsOptionsPCMenu]
Options[0].Items=("LOWEST","LOW","MEDIUM","HIGH","HIGHEST","CUSTOM")
```

### 3.2 菜单 `.int` 直出机制（当前主路线）

关键新结论（2026-07-09）：官方日文包中的 `System\XinterfaceCtmenus.int` 已在 Steam 英文版 + Fix 环境中实测可生效，能够覆盖 `xinterfacectmenus.u` 各菜单类的 localized/default 字段。发布路线因此改为**统一生成 `System\*.int`**，不再把菜单主路径建立在 `PropertyOverrides` 的整结构体覆盖上。

实施注意：
- JSON/catalog 的 target key 必须以英文版运行时会读取的 `.int` 路径为准；日文包只作为官方覆盖索引和参考译文
- `XinterfaceCtmenus.int` 中 `Options[n].Items=(...)` 等数组值应由生成工具负责转为 Unreal 元组语法，翻译 JSON 不应要求用户手写 UE 结构
- 日文 `.int` 中以 `//` 开头的伪键属于导出残留注释，不作为可写翻译项；应进入 audit 报告

### 3.3 PropertyOverrides 注入机制（已验证备用方案，Fix 2.13 提供）

来源已核实（`CT-headers\Mod\Src\SWRCFix.cpp` → `ImportPropertyOverrides()`）：

- 扫描 `System\PropertyOverrides\*.txt`，文件名（去 .txt）作为**类名**传给 `LoadClass`，故必须形如 `包名.类名.txt`（如 `XInterfaceCTMenus.CTMenuMain.txt`）
- 内容为 defaultproperties 风格的 `属性=值` 行，经 `ImportProperties` 应用到**类默认值**（支持结构体、数组 `Prop(0)=`、对象引用 `Font'OrbitFonts.OrbitBold8'`）
- 只能作用于类默认值，不能作用于任意实例；加载失败静默跳过（成功时日志出现 `Dynamic load 包名.类名`）
- 文件读取用引擎 `appLoadFileToString` → **支持 UTF-16 LE with BOM**（已实测），无 BOM 则按"逐字节拉宽"读入（见 §5 R3）

本机制仍有保留价值：可用于临时探针、非 localized 字段覆盖、字体对象切换等高级调试；但发布版菜单文字优先走 `XinterfaceCtmenus.int`，避免整结构体覆盖带来的字段补全和 UE 语法复杂度。

### 3.4 字体系统

- 菜单/字幕全部引用 `Font'OrbitFonts.OrbitBoldN'`（N=8/12/15/18/24，游戏内按分辨率/用途选字号）
- **美版**：每字体 1 页贴图、256 个字形直查（`IsRemapped=0`，字符码即索引），对象恰好 4366 字节
- **日版**：每字体多页贴图（8 号 5 页 … 24 号 21 页），子集字形（OrbitBold15 共 1438 个字形），`IsRemapped=1`，`CharRemap` 1378 项，**键 = Shift-JIS 双字节码值**（实证：`序`→0x8F98 在表中，Unicode 0x5E8F 不在）
- 日版第 0 页混有 ASCII 和 200 个 SJIS 全角标点键（0x8140 起）——可用于"同页 CJK 探针"（§7）

## 4. 二进制格式详解（已实证，可直接照此读写）

### 4.1 包文件头（偏移 0 起）

```
u32  签名 0x9E2A83C1
u16  文件版本 = 159
u16  Licensee 版本 = 1
u32  PackageFlags
u32  NameCount      u32 NameOffset
u32  ExportCount    u32 ExportOffset
u32  ImportCount    u32 ImportOffset
（其后为 GUID/Generations，读表不需要）
```

### 4.2 紧凑索引（Compact Index，UE1/2 标准）

首字节：bit7=负号，bit6=后续标志，bit0-5=值低 6 位；后续字节：bit7=后续标志，bit0-6=值（左移 6、13、20…）。

### 4.3 名称表 / 导入表（标准 UE2）

- 名称项：`CI 长度（含 \0）+ 字节串 + u32 旗标`
- 导入项：`CI ClassPackage名 + CI ClassName名 + i32 Outer + CI Object名`
- 对象引用：正数 = 导出表 1 基索引；负数 = 导入表（`-idx-1`）；0 = 无

### 4.4 导出表 — ⚠ RC 定制布局（与标准 UE2 不同！）

```
CI  ClassIndex        （对象引用）
CI  SuperIndex
i32 PackageIndex      （Outer，0=包根）
CI  X                 ★ RC 特有字段：贴图对象为 0；Font 对象观测值 = 其首页贴图的导出索引
CI  ObjectName        （名称表索引）
u32 ObjectFlags       （典型：公开对象 0xF0004，内嵌贴图 0x70000）
i32 SerialSize        ★ 定长 i32，非 CI
i32 SerialOffset      ★ 定长 i32，非 CI（标准 UE2 是"CI 且 size>0 才有"，此处始终存在）
```

> CT-headers 里 `UnLinker.h` 的 FObjectExport 是标准布局，**与实际文件不符**——以本节实测布局为准（在 orbitfonts.utx 上 10/10 项完美解析，数据区连续无缝隙）。

### 4.5 UFont 对象序列化（导出数据区内）

```
0x00                              ← 属性表：仅一个 None（无脚本属性）
CI  字形数 N
N × FFontCharacter（17 字节）:
    i32 StartU, i32 StartV, i32 USize, i32 VSize, u8 TextureIndex
    ★ TextureIndex 在 CT-headers 中被注释掉，实际存在（stride=17 已实证）
CI  贴图页数 T
T × CI 对象引用（指向本包内 Texture 导出项）
i32 Kerning                       （美/日版均为 1）
CI  CharRemap 项数 M
M × (u16 键, u16 字形索引)         （TMap 序列化；键非严格有序）
u32 IsRemapped                    （美版 0，日版 1）
```

### 4.6 贴图对象（✅ 已完全解码，2026-07-08；美版 5 + 日版 56 个样本全部解析通过，尾部零剩余）

```
属性表（与 UFont 不同，非空）：每项 = CI 名称索引 + u8 信息字节 + 载荷
    信息字节低 4 位 = 类型：1=byte(载荷1B) 2=int(载荷4B) 3=bool(载荷1B★)
    ★ RC 布尔属性带 1 字节载荷，与标准 UE2（值存 bit7、无载荷）不同
    字体页实测属性（顺序固定）：bAlphaTexture=0, bNoRawData=0, LODSet=0(byte),
        Format=8(byte), UBits, VBits(byte), USize, VSize, UClamp, VClamp(int)
    以名称索引 None 结束
u8   mip 数（字体页均为 1）
每 mip：
    u32 数据尾绝对文件偏移（= 本 mip 数据末字节的下一位置，写包时需回填）
    CI  数据大小
    数据本体
    i32 USize   i32 VSize   u8 UBits   u8 VBits
```

**像素格式：Format=8 = TEXF_DXT5**（枚举见 `CT-headers\ClassInfo\Native\Engine\BitmapMaterial.txt`）。DXT5 恰 1 字节/像素（4×4 块 16B），验证：512×512→262144B；256×1 页→1024B（块行数上取整到 4：64 块×16B）。无调色板对象（非 P8）。

**字形像素构成**（日/美版一致）：RGBA 中 RGB≈亮度（字形主体白、外部黑）、A=覆盖度（含抗锯齿边缘）；黑色 RGB + 中间 alpha 形成自然深色描边。生成器照此产出：渲染灰度字形 → RGB=A=灰度值 即可复现原版观感。

**读写工具**：`tools\swrc_package.py` 的 `tex` 命令可解码任意页为 PNG（Pillow bcn 解码器，参数 3=DXT5）。写出侧需自实现 DXT5 编码（Pillow 不支持编码；白字+alpha 场景颜色端点恒白/黑，仅 alpha 块需认真插值，实现简单）。

## 5. 实验记录（时序）

环境：Steam 版 + Fix 2.13 + 日文 `orbitfonts.utx`（已替换）+ ACP=936。观察点：主菜单第一/二按钮（PropertyOverrides 覆盖 `CTMenuMain` 的 `MenuOptions(0)/(1)`）。

| # | 探针（编码 / 内容） | 显示结果 | 结论 |
|---|---|---|---|
| R1 | UTF-16 BOM / `UTF16中文測試` | `UTF16` + 空白 | UTF-16 解析✓、PropertyOverrides✓、结构体覆盖✓；CJK 空白 |
| R2 | UTF-16 / A=`行隊撃敵`（日文剧本高频字，必在字体内）；B=`擔杮岅`（GBK 反解码乱码，转 ANSI 后=日本語的 SJIS 字节） | A、B 均空白（字母可见） | 排除"子集缺字"；排除"加载时转 ACP 字节+字节对查表"；**无低字节截断**（否则 行→0x4C 应显示"L"） |
| R3 | ANSI 无 BOM / A=原始 SJIS 字节 `93 FA 96 7B 8C EA`；B=原始 GBK 字节 | A 显示 `A  {  `（0x7B 单独现形！）；B 空白 | **ANSI 文件逐字节拉宽，无 DBCS 配对**（若有配对 0x7B 会被吞入字对）；≥0x80 单字节无字形 |
| R4 | 官方日版 `LevelLoadingInfo.int`（SJIS）装入，看加载画面 | `N`、`{` 等零散 ASCII + 空白 | `.int`/Localize 路径同样逐字节、无配对（已还原原文件） |
| R5 | UTF-16 / `C` + `鏺陻質`（U+93FA/U+967B/U+8CEA，**码位=日文字体 CharRemap 中真实存在的键**） | 仅 `C`，后空白 | **码位并未直达 CharRemap**——查表前存在过滤/变换 |
| R6 | UTF-16 / 两按钮均以 `MenuFont=Font'OrbitFonts.OrbitBold8'` 强制字体；A=`D`+chr(0x8141)+chr(0x8142)（**第 0 页**键，与正常渲染的 ASCII 同一张贴图）；B=`E`+chr(0x93FA)+chr(0x967B)（第 3 页键） | A、B 的 CJK 均空白；字号明显变小（证明字体覆盖生效、OrbitBold8 确在使用） | **H-A（贴图页失败）被排除**：同页字形也不渲染 → **过滤发生在字形查表之前**（R6 定论） |
| R7 | **静态分析**（非运行实验）：`CT-headers\Engine\Engine.c`（Engine.dll 的 Hex-Rays 反编译，随仓库自带）、`Engine.dll demangled names.txt`、exe/dll 导入导出表解析 | 见下"R7 定论" | **根因定性**，纯字体方案正式判死 |

**R7 定论（根因）**：
- `Core\Inc\UnVcWin32.h:86`：`typedef ANSICHAR TCHAR` —— **本构建引擎是 ANSI 版**，FString/Localize/绘制全链路为 8 位字节串。§5 旧"事实 1"（UTF-16 文件→内存保持 16 位码位）系误判：UTF-16 文件在装载时即被折算成字节串。
- `UCanvas::WrappedPrint`（Engine.c 200342，实址 Engine.dll）：绘制循环 `v24 = *(_BYTE*)...` **逐字节取字符**，CharRemap TMap 查表键恒 ≤0xFF；`FCanvasUtil::DrawString`（370756）同样逐字节，且 remap 结果处还有 `(unsigned __int8)` 截断；`UFont::GetCharSize`（117988）入口即 `(unsigned __int8)a3` 截断。`UFont::RemapChar` 本身干净。
- 全 Engine.dll **无任何 DBCS 配对/代码页调用**（无 `<<8` 组键、无 MultiByteToWideChar/_ismbblead）。
- exe 中 `_ismbblead` 的两处调用点（0x40cba7/0x40cd9c）均为 **CRT 命令行解析**（引号 0x22 处理），与渲染无关——H-B、"exe 有 MBCS 绘制代码"排除。
- 推论：官方日版必然自带**修改过的 Engine.dll**（含 SJIS 双字节配对）；ModDB 日文包不含 dll，故在 Steam 版上 CJK 必然空白（与 R1–R6 全部吻合）。
- **可行解**：以下 4 个函数全部按名字从 Engine.dll 导出，可由 native Mod.dll `GetProcAddress` + inline detour：
  - `?WrappedPrint@UCanvas@@AAEXHAAH0PAVUFont@@MMHPBD@Z`（换行+量宽+发绘制，菜单/字幕主路径）
  - `?DrawString@FCanvasUtil@@QAEHHHPBDPAVUFont@@VFColor@@MM_N@Z`（字形发射）
  - `?GetCharSize@UFont@@QAEXDAAH0@Z`、`?RemapChar@UFont@@QAEGG@Z`（其余量宽路径）

已确认的管线事实：
1. ~~UTF-16 LE(BOM) 文件→字符串保持真实 16 位码位~~ **R7 修正：引擎 FString 为 8 位字节串**；UTF-16 文件装载时折算为字节（具体折算规则已无关紧要——最终方案文本将以 GBK 字节存放）
2. ANSI 文件→字节原样进入 FString，任何系统代码页都不参与（引擎 dll 无任何代码页 API；exe 的 `_ismbblead` 仅用于 CRT 命令行解析）
3. 美版字体 0x80–0xFF 区字形为空白矩形 → R1–R4 的"空白"与"查不到/被滤"均兼容
4. R5+R6+R7 定论：绘制循环逐字节迭代，**>0xFF 的查表键在 ANSI 构建下根本无法产生**
5. 附带发现：`MenuFont` 可被 PropertyOverrides 覆盖（R6 字号变化证实）→ 必要时可让 UI 指向自定义字体对象

## 6. 根因与解决方案（R7 定性，取代原假设表）

**根因**：Steam 版 Engine.dll 为 ANSI 构建，文本绘制（WrappedPrint/DrawString/GetCharSize）逐字节迭代并以单字节值查 CharRemap。旧假设归档：H-A 假（R6）、H-B 假（`_ismbblead` 是 CRT 命令行解析）、H-C 部分真（多处 u8 截断，但本质是整个管线就是 8 位的）、H-D 变体真（日版靠改过的 Engine.dll，不是 exe）。

**选定方案 —— native Mod.dll detour（仿日版机制，GBK 双字节配对）**：
1. 文本一律以 **GBK 编码 ANSI 文件**（无 BOM）保存（.int 与 PropertyOverrides 同理），字节原样进入 FString——此链路 R3/R4 已实证
2. 自制字体包 CharRemap 以 **GBK 双字节码值为键**（如日版用 SJIS 键），`IsRemapped=1`
3. 写 native Mod.dll（VS2022 + CT.sln，参考 `Mod\Src\`）：加载时 `GetProcAddress` 拿到 §5 R7 列出的 4 个 Engine.dll 导出函数，inline detour 重写字符迭代——遇 GBK 首字节（0x81–0xFE）且后随合法尾字节时组成 16 位键 `(lead<<8)|trail` 再查 CharRemap，其余逻辑照抄反编译原文（Engine.c 有完整参照）
4. 兜底：若 detour 与 Fix 的 ModRenderDevice 冲突，退而直接补丁 Engine.dll（非 exe），但优先 detour（免改官方文件、与 Fix 分发生态一致）

## 7. 渲染方案实现记录（已打通，2026-07-07 实证）

**实现**：`CT-headers\Mod\Src\CJKText.cpp`（Fix 源码树内新增，`InitSWRCFix()` 末尾调用 `InitCJKText()` 安装钩子）。用 `appGetDllExport` + `RedirectFunction`（5 字节 JMP，无 trampoline——四个函数均整体重写，不回调原函数）detour Engine.dll 的：

| 函数（按名导出） | 角色 | 验证情况 |
|---|---|---|
| `UCanvas::WrappedPrint` | 换行打印（字幕/HUD/法律页；execDrawText 终点） | 法律页 + **局内全场景 CJK 实证** ✅ |
| `UCanvas::ClippedPrint` | 单行裁剪打印——**菜单按钮的实际路径**（exe 内菜单原生代码经虚函数调用） | 主菜单探针"OK日本語"实证 ✅ |
| `UCanvas::ClippedStrLen` | 单行量宽（菜单 MaxSizeX/省略号布局依赖） | 随 ClippedPrint 生效 |
| `FCanvasUtil::DrawString` | 工具路径（居中量宽、`&` 快捷键下划线） | 已挂钩，暂未观察到调用方 |

**局内验证（2026-07-07，SJIS"日本語"探针，五处全部显示 ✅）**：开场标题卡（geo_titlecard.int）、加载画面标题+正文（LevelLoadingInfo.int）、加载提示（hints.int）、简报字幕（subtitles_geo_01briefing.int）、局内字幕（subtitles_geo_01.int）。**菜单+局内文字全线打通，C++ 侧封版**（`WrappedIconPrint`/`UHelmet::DrawTextInfo` 未挂钩也未表现出需要,遇到具体场景缺字再补）。历史探针备份仍存放于仓库 `probe-backup\`，仅用于追溯实验，不作为当前测试区还原说明。

字形发射：WrappedPrint/ClippedPrint 经 **UCanvas vtable[32]（DrawTile 虚函数）**；DrawString 经导出的原版 `FCanvasUtil::DrawTile`。

**实现要点（踩坑记录）**：
- DBCS 配对：首字节 0x81–0xFE 且尾字节 0x40–0xFE（排除 0x7F）→ 键 `(lead<<8)|trail`；GBK 与 SJIS 范围同时兼容
- TArray 的 Num 是 **29 位位域**（高 3 位为分配标志），读数必须 `& 0x1FFFFFFF`（反编译中的 `8*x>>3` 即此掩码）
- FFontCharacter 内存 stride=**20**（TextureIndex 字节在 +16，CT 头文件把它注释掉了，勿用头文件的 16 字节布局）
- UFont 内存布局：+40 Chars.Data / +44 Num / +48 Textures.Data / +52 Num / +56 CharRemap 对表(8B/项:Next i32,Key u16,Value u16) / +64 Hash / +68 HashCount / +72 IsRemapped / +76 Kerning
- FColor 内存序 **B,G,R,A**；`FCanvasUtil::DrawString` 在 `GIsOpenGL` 时需交换 R/B
- UCanvas 头文件（UnCamera.h）数据成员与二进制一致（Viewport@+132、pCanvasUtil@+136），虚表次序不可信——DrawTile 用显式 vtable[32]
- 原版三处 `(unsigned __int8)` 截断（GetCharSize 入口、两个绘制循环的 remap 结果）在重写中全部移除——remap 结果 >255 的字形索引（日版字体最多 1437）需要完整通过
- 源文件必须存 **UTF-8 BOM**（CP936 开发机上 MSVC 否则报 C4819 转错误）
- 构建：`MSBuild Mod\Mod.vcxproj -p:Configuration=Release -p:Platform=Win32 "-p:SolutionDir=<CT-headers 绝对路径>\\"`（VS2022/v143）,输出 `.lang\GameData\System\Mod.dll`,复制到 `GameData\System\`;官方 2.13 备份:`.lang\Mod.dll.official-2.13.bak`
- 诊断:四个钩子各有前 12 次调用的 `CJKText: 函数名("文本")` 日志(定位文本路径用,发布前可移除)

**待办（渲染尾工）**：
1. ~~字幕/HUD/加载画面路径实测~~ ✅ 已全部实证（见上）
2. ~~`EnableCJKText` 配置开关~~ ✅ 已完成（`Mod.u` 需与新版 `Mod.dll` 配套重编；旧脚本类不含属性时会读不到 config）
3. 发布前打磨：跟踪日志移除或降噪、`&` 字面量行为核对、构建产物版本号/说明整理
4. 版本控制：fork = `github.com/sharrrkcat/CT-cjk-text`,分支 `cjk-text`;终局建议提 PR 回上游 SWRC-Modding/CT（日文社区同样受益）,汉化包只声明依赖"Fix ≥ 某版本"

## 7.5 字体与文本生成工具状态

1. ~~解码贴图对象格式（§4.6）~~ ✅ 完成（DXT5，见 §4.6）
2. ~~中文字体生成器~~ ✅ 完成（2026-07-08）：`tools\font_gen.py`（渲染思源黑体 → numpy 向量化 DXT5 编码 → 写 .utx；CharRemap 键=GBK 双字节、IsRemapped=1；字号→行高按日版实测 8→13/12→16/15→20/18→24/24→29，全角=行高×行高，基线锚 0.88em）。`tools\make_charset.py` 产字符集（默认=ASCII+GB2312 全集 7573 字；`--slim` 瘦身模式=GB2312 一级字 ∪ translation.json 用字 ∪ 常用标点，约 3900 字，发布推荐）。生成的 `orbitfonts-cn.utx`（全集约 19.8MB / 瘦身约 10MB）已通过解析器全量往返校验；曾以 GBK"中文测试"探针完成菜单+局内验证。字体文件在 `.lang\fonts\SourceHanSansCN-Bold.otf`（OFL，从 adobe-fonts/source-han-sans release 下载）。✅ **局内实测通过（2026-07-08）：菜单两按钮（含全角标点、弯引号）+ 局内字幕全部正常，无缺字/错位，字号观感合适**。2026-07-10 增加可选 `--latin-source <英文版 orbitfonts.utx>` 混合模式：仅复用英文版 `0x20-0x7E` ASCII glyph 的原始宽高和 RGBA 像素，中文/GBK 字符仍由 `--font` 渲染；未传该参数时默认纯 TTF/OTF 管线不变。高级用户自定义字体/字号/译文见 `docs\高级用法.md`
3. ~~翻译索引/catalog 生成工具~~ ✅ `tools\make_translation_json.py` 已建立当前翻译源：从日文 `JapanesePack\System\*.int` 取得覆盖索引，从英文运行时 `GameData\System\*.int`、`GameData\System\*.u`、`GameData\Properties\*.u`、`GameData\Maps\*.ctm` 追溯英文 source，可选读入 `TranslationPackFormOnline\German Files\*.det` 作为德语参照；输出 `translation.json`（schema 2）+ `reference\export\localization_catalog.json`（schema 1）+ audit/skipped 报告。重新生成默认按 `(group, note, en)` 保留已有 `zh_CN`，只有显式 `--reset-translations` 才清空译文；默认 strict skipped，若仍有 skipped 会失败，审查期才使用 `--allow-skipped`
4. ~~语言包生成工具~~ ✅ `tools\build_langpack.py` 已切到 catalog 驱动：读取用户翻译 JSON（schema 2）+ 机器 catalog（schema 1）→ `build\GameData\System\*.int` + manifest；菜单也输出 `XinterfaceCtmenus.int`，不生成 `PropertyOverrides`。默认要求所有 `zh_CN` 非空且 GBK 可编码；`--allow-untranslated` 仅作开发期英文 fallback，并只对 fallback 英文做最小 GBK 兼容规范化
5. 进入汉化实施（§8）：译文输出一律 GBK 编码 ANSI 文件、无 BOM；翻译源数据采用 UTF-8 JSON

## 8. 汉化实施路线图（当前阶段）

1. **翻译索引**：官方日文包 `JapanesePack\System\*.int` 作为覆盖索引；当前英文版 + Fix 的 `GameData` 作为英文 source 权威；可选的 `TranslationPackFormOnline\German Files\*.det` 提供德语参照（`de` 字段）。`voicepacks.int` 是真实缺失项，英文默认值来自 Steam `GameData\Properties\voicepacks.u` 的 `GenericClone` class default，发布时生成到 `GameData\System\voicepacks.int`；`Winddrv.int` 与已映射的 `WinDrv/windrv.int` 重复，不作为当前补入目标
2. **数据结构**：采用机器 catalog 与用户翻译 JSON 分离；catalog 保存 `.int` 路径、value 类型、locked/control 项、字幕编号重映射、EN-only passthrough 等构建细节，用户 JSON 只保留分组、id、note、en、jp、de、zh_CN。当前审查版约 9,393 个翻译条目、147 个 catalog 输出文件；剩余 skipped 约 1,684 条，记录在 `reference\export\localization_jp_only_skipped.json`。用户 JSON 示例：

```json
{
  "schema": 2,
  "XinterfaceCtmenus.CTAcceptSettingsTimedMenu": {
    "123": {
      "note": "Label.Text",
      "en": "Use these settings?",
      "jp": "この設定を使用しますか?",
      "de": "",
      "zh_CN": ""
    }
  }
}
```

3. **关键映射规则**：
   - 输出 key 必须以英文运行时 key 为准；日文字幕 `.int` 的 `SubtitleText[n]` / `SubtitleSound[n]` 编号可能相对英文偏移，需按 sound id 对齐
   - `SubtitleSound`、`CreditsLine` 控制行、`Object+=` / `Preferences+=`、EN-only passthrough 等非翻译控制项由 catalog 锁定，不要求用户翻译；`CreditsLine*` 中 `jp == en` 的人名/署名也按 literal 保留
   - `shared.enjp` 是按 `(en, jp, de)` 合并的共享译文组，同组只能有一个中文译文；后续若条目离开 shared，生成器会按 `(en, jp, de)` 回填旧译文
   - `XinterfaceCtmenus.int` 是菜单主输出，不再生成菜单 `PropertyOverrides` 作为发布默认路径
4. **索引生成工具**：`tools\make_translation_json.py` 默认读取既有 `translation.json` 并保留同签名条目的 `zh_CN`，因此正式翻译开始后可重复跑生成器做 source 修正；若旧条目匹配但 `jp` 发生变化，保留 `zh_CN` 并在 audit 记录 `preserved_translation_with_jp_change`。默认 skipped 严格失败，防止漏项静默进入正式翻译；审查期需要保留当前漏项时显式加 `--allow-skipped`，从零重建才加 `--reset-translations`。默认构建验证写入临时目录，不会清理真实 `build\`
5. **语言包生成工具**：`tools\build_langpack.py` 默认读取 `translation.json` 和 `reference\export\localization_catalog.json`；可用 `--json` / `--catalog` / `--out` 指定临时输入输出。默认要求所有 `zh_CN` 非空，且输出必须 GBK 可编码；`--allow-untranslated` 只用于开发期抽样，空译文会回退英文，并仅对 fallback 英文中的少量非 GBK 字符做兼容替换。JSON 重复 key 会直接报错；bare 样式遇到 `=`、引号、首尾空白、`(` 或 `"` 开头会自动升级 quoted 并写入 manifest 计数。工具只输出 `build\GameData\System\*.int` 和 manifest，不直接写入游戏目录
6. **字符集与字体**：发布版使用 `make_charset.py --slim` 生成瘦身字符集（GB2312 一级字 ∪ translation.json 用字 ∪ 常用标点，约 3900 字），再重新生成 `orbitfonts.utx`（约 10MB）；开发期可不带 `--slim` 使用 GB2312 全集（7573 字，约 19.8MB）
7. **测试与发布**：至少覆盖新战役全流程、加载/标题卡/提示/字幕、全部菜单与设置页、存读档界面；发布包复制 `System\*.int + Textures\orbitfonts.utx + CJK Mod.dll/Mod.u`，标注 Fix / CJK 依赖

## 9. 文件与工具清单

```
.lang\
  SWRC-ChinesePack\           ← 汉化包仓库（github.com/sharrrkcat/SWRC-ChinesePack，最终发布物）
    docs\README-汉化技术文档.md ← 本文档
    tools\swrc_package.py     ← 包解析器（逆向成果的代码化：导出表/UFont/DXT5 贴图解码）
    tools\font_gen.py         ← 中文字体包生成器（TTF/OTF → orbitfonts.utx，DXT5 字体页）
    tools\make_charset.py     ← 字符集生成器（默认 GB2312 全集；--slim 瘦身=一级字 ∪ 译文用字 ∪ 常用标点）
    tools\make_translation_json.py ← 翻译索引/catalog 生成器（JP .int + 英文 GameData source → translation.json + localization_catalog/audit/skipped）
    tools\build_langpack.py   ← catalog 驱动语言包生成器（translation.json + localization_catalog.json → build\GameData\System\*.int）
    tools\localization_common.py ← 共享模块（FALLBACK_REPLACEMENTS / normalize_fallback_text，被 make_translation_json 和 build_langpack 导入）
    tools\test_localization_tools.py ← unittest 测试套件（字体/翻译 JSON/构建管线往返校验）
    translation.json           ← 用户翻译表（UTF-8 JSON；正式译文写入 zh_CN）
    reference\export\XInterfaceCTMenus\ ← 53 个菜单类 .uc 源码（ucc batchexport 产物）
    reference\export\localization_catalog.json ← 机器 catalog（输出路径、键、类型、模板、控制行）
    reference\export\localization_audit.json   ← 生成审计信息（source、导出、统计、build validation）
    reference\export\localization_jp_only_skipped.json ← 未进入 catalog 的 JP-only/skipped 明细
    reference\export\         ← catalog、审计报告、必要源码导出的归档位置；除已保留的菜单参照源外，后续批量导出的 `*.uc` 中间文件已按 gitignore 过滤噪音
    probe-backup\             ← 探针实验替换掉的原版 .int 备份
  JapanesePack\               ← 日版参照（System/Sounds/Textures；ModDB 下载物，不入库）
  fonts\SourceHanSansCN-Bold.otf ← 思源黑体（OFL，字体生成器输入）
  orbitfonts-cn.utx           ← 字体生成器产物（已实测可装入游戏）
  orbitfonts-jp.utx.bak       ← 日文版字体备份
  CT-headers\                 ← SWRC-Modding/CT 仓库克隆（引擎头文件+Fix源码，独立版本管理）
    Engine\Engine.c           ← Engine.dll 完整 Hex-Rays 反编译（管线逆向的核心参照）
    Mod\Src\CJKText.cpp       ← CJK 渲染钩子（本项目新增，构建进 Mod.dll）
  GameData\System\Mod.dll     ← MSBuild 输出（构建时创建；目录可能不存在）
  Mod.dll.official-2.13.bak   ← 官方 Fix 2.13 的 Mod.dll 备份
.originalbackup\              ← 完整原版备份（还原点；当前实施以已清理的英文版+Fix 游戏目录为 source 权威）
GameData\                      ← 当前英文版 + 官方 Fix 2.13 测试区；具体文件状态会随实验变化，不再在本文档硬编码探针状态
```

工具链：
- `UCC.exe`（Fix 附带）：`batchexport <pkg> Class uc <目录>` 导源码；`batchexport <map.ctm> Object t3d <临时目录>` 可导出关卡对象属性用于 source 溯源；`fontupdate` 可更新字体单页贴图；`make` 编译脚本包
- `ModEd.dll` + unrealed：修复版编辑器（本项目暂未用到 GUI）
- Python 3.14（`py`）：所有解析/生成脚本；编码转换注意用 `-X utf8` 避免控制台 GBK 报错

### 还原/清理原则

当前用户已重新整理测试区为完整英文版 + 官方 Fix 2.13。后续发布工具默认只输出到仓库 `build\`，不直接写游戏目录。若需要还原用户安装环境，优先使用 Steam 验证完整性或发布包 manifest 精确清理；不要删除整个 `System\PropertyOverrides\` 目录，因为 Fix 自带文件也在其中。

## 10. 参考链接

- 日文补丁（含官方日版文本/语音/字体）: https://www.moddb.com/downloads/star-wars-republic-commando-japanese-patch
- Republic Commando Fix: https://www.moddb.com/mods/republic-commando-fix
- SWRC-Modding/CT 仓库: https://github.com/SWRC-Modding/CT
- 社区 Wiki: https://wiki.swrc-modding.net ｜ Discord: https://discord.gg/3u69jMa
- 3DM/游侠专区（确认无现成汉化）: https://www.3dmgame.com/games/starwrc/
