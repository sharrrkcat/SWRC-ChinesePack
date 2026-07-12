# credits 校对记录 — 不确定条目与决策

> 2026-07-12 校对。本区块 194 条(全部待校),共修订 5 条。人名/公司名按项目规则保留英文,故绝大多数条目零改动。
> **里程碑:本区块修复后,`build_langpack.py` 全库构建验证首次完整通过(147 个输出文件)。**

## 修订明细

| 条目 | 原文/原译 | 修订 | 原因 |
| --- | --- | --- | --- |
| #141 | (P) & © LUCASFILM LTD. & TM. | © → (C) | GBK 不可编码(构建阻塞项);跟随官方 jp 版写法 (C) |
| #671 | COPYRIGHT ©1995-2003 JEAN-LOUP | © → (C) | 同上(zlib 版权行) |
| #531 | HERB AND PHIL BOSSÉ | É → E | GBK 不可编码;人名降级为 ASCII(jp 版同样无法表示,显示为乱码) |
| #417 | PHILLIP BERRY, 首席 | PHILLIP BERRY，负责人 | LEAD 在制作人员名单中指小组负责人;逗号全角 |
| #653 | VERY SPECIAL THANKS→最特别鸣谢 | 最诚挚的鸣谢 | 与 SPECIAL THANKS=特别鸣谢 区分,"最特别鸣谢"生硬 |

## 保留英文的决策(不改)

- 全部人名(含 PERSONAL THANKS 中的昵称/家庭条目,如 THE PIZZA GUY、THE MAKERS OF ENERGY DRINKS、COWBELLS AND UNDERACHIEVERS 等玩笑致谢)——视同人名整体保留,不做意译。
- 公司/工作室/地名条目:HAMAGAMI / CARROLL, INC.、BAYSIDE ENTERTAINMENT、SKYWALKER SOUND、EPIC GAMES、PRIMA GAMES、AUCKLAND AUDIO 等。
- zlib 许可证声明(#668-672)保留英文原文(法律文本)。

## 待复核(不确定)条目

| 条目 | en | 现译 | 疑点 |
| --- | --- | --- | --- |
| #484 | IS LIAISON | 信息系统联络(未改) | IS=Information Systems 推断;若实为 LucasArts 内部其他含义需修正 |
| #496 | EXTRAS & ATTRACT FEATURETTES | 花絮与宣传短片(未改) | ATTRACT=街机吸引模式短片,意译为宣传短片 |
| #653 | VERY SPECIAL THANKS | 最诚挚的鸣谢 | 措辞可再酌("非常特别鸣谢"等) |

## 说明

- 本区块 jp 列与 en 存在系统性错位(jp 是移位后的下一节内容,且混入 Scale=0.8 等控制行残留),不可作为参照;以 en 为准。
- 控制行(Scale=、空行)由 catalog 锁定,不在翻译 JSON 中。
