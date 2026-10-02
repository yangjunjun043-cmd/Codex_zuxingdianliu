# M5 Step3 正式实验预注册

## 1. 状态、用途与停止边界

本文冻结 M5 Step4 的确定性实验矩阵、研究问题、算法角色、漂移几何、指标、比较方式、历史复用规则及 GO/STOP 判据。冻结日期为 2026-09-30。

```text
DOCUMENT_ROLE: PREREGISTRATION
M5_PERFORMANCE_EXPERIMENT: NOT RUN
MONTE_CARLO: NOT RUN
METHOD_TUNING: PROHIBITED
STEP4_AUTHORIZED_BY_THIS_FILE: NO, PENDING HUMAN REVIEW
```

Step3 没有运行 M5 性能实验，没有查看未注册的 M5 性能预览，也没有修改 M2、M3、M4、M5、REW、hard gate、Simulink 模型、Phase2 registry 或历史 CSV。本文只允许在人工审核通过后作为 Step4 deterministic core 的执行合同。

## 2. 权威来源与版本冻结

本预注册以 Phase1A/1B、M4、Phase2、M5 Step0–Step2 的冻结材料为权威来源。算法及模型版本固定如下。

| 对象 | 版本或模式 | SHA-256 |
|---|---|---|
| Simulink model | `AI6109_MOA_AutoComp9.slx` | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| default config | `patent_default_config.m` | `D9F3E6894F51C3D978421C9E1E93828A9205F418C77D01AC449B994A3D789726` |
| M2/M3 source | `track_coupling_cvff_rls.m` | `033135775D81BE4521AA76B8C6C2C8C3415988DA8870561722779DB0FC485D7E` |
| M4 source | `track_coupling_m4_weighted_rls.m` | `A0504AD65B490F803AED454BF4D8CD2C6F724D0A96DF60502F7F32789521EEC1` |
| REW evidence | `m4_fault_evidence.m` | `486FF017CE4491C84FBBF84D042EF661A5AFC5A8D255F0B88AC583304D593D15` |
| M5 tracker / GH / GC | `track_coupling_m5_directional_rls.m` | `8B580215A6268F4AC3BF27FB357DB6A4A01027DD2410C7FF59EA3C4B46DA4DDB` |
| M5 projector helper | `m5_directional_update.m` | `47D2C12DB80F4BBFE7CE296841074DB6F3FF641CD769907666292E4398E06CA7` |
| regressor | `coupling_regressor.m` | `7582F66875A1099DF9656F9A89FE12D8FF6972C55D4A034736527A7DB00E03D5` |

Step4 开始前和结束后必须重新计算这些哈希。任一不一致都使 Step4 停止，不得通过修改预注册来迁就源码变化。

## 3. 冻结方法对象

参数顺序固定为

\[
\theta=[C_{s1},C_{s2}]^T=[C_{AB},C_{BC}]^T.
\]

模型导出的故障敏感方向及投影为

\[
d_f=[1,-1]^T/\sqrt{2},\quad P_f=d_fd_f^T,\quad P_\perp=I-P_f.
\]

M5-DH 和 M5-Full 分别使用继承的 `w_hard=1-gate` 与冻结的 `w_REW`：

\[
\Delta\theta_{dir}=P_\perp\Delta\theta_{raw}+wP_f\Delta\theta_{raw}.
\]

GH 和 GC 采用同一 raw proposal、state reconciliation、rate limit、projection 与 baseIn 路径，唯一结构差异是使用

\[
\Delta\theta_{global}=w\Delta\theta_{raw}.
\]

M5 新增可调超参数保持为 0。

## 4. 科学问题

- **RQ1 Fault preservation：** pure resistive fault 下，directional protection 是否减少 fault-induced parameter absorption？
- **RQ2 Legitimate adaptation：** coupling drift 与 fault 重叠时，directional scope 是否比 operator-matched global suppression 保留更多合法参数更新？
- **RQ3 Directionality mechanism：** M5 与 matched global control 的差异是否随真实漂移相对 `d_f` 的几何关系而变化？
- **RQ4 Identifiability boundary：** 当真实漂移与 `d_f` 共线时，M5 是否失去仅凭参数方向区分真实漂移与故障诱导更新的能力？
- **RQ5 Hard vs Continuous：** 在相同 scope 下，continuous REW 与 hard suppression 的 fault-preservation / adaptation 关系有何差异？

## 5. 算法角色

| 算法 | 角色 | Step4 用途 |
|---|---|---|
| M2 | historical unprotected baseline | fault absorption 与无保护跟踪参考 |
| M3 | historical global hard baseline | 实用历史比较，不作 matched factorial 归因 |
| M4 | historical global REW baseline | 实用历史比较，不作 matched factorial 归因 |
| GH | matched global hard control | Hard 条件下 Global vs Directional |
| GC | matched global continuous control | Continuous 条件下 Global vs Directional |
| M5-DH | directional hard ablation | Directional scope 下 Hard 分量 |
| M5-Full | primary candidate | Directional scope 下 Continuous 正式候选 |

M3/M4 的内部 state realization 与 M5 不同，因此 M3 vs M5-DH、M4 vs M5-Full 只能作为历史/实用比较。GH/GC 才是 scope 因子的严格配对对照。

## 6. 实验块与正式 case

### 6.1 Block A：no-fault / drift sanity

Block A 原样复用 Phase2 冻结 case 定义，不创建更容易通过的新基线。

| Case | 来源 | seed | 条件 | 评价窗口 |
|---|---|---:|---|---|
| `M5_A1_STATIC` | `P2_AN_C01 / Case01_static` | 101 | `Cs=[10,10] pF`，无漂移、无故障 | `t∈[0.80,4.00] s` |
| `M5_A2_DRIFT_ONLY` | `P2_AN_C02 / Case02_slow_drift` | 102 | `[10,10]→[14,7] pF`，漂移 `[1.00,3.00] s`，无故障 | `t∈[0.80,4.00] s` |

Block A 主要检查 `Cs tracking RMSE` 与 final signed Cs error；同时记录 `mean w_REW`、hard-gate active ratio、rate-limit cycles 和 projection cycles。Block A 不设置性能优化阈值。

### 6.2 Block B：pure-fault severity

只使用冻结的 Case05 persistent B-phase fault 定义，seed 固定为 106，`Cs=[10,10] pF`。severity grid 固定为：

```text
1.05, 1.10, 1.20, 1.30, 1.40, 1.60
```

预故障窗口固定为 `[2.60,2.90) s`，故障评价窗口为 `[3.40,3.80) s`，fault response onset 为 `3.00 s`。除 `fault_factor` 外，不改变 seed、噪声、相位、谐波、Cself、耦合真值、算法或评价定义。

### 6.3 Block C：controlled drift-geometry overlap

Block C 使用同一个漂移范数

\[
D_{ref}=\|[3,-2]^T\|_2=\sqrt{13}=3.605551275463989\ \mathrm{pF}.
\]

该值来自冻结 Case06/Phase2 overlap 的正式漂移向量，不根据 M5 结果选择。初始参数均为 `[10,10] pF`，三种方向为：

| Geometry | 单位方向 | 总漂移向量 (pF) | 最终参数 (pF) | 解释 |
|---|---|---|---|---|
| Orthogonal | `[1,1]/sqrt(2)` | `[+2.549509757,+2.549509757]` | `[12.549509757,12.549509757]` | 合法漂移全部位于 `P_perp` |
| Mixed | `[3,-2]/sqrt(13)` | `[+3,-2]` | `[13,8]` | 原样采用 Case06/Case07/08 方向 |
| Parallel | `[1,-1]/sqrt(2)` | `[+2.549509757,-2.549509757]` | `[12.549509757,7.450490243]` | 预注册 identifiability boundary |

每种方向只使用 `fault_factor=1.30` 和 `1.60`，共 6 个 case。所有 case 使用 seed 105、SNR 30 dB、Phase2 `WINDOWSET_OV_R10` timing：

```text
drift:       [0.80, 2.20] s
fault start: 1.50 s
ramp-up end: 1.56 s
plateau end: 1.90 s
fault end:   1.96 s
stop time:   4.00 s
```

评价窗口冻结为：

| 标签 | 区间 | 用途 |
|---|---|---|
| PRE | `[0.40,0.80)` | 漂移与故障前基线 |
| DRIFT_ONLY | `[1.20,1.45)` | Phase2 W0，只有真实漂移 |
| OVERLAP | `[1.62,1.74)` | Phase2 W1，早期 plateau overlap |
| LATE_OVERLAP | `[1.74,1.88)` | Phase2 W2，晚期 plateau overlap |
| POST_RECOVERY | `[2.40,2.80)` | Phase2 W4，辅助记忆指标 |

Block C 的 tracking primary metrics 使用 `W1∪W2`；W1/W2 fault retention 必须分别报告。不得把两个窗口合并后省略标签。

## 7. 指标冻结

### 7.1 参数误差

令

\[
e_\theta(t)=\hat\theta(t)-\theta_{true}(t).
\]

对注册窗口 `W`：

\[
RMSE_{total}=\sqrt{\operatorname{mean}_{t\in W}\|e_\theta(t)\|_2^2},
\]

\[
RMSE_{parallel}=\sqrt{\operatorname{mean}_{t\in W}\|P_fe_\theta(t)\|_2^2},
\]

\[
RMSE_{perp}=\sqrt{\operatorname{mean}_{t\in W}\|P_\perp e_\theta(t)\|_2^2}.
\]

Orthogonal 条件的几何关键指标是 `RMSE_perp`；Parallel 条件的几何关键指标是 `RMSE_parallel`。总 RMSE、平行 RMSE 与正交 RMSE均保存，不以其中一个替代另一个。Block A final error 保存两个带符号分量和 L2 norm。

### 7.2 Persistent-fault retention 与 bias

Block B 沿用 Phase2 定义：在同一 pre/fault 窗口估计 B 相阻性基波 RMS 比值

\[
f_{true}=I_{R,true,fault}/I_{R,true,pre},\qquad
f_{est}=I_{R,est,fault}/I_{R,est,pre},
\]

\[
retention\ error\ (\%)=100(f_{est}-f_{true})/f_{true}.
\]

主要指标使用其绝对值，但 CSV 同时保留 signed value。对 fault branch `F` 和 paired counterfactual `CF`，参数变化定义为 post-window 均值减 pre-window 均值：

\[
\Delta\theta_F=\bar\theta_{F,fault}-\bar\theta_{F,pre},\quad
\Delta\theta_{CF}=\bar\theta_{CF,fault}-\bar\theta_{CF,pre},
\]

\[
b_{fault}=\Delta\theta_F-\Delta\theta_{CF},\qquad
bias\ norm=\|b_{fault}\|_2.
\]

带符号 `Cs1/Cs2` 分量必须与 norm 一起保存。bias norm 只回答故障诱导参数吸收量，不是 tracking error 或 purity。

### 7.3 Temporary-overlap retention 与 bias

Block C 沿用 Phase2 的 matched temporary-fault 定义：

\[
r_W=(\hat I_{R,F,W}-\hat I_{R,CF,W})/(I_{R,F,W}-I_{R,CF,W}),
\]

\[
absolute\ retention\ error_W=|r_W-1|,
\]

其中 `W1` 与 `W2` 分别计算。故障诱导参数移动使用冻结 movement interval：最后一个 W0 样本到最后一个 W2 样本，计算 `Δθ_F-Δθ_CF` 的带符号分量及 L2 norm。该指标与 `RMSE_total/parallel/perp` 分开报告。

### 7.4 过程诊断

所有新运行都记录：hard gate active ratio、mean REW weight、parallel/perpendicular raw-update energy、rate-limit/projection activation、pre-constraint/post-rate/post-projection direction。near-zero update 保留为 `NaN` angle，不改写为 0°。这些量是机制和边界诊断，不进入综合评分。

## 8. Matched factorial 与历史比较

严格 2×2 为：

| Scope / weight | Hard | Continuous |
|---|---|---|
| Global matched | GH | GC |
| Directional | M5-DH | M5-Full |

四个预注册比较为：

1. GH vs M5-DH：Hard 下 Global vs Directional；
2. GC vs M5-Full：Continuous 下 Global vs Directional；
3. GH vs GC：Global 下 Hard vs Continuous；
4. M5-DH vs M5-Full：Directional 下 Hard vs Continuous。

对每个原始 error metric `m`，factorial interaction 原样计算为

\[
Interaction_m=(m_{M5-Full}-m_{GC})-(m_{M5-DH}-m_{GH}).
\]

负值表示 continuous 条件下 Directional-vs-Global 的 error difference 比 hard 条件更负。该符号解释必须附带原始四格结果，不转换为总分。

历史比较另行报告 M2、M3、M4、M5-Full。M4 vs M5-Full 的全部差异不得解释成 directionality effect。

## 9. 预注册假设

- **H1：** Block B 中，M5-Full 相对 M2 的 fault-induced bias norm 与 absolute retention error 应呈降低趋势。
- **H2：** Orthogonal overlap 中，M5-Full 相对 GC 应降低 `RMSE_perp`，因为 directional operator 不全局缩放 `P_perp` 更新。
- **H3：** Mixed overlap 中，M5-Full 相对 GC 应保留其非零 `P_perp` 漂移分量的部分适应能力；不预注册总 RMSE 必然改善。
- **H4：** Parallel overlap 中，M5-Full 不保证改善 `RMSE_parallel`，允许无优势或退化；该结果必须保留。
- **H5：** Continuous vs Hard 只通过 GH vs GC 和 M5-DH vs M5-Full 的同-scope 比较解释。

## 10. Step4 GO / STOP 判据

这些判据只使用预注册指标的符号和跨注册条件的一致性，不设置事后百分比门槛，也不使用综合排名。

### Gate A：pure-fault protection

对六个 severity 点分别计算

```text
Δbias_j = bias_norm(M5-Full)_j - bias_norm(M2)_j
Δret_j  = abs_retention_error(M5-Full)_j - abs_retention_error(M2)_j
```

Gate A 要求 `median(Δbias_j)<0` 且 `median(Δret_j)<0`。这只判定系统性方向，不规定最小改善幅度。若任一中位差不小于 0，则 pure-fault mechanism gate 失败。

### Gate B：orthogonal legitimate tracking

对 factor 1.30 与 1.60，计算

```text
Δperp = RMSE_perp(M5-Full) - RMSE_perp(GC)
```

Gate B 要求两个 `Δperp≤0`，且至少一个严格小于 0。仅用于判断数值相等的 roundoff tolerance 固定为 `1e-12*(1+max(abs(values)))`，它不是性能阈值。若两个条件都没有 perpendicular preservation，directionality 核心主张不成立。

### Gate C：mixed geometry consistency

Mixed 条件同样检查 `RMSE_perp(M5-Full)-RMSE_perp(GC)`。若两个 fault levels 均显示 `RMSE_perp` 和 `RMSE_total` 同时恶化，且周期日志中没有 rate/projection rotation 或其他已注册机制可解释，则 H3 失败并停止进入 Step5。不得更换 mixed direction 或漂移范数。

### Gate D：parallel boundary retention

Parallel 条件无性能 PASS 门槛。无优势、等效或退化都保留。删除该条件、改写方向或把负结果排除在结论外均构成预注册违背。

### 总体决定

进入 Step5 至少要求 Gate A 和 Gate B 通过，Gate C 不出现未解释的机制反向结果，并完整保留 Gate D。若 M5-Full 在 fault preservation 和 matched legitimate tracking 两方面均未提供可解释的新信息，则 `STEP4=STOP`，不运行 Monte Carlo。

## 11. Run / reuse 与工作量

完整机器可读矩阵见 `M5_STEP3_EXPERIMENT_MATRIX.csv`。计数如下：

| Block | physical cases | case×algorithm rows | frozen result reuse | frozen trajectory / metrics-only | new tracker executions | expected `sim()` calls |
|---|---:|---:|---:|---:|---:|---:|
| A | 2 | 14 | 6 | 0 | 8 | 4 |
| B | 6 | 42 | 18 | 0 | 24 | 12 |
| C | 6 | 42 | 0 | 6 | 36 | 18 |
| Total | 14 | 98 | 24 | 6 | 68 | 34 |

`sim()` 口径按现有 runner 冻结：Block A/B 每个 case 使用 clean + noisy 两次 Simulink 调用；Block C 每个 case 使用 clean-F、noisy-F、matched-noisy-CF 三次调用。一次生成的数据由该 case 的所有新算法共享，不按算法重复仿真。

复用规则：

1. Block A 与 B 的 M2/M3/M4 使用冻结结果，不重新运行历史 baseline；
2. Mixed Block C 的 M2/M3/M4 从 Case07/08 冻结 `cHist` 轨迹计算新增 `RMSE_parallel/perp`，只做 metrics-only，不重新执行算法；
3. GH、GC、M5-DH、M5-Full 在 14 个 case 上均为新 tracker execution；
4. Orthogonal/Parallel Block C 的 M2/M3/M4 因物理几何为新条件，需要执行；
5. 新生成 physical data 必须先通过 seed、truth trajectory、noise replay 和 data signature 一致性检查，再供所有算法共享；
6. 历史结果缺失不得用另一 case、另一 seed 或近似指标替代。

## 12. Step4 分析规则

- 所有比较均在同一 physical case、seed、F/CF branch 与窗口内配对。
- 报告每个 case 的原始指标、带符号差值和 factorial interaction，不作 overall score、TOPSIS 或算法总排名。
- Deterministic Step4 不作群体统计显著性推断；14 个 case 是预注册机制条件，不是随机样本。
- 不删除 numerical success 但 performance 较差的记录。
- numerical failure 只指仿真中止、必需输出缺失、NaN/Inf、文件损坏或 validator failure；性能差不是 numerical failure。
- projection/rate 激活周期完整保留；projection 后不增加第二次 directional correction。
- Parallel boundary、mixed 反向结果和 hard-gate 未触发条件均保留。

## 13. Step5 边界计划

只有 Step4 GO 后，Step5 才可登记并运行 Monte Carlo、noise/reference phase、Cself mismatch、projection-active boundary、near-zero update 与其他 robustness 条件。Step5 必须保留 projection-active samples，并报告 pre-constraint、post-rate、post-projection 方向与周期数。Step5 不能用于修正 Step4 假设、改变方向或回填新的性能阈值。

## 14. 未解决问题与 Step4 入口门

| ID | 未解决问题 | Step4 前处理 | 是否允许改算法 |
|---|---|---|---:|
| U1 | M5 尚未接入独立 Step4 runner | 新建 M5 专用 runner；不得修改冻结 dispatcher/trackers | 否 |
| U2 | Direction-resolved metric evaluator 尚未实现 | 先做公式单元测试、projector decomposition identity 和窗口测试 | 否 |
| U3 | Block A/B 新算法需要重放冻结 case 数据 | 验证 seed、truth trajectory、noise replay 与现有 data signature | 否 |
| U4 | Mixed C 的历史 workspace 只供 M2/M3/M4 trajectory metrics-only；新算法仍需再生 F/CF 数据 | 再生后先通过 Case07/08 configuration 与 signature gate | 否 |
| U5 | 不同算法 cycle log 字段名不同 | evaluator 只做显式字段映射；不得改变指标定义或算法状态 | 否 |
| U6 | Step2 smoke 未触发 projection | Step4 如自然触发则完整报告；专门 boundary sweep 延后至 Step5 | 否 |
| U7 | M5 的 pre-constraint h reconciliation 与既有 post-constraint mismatch 语义并存 | 保留并报告 `final_h_Jtheta_mismatch`; 不在 Step4 改顺序 | 否 |
| U8 | Phase2 的 negative-sequence internal convention 仍未解决 | 不属于 Step4 core；Step5 如纳入必须继续标注 validity boundary | 否 |

U1–U5 是执行前门。任何一项未通过时，Step4 标记 `BLOCKED`，不得先看部分性能再修订本预注册。

## 15. 完整性声明

本预注册覆盖 RQ1–RQ5、三类算法角色、Block A/B/C、六级 pure-fault grid、三种 drift geometry、两个 overlap severity、五类 primary metric、四个 matched comparisons、历史比较边界、Step4 GO/STOP、Step5 边界计划、run/reuse 规则、工作量和未解决问题。它没有预先宣称 M5 superior，也没有把 Step2 结构通过升级为性能结论。

Step3 在此停止。下一步必须先由人工审核本文和实验矩阵；审核前不得执行 Step4。
