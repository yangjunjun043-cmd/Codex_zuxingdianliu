# Case08 Frozen Specification

**CASE08 FROZEN BEFORE RESULTS.**

## Provenance and sole physical change

- source Case07: `Case07_overlap_drift_fault`
- source Case07 specification SHA-256: `8D1A8154960A58BF3E853F471B1112E68EA8029370247B51FCCD5F40359A20B1`
- source Case07 configuration SHA-256: `E0391512C8EDD91751E75C9F8A2D554A72B19EAAD7D7DA07C53CAB66F1A075FF`
- sole allowed physical change: `fault.factor: 1.30 -> 1.60`

All other fields are inherited directly from the frozen Case07 definition.

## Identity

- schema: `phase1c_step5b_case08_v1`
- case: `Case08_overlap_drift_fault_f160`
- seed: `105`
- model: `AI6109_MOA_AutoComp9`
- duration: `4.00 s`
- sample time: `2e-05 s`
- fundamental frequency: `50.0 Hz`
- SNR: `30.0 dB`

## True Cs trajectory

- drift interval: `0.80-2.20 s`
- profile: `cubic smooth step x^2(3-2x)`
- `Cs1 = 10.0 + 3.0*smoothstep pF`
- `Cs2 = 10.0 -2.0*smoothstep pF`

## Temporary B-phase resistive fault

- factor: `1.60`
- onset: `1.50 s`
- ramp-up: `1.50-1.56 s`
- plateau: `1.56-1.90 s`
- ramp-down: `1.90-1.96 s`
- clear: `1.96 s`

## Reference and noise

- reference source: `B-phase voltage from AutoComp9`
- reconstruction: `reconstruct_refs_from_b`
- phase error: `0.00 deg`
- initialization: `[0.10, 0.70) s`
- noise source: `exact Case06 seed-105 measurement-noise replay`
- noise RNG seed: `10105`
- F/CF policy: `one shared noise vector per phase for F and CF`

## Matched branches

- `F`: shared drift/reference/noise plus factor-1.60 fault.
- `CF`: identical drift/reference/noise with no fault.
- required pre-fault and non-fault input difference: exactly zero.

## Frozen analysis windows

All windows use `[start,end)` boundaries.

| Window | Start (s) | End (s) | Description |
|---|---:|---:|---|
| W0 | 1.20 | 1.45 | pre-fault active drift |
| W1 | 1.62 | 1.74 | overlap early |
| W2 | 1.74 | 1.88 | overlap late |
| W3 | 1.98 | 2.18 | post-fault active drift |
| W4 | 2.40 | 2.80 | post-drift recovery |

## Pre-registered trade-off rule

- A: `M4 fault-increment retention better than M2`
- B: `M4 Fault-branch movement during the M3 gate interval exceeds M3`
- C: `M4 counterfactual drift movement exceeds its fault-induced movement`
- demonstrated: `A and B and C`
- mixed: `at least one but not all of A, B, and C`
- not demonstrated: `none of A, B, and C`
