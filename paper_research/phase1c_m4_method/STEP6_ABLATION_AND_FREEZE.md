# Phase 1C Step 6 — Ablation, Method Freeze and Final Decision

## 1. Scope and Execution Status

Step 6 executed only the pre-registered minimal ablation on Case02, Case05, Case07, and Case08. No M4 formula, threshold, inherited parameter, M2/M3 implementation, case definition, evaluation window, model, or previous output was modified. No parameter optimization, Monte-Carlo, robustness sweep, Phase 2 experiment, hardware experiment, or new Case09 was performed.

```text
STEP6 EXECUTION:
PASS
```

The first attempted batch stopped before analysis because the default configuration selected AutoComp8; the Step 6 runner was corrected to explicitly select the frozen AutoComp9 model. A later draft evaluation was discarded because its Case05 counterfactual removed A/C components in addition to the frozen B-phase definition and its lag endpoint convention differed from Step 3. The final batch reproduced the exact Step 3/4 definitions. Only the final batch reported below is formal.

## 2. Ablation Variants

| Variant | Definition | Role |
|---|---|---|
| M2 | Frozen full VFF-RLS adaptation | No-protection reference |
| M3 | Frozen hard fault gate | Binary-freeze reference |
| A_FULL | Frozen M4-v0 | Final freeze candidate |
| A_NO_WEIGHT | `g = 1` | Continuous-weight contribution reference |
| A_BACKGROUND_ONLY | `p_q = 1`, `g=1/(1+e_b)` | Phase-consistency ablation |
| A_FIXED_LAMBDA | `lambda = lambda_max = 0.995` | VFF ablation |

`A_NO_WEIGHT` matched M2 exactly in all seven evaluated streams: Case02, Case05 F/CF, Case07 F/CF, and Case08 F/CF. Maximum parameter and B-current differences were both zero for every stream.

Direction control ablation is **NOT APPLICABLE**: direction quantities are diagnostic-only and never enter M4's control law. No c-only weighting variant was implemented because it is state-inconsistent and would test a known hidden-absorption error rather than a defensible component.

## 3. Case02 — Normal Tracking Anchor

| Variant | Cs1 RMSE (pF) | Cs2 RMSE (pF) | B error (%) | mean g | USR | lag Cs1/Cs2 (s) |
|---|---:|---:|---:|---:|---:|---:|
| M2 | 0.157320 | 0.108514 | 0.354786 | 1.000000 | 0 | 0.12 / 0.04 |
| M3 | 0.157320 | 0.108514 | 0.354786 | 1.000000 | 0 | 0.12 / 0.04 |
| A_FULL | 0.160864 | 0.110566 | 0.364798 | 0.975012 | 0.024988 | 0.12 / 0.06 |
| A_BACKGROUND_ONLY | 0.160864 | 0.110566 | 0.364798 | 0.975012 | 0.024988 | 0.12 / 0.06 |
| A_FIXED_LAMBDA | 1.454070 | 1.070934 | 4.475509 | 0.973844 | 0.026156 | 1.02 / 1.00 |

A_FULL preserves normal tracking with a small cost: Cs1/Cs2 RMSE rise by about 2.25%/1.89%, B error changes by +0.0100 percentage point, and Cs2 midpoint lag increases by one cycle. Its 2.50% unnecessary suppression is real and is retained as a limitation. Removing VFF is not acceptable for normal tracking: RMSE rises by roughly nine to ten times and lag approaches one second.

## 4. Case05 — Pure Fault Anchor

True fault factor is 1.600000.

| Variant | Estimated factor | Retention error (%) | Fault-induced ΔCs1/ΔCs2 (pF) | PAR norm | fault mean g | latency (s) | ISR J/h |
|---|---:|---:|---:|---:|---:|---:|---:|
| M2 | 1.401075 | -12.432825 | +4.886379 / -4.885713 | 1.000000 | 1.000000 | — | — |
| M3 | 1.581137 | -1.178930 | +0.427125 / -0.547006 | 0.100437 | 0 | — | — |
| A_FULL | 1.408580 | -11.963729 | +4.695238 / -4.710032 | 0.962463 | 0.360837 | 0.01998 | 0.638866 / 0.638877 |
| A_BACKGROUND_ONLY | 1.408580 | -11.963729 | +4.695238 / -4.710032 | 0.962463 | 0.360837 | 0.01998 | 0.638866 / 0.638877 |
| A_FIXED_LAMBDA | 1.582535 | -1.091548 | +0.505816 / -0.505956 | 0.103537 | 0.342959 | 0.01998 | 0.657035 / 0.657029 |

Continuous weighting has an independent but small pure-fault contribution: relative to M2, A_FULL reduces the fault-bias norm by 3.75% and improves retention error by 0.469 percentage point. It is not close to M3's hard-freeze preservation.

The apparent contrast between about 63.9% fault-window information suppression and only 3.75% steady fault-bias reduction is expected. ISR measures rejected *cycle increments*, while the nonzero repeated update still integrates fault-biased information and converges toward essentially the same biased fixed point. Existing information-state memory, the VFF time scale, and the nonlinear map from information state to `c` further prevent ISR from being interpreted as an equal percentage reduction in steady parameter bias.

The fixed-lambda result shows that VFF is not necessary for steady fault preservation; in this case it actively accelerates absorption. However, fixed lambda achieves preservation by extremely slow learning and fails normal tracking, so it is not a replacement method.

No rate limit or projection cycle occurred in any Case05 variant.

## 5. Case07 — Weak Overlap Anchor

M3 did not trigger and therefore exactly followed M2. A_FULL retained a continuous sub-threshold response:

| Variant | Mean bias RMS norm (pF) | Mean increment retention | overlap mean g | post-fault memory AUC (pF·s) |
|---|---:|---:|---:|---:|
| M2/M3 | 3.477660 | 0.664536 | 1.000000 | 0.121780 |
| A_FULL | 3.133961 | 0.698180 | 0.545523 | 0.117420 |
| A_BACKGROUND_ONLY | 3.133961 | 0.698180 | 0.545523 | 0.117420 |
| A_FIXED_LAMBDA | 0.311456 | 0.970379 | 0.526290 | 0.342040 |

A_FULL improves W1/W2 retention from 0.665120/0.663952 to 0.717784/0.678576, while maintaining nonzero adaptation. This supports the intended advantage over a binary threshold: a factor-1.30 fault receives protection even though M3 remains inactive. Fixed lambda again preserves the fault more strongly but has nearly three times A_FULL's post-fault memory and is already invalidated by Case02 normal tracking.

## 6. Case08 — Triggered Overlap Anchor

M3 was active for 100% of W1 and W2. Mean retention was M2 0.666764, M3 0.967739, A_FULL 0.745323, and A_FIXED_LAMBDA 0.980388. A_FULL's overlap mean `g` was 0.360041, so it preserved nonzero adaptation while improving retention relative to M2.

During the exact M3 gate interval, the true drift was approximately `[+1.307679, -0.871786] pF`. Direct movement decomposition was:

| Variant | F movement vector (pF) | ‖F‖ | CF drift vector (pF) | ‖CF‖ | Fault-induced vector (pF) | ‖fault‖ |
|---|---|---:|---|---:|---|---:|
| M2 | [-0.685593, +1.242958] | 1.419501 | [+1.394227, -0.889029] | 1.653555 | [-2.079820, +2.131988] | 2.978426 |
| M3 | [0, 0] | 0 | [+1.394227, -0.889029] | 1.653555 | [-1.394227, +0.889029] | 1.653555 |
| A_FULL | [+0.477525, +0.045154] | 0.479655 | [+1.396625, -0.889635] | 1.655902 | [-0.919101, +0.934788] | 1.310945 |
| A_FIXED_LAMBDA | [+1.429200, -1.081109] | 1.792040 | [+1.114177, -0.735003] | 1.334773 | [+0.315023, -0.346106] | 0.468005 |

The formal A_FULL tradeoff remains supported: fault preservation is better than M2, adaptation during the M3 freeze interval is nonzero, and its counterfactual drift movement (1.655902 pF) exceeds its fault-induced movement (1.310945 pF). This is a tradeoff, not separation. The two movements are the same order, they oppose strongly (cosine -0.9744), and A_FULL's net Cs2 movement is +0.045154 pF even though true Cs2 drift is negative. The former `P_drift=||Δc_CF||/||Δc_F||` quantity is therefore not a 0–1 purity fraction and is not used for the final conclusion.

Post-fault memory AUC is 0.19231/0.25917/0.16372 pF·s for M2/M3/A_FULL. Fixed lambda increases it to 0.46277 pF·s.

## 7. Component Contribution

| Component | Case02 normal | Case05 fault | Case07 weak overlap | Case08 triggered overlap | Contribution |
|---|---|---|---|---|---|
| Continuous weighting | LIMITED | SUPPORTED | SUPPORTED | SUPPORTED | **SUPPORTED** |
| Phase-consistency factor | NOT DEMONSTRATED | NOT DEMONSTRATED | NOT DEMONSTRATED | NOT DEMONSTRATED | **NOT DEMONSTRATED** |
| VFF | SUPPORTED | LIMITED | LIMITED | LIMITED | **SUPPORTED** |
| Hard-freeze comparison | NOT APPLICABLE | SUPPORTED | LIMITED | SUPPORTED | **SUPPORTED** |
| Direction diagnostic | NOT APPLICABLE | NOT DEMONSTRATED | NOT DEMONSTRATED | NOT DEMONSTRATED | **NOT DEMONSTRATED** |

Continuous weighting is supported because A_FULL consistently improves Case05/07/08 fault evidence over A_NO_WEIGHT/M2 and preserves nonzero overlap adaptation. Its Case02 cost is small but nonzero.

The phase-consistency factor's contribution is not demonstrated: A_FULL and A_BACKGROUND_ONLY are numerically identical in every reported metric for all four cases. This agrees with the observed `p_q≈1` saturation. The factor remains in `paper_method_v1`; deleting it would create a new formula requiring full revalidation.

VFF is supported for normal dynamic tracking and recovery, not for steady fault preservation. A_FIXED_LAMBDA sharply improves fault retention by making the estimator slow, but catastrophically degrades Case02 tracking and lengthens post-fault memory. In Phase 1C, VFF is the mechanism that prevents protection from collapsing into a near-frozen estimator.

## 8. Direction Evidence Decision

Direction evidence does not have sufficient fault specificity and does not enter final control. Case02 normal drift already has median local cosine 0.9045; Case05 fault-window median is 0.9095; Case07 W1 mean is 0.9902. Earlier matched-branch analysis also placed fault-induced bias nearly parallel to the true drift direction (about 0.98). These overlapping distributions cannot support a fault-specific direction discriminator.

```text
DIRECTION CONTROL ABLATION:
NOT APPLICABLE

DIRECTION EVIDENCE FAULT SPECIFICITY:
NO
```

## 9. M3 Hard Gate versus M4 Continuous Update

M3 obtains strong pure-fault preservation by holding the information and parameter states exactly constant after a threshold-triggered latency. The same mechanism loses all real drift during its Case08 gate, retains a longer post-fault hold memory, and fails completely to act at factor 1.30.

M4 instead scales the information-state and baseline-state increments continuously. It acts below M3's trigger threshold and keeps adapting during a triggered fault. The cost is weaker fault preservation and residual fault contamination because scalar weighting changes learning speed, not the fault-biased fixed point. Neither method is declared a universal winner.

## 10. Final Limitations

1. Steady fault preservation remains markedly weaker than M3.
2. Scalar continuous weighting mainly slows fault absorption; it cannot change the fault-biased fixed point completely.
3. In Case08, fault-induced movement and drift-associated movement are the same order.
4. Cs2 net movement in triggered overlap has the wrong sign despite true negative drift.
5. Direction evidence is not fault-specific.
6. M3 does not trigger at factor 1.30, demonstrating hard-threshold dependence.
7. M4 causes small unnecessary suppression in normal cases.
8. Evidence is limited to frozen representative single-seed cases; no Monte-Carlo or robustness conclusion is made.

In addition, the independent phase-consistency contribution was not demonstrated in the current cases, and fixed-lambda protection revealed an unavoidable tracking/memory tradeoff rather than a new candidate method.

## 11. Answers to the 12 Required Questions

**Q1. Does continuous weighting have an independent contribution?** Yes — **SUPPORTED**. A_NO_WEIGHT equals M2 exactly, while A_FULL improves Case05 bias/retention and both overlap cases and keeps nonzero Case08 adaptation.

**Q2. Does the phase-consistency factor have an independent contribution?** **CURRENT FORMAL CASES: CONTRIBUTION NOT DEMONSTRATED.** A_FULL and A_BACKGROUND_ONLY are identical.

**Q3. Is VFF still necessary, and where?** Yes, for normal drift tracking and post-fault recovery. It is not necessary for steady fault preservation; removing it improves retention only by turning the estimator into an excessively slow, high-memory tracker.

**Q4. Why is direction evidence excluded from control?** Normal drift and fault direction statistics overlap heavily, and fault bias can align with true drift. It lacks fault specificity and remains diagnostic-only.

**Q5. Is normal M4 tracking preserved?** Yes, with a small measured penalty: roughly 2% RMSE increase, 2.50% USR, and one-cycle extra Cs2 lag.

**Q6. Is pure-fault preservation improved?** Yes, but only slightly over M2: retention error improves by 0.469 percentage point and bias norm falls 3.75%. It remains far weaker than M3.

**Q7. Why is pure-fault improvement much smaller than fault-window ISR?** ISR is a cycle-increment rejection measure; continuing nonzero biased updates still accumulates toward nearly the same fixed point. It is not a steady-bias reduction ratio.

**Q8. Does Case07 show sub-threshold response?** Yes. M3 remains off, while A_FULL has mean `g=0.545523`, raises mean retention from 0.664536 to 0.698180, and reduces matched fault bias.

**Q9. Does Case08 show a real continuous-adaptation tradeoff?** Yes. A_FULL improves retention over M2 and moves 0.479655 pF during the M3 freeze, but its movement remains substantially fault-contaminated.

**Q10. What is the largest remaining problem?** Scalar weighting cannot distinguish real drift from geometrically aligned fault-induced learning, so it slows rather than eliminates absorption.

**Q11. Is M4-v0 frozen as paper_method_v1?** Yes. Only A_FULL is frozen.

**Q12. Is Phase 2 full experimental design allowed?** Yes, after this freeze; it was not executed here.

## 12. Method Freeze and Reproducibility

Final method name:

```text
M4 — Residual-Evidence Weighted Adaptive Identification
REW-AI
```

The exact equations, parameters, hashes, MATLAB/Simulink versions, and model identity are recorded in `step6_ablation/PAPER_METHOD_V1_FREEZE.md` and `tables/freeze_hash_manifest.csv`.

```text
M4 VERSION:
paper_method_v1

FORMULA STATUS:
FROZEN

PARAMETER STATUS:
FROZEN

SOURCE STATUS:
FROZEN

M4 NEW FITTED/TUNED PARAMETERS:
0
```

Regression protection:

```text
Formal validator = 19/19 PASS
Historical regression = 11/11 PASS
A_NO_WEIGHT == M2 = 7/7 exact PASS
M0/M2/M3 frozen outputs unchanged
Phase1A frozen
Phase1B frozen
Step1–5B protected files unchanged
```

## 13. Final Decision

The full M4 implementation is valid, normal tracking is acceptable, fault preservation is consistently better than M2, the Case08 tradeoff survives ablation, and the component roles and limitations are now bounded. M4 is not superior to M3 in pure-fault preservation and does not claim perfect separation.

```text
PHASE 1C STATUS:
COMPLETE

PHASE 2 READINESS:
YES
```

Permitted future Phase 2 scope is limited to a robustness matrix over fault amplitude, reference phase error, noise/SNR, different drift directions/rates, Monte-Carlo, and statistical summaries. None was executed in Step 6.
