# 中文核心论文 Phase 1A — Formal Baseline Report

## 1. Research objective

Phase 1A 的目标不是开发新算法，而是建立一套统一、可重复、公平的论文 baseline
framework：冻结模型、case、算法入口、指标、NaN 规则和复现元数据，使 M0/M2/M3
在相同数据、参考和配置下可直接比较，并为后续 M1/M4 与 Phase 1B 提供稳定入口。

最终状态：

```text
6 cases
3 algorithms
18 result rows
19 / 19 formal validator checks PASS
11 / 11 historical regression checks PASS
```

## 2. Baseline model

正式模型：

```text
MATLAB一键实验/AI6109_MOA_AutoComp9.slx
```

SHA-256：

```text
56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70
```

AutoComp9 在 Phase 1A 全阶段未被修改。六个正式 case 均由同一模型、同一
`simulate_phase2_case` 路径生成；每个 case 一次 case-level 调用，内部保留冻结 helper
的 zero-noise 与 noisy 两次底层运行。

## 3. Case Registry

| 正式 Case | legacy scenario | seed | 来源与角色 |
|---|---|---:|---|
| `Case01_static` | `static` | 101 | 历史 AutoComp9 静态定义/一致性证据复用 |
| `Case02_slow_drift` | `slow_drift` | 102 | 历史 AutoComp9 慢漂移定义与关键回归证据复用 |
| `Case03_smooth_step` | `smooth_step` | 103 | 历史 MATLAB synthetic 轨迹迁移进 AutoComp9 |
| `Case04_random_drift` | `random_drift` | 104 | 历史 MATLAB synthetic 随机轨迹迁移进 AutoComp9 |
| `Case05_fault_only` | `fault_only` | 106 | Phase 1A 新增最小 fault-only case |
| `Case06_drift_then_fault` | `fault_with_drift` | 105 | 历史 AutoComp9 漂移后故障定义与证据复用 |

Case05 冻结为 Cs1=Cs2=10 pF，使用与 Case06 完全相同的 3.00–3.06 s、1.0→1.6
故障轨迹。第一次 Step 6 暴露的 legacy synthetic compatibility 缺口已在 Step 6A
最小修复并通过 12/12 专项测试。

为形成统一正式 baseline，最终六个 Case 全部通过统一入口从 Case01 开始重新运行一次，
没有从失败位置续跑，也没有拼接不同代码状态下的数据。

## 4. Algorithm Registry

三种算法全部通过 `run_phase1a_algorithm` 统一调度：

| Mode | 定义 | gate |
|---|---|---|
| M0 | 初始化窗口联合 LS 得到 Cs1/Cs2，之后全程冻结 | 无 |
| M2 | 现有 VFF-RLS、变化率限制和物理投影，关闭 fault gate | 无 |
| M3 | 与 M2 相同的 VFF-RLS 和约束，启用现有 hard fault gate | 硬门控 |

每个 case 的 M0/M2/M3 共用同一份正式 noisy `data`、同一 `ref` 和同一 `cfg`。
本报告只描述结果差异，不宣称某一种算法在所有工况下“最好”。

## 5. Unified metrics

统一结果 schema 的一行对应一个 `case × algorithm`，包含：

- Cs1/Cs2 RMSE；
- B 相阻性电流基波误差；
- 真实/估计故障增幅与 fault retention error；
- Cs1/Cs2 故障前后变化；
- 首次 gate 时间、gate 周期数和持续时间；
- seed、模型、SHA、时间戳和 Git/平台元数据。

NaN 规则：

- Case01–Case04 的故障指标为 NaN；
- M0/M2 的 gate 指标为 NaN；
- M3 未真实触发 gate 时仍为 NaN；
- 不适用值不得用 0 代替。

正式 validator 确认 schema、NaN、Inf/complex、metadata 和组合完整性全部通过。

## 6. Reproducibility

| 字段 | 正式值 |
|---|---|
| MATLAB | `23.2.0.2365128 (R2023b)` |
| Simulink | `23.2` |
| platform | `PCWIN64` |
| run timestamp | `2026-09-17T10:45:57+08:00` |
| baseline run Git commit | `21db36134f1ff89be6d3be390a58b0afb741ac32` |
| Step 6 checkpoint | `80b8898` |
| branch | `main` |
| run dirty status | `DIRTY`，仅因未跟踪的大型本地 workspace |
| case-level calls | 6 |
| low-level `sim(in)` calls | 12 |

每行结果保存 `random_seed`、`model_file`、`model_sha256`、`run_timestamp`、
`git_commit`、`git_branch` 和 `git_dirty_status`。正式 workspace 同时保存 registry、
schema、historical reference、时序 truth、算法估计和 validator 结果。

## 7. Formal six-case results

下表为论文级简化显示；完整精度保存在 `baseline_summary.csv`。

| Case | Mode | Cs1 RMSE/pF | Cs2 RMSE/pF | B fund. error/% | true factor | est. factor | ΔCs1/pF | ΔCs2/pF |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Case01 | M0 | 0.0199 | 0.0501 | 0.0528 | — | — | — | — |
| Case01 | M2 | 0.0404 | 0.0393 | -0.0356 | — | — | — | — |
| Case01 | M3 | 0.0404 | 0.0393 | -0.0356 | — | — | — | — |
| Case02 | M0 | 2.9438 | 2.2136 | 8.9588 | — | — | — | — |
| Case02 | M2 | 0.1573 | 0.1085 | 0.3548 | — | — | — | — |
| Case02 | M3 | 0.1573 | 0.1085 | 0.3548 | — | — | — | — |
| Case03 | M0 | 4.3032 | 3.4843 | 14.0220 | — | — | — | — |
| Case03 | M2 | 0.2298 | 0.1801 | 0.1642 | — | — | — | — |
| Case03 | M3 | 0.2298 | 0.1801 | 0.1642 | — | — | — | — |
| Case04 | M0 | 1.1638 | 0.9823 | -1.3540 | — | — | — | — |
| Case04 | M2 | 0.2693 | 0.2099 | -0.0876 | — | — | — | — |
| Case04 | M3 | 0.2693 | 0.2099 | -0.0876 | — | — | — | — |
| Case05 | M0 | 0.0257 | 0.0608 | -0.1320 | 1.6000 | 1.6046 | 0.0000 | 0.0000 |
| Case05 | M2 | 2.6008 | 2.5910 | -4.8376 | 1.6000 | 1.4011 | 4.9168 | -4.9570 |
| Case05 | M3 | 0.2666 | 0.3160 | -0.4986 | 1.6000 | 1.5811 | 0.4575 | -0.6183 |
| Case06 | M0 | 2.5795 | 1.6833 | 6.7818 | 1.6000 | 1.5511 | 0.0000 | 0.0000 |
| Case06 | M2 | 2.6152 | 2.5999 | -4.6566 | 1.6000 | 1.4023 | 5.0063 | -4.9773 |
| Case06 | M3 | 0.3153 | 0.3281 | -0.3102 | 1.6000 | 1.5829 | 0.5611 | -0.6163 |

Case05/06 中 M3 的首次 gate 均为 `3.05998 s`，持续 48 cycles（0.96 s）。

## 8. Historical regression

正式回归只读取 `baseline_summary.csv` 和冻结的
`phase1a_historical_reference.m`：

```text
Case02 = 4 / 4 PASS
Case06 = 7 / 7 PASS
Total  = 11 / 11 PASS
```

使用冻结容差 `absTol=1e-9`、`relTol=1e-8`。11 个正式 CSV 值与 reference 在保存
精度下差值均为 0。完整对照见 `STEP7_HISTORICAL_REGRESSION.md`。

结论：统一 baseline 成功保持了历史 slow-drift 与 drift-then-fault 关键证据。

## 9. Baseline figures

所有图只读取 SHA 已验证的 `baseline_workspace.mat`，没有重新运行模型或算法。

| Figure | 内容 | 文件 |
|---|---|---|
| Figure 1 | Case02 Cs1/Cs2 truth 与 M0/M2/M3 慢漂移跟踪 | `figures/figure1_case02_slow_drift_tracking.png/.fig` |
| Figure 2 | Case06 truth、M2、M3 参数跟踪及 3.00–3.06 s 故障区间 | `figures/figure2_case06_fault_parameter_tracking.png/.fig` |
| Figure 3 | Case06 B 相真实/估计阻性电流的故障窗口与过渡细节 | `figures/figure3_case06_B_resistive_current.png/.fig` |

图中只展示正式 baseline 现象，没有定义 `P_X`、`eta_abs` 或新的机理指标。

## 10. Hard-coded parameter audit

### 10.1 cfg 集中管理参数

`patent_default_config.m` 集中管理：

| 类别 | 当前参数 |
|---|---|
| 仿真 | duration=4.0 s，dt=2e-5 s，f=50 Hz |
| 评价 | metric_start=0.80 s |
| 测量 | SNR=30 dB，phase error=0° |
| 初始化 | 0.10–0.70 s |
| VFF | lambda=0.55–0.995 |
| 物理约束 | Cs `[0,40] pF`，变化率 `1.2 pF/cycle` |
| hard gate | ratio 1.12，direction ratio 1.20，hold 25 cycles |

这些默认参数对 M0/M2/M3 使用同一 cfg，不构成方法间不公平。

### 10.2 case generator 中冻结的实验定义

`generate_coupling_signals.m` 固定保存：

- 10/10 pF 耦合初值；
- Case02 1.0–3.0 s、+4/-3 pF 慢漂移；
- Case03 1.45–1.65 s、10→15/10→6 pF smooth step；
- Case04 的正弦与 0.30 s moving-average 随机项；
- Case06 0.8–2.2 s、+3/-2 pF 漂移；
- Case05/06 3.00–3.06 s、1.0→1.6 fault profile。

这些值是冻结实验定义，不是算法调参；后续公平比较必须继续共享它们。

### 10.3 algorithm core 中的历史内部常量

现有核心仍包含并保留：

- 初始 LS 正则 `1e-10 I`；
- RLS `J0=0.05 X0'X0 + 1e-8 I` 和求解正则 `1e-10 I`；
- innovation normalization `[5;5] pF` 与饱和尺度 0.20；
- fault 判据启用时刻 1.0 s；
- `baseIn` 更新条件 1.08 与指数系数 0.985/0.015；
- 1/3 次谐波拟合、A/B/C 基波 ±120° 和三次谐波同相假设；
- fault 指标窗口 `[2.60,2.90)` 与 `[3.40,3.80)` s；
- noise seed 偏移 +10000、禁用旧耦合支路的 `1e-18 F`。

这些历史常量没有在 Phase 1A 重构或优化。它们应继续记录并在后续鲁棒性阶段检验，
不能声称项目“完全没有硬编码”。

### 10.4 公平性风险判断

在相同 case/cfg 和现有统一指标下，没有阻止 M1/M4 以新增 algorithm rows 参与公平比较的
参数级硬编码；现有 schema 不需要改变。

但有一个明确的实现级扩展点：`evaluate_phase1a_metrics.m` 的 `gate_metrics` 当前用
`algorithmMode == "M3"` 决定是否读取 gate log。未来 M4 若输出 gate 权重或 gate log，
必须改为由 Algorithm Registry 的能力字段驱动，否则 M4 的 gate 指标会被错误写为 NaN。
这不阻塞 baseline 数据结构，但不能忽略。

## 11. M1 / M4 extensibility

```text
baseline_data_structure_extensible = true
```

增加 M1/M4 时，case registry、20 字段结果 schema、CSV 行粒度和 workspace 的
`caseData/algorithmResults` 分层结构均可保持不变。最低代码扩展为：

1. 在 Algorithm Registry 增加 M1/M4 item；
2. 在 dispatcher 增加相应 branch；
3. 对每个 case 生成新的 `case × algorithm` 行；
4. 若 M4 需要正式 gate metrics，将 gate 提取从 M3 名称判断改为 registry/capability 驱动。

因此无需修改既有 baseline schema，但不能把“schema 可扩展”等同于“所有实现代码零修改”。
本轮没有实际创建 M1/M4。

## 12. Remaining limitations

当前 Phase 1A 是 deterministic baseline，尚未开展：

- Monte-Carlo 多随机种子统计；
- 参数和模型失配鲁棒性；
- 多 SNR 噪声鲁棒性；
- 传感器相位/增益误差和三相不平衡有效性边界；
- 新 M4 或 soft gate；
- Fault Absorption Mechanism 的定量指标；
- `P_X`、`eta_abs` 或方向感知更新；
- 低压实验验证。

这些均属于后续论文阶段，不应从 Phase 1A 的 18 行 deterministic baseline 过度外推。

## 13. Phase 1B evidence entry point

Case06 的正式 baseline 事实：

```text
true fault factor = 1.6000

M2:
estimated factor  = 1.4023
Delta Cs1         = +5.0063 pF
Delta Cs2         = -4.9773 pF

M3:
estimated factor  = 1.5829
Delta Cs1         = +0.5611 pF
Delta Cs2         = -0.6163 pF
```

Case05 的附加事实：

```text
M2 estimated factor = 1.4011
M3 estimated factor = 1.5811
```

这些现象表明：在真实阻性电流故障存在时，无门控自适应参数估计出现明显参数偏移，
同时故障增幅估计被削弱。Phase 1A 只把它作为 Phase 1B 的研究动机；尚未宣称完整的
fault absorption 机理已经被定量证明。

## 14. 原始七个问题的正式回答

### Q1 — AutoComp9 是否成功冻结为正式论文 baseline？

**YES。** 模型 SHA 在运行前后相同，六 case 正式结果均来自该冻结模型。

### Q2 — M0/M2/M3 是否统一调用？

**YES。** 三种模式均经统一 Algorithm Registry 和 dispatcher，对每个 case 共享同一
data/ref/cfg。

### Q3 — 六个 case 哪些复用、迁移或新增？

- Case01/02/06：复用历史 AutoComp9 定义/证据；
- Case03/04：迁移历史 MATLAB synthetic 轨迹到 AutoComp9；
- Case05：新增最小 fault-only case，并复用 Case06 fault profile。

### Q4 — 历史关键结果是否成功复现？

**YES。** Case02 4/4、Case06 7/7，总计 11/11 PASS。

### Q5 — 是否仍存在硬编码参数？

**YES。** 冻结 case 定义和算法内部历史常量仍存在；cfg 关键参数已集中管理。另有
M3 名称绑定的 gate metric 提取需要在增加 M4 时泛化。

### Q6 — 后续加入 M1/M4 是否无需修改 baseline 数据结构？

**YES。** `baseline_data_structure_extensible=true`。需增加 registry/dispatcher 分支和
算法结果行；M4 gate 指标实现需小幅泛化，但不需改变 schema。

### Q7 — 是否可以进入 Phase 1B — Fault Absorption Mechanism？

**YES。** Step 7、正式产物、figures 和完整性检查均通过。这里只授权“可以进入”，
本轮没有自动开始 Phase 1B。

## 15. Final file integrity

正式根目录：

```text
paper_research/phase1a_baseline/
```

已确认保留：

- `baseline_summary.csv`
- `baseline_workspace.mat`
- `figures/` 下三组 PNG/FIG
- `STEP1_FREEZE_AND_SCAFFOLD.md`
- `STEP2_CASE_REGISTRY_AND_SIGNAL_GENERATION.md`
- `STEP3_ALGORITHM_DISPATCHER.md`
- `STEP4_UNIFIED_METRICS.md`
- `STEP5_END_TO_END_SMOKE_TEST.md`
- `STEP6_FORMAL_BASELINE_RUN_FAILED_ATTEMPT1.md`
- `STEP6A_FAULT_ONLY_COMPATIBILITY_FIX.md`
- `STEP6_FORMAL_BASELINE_RUN.md`
- `STEP7_HISTORICAL_REGRESSION.md`
- `PHASE1A_BASELINE_REPORT.md`

关键文件：

| 文件 | 大小/bytes | SHA-256 | Git 处理 |
|---|---:|---|---|
| `baseline_summary.csv` | 5,821 | `E7BEB3EC...D9D0AB3` | 已在 Step 6 checkpoint 提交 |
| `baseline_workspace.mat` | 115,337,063 | `A90632B7...61E87B5` | 本地保留，不提交 |
| `step5_smoke_workspace.mat` | 73,214,323 | `C32D1AE6...7C6A5CA` | 调试数据，本地保留，不提交 |

`baseline_workspace.mat` 没有删除或加入普通 Git commit。失败审计报告也完整保留。

## 16. Final acceptance A–V

| ID | 项目 | 结果 |
|---|---|---|
| A | AutoComp9 integrity | PASS |
| B | Six-case registry | PASS |
| C | M0/M2/M3 dispatcher | PASS |
| D | Unified metrics | PASS |
| E | Step 5 historical smoke test | PASS |
| F | Step 6 formal six-case run | PASS |
| G | 18-row baseline summary | PASS |
| H | Frozen schema | PASS |
| I | NaN rules | PASS |
| J | Reproducibility metadata | PASS |
| K | Case02 formal historical regression | PASS, 4/4 |
| L | Case06 formal historical regression | PASS, 7/7 |
| M | `baseline_workspace.mat` | PASS，SHA/size 已记录 |
| N | `baseline_summary.csv` | PASS，SHA/size 已记录 |
| O | baseline figures | PASS，三组 PNG/FIG 已视觉核验 |
| P | hard-coded parameter audit | PASS |
| Q | M1/M4 extensibility | PASS，schema 可扩展并记录实现注意项 |
| R | historical results untouched | PASS |
| S | AutoComp9 untouched | PASS |
| T | algorithm core untouched | PASS |
| U | final Git checkpoint | PASS；commit hash 记录在最终交付信息中 |
| V | ready for Phase 1B | PASS |

A–U 全部通过，因此 V=PASS。

## 17. Final status

```text
PHASE 1A STATUS: COMPLETE

Historical regression:
11 / 11 PASS

Formal baseline:
6 cases × 3 algorithms = 18 rows

Baseline model:
AI6109_MOA_AutoComp9.slx

NEXT PHASE:
Phase 1B — Fault Absorption Mechanism
```

本轮在此停止，不自动进入 Phase 1B，不实现 M4，不定义 `P_X` 或 `eta_abs`。
