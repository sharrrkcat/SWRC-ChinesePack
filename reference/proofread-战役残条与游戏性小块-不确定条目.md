# 战役残条+游戏性小块 校对记录 — 不确定条目与决策

> 2026-07-13 校对/精翻。覆盖区块:subtitles_ras_02、RAS_02C/02D/04B、YYY_35A/35C、ctgame、gameplay、ctcharacters、xmaps、xgames,共 237 条(其中 PS4 锁定约 130 条,待校 107 条),修订 14 条(含 shared.enjp 1 条同步)。

## 修订要点

- **DISARM 统一为 PS4 官方"卸除"**:ctgame.DisarmTrap 官方译"按住@卸除";YYY_35A.DisarmTrap6(原"解除")与 shared.enjp#100802(原"拆除")均已统一为"按住@卸除"。后续区块 DISARM=卸除。
- **FOV 对齐 PS4**:RAS_02C.SubActionFOV0 保留英文改为官方"视场角"。
- **ctgame 死亡消息精修**:Ballistic"打了个对穿"(punched a hole through)、Energy"轰杀"(与 Explosion"炸飞"区分,原两者同词)、Fire"烧成了灰"(incinerated)、Stun 自杀行"把自己击晕了"(按 jp"気絶した"语义,en 是通用 killed himself 模板)。
- **xgames 模式简介**:死亡竞赛"every being for themselves"原误译"各为其主"→"人人各自为战";团队/夺旗简介润色(太空尘埃/绝不留情)。
- **xmaps 地图简介**:"制压"错字→"压制";Episode III"第三集"→"电影第三部";proving ground"训练场"→"试炼场";KAM_ZeroG 结尾"混乱的混战"→"混乱的自由混战"。

## 待复核(不确定)条目

| 条目 | en | 现译 | 疑点 |
| --- | --- | --- | --- |
| ctgame.CTDamageStun#2 | %o killed himself. | %o把自己击晕了。 | en 是通用自杀模板,jp 按 Stun 语义译"气绝";若实测 Stun 伤害确会致死,应改回"%o自杀了。" |
| RAS_02D.FlashBangBox1 | Flashbang Detonators | 闪光雷管(未改) | **术语表与 PS4 冲突**:术语表=闪光雷管,PS4 shared 同名条目(#100710,锁定)="闪光弹雷管"。按术语表执行,两者将在游戏内并存,待官方错译统一处理时定夺 |
| ctcharacters.CTTeamClone/Trandoshan | Republic / Trandoshan | 共和国 / 特兰多沙人(未改) | TeamName 用于"is now on X"拼接及计分板;shared 的 CloneMsg/TrandoshanMsg 为"共和国队/特兰多沙人队",两组字段用途不同保持现状 |
| xmaps.DecoText#7 | Run the gauntlet | 冲过封锁线(未改) | 习语意译 |
| xmaps.DecoText#3/#5 | catwalks | 栈道(未改) | 舰内悬空走道,也可译"猫道";取通俗"栈道" |
| xgames.DecoText#5 | Advance your flag into your enemy's base | 将旗帜推进至敌方基地(未改) | 突击模式确为"带己方旗进攻敌方基地",en 无误,与 subtitles_all_mp #2960 的说明一致 |

## PS4 锁定条目中的观察(仅记录,不改)

- subtitles_ras_02#2957 "This keeps getting better and better."(反讽)→官方"情况真是越演越佳。"——中文反讽感弱,统一处理官方错译时可复查。
- subtitles_ras_02#3030 "Blast!"→"该死！"✓(星战咒骂语,官方处理正确,后续区块沿用)。

## 新增官方风格基准

- DISARM=卸除;FOV=视场角;Blast!(咒骂)=该死!;battle droid dispenser=战斗机器人派遣器;detention block/center=扣押区/拘留中心;rendezvous point=会合点;jamming device/signal jammer=干扰装置/信号干扰器;scavs=拾荒者;IED=临时爆炸装置
