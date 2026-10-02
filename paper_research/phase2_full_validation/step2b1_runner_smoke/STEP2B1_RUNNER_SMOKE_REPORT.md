# Phase 2 Step 2B-1 — Registry-Driven Runner Smoke Report

## 1. Runner architecture

`run_phase2_deterministic_core.m` directly reads both frozen registries. It materializes physical truth, algorithm assumptions, data generation, evaluation windows, and provenance before calling the frozen `run_phase1a_algorithm` dispatcher.

All algorithms consume one in-memory physical dataset, truth, noise realization, reconstructed reference, and window definition. Persistent-fault metrics use a paired counterfactual metric branch from the same physical realization; this is not an additional registered physical condition or algorithm evaluation.

## 2. Six smoke conditions

| Condition | Complete evaluations | Status |
|---|---:|---|
| `P2_FA_FO_130` | 4/4 | PASS |
| `P2_FA_DF_130` | 4/4 | PASS |
| `P2_SN_20` | 4/4 | PASS |
| `P2_PE_100` | 4/4 | PASS |
| `P2_H3_100` | 4/4 | PASS |
| `P2_NS_003` | 4/4 | PASS |

Only the six preregistered smoke conditions were run. The full deterministic matrix, Cself, CsAC, overlap, Monte Carlo, replay, and sensitivity matrices were not run.

## 3. Registry mapping audit

Unique condition lookup, exact target value, anchor non-target equality, runtime trajectory/config checks: **24/24 algorithm rows pass**.

`P2_PE_100` applies +1 deg to fitted fundamental phase and +3 deg to fitted third-harmonic phase without changing physical data. `P2_NS_003` remains `NEGATIVE_SEQUENCE_INTERNAL_CONVENTION=UNRESOLVED` and `INTERPRETATION=CONFIGURED_VALIDITY_BOUNDARY_ONLY`.

Schema normalization: the frozen Case06 anchor uses NaN for an unspecified base `drift_rate_multiplier`, while its Phase 2 descendant explicitly uses 1. Both map to the unchanged frozen Case06 Cs trajectory; the runtime trajectory assertion also passed.

## 4. Shared-data audit

Shared physical data/truth/reference/window signature: **24/24 algorithm rows pass**.

Each condition was simulated once as a clean/noisy deterministic pair; M0/M2/M3/M4 received the same noisy arrays and reference object.

## 5. Metric extraction audit

Required frozen metrics available: **24/24 rows**.

Fault rows include retention and signed paired-counterfactual fault-induced Cs bias. M3 uses response-window hard-gate ratio and onset latency; M4 uses frozen update-weight definitions. NaN values in non-applicable fields mean N/A, including no-trigger latency.

## 6. Numerical failures

Numerical/execution failures: **0/24 rows**.

## 7. Frozen integrity

PRE: Phase 1 9/9, Step 1 3/3. POST: Phase 1 9/9, Step 1 3/3. PRE/POST unchanged: **PASS**.

## 8. Unexpected observations

No simulation abort, missing required output, NaN/Inf in core signals, or missing applicable metric was observed. Metric values are smoke evidence only and are not robustness conclusions.

Descriptive smoke observations retained without tuning: M4 B fundamental error is 10.438460% at `P2_PE_100` and 34.899573% at `P2_NS_003`; M4 fault-retention error is -7.464005% at `P2_FA_FO_130`. The negative-sequence result remains a configured validity-boundary observation, not a mechanism claim.

Before the formal Step 3 CsAC matrix, add a `GENERIC_ZERO_PATH_REGRESSION`: exercise ideal current -> zero CsAC contribution -> sigma -> same RNG -> noisy current through the generic path, without a `CsAC==0` nominal-data shortcut. This does not block Step 2B.

## 9. Authorization for full deterministic core

STEP 2B-1 STATUS: **PASS**

REGISTRY RUNNER: **AUTHORIZED**

SMOKE CONDITIONS: **6 / 6 COMPLETE**

ALGORITHM EVALUATIONS: **24 / 24 COMPLETE**

FROZEN SOURCE MODIFIED: **NO**

FULL DETERMINISTIC MATRIX EXECUTED: **NO**

READY FOR STEP 2B-2: **YES**
