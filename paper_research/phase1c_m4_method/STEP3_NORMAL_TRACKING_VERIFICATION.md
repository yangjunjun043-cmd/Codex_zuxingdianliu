# Phase 1C Step 3 — Normal Tracking Verification

## 1. Scope

本步骤只评价 M4-v0 在无真实阻性故障条件下的正常跟踪代价。正式评价工况为：

- `Case01_static`，seed 101；
- `Case02_slow_drift`，seed 102；
- `Case03_smooth_step`，seed 103；
- `Case04_random_drift`，seed 104。

正式比较算法为 M2、M3、M4。未新增工况，未执行参数搜索、阈值选择、Monte-Carlo、Step 4/5/6 或 M4 公式修改。

正式 Step 3 runner 对每个 case 只取得一份 case-level `data/ref/cfg`，然后将同一份数据、同一参考和同一配置交给 M2/M3/M4。`simulate_phase2_case` 内部仍保留既有双路径低层仿真与一致性检查；这不产生算法间不同的数据实现。

说明：为满足第 21 节的“formal frozen baseline unchanged”回归要求，最后在系统临时目录隔离重放了冻结的 Phase 1A 六工况 runner。因此 Case05/06 只在冻结 M0/M2/M3 回归中经过重放；没有运行 M4、没有进入本报告的评价数据、没有生成 Step 4 故障保持结论，也没有写入正式 Phase 1A/B 路径。

## 2. Frozen Algorithms and Fairness

本步骤没有修改：

- `AI6109_MOA_AutoComp9.slx`；
- M0、M2、M3 与 `track_coupling_cvff_rls.m`；
- M4-v0 evidence、information update、`baseIn` 更新公式；
- `gate_ratio`、`gate_quad_ratio`、lambda、rate limit、physical projection；
- Case01–04 数据生成、seed 和 Phase 1A/B 正式结果。

运行前建立的保护清单包含 111 个文件。运行和报告生成前复核结果为：

```text
protected files = 111
hash changes = 0
```

M4 方向量只被记录和离线统计，没有进入 `g/J/h/c/baseIn` 控制路径。

## 3. Metrics

### 3.1 正式跟踪指标

Cs 指标沿用 Phase 1A 正式评价窗口 `t >= cfg.metric_start`：

\[
RMSE_{Cs_i}=\sqrt{\operatorname{mean}\left((\hat C_{s_i}-C_{s_i})^2\right)}.
\]

最大绝对误差使用同一窗口。

B 相阻性电流误差直接调用冻结的 `evaluate_phase1a_metrics.m -> evaluate_case_metrics.m`。在正式窗口内，以

```text
[sin(wt), cos(wt), sin(3wt), cos(3wt), 1]
```

分别拟合真值和估计波形；基波 RMS 为 `hypot(b1,b2)/sqrt(2)`，正式指标为：

\[
E_{B,1}=\frac{I_{1,est}-I_{1,true}}{I_{1,true}+\epsilon}\times 100\%.
\]

报告中的 B 相“退化”比较绝对误差大小，即 `abs(E_M4)-abs(E_M2)`，避免正负号抵消。

### 3.2 M4 正常保护指标

按冻结定义计算：

\[
\bar g=\operatorname{mean}(g_k),\qquad
USR=\operatorname{mean}(1-g_k)=1-\bar g.
\]

同时计算 `ISR_J`、`ISR_h`、information-suppressed 参数更新 RMS/最大值以及 `g` 的分位数和描述性阈值比例。四个工况的 USR 数值闭合误差均不超过 `1.43e-16`。

## 4. Case01 Static

| Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | Cs1 max (pF) | Cs2 max (pF) | B fundamental error (%) |
|---|---:|---:|---:|---:|---:|
| M2 | 0.040370 | 0.039295 | 0.096843 | 0.094084 | -0.035610 |
| M3 | 0.040370 | 0.039295 | 0.096843 | 0.094084 | -0.035610 |
| M4 | 0.039814 | 0.039258 | 0.096302 | 0.092259 | -0.034742 |

M4 的 `mean(g)=0.980272`，`USR=0.019728`，说明静态正常工况下并未严格退化到 `g=1`，而是存在平均约 1.97% 的轻微信息抑制。稳态窗口内 `E_in/baseIn` 均值为 1.00056，`E_in/E_quad` 均值为 89.039；背景归一化残差围绕 1 的随机正向超出产生了持续但较弱的自然 evidence。该动作没有损害静态性能：Cs1/Cs2 RMSE 分别变化 -1.38%/-0.094%，B 相绝对误差下降 0.000868 个百分点。

这不是“无保护动作”，但在本工况中是无可见性能代价的轻微正常残差响应。

## 5. Case02 Slow Drift

| Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | Cs1 max (pF) | Cs2 max (pF) | B fundamental error (%) |
|---|---:|---:|---:|---:|---:|
| M2 | 0.157320 | 0.108514 | 0.378823 | 0.269201 | 0.354786 |
| M3 | 0.157320 | 0.108514 | 0.378823 | 0.269201 | 0.354786 |
| M4 | 0.160864 | 0.110566 | 0.388028 | 0.271503 | 0.364798 |

M4 的 `mean(g)=0.975012`、`USR=0.024988`，是四个正常工况中平均抑制最强的工况。分阶段结果为：

| Phase | Mean g | USR | Mean fault evidence | Mean parameter-error norm (pF) |
|---|---:|---:|---:|---:|
| drift onset | 0.952311 | 0.047689 | 0.050494 | 0.043793 |
| drift middle | 0.973088 | 0.026912 | 0.029392 | 0.347880 |
| drift end | 0.976867 | 0.023133 | 0.024402 | 0.111679 |
| post drift | 0.985760 | 0.014240 | 0.014983 | 0.061035 |

抑制主要在 drift onset 较强，随后减弱。相对 M2，M4 的 Cs1/Cs2 RMSE 增加 2.253%/1.891%，绝对增加 0.003544/0.002052 pF。中点跟踪滞后为：Cs1 0.12 s（与 M2 相同），Cs2 0.06 s（M2 为 0.04 s），即 Cs2 增加一个 20 ms 工频周期。B 相绝对误差增加 0.010013 个百分点。

结论：存在可测但较小的正常跟踪代价，不构成明显失跟踪。

## 6. Case03 Smooth Step

| Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | Cs1 max (pF) | Cs2 max (pF) | B fundamental error (%) |
|---|---:|---:|---:|---:|---:|
| M2 | 0.229793 | 0.180056 | 1.635393 | 1.197288 | 0.164192 |
| M3 | 0.229793 | 0.180056 | 1.635393 | 1.197288 | 0.164192 |
| M4 | 0.231236 | 0.181171 | 1.640273 | 1.201743 | 0.166911 |

M4 的 `mean(g)=0.984192`、`USR=0.015808`。在 1.45–1.65 s transition 窗口中，`mean(g)=0.995739`、USR 仅 0.004261；此时 lambda 明显响应，而 protection 反而接近完全开放。因此该工况的主要瞬态跟踪滞后来自冻结的 CVFF-RLS/lambda 与块更新动态，不应归因于 M4 protection。

M2/M3/M4 的 Cs1 和 Cs2 中点滞后均为 0.03 s，M4 没有增加该定义下的过渡滞后。相对 M2，Cs1/Cs2 RMSE 增加 0.628%/0.619%，B 相绝对误差增加 0.002719 个百分点。

## 7. Case04 Random Drift

| Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | Cs1 max (pF) | Cs2 max (pF) | B fundamental error (%) |
|---|---:|---:|---:|---:|---:|
| M2 | 0.269285 | 0.209895 | 1.059245 | 0.762948 | -0.087605 |
| M3 | 0.269285 | 0.209895 | 1.059245 | 0.762948 | -0.087605 |
| M4 | 0.270183 | 0.210839 | 1.059125 | 0.761986 | -0.087082 |

M4 的 `mean(g)=0.991764`、`USR=0.008236`，为四工况中最小。随机跟踪阶段 `mean(g)=0.991012`、USR=0.008988。相对 M2，Cs1/Cs2 RMSE 仅增加 0.334%/0.450%，最大绝对误差反而略小；B 相绝对误差下降 0.000523 个百分点。

没有发现持续强保护或随时间积累的跟踪误差。存在低强度、间歇性的正常保护动作，但其量级没有形成可见的累计性能损害。

## 8. M2/M3/M4 Summary

| Case | Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | B error (%) | Mean g | USR | M3 hard-gate ratio |
|---|---|---:|---:|---:|---:|---:|---:|
| Case01 | M2 | 0.040370 | 0.039295 | -0.035610 | N/A | N/A | N/A |
| Case01 | M3 | 0.040370 | 0.039295 | -0.035610 | N/A | N/A | 0 |
| Case01 | M4 | 0.039814 | 0.039258 | -0.034742 | 0.980272 | 0.019728 | N/A |
| Case02 | M2 | 0.157320 | 0.108514 | 0.354786 | N/A | N/A | N/A |
| Case02 | M3 | 0.157320 | 0.108514 | 0.354786 | N/A | N/A | 0 |
| Case02 | M4 | 0.160864 | 0.110566 | 0.364798 | 0.975012 | 0.024988 | N/A |
| Case03 | M2 | 0.229793 | 0.180056 | 0.164192 | N/A | N/A | N/A |
| Case03 | M3 | 0.229793 | 0.180056 | 0.164192 | N/A | N/A | 0 |
| Case03 | M4 | 0.231236 | 0.181171 | 0.166911 | 0.984192 | 0.015808 | N/A |
| Case04 | M2 | 0.269285 | 0.209895 | -0.087605 | N/A | N/A | N/A |
| Case04 | M3 | 0.269285 | 0.209895 | -0.087605 | N/A | N/A | 0 |
| Case04 | M4 | 0.270183 | 0.210839 | -0.087082 | 0.991764 | 0.008236 | N/A |

M3 在四个无故障工况中 hard gate 均未触发，因此 M2/M3 数值完全相同。M3 的 hard gate 不能与 M4 的连续 `g` 混为同一指标。

## 9. Unnecessary Suppression Analysis

| Case | Mean g | USR | ISR J | ISR h | RMS suppressed ΔCs1 (pF) | RMS suppressed ΔCs2 (pF) | Max suppressed ΔCs (pF) | Min/P05/P50/P95 g |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Case01 | 0.980272 | 0.019728 | 0.020548 | 0.020534 | 0.000825 | 0.000703 | 0.004088 | 0.8870 / 0.9273 / 0.9966 / 1.0000 |
| Case02 | 0.975012 | 0.024988 | 0.025422 | 0.025067 | 0.002216 | 0.001673 | 0.020002 | 0.8749 / 0.9222 / 0.9870 / 1.0000 |
| Case03 | 0.984192 | 0.015808 | 0.015978 | 0.015922 | 0.001340 | 0.001212 | 0.014733 | 0.9015 / 0.9315 / 1.0000 / 1.0000 |
| Case04 | 0.991764 | 0.008236 | 0.008450 | 0.008358 | 0.002168 | 0.001437 | 0.024452 | 0.9222 / 0.9617 / 1.0000 / 1.0000 |

`ISR_J/h` 与 USR 同量级，说明连续权重确实按预期作用于信息增量；它不是只有日志中的 `g` 变化。另一方面，information-suppressed 参数运动的 RMS 仅为 0.00070–0.00222 pF/cycle，绝对量很小。四个工况均无 rate-limit 或 projection active cycle，因此观察到的 M4–M2 差异不是由后级约束触发造成。

描述性比例显示：Case01–04 的 `fraction(g<0.99)` 分别为 44.85%、53.33%、39.39%、26.06%；但低阈值出现频繁不等同于强保护，因为平均 `1-g` 仍只有 0.82%–2.50%。

## 10. Drift–Evidence Correlation

每周期用真实 `Cs1/Cs2` 增量的欧氏模作为离线 drift magnitude。真值只参与评价，没有进入在线算法。

| Case | Target | Pearson r | Spearman rho | Valid pairs |
|---|---|---:|---:|---:|
| Case02 | `1-g` | -0.02496 | -0.00158 | 164 |
| Case02 | fault evidence | -0.02591 | -0.00158 | 164 |
| Case03 | `1-g` | -0.11488 | -0.13413 | 164 |
| Case03 | fault evidence | -0.11412 | -0.13413 | 164 |
| Case04 | `1-g` | 0.00242 | 0.00376 | 164 |
| Case04 | fault evidence | 0.00426 | 0.00376 | 164 |

三种 drift 工况的线性和秩相关均很弱，且 Case02/03 为弱负相关。当前自然 residual evidence 没有系统性地把“真实参数运动越快”解释成“fault evidence 越强”。Case03 transition 中 `g` 接近 1 的分阶段结果与该结论一致。

## 11. Direction Diagnostic under Normal Drift

| Case | Valid ratio | Local cosine mean | median | P05 | P95 | Mean abs | Raw cosine mean | median | P05 | P95 | Mean abs |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Case01 | 1.000 | 0.4982 | 0.7787 | -0.8603 | 0.9990 | 0.7321 | 0.4983 | 0.7798 | -0.8614 | 0.9991 | 0.7321 |
| Case02 | 1.000 | 0.6284 | 0.9045 | -0.7003 | 0.9987 | 0.7548 | 0.6283 | 0.9034 | -0.6987 | 0.9987 | 0.7546 |
| Case03 | 1.000 | 0.4506 | 0.7307 | -0.9002 | 0.9987 | 0.7408 | 0.4505 | 0.7319 | -0.9013 | 0.9989 | 0.7409 |
| Case04 | 1.000 | 0.5835 | 0.7508 | -0.5162 | 0.9986 | 0.6910 | 0.5835 | 0.7501 | -0.5157 | 0.9987 | 0.6910 |

正常工况的 direction candidate 在全部周期都有效，median cosine 为 0.731–0.904，P95 约 0.999，mean absolute cosine 为 0.691–0.755。与此同时 P05 为负，说明符号并不稳定。关键负证据是：高方向一致性并非 fault 独有；仅凭高 cosine 不能安全区分正常漂移与故障吸收。当前方向诊断不具备 fault-specific discrimination evidence，继续保持 diagnostic-only 是必要的。

## 12. Normal-Tracking Cost of M4

| Case | Cs1 relative degradation | Cs2 relative degradation | ΔCs1 RMSE (pF) | ΔCs2 RMSE (pF) | B absolute-error relative degradation | B absolute change (percentage point) |
|---|---:|---:|---:|---:|---:|---:|
| Case01 | -1.378% | -0.094% | -0.000556 | -0.000037 | -2.437% | -0.000868 |
| Case02 | +2.253% | +1.891% | +0.003544 | +0.002052 | +2.822% | +0.010013 |
| Case03 | +0.628% | +0.619% | +0.001443 | +0.001114 | +1.656% | +0.002719 |
| Case04 | +0.334% | +0.450% | +0.000898 | +0.000944 | -0.597% | -0.000523 |

最大正常跟踪代价出现在 Case02；其相对数值约 2%，但绝对 Cs RMSE 增量不超过 0.00355 pF，B 相绝对误差增量为 0.0100 个百分点。Case03/04 的退化更小。结合绝对误差、跟踪滞后和信息抑制量，M4-v0 保持了可接受的正常自适应能力。

本结论只说明“normal tracking preserved with minor degradation”；不说明 M4 superior、optimal 或具有故障保持优势。故障保持尚未在本步骤评价。

## 13. Failure / Limitation Analysis

1. Case01 的 `g` 不是严格等于 1：静态正常残差仍产生约 1.97% 平均抑制，说明 evidence 并非无故障零响应。
2. Case02 是当前代价最大的正常工况，Cs2 中点滞后比 M2 增加 20 ms。
3. `fraction(g<0.99)` 可较高，但它是描述性阈值统计；不能替代 USR、ISR 和最终跟踪误差。
4. 方向候选在正常工况同样产生很高 cosine，方向信息本身不具故障特异性。
5. 本步骤只有单个冻结 seed/工况轨迹，不支持概率性鲁棒性结论。
6. 本步骤没有 fault，不能推断 M4 的 fault preservation、fault retention 或相对 M3 的故障性能。
7. 模型运行仍出现既有的未连接测量端口和 algebraic-loop warnings；无 MATLAB/Simulink error，且模型未修改。

没有发现会阻止下一阶段“故障保持评价”的正常跟踪结构性 blocker。

## 14. Regression Protection

### 14.1 Step 3 内部回归

- 12 个正式 `case × algorithm` 结果完整；
- Case01–04 M2/M3 与冻结 baseline CSV 最大绝对差：`4.718447854656915e-16`（十进制 CSV 读取往返量级）；
- 所有权重满足 `0 < g <= 1`；
- USR 闭合误差最大 `1.43e-16`；
- 正式工况中 M3 hard gate ratio 全部为 0。

### 14.2 独立冻结回归

使用临时输出目录重放 `run_phase1a_baseline`，未覆盖正式结果：

```text
Formal validator = 19/19 PASS
M0/M2/M3 workspace numeric exact = true
M0/M2/M3 maximum absolute difference = 0
Historical Case02 = 4/4 PASS
Historical Case06 = 7/7 PASS
Historical total = 11/11 PASS
Protected-file hashes = 111/111 unchanged
```

因此 Step 3 没有改变冻结基线或历史参考。

## 15. Step 3 Acceptance Conclusion

### Q1–Q13

**Q1. Case01 中 M4 是否基本保持 M2 的静态性能？**

是。Cs RMSE 与 B 相误差没有恶化；M4 甚至略低。需要保留的事实是 `mean(g)=0.9803`，静态下仍有约 1.97% 平均抑制。

**Q2. Case02 慢漂移时是否产生明显不必要 suppression？**

产生了可测的 suppression，且是四工况中最大：USR=2.499%，onset 窗口为 4.769%。其最终代价较小而非“明显失跟踪”：Cs RMSE 增加约 1.9%–2.3%。

**Q3. Case03 smooth step 中 M4 的跟踪滞后是否增加？**

没有。按冻结轨迹的中点穿越定义，M2/M3/M4 的 Cs1/Cs2 滞后均为 0.03 s。transition 期间 lambda 有明显响应，而 M4 的 `g=0.9957`，应区分两种机制。

**Q4. Case04 random drift 是否造成持续保护和累计误差？**

没有发现持续强保护或累计误差。USR=0.824%，Cs RMSE 增量约 0.33%–0.45%，最大误差未增加。

**Q5. M4 的 mean update weight 分别是多少？**

Case01–04 分别为 `0.980272 / 0.975012 / 0.984192 / 0.991764`。

**Q6. Case01–04 的 USR 分别是多少？**

分别为 `0.019728 / 0.024988 / 0.015808 / 0.008236`，即 `1.973% / 2.499% / 1.581% / 0.824%`。

**Q7. M4 相对 M2 的 Cs1/Cs2 RMSE 变化是多少？**

Case01 `-1.378%/-0.094%`；Case02 `+2.253%/+1.891%`；Case03 `+0.628%/+0.619%`；Case04 `+0.334%/+0.450%`。

**Q8. B 相阻性电流误差是否明显恶化？**

否。绝对误差的最大增加为 Case02 的 0.010013 个百分点；Case01/04 还略有下降。

**Q9. fault evidence 是否与真实 Cs drift magnitude 明显相关？**

否。Case02–04 的 Pearson 绝对值不超过 0.1149，Spearman 绝对值不超过 0.1341，没有明显正相关。

**Q10. 正常 drift 是否也产生高 direction cosine？**

是。Case02–04 的 local median cosine 为 0.9045/0.7307/0.7508，P95 均约 0.999；正常 drift 可以产生高方向一致性。

**Q11. 当前方向诊断是否具有 fault-specific discrimination evidence？**

没有。正常工况已经产生高 cosine，且 P05 又为负，不能仅依靠方向一致性完成安全分离。

**Q12. M4-v0 是否在未发生 fault 时保持了“可接受的正常自适应能力”？**

是。观察到 minor degradation，但绝对量小、无 rate/projection 参与、无明显累计误差，正常跟踪能力得到保留。

**Q13. 是否允许进入 Step 4 Fault Preservation Verification？**

允许。Step 3 已充分刻画正常跟踪成本，未发现进入故障保持评价前的结构性 blocker；但本步骤不自动执行 Step 4。

```text
PHASE 1C STEP 3 STATUS:
PASS

M4-v0 normal-tracking cost is sufficiently characterized
and no structural blocker was found before fault-preservation evaluation.
```

完成后停止，等待人工验收。

## 16. Reproducibility and Artifacts

### MATLAB commands

```text
matlab -batch "... checkcode Step 3 sources ..."
matlab -batch "addpath(stepRoot); result=run_phase1c_step3_normal_tracking();"
matlab -batch "... run_phase1a_baseline(tempname); compare frozen workspace; run_phase1a_step7_regression();"
```

### Main artifacts

- `step3_normal_tracking/tables/normal_tracking_summary.csv`
- `step3_normal_tracking/tables/m4_normal_protection_metrics.csv`
- `step3_normal_tracking/tables/relative_degradation.csv`
- `step3_normal_tracking/diagnostics/tracking_lag.csv`
- `step3_normal_tracking/diagnostics/drift_evidence_correlation.csv`
- `step3_normal_tracking/diagnostics/direction_diagnostics.csv`
- `step3_normal_tracking/diagnostics/normal_phase_diagnostics.csv`
- `step3_normal_tracking/diagnostics/m4_cycle_diagnostics.csv`
- `step3_normal_tracking/workspace/normal_tracking_workspace.mat`
- `step3_normal_tracking/figures/Figure_A...Figure_F`，均含 `.png` 与 `.fig`。

### Step 3 source files

- `step3_normal_tracking/run_phase1c_step3_normal_tracking.m`
- `step3_normal_tracking/evaluate_phase1c_step3_case.m`
- `step3_normal_tracking/generate_phase1c_step3_figures.m`

