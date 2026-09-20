# Phase 1C Step 6 — Frozen Ablation Specification

## Scope

This specification is the human-readable companion to `phase1c_step6_definition.m`. It contains no parameter search and introduces no new physical case.

Formal anchors:

- `Case02_slow_drift`, seed 102: normal tracking.
- `Case05_fault_only`, seed 106: pure fault.
- `Case07_overlap_drift_fault`, seed 105, factor 1.30: weak overlap with M3 inactive.
- `Case08_overlap_drift_fault_f160`, seed 105, factor 1.60: triggered overlap with M3 active.

All anchors use AutoComp9, 30 dB SNR, the frozen reference reconstruction, existing sampling, existing windows, and inherited algorithm parameters.

## Variants

| Variant | Definition | Status |
|---|---|---|
| M2 | Frozen full VFF-RLS adaptation | Reference |
| M3 | Frozen binary hard gate | Reference |
| A_FULL | Unmodified M4-v0 | Sole production/freeze candidate |
| A_NO_WEIGHT | `g = 1` | Ablation only; must equal M2 |
| A_BACKGROUND_ONLY | `p_q = 1`, hence `s=e_b` | Ablation only |
| A_FIXED_LAMBDA | `lambda = lambda_max = 0.995` | Ablation only |

Direction is diagnostic-only in the implementation, so `DIRECTION CONTROL ABLATION: NOT APPLICABLE`. A state-inconsistent c-only weighting variant is excluded.

## Decision Rules

Allowed contribution labels are `SUPPORTED`, `LIMITED`, `NOT DEMONSTRATED`, and `NOT APPLICABLE`.

- Continuous weighting is supported only if A_FULL improves fault-preservation evidence over A_NO_WEIGHT/M2 while retaining nonzero adaptation in overlap.
- Phase consistency is demonstrated only by a measurable A_FULL versus A_BACKGROUND_ONLY difference.
- VFF is assessed separately for normal tracking, fault transient/steady behavior, overlap behavior, and recovery. A_FIXED_LAMBDA cannot become a method candidate.
- No ablation result may trigger parameter tuning or formula revision in Step 6.

## Freeze Boundary

Only A_FULL can become `paper_method_v1`. A_NO_WEIGHT, A_BACKGROUND_ONLY, and A_FIXED_LAMBDA are permanently ablation-only results.
