# Phase 2 Step 1B — Experiment Budget

## 1. Counting rules

本预算是 preregistration estimate，不代表已运行。为避免重复计数，定义：

- **physical condition**：一套 truth/reference/noise/fault/model-mismatch 物理设置；同一 condition 的四算法共享数据。
- **condition×algorithm evaluation**：一个算法在一个 registered physical condition 上的一条正式结果。
- **sensitivity variant evaluation**：相同物理 condition 上的离线参数变体；不是新 physical condition。
- **replay trajectory evaluation**：同一 Case08 物理 anchor 上的反事实递归轨迹；不是新 physical condition。
- Pilot 是 formal MC registry 前 20 条/cohort，不单独累加。

Nominal duplicates 按 `STEP1B_FACTOR_METRIC_FREEZE.md` 冻结的 anchor 分配去重。

## 2. Deterministic physical-condition budget

| Family | Raw grid | Duplicate with prior frozen condition | Incremental unique | Cumulative unique | Duplicate basis |
|---|---:|---:|---:|---:|---|
| Existing frozen Case01–Case08 anchors | 8 | 0 | 8 | 8 | frozen anchors |
| Fault amplitude: 2 families × 6 levels | 12 | 2 | 10 | 18 | Case05/06 factor 1.60 |
| SNR | 4 | 1 | 3 | 21 | Case02 at 30 dB |
| Reference phase | 6 | 1 | 5 | 26 | Case05 at 0 deg |
| Third-harmonic amplitude | 5 | 1 | 4 | 30 | Case02 at h3=0.05 |
| Negative sequence | 4 | 1 | 3 | 33 | Case02 at Vneg=0 |
| Cself mismatch | 7 | 1 | 6 | 39 | Case02 at 0%, truth=algorithm=400 pF |
| CsAC mismatch | 5 | 1 | 4 | 43 | Case02 at CsAC=0, subject to zero-injection gate |
| Overlap core: 3 rates × 3 fault factors | 9 | 2 | 7 | 50 | rate 1×, factor 1.30/1.60 are Case07/08 |
| Direction extension: 3 directions × 2 factors | 6 | 2 | 4 | 54 | D1 points already in core |
| **Total deterministic physical conditions** |  |  | **54** | **54** | 8 existing + 46 incremental |

说明：CsAC 的 4 个非零条件进入冻结预算，但执行资格取决于 zero-injection regression；若失败，保持定义不变并标记 `BLOCKED`，不得用其他路径替换。

## 3. Main algorithm-evaluation budget

完整四算法矩阵：

```text
54 physical conditions × 4 algorithms = 216 evaluations
```

复用与待执行拆分：

| Component | Evaluations | Status |
|---|---:|---|
| Case01–Case06 × 4 algorithms | 24 | existing frozen evidence |
| Case07–Case08 × M2/M3/M4 | 6 | existing frozen evidence |
| Case07–Case08 × M0 | 2 | `MISSING_FOR_PHASE2_MATRIX` |
| 46 incremental conditions × 4 | 184 | future execution required |
| **Main matrix total** | **216** | 30 reusable + 186 required to complete |

“Reuse” 仅在原 frozen schema/window 和 validator provenance 保持成立时适用；Step 1C 若要求新字段，必须显式区分复用字段与 rerun-required 字段。

## 4. Sensitivity budget

以 Case08 为局部 anchor，nominal 已由主矩阵覆盖。每个参数只改变 low/high，其他保持 frozen：

| Parameter | Low/high variants | Algorithms | Incremental evaluations |
|---|---:|---|---:|
| gate_ratio | 2 | M3, M4 | 4 |
| gate_quad_ratio | 2 | M3, M4 | 4 |
| gate_hold_cycles | 2 | M3 only | 2 |
| **Total** |  |  | **10** |

Registry-style 看法：nominal 加 6 个 low/high parameter-setting records，共 7 records；其中 6 个是增量 offline variant records，但物理 condition 仍只有 Case08 一个。M4 不适用 hold cycles。

## 5. Counterfactual replay budget

Case08 的 F/N/P/A × M3/M4 共 8 条概念 trajectory evaluations：

- F/N × M3/M4：4 条已有冻结/自然 matched trajectory 证据；
- P/A × M3/M4：4 条未来新增 replay trajectories。

因此预算增量为 4，不把 replay 当作新 physical conditions。

## 6. Deterministic totals

| Scope | Physical conditions | Evaluations / trajectories |
|---|---:|---:|
| Main deterministic matrix | 54 | 216 |
| Offline sensitivity increment | 0 | 10 |
| Counterfactual replay increment | 0 | 4 |
| **Deterministic planned total** | **54** | **230** |

若执行清单需要以“记录”计数，可表述为 54 main condition records + 6 incremental sensitivity records + 4 incremental replay trajectory records = 64 execution records；该数字不得称为 64 physical conditions。

## 7. Monte-Carlo budget — separate

| Stage | Cohorts | N/cohort | Stochastic conditions | Algorithms/condition | Evaluations |
|---|---:|---:|---:|---:|---:|
| Pilot subset | 3 | 20 | 60 | 4 | 240 |
| Formal registry | 3 | 50 | 150 | 4 | 600 |
| Remaining after pilot | 3 | 30 | 90 | 4 | 360 |

Pilot 60/240 是 formal 150/600 的严格子集，不能相加成 210/840。

## 8. Grand preregistered budget

```text
deterministic physical conditions = 54
formal stochastic conditions = 150
total physical/stochastic conditions = 204

main deterministic evaluations = 216
sensitivity evaluations = 10
incremental replay trajectories = 4
formal MC evaluations = 600
grand evaluations/trajectories = 830
```

本预算不估算底层 Simulink invocation 次数：同一数据可被四算法共享，overlap F/CF 与 replay wrapper 还可能包含多分支执行。Step 1C 应另设 execution-plan 字段，不能把 algorithm evaluation 数量冒充模型仿真次数。

## 9. Execution status

```text
SIMULATIONS RUN IN STEP 1B: 0
MONTE-CARLO RUNS IN STEP 1B: 0
CONDITION REGISTRY CREATED: NO
```

