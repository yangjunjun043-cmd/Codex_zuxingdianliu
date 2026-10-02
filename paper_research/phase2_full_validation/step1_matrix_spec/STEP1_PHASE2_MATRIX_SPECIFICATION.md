# Phase 2 Step 1 — Final Matrix Specification

## 1. Purpose and scientific questions

This document is the final preregistration entry point for Phase 2. Together with `phase2_condition_registry.csv` and `phase2_execution_registry.csv`, it defines all authorized Phase 2 conditions, evaluations, metrics, gates and execution order.

Phase 2 asks four questions:

1. How robust are M0/M2/M3/M4 to noise, reference phase error, harmonic amplitude and negative-sequence boundary conditions?
2. How do Cself mismatch and unmodelled CsAC coupling affect parameter tracking and resistive-current extraction?
3. During simultaneous true drift and resistive fault, how do drift rate, fault amplitude and drift direction affect tracking, fault retention and post-fault memory?
4. Across frozen stochastic cohorts, what distributions of accuracy, contamination, suppression cost and numerical failures are observed?

Phase 2 validates robustness and generalization. It does not tune M4. A method failure is a valid result and must remain in the evidence set.

## 2. Frozen algorithm set

| ID | Definition | Frozen version |
|---|---|---|
| M0 | Fixed coupling compensation | Phase 1A frozen implementation |
| M2 | VFF-RLS without gate | Phase 1C inherited implementation |
| M3 | VFF-RLS with hard gate | Phase 1C inherited implementation |
| M4 | Residual-Evidence Weighted Adaptive Identification | `paper_method_v1` |

No fifth main algorithm is authorized. Case07/08 lack historical M0 results, so their M0 records remain `NEW_RUN_REQUIRED` and `MISSING_FOR_PHASE2_MATRIX`.

## 3. Deterministic factor matrix

| Factor family | Frozen levels | Anchor / control rule | Unique rows added |
|---|---|---|---:|
| Fault amplitude, fault only | 1.05, 1.10, 1.20, 1.30, 1.40, 1.60 | Case05; 1.60 reuses anchor | 5 |
| Fault amplitude, drift then fault | same six levels | Case06; 1.60 reuses anchor | 5 |
| SNR | Inf, 40, 30, 20 dB | Case02; 30 dB reuses anchor | 3 |
| Reference phase error | 0, 0.33, 0.5, 1, 2, 3 deg | Case05; positive coherent lead; 0 reuses anchor | 5 |
| Third-harmonic amplitude | 0.005, 0.02, 0.05, 0.08, 0.10 | Case02; `phi3=0`; 0.05 reuses anchor | 4 |
| Negative sequence | 0, 0.01, 0.03, 0.05 pu | Case02 validity boundary; 0 reuses anchor | 3 |

All four algorithms share identical physical data within a condition. Fault-factor sweeps hold timing, ramp, reference, harmonic, negative sequence, Cself and noise definition fixed.

## 4. Model-mismatch matrix

### Cself

```text
Cself_algorithm = 400 pF
Cself_mismatch_pct = 100 * (Cself_truth - 400) / 400
```

Truth levels are 360, 380, 392, 400, 408, 420 and 440 pF, corresponding to -10%, -5%, -2%, 0%, +2%, +5% and +10%. Only three-phase common-mode mismatch is included. Every nonzero mismatch remains subject to `CSELF_SPLIT_INTERFACE_GATE`.

### CsAC

Truth levels are 0, 0.5, 1, 2 and 3 pF. The estimator remains restricted to AB/BC parameters. AutoComp9 is not modified. Future external-wrapper injection is frozen as:

```text
iA_AC = CsAC * (duA/dt - duC/dt)
iB_AC = 0
iC_AC = CsAC * (duC/dt - duA/dt)
```

Injection occurs before formal measurement-noise generation. Every nonzero CsAC condition remains subject to `ZERO_INJECTION_REGRESSION`.

## 5. Overlap rate and direction matrix

The overlap core uses `D1=[+3,-2] pF`, norm `sqrt(13) pF`, rate multipliers `{0.5,1,2}` and fault factors `{1.10,1.30,1.60}`. The raw 3×3 core has nine points. Case07 and Case08 supply the two D1/rate-1 anchor points, so seven new core rows are registered.

Direction extension uses rate 1 and factors 1.30/1.60:

- D1 = `[+3,-2] pF`;
- D2 = `[-3,+2] pF`;
- D3 = `[+3,+2] pF`.

All directions have norm `sqrt(13) pF`. The D1 points reuse the anchors. Four new D2/D3 rows remain. A full direction×rate×factor Cartesian product is excluded.

## 6. Timing and evaluation windows

For rate `r`:

```text
drift_start = 0.80 s
drift_duration = 1.40/r
fault_start = drift_start + 0.50*drift_duration
fault shape = 0.06 s ramp-up + 0.34 s plateau + 0.06 s ramp-down
```

| Item | 0.5x | 1x | 2x |
|---|---|---|---|
| Drift | `[0.80,3.60)` | `[0.80,2.20)` | `[0.80,1.50)` |
| Fault | `[2.20,2.66)` | `[1.50,1.96)` | `[1.15,1.61)` |
| W0 | `[1.60,2.10)` | `[1.20,1.45)` | `[1.00,1.125)` |
| W1 | `[2.32,2.44)` | `[1.62,1.74)` | `[1.2611764706,1.3635294118)` |
| W2 | `[2.44,2.58)` | `[1.74,1.88)` | `[1.3635294118,1.4829411765)` |
| W3 | `[2.7383333333,3.5216666667)` | `[1.98,2.18)` | `N/A_BY_DESIGN` |
| W4 | `[3.80,4.20)` | `[2.40,2.80)` | `[1.81,2.21)` |
| Stop time | 4.40 s | 4.00 s | 4.00 s |

The 1x schedule exactly reproduces Case07/08. The 2x condition retains real overlap `[1.15,1.50)` but has no post-fault active-drift interval because fault clear occurs after drift end. This absence is not a numerical failure.

## 7. Counterfactual replay specification

Case08 M3/M4 use four conceptual trajectories:

- F: frozen fault actual;
- N: no-fault natural schedules;
- P: no fault, replay F gate/weight schedule, natural no-fault lambda;
- A: no fault, replay F gate/weight and lambda schedules.

The operational decomposition is:

```text
Delta_c_F - Delta_c_N
= (Delta_c_F - Delta_c_A)
+ (Delta_c_A - Delta_c_P)
+ (Delta_c_P - Delta_c_N)
```

P/A may execute only after `REPLAY_EQUIVALENCE_GATE`. The decomposition is operational and must not be described as perfect causal identification.

## 8. Sensitivity specification

Offline Case08 sensitivity records are descriptive, not tuning:

| Parameter | Algorithms | Low | Frozen | High |
|---|---|---:|---:|---:|
| gate_ratio | M3/M4 | 1.008 | 1.12 | 1.232 |
| gate_quad_ratio | M3/M4 | 1.08 | 1.20 | 1.32 |
| gate_hold_cycles | M3 | 24 | 25 | 26 |

Low/high variants require `TRACKER_EQUIVALENCE_GATE`. They cannot replace frozen method parameters or be used to select an optimum.

## 9. Monte-Carlo specification

The formal registry contains H/F/O cohorts with N=50 each. Pilot uses indices 001–020 in each cohort and is a strict 60-condition subset.

- H: SNR, reference phase, drift rate, Cself mismatch;
- F: SNR, reference phase, fault factor, Cself mismatch;
- O: SNR, reference phase, fault factor, drift rate, Cself mismatch.

Sampling uses the already frozen equal-probability categorical registry. Master seed is `2290434627`, derived once from the three Step 1B freeze artifacts. The 300 truth/noise seeds are mutually unique and must not be regenerated. Fault onset, Cs initial value and drift amplitude were excluded as `EXCLUDED_UNRESOLVED_BOUND` and retain nominal values. Negative sequence and CsAC do not enter primary MC.

## 10. Metrics

### Healthy and drift

- Primary: `Cs1_RMSE_pF`, `Cs2_RMSE_pF`.
- Secondary: B resistive fundamental error and Cs1/Cs2 maximum absolute error.
- M4 cost: `unnecessary_suppression_ratio`.

### Persistent fault

- Primary: true/estimated fault factor, retention error, signed fault-induced Cs1/Cs2 changes and their contamination norm.
- Secondary: gate timing/ratio, M4 mean update weight, suppression onset and ISR J/h.
- ISR is not final bias reduction.

### Temporary overlap

- Primary: overlap Cs1/Cs2 RMSE and W1/W2 fault-increment retention.
- Mandatory records: signed true-drift, F, CF and F-CF vectors plus L2 norms.
- Secondary: parameter-error RMS norm, mean/endpoint memory, post-fault AUC, gate response and M4 mean weight.

`drift_adaptation_purity` is provenance only and cannot be used as a purity score. `NUMERICAL_FAILURE` includes only abort, missing required output, NaN, Inf, validator failure or corrupt result. No performance threshold is preregistered.

## 11. Reuse policy

Across the 816 main evaluation records:

| Status | Count | Policy |
|---|---:|---|
| EXACT_REUSE | 30 | Frozen production result available |
| PARTIAL_REUSE | 20 | Background/formal partial evidence; a Phase 2 run is still required |
| RECOMPUTE_METRICS_ONLY | 0 | No source workspace supports the complete new schema without rerun |
| NEW_RUN_REQUIRED | 766 | 166 deterministic + 600 MC |
| BLOCKED | 0 | Pending gates have not failed |

Nominal aliases for Case05/06/07/08 and Case02 factor controls are omitted as duplicate physical rows and point conceptually to their frozen anchors.

## 12. Execution gates

| Gate | Required before |
|---|---|
| `CSELF_SPLIT_INTERFACE_GATE` | any nonzero Cself mismatch |
| `ZERO_INJECTION_REGRESSION` | any nonzero CsAC condition |
| `REPLAY_EQUIVALENCE_GATE` | P/A replay conclusions |
| `TRACKER_EQUIVALENCE_GATE` | offline sensitivity variants |
| `RATE_TIMING_DESIGN_GATE` | overlap execution; Step 1 design validation passed |
| `NO_FROZEN_SOURCE_DIFF_GATE` | every future execution batch |

`PENDING_GATE` is not `BLOCKED`. A failed gate blocks the affected records and must not be bypassed by method changes.

## 13. Scope exclusions

This phase excludes independent harmonic-phase sweeps, per-phase Cself mismatch, general sensor gain/bias/filter/delay models, full direction×rate×factor grids, negative-sequence/CsAC Monte-Carlo variables, new detector thresholds, detection/false-alarm primary metrics, new learning algorithms and results-driven parameter optimization.

## 14. Final condition budget

```text
deterministic physical conditions = 54
Monte-Carlo conditions = 150
total physical/stochastic conditions = 204
```

The deterministic total comprises eight anchors and 46 new unique conditions. No duplicate physical signature remains.

## 15. Final execution budget

The unified execution registry has 839 records:

| Record type | Registry records | Future incremental execution interpretation |
|---|---:|---|
| MAIN_ALGORITHM_EVALUATION | 816 | governed by reuse/run status |
| COUNTERFACTUAL_REPLAY | 8 | four P/A trajectories are new |
| SENSITIVITY_VARIANT | 15 | ten low/high variants are incremental |
| **Total records** | **839** | not 839 new runs |

The Step 1B planned evaluation/trajectory budget remains 830: 216 deterministic main + 600 MC + 10 incremental sensitivity + 4 incremental replay.

## 16. Frozen-source integrity

The Phase 1C manifest at `paper_research/phase1c_m4_method/step6_ablation/tables/freeze_hash_manifest.csv` was recomputed during Step 1D. All 9/9 expected SHA-256 values match. AutoComp9, M0/M2/M3/M4, `paper_method_v1`, Case01–Case08 and frozen reports were not modified.

## 17. Known unresolved limitations

- Negative-sequence internal phase convention remains `UNRESOLVED_INTERNAL_CONVENTION`; nonzero cases are configured validity-boundary tests only.
- Cself truth/assumption separation has not yet passed its interface gate.
- CsAC wrapper has not been implemented or zero-injection validated.
- Counterfactual and sensitivity wrappers have not passed equivalence gates.
- The main reference-phase matrix covers positive coherent lead only, not signed symmetry or a complete field-sensor chain.
- MC fault-onset, initial-Cs and drift-amplitude distributions remain excluded because traceable bounds were not available.

## 18. Phase 2 execution order

1. **Step 2A — Execution Infrastructure & Gates:** complete Cself split, CsAC zero-injection, no-frozen-source-diff and common-runner validation.
2. **Step 2B — Deterministic Core Matrix:** execute conditions not blocked by pending feature gates first.
3. **Step 3 — Model Mismatch Robustness.**
4. **Step 4 — Simultaneous Drift + Fault.** Counterfactual replay may run around this step only after replay equivalence passes.
5. **Step 5 — Sensitivity / Validity Boundary.**
6. **Step 6 — Monte-Carlo:** run 20/cohort pilot, audit execution completeness, then extend the same registry to 50/cohort.
7. **Step 7 — Final Statistical Analysis.**

## 19. Completion rule

Phase 2 passes when the protocol is executed correctly, frozen sources remain unchanged, the registry is followed, required metrics are complete, negative results are retained and validators pass. Completion is not defined by M4 outperforming M2 or M3.

The record must retain M4, M3 or M2 failures, wrong-direction movement, noise/phase/model-mismatch sensitivity, threshold misses and hard-freeze drift loss. Results cannot authorize redesigning the frozen matrix.

## 20. Final status

```text
STEP 1 FINAL STATUS:
COMPLETE

PHASE2 PREREGISTRATION:
FROZEN

REGISTRY VERSION:
PHASE2_REGISTRY_V1

DETERMINISTIC CONDITIONS:
54

MONTE-CARLO CONDITIONS:
150

TOTAL PHYSICAL/STOCHASTIC CONDITIONS:
204

MAIN ALGORITHM EVALUATIONS:
816

NEW PHASE2 SIMULATION:
NO

FROZEN SOURCE MODIFIED:
NO

READY FOR PHASE2 EXECUTION:
YES
```

## 21. FINAL FREEZE MANIFEST

```text
registry_version: PHASE2_REGISTRY_V1
freeze_timestamp: 2026-09-20T11:28:01+08:00
phase1_frozen_manifest_reference: paper_research/phase1c_m4_method/step6_ablation/tables/freeze_hash_manifest.csv
phase1_frozen_manifest_match: 9/9

STEP1_PHASE2_MATRIX_SPECIFICATION.md
specification_sha256_mode: CANONICAL_SELF_HASH
specification_sha256_canonical: 9FAB573BCE6D5D0A1F3F6A569771F5B1C69706AB6E6E38FD97843BF41B931531

phase2_condition_registry.csv
sha256: 8A498E19A455C13CAA7B5371BE2F933CA7B7637B893C656C92DA84D88D1938BE

phase2_execution_registry.csv
sha256: 974B8874404C46C4B549CAD8E2D52CCCC7F1D4F81D68AF8911201307230394D7
```

The specification uses a canonical self-hash because a file cannot contain its own ordinary byte-for-byte SHA-256 without changing those bytes. Verification rule: replace the 64-hex value after `specification_sha256_canonical:` with the literal `<SELF_SHA256_CANONICAL_PLACEHOLDER>`, preserve all other bytes, then compute SHA-256.
