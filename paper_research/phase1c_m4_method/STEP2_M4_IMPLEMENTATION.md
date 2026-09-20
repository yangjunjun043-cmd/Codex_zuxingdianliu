# Phase 1C Step 2 — M4 Implementation

## 1. Scope

本步骤只完成 M4-v0 的结构实现与回归保护：

- 独立实现 Residual-Evidence Weighted Information Update；
- 将 M4 注册为新算法并接入现有 dispatcher；
- 实现连续 evidence、信息状态加权、`baseIn` 加权和完整周期日志；
- 实现仅诊断的候选故障方向、方向余弦和平行/正交更新；
- 实现 forced `g=0/0.5/1` 结构测试；
- 重新运行 Phase 1A formal validator、historical regression 和完整单元测试。

本步骤没有执行 M4 性能排名、Case05/06 保持效果分析、同时漂移与故障实验、Monte-Carlo、鲁棒性研究或 Step 3。

M4-v0 当前解决的是：

```text
binary hard freeze
→ continuous state-consistent protection
```

当前没有证明：

```text
direction-aware separation
true drift / fault perfect decomposition
M4 > M3
simultaneous drift+fault advantage
```

## 2. Frozen Inputs

本步骤以以下冻结内容为输入：

- `STEP1_M4_METHOD_SPECIFICATION.md`；
- `AI6109_MOA_AutoComp9.slx`；
- `track_coupling_cvff_rls.m` 中的 M2/M3；
- Phase 1A Case01–Case06、结果 schema、historical reference；
- Phase 1B Step 1–5 的正式机理证据；
- 原有 lambda、rate limit、physical projection 和 M3 gate 参数。

没有修改 AutoComp9、M2/M3 核心、Case01–Case06、Phase 1A/1B 正式结果或现有算法参数。

## 3. M4-v0 Exact Formula

M4-v0 使用零新增调优参数的确定公式。对第 `k` 个工频周期：

\[
r_{b,k}=\frac{E_{in,k}}{baseIn_{k-1}+\epsilon},
\qquad
r_{q,k}=\frac{E_{in,k}}{E_{quad,k}+\epsilon}.
\]

\[
e_{b,k}=\max\left(0,
\frac{r_{b,k}-1}{\max(gate\_ratio-1,\epsilon)}\right),
\]

\[
p_{q,k}=clip\left(
\frac{r_{q,k}}{gate\_quad\_ratio},0,1\right),
\]

\[
s_k=e_{b,k}p_{q,k},
\qquad
g_k=\frac{1}{1+s_k}.
\]

因此自然 evidence 模式满足：

```text
0 < g <= 1
E_in <= baseIn → e_b = 0 → s = 0 → g = 1
```

`gate_ratio` 和 `gate_quad_ratio` 仅作为无量纲归一化尺度，数值未改变。没有新增 `g_min`、`kappa`、第二阈值、hold time 或状态机。

代码中已明确注释：

```text
This is the M4-v0 structural implementation,
not the final frozen M4 formula.
```

## 4. Fault Evidence Implementation

连续 evidence 位于独立纯函数：

```text
MATLAB一键实验/m4_fault_evidence.m
```

该函数：

- 支持标量和数组输入，便于不依赖 Case05/06 的 synthetic monotonicity test；
- 对非有限输入、非法 gate scale 或负能量标记 `valid=false`；
- evidence 无效且未强制权重时采用 `g=1` 的 fail-open 行为；
- `forced_update_weight` 只允许 `NaN` 或 `[0,1]` 内标量；
- `NaN` 表示正式 evidence 模式，`0/0.5/1` 只用于结构测试。

M4 控制路径不读取真实 Cs、故障标签、真实 fault factor、`r_fault`、counterfactual、未来样本、case name 或 Case05/06 特殊分支。

## 5. Information-State Weighted Update

先完全复用 M2 的局部 LS innovation 和 VFF lambda：

\[
\hat c_{LS,k}=(R_k+10^{-10}I)^{-1}z_k,
\]

\[
\nu_k=\left\|\frac{\hat c_{LS,k}-c_{k-1}}{[5,5]^T}\right\|_2,
\]

\[
\lambda_k=\lambda_{max}-(\lambda_{max}-\lambda_{min})
clip\left(\frac{\nu_k}{0.20},0,1\right).
\]

lambda 不参与 fault classification。

原 M2 信息候选为：

\[
J_k^*=\lambda_kJ_{k-1}+R_k,
\qquad
h_k^*=\lambda_kh_{k-1}+z_k.
\]

M4-v0 应用：

\[
J_k=J_{k-1}+g_k(J_k^*-J_{k-1}),
\]

\[
h_k=h_{k-1}+g_k(h_k^*-h_{k-1}).
\]

之后：

\[
c_{raw,k}=(J_k+10^{-10}I)^{-1}h_k.
\]

执行顺序保持为：

```text
weighted information state
→ raw parameter candidate
→ existing rate limit
→ existing [0,40] pF physical projection
→ final c
```

为保证端点严格成立，代码对 `g==0` 和 `g==1` 使用精确端点分支。该分支不是新的 fault threshold；自然公式在有限 evidence 下不会产生 `g=0`。

## 6. baseIn Weighted Update

先按原 M2 逻辑生成候选：

\[
baseIn_k^*=\begin{cases}
0.985baseIn_{k-1}+0.015E_{in,k}, &
E_{in,k}<1.08baseIn_{k-1},\\
baseIn_{k-1}, & otherwise.
\end{cases}
\]

再执行：

\[
baseIn_k=baseIn_{k-1}+g_k(baseIn_k^*-baseIn_{k-1}).
\]

所以：

- `g=1`：与原 M2 baseline 更新一致；
- `g=0`：`baseIn` 严格保持；
- `0<g<1`：候选 baseline 增量按相同比例连续缩放。

没有增加额外 baseline freeze threshold。

## 7. Direction Diagnostic Implementation

每周期残差谐波拟合除 `E_in/E_quad` 外，还输出三相拼接的同相拟合残差样本向量 `e_in_vector`。

候选故障方向：

\[
q_k=(R_k+10^{-10}I)^{-1}X_k^Te_{in,k},
\qquad
d_{f,k}=\frac{q_k}{\|q_k\|_2+\epsilon}.
\]

同时计算：

\[
\delta c_{local,k}=\hat c_{LS,k}-c_{k-1},
\qquad
\delta c_{raw,k}=c_{raw,k}-c_{k-1},
\]

以及：

- `cos_local_fault`；
- `cos_raw_fault`；
- `delta_c_parallel`；
- `delta_c_perpendicular`。

方向有效性要求：

- residual harmonic fitting 有效；
- `q`、local update、raw update 范数大于基于 `sqrt(eps)` 的数值阈值；
- `cond(R) <= 1/sqrt(eps)`；
- 所有相关量有限。

无效时方向、余弦和平行/正交分量均输出 NaN，不能用 0 冒充有效结果。

方向诊断通过独立开关可完全禁用。启用和禁用时，`g/J/h/c/baseIn` 及最终输出逐项完全相同。方向量没有反馈到 evidence 或控制律。

## 8. Files Added / Modified

### 新增

| 文件 | 用途 |
|---|---|
| `MATLAB一键实验/m4_fault_evidence.m` | 零新增调参的连续 evidence 纯函数 |
| `MATLAB一键实验/track_coupling_m4_weighted_rls.m` | 独立 M4-v0 tracker、完整日志和方向诊断 |
| `MATLAB一键实验/tests/M4WeightedInformationUpdateTest.m` | Test A–G 的 class-based 单元/结构测试 |
| `paper_research/phase1c_m4_method/STEP2_M4_IMPLEMENTATION.md` | 本报告 |

### 最小修改

| 文件 | 修改原因 |
|---|---|
| `phase1a_algorithm_registry.m` | 注册 M4 及 capability 字段 |
| `run_phase1a_algorithm.m` | 增加独立 M4 dispatcher 分支 |
| `run_phase1a_baseline.m` | 仅运行 `include_in_frozen_baseline=true` 的 M0/M2/M3；增加向后兼容的可选输出目录供临时回归 |
| `run_phase1a_smoke_test.m` | 继续只运行冻结 baseline algorithms |
| `tests/Phase1AAlgorithmDispatcherTest.m` | 验证 M4 注册/调度及冻结算法筛选 |

### 明确未修改

```text
AI6109_MOA_AutoComp9.slx
track_coupling_cvff_rls.m
Case01–Case06 definitions
patent_default_config.m
Phase 1A result schema / historical reference
Phase 1A historical CSV/MAT/reports
Phase 1B formal results
```

## 9. Algorithm Registry Integration

M4 注册项：

```text
algorithm_mode = M4
algorithm_name = M4_weighted_information_update
adaptive = true
continuous_update_weight = true
hard_fault_gate = false
direction_diagnostics = true
include_in_frozen_baseline = false
```

M0/M2/M3 的 `include_in_frozen_baseline=true`。因此：

- dispatcher 可以显式运行 M4；
- Phase 1A formal baseline 和 historical smoke 仍严格运行 M0/M2/M3；
- 冻结主表仍为 6 cases × 3 algorithms = 18 rows；
- M4 诊断不会改变 Phase 1A 冻结 schema。

## 10. Logging Schema

M4 周期日志包含任务要求的全部字段：

```text
time_s, Cs1_pF, Cs2_pF
lambda, innovation_scalar, local_ls_Cs1_pF, local_ls_Cs2_pF
E_in, E_quad, base_in
evidence_ratio_base, evidence_ratio_quad
evidence_background_excess, evidence_phase_weight
fault_evidence_score, update_weight
delta_c_local_1/2
delta_c_raw_1/2
delta_c_applied_1/2
delta_c_suppressed_1/2
J_increment_norm_raw/applied
h_increment_norm_raw/applied
rate_limit_active, projection_active
m4_evidence_valid
fault_direction_candidate_1/2
direction_candidate_valid
cos_local_fault, cos_raw_fault
delta_c_parallel_1/2
delta_c_perpendicular_1/2
R_condition_number
```

为区分三类抑制，还额外记录：

```text
delta_c_m2_raw_1/2
delta_c_after_rate_1/2
delta_c_information_suppressed_1/2
delta_c_rate_suppressed_1/2
delta_c_projection_suppressed_1/2
```

结构测试所需的完整 `J/h` 状态和元素级 raw/applied increments 也保留在算法专属 cycle log 中，不扩展冻结 baseline 主表。

## 11. Forced-g Endpoint Tests

测试类：`M4WeightedInformationUpdateTest`。

### Test A — forced `g=1`

结果：**PASS**。

- M4 `cHist/Cs1/Cs2/lambda/baseIn` 与实际 M2 比较通过；
- `J/h` 与独立 M2 信息状态重放比较通过；
- rate/projection flags 比较通过；
- A/B/C 最终阻性电流比较通过；
- Cs 容差 `1e-12 pF`，lambda/baseIn 容差 `1e-15`，电流容差 `1e-15 A`，J/h 使用 machine-level relative tolerance。

### Test B — forced `g=0`

结果：**PASS**。

进入有效周期后：

```text
J unchanged
h unchanged
c unchanged
baseIn unchanged
delta_c_applied = [0,0]
```

均以零绝对容差验证。不存在隐藏信息积累。

### Test C — forced `g=0.5`

结果：**PASS**。

元素级验证：

\[
\Delta J_{applied}=0.5\Delta J_{raw},
\qquad
\Delta h_{applied}=0.5\Delta h_{raw}.
\]

`baseIn` applied increment 与 `0.5 × candidate increment` 的最大浮点消去误差小于 `5e-20 A`。

首次测试为 7/8 PASS，唯一失败是该 baseline 增量断言原绝对容差 `1e-20 A` 小于实际浮点消去误差 `2.7105e-20 A`。只将测试容差调整为 `5e-20 A`，没有修改算法、公式或参数；重跑后 8/8 PASS。

## 12. Evidence Monotonicity Tests

### Test D — background monotonicity

结果：**PASS**。

固定 `E_quad/baseIn/gate ratios` 并单调增加 `E_in`：

- `fault_evidence_score` 非递减；
- `update_weight` 非递增；
- 全部自然权重满足 `0<g<=1`；
- `E_in<=baseIn` 时 `g=1` 精确成立。

### Test E — phase consistency

结果：**PASS**。

固定 `E_in/baseIn`，单调增加 `E_in/E_quad`：

- `evidence_phase_weight` 非递减；
- fault evidence 非递减；
- update weight 非递增。

测试输入为 synthetic evidence，不使用 Case05/06，也没有性能调参。

## 13. No-Truth-Leakage Check

结果：**PASS**。

静态扫描 M4 tracker 与 evidence helper，控制路径不存在：

```text
Cs1_true / Cs2_true
fault_factor_true
fault_label
r_fault
counterfactual
Case05 / Case06
case_name
```

M4 只使用当前/历史 `data/ref/X/y/R/z`、递归状态、残差拟合量和既有 cfg 参数。

## 14. Direction-Diagnostic Independence Check

结果：**PASS**。

在相同输入和 forced `g=0.5` 下分别启用/禁用方向诊断：

- `hist` 以零绝对容差完全相同；
- `g/J/h/c/baseIn/lambda/raw/applied update` 以零绝对容差完全相同；
- 禁用时 `direction_candidate_valid=false`；
- 禁用时方向余弦和投影量为 NaN。

因此当前方向路径严格为 diagnostic-only。

## 15. Phase1A Regression Results

### Formal validator

为了不覆盖冻结结果，`run_phase1a_baseline` 使用可选临时输出目录运行。正式历史路径未写入。

```text
6 cases × 3 frozen algorithms = 18 rows
Formal validator A–S = 19/19 PASS
Frozen algorithm core during run = 14/14 hashes unchanged
Historical result directories untouched = PASS
```

临时回归 workspace 与冻结 `baseline_workspace.mat` 的 12 个数值指标逐项比较：

```text
WORKSPACE_NUMERIC_EXACT = true
M0/M2/M3 maximum absolute difference = 0
```

一次附加 CSV 二进制精确比较得到最大 `4.2632564145606011e-14` 的差异，原因是 CSV 十进制序列化/读取往返；随后使用两个 workspace 的原始 double 比较确认差值严格为 0。该 CSV 精确断言不作为算法回归失败。

### Historical regression

```text
Case02 = 4/4 PASS
Case06 = 7/7 PASS
Total = 11/11 PASS
```

### MATLAB test suite

```text
M4 structural tests = 8/8 PASS
M4 + dispatcher focused tests = 18/18 PASS
MATLAB一键实验/tests full suite = 61/61 PASS
```

模型运行仍显示既有测量端口和 algebraic-loop warnings，但没有 error；本步骤未修改模型。

## 16. Known Limitations

1. M4-v0 是标量连续权重，对所有信息方向统一缩放；当前不是 direction-aware controller。
2. 方向候选只记录，不参与 `g/J/h/c/baseIn`。
3. 尚未验证 M4 是否早于 M3 hard gate 开始抑制。
4. 尚未验证 M4 在 Case05/06 的 fault retention，也没有与 M3 排名。
5. 尚未测试真实漂移与故障同时存在时的性能。
6. reference phase error 或其他正常模型失配仍可能提高 `E_in` 并造成误保护。
7. Case06 真实漂移方向 `[+3,-2]` 与故障诱导方向约 `[+1,-1]` 的余弦相似度约为 `0.981`。这仍是不可删除的 identifiability warning；当前实现没有解决共线漂移/故障分解。
8. M4-v0 公式是 Step 2 结构冻结，不是最终论文或专利公式。

## 17. Step 2 Acceptance Conclusion

| 验收项 | 结果 |
|---|---|
| M4 独立文件 | PASS |
| M2/M3 源码未修改 | PASS |
| `g=1` reproduces M2 | PASS |
| `g=0` fully freezes J/h/c/baseIn | PASS |
| `g=0.5` information increments exact within numerical tolerance | PASS |
| evidence monotonic | PASS |
| `0<g<=1` | PASS |
| no truth leakage | PASS |
| direction path diagnostic-only | PASS |
| rate/projection order unchanged | PASS |
| M0/M2/M3 historical outputs unchanged | PASS，workspace max diff = 0 |
| formal validator | 19/19 PASS |
| historical regression | 11/11 PASS |
| logs complete | PASS |

```text
STEP 2 STATUS:
PASS

M4 VERSION:
M4-v0 — Residual-Evidence Weighted Information Update

DIRECTION CONTROL STATUS:
DIAGNOSTIC ONLY

PERFORMANCE CLAIM STATUS:
NOT EVALUATED
```

Step 2 完成后停止；未进入 Step 3。
