# Phase 2 Step 1C — Reuse and Duplicate Audit

## 1. ID and physical-signature audit

- Physical condition IDs：204/204 unique。
- Algorithm evaluation IDs：816/816 unique。
- Replay IDs：8/8 unique。
- Sensitivity IDs：15/15 unique。
- Deterministic physical signatures：0 duplicate groups across 54 rows。
- All four CSV files contain zero blank cells；`NaN`/`N/A` rules are followed。

## 2. Omitted nominal aliases

The following conceptual Step 1B points are not duplicated as physical rows. Their provenance maps to the listed anchor:

| Omitted nominal ID / role | Reused condition |
|---|---|
| `P2_FA_FO_160` | `P2_AN_C05` |
| `P2_FA_DF_160` | `P2_AN_C06` |
| `P2_SN_30` | `P2_AN_C02` |
| `P2_PE_000` | `P2_AN_C05` |
| `P2_H3_050` | `P2_AN_C02` |
| `P2_NS_000` | `P2_AN_C02` |
| `P2_CS_000` | `P2_AN_C02` |
| `P2_AC_000` | `P2_AN_C02` for physical truth; external wrapper equivalence still requires zero-injection regression |
| `P2_OV_R10_F130` | `P2_AN_C07` |
| `P2_OV_R10_F160` | `P2_AN_C08` |
| `P2_DD_D1_F130` | `P2_AN_C07` |
| `P2_DD_D1_F160` | `P2_AN_C08` |

The registry therefore contains no second nominal physical dataset. `reuse_condition_id` remains `N/A` on retained unique rows; alias-to-anchor mapping is frozen in this audit rather than represented by duplicate rows.

## 3. Anchor reuse

- Case01–Case06：M0/M2/M3/M4 frozen evidence registered as 24 `EXACT_REUSE` evaluations。
- Case07–Case08：M2/M3/M4 registered as 6 `EXACT_REUSE` evaluations。
- Case07–Case08 M0：2 `NEW_RUN_REQUIRED` rows with `MISSING_FOR_PHASE2_MATRIX` note。
- Total exact reuse：30。

## 4. Partial reuse and metric recomputation

- Phase 1B fault-amplitude M2：5 nonnominal fault-only rows are formal historical evidence but lack the complete Phase 2 schema/full saved workspace。
- Phase 1B reference-phase M2：5 nonzero phase rows have the same limitation。
- Legacy M3-style background：3 SNR + 4 harmonic + 3 negative-sequence rows。

Therefore:

```text
PARTIAL_REUSE = 20
RECOMPUTE_METRICS_ONLY = 0
```

The Phase 1B Step4 summary/cycle CSVs alone are insufficient to reconstruct every frozen Phase 2 metric, so those rows are not mislabeled as metrics-only recomputation.

## 5. Rerun and gate status

Deterministic algorithm evaluations：166 `NEW_RUN_REQUIRED`。Among physical conditions, 6 Cself and 4 CsAC rows are `PENDING_GATE`, not `BLOCKED`。No gate has failed, so `BLOCKED=0`。

MC contributes 600 additional `NEW_RUN_REQUIRED` evaluations. Across all 204 physical conditions, 131 are pending an interface gate: 127 include nonzero Cself mismatch and 4 are CsAC mismatch. This does not alter the preregistered count.

## 6. Budget result

Actual deterministic unique count is exactly 54. No condition was added or removed to force this result; it follows the Step 1B raw-grid minus explicitly frozen nominal aliases calculation.

