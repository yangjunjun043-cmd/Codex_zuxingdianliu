# Phase 2 Step 2A — Execution Infrastructure & Gate Validation

## 1. Scope

Step 2A executed only frozen-source integrity checks, three anchor equivalence paths, the Cself split interface checks, and the external CsAC zero-injection/structural checks. No deterministic matrix, sweep, Monte-Carlo cohort, tuning, or method change was run.

## 2. Frozen integrity pre-check

- Phase 1 manifest: 9/9 PASS.
- Phase 2 Step 1 final files: 3/3 PASS.
- Specification verification used the frozen canonical self-hash rule.
- PRE result: **PASS**.

## 3. Common runner architecture

The wrapper exposes separate `physical_truth_config.Cself_truth_pF` and `algorithm_assumption_config.Cself_algorithm_pF`. Physical data generation receives only the truth value; the frozen dispatcher receives the independent three-phase `self_pF` assumption. M0/M2/M3/M4 are delegated to `run_phase1a_algorithm` without copied formulas.
The external CsAC path starts from the frozen clean Case02 signal, adds the AC contribution to ideal current, recomputes per-phase noise sigma from the modified ideal current, and then draws noise with the frozen seed.

## 4. COMMON_RUNNER_EQUIVALENCE_GATE

- Result: **PASS** (137/137 comparison rows passed).
- Anchor budget: 11 algorithm evaluations (Case08 M2/M3/M4 each includes matched F/CF trajectories).
- Seeds: Case02=102, Case05=106, Case08=105.
- Maximum recorded numeric difference: 4.8849813083506888e-15.
- Missing state/trajectory evidence, where applicable, is explicitly marked `NOT_AVAILABLE_IN_FROZEN_EVIDENCE`; it is not synthesized.

## 5. CSELF_SPLIT_INTERFACE_GATE

- Result: **PASS** (18/18 rows passed).
- C+ (440/400 pF) maximum physical-current change: 0.0013974208132434864 A.
- C- (360/400 pF) maximum physical-current change: 0.0013973416378183397 A.
- C+/C- are interface and sanity tests only; their performance is not a Step 3 robustness result.

## 6. ZERO_INJECTION_REGRESSION

- Result: **PASS** (34/34 rows passed).
- AC0 maximum noisy-current difference: 0 A.
- AC0 compares ideal/noisy currents, truth, references, and formal M0/M2/M3/M4 outputs against the nominal Case02 path.

## 7. CsAC structural sanity

- AC1 formula maximum error: 8.6736173798840355e-19 A.
- AC1 three-phase conservation maximum error: 1.7347234759768071e-18 A.
- Optional 0.5-to-1.0 pF linearity error: 2.6020852139652106e-18 A (PASS).
- AC1 and optional linearity checks are structural sanity evidence, not paper performance comparisons.

## 8. Frozen integrity post-check

- Phase 1 manifest: 9/9 PASS.
- Phase 2 Step 1 final files: 3/3 PASS.
- PRE/POST hash vectors identical: **PASS**.
- POST result: **PASS**.

## 9. Gate summary

```text
NO_FROZEN_SOURCE_DIFF_GATE: PASS
COMMON_RUNNER_EQUIVALENCE_GATE: PASS
CSELF_SPLIT_INTERFACE_GATE: PASS
ZERO_INJECTION_REGRESSION: PASS
REPLAY_EQUIVALENCE_GATE: NOT_RUN
TRACKER_EQUIVALENCE_GATE: NOT_RUN
NEGATIVE_SEQUENCE_INTERNAL_CONVENTION: UNRESOLVED
```

## 10. Allowed / blocked Phase2 families

- Registry conditions ready: **204**.
- Registry conditions pending or blocked: **0**.
- Ordinary deterministic families: AUTHORIZED.
- Nonzero Cself mismatch and dependent MC rows: AUTHORIZED.
- Nonzero CsAC conditions: AUTHORIZED.
- Negative-sequence rows remain validity-boundary tests; the internal convention remains unresolved.
- Counterfactual replay and sensitivity variants remain pending because their dedicated equivalence gates were not run.
- Monte-Carlo remains scheduled for Step 6 and was not executed here.

## 11. Next-step authorization

```text
STEP 2A STATUS: PASS
COMMON PHASE2 RUNNER: AUTHORIZED
CSELF CONDITIONS: AUTHORIZED
CSAC CONDITIONS: AUTHORIZED
FROZEN SOURCE MODIFIED: NO
FULL MATRIX EXECUTED: NO
READY_CONDITION_COUNT: 204
PENDING_OR_BLOCKED_CONDITION_COUNT: 0
READY FOR STEP 2B: YES
```
