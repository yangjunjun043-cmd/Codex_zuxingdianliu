# Phase 2 Step 1C — Registry Validation Report

## 1. Outcome

Step 1C converted the accepted Step 1A/1B specifications into a frozen draft registry without running simulations. All required structural, timing, seed, duplicate and budget checks passed.

## 2. Registry validation summary

| Check | Result |
|---|---|
| Frozen manifest | 9/9 SHA-256 match |
| Deterministic physical conditions | 54 |
| Monte-Carlo physical conditions | 150 |
| Physical registry total | 204 rows |
| Algorithm-evaluation registry | 816 rows |
| Physical/evaluation/replay/sensitivity IDs | all unique |
| Blank CSV cells | 0 |
| Deterministic duplicate physical signatures | 0 groups |
| truth/noise seeds | 300/300 mutually unique |
| Rate timing validation | 0.5x/1x/2x PASS |
| Step 1B budget reconciliation | PASS |

## 3. Algorithm-evaluation classification

| Status | Deterministic | MC | Total |
|---|---:|---:|---:|
| `EXACT_REUSE` | 30 | 0 | 30 |
| `PARTIAL_REUSE` | 20 | 0 | 20 |
| `RECOMPUTE_METRICS_ONLY` | 0 | 0 | 0 |
| `NEW_RUN_REQUIRED` | 166 | 600 | 766 |
| `BLOCKED` | 0 | 0 | 0 |
| **Total** | **216** | **600** | **816** |

Pending feature gates are kept separate from `BLOCKED`: 10 deterministic and 121 MC physical conditions are `PENDING_GATE`; none has failed a gate.

## 4. Required final answers

1. **Frozen source hash 是否全部一致？** 是，freeze manifest 9/9 匹配。
2. **实际 deterministic physical condition 数量？** 54。
3. **是否等于 Step 1B 预期 54？** 是。
4. **Algorithm-evaluation row 数量？** 816 total：216 deterministic + 600 MC。
5. **EXACT_REUSE 数量？** 30。
6. **PARTIAL_REUSE 数量？** 20。
7. **RECOMPUTE_METRICS_ONLY 数量？** 0；现有 Step4 summary/cycle 文件不足以安全重算全部 Phase 2 metrics。
8. **NEW_RUN_REQUIRED 数量？** 766：166 deterministic + 600 MC。
9. **BLOCKED 数量？** 0。另有 131 physical conditions 为 `PENDING_GATE`，不是 blocked。
10. **0.5x / 1x / 2x timing 是否均通过？** 是，全部通过八项 timing/window arithmetic checks。
11. **1x 是否精确恢复 Case07/08？** 是：drift `[0.80,2.20)`、fault `[1.50,1.96)`、W0–W4 均精确恢复。
12. **2x 是否仍有真实 simultaneous overlap？** 是，fault+drift `[1.15,1.50)`；simultaneous plateau `[1.21,1.50)`。
13. **哪些窗口为 N/A_BY_DESIGN？** 所有 2x overlap 条件的 `W3_ACTIVE_DRIFT`，因为 fault end 1.61 s 晚于 drift end 1.50 s。
14. **Cself mismatch 是否仍受 interface gate？** 是。所有非零 deterministic Cself 条件以及抽到非零 mismatch 的 MC 条件均受 `CSELF_SPLIT_INTERFACE_GATE` 限制。
15. **CsAC 是否仍受 zero-injection gate？** 是。四个非零 CsAC 条件为 `PENDING_GATE`，未实现 wrapper。
16. **Negative-sequence convention 是否仍 unresolved？** 是，保持 `UNRESOLVED_INTERNAL_CONVENTION`，非零条件仅标记 `CONFIGURED_VALIDITY_BOUNDARY_ONLY`。
17. **MC 是否冻结为 150 conditions？** 是，H/F/O 各 50。
18. **Pilot 是否严格是其中前 60 条（20/cohort）？** 是，每 cohort indices 001–020，共 60；不是额外样本。
19. **是否有 unresolved-bound variable 被排除出 MC？** 是：fault onset、Cs initial value、drift amplitude；均使用 frozen nominal value，未创造 bounds。
20. **MC master seed 如何产生？** 对三个指定 Step 1B artifacts 的 uppercase SHA-256 以 LF 连接后再做 SHA-256，取 combined digest 前 32 bits；结果 `0x88854243 = 2290434627`，未尝试其他 seed。
21. **是否存在 duplicate condition？** 不存在。54 个 deterministic physical signatures 无重复；nominal aliases 均在 audit 中指向 anchor 而不生成新行。
22. **实际预算与 Step 1B 是否一致？** 是：54 deterministic/216 evaluations；150 MC/600 evaluations；10 incremental sensitivity；4 incremental replay；grand total 830 evaluations/trajectories。
23. **是否运行任何 Simulink？** 否。
24. **是否修改 frozen source？** 否。

## 5. Files and execution boundary

Step 1A/1B files were retained. Step 1C produced only the eleven requested draft/specification artifacts. It did not implement Cself/CsAC/replay interfaces, did not run MATLAB/Simulink/MC, and did not start Step 1D or Step 2.

```text
STEP 1C STATUS:
COMPLETE

NEW PHASE2 SIMULATION:
NO

FROZEN SOURCE MODIFIED:
NO

STEP 1D STARTED:
NO
```

