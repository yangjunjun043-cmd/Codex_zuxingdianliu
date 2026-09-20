# Phase 1C Step 5 — Simultaneous Drift + Fault

## 1. Scope

本步骤只验证冻结的 `M4-v0 = Residual-Evidence Weighted Information Update` 在真实 Cs 漂移与临时阻性故障同时存在时的行为。正式比较对象为 M2、M3、M4；方向量仅做离线诊断，不进入控制。

本步骤没有修改：

- `AI6109_MOA_AutoComp9.slx`；
- Phase 1A Case01–Case06 registry 或正式结果；
- Phase 1B 正式结果；
- M2/M3/M4 core、lambda、rate limit、projection、gate 或 M4 evidence 参数。

未执行 Step 6，未进行 fault-factor sweep，未调参。

## 2. Case07 Frozen Specification

Case07 在任何 M2/M3/M4 结果产生前完成冻结。

| Item | Frozen value |
|---|---:|
| Case | `Case07_overlap_drift_fault` |
| Source case | `Case06_drift_then_fault` |
| Model | `AI6109_MOA_AutoComp9` |
| Seed | 105 |
| Duration | 4.0 s |
| Sampling | 20 us |
| SNR | 30 dB |
| Reference phase error | 0 deg |
| Cs drift | 0.80–2.20 s |
| Cs1 truth | `10 + 3 smoothstep(0.80,2.20)` pF |
| Cs2 truth | `10 - 2 smoothstep(0.80,2.20)` pF |
| Fault factor | 1.30 |
| Fault onset | 1.50 s |
| Ramp-up | 1.50–1.56 s |
| Plateau | 1.56–1.90 s |
| Ramp-down | 1.90–1.96 s |
| Fault clear | 1.96 s |

冻结窗口均采用 `[start,end)`：W0 `[1.20,1.45)`、W1 `[1.62,1.74)`、W2 `[1.74,1.88)`、W3 `[1.98,2.18)`、W4 `[2.40,2.80)` s。

- Specification: `step5_simultaneous_drift_fault/CASE07_SPECIFICATION.md`
- Specification SHA-256: `8D1A8154960A58BF3E853F471B1112E68EA8029370247B51FCCD5F40359A20B1`
- Configuration snapshot SHA-256: `E0391512C8EDD91751E75C9F8A2D554A72B19EAAD7D7DA07C53CAB66F1A075FF`
- Builder SHA-256: `EB76BEE6E7F271F9AD82AFDB9FF25D6EE46E6263C6ADE8D28D438F0B6F0A44F2`

## 3. Fairness and Counterfactual Design

Fault branch F 与 counterfactual branch CF 使用完全相同的：

- AutoComp9 model 与物理参数；
- Cs1/Cs2 truth；
- B 相参考重构；
- seed 105；
- Case06 seed-105 的同一组三相测量噪声样本；
- sampling、duration、初始化窗口和算法参数。

噪声由冻结 Case06 的 `30 dB` 与 `Inf dB` 两次运行之差重建，并原样输入 F/CF。两分支唯一不同输入是 `fault_scale`。

公平性检查：

| Check | Result |
|---|---:|
| Non-fault input max difference | 0 |
| Pre-fault 15 fields max sample difference | 0 |
| M2/M3/M4 pre-fault parameter-state difference | 0 |
| Fault schedule max branch difference | 0.30 |
| True Cs changes during overlap | PASS |
| Fault plateau active during W1/W2 | PASS |

因此 Case07 确实同时包含 Cs drift 和 resistive fault，且 matched counterfactual 有效。

## 4. Metrics

分别评价两个目标，不构造任何综合评分：

1. Fault branch 相对 true Cs 的 tracking error；
2. F-CF matched fault-induced parameter deviation；
3. matched B-phase fundamental fault increment retention；
4. M3 gate、M4 update weight、recovery 和 post-fault memory；
5. fault-induced bias 相对 true drift direction 的离线几何投影。

真实 drift direction 由 W0 末端到 W2 末端定义，对应未归一化变化量：

```text
[Delta true Cs1, Delta true Cs2] = [+1.2619, -0.8413] pF
```

## 5. No-Fault Drift Baseline

CF branch 证明 Case07 的 drift 本身不是异常工况。M2 与 M3 完全一致，M4 只有 Step 3 已见的轻微正常跟踪代价。

| Window | Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | RMS norm (pF) |
|---|---|---:|---:|---:|
| W1 | M2 | 0.1796 | 0.1025 | 0.2067 |
| W1 | M3 | 0.1796 | 0.1025 | 0.2067 |
| W1 | M4 | 0.1815 | 0.1042 | 0.2093 |
| W2 | M2 | 0.1935 | 0.1335 | 0.2351 |
| W2 | M3 | 0.1935 | 0.1335 | 0.2351 |
| W2 | M4 | 0.1937 | 0.1344 | 0.2358 |

## 6. Overlap Parameter Tracking

Fault branch 的正式 overlap tracking 结果为：

| Window | Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | RMS norm (pF) |
|---|---|---:|---:|---:|
| W1 | M2 | 2.2995 | 2.3404 | 3.2810 |
| W1 | M3 | 2.2995 | 2.3404 | 3.2810 |
| W1 | M4 | 1.8970 | 1.9852 | 2.7459 |
| W2 | M2 | 2.2880 | 2.3290 | 3.2648 |
| W2 | M3 | 2.2880 | 2.3290 | 3.2648 |
| W2 | M4 | 2.1711 | 2.2292 | 3.1117 |

W1+W2 合并 RMS norm：M2 = M3 = 3.2723 pF，M4 = 2.9485 pF。M4 数值较低，但不能直接解释为真实 drift tracking 更好，因为 matched fault bias 与 drift 高度同向。

## 7. Fault-Induced Parameter Deviation

定义 `delta c_fault = c_F-c_CF`。表中 Delta Cs 为窗口均值，同时给出向量 RMS norm。

| Window | Algorithm | Mean Delta Cs1 (pF) | Mean Delta Cs2 (pF) | RMS norm (pF) | Cosine with drift |
|---|---|---:|---:|---:|---:|
| W1 | M2 | +2.4770 | -2.4322 | 3.4718 | 0.9823 |
| W1 | M3 | +2.4770 | -2.4322 | 3.4718 | 0.9823 |
| W1 | M4 | +2.0679 | -2.0693 | 2.9359 | 0.9805 |
| W2 | M2 | +2.4700 | -2.4564 | 3.4835 | 0.9811 |
| W2 | M3 | +2.4700 | -2.4564 | 3.4835 | 0.9811 |
| W2 | M4 | +2.3542 | -2.3578 | 3.3320 | 0.9804 |

合并 W1+W2 的 fault-induced RMS norm：M2 = M3 = 3.4781 pF，M4 = 3.1554 pF。M4 相对 M2 少约 0.3227 pF（9.3%），但仍保留了大部分 fault absorption。

## 8. Fault Increment Preservation

matched differential metric 使用每个窗口内冻结的基波 RMS 提取：

| Window | Algorithm | True increment (A) | Estimated increment (A) | Retention ratio | Error |
|---|---|---:|---:|---:|---:|
| W1 | M2 | 2.5330e-4 | 1.6848e-4 | 0.6651 | -33.49% |
| W1 | M3 | 2.5330e-4 | 1.6848e-4 | 0.6651 | -33.49% |
| W1 | M4 | 2.5330e-4 | 1.8182e-4 | 0.7178 | -28.22% |
| W2 | M2 | 2.5330e-4 | 1.6818e-4 | 0.6640 | -33.60% |
| W2 | M3 | 2.5330e-4 | 1.6818e-4 | 0.6640 | -33.60% |
| W2 | M4 | 2.5330e-4 | 1.7189e-4 | 0.6786 | -32.14% |

M4 的平均绝对 retention-ratio error 为 0.3018，M2/M3 为 0.3355。改善存在，但故障增量仍有约 28%–32% 被丢失。

## 9. M2 Mechanism

M2 全更新，在 W1/W2 产生约 `[+2.47,-2.44] pF` 的 matched fault-induced bias。其 overlap Cs error 很大；由于 bias cosine 约 0.982，与 true drift 同向，不能将参数曲线靠近某些 drift 方向的现象解释为正确识别真实漂移。

## 10. M3 Hard-Freeze Mechanism

本工况最重要的意外结果是：

```text
M3 gate onset = NaN
M3 W1 active ratio = 0
M3 W2 active ratio = 0
M3 overlap active ratio = 0
```

因此 factor 1.30 的临时故障没有触发冻结，M3 在本步骤等同 M2。不存在实际 hard-gate active interval，所以：

- `true Cs change while gate active` 为 N/A，而不是 0；
- `M3 release latency` 为 N/A；
- 本步骤不能检验“hard freeze 期间失去 drift tracking”的预期机制。

## 11. M4 Continuous-Update Mechanism

| Window | Mean g | Median g | Min g | Mean USR |
|---|---:|---:|---:|---:|
| W0 | 0.9927 | 1.0000 | 0.9680 | 0.0073 |
| W1 | 0.5402 | 0.5419 | 0.5229 | 0.4598 |
| W2 | 0.5501 | 0.5528 | 0.5330 | 0.4499 |
| W3 | 0.9963 | 1.0000 | 0.9720 | 0.0037 |

W1+W2 overlap mean g = 0.5455，说明 M4 保留约 54.6% 的信息更新；material response onset = 1.53998 s，latency = 39.98 ms。该连续权重使 fault-induced bias 比 M2 小约 9.3%，但仍不足以阻止大量 fault absorption。

CF baseline 中 M4 的 overlap tracking norm（0.22395 pF）与 M2/M3（0.22246 pF）基本相同；在 F branch 中得到的较低误差主要与较小的 fault-induced bias共同出现，不能证明保留的更新在 overlap 中被明确用于追踪 true drift。

## 12. Post-Fault Recovery and Memory

| Algorithm | W3 mean memory (pF) | W3 end (pF) | W4 mean (pF) | W4 end (pF) | AUC (pF s) |
|---|---:|---:|---:|---:|---:|
| M2 | 0.3838 | 0.1293 | 0.00633 | 0.00149 | 0.12178 |
| M3 | 0.3838 | 0.1293 | 0.00633 | 0.00149 | 0.12178 |
| M4 | 0.3677 | 0.1275 | 0.00622 | 0.00153 | 0.11742 |

按 W3 mean 和 AUC，M2/M3 的 post-fault memory 最大；M4 略小。W4 endpoint 均已接近零，M4 的 0.00153 pF 虽略高于 M2/M3 的 0.00149 pF，但差异可忽略。

M4 在 1.97998 s 首次连续两个周期回到 W0 robust suppression band，recovery latency = 19.98 ms。

## 13. Geometric Confounding Analysis

W1/W2 的 fault-induced bias 与 true drift direction cosine 均约为 0.98：

- M2/M3 combined cosine = 0.98168；
- M4 combined cosine = 0.98047。

这正是 Step 5 预先警告的几何混淆。所有 Fault branch tracking error 都远大于各自 CF baseline，因此 fault 并未让任何算法绝对优于无故障状态；但 M4 相对 M2/M3 的较低 Fault-branch RMSE 仍不能独立证明 true-drift tracking，因为比较同时受高度同向的 fault bias 大小影响。

## 14. Direction Diagnostics

M4 diagnostic-only `cos_local_fault` median：

| Window | Median | Mean absolute |
|---|---:|---:|
| W0 drift only | 0.9152 | 0.8902 |
| W1 overlap | 0.9963 | 0.9902 |
| W2 overlap | 0.9572 | 0.8538 |
| W3 drift only | 0.8821 | 0.7567 |

W1 有增强，但 W0/W3 drift-only 也很高，且 Step 3/4 已显示分布重叠。本步骤不支持“direction alone separates fault and drift”。方向量未反馈控制。

## 15. Two-Objective Trade-Off

二维比较结果：

| Algorithm | Overlap tracking RMS norm (pF) | Mean abs retention error |
|---|---:|---:|
| M2 | 3.2723 | 0.3355 |
| M3 | 3.2723 | 0.3355 |
| M4 | 2.9485 | 0.3018 |

纯数值上，M4 同时低于 M2 retention error 和 M3 tracking error。但不能判为 `TRADEOFF_DEMONSTRATED`，原因有二：

1. M3 未触发 hard freeze，未形成预期的“保护强但 drift tracking 差”对照；
2. fault bias 与 drift 高度同向，存在显著几何混淆。

因此正式评估为：

```text
M4 OVERLAP TRADEOFF ASSESSMENT:
MIXED
```

## 16. Limitations

- 只有一个预注册代表工况，不代表更广 fault amplitude robustness；
- factor 1.30 未触发 M3 gate，使 hard-freeze 对照缺失；
- M4 标量权重仍允许大量故障信息进入状态；
- true drift 与 fault bias 高度共线，不能仅用 Cs RMSE 解释机制；
- 未执行可选 protection-only replay，因为当前核心结论已由 matched CF、gate schedule 和几何投影直接确定。

## 17. Regression Protection

| Check | Result |
|---|---:|
| Step 5 source checkcode | 0 issues |
| Frozen specification hashes | PASS |
| Phase 1A formal validator | 19/19 PASS |
| Historical regression | 11/11 PASS |
| Protected files | 209/209 unchanged |
| F/CF pre-fault sample identity | exact, max difference 0 |
| Rate-limit active cycles | M2 0, M3 0, M4 0 |
| Projection active cycles | M2 0, M3 0, M4 0 |
| PNG/FIG | 8/8 |

差异来自更新机制，不是 rate limit 或 projection。

## 18. Required Questions

**Q1. Case07 是否真正满足 Cs drift 与 resistive fault 时间重叠？**  满足；1.50–1.96 s fault 期间 true Cs 持续变化，W1/W2 均处于 plateau 与 drift 重叠区。

**Q2. CF 是否除 fault 外完全相同？**  是；non-fault input 与 pre-fault sample 最大差均为 0。

**Q3. M2 overlap Cs1/Cs2 RMSE？**  W1 = 2.2995/2.3404 pF；W2 = 2.2880/2.3290 pF。

**Q4. M3 overlap Cs1/Cs2 RMSE？**  与 M2 相同：W1 = 2.2995/2.3404 pF；W2 = 2.2880/2.3290 pF。

**Q5. M4 overlap Cs1/Cs2 RMSE？**  W1 = 1.8970/1.9852 pF；W2 = 2.1711/2.2292 pF。

**Q6. M3 gate 期间 true Cs 变化多少？**  M3 gate 未触发，故 active interval 不存在，结果为 N/A。

**Q7. M4 overlap mean g？**  0.5455；W1 = 0.5402，W2 = 0.5501。

**Q8. 保留 adaptation 是否转化为可测 true-Cs tracking？**  CF 证明 M4 具备正常 drift tracking；但 overlap 中较低 error 与较小且高度同向的 fault bias同时出现，不能把改善明确归因于 true-drift tracking。

**Q9. Matched fault-induced Delta Cs？**  见第 7 节；M2/M3 W1 约 `[+2.477,-2.432]` pF、W2 `[+2.470,-2.456]` pF；M4 W1 `[+2.068,-2.069]` pF、W2 `[+2.354,-2.358]` pF。

**Q10. Fault-increment retention ratio？**  M2/M3 W1/W2 = 0.6651/0.6640；M4 = 0.7178/0.6786。

**Q11. M4 是否比 M2 少吸收 fault？**  是，fault-induced RMS norm 低约 9.3%，retention ratio 也更高；但改善有限。

**Q12. M4 是否比 M3 保留更多真实 drift tracking？**  Fault-branch RMSE 数值更低，但 M3 未冻结且存在几何混淆，不能把该差异认定为已证明的真实 drift tracking 优势。

**Q13. 是否有同向 fault bias 造成假改善？**  有明显风险；cosine 约 0.98。虽然 F error 没有低于 CF error，但相对算法排序仍受同向 bias 大小影响。

**Q14. Fault bias vs drift cosine？**  M2/M3 W1/W2 = 0.9823/0.9811；M4 = 0.9805/0.9804。

**Q15. Fault clear 后谁的 parameter memory 最大？**  按 W3 mean/AUC，M2 与 M3 并列最大；M4 略低。W4 全部接近零。

**Q16. M3 release latency？**  N/A，因为 gate 从未触发。

**Q17. M4 g recovery latency？**  19.98 ms。

**Q18. M4 是否同时满足两个数值不等式？**  数值上满足，但科学上不能满足无混淆的 demonstrated 条件。

**Q19. 是否观察到真正 continuous-update trade-off？**  仅部分证据支持，正式结论 `MIXED`。

**Q20. M4-v0 是否值得进入 Step 6 ablation/freeze？**  可保留为后续 ablation baseline，但不建议直接 freeze 为论文最终方法；应先返回 M4 方法设计，解决弱 steady preservation、M3 低幅故障不触发以及 drift/fault 几何共线问题。

## 19. Artifacts and Reproducibility

主要输出：

- `step5_simultaneous_drift_fault/tables/actual_parameter_tracking.csv`
- `step5_simultaneous_drift_fault/tables/no_fault_drift_baseline.csv`
- `step5_simultaneous_drift_fault/tables/fault_induced_parameter_deviation.csv`
- `step5_simultaneous_drift_fault/tables/fault_increment_preservation.csv`
- `step5_simultaneous_drift_fault/tables/protection_behavior.csv`
- `step5_simultaneous_drift_fault/tables/m4_window_response.csv`
- `step5_simultaneous_drift_fault/tables/post_fault_memory.csv`
- `step5_simultaneous_drift_fault/tables/two_objective_tradeoff.csv`
- `step5_simultaneous_drift_fault/diagnostics/*.csv`
- `step5_simultaneous_drift_fault/workspace/case07_step5_workspace.mat`
- `step5_simultaneous_drift_fault/figures/Figure_A...Figure_H`（PNG + FIG）

正式命令：

```text
matlab -batch "... freeze_phase1c_case07_specification();"
matlab -batch "... run_phase1c_step5_simultaneous_drift_fault();"
matlab -batch "... reprocess_phase1c_step5_saved_workspace();"  # only saved-data diagnostics/figures
```

## 20. Step 5 Acceptance Conclusion

```text
STEP 5 EXECUTION STATUS:
PASS
```

Case specification 在结果前冻结；F/CF 公平且逐样本验证；指标、CSV、MAT、八组图和回归均完整；历史资产未改变。

```text
M4 OVERLAP TRADEOFF ASSESSMENT:
MIXED
```

Step 5 到此停止。未执行 Step 6。
