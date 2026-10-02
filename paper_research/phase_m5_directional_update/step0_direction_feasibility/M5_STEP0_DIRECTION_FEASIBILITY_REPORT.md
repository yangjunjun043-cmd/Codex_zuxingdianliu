# M5 Step0 — Fault-Sensitive Parameter-Space Direction Feasibility

分析日期：2026-09-29  
分析性质：冻结数据再分析；GO/NO-GO 证据审查  
最终状态：**SUPPORTED（存在明确的物理投影边界）**

## 1. 结论先行

Phase1B 的 12 个开发样本表明，故障诱发参数偏置具有高度集中的一维主方向：

\[
d_f=
\begin{bmatrix}
0.6998427631\\
-0.7142969319
\end{bmatrix},
\qquad \|d_f\|_2=1.
\]

第一主方向解释的 directional energy ratio 为 **0.9997128291**。开发样本相对该方向的 mean / median / P90 / max angle 分别为 **0.743608° / 0.587415° / 1.401581° / 2.526414°**。该方向与理论 differential direction `[1,-1]/sqrt(2)` 的夹角为 **0.585610°**，因此 `[1,-1]` 是很好的物理解释，但不是本研究直接写死的正式方向。

Phase2 可作为独立验证。与 Phase1B 估计量一致的 M2 数据共有 128 条有符号记录，其中 **111 条为有效方向样本，17 条为 near-zero 样本**；near-zero 记录保留在样本表中，但不进入角度统计。使用 Phase1B 的固定 `d_f`，Phase2 M2 的 mean / median / P90 / max angle 为 **4.431048° / 0.638911° / 2.602169° / 45.585610°**，固定方向解释的能量比例为 **0.9624865924**。

偏离并非均匀散布：未触发物理投影的 100 个正式验证样本最大偏角为 **2.602169°**；11 个物理投影激活样本的偏角为 **6.989857°–45.585610°**。因此现有证据支持稳定主方向，但不支持把它扩张为“在参数投影/饱和边界下仍保持不变”的无条件命题。

## 2. 范围与锁定条件

本步骤只读取已有冻结 CSV，没有：

- 调用 `sim` 或重新运行 Simulink；
- 重新运行 Phase1B、Phase2 或任何 tracker；
- 修改 AutoComp9、M2、M3、M4、REW weight、hard gate 或 threshold；
- 修改评价窗口、随机种子或冻结注册表；
- 删除离群点、负结果或 near-zero 记录；
- 使用 Phase2 反向调整 `d_f`；
- 实现 M5。

可复现分析入口为 `run_m5_step0_direction_analysis.m`。该函数只执行 CSV 读取、向量归一化、SVD、分组统计和内部绘图。

## 3. 数据源审计

### 3.1 Phase1B development

| 数据源 | 用途 | 纳入规则 | 样本数 |
|---|---|---|---:|
| `phase1b_fault_absorption/step2/case05_key_metrics.csv` | Case05 nominal | 直接读取冻结 `recursive_fault_induced_Delta_Cs1/2_pF` | 1 |
| `phase1b_fault_absorption/step3/case06_key_metrics.csv` | Case06 drift-then-fault | 直接读取同名冻结字段 | 1 |
| `phase1b_fault_absorption/step4/controlled_factor_summary.csv` | fault factor 与 reference phase 受控实验 | 直接读取冻结 `DeltaCs1/2_fault_induced` | 10 |

Step4 的 `fault_factor_1p60_phase_0deg` 与 Case05 nominal 是同一冻结锚点。为避免对同一实验重复计权，SVD 中只保留 Case05 key metrics 的一份；该锚点仍同时出现在 amplitude/phase 分组摘要中。没有删除任何独立条件。

Phase1B 的 cycle table 没有被拆成伪独立样本。正式样本单位沿用 Phase1B 冻结的 case-level、pre/post-window fault branch minus counterfactual branch 偏置。

### 3.2 Phase2 validation

| 数据源 | M2 方向记录 | 有效 | near-zero | 角色 |
|---|---:|---:|---:|---|
| `step2b2_deterministic_results.csv` | 15 | 15 | 0 | 正式独立验证 |
| `step4_overlap_results.csv` | 13 | 13 | 0 | 正式独立验证；使用冻结 `F_minus_CF` |
| `step6_monte_carlo_full_results.csv`, cohort F | 50 | 41 | 9 | 正式独立验证 |
| `step6_monte_carlo_full_results.csv`, cohort O | 50 | 42 | 8 | 正式独立验证；使用冻结 `F_minus_CF` |
| 合计 | 128 | 111 | 17 | — |

以下数据没有用于正式 `d_f` 验证：

- Step2B1 smoke 与 Step6A pilot 是上述正式全集的重复子集，未重复计权；
- Step3 model-mismatch 条件以非故障 tracking case 为锚点，`DeltaCs1/2_fault_induced_pF` 为 unavailable/NaN，不能从 bias norm 反推方向；
- Phase2 H cohort 没有 fault-induced bias，方向不适用；
- M0 没有自适应参数轨迹，不能定义 parameter-bias direction；
- M3/M4 改变了保护日程或更新权重，不再是与 Phase1B M2 完全相同的估计量，因此仅作为上下文诊断；
- Step5 sensitivity 有 15 条 M3/M4 冻结结果，均保留为 `CONTEXT_ONLY`，但不参与 `d_f` 或正式 GO/NO-GO 统计。

这一区分是估计量隔离，不是按结果好坏筛选数据。M3/M4 的较大偏角和 sensitivity 负结果仍保留在样本 CSV 与汇总 CSV 中。

## 4. 冻结定义与计算方法

Phase1B 的正式递归定义为：

\[
\Delta\theta_{fault}
=\Delta\theta_{fault\ branch}-\Delta\theta_{counterfactual\ branch}
=
\begin{bmatrix}
\Delta C_{s1,fault}\\
\Delta C_{s2,fault}
\end{bmatrix}.
\]

Phase1B key/summary 文件已直接保存两个分量，因此直接读取。Phase2 overlap 与 Monte-Carlo O 文件保存 `F_movement`、`CF_movement` 及已计算的 `F_minus_CF_Cs1/2_pF`；本分析读取该冻结差值，并在样本表的 `calculation_source` 中逐行记录来源。

对每条有限记录计算：

\[
\|\Delta\theta_i\|_2
=\sqrt{\Delta C_{s1,i}^2+\Delta C_{s2,i}^2},
\qquad
d_i=\frac{\Delta\theta_i}{\|\Delta\theta_i\|_2}.
\]

near-zero 的数值判据在分析前固定为 `bias_norm <= 1e-9 pF`。它只用于避免零向量的除法和无定义角度，不是 GO/NO-GO 阈值。所有 near-zero 行都保留，`normalized_d1/d2`、alignment 和 angle 记为 NaN，`direction_status` 明确标记。

将 12 个 Phase1B normalized development vectors 组成矩阵 `D`，通过 `svd(D,'econ')` 得到第一右奇异向量。由于方向正负等价，报告时令其与 `[1,-1]/sqrt(2)` 点积为正。Phase2 从未参与 `d_f` 估计。

对每个有效方向计算：

\[
alignment_i=|d_i^T d_f|,
\qquad
angle_i=\arccos(alignment_i).
\]

汇总表中的 `directional_energy_ratio` 是各组沿固定 Phase1B `d_f` 的平均方向能量 `mean(alignment^2)`；对 `DEVELOPMENT_ALL`，它与 SVD 第一奇异值平方占总奇异值平方之比相同。

## 5. Phase1B 开发结果

| 数据集 | n | mean angle | median | P90 | max | directional energy ratio |
|---|---:|---:|---:|---:|---:|---:|
| Development all | 12 | 0.743608° | 0.587415° | 1.401581° | 2.526414° | 0.999712829 |
| Case05 family | 11 | 0.754385° | 0.586888° | 1.487862° | 2.526414° | 0.999697542 |
| Case06 | 1 | 0.625056° | 0.625056° | 0.625056° | 0.625056° | 0.999880992 |
| Fault-factor sweep | 6 | 0.586312° | 0.587415° | 0.589251° | 0.589517° | 0.999895283 |
| Reference-phase sweep | 6 | 0.894981° | 0.519359° | 2.007138° | 2.526414° | 0.999532566 |

Case05 nominal 与 Case06 nominal 的方向夹角仅 **0.035539°**。fault factor 从 1.05 增至 1.60 时，首末方向夹角为 **0.011701°**；各幅值样本相对 `d_f` 的偏角保持在 **0.577816°–0.589517°**。因此 fault factor 改变主要缩放 bias magnitude，没有产生可见的方向旋转。

开发样本中 12/12 均为 `DeltaCs1 > 0`、`DeltaCs2 < 0`。

## 6. Phase2 独立验证

| 数据集 | 有效 n | near-zero | mean angle | median | P90 | max | energy ratio |
|---|---:|---:|---:|---:|---:|---:|---:|
| Deterministic | 15 | 0 | 0.742352° | 0.588984° | 1.195412° | 2.526415° | 0.999737371 |
| Overlap matrix | 13 | 0 | 0.706069° | 0.674674° | 0.827262° | 0.969953° | 0.999844654 |
| Monte-Carlo F | 41 | 9 | 1.885856° | 0.585773° | 2.542346° | 14.447295° | 0.996128282 |
| Monte-Carlo O | 42 | 8 | 9.386000° | 0.647009° | 45.585610° | 45.585610° | 0.904778836 |
| Phase2 M2 all | 111 | 17 | 4.431048° | 0.638911° | 2.602169° | 45.585610° | 0.962486592 |

104/111 个有效验证样本保持 `DeltaCs1` 与 `DeltaCs2` 反号。其余 7 个样本不是同号随机漂移，而是 `DeltaCs2=0` 的投影边界记录。

按冻结 `projection_active_cycles` 复核：

- 未激活物理投影：100 个有效样本，mean / median / P90 / max angle 为 **1.078465° / 0.585374° / 2.528831° / 2.602169°**；
- 激活物理投影：11 个有效样本，mean / median / P90 / max angle 为 **35.807512° / 45.585610° / 45.585610° / 45.585610°**；
- 正式验证偏角最大的 10 个样本全部来自 projection-active 组。

该复核没有删除或重算这些样本，只说明偏离与已有物理投影边界共现。它不能证明投影是唯一原因，但足以否定“最终受约束 bias 在边界上仍保持同一方向”的强外推。

## 7. 明显反例

以下逐条列出全部 11 个 projection-active 正式 M2 方向样本；没有从统计中删除：

| condition | cohort | fault factor | Cself mismatch | phase error | SNR | `[DeltaCs1, DeltaCs2]` pF | angle | projection cycles |
|---|---|---:|---:|---:|---:|---|---:|---:|
| P2_MC_O_003 | O | 1.6 | -10% | 1° | 40 | `[1.021828, 0]` | 45.585610° | 13 |
| P2_MC_O_014 | O | 1.6 | -10% | 3° | 40 | `[0.290501, 0]` | 45.585610° | 13 |
| P2_MC_O_020 | O | 1.3 | -5% | 3° | 40 | `[2.325247, 0]` | 45.585610° | 13 |
| P2_MC_O_037 | O | 1.1 | -5% | 1° | 40 | `[0.913822, 0]` | 45.585610° | 11 |
| P2_MC_O_042 | O | 1.3 | -5% | 3° | 30 | `[2.307695, 0]` | 45.585610° | 13 |
| P2_MC_O_045 | O | 1.1 | -5% | 0.33° | 30 | `[0.872974, 0]` | 45.585610° | 11 |
| P2_MC_O_049 | O | 1.6 | -5% | 3° | 30 | `[4.613741, 0]` | 45.585610° | 11 |
| P2_MC_O_028 | O | 1.6 | -5% | 0.5° | 40 | `[5.001972, -0.521005]` | 39.639128° | 13 |
| P2_MC_F_005 | F | 1.4 | -5% | 0° | 20 | `[3.251622, -1.964471]` | 14.447295° | 19 |
| P2_MC_F_012 | F | 1.4 | -5% | 0.33° | 20 | `[3.239591, -2.014784]` | 13.707079° | 19 |
| P2_MC_F_014 | F | 1.3 | -5% | 0° | 20 | `[2.456662, -1.960830]` | 6.989857° | 19 |

此外，17 个 near-zero M2 记录同样是正式结果，其中 Monte-Carlo F 为 9 个、O 为 8 个。它们的方向数学上未定义，已保留但未被伪造为零角度。

## 8. M3/M4 上下文诊断

这些统计不用于 `d_f` 或主假设判定，但用于保留保护算法的负结果：

| 数据 | 有效 n | near-zero | mean | median | P90 | max | energy ratio |
|---|---:|---:|---:|---:|---:|---:|---:|
| M3 core context | 109 | 19 | 9.695385° | 2.404674° | 41.482983° | 89.187197° | 0.916702361 |
| M4 core context | 111 | 17 | 4.451178° | 0.639580° | 3.445802° | 45.585610° | 0.962567690 |
| Frozen sensitivity context | 15 | 0 | 25.748792° | 41.256267° | 41.256267° | 84.882663° | 0.728985237 |

M3 的 binary freeze 和 M4 的 continuous weight 改变了最终 fault/counterfactual trajectory difference，尤其在保护日程或约束边界附近。因此“最终受保护参数移动方向”不能与“原始/无门控 RLS 的 fault-sensitive direction”混为同一估计量。M5 若进入实现阶段，应明确作用于哪一个更新量；本 Step0 不作实现选择。

## 9. 对 Q1–Q9 的正式回答

### Q1. `DeltaCs1` 与 `DeltaCs2` 是否稳定反向变化？

**是，在开发数据和绝大多数同估计量验证样本中成立。** Phase1B 为 12/12，Phase2 M2 有效样本为 104/111。7 个非反号样本均为 `DeltaCs2=0` 的投影边界记录，不是一般条件下的同号随机散布。

### Q2. 是否存在稳定 principal fault-sensitive direction？

**是。** Phase1B 第一方向能量比例为 0.999712829；Phase2 固定方向验证能量比例为 0.962486592。验证能量下降由少量 projection-active 边界样本主导。

### Q3. 第一主方向是什么？

`d_f = [0.6998427631, -0.7142969319]^T`。其相反数表示同一无向参数轴。

### Q4. 与 `[1,-1]/sqrt(2)` 的夹角是多少？

**0.585609775°**。因此 differential mode 是近似解释，不应替代数据估计的 `d_f`。

### Q5. Case05 与 Case06 是否方向一致？

**一致。** 两个 nominal bias vectors 的无向夹角为 **0.035538991°**。Case06 相对 `d_f` 的偏角为 0.625056°。

### Q6. fault factor 改变后方向是否稳定？

**稳定。** 1.05–1.60 amplitude sweep 的首末方向夹角为 0.011701°，整组相对 `d_f` 的最大偏角为 0.589517°。现有数据表现为幅值缩放而非方向旋转。

### Q7. 是否存在明显反例？

**存在，且已全部保留。** 11 个 projection-active M2 验证样本偏角为 6.989857°–45.585610°，其中 7 个因 `DeltaCs2=0` 达到 45.585610°。它们说明物理投影/参数饱和会旋转最终 bias direction，是后续 M5 必须显式处理的 validity boundary。

### Q8. Phase2 能否作为独立方向验证？

**可以。** Deterministic、overlap 与 full Monte-Carlo 文件保存了 individual signed components 或正式 `F-CF` 两分量。Phase2 未参与 `d_f` 估计，只用 Phase1B 固定方向计算 alignment/angle。Step3 非故障 model-mismatch 数据没有 individual fault bias，记为 unavailable，不用于反推。

### Q9. M5 directional hypothesis 最终状态？

**SUPPORTED。** 支持的是：在当前 AB/BC 参数化、Phase1B 开发范围及绝大多数 Phase2 M2 条件中，fault-induced bias 主要集中于稳定的一维参数轴。该结论不包含“物理投影激活后方向仍保持不变”，也不授权直接把 `[1,-1]` 写死为 M5 正式方向。

## 10. GO/NO-GO 解释

本判定没有设置事后 PASS 阈值。综合证据为：

- development 方向能量为 99.9713%，所有样本反号；
- Case05/Case06 nominal 夹角仅 0.0355°；
- fault factor 1.05–1.60 未出现方向旋转；
- Phase2 M2 median 与 P90 仅 0.6389° 和 2.6022°；
- 111 个有效验证样本的固定方向能量为 96.2487%；
- 没有接近 90° 的正式 M2 样本；
- 所有显著偏离均集中于已记录的 projection-active 边界，而非各 case 无规律散布。

因此 Step0 对“存在可用于后续研究的 fault-sensitive parameter-space direction”给出 GO 证据。人工验收时必须同时接受以下限制：后续方法不能假定最终受约束 bias 在投影边界仍沿 `d_f`；需要把 projection/near-zero/validity 状态作为方法边界，而不是删除这些条件。

## 11. 内部分析图

这些图仅用于 Step0 内部审查，不作为正式论文 Figure：

- `figures/parameter_space_scatter.png`
- `figures/angle_vs_fault_factor.png`
- `figures/alignment_distribution.png`
- `figures/case05_case06_direction.png`

## 12. 输出与停止条件

输出文件：

- `m5_fault_direction_samples.csv`
- `m5_fault_direction_summary.csv`
- `M5_STEP0_DIRECTION_FEASIBILITY_REPORT.md`
- `run_m5_step0_direction_analysis.m`
- `figures/*.png`

本步骤到此停止。没有实现 M5，也没有修改 M4、REW、hard gate、threshold、模型或冻结实验。

## 13. Functional-completeness retrospective

- Scope covered：Phase1B Case05/06、controlled factors；Phase2 deterministic、overlap、full Monte-Carlo；M3/M4/sensitivity 负结果作为上下文保留。
- Authority and locks：沿用 Phase1B 冻结 fault-minus-counterfactual 定义；Phase2 未参与 `d_f` 估计；重复 smoke/pilot 未重复计权。
- Alignment：Q1–Q9 均有方法、数值证据、答案与边界。
- Computational/simulation adapter：区分冻结仿真再分析、算法估计量与现实外推；没有把仿真方向稳定性表述为现场普遍规律。
- Change propagation：仅新建 M5 Step0 输出；未改写前序报告、CSV、算法或模型。
- Deterministic and visual checks：分析脚本在 MATLAB R2023b 成功运行；CSV 字段、样本计数、near-zero、图像可读性和源字段已复核。
- Open issues：物理投影边界下最终 bias 方向会旋转；M3/M4 最终轨迹差不是与 M2 相同估计量；现场与硬件外推仍不可用。
- Readiness：**ready for human M5 Step0 GO/NO-GO review；not an M5 implementation authorization by itself**。
