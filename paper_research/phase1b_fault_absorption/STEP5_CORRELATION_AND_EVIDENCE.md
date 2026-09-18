# Phase 1B-5 — Correlation & Mechanism Evidence

执行日期：2026-09-18  
正式结论：`STEP5_CORRELATION_AND_EVIDENCE: PASS`

本步骤只分析 Step 4 冻结的 11 个受控工况，并仅用 Step 2/3 正式结果交叉引用 Case05/Case06。没有运行 Simulink，没有重跑 Phase 1A，没有新增工况、调参、开发 M4 或执行 Monte-Carlo。

每个 sweep 只有 `n=6`，本文所有相关结果均属于 **controlled exploratory evidence**。不使用 p-value 下广泛统计结论，也没有把两个 sweep 合并制造相关性。

---

## 1. Data integrity and definitions

正式读取：

- `step4/controlled_factor_summary.csv`：11 个唯一正式工况；
- `step4/controlled_factor_cycles.csv`：1815 行 cycle-level 数据；
- `step4/controlled_factor_workspace.mat`：Step 4 formal validation 为 PASS；
- Step 2/3 key metrics：只用于 Case05/Case06 证据链交叉引用。

Step 1–4、AutoComp9、Phase 1A、原 tracker/dispatcher/reference/config 共 19 个冻结文件在分析前后 SHA-256 完全一致。Step 5 运行元数据明确记录 `simulink_executed=false`。

故障增量损失沿用既定 fault-factor 定义：

```text
true_increment      = fault_factor_true - 1
estimated_increment = fault_factor_est - 1
lost_increment      = true_increment - estimated_increment
                    = fault_factor_true - fault_factor_est
```

该定义未根据结果调整。

---

## 2. Fault-amplitude sweep

### 2.1 Fault increment to recursive false Cs bias

令 `x=F-1`。六个 amplitude 条件给出：

| Response | Pearson r | Spearman rho | Linear slope | Intercept | R² | n |
|---|---:|---:|---:|---:|---:|---:|
| `Delta Cs1_fault_induced` | 0.99999994 | 1.000000 | 8.147435 pF | -0.001826 pF | 0.99999987 | 6 |
| `|Delta Cs2_fault_induced|` | 0.99999994 | 1.000000 | 8.146079 pF | -0.001659 pF | 0.99999987 | 6 |

`Delta Cs1` 从 `0.404536 pF` 增至 `4.886379 pF`，`|Delta Cs2|` 从 `0.404646 pF` 增至 `4.885713 pF`。在本受控范围内，数据强力支持：

```text
fault-induced parameter bias is approximately proportional
to the excess fault amplitude F-1
```

这不是总体统计规律；它成立于同一 voltage/reference geometry、同一 fault waveform direction、同一噪声 realization 和未触发约束的六个确定性工况。

### 2.2 Static LS prediction of recursive bias

`Delta c_LS,f` 与 `fault branch - counterfactual branch` 的独立递归结果比较：

| Sweep | Parameter | RMSE / pF | MAE / pF | Max abs error / pF | Max relative error | Pearson r | Spearman rho | Direction agreement |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| amplitude | Cs1 | 0.001256 | 0.000975 | 0.002681 | 0.6628% | 0.99999994 | 1.000000 | 100% |
| amplitude | Cs2 | 0.001339 | 0.001181 | 0.002571 | 0.6354% | 0.99999994 | 1.000000 | 100% |
| phase error | Cs1 | 0.000180 | 0.000174 | 0.000225 | 0.00460% | 1.00000000 | 1.000000 | 100% |
| phase error | Cs2 | 0.000966 | 0.000963 | 0.001086 | 0.02111% | 1.00000000 | 1.000000 | 100% |

amplitude sweep 的最大相对误差出现在最弱 `F=1.05` 条件；因为实际 bias 只有约 `0.405 pF`，`0.0027 pF` 的小绝对误差对应较大的相对百分比。全部正式条件方向一致。

结论：static `Delta c_LS,f` 对 recursive fault-induced bias 的方向和数量级具有很高预测精度；它仍不描述递归时间、正常背景漂移、lambda 响应或状态历史。

### 2.3 False compensation and lost increment

| Response versus `F-1` | Pearson r | Spearman rho | Slope | Intercept | R² | n |
|---|---:|---:|---:|---:|---:|---:|
| false-compensation RMS | 0.99999994 | 1.000000 | 0.281532 mA | -0.000060 mA | 0.99999987 | 6 |
| lost increment | 0.99999994 | 1.000000 | 0.333433 | -0.001124 | 0.99999987 | 6 |

false-compensation RMS 从 `0.013982 mA` 增至 `0.168850 mA`，lost increment 从 `0.015507` 增至 `0.198925`。同时，false-compensation/fault RMS ratio 保持在 `0.331184–0.333295`。

参数漂移与 lost increment 的关系也稳定：

| Predictor to lost increment | Pearson r | Spearman rho | Slope | R² |
|---|---:|---:|---:|---:|
| `Delta Cs1_fault_induced` | 0.9999999999 | 1.000000 | 0.0409249 per pF | 0.9999999998 |
| `|Delta Cs2_fault_induced|` | 0.9999999999 | 1.000000 | 0.0409318 per pF | 0.9999999999 |

因此，fault increment、recursive false Cs、false compensation 与 absolute increment loss 在该受控系列中形成稳定的幅值链。

### 2.4 eta_geom is a proportion, not an absolute magnitude

amplitude sweep 的 `eta_geom_post` 六点全部为 `0.275451415244565`，数值极差为 `0`。因此没有报告 `eta_geom ↔ retention` 的强行相关系数。

这组结果直接说明：

```text
eta_geom describes the geometric proportion of r_fault expressible by col(X),
while the absolute projected component scales with the magnitude of r_fault.
```

几何比例不变并不意味着被吸收的绝对电流或参数偏差不变。`F-1` 增大时，`r_fault`、`r_parallel`、`Delta c_LS,f`、recursive bias 和 lost increment 可以一起增加。

---

## 3. Reference-phase-error sweep

### 3.1 Pre-fault parameter bias

| Response | Pearson r | Spearman rho | Slope per degree | R² | Observed range / pF | n |
|---|---:|---:|---:|---:|---:|---:|
| pre-fault Cs1 bias | -0.997218 | -1.000000 | -0.271944 pF/deg | 0.994445 | +0.0202 to -0.7948 | 6 |
| pre-fault Cs2 bias | -0.999084 | -1.000000 | -0.473803 pF/deg | 0.998169 | +0.0506 to -1.3701 | 6 |

相位误差在故障前已产生明显 Cs 估计偏差。这是 reference/model mismatch 的直接证据，与 fault-induced absorption 不同。

### 3.2 Retention degradation

| Response | Pearson r | Spearman rho | Slope per degree | R² | 0° to 3° change | n |
|---|---:|---:|---:|---:|---:|---:|
| M2 retention error | -0.993940 | -1.000000 | -2.83068 pp/deg | 0.987917 | -12.4328% to -21.0069% | 6 |
| counterfactual retention error | -0.993929 | -1.000000 | -4.24237 pp/deg | 0.987895 | +0.0657% to -12.7846% | 6 |

counterfactual 参数路径本身在 0–3° 间恶化 `12.8503` 个百分点，证明 phase-error sweep 的总 retention degradation 不能只归因于故障被参数吸收。作为分解参考：

- 0°：M2 与 counterfactual retention 差约 `-12.4985 pp`；
- 3°：该差约 `-8.2223 pp`。

相位误差增大时，总 M2 结果更差，但 fault/counterfactual 之间的附加吸收差反而缩小。主导新增恶化来自参考失配造成的正常估计/补偿误差，而不是 `eta_geom` 大幅增加。

### 3.3 eta_geom association and effect size

phase error 与 `eta_geom_post` 的结果为：

```text
Pearson r  = 0.967554
Spearman ρ = 1.000000
R²         = 0.936160
range      = 0.2754514 to 0.2760550
relative change from 0° to 3° = +0.2191%
```

高秩相关来自六个点的单调微小变化，不能替代效应量判断。同期 M2 retention 恶化 `8.5741 pp`，counterfactual retention 恶化 `12.8503 pp`。所以正式判断是：

> `eta_geom` alone is insufficient to explain or predict the phase-error retention degradation.

### 3.4 False-compensation direction

| Response | Pearson r | Spearman rho | Slope | R² | Range |
|---|---:|---:|---:|---:|---:|
| false-compensation phase | -0.999998 | -1.000000 | -0.795609 deg/deg | 0.999997 | +0.0068° to -2.3796° |
| false-compensation RMS ratio | +0.967328 | +1.000000 | +0.000339/deg | 0.935723 | 0.333295 to 0.334309 |

相位误差主要使错误补偿方向近线性旋转；其幅值比例只变化约 `0.001014`，远小于方向和 pre-fault bias 的变化。这与“reference mismatch 改变补偿相位及正常估计工作点”的解释一致。

---

## 4. Formal position of eta_geom

### eta_geom can explain

- 在给定 observation model 和 reference geometry 下，`r_fault` 有多少能量落入 `col(X)`；
- fault waveform direction 与 coupling-parameter model 的几何可表达程度；
- static `Delta c_LS,f` 存在的几何基础。

### eta_geom cannot explain alone

- fault 的绝对幅值以及由此产生的绝对 `Delta c`；
- phase error 引入的 pre-fault/normal estimation bias；
- reference/model mismatch 对提取波形的直接影响；
- recursive state history、counterfactual background 与收敛时间；
- lambda 的动态响应；
- 最终 fault-retention error 的全部来源。

amplitude sweep 提供“比例不变、绝对损失增加”的直接反例；phase sweep 提供“几何仅微变、正常估计与 retention 显著恶化”的第二个反例。因此不得把 `eta_geom` 包装为通用 retention predictor。

---

## 5. Final mechanism evidence chain

| Link | Evidence level | Quantitative evidence | Boundary |
|---|---|---|---|
| `r_fault → projection onto col(X)` | directly verified | Step 2/3 projection energy closure `≤5.50e-15`；Step 4 正式 eta 完整计算 | 条件于冻结的两列 X/reference model |
| `projection → Delta c_LS,f` | directly verified | `X*Delta c_LS,f` 与投影分量通过 Step 2/3 数值闭合 | static LS 不描述递归时序 |
| `Delta c_LS,f → recursive false Cs bias` | strongly supported | amplitude 最大 RMSE `0.001339 pF`、最大相对误差 `0.6628%`、方向一致率 100%；phase 结果同样通过 | 每个 sweep 仅 6 个确定性点，state history 独立存在 |
| `recursive false Cs bias → false coupling compensation` | directly verified | amplitude 中 compensation RMS `0.013982→0.168850 mA`，比例约 `0.331–0.333` | 对冻结 B 相提取方程成立 |
| `false coupling compensation → fault increment loss` | directly verified | controlled lost increment `0.015507→0.198925`；Case05/06 counterfactual factor 分别恢复到 `1.6011/1.6026`，真值 `1.6000` | 确定性闭环证据，不等同总体鲁棒性 |

证据等级没有把 E3 写成“directly verified”，因为 static LS 与 dynamic recursion 不是数学同一量；现有数据是极强预测支持，但递归历史和 lambda 仍是独立机制层。

---

## 6. Case05, Case06 and controlled sweeps

三组证据共同支持同一机制链：

- Case05：static LS `+4.8866/-4.8866 pF`，recursive fault-induced `+4.8864/-4.8857 pF`，false-compensation ratio `0.333295`，M2 factor `1.4011`，counterfactual 恢复 `1.6011`；
- Case06：真实 Cs 已漂移，但 recursive fault-induced 仍为 `+4.8884/-4.8817 pF`，ratio `0.333228`，M2 factor `1.4023`，counterfactual 恢复 `1.6026`；
- Step 4 amplitude sweep：证明该链随 fault increment 近比例缩放；
- Step 4 phase sweep：证明 reference mismatch 会叠加 normal bias 和方向旋转，并揭示 `eta_geom` 的解释边界。

因此 Case05/Case06 给出两个工作点上的闭环复现，controlled sweeps 给出幅值规律和参考失配边界；三者不是互相替代，而是互补证据。

---

## 7. Required questions

1. **fault increment 与 fault-induced Delta Cs 是否稳定相关？** 是。在本受控范围内 Pearson 约 `0.99999994`、Spearman `1`、R² 约 `0.99999987`。
2. **static Delta c_LS,f 的预测精度？** amplitude 最大 RMSE `0.001339 pF`、最大相对误差 `0.6628%`；phase 最大 RMSE `0.000966 pF`；全部方向一致。
3. **false compensation 是否随 amplitude 稳定增长？** 是，Pearson `0.99999994`，斜率 `0.281532 mA` per unit `F-1`。
4. **fault increment loss 与参数漂移是否稳定相关？** 是，Cs1/|Cs2| 与 lost increment 的 Pearson 均大于 `0.9999999998`。
5. **eta_geom 能否单独预测 retention？** 不能。
6. **为何 amplitude sweep 中 eta 不变而 loss 增大？** eta 是几何能量比例；故障方向不变时比例保持，但 `r_fault` 的绝对幅值及其投影随 `F-1` 增大。
7. **phase error 主要通过 geometry 还是 model mismatch？** 主要通过 reference/model mismatch、normal bias 和递归工作点影响。eta 只相对变化 `0.2191%`。
8. **phase error 是否主要影响 normal/pre-fault bias？** 是。故障前 Cs1/Cs2 bias 已分别达到 `-0.7948/-1.3701 pF`，且 counterfactual retention 显著恶化。
9. **Case05、Case06、Step 4 是否支持同一链？** 是；geometry、LS 方向、recursive bias、false compensation 和 counterfactual recovery 均一致，phase sweep 同时标出了边界。
10. **是否足以进入 Phase 1B-6？** 是，足以形成确定性机理证据的最终汇总；但不得把它写成 Monte-Carlo 鲁棒性或普适统计证明。

---

## 8. Outputs and command

新增分析代码：

- `step5/run_phase1b_step5_correlation_evidence.m`
- `step5/generate_phase1b_step5_figures.m`

正式数据：

- `step5/correlation_summary.csv`：14 个分层关系，其中 amplitude eta 为 descriptive invariant；
- `step5/prediction_error_summary.csv`：两个 sweep、两个参数，共 4 行；
- `step5/mechanism_evidence_table.csv`：5 个机制箭头及证据等级；
- `step5/correlation_workspace.mat`：来源元数据、派生变量、完整性清单、统计与验证；
- `step5/figures/`：6 张 `.png` 和 6 张 `.fig`。

运行命令：

```matlab
addpath(fullfile(pwd,'paper_research','phase1b_fault_absorption','step5'));
run_phase1b_step5_correlation_evidence;
```

两个新增 MATLAB 文件最终 `checkcode` 均为 0 issues。

---

## 9. Acceptance

| ID | Requirement | Result |
|---|---|---|
| A | Step 1–4 frozen artifacts unchanged | PASS，19 个文件运行前后 SHA-256 一致 |
| B | amplitude relationships completed | PASS，独立 6 点 sweep |
| C | phase-error relationships completed | PASS，独立 6 点 sweep |
| D | LS prediction error quantified | PASS，RMSE/MAE/max abs/max relative/correlation/direction 完整 |
| E | Pearson and Spearman reported where meaningful | PASS；amplitude eta 明确不强行相关 |
| F | eta_geom limitations stated | PASS |
| G | mechanism evidence chain completed | PASS，5 个箭头逐项分级 |
| H | figures / CSV / MAT / report saved | PASS，6 对图及全部正式文件完整 |
| I | no cherry-picking or metric redefinition | PASS，全部正式点保留，两个 sweep 未混合 |

```text
STEP5_CORRELATION_AND_EVIDENCE: PASS
```

```text
ready for Phase 1B-6 Final Report
```

本步骤在此停止，不自动进入 Step 6，不开发 M4。
