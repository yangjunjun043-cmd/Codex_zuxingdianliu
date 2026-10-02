# Phase 2 Experiment Matrix — Step 1C Draft

## 1. Deterministic physical conditions

| Group | Raw design points | Omitted nominal duplicates | Registry rows | IDs / anchor mapping |
|---|---:|---:|---:|---|
| Frozen anchors | 8 | 0 | 8 | `P2_AN_C01`–`P2_AN_C08` |
| Fault amplitude | 12 | 2 | 10 | factor 1.60 maps to C05/C06 |
| SNR | 4 | 1 | 3 | 30 dB maps to C02 |
| Reference phase | 6 | 1 | 5 | 0° maps to C05 |
| Third harmonic amplitude | 5 | 1 | 4 | 0.05 maps to C02 |
| Negative sequence | 4 | 1 | 3 | 0 maps to C02 |
| Cself mismatch | 7 | 1 | 6 | 0% maps to C02 |
| CsAC mismatch | 5 | 1 | 4 | 0 pF maps to C02 subject to wrapper equivalence gate |
| Overlap core | 9 | 2 | 7 | R10/F130 maps C07; R10/F160 maps C08 |
| Direction extension | 6 | 2 | 4 | D1/F130 and D1/F160 reuse the core anchors |
| **Total** |  |  | **54** | exact Step 1B budget |

All 54 rows expand to M0/M2/M3/M4, yielding 216 deterministic algorithm-evaluation rows.

## 2. Deterministic readiness

| Physical-condition status | Rows | Meaning |
|---|---:|---|
| `REUSE_AVAILABLE` | 8 | frozen anchor physical data |
| `READY` | 36 | new condition design has no pending feature-interface gate |
| `PENDING_GATE` | 10 | 6 nonzero Cself + 4 nonzero CsAC conditions |
| `BLOCKED` | 0 | no gate has failed |

Algorithm-result classification within the 216 rows:

| Result status | Rows |
|---|---:|
| `EXACT_REUSE` | 30 |
| `PARTIAL_REUSE` | 20 |
| `RECOMPUTE_METRICS_ONLY` | 0 |
| `NEW_RUN_REQUIRED` | 166 |
| `BLOCKED` | 0 |

The 20 partial rows are 10 Phase 1B M2 amplitude/phase records and 10 pre-unified M3-style SNR/harmonic/negative-sequence background records. All still require a formal Phase 2 run.

## 3. Monte-Carlo matrix

The same physical registry additionally contains 150 frozen stochastic rows: H/F/O × 50. They expand to 600 `NEW_RUN_REQUIRED` algorithm-evaluation rows. Pilot H/F/O indices 001–020 form 60 physical conditions and 240 evaluations, strictly inside the formal registry.

## 4. Nonphysical addenda

- Replay registry：8 conceptual trajectories, F/N existing provenance and P/A four future incremental trajectories.
- Sensitivity registry：15 parameter×algorithm level records; five nominal records reuse Case08 and ten low/high evaluations are incremental.

## 5. Budget reconciliation

```text
physical registry rows                 = 54 + 150 = 204
algorithm-evaluation registry rows     = 216 + 600 = 816
incremental sensitivity evaluations   = 10
incremental replay trajectories       = 4
grand planned evaluations/trajectories= 830
```

This matches Step 1B. No execution has occurred.

