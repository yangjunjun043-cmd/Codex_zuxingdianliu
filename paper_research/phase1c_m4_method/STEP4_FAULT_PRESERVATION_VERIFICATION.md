# Phase 1C Step 4 — Fault Preservation Verification

## 1. Scope

本步骤只评价冻结的 M4-v0 在两个正式故障工况中的 fault preservation：

- `Case05_fault_only`，seed 106，真实 Cs 恒定；
- `Case06_drift_then_fault`，seed 105，先完成 Cs drift，后发生 fault。

正式比较为 M2、M3、M4。没有执行 simultaneous drift+fault、Step 5/6、参数搜索、Monte-Carlo 或算法调优。Case06 的 drift 与 fault 不重叠，不能据此声称已经解决 simultaneous drift+fault。

## 2. Frozen Evidence and Fairness

每个 case 只取得一份 case-level Simulink 输出、参考、配置、seed、噪声实现和故障波形，再交给 M2/M3/M4。反事实分支从同一含故障数据中严格扣除：

\[
r_{fault,B}=(1-1/g_f)i_{R,B},
\]

且故障前逐样本完全相同。故障分支与反事实分支分别完整递归，fault-induced 参数偏差定义为：

\[
\Delta c_{fault}=\Delta c_{fault\ branch}-\Delta c_{counterfactual\ branch}.
\]

这与 Phase 1B 正式 recursive fault/counterfactual 定义一致。真值和 fault onset 只用于离线评价，从未进入 M4 控制。

本步骤没有修改 AutoComp9、M0/M2/M3、M4 evidence、M4 information/baseIn update、gate ratios、lambda、rate/projection、Case05/06、seed、fault waveform 或 Phase 1A/B/Step 1–3 结果。运行前后 303 个受保护文件 SHA-256 变化为 0。

## 3. Metrics and Fault Windows

正式冻结窗口来自 `evaluate_phase1a_metrics.m` 和 Phase 1B：

```text
pre-fault sample window = [2.60, 2.90) s
fault-state sample window = [3.40, 3.80) s
true fault onset = 3.00 s
fault ramp = 3.00–3.06 s
```

基波 RMS 由 `[sin(wt), cos(wt), 1]` 最小二乘拟合后计算 `hypot(b1,b2)/sqrt(2)`。正式 fault factor 为 fault-state 与 pre-fault 基波 RMS 之比；retention error 为：

\[
E_{ret}=100\frac{F_{est}-F_{true}}{F_{true}}.
\]

`pre/fault mean g`、USR、ISR 和方向统计同样采用完全落入上述两个窗口的完整工频周期。响应时间与 excess suppression area 使用从 3.00 s 到仿真结束的 response window；该窗口只用于动态诊断，不替换正式 retention 窗口。

Material suppression 的离线阈值严格按任务定义：

\[
T_{material}=median_{pre}(1-g)+3MAD_{pre}.
\]

本次两工况的 MAD 都为 0，因此采用 `max(P95_pre, median_pre+numerical_tol)`。onset 是故障后首次连续两个周期超过阈值的第一个周期时间戳；时间戳为周期末端。

## 4. Historical Baseline Reproduction

| Case | Historical item | Frozen | Step 4 | Absolute difference |
|---|---|---:|---:|---:|
| Case05 | true factor | 1.600000 | 1.600000 | < 4e-15 |
| Case05 | M2 factor | 1.401075 | 1.401075 | < 4e-15 |
| Case05 | M3 factor | 1.581137 | 1.581137 | < 4e-15 |
| Case05 | M2 fault ΔCs1 | +4.886379 | +4.886379 | < 4e-15 |
| Case05 | M2 fault ΔCs2 | -4.885713 | -4.885713 | < 4e-15 |
| Case06 | true factor | 1.600000 | 1.600000 | < 4e-15 |
| Case06 | M2 factor | 1.402269 | 1.402269 | < 4e-15 |
| Case06 | M3 factor | 1.582876 | 1.582876 | < 4e-15 |
| Case06 | M2 fault ΔCs1 | +4.888415 | +4.888415 | < 4e-15 |
| Case06 | M2 fault ΔCs2 | -4.881689 | -4.881689 | < 4e-15 |

Phase 1B 锚点最大绝对差为 `3.33e-15`。正式 baseline CSV 因十进制往返的最大差为 `4.26e-14`，远小于 `1e-12` 校验容差。历史锚点复现通过后才解释 M4。

## 5. Case05 Fault Only

### 5.1 Fault Factor

| Algorithm | True factor | Estimated factor | Retention error | Estimated pre RMS (A) | Estimated fault RMS (A) |
|---|---:|---:|---:|---:|---:|
| M2 | 1.600000 | 1.401075 | -12.4328% | 8.44343e-4 | 1.18299e-3 |
| M3 | 1.600000 | 1.581137 | -1.1789% | 8.44343e-4 | 1.33502e-3 |
| M4 | 1.600000 | 1.408580 | -11.9637% | 8.44349e-4 | 1.18933e-3 |

M4 相对 M2 恢复 0.46910 个 retention-error 百分点，即 M2 绝对 retention error 的约 3.77%。M4 明显弱于 M3：M3 的估计因子比 M4 高 0.17256，绝对 retention error 小 10.7848 个百分点。

### 5.2 Fault-Induced Parameter Bias

| Algorithm | ΔCs1 fault (pF) | ΔCs2 fault (pF) | PAR Cs1 | PAR Cs2 |
|---|---:|---:|---:|---:|
| M2 | +4.886379 | -4.885713 | 1.0000 | 1.0000 |
| M3 | +0.427125 | -0.547006 | 0.0874 | 0.1120 |
| M4 | +4.695238 | -4.710032 | 0.9609 | 0.9640 |

M4 相对 M2 将 |ΔCs1|/|ΔCs2| 分别减少 `0.191141/0.175681 pF`，相对减少 `3.912%/3.596%`。M4 achieved/static bias ratios 为 `0.96084/0.96387`，说明 Phase 1B 静态可吸收方向仍有约 96% 最终进入递归参数偏差。

### 5.3 Continuous Suppression

```text
pre mean g       = 0.997214
fault mean g     = 0.361036
pre USR          = 0.002786
fault USR        = 0.638964
Delta USR fault  = 0.636177
fault min/P05/P50/P95 g = 0.352129 / 0.353324 / 0.360472 / 0.368737
excess suppression area = 0.628815 s
```

故障后产生了强、持续且连续的降权，不是正常背景 `g<1` 的简单延续。

### 5.4 Response Latency

```text
M4 material onset   = 3.01998 s
M4 material latency = 0.01998 s
M3 gate onset       = 3.05998 s
M3 gate latency     = 0.05998 s
```

按冻结的 robust-background 定义，M4 比 M3 早约 40 ms（两个工频周期）出现可测 fault-related excess suppression。但“更早”不等于“保持更强”；最终 retention 明显弱于 M3。

### 5.5 Information-State Absorption

| Metric | Pre | Fault |
|---|---:|---:|
| ISR J | 0.004344 | 0.638823 |
| ISR h | 0.004348 | 0.638830 |

fault window 的 information-suppressed ΔCs1/ΔCs2 RMS 为 `0.057261/0.053720 pF/cycle`，累计绝对抑制为 `0.893513/0.751201 pF`，最大单周期抑制为 `0.159701 pF`。rate limit 和 projection 均为 0 周期，因此 J/h 写入减少确实来自 weighted information update。

## 6. Case06 Drift Then Fault

### 6.1 Pre-Fault State

在冻结的 0.80–2.20 s drift window：

| Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | Pre Cs1 bias (pF) | Pre Cs2 bias (pF) |
|---|---:|---:|---:|---:|
| M2 | 0.216861 | 0.159477 | -0.057827 | +0.056939 |
| M3 | 0.216861 | 0.159477 | -0.057827 | +0.056939 |
| M4 | 0.217700 | 0.160200 | -0.058015 | +0.056772 |

M4 的正常 drift RMSE 只略高于 M2/M3，与 Step 3 的 minor normal-tracking degradation 一致。fault 前 `mean(g)=0.990050`、USR=0.009950，存在较弱 background suppression。

### 6.2 Fault Factor

| Algorithm | True factor | Estimated factor | Retention error |
|---|---:|---:|---:|
| M2 | 1.600000 | 1.402269 | -12.3582% |
| M3 | 1.600000 | 1.582876 | -1.0702% |
| M4 | 1.600000 | 1.409655 | -11.8966% |

M4 相对 M2 恢复 `0.46161` 个 retention-error 百分点，即 M2 绝对 error 的约 3.74%。

### 6.3 Fault-Induced Parameter Bias

| Algorithm | ΔCs1 fault (pF) | ΔCs2 fault (pF) | PAR Cs1 | PAR Cs2 |
|---|---:|---:|---:|---:|
| M2 | +4.888415 | -4.881689 | 1.0000 | 1.0000 |
| M3 | +0.443259 | -0.520594 | 0.0907 | 0.1066 |
| M4 | +4.706376 | -4.705511 | 0.9628 | 0.9639 |

M4 的绝对减少为 `0.182039/0.176178 pF`，相对减少 `3.724%/3.609%`。achieved/static ratios 为 `0.96312/0.96294`。

### 6.4 Continuous Suppression

```text
pre mean g       = 0.990050
fault mean g     = 0.361718
pre USR          = 0.009950
fault USR        = 0.638282
Delta USR fault  = 0.628332
fault min/P05/P50/P95 g = 0.351772 / 0.352239 / 0.361679 / 0.373935
excess suppression area = 0.626080 s
```

fault 后 excess suppression 明显增加，并与 Case05 量级一致。

### 6.5 Response Latency and Information State

M4 material latency 同样为 `0.01998 s`，M3 gate latency 为 `0.05998 s`。ISR J 从 `0.005562` 增至 `0.637427`，ISR h 从 `0.005568` 增至 `0.637456`。fault-window suppressed ΔCs1/ΔCs2 RMS 为 `0.063985/0.073235 pF/cycle`，累计绝对抑制为 `0.870769/0.898358 pF`，最大单周期为 `0.208722 pF`。rate/projection 仍均为 0。

## 7. M2/M3/M4 Comparison

| Case | Algorithm | True factor | Estimated factor | Retention error | ΔCs1 fault (pF) | ΔCs2 fault (pF) |
|---|---|---:|---:|---:|---:|---:|
| Case05 | M2 | 1.600000 | 1.401075 | -12.4328% | +4.886379 | -4.885713 |
| Case05 | M3 | 1.600000 | 1.581137 | -1.1789% | +0.427125 | -0.547006 |
| Case05 | M4 | 1.600000 | 1.408580 | -11.9637% | +4.695238 | -4.710032 |
| Case06 | M2 | 1.600000 | 1.402269 | -12.3582% | +4.888415 | -4.881689 |
| Case06 | M3 | 1.600000 | 1.582876 | -1.0702% | +0.443259 | -0.520594 |
| Case06 | M4 | 1.600000 | 1.409655 | -11.8966% | +4.706376 | -4.705511 |

M2 完整自适应并形成最大 fault absorption。M3 在 60 ms 后二值冻结，保持强度最高。M4 在约 20 ms 后连续降权且保留非零更新，但最终 preservation 只比 M2 略好，明显弱于 M3。

## 8. Retention–Parameter-Bias Mechanism

Case05/06 都出现同一组同步变化：

```text
M2 -> M4:
fault-induced |Delta Cs| reduces by about 3.6%–3.9%
retention absolute error reduces by about 3.7%–3.8%
```

因此 fault-factor recovery 与 fault-induced false Cs bias reduction 同时出现，支持 Phase 1B 的机制链在 M4 上仍成立。然而恢复量很小，因为 M4 最终仍吸收了约 96% 的 M2/static fault bias。

最重要的机制观察是：虽然 fault-window J/h information write 被抑制约 64%，M4 同时按相同标量权重缩放 J 与 h 的信息增量；持续故障下，递归状态仍向近似相同的故障偏置固定点推进，只是速度较慢。因而强瞬时 information suppression 没有等比例转化为稳态参数保持。

## 9. Residual Evidence Analysis

| Case | Pre Ein/baseIn | Fault Ein/baseIn | Pre Ein/Equad | Fault Ein/Equad | Pre eb | Fault eb | Pre pq | Fault pq | Pre s | Fault s |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Case05 | 0.9967 | 1.2124 | 83.24 | 9.80 | 0.00288 | 1.77024 | 1.000 | 1.000 | 0.00288 | 1.77024 |
| Case06 | 0.9974 | 1.2119 | 91.21 | 9.94 | 0.01053 | 1.76544 | 1.000 | 1.000 | 0.01053 | 1.76544 |

故障后 `E_in/baseIn` 上升并推动 `e_b` 从接近 0 增至约 1.77，从而令 `g≈1/(1+1.77)≈0.36`。`E_in/E_quad` 虽然下降，但仍足以使 `p_q` 在故障前后均饱和为 1；本工况的降权主要由 background residual excess 驱动，而不是 phase-weight 的额外区分。

## 10. Direction Diagnostic during Fault

| Case/phase | Median local cosine | Mean abs cosine | P05 | P95 |
|---|---:|---:|---:|---:|
| Case05 pre | 0.8474 | 0.7525 | -0.3070 | 0.9995 |
| Case05 fault | 0.9095 | 0.7751 | -0.8171 | 0.9989 |
| Case06 pre | 0.6711 | 0.6934 | -0.6860 | 0.9843 |
| Case06 fault | 0.9419 | 0.8373 | -0.9733 | 0.9996 |

Step 3 正常 Case01–04 的 median local cosine 为 `0.731–0.904`，mean absolute cosine 为 `0.691–0.755`。fault window 特别是 Case06 有一定上移，说明方向量存在 additional diagnostic potential；但 fault 与 normal 范围高度重叠，且 fault P05 仍显著为负。方向量尚未形成 fault-specific discrimination evidence，不能单独反馈到控制。

## 11. M4 versus M3 Mechanistic Differences

- M4 的 material response 比 M3 gate 早两个周期，并持续保留约 36% update weight。
- M3 触发后 hard gate active ratio 为 0.96，相当于近乎完整冻结。
- M4 fault-window ISR 约 0.638，但最终 PAR 仍约 0.96；响应早、信息写入少，不代表最终偏置小。
- M3 最终 PAR 约 0.087–0.112，retention factor 约 1.581–1.583；preservation 明显强于 M4。
- M3 的代价是二值冻结期间无法继续正常跟踪；M4 保留连续适应能力。该差异是否在真正 overlapping drift+fault 中有价值，必须由 Step 5 才能评价。

因此不做简单“谁赢了”的总排名：M4 响应更早且连续，M3 保持强度更高。

## 12. Limitations

1. 只有冻结的 Case05/06 单 seed，不能作概率性或鲁棒性结论。
2. Case06 的 drift 在 fault 前已经结束，不是 simultaneous drift+fault。
3. Material onset 阈值只用于离线评价；两工况 pre MAD 为 0，使用了任务指定的 P95 fallback。
4. M4-v0 是标量 state-consistent information weighting。当前结果暴露其结构限制：可显著减慢错误信息写入，却不能显著改变持续故障下的最终错误固定点。
5. Direction distribution 有上移但与正常分布重叠，仍不得用于控制。
6. 模型运行继续显示既有未连接端口和 algebraic-loop warnings；无运行 error，模型未修改。

## 13. Regression Protection

```text
Formal frozen validator              19/19 PASS
Historical regression                11/11 PASS
Step 4 M2/M3 baseline max difference 4.26e-14
Phase 1B anchor max difference       3.33e-15
Protected files unchanged            303/303
```

Formal validator 采用冻结 workspace 只读检查；历史回归为只读 CSV/reference 检查。Step 4 当前 Case05/06 M2/M3 又独立重算并与 baseline/Phase 1B 锚点闭合。没有为回归额外运行其他正式工况。

## 14. Step 4 Acceptance Conclusion

### Q1. Case05 M4 fault factor 是多少？

`1.408580`，retention error 为 `-11.9637%`。

### Q2. Case06 M4 fault factor 是多少？

`1.409655`，retention error 为 `-11.8966%`。

### Q3. 相对 M2，M4 将 retention error 减少了多少？

Case05 减少 `0.46910` 个百分点（约 3.77% 相对减少）；Case06 减少 `0.46161` 个百分点（约 3.74%）。

### Q4. 相对 M2，M4 将 fault-induced ΔCs1/ΔCs2 减少了多少？

Case05：`0.191141/0.175681 pF`，即 `3.912%/3.596%`；Case06：`0.182039/0.176178 pF`，即 `3.724%/3.609%`。

### Q5. M4 fault-window mean g 是多少？

Case05 `0.361036`；Case06 `0.361718`。

### Q6. fault 相对 pre-fault 增加了多少 excess suppression？

`Delta USR`：Case05 `0.636177`，Case06 `0.628332`。Excess suppression area：`0.628815/0.626080 s`。

### Q7. M4 material suppression latency 是多少？

两工况均为 `0.01998 s`，约一个工频周期。

### Q8. M3 hard gate latency 是多少？

两工况均为 `0.05998 s`，约三个工频周期。

### Q9. M4 是否在 M3 gate 前出现了可测的 fault-related excess suppression？

是。M4 material onset 比 M3 gate 早约 `0.040 s`，但其最终 preservation 更弱。

### Q10. M4 是否真正减少了 J/h 信息状态的 fault absorption？

是。fault ISR J/h 均约 0.637–0.639，而 pre 仅约 0.004–0.006；且 rate/projection 未参与。但这主要减慢了写入速度，没有等比例改变最终故障偏置。

### Q11. fault-factor recovery 是否与 parameter-bias reduction 同时出现？

是。两个 case 都同时出现约 3.6%–3.9% 的参数偏置减少和约 3.7% 的 retention-error 减少，机制方向一致。

### Q12. M4 fault preservation 与 M3 相比属于更强、相近还是更弱？

保持强度明显更弱：M4 factor 约 1.409、PAR 约 0.96；M3 factor 约 1.581–1.583、PAR 约 0.09–0.11。M4 的优势仅在更早、连续且保留非零 adaptation，不能据此宣称总体优于 M3。

### Q13. Case05 与 Case06 的机制表现是否一致？

一致。factor、PAR、Delta USR、latency、ISR 和 achieved/static ratio 均高度接近，说明前置 drift 没有改变本步骤观察到的 M4-v0 基本机制。

### Q14. fault direction diagnostic 是否出现新的 fault-specific discrimination evidence？

没有形成 fault-specific 证据。fault 分布有上移，具有额外诊断潜力，但与 Step 3 正常分布仍高度重叠。

### Q15. 当前 M4-v0 是否值得进入 Step 5 simultaneous drift+fault？

值得作为冻结候选继续评价：它显示了可重复的早期连续响应和小幅 fault preservation，同时暴露了稳态保持较弱的结构限制。Step 5 可检验“保留非零 adaptation”在真正重叠 drift+fault 中是否带来 M3 不具备的价值。本步骤不自动执行 Step 5。

### Q16. Step 4 execution 是否 PASS？

是。数据公平、指标完整、历史锚点复现、受保护文件未变化、结果可重现。

```text
STEP 4 EXECUTION STATUS:
PASS

M4 FAULT-PRESERVATION ASSESSMENT:
IMPROVED
```

`IMPROVED` 表示相对 full-adaptation M2，两个 case 的 retention、fault-induced bias、information absorption 和 latency 证据方向一致地改善；改善幅度有限，且 preservation 明显弱于 M3。

完成后停止，等待人工验收。

## 15. Artifacts and Commands

### Commands

```text
matlab -batch "... checkcode Step 4 sources ..."
matlab -batch "addpath(stepRoot); result=run_phase1c_step4_fault_preservation();"
matlab -batch "... regenerate figures from saved workspace ..."
matlab -batch "... read frozen formal validation; run read-only historical regression ..."
```

### Tables and diagnostics

- `step4_fault_preservation/tables/fault_preservation_summary.csv`
- `step4_fault_preservation/tables/parameter_absorption_summary.csv`
- `step4_fault_preservation/tables/m4_fault_response_summary.csv`
- `step4_fault_preservation/tables/m3_gate_response_summary.csv`
- `step4_fault_preservation/diagnostics/prefault_tracking_summary.csv`
- `step4_fault_preservation/diagnostics/direction_fault_diagnostics.csv`
- `step4_fault_preservation/diagnostics/m4_fault_cycle_diagnostics.csv`
- `step4_fault_preservation/workspace/fault_preservation_workspace.mat`

### Figures

`Figure_A` through `Figure_G` are saved as both `.png` and `.fig` under `step4_fault_preservation/figures/`.

### Step 4 source

- `run_phase1c_step4_fault_preservation.m`
- `evaluate_phase1c_step4_case.m`
- `generate_phase1c_step4_figures.m`
- `prefault_tracking_table.m`

