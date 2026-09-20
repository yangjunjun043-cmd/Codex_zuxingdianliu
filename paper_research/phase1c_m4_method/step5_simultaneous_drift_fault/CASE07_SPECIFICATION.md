# Case07 Frozen Specification

This specification was frozen before running M2/M3/M4.

## Identity

- schema: `phase1c_step5_case07_v1`
- case: `Case07_overlap_drift_fault`
- source case: `Case06_drift_then_fault`
- seed: `105`
- model: `AI6109_MOA_AutoComp9`
- simulation duration: `4.00 s`
- sample time: `2e-05 s`
- fundamental frequency: `50.0 Hz`

## True Cs trajectory

For `s=smoothstep(t; 0.80, 2.20)`, using `x^2(3-2x)`:

- `Cs1 = 10.0 + 3.0 s pF`
- `Cs2 = 10.0 -2.0 s pF`

## Temporary B-phase resistive fault

- factor: `1.30`
- onset: `1.50 s`
- ramp-up: `1.50-1.56 s`
- plateau: `1.56-1.90 s`
- ramp-down: `1.90-1.96 s`
- cleared after: `1.96 s`

## Reference and noise

- reference source: `B-phase voltage from AutoComp9`
- reconstruction: `reconstruct_refs_from_b`
- phase error: `0.00 deg`
- initialization window: `[0.10, 0.70) s`
- SNR: `30.0 dB`
- noise source: `exact Case06 seed-105 measurement-noise replay`
- branch policy: `one shared noise vector per phase for F and CF`

The exact Case06 seed-105 measurement-noise vectors are reconstructed by subtracting an `SNR=Inf` Case06 run from its frozen `SNR=30 dB` run. Those identical vectors are then supplied to both Case07 branches.

## Matched branches

- `F`: shared drift/reference/noise plus the temporary fault.
- `CF`: identical inputs with `fault_scale=1` throughout.
- Required identity: all branch inputs except fault scale match, and all observed signals match sample-by-sample before 1.50 s.

## Frozen analysis windows

All windows use `[start,end)` boundaries.

| Window | Start (s) | End (s) | Description |
|---|---:|---:|---|
| W0 | 1.20 | 1.45 | pre-fault active drift |
| W1 | 1.62 | 1.74 | overlap early |
| W2 | 1.74 | 1.88 | overlap late |
| W3 | 1.98 | 2.18 | post-fault active drift |
| W4 | 2.40 | 2.80 | post-drift recovery |

## Pre-registered comparison rule

No weighted or overall score is used. Drift tracking and fault increment preservation remain separate objectives.

- overlap drift metric: `fault-branch RMS parameter-error norm over W1 union W2`
- retention metric: `mean absolute matched retention-ratio error over W1 and W2`
- geometric check: `fault branch must not obtain lower overlap error than its matched CF branch`
- demonstrated: `M4 drift metric < M3, M4 retention metric < M2, and no geometric false improvement`
- mixed: `only one objective improves, or both improve with geometric confounding`
- not demonstrated: `neither required objective improves`
