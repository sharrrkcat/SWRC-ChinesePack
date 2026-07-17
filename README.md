# SWRC 简体中文汉化包 / Star Wars: Republic Commando Chinese Localization

《星球大战：共和国突击队》（Steam 版）简体中文本地化项目——字幕、界面、菜单全汉化，语音保留英文原声。

**状态**：CJK 渲染已打通（依赖 [CT-cjk-text](https://github.com/sharrrkcat/CT-cjk-text) 的 Mod.dll，计划提 PR 回上游 [SWRC-Modding/CT](https://github.com/SWRC-Modding/CT)）；**自制中文字体（思源黑体，5 字号，GBK CharRemap）已局内实测通过**。正式翻译表已完成，当前阶段为发布前验证与打包。

## 仓库结构

| 路径 | 内容 |
|---|---|
| `docs/README-汉化技术文档.md` | **权威技术文档**：包格式逆向、实验记录、渲染方案、路线图 |
| `docs/高级用法.md` | 高级用户指南：更换字体、调整字号、修改译文 |
| `tools/swrc_package.py` | Unreal 包（版本 159）解析器：导出表 / UFont / DXT5 贴图解码 |
| `tools/font_gen.py` | 中文字体包生成器：TTF/OTF → orbitfonts.utx（DXT5，GBK 键） |
| `tools/make_charset.py` | 字符集生成（ASCII + GB2312 全集） |
| `tools/build_langpack.py` | 正式语言包生成器：translation + catalog → `GameData/System/*.cht` |
| `translation.json` | 完整简体中文翻译表 |
| `reference/export/localization_catalog.json` | 构建所需的机器 catalog；其他导出和审计文件按需再生成 |
| `reference/glossary.md` | 项目术语表与翻译约定 |

所有生成、导入和解码工具均支持通过命令行参数接收输入、输出及临时目录，不依赖固定的游戏安装路径。`build_langpack.py` 在仓库根目录运行时另提供标准 translation/catalog 的便捷默认值；完整命令见 `docs/高级用法.md`。

## 依赖

- [Republic Commando Fix](https://www.moddb.com/mods/republic-commando-fix) ≥ 2.13（含 CJK 渲染支持的版本）
- 字体：思源黑体 Bold（SIL OFL，可再分发）

## 相关链接

- 引擎侧 CJK 渲染实现：https://github.com/sharrrkcat/CT-cjk-text （分支 `cjk-text`）
- 社区 Wiki：https://wiki.swrc-modding.net
