# Phase 1B-2 — Case05 Baseline Fault Absorption Mechanism

执行日期：2026-09-17  
研究对象：`Case05_fault_only`  
正式结论：`STEP2_BASELINE_MECHANISM = PASS`

本步骤只研究冻结 Case05。未运行 Case06，未修改 AutoComp9、Phase 1A、原 tracker 或 Step 1 定义，未开发 M4、soft gate 或新 lambda。

---

## 1. Scope and integrity

### 1.1 开始状态

| 项目 | 值 | 结果 |
|---|---|---|
| Git branch | `main` | PASS |
| Git commit | `91e1b3efc8d2bf637c3fa30865d44c7691330fe5` | PASS |
| AutoComp9 SHA-256 | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` | PASS |
| Phase 1A CSV SHA-256 | `E7BEB3ECFEDF521105B67198684752BB32AFAAEFD84ACA80822BA57FBD9D0AB3` | PASS |
| Step 1 report SHA-256 | `02859DD0D35E35C18722B452DC7A5C9EE73B55CC6E7A26FC5566500F6E4B9041` | PASS |

冻结配置未调整：Case05 seed=`106`，SNR=`30 dB`，故障轨迹 `3.00–3.06 s`、`1.0→1.6`，`lambda_min/max=0.55/0.995`，rate limit=`1.2 pF/cycle`，projection=`[0,40] pF`。

### 1.2 新增实现

所有新增代码和结果均位于：

```text
paper_research/phase1b_fault_absorption/step2/
```

核心文件：

- `run_phase1b_step2_case05.m`：完整编排、完整性闸门、正式输出；
- `instrument_phase1b_vff_rls.m`：独立 M2 replay、fault/counterfactual 递归分支和可观测状态日志；
- `build_phase1b_fault_component.m`：严格恢复 `r_fault`；
- `analyze_fault_projection.m`：SVD/QR 几何投影；
- `generate_phase1b_step2_figures.m`：七组正式图。

原 `track_coupling_cvff_rls.m` 只作为等价性参考调用，没有修改。

---

## 2. Instrumentation equivalence

独立 replay 按原 M2 顺序重新实现：

```text
X/y → R/z → local LS → innovation → lambda
→ E_in/E_quad → J/h → raw cNew
→ rate limit → physical projection → baseIn
```

它与同一冻结 Case05 数据上的原 tracker 逐周期比较：

| 比较量 | max absolute difference | 阈值 | 结果 |
|---|---:|---:|---|
| Cs1 | `0` | `1e-12 pF` | PASS |
| Cs2 | `0` | `1e-12 pF` | PASS |
| lambda | `0` | `1e-12` | PASS |
| E_in | `0` | `1e-12 A` | PASS |
| E_quad | `0` | `1e-12 A` | PASS |
| baseIn | `0` | `1e-12 A` | PASS |
| gate | `0` | `1e-12` | PASS |

重新生成的 Case05 时域数据、M2 `cHist/cycle` 和辅助 M3 `cHist` 也与冻结 `baseline_workspace.mat` 在 `1e-12` 内一致；正式 Phase 1A Case05 数值精确复现。

因此后续机理分析使用的 fault branch 是原 M2 的数值等价 replay，不是近似替代算法。

---

## 3. Strict fault construction

按 Step 1 冻结定义：

\[
i_{B,R,true}=-g(t)i_{B,R,raw},
\]

\[
r_{f,B}(t)=\left(1-\frac{1}{g(t)}\right)i_{B,R,true}(t).
\]

每周期以与 `coupling_regressor` 完全相同的排列构造：

\[
\boldsymbol r_{f,k}=
\begin{bmatrix}0_A&r_{f,B}&0_C\end{bmatrix}^{\mathsf T}
\in\mathbb R^{3000}.
\]

同时定义：

\[
\boldsymbol y_{cf,k}=\boldsymbol y_{fault,k}-\boldsymbol r_{f,k}.
\]

检查结果：

- X 为 `3000×2`；
- `r_fault/y_fault/y_counterfactual` 均为 `3000×1`；
- 相顺序为 A 全周期、B 全周期、C 全周期；
- 单位均在同一 observation space 中为 A；
- `y_fault-y_counterfactual-r_fault` 的最大绝对误差为浮点零量级；
- 未使用 `y-X*c_est` 作为故障真值。

正式 observation blocks 已独立保存，可复算每个周期的 X、y 和 r_fault。

---

## 4. X conditioning and rank

全部 165 个在线周期均使用 economy SVD 检查 X：

| 指标 | 结果 |
|---|---:|
| `rank(X)` | 全部为 `2` |
| `cond2(X)` minimum | `1.29099444873578` |
| `cond2(X)` maximum | `1.29099444873585` |
| `cond2(X)` mean | `1.29099444873580` |

X 在 Case05 中满列秩且条件良好。下述投影和 `X\r_fault` 结果不存在由病态矩阵放大的证据。

---

## 5. Geometric fault projection

定义：

\[
r_{\parallel}=Q_XQ_X^Tr_f,
\qquad
r_{\perp}=r_f-r_{\parallel},
\]

\[
\eta_{geom}=\frac{\|r_{\parallel}\|^2}{\|r_f\|^2}.
\]

无故障周期的 `eta_geom` 按冻结规则保存为 NaN。故障周期结果：

| 区间 | eta_geom |
|---|---:|
| fault ramp average | `0.235466619851413` |
| post-fault average | `0.275451415244565` |
| fault-cycle minimum | `0.173363711368723` |
| fault-cycle maximum | `0.275451415244936` |

能量闭合最大相对误差：

```text
5.49813204261326e-15 <= 1e-10  PASS
```

`X*Delta c_LS,f` 与 `r_parallel` 也通过数值一致性检查。

物理解释：故障完全建立后，约 `27.55%` 的完整三相 observation-space 故障能量位于当前两列耦合模型的列空间中。该数值是几何可表达性，不是算法最终吸收百分比。ramp 期 `eta_geom` 从约 0.17 增至 0.275，是因为倍率在一个周期内变化，故障波形方向尚未达到稳态；并非单纯因为幅值变大。

---

## 6. Static LS fault bias

稳定计算：

\[
\Delta c_{LS,f}=X\backslash r_f.
\]

结果从第一个含故障样本的周期即出现 `Cs1>0`、`Cs2<0`：

| 指标 | Delta Cs1 / pF | Delta Cs2 / pF |
|---|---:|---:|
| first fault cycle, `3.00000–3.01998 s` | `+0.395164` | `-0.473056` |
| three ramp cycles mean | `+2.393390` | `-2.493214` |
| steady window mean | `+4.886604` | `-4.886604` |

稳态静态 LS 偏差与最终 M2 的 `+4.9168/-4.9570 pF` 方向和数量级一致。它正确预测了故障在耦合参数空间中的最终平衡方向，但不描述达到该平衡所需的递归时间，也不包含正常噪声导致的 counterfactual 小漂移。

---

## 7. Direct VFF-RLS fault contribution

按冻结定义：

\[
\Delta c_{RLS,f,direct}=
(\lambda J_{k-1}+R_k+10^{-10}I)^{-1}X_k^Tr_{f,k}.
\]

该量使用 fault branch 当期历史状态和同一个 lambda，只表示当前周期的直接 unconstrained 故障贡献。

| 区间 | direct Cs1 / pF/cycle | direct Cs2 / pF/cycle |
|---|---:|---:|
| first fault cycle | `+0.054495` | `-0.065237` |
| ramp mean | `+0.569624` | `-0.589742` |
| steady-window mean | `+0.680395` | `-0.680395` |

对比可见：静态 LS 稳态偏差约 `±4.887 pF`，而 direct RLS 单周期贡献约 `±0.68 pF`。实际参数不会每周期继续增加 0.68 pF，因为历史 h/J、已有 c 与当前残差共同形成反向平衡项；稳态窗口实际平均更新仅为 Cs1 `+0.00799 pF/cycle`、Cs2 `+0.00322 pF/cycle`。

因此 direct term 不能被当作实际周期更新或累计漂移。

---

## 8. Recursive fault/counterfactual replay

### 8.1 分支定义

故障前两个分支共享完全相同的 c/J/h/baseIn/history。第一个含故障样本的完整周期为：

```text
cycle 116
3.00000–3.01998 s
```

之后：

- fault branch 使用 `y_fault` 并递归保存自己的全部状态；
- counterfactual branch 使用 `y_fault-r_fault` 并递归保存自己的全部状态；
- 没有在每周期把 counterfactual 状态重置为 fault branch。

### 8.2 Phase 1A 同窗口比较

严格复用 Phase 1A：

```text
pre  = [2.60,2.90) s
post = [3.40,3.80) s
Delta Cs = mean(post)-mean(pre)
```

| 指标 | Cs1 / pF | Cs2 / pF |
|---|---:|---:|
| Phase 1A actual M2 | `+4.9167737453` | `-4.9569944566` |
| fault replay | 与 actual 完全一致 | 与 actual 完全一致 |
| counterfactual branch | `+0.0303943857` | `-0.0712814697` |
| recursive fault-induced = fault − counterfactual | `+4.8863793596` | `-4.8857129869` |
| predicted minus actual | `-0.0303943857` | `+0.0712814697` |
| relative difference | `-0.6182%` | `+1.4380%` |

递归 fault/counterfactual 差异解释了正式约 `+4.9/-5.0 pF` 的主要数量级。剩余差异恰好是相同噪声和正常模型残差下 counterfactual estimator 的小幅基线变化，不是机理缺项。

---

## 9. Lambda feedback

| 区间 | lambda fault | lambda counterfactual | fault − cf |
|---|---:|---:|---:|
| pre-fault mean | `0.873952` | `0.873952` | `0` |
| fault ramp mean | `0.590783` | `0.880154` | `-0.289370` |
| steady post window mean | `0.880369` | `0.880874` | `-0.000504` |

故障斜坡使 local LS innovation 的 ramp 均值由 counterfactual 的 `0.05162` 增至 `0.65935`，主动把 lambda 拉低。第一个故障周期 lambda 为 `0.67235`，counterfactual 为 `0.85508`；故障期最大绝对 lambda 差为 `0.41031`。参数逐渐吸收故障后，innovation 和 lambda 回到接近 counterfactual 的水平。

为量化而非预设 lambda 贡献，增加了一个可选 diagnostic：使用真实 `y_fault`，但每周期强制采用 counterfactual lambda，其他状态独立递归。其 Phase 1A 窗口参数变化为：

```text
Cs1 = +4.783146 pF
Cs2 = -4.825003 pF
```

相对真实 fault branch，lambda feedback 对最终变化的增量约为：

```text
Cs1 = +0.133627 pF
Cs2 = -0.131992 pF
```

约占 fault-induced `±4.886 pF` 的 2.7%。结论是：VFF 明显加快故障初始跟随，并有小幅最终放大，但不是 Case05 约 ±5 pF 吸收的主要来源；主要来源是持续故障方向与 `col(X)` 的稳定重合及递归信息状态收敛。

---

## 10. Rate limit and physical projection

故障期间 raw 单周期最大更新需求为：

```text
Cs1: 1.117322 pF/cycle
Cs2: 1.076082 pF/cycle
```

均低于 `1.2 pF/cycle`，所以：

| 约束 | Cs1 active cycles | Cs2 active cycles |
|---|---:|---:|
| rate limit | `0` | `0` |
| `[0,40] pF` projection | `0` | `0` |

所有 fault cycle 上 `c_raw == c_rate_limited == c_projected`，数值最大差为 0。

因此：

```text
physical projection is inactive in Case05 fault absorption
rate limit is also inactive in Case05 fault absorption
```

约 ±5 pF 的错误参数是在多个递归周期中逐步收敛形成，但不是由 rate limiter 强制分段形成。这一点与预先可能的解释不同，必须以数据结论为准。

---

## 11. J/h state inconsistency

计算归一化状态不一致：

\[
d_{state,rel}=\frac{\|h-Jc\|_2}{\max(\|h\|_2,\epsilon)}.
\]

| 区间 | mean relative mismatch |
|---|---:|
| pre-fault | `3.9485e-6` |
| fault ramp | `6.7856e-6` |
| steady post | `4.9842e-6` |
| post-fault maximum | `1.4994e-5` |

该量在 fault ramp 略有增加，但整体很小；又因为 rate limit/projection 未触发，本工况中 J/h 与 constrained c 的状态不一致不是主要放大因素。它仍说明实际实现不能无条件简化为 textbook covariance-form RLS，但不足以解释 ±5 pF 主漂移。

---

## 12. Fault-retention mechanism

### 12.1 故障倍率闭环

| 路径 | estimated fault factor | retention error |
|---|---:|---:|
| truth | `1.6000000000` | — |
| original/replayed M2 | `1.4010747974` | `-12.432825%` |
| counterfactual parameter path applied to actual fault data | `1.6010511543` | `+0.065697%` |
| M3 auxiliary reference | `1.5811371121` | `-1.178930%` |

counterfactual branch 中故障不进入参数更新后，Cs false drift 基本消失；把该 counterfactual Cs 轨迹用于真实含故障总电流时，故障倍率恢复到 1.6011，接近 truth 1.6000。这是参数漂移与故障保持损失之间的直接闭环证据。

### 12.2 B 相耦合补偿变化

由 fault/counterfactual 参数差产生：

\[
\Delta i_{coupling,B}=
\Delta C_{s1}(\dot u_B-\dot u_A)+
\Delta C_{s2}(\dot u_B-\dot u_C).
\]

在 `[3.40,3.80) s`：

| 指标 | 值 |
|---|---:|
| `r_fault,B` 基波 RMS | `0.506607 mA` |
| false coupling compensation 基波 RMS | `0.168850 mA` |
| 幅值比 | `0.333295` |
| 基波相位差 | `0.00677°` |
| 波形相关系数 | `0.90904` |

虚假耦合补偿与真实阻性故障基波几乎同相，幅值约为故障增量的三分之一。提取阻性电流时该补偿被扣除，使理论 `1.0+0.6` 的故障增幅约损失 `0.6×1/3≈0.2`，与实际 `1.4011` 一致。

完整证据链为：

```text
r_fault 与 col(X) 有稳定重合
→ 静态等效方向为 Cs1 正、Cs2 负
→ M2 递归收敛到约 +4.9/-4.9 pF 偏差
→ B 相虚假耦合补偿与 r_fault 近同相，幅值约 1/3
→ 阻性增量被错误扣除
→ fault factor 从 1.6000 降为 1.4011
```

---

## 13. E_in / E_quad timeline

| 区间 | E_in / mA | E_quad / mA |
|---|---:|---:|
| pre-fault mean | `0.927120` | `0.012353` |
| fault ramp mean | `1.034603` | `0.015978` |
| steady post mean | `1.126072` | `0.119688` |
| post relative change | `+21.459%` | `+868.877%` |

`E_quad` 的相对百分比很大是因为其 pre-fault 基数接近零；绝对值仍远小于 `E_in`。现有 M3 双阈值条件在 50 个 fault-containing 周期中的 48 个周期成立，与历史 M3 48-cycle gate 一致。

因果时序为：

```text
3.00 s fault onset
→ 同周期 local LS innovation 上升
→ lambda 下降
→ M2 参数开始沿 +Cs1/-Cs2 更新
→ E_in 升高并满足 fault-evidence 阈值
→ 参数逐步吸收后 innovation/lambda 接近正常水平
```

代码层面必须区分：

- M2 的参数更新驱动来自 X/y、local LS innovation、lambda 和 J/h；
- `E_in/E_quad` 在 M2 中只被计算和记录，不参与更新；
- 它们只有在 `enableGate=true` 的 M3 中才作为 fault detector evidence 冻结更新。

因此 `E_in/E_quad` 是故障证据，不是 M2 漂移的直接 update signal。

---

## 14. Core figures

全部图同时保存 PNG 和 FIG，并已完成视觉检查：

1. `figure1_case05_false_cs_drift`：Cs truth 不变而 M2 在 3.0 s 后发生正/负虚假漂移；
2. `figure2_case05_fault_geometric_decomposition`：代表稳态周期的 A/B/C 完整投影分解；
3. `figure3_case05_eta_geom_static_bias`：eta_geom 和静态 LS 偏差时间线；
4. `figure4_case05_recursive_parameter_bias`：fault replay、counterfactual 和累计差；
5. `figure5_case05_ls_direct_recursive_relationship`：静态、direct 与实际周期/累计量分轴比较；
6. `figure6_case05_lambda_innovation_rate_limit`：innovation、lambda、rate-limit 与 fault profile；
7. `figure7_case05_ein_equad_timeline`：E_in/E_quad/baseIn/阈值和严格故障时序。

---

## 15. Quantitative summary and Q1–Q12

### Q1 — Cs truth 不变时 M2 是否仍有显著虚假漂移？

**是。** truth 全程 10/10 pF，M2 正式变化为 `+4.9168/-4.9570 pF`。

### Q2 — r_fault 是否显著落入 col(X)？

**是。** 满故障后约 27.55% 的 observation-space 故障能量位于 `col(X)`。

### Q3 — eta_geom 是多少，含义是什么？

ramp 平均 `0.23547`，post 平均 `0.27545`，范围 `0.17336–0.27545`。它表示几何可表达故障能量比例，不表示最终算法吸收比例。

### Q4 — 静态 Delta c_LS,f 是否预测方向和数量级？

**是。** steady 静态偏差 `+4.8866/-4.8866 pF`，与实际 `+4.9168/-4.9570 pF` 同方向、同数量级；它不描述递归时间和 counterfactual 小漂移。

### Q5 — direct RLS 与静态 LS 有何不同？

静态 LS 给出当前 block 的最终等效偏差；direct RLS 在现有 J/h/lambda 下每周期仅贡献约 `±0.68 pF`，且不能等同于实际更新。稳态时其他历史项抵消 direct term，实际更新趋近零。

### Q6 — 递归双分支能否预测约 +4.9/-5.0 pF？

**能。** fault-induced 预测为 `+4.8864/-4.8857 pF`；与实际的差异仅 `-0.0304/+0.0713 pF`，对应 counterfactual 正常小漂移。

### Q7 — VFF lambda feedback 贡献多大？

ramp 期 lambda 从 counterfactual `0.8802` 降至 `0.5908`，明显加快初始跟随；lambda-neutral diagnostic 表明最终贡献约 `+0.1336/-0.1320 pF`，约占总 fault-induced 偏差的 2.7%，不是主因。

### Q8 — rate limit 是否使错误 Cs 分周期累积？

**否。** 参数确实递归多周期累积，但 raw 更新最大值低于 1.2 pF/cycle，rate limit 触发 0 周期。

### Q9 — physical projection 是否参与？

**否。** Cs1/Cs2 projection 均为 0 active cycles。

### Q10 — J/h 与 constrained c 不一致是否明显影响？

本工况中归一化 mismatch 最大 `1.50e-5`，较小，不是主要机制。

### Q11 — 虚假 Cs 能否解释 1.6000→1.4011？

**能。** false coupling compensation 与 r_fault 基波近同相、幅值约为其 1/3；counterfactual 参数路径把估计倍率恢复至 `1.6011`。

### Q12 — E_in/E_quad 是 evidence 还是 update driver？

它们在 fault onset 后给出明确 evidence，并满足 M3 gate 判据；但 M2 中不进入 J/h/c 更新，因此不是直接 update driver。

---

## 16. Limitations

1. 本报告只验证 Case05 单一 seed、单一 30 dB 噪声实现；不外推到统计鲁棒性。
2. eta_geom 属于当前 AB/BC 两列模型和理想 B 相参考；不能外推到一般耦合矩阵或传感器误差。
3. lambda-neutral branch 是本步骤用于归因的辅助 diagnostic，不是新算法或性能方案。
4. 现有模型故障不反馈改变电压，因此可代数构造 counterfactual；未来闭环电网模型需要 paired run。
5. 本步骤没有运行 Case06；漂移后故障的可迁移性留给 Phase 1B-3。

---

## 17. Step 2 acceptance

| ID | 验收项 | 结果 |
|---|---|---|
| A | Phase 1A integrity | PASS |
| B | instrumentation replay matches original M2 | PASS，最大误差 0 |
| C | strict r_fault constructed | PASS |
| D | X/r_fault alignment verified | PASS，`3000×2` / `3000×1` |
| E | projection energy closure | PASS，max `5.50e-15` |
| F | eta_geom computed | PASS |
| G | static Delta c_LS computed | PASS |
| H | dynamic direct RLS term computed | PASS |
| I | recursive fault/counterfactual branches | PASS |
| J | actual vs predicted parameter bias | PASS |
| K | lambda/rate/projection influence identified | PASS |
| L | retention loss linked to parameter drift | PASS |
| M | seven PNG/FIG figure pairs | PASS |
| N | CSV/workspace/observation MAT saved | PASS |
| O | no forbidden modifications or Case06 run | PASS |

正式结果：

```text
STEP2_BASELINE_MECHANISM: PASS
```

```text
ready for Phase 1B-3 Case06 verification
```

本步骤在此停止，不自动执行 Phase 1B-3，不运行 Case06，不开发 M4。
