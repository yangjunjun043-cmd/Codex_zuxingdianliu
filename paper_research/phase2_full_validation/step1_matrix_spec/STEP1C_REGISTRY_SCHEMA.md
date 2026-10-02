# Phase 2 Step 1C — Registry Schema

## 1. Registry boundary

Step 1C 只建立 preregistered design records，不运行模型。四个 CSV 的行语义严格分开：

| Registry | Row meaning | Rows |
|---|---|---:|
| `phase2_condition_registry_DRAFT.csv` | one unique physical/stochastic condition | 204 = 54 deterministic + 150 MC |
| `phase2_algorithm_evaluation_registry_DRAFT.csv` | one condition × one frozen algorithm | 816 = 204 × 4 |
| `phase2_replay_registry_DRAFT.csv` | one Case08 algorithm × F/N/P/A replay trajectory | 8 |
| `phase2_sensitivity_registry_DRAFT.csv` | one Case08 parameter level × applicable algorithm | 15 records, 10 incremental evaluations |

Replay 和 sensitivity 不是新 physical conditions，不能并入 54 或 150 的条件计数。

## 2. Missing-value rules

- 不适用数值字段统一写 `NaN`。
- 不适用文本字段统一写 `N/A`。
- 所有 CSV 禁止空单元格。
- `Inf` 是正式 noise-free SNR level，不是 missing value。
- `N/A_BY_DESIGN` 是窗口语义不存在，不是数值或执行失败。

## 3. Physical-condition schema

`phase2_condition_registry_DRAFT.csv` 包含 59 列。用户要求的字段全部保留，并增加以下用于 MC、审计和时序消歧的字段：

- `registry_kind`：`DETERMINISTIC` 或 `MONTE_CARLO`；
- `registry_index`、`mc_cohort`、`pilot_member`；
- `truth_seed`、`noise_seed`；
- `interpretation_flag`；
- `fault_ramp_end_s`：绝对时刻；而 `fault_ramp_up_s`、`fault_ramp_down_s` 是 duration；
- `relative_fault_onset`。

关键字段约定：

| Field | Frozen meaning |
|---|---|
| `condition_id` | stable unique physical-condition ID |
| `reuse_condition_id` | only used when a retained row reuses another physical record; omitted nominal aliases are documented in the duplicate audit |
| `reuse_status` | `EXACT_REUSE`, `NEW_CONDITION`, or `NEW_STOCHASTIC_CONDITION` |
| `execution_status` | `REUSE_AVAILABLE`, `READY`, or `PENDING_GATE` |
| `is_blocked` | only true after a required gate has actually failed; a pending gate is not silently promoted to `BLOCKED` |
| `deterministic_seed` | fixed case/sweep seed; MC rows use `NaN` and separate truth/noise seeds |
| `negative_sequence_convention_status` | always retains `UNRESOLVED_INTERNAL_CONVENTION` until formally resolved |
| `evaluation_window_set_id` | points to the frozen family/rate window definition |

## 4. Algorithm-evaluation schema

Every physical condition expands to M0/M2/M3/M4. `result_reuse_status` is mutually exclusive:

- `EXACT_REUSE`：frozen production result directly available in its frozen schema；
- `PARTIAL_REUSE`：historical evidence exists but cannot replace the unified Phase 2 run；
- `RECOMPUTE_METRICS_ONLY`：full reusable data exist and only metric recomputation is needed；
- `NEW_RUN_REQUIRED`：no adequate formal result exists；
- `BLOCKED`：a gate has failed, not merely pending。

`execution_required` and `rerun_required` remain explicit. A `PARTIAL_REUSE` row may still require a new run. Step 1C found no safe `RECOMPUTE_METRICS_ONLY` row because the Phase 1B controlled sweep lacks a saved full condition workspace sufficient for the complete Phase 2 metric schema.

Frozen algorithm versions in the registry:

```text
M0 = FIXED_COUPLING_PHASE1A
M2 = VFF_RLS_NO_GATE_PHASE1C
M3 = VFF_RLS_HARD_GATE_PHASE1C
M4 = REW_AI_PAPER_METHOD_V1
```

## 5. Execution gates

| Gate | Scope | Step 1C state |
|---|---|---|
| `GATE_NONE` | no special feature gate | registered |
| `CSELF_SPLIT_INTERFACE_GATE` | nonzero Cself mismatch and MC rows drawing nonzero mismatch | pending |
| `ZERO_INJECTION_REGRESSION` | all CsAC>0 conditions | pending |
| `REPLAY_EQUIVALENCE_GATE` | P/A counterfactual replay | pending |
| `TRACKER_EQUIVALENCE_GATE` | offline sensitivity implementation | pending |
| `RATE_TIMING_DESIGN_GATE` | overlap rate schedule | passed at design level |
| `NO_FROZEN_SOURCE_DIFF_GATE` | all future execution paths | passed for Step 1C source state; must be rechecked before execution |

Pending gates do not change `is_blocked` to true. A failed gate must stop the affected execution and then record `BLOCKED` with a reason.

## 6. ID rules

- Anchors：`P2_AN_C01`–`P2_AN_C08`。
- Deterministic one-factor IDs use the Step 1C prescribed prefixes (`P2_FA_*`, `P2_SN_*`, `P2_PE_*`, `P2_H3_*`, `P2_NS_*`, `P2_CS_*`, `P2_AC_*`, `P2_OV_*`, `P2_DD_*`)。
- MC IDs：`P2_MC_H_001`–`050`、`P2_MC_F_001`–`050`、`P2_MC_O_001`–`050`。
- Evaluation IDs：`EV_<condition_id>_<algorithm_id>`。
- Replay and sensitivity IDs have independent `RP_` and `SENS_` namespaces。

All four registries passed ID uniqueness and blank-cell validation.

