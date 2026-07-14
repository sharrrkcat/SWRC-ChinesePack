# properties 校对记录 — 不确定条目与决策

> 2026-07-13 校对/精翻。本区块 109 条(55 条 PS4 锁定 + 54 条待校),共修订 16 条。武器/装备名逐条对照术语表核验,全部合规。

## 修订要点

- **MessageNoAmmo 全部对齐 PS4 官方**:同一武器的 SP 版(PS4 锁定)与 MP 版(待校)此前措辞不一(不足 vs 耗尽),已统一为官方口径——out of ammo=弹药不足、out of cartridges=弹夹不足、out of charges=炸药不足、out of Homing Rocket shells=制导导弹不足(共 8 处)。
- **死亡消息 "blasted %o with X"**:原译"击毁"(机器损毁语感,%o 是玩家/角色)→"轰杀",与 ctgame.CTDamageEnergy 基准一致(5 处)。
- **Ballistic 系与 ctgame 对齐**:punched a hole through="把%o打了个对穿"(2 处);punched several holes="打成了筛子"(与 Shotgun 版"打成了筛子"同修辞,en 亦是同族表达)。

## 术语表合规确认(未改,列出备查)

- 别名统一:SMGPickupMP "Trandoshan Mercenary SMG"=ACP连发炮、TrandoshanRifleMP "Heavy Machine Gun"=LS-150重型ACP连发炮、TrandoshanRifleMPAmmo "LS-150 Heavy AP Repeater Gun"(en 笔误 AP)=LS-150重型ACP连发炮——均按术语表"别名不另译为不同武器"执行;与 PS4 shared #100712"特兰多佣兵冲锋枪"的冲突已在 shared 记录中登记,归入最后统一处理。
- 型号规范:ConcussionRifle→LJ-50震荡步枪、DC17mSniper→DC-17m狙击附件、DC15s Side Arm Blaster→DC-15s佩枪爆能枪。
- Cell=电池(跟随 PS4 "LJ-50 Concussion Rifle Cell=LJ-50震荡步枪电池")。

## 待复核(不确定)条目

| 条目 | en | 现译 | 疑点 |
| --- | --- | --- | --- |
| DC17mBlasterAmmoMP#2 | DC17m Blaster Modified | DC-17m爆能枪改装版(未改) | MP 弹药类的 ItemName,en 本身怪异("Modified");语义待游戏内确认 |
| CTDamageExplosionEMPPulse / CTDamageEMPPulse | electrocuted %o with an EPB | %k用EPB电死了%o。(未改) | EPB 为识别码保留;jp 同样保留 EPB |
| CTDamageBallisticShotgun#2 | pumped %o full of plasma shot | 打成了筛子(未改,粗翻原译) | 与 BallisticSMG"打成了筛子"重复;若需区分可改"灌满了等离子弹" |
| CTDamageMeleeWookieePaws#1 | %o was beaten to death by %k. | %o被%k打死了。(未改) | 与其他 Melee 行"%k将%o活活打死了"语序不同(en 本身为被动式),保留区分 |

## 说明

- 本区块另有用户手工润色的条目(2026-07-13 前后),本次校对未回退任何用户改动。
