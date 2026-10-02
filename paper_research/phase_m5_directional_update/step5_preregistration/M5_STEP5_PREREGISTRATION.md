# M5 Step5A Robustness / Monte-Carlo 预注册

## 1. 状态与停止边界

本文只冻结 M5 Step5 robustness matrix、成对规则、端点、统计量、边界处理和 GO/STOP 条件。Step4 已由人工审核为 `GO`，但该结论只授权编写本预注册，不授权本轮运行 Step5。

```text
DOCUMENT_ROLE: PREREGISTRATION
STEP4_HUMAN_DECISION: GO
M5_ROBUSTNESS_SIMULATION: NOT_RUN
M5_ROBUSTNESS_PERFORMANCE: NOT_VIEWED
ALGORITHM_MODIFICATION: PROHIBITED
STEP5_EXECUTION_AUTHORIZED_BY_THIS_FILE: NO, PENDING HUMAN REVIEW
STEP6_AUTHORIZED: NO
```

本轮未调用 MATLAB/Simulink，未执行 tracker，未生成或读取 M5 robustness performance。输出矩阵中的 `simulation_status` 全部为 `NOT_RUN`。本轮结束后停止，等待人工审核。

## 2. 唯一研究目的

Step5 不再寻找更大的性能提升，只检验 Step4 的 direction-selective mechanism 在冻结 nuisance 条件下是否稳定：

1. Orthogonal geometry 中，`M5_FULL` 相对 `GC` 是否稳定降低 `RMSE_perp`；
2. Hard 条件中，`M5_DH` 相对 `GH` 是否稳定保留 perpendicular adaptation；
3. Mixed geometry 中，是否保留部分、方向相关的 adaptation；
4. Parallel geometry 是否继续表现为 identifiability boundary，而不是被当作必须获胜的条件。

不构造 overall score，不使用 parallel 结果调算法，不因 robustness failure 修改算法或在线旋转 `d_f`。

## 3. 权威来源与冻结版本

### 3.1 Base registry

Base registry 唯一来源为：

```text
paper_research/phase2_full_validation/step1_matrix_spec/phase2_condition_registry.csv
SHA-256: 8A498E19A455C13CAA7B5371BE2F933CA7B7637B893C656C92DA84D88D1938BE
```

筛选规则固定为：

```text
registry_kind == MONTE_CARLO
mc_cohort == O
registry_index == 1:50
```

审计结果为 50 条唯一 `condition_id`，索引严格连续为 1–50；50 个 `truth_seed` 唯一，50 个 `noise_seed` 唯一，且任一行均不存在 `truth_seed == noise_seed`。不重新抽样，不删除、不替换、不重排为“更适合 M5”的条件。

### 3.2 冻结实现对象

| 对象 | SHA-256 | Step5A 用途 |
|---|---|---|
| `AI6109_MOA_AutoComp9.slx` | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` | 冻结物理模型 |
| `patent_default_config.m` | `D9F3E6894F51C3D978421C9E1E93828A9205F418C77D01AC449B994A3D789726` | 冻结默认配置 |
| `track_coupling_m5_directional_rls.m` | `8B580215A6268F4AC3BF27FB357DB6A4A01027DD2410C7FF59EA3C4B46DA4DDB` | GH/GC/M5_DH/M5_FULL 共用的 matched tracker |
| `m5_directional_update.m` | `47D2C12DB80F4BBFE7CE296841074DB6F3FF641CD769907666292E4398E06CA7` | 冻结 directional/global update operator |
| `coupling_regressor.m` | `7582F66875A1099DF9656F9A89FE12D8FF6972C55D4A034736527A7DB00E03D5` | 冻结回归量定义 |
| `M5_STEP4_DECISION_REPORT.md` | `BEA8B8B0A2C8462CA0B59123A3ACF170594066EE970CB150E1B365F13385C5E7` | 人工审核前的 Step4 决策记录 |

Step5 正式执行前后必须重算以上源码、模型和 registry 哈希。哈希不一致时停止，不得通过改写本预注册适配变更。

## 4. 冻结 nuisance fields

每一条 base row 原样保留下列字段：

- registry identity：`condition_id`、`registry_index`、`mc_cohort`；
- randomness：`truth_seed`、`noise_seed`；
- fault：`fault_mode`、`fault_factor`、fault start/ramp/plateau/end timing、`relative_fault_onset`；
- drift timing：`drift_rate_multiplier`、`drift_start_s`、`drift_end_s`、`drift_duration_s`；
- measurement/reference：`SNR_dB`、`noise_mode`、`reference_phase_error_deg`；
- physical mismatch：`Cself_truth_pF`、`Cself_algorithm_pF`、`Cself_mismatch_pct`、`CsAC_truth_pF`；
- background：`h3_ratio`、`h3_phase_deg`、`negative_sequence_pu`；
- evaluation：`evaluation_window_set_id`、`simulation_stop_s`；
- initial coupling：`Cs1_initial_pF`、`Cs2_initial_pF`。

冻结分布如下。这些是 registry 设计值，不是 M5 performance：

| Field | 冻结 levels 与计数 |
|---|---|
| `fault_factor` | 1.10: 19；1.30: 16；1.60: 15 |
| `drift_rate_multiplier` | 0.5: 16；1.0: 18；2.0: 16 |
| `SNR_dB` | 20: 13；30: 19；40: 18 |
| `reference_phase_error_deg` | 0: 6；0.33: 8；0.5: 8；1: 9；2: 5；3: 14 |
| `Cself_mismatch_pct` | -10: 10；-5: 6；-2: 3；0: 12；2: 5；5: 8；10: 6 |
| `evaluation_window_set_id` | `WINDOWSET_OV_R05`: 16；`WINDOWSET_OV_R10`: 18；`WINDOWSET_OV_R20`: 16 |
| 固定背景 | `h3_ratio=0.05`、`h3_phase_deg=0`、`negative_sequence_pu=0`、`CsAC_truth_pF=0` |

## 5. 三 geometry 成对复制

所有 geometry 使用同一漂移范数：

\[
D_{ref}=\sqrt{13}=3.605551275463989\ \mathrm{pF}.
\]

参数顺序为 `theta=[Cs1,Cs2]^T`，初始值由 base registry 保留，当前 50 行均为 `[10,10] pF`。三种方向固定为：

| Geometry | 单位方向 | 漂移向量 (pF) | 当前初值下终点 (pF) | 角色 |
|---|---|---|---|---|
| ORTHOGONAL | `[1,1]/sqrt(2)` | `[+sqrt(13/2), +sqrt(13/2)]` | `[12.5495097568, 12.5495097568]` | primary robustness geometry |
| MIXED | `[3,-2]/sqrt(13)` | `[+3,-2]` | `[13,8]` | mechanism external validation |
| PARALLEL | `[1,-1]/sqrt(2)` | `[+sqrt(13/2), -sqrt(13/2)]` | `[12.5495097568, 7.4504902432]` | identifiability validity boundary |

每个 base row 生成一个 `geometry_pair_id` 和三个 physical condition。三者除 geometry、`drift_delta_Cs1_pF`、`drift_delta_Cs2_pF`、终点外，所有 nuisance、时序、评价窗口和随机种子必须相同。

噪声配对的操作定义为：三种 geometry 使用同一个 `noise_seed`，逐相重放完全相同的标准正态抽样序列；每个 geometry 仍按冻结定义 `sigma = rms(ideal total leakage current)/10^(SNR_dB/20)` 缩放。因此随机实现按标准化抽样严格匹配，同时每个 geometry 保持其登记 SNR 定义。禁止为某个 geometry 重新抽 seed 或筛选 noise draw。

## 6. 正式算法、数据共享与数量

Step5 只运行以下四个 matched 算法：

| Weight | Global | Directional | 正式差值 |
|---|---|---|---|
| Hard | GH | M5_DH | `M5_DH - GH` |
| Continuous | GC | M5_FULL | `M5_FULL - GC` |

M2/M3/M4 只保留已有 Phase2 冻结 reference，不在 150 条条件上重跑，不进入 matched causal attribution。

每个 physical condition 内，GH、GC、M5_DH、M5_FULL 必须共享同一 F/CF physical data、truth、噪声抽样、reference、评价窗口与时间轴。算法之间不得重抽噪声或重新生成 nuisance。

正式数量为：

| 项目 | 数量 |
|---|---:|
| Base nuisance rows | 50 |
| Geometry replicas per row | 3 |
| Physical robustness conditions | 150 |
| Algorithms per condition | 4 |
| Matched algorithm evaluations | 600 |
| Continuous paired comparisons | 150 |
| Hard paired comparisons | 150 |

## 7. Primary 与 secondary robustness endpoints

故障敏感方向固定为：

\[
d_f=[1,-1]^T/\sqrt{2},\quad P_f=d_fd_f^T,\quad P_\perp=I-P_f.
\]

`RMSE_total`、`RMSE_parallel` 和 `RMSE_perp` 沿用 Step4 定义，并在每行冻结的 overlap 评价窗口 `W1∪W2` 上计算。

### 7.1 Primary paired deltas

Continuous directionality：

\[
\Delta_{\perp,cont}=RMSE_\perp(M5\_FULL)-RMSE_\perp(GC).
\]

Hard directionality：

\[
\Delta_{\perp,hard}=RMSE_\perp(M5\_DH)-RMSE_\perp(GH).
\]

负值表示 directional scope 的 perpendicular tracking error 更小。所有差值先按同一 `physical_condition_id` 严格配对，再做 geometry 内汇总；禁止跨 condition 配对。

### 7.2 必须保存的 paired deltas

两个 weight mode 均保存以下差值，结果列使用 `_cont` 或 `_hard` 后缀防止覆盖：

- `Delta_total`：matched candidate 与 control 的 `RMSE_total` 差；
- `Delta_parallel`：`RMSE_parallel` 差；
- `Delta_W1_retention`：W1 absolute retention error 差；
- `Delta_W2_retention`：W2 absolute retention error 差；
- `Delta_bias`：`F_minus_CF_norm_pF` 差。

原始 candidate/control 值、带符号差值和配对 ID 必须一并保存。不得只留汇总统计量。

## 8. 冻结汇总统计量

### 8.1 Orthogonal：primary robustness geometry

对 `Delta_perp_cont` 正式报告：

- median；
- P25 / P75；
- P10 / P90；
- `fraction(Delta_perp_cont < 0)`；
- 50 组 paired raw values。

对 `Delta_perp_hard` 完全同样报告。分位数使用 MATLAB `prctile` 的默认线性插值定义。执行完整性要求 50/50 对 primary endpoints 均为 finite；任何缺失或非有限结果必须保留并计数，且在 primary completeness gate 中判为 STOP，不允许静默删除。`fraction(Delta<0)` 的分母固定为登记的 50 条，而不是事后缩小到可用子集。

不预注册 p-value 作为 GO 条件，因为这些条件来自设计 registry，不解释为自然总体抽样。

### 8.2 Mixed：机制外部验证

Mixed 保存并报告 `Delta_perp`、`Delta_total` 及其 paired raw values。Continuous 为主要机制检查，Hard 为配套描述。不要求所有条件改善，也不要求 total error 必然改善。

“绝大多数反向恶化”的操作性 red flag 固定为：`fraction(Delta_perp_cont > 0) > 0.75`。若触发，只允许使用第 10 节预注册的 phase/projection/rate/angle 边界诊断解释；不得补充新分层、改 direction 或调算法。若触发且没有与预注册边界一致的诊断证据，则 Mixed gate 为 STOP。

### 8.3 Parallel：validity boundary

Parallel 完整保留 50 条 continuous pairs 与 50 条 hard pairs，报告 raw values 和同一组描述性统计量，但没有 superiority PASS threshold。无优势或退化均为允许结果。禁止删除 parallel rows、改变方向、用 parallel 结果调算法，或把 parallel 失败改写为 primary superiority failure。

## 9. Step5 robustness GO / STOP

Step5 正式执行后的判据冻结如下：

### Gate 0：execution integrity

- 150/150 physical conditions 完整；
- 600/600 algorithm evaluations 完整；
- Orthogonal primary pairs 50/50 finite；
- registry/hash/seed/data-sharing audits 全部通过；
- 无条件或算法行被删除。

任一项失败即 STOP，先修复执行完整性；不得用缺失行上的性能判断替代。

### Gate A：Orthogonal continuous，Step6 的 primary survival gate

必须同时满足：

```text
median(Delta_perp_cont) < 0
fraction(Delta_perp_cont < 0) > 0.5
```

否则 Step5 robustness 为 STOP，不得因修改统计量或算法改判。

### Gate B：Orthogonal hard

报告与 Gate A 相同的 median、分位数、改善比例和 raw pairs，但该项不是 `M5_FULL` 的唯一生死条件。其结果用于判断 hard directionality 是否保留 perpendicular adaptation，并与 continuous 结果并列解释。

### Gate C：Mixed

不得出现 `fraction(Delta_perp_cont > 0) > 0.75` 且没有预注册 boundary explanation 的情况。该 gate 不要求所有条件改善，也不设置 overall-score 补偿。

### Gate D：Parallel

只要求完整保留和正确标记 identifiability boundary；没有 superiority threshold。

### Gate E：method integrity

不得通过修改 GH、GC、M5_DH、M5_FULL、REW、hard gate、`d_f`、rate limit、projection、评价窗口或 registry 来解决 robustness failure。若 Gate A/C 失败，保留失败并停止进入 Step6。

## 10. Phase-error / projection / rate-limit boundary

固定 `d_f=[1,-1]/sqrt(2)`。任何条件下均禁止在线旋转 `d_f`。

正式结果必须按以下字段分层：

- `reference_phase_error_deg`：保留 registry 原始 levels，不事后合并；
- `projection_active=0/1`；
- `rate_limit_active=0/1`。

对 continuous pair，primary 约束标志取 `M5_FULL` 的 F branch；对 hard pair取 `M5_DH` 的 F branch。`projection_active=1` 定义为 W1∪W2 内至少一个注册更新周期发生 projection；`rate_limit_active=1` 同理。GC/GH 及 CF branch 的对应标志也必须原样保存，用于 matched diagnosis，不替代 primary stratifier。

每个 F/CF branch 保存：

- `pre_constraint_angle_deg`；
- `post_rate_angle_deg`；
- `post_projection_angle_deg`；
- 有效 angle 样本数与 `NaN` 数。

角度均相对固定 `d_f` 及预注册 true-drift direction 计算；near-zero update 保留为 `NaN`，不得改写为 0°。这些诊断只用于说明 phase mismatch、rate limit 或 projection 是否伴随方向旋转，不参与 overall score，也不得用于事后改算法。

Mixed red flag 的 boundary explanation 仅限以下预注册链条：恶化集中在非零或较大的 phase error、projection-active 或 rate-limit-active strata。与此同时，`pre_constraint -> post_rate -> post_projection` 角度记录必须显示约束路径发生同向旋转。报告必须展示 inactive、phase-zero 对照 strata 和全部 raw pairs；单个异常条件或新增分组不构成解释。

## 11. 预期工作量（下一阶段，不在本轮执行）

沿用 Phase2 O-cohort 的 F/CF 结构，每个 physical condition 预计包含：

1. 一个 clean F simulation，用于冻结 SNR scaling；
2. 一个 noisy F simulation；
3. 一个使用相同标准化 noise draw 的 noisy CF simulation。

因此预计：

| Work item | 数量 |
|---|---:|
| Simulink physical simulation calls | 150 × 3 = 450 |
| Tracker branches | 600 evaluations × 2 branches = 1200 |
| Primary Orthogonal continuous pairs | 50 |
| Orthogonal hard pairs | 50 |
| 全部 continuous + hard matched pairs | 300 |

这些是 execution planning counts，不是本轮已完成的运行量。

## 12. 登记矩阵与审核结论

正式矩阵为 `M5_STEP5_ROBUSTNESS_MATRIX.csv`：600 行、150 个唯一 physical condition、50 个 geometry pair、三种 geometry 各 200 行、四个算法各 150 行。矩阵包含 source registry identity、全部 nuisance/timing、geometry、algorithm role、端点定义、分层字段、诊断字段、哈希和 `NOT_RUN` 状态。

本轮结论：

```text
STEP5A_PREREGISTRATION: COMPLETE
MATRIX_FROZEN_FOR_HUMAN_REVIEW: YES
STEP5_MONTE_CARLO_EXECUTED: NO
M5_ROBUSTNESS_PERFORMANCE_VIEWED: NO
READY_FOR_STEP5_EXECUTION: PENDING_HUMAN_REVIEW
READY_FOR_STEP6: NO
```

人工审核只需上传：

1. `M5_STEP5_PREREGISTRATION.md`
2. `M5_STEP5_ROBUSTNESS_MATRIX.csv`

审核前不得运行 Step5 Monte-Carlo。
