# Phase 1C Step 5B — Triggered Hard-Gate Overlap Confirmation

## 1. Why Step5B Was Required

Step 5 Case07 的 fault factor 为 1.30，M3 hard gate 未触发，M3 在 overlap 中与 M2 完全相同。因此 Case07 没有形成预期的：

```text
M3 hard freeze
vs
M4 continuous adaptation
```

Step 5B 只补充一个确认性 Case08，不做 fault-factor sweep、不调 M3/M4 参数，也不修改算法。

## 2. Frozen Case08 Specification

Case08 直接继承冻结的 Case07 definition，唯一物理变量变化是：

```text
fault factor: 1.30 -> 1.60
```

其余 model、seed、duration、sampling、SNR、reference、noise replay、Cs truth、fault timing 和 W0–W4 窗口全部不变。

| Item | Frozen value |
|---|---:|
| Case | `Case08_overlap_drift_fault_f160` |
| Model | `AI6109_MOA_AutoComp9` |
| Seed | 105 |
| Duration | 4.0 s |
| Sampling | 20 us |
| SNR | 30 dB |
| Cs drift | 0.80–2.20 s |
| Cs1 truth | `10 + 3*smoothstep(0.80,2.20)` pF |
| Cs2 truth | `10 - 2*smoothstep(0.80,2.20)` pF |
| Fault factor | 1.60 |
| Fault interval | 1.50–1.96 s |
| W1 / W2 | `[1.62,1.74)` / `[1.74,1.88)` s |

冻结发生在任何 M2/M3/M4 运行之前：

| Artifact | SHA-256 |
|---|---|
| Case07 source specification | `8D1A8154960A58BF3E853F471B1112E68EA8029370247B51FCCD5F40359A20B1` |
| Case08 specification | `F18DCF91BA8AFCC11FF9D382D85B91138EEC90296EF785B6C1412181B26F8580` |
| Case08 configuration snapshot | `693C0A3DF790CC38C58D581B274F954B26D23DFB2EAD6BC957E286A169E57EB4` |
| Case08 builder | `086C6C346A5988FE35384C2734B00BF233907B825F5F8E55C6731325BBF38BA1` |

正式冻结文件为 `step5b_triggered_overlap/CASE08_SPECIFICATION.md` 和 `CASE08_SPECIFICATION.sha256`。

## 3. Fairness

F 与 CF 使用相同 drift、noise、reference、seed、sampling、initialization 和算法参数，唯一不同输入是 fault scale。

| Check | Result |
|---|---:|
| Non-fault input max difference | 0 |
| Pre-fault 15 fields max sample difference | 0 |
| M2/M3/M4 pre-fault state difference | 0 |
| Fault schedule max branch difference | 0.60 |
| True Cs changes during overlap | PASS |
| Fault plateau active during W1/W2 | PASS |

因此 Case08 是有效 matched F/CF 对照。

## 4. M3 Gate Trigger Verification

M3 hard gate 成功触发：

| Metric | Value |
|---|---:|
| Gate onset | 1.55998 s |
| Onset latency | 59.98 ms |
| W1 active ratio | 1.0000 |
| W2 active ratio | 1.0000 |
| W1+W2 active ratio | 1.0000 |
| Last active cycle | 2.39998 s |
| First released cycle | 2.41998 s |
| Release latency after fault clear | 459.98 ms |

连续 active interval 为 `[1.55998,2.39998]` s。由于 gate hold，冻结持续到 fault clear 后，并超过 2.20 s 的 drift end。

## 5. Counterfactual Drift Baseline

CF branch 中 M2/M3 正常跟踪相同，M4 只保留 Step 3 已观察到的轻微正常代价：

| Window | Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | RMS norm (pF) |
|---|---|---:|---:|---:|
| W1 | M2/M3 | 0.1796 | 0.1025 | 0.2067 |
| W1 | M4 | 0.1815 | 0.1042 | 0.2093 |
| W2 | M2/M3 | 0.1935 | 0.1335 | 0.2351 |
| W2 | M4 | 0.1937 | 0.1344 | 0.2358 |

这证明无 fault 时的 drift tracking 路径正常。Fault-branch Cs RMSE 不能作为纯 drift 指标，因为 fault-induced bias 与 drift 高度同向。

## 6. Hard-Gate-Interval Drift Tracking

在同一 M3 continuous gate-active interval 内，真实变化为：

```text
Delta true Cs = [+1.30768, -0.87179] pF
```

| Algorithm | F Delta Cs1 (pF) | F Delta Cs2 (pF) | DCR1 | DCR2 | F movement norm (pF) |
|---|---:|---:|---:|---:|---:|
| M2 | -0.68559 | +1.24296 | 0.5243 | 1.4258 | 1.41950 |
| M3 | 0 | 0 | 0 | 0 | 0 |
| M4 | +0.47752 | +0.04515 | 0.3652 | 0.0518 | 0.47965 |

M3 的实际参数完全冻结，DCR 为 0。M4 保留了可测的非零运动；Cs1 与真实 drift 同向，但 Cs2 的 Fault-branch 净运动为正，与真实变化的负方向相反。因此 DCR 只用于描述幅值，不能单独证明纯净 drift tracking。

W1/W2 Fault-branch tracking RMSE 如下：

| Window | Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | RMS norm (pF) |
|---|---|---:|---:|---:|
| W1 | M2 | 4.7031 | 4.7465 | 6.6819 |
| W1 | M3 | 0.3481 | 0.6317 | 0.7213 |
| W1 | M4 | 3.0369 | 3.1658 | 4.3869 |
| W2 | M2 | 4.7369 | 4.7754 | 6.7263 |
| W2 | M3 | 0.1088 | 0.3917 | 0.4066 |
| W2 | M4 | 4.0558 | 4.1560 | 5.8070 |

这些 Fault-branch RMSE 混合了 drift、fault absorption 和冻结效应，不作为纯 drift 排名。

## 7. Matched Fault-Induced Bias

定义 `delta c_fault = c_F-c_CF`。窗口均值与 RMS norm：

| Window | Algorithm | Mean Delta Cs1 (pF) | Mean Delta Cs2 (pF) | RMS norm (pF) | Cosine with drift |
|---|---|---:|---:|---:|---:|
| W1 | M2 | +4.8802 | -4.8380 | 6.8728 | 0.9814 |
| W1 | M3 | +0.5101 | -0.7212 | 0.8970 | 0.9333 |
| W1 | M4 | +3.1872 | -3.2303 | 4.5747 | 0.9792 |
| W2 | M2 | +4.9194 | -4.9030 | 6.9455 | 0.9809 |
| W2 | M3 | +0.1517 | -0.5133 | 0.5417 | 0.7678 |
| W2 | M4 | +4.2358 | -4.2810 | 6.0296 | 0.9795 |

Case08 合并 W1/W2 后，M4 fault-bias RMS norm 相对 M2 降低 21.77%。但 M4 仍吸收了大量 fault，且 cosine 约 0.979，几何混淆仍强。M3 hard gate 的 bias 明显最小。

## 8. Fault Increment Retention

严格使用 Step 5 matched differential 定义：

| Window | Algorithm | True increment (A) | Estimated increment (A) | Retention ratio | Error |
|---|---|---:|---:|---:|---:|
| W1 | M2 | 5.0661e-4 | 3.3869e-4 | 0.6685 | -33.15% |
| W1 | M3 | 5.0661e-4 | 4.8535e-4 | 0.9580 | -4.20% |
| W1 | M4 | 5.0661e-4 | 3.9572e-4 | 0.7811 | -21.89% |
| W2 | M2 | 5.0661e-4 | 3.3689e-4 | 0.6650 | -33.50% |
| W2 | M3 | 5.0661e-4 | 4.9517e-4 | 0.9774 | -2.26% |
| W2 | M4 | 5.0661e-4 | 3.5945e-4 | 0.7095 | -29.05% |

M4 在 W1/W2 均优于 M2，但 M3 明显强于 M4。平均绝对 retention error：M2 = 0.33324，M3 = 0.03226，M4 = 0.25468。

## 9. M4 Continuous Adaptation Analysis

M4 在 W1/W2 的 update weight 为：

| Window | Mean g | Median g | Min g |
|---|---:|---:|---:|
| W1 | 0.3553 | 0.3553 | 0.3476 |
| W2 | 0.3641 | 0.3652 | 0.3569 |
| W1+W2 | 0.3600 | — | — |

在完整 M3 gate-active interval `[1.55998,2.39998]` 内，M4 mean/median/min g 分别为 0.69758 / 0.94983 / 0.34072。均值较高是因为该 interval 包含 fault clear 后到 M3 延迟释放前的 0.44 s，此时 M4 已恢复接近全更新。

M4 protection material onset 为 1.51998 s；fault clear 后在 1.99998 s 恢复到 pre-fault suppression band，recovery latency 为 39.98 ms。

## 10. Drift-Associated vs Fault-Induced Movement

在相同 M3 gate-active interval 内，对 M4 有精确离线分解：

```text
Delta c_F  = [+0.47752, +0.04515] pF
Delta c_CF = [+1.39663, -0.88963] pF
Delta c_fault = Delta c_F - Delta c_CF
              = [-0.91910, +0.93479] pF
```

| Quantity | Norm (pF) |
|---|---:|
| M4 Fault-branch net movement | 0.47965 |
| M4 CF drift-associated movement | 1.65590 |
| M4 fault-induced movement | 1.31094 |

`P_drift = ||Delta c_CF|| / ||Delta c_F|| = 3.4523`。该量不是 0–1 purity fraction；大于 1 表示 drift-associated 与 fault-induced 向量发生强抵消。按预注册范数判据，CF drift-associated movement 大于 fault-induced movement，因此 M4 的运动不以 fault absorption 为主；但两者量级接近，且 Cs2 净方向被反转，故连续 adaptation 仍明显受 fault 污染。

未执行 optional protection-schedule replay：冻结的 M3/M4 core API 不接受逐周期外部 schedule；为遵守“不得修改 core tracker”，本步骤保留 mandatory matched F/CF 主分析，不复制或改写核心更新器。

## 11. Post-Fault Recovery

| Algorithm | W3 mean memory (pF) | W3 endpoint (pF) | W4 mean (pF) | W4 endpoint (pF) | AUC (pF s) |
|---|---:|---:|---:|---:|---:|
| M2 | 0.5859 | 0.1607 | 0.00773 | 0.00179 | 0.19231 |
| M3 | 0.4402 | 0.5572 | 0.07589 | 0.00997 | 0.25917 |
| M4 | 0.4895 | 0.1490 | 0.00737 | 0.00177 | 0.16372 |

M3 的长 gate hold 造成最大 post-fault AUC 和 W4 memory。M4 在 fault clear 后恢复最快，AUC 最小；M2 次之。

## 12. Case07 vs Case08

| Metric | Case07 factor 1.30 | Case08 factor 1.60 |
|---|---:|---:|
| M3 gate triggered | no | yes |
| M3 overlap active ratio | 0 | 1.0000 |
| M4 overlap mean g | 0.5455 | 0.3600 |
| M4 fault-bias reduction vs M2 | 9.28% | 21.77% |
| M2 mean retention | 0.6645 | 0.6668 |
| M3 mean retention | 0.6645 | 0.9677 |
| M4 mean retention | 0.6982 | 0.7453 |

fault severity 增强后，M2 retention 基本不变；M3 从不触发转为全 overlap hard freeze，fault preservation 大幅提高；M4 自动降低 g，fault preservation 改善，但仍弱于 hard gate。

## 13. Two-Objective Tradeoff

预注册必要条件：

| Criterion | Result | Evidence |
|---|---:|---|
| A. M4 retention better than M2 | PASS | mean error 0.25468 < 0.33324 |
| B. M4 gate-interval movement greater than M3 | PASS | 0.47965 pF > 0 |
| C. M4 movement not mainly fault-induced | PASS | CF drift norm 1.65590 > fault-induced norm 1.31094 pF |

因此按结果前冻结的判据：

```text
M4 TRIGGERED-OVERLAP TRADEOFF:
DEMONSTRATED
```

该结论是“相对 M2 提升 fault retention，同时相对 M3 保留非零、且范数上主要与 true drift response 一致的 adaptation”。它不代表 M4 达到 M3 的 fault preservation，也不代表 M4 参数运动纯净无污染。

## 14. Limitations

- 只有一个预注册确认性 Case08，不代表 amplitude trend 或完整 robustness；
- M3 gate hold 延续到 drift end 之后，gate interval 同时包含 fault、post-fault drift 和 post-drift 段；
- M4 fault-induced movement 仍达 1.3109 pF，与 1.6559 pF 的 CF drift movement 同量级；
- M4 Cs2 Fault-branch 净运动方向错误，说明抵消显著；
- fault bias 与 true drift 在 W1/W2 仍高度共线；
- 未做 protection-schedule replay、Monte Carlo、M4 tuning 或 Step 6 ablation。

## 15. Regression Protection

| Check | Result |
|---|---:|
| Step 5B source checkcode | 0 issues |
| Frozen Case08 hashes | PASS |
| Formal validator | 19/19 PASS |
| Historical regression | 11/11 PASS |
| Protected files | 252/252 unchanged during formal run |
| M0/M2/M3 frozen outputs | unchanged |
| Phase 1A/B assets | unchanged |
| Step 1–5 protected assets | unchanged |
| Rate-limit active cycles M2/M3/M4 | 0 / 0 / 0 |
| Projection active cycles M2/M3/M4 | 0 / 0 / 0 |
| Figures | 8 PNG + 8 FIG |

AutoComp9 的既有未连接测量端口和代数环警告仍存在，但未产生 simulation error，也未改变本步骤的回归结论。

## 16. Step5B Conclusion

1. **Q1 — Case08 是否只修改 fault factor？** 是；definition 直接继承 Case07，只覆盖 1.30→1.60。
2. **Q2 — 是否在结果前冻结？** 是；spec/config/builder 哈希均在算法运行前生成。
3. **Q3 — M3 是否触发？** 是。
4. **Q4 — onset/latency？** 1.55998 s / 59.98 ms。
5. **Q5 — W1/W2 active ratio？** 1.0000 / 1.0000。
6. **Q6 — gate-active true Cs change？** `[+1.30768,-0.87179]` pF。
7. **Q7 — M3 参数实际变化？** `[0,0]` pF，DCR1=DCR2=0。
8. **Q8 — 同区间 M4 mean g？** 0.69758；median 0.94983，min 0.34072。W1/W2 combined mean g 为 0.36004。
9. **Q9 — M4 参数实际变化？** `[+0.47752,+0.04515]` pF，norm 0.47965 pF。
10. **Q10 — true-drift-associated 与 fault-induced 各多少？** CF response norm 1.65590 pF；fault-induced norm 1.31094 pF；二者强抵消。
11. **Q11 — W1/W2 retention？** M2 0.6685/0.6650；M3 0.9580/0.9774；M4 0.7811/0.7095。
12. **Q12 — matched fault-induced Delta Cs？** W1/W2：M2 `[+4.880,-4.838]` / `[+4.919,-4.903]` pF；M3 `[+0.510,-0.721]` / `[+0.152,-0.513]` pF；M4 `[+3.187,-3.230]` / `[+4.236,-4.281]` pF。
13. **Q13 — M4 fault preservation 是否优于 M2？** 是；两窗口 retention 均更高，合并 fault-bias norm 低 21.77%。
14. **Q14 — M3 是否明显强于 M4？** 是；M3 retention 接近 1，matched bias 远小于 M4。
15. **Q15 — M4 是否比 M3 保留更多可归因于 true drift 的 adaptation？** 是；M3 实际 movement 为 0，M4 为 0.47965 pF，且 CF drift component 范数大于 fault component；但 Cs2 净方向错误。
16. **Q16 — M4 运动是否主要由 fault absorption 驱动？** 按冻结的范数判据不是；1.31094 < 1.65590 pF。但 fault component 同量级，污染仍显著。
17. **Q17 — fault bias vs drift cosine？** M2 W1/W2 = 0.9814/0.9809；M3 = 0.9333/0.7678；M4 = 0.9792/0.9795。
18. **Q18 — 是否形成公平 hard-freeze vs continuous-adaptation 对照？** 是；M3 在 W1/W2 全冻结，M4 g 始终非零，F/CF 前置一致性为零差。
19. **Q19 — 最终 tradeoff？** `DEMONSTRATED`，同时保留上述污染与方向限制。
20. **Q20 — 是否允许进入 Step 6？** 允许；Step 6 应继续做 ablation/freeze，并把 Case08 的强 fault contamination 作为必须保留的负面证据。

```text
STEP 5B EXECUTION STATUS:
PASS
```

```text
M4 TRIGGERED-OVERLAP TRADEOFF:
DEMONSTRATED
```

```text
RECOMMENDATION FOR STEP 6:
PROCEED
```

本步骤到此停止，未自动执行 Step 6。
