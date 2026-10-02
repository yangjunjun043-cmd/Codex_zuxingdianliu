# Phase 2 Step 3 — Model Mismatch Robustness

## 1. Scope and frozen authorization

This formal batch evaluates only common-mode `Cself` mismatch and unmodelled A-C coupling. M0/M2/M3/M4, AutoComp9, method parameters, windows, seeds, and frozen registries were not changed.

Step 2A authorization read without editing the registry: CSELF_SPLIT_INTERFACE_GATE=PASS, ZERO_INJECTION_REGRESSION=PASS, NO_FROZEN_SOURCE_DIFF_GATE=PASS. Frozen PENDING_GATE labels were retained.

PRE integrity: Phase 1 9/9 and Step 1 3/3. POST integrity: Phase 1 9/9 and Step 1 3/3. PRE/POST unchanged: **PASS**.

## 2. Generic zero-path regression

The strengthened path contains no `CsAC==0` nominal-data shortcut. It executes ideal current → zero CsAC contribution → recomputed sigma → frozen RNG → noisy current, then compares the result with the frozen Case02 nominal path.

| Comparison | Maximum absolute difference | Tolerance |
|---|---:|---:|
| Ideal iA/iB/iC | 0 A | 1e-12 |
| Noisy iA/iB/iC | 0 A | 1e-12 |
| Reference | 0 | 1e-12 |
| Truth | 0 | 1e-10 |
| M0 outputs | 0 | 1e-12 |
| M2 outputs | 0 | 1e-12 |
| M3 outputs | 0 | 1e-12 |
| M4 outputs | 0 | 1e-12 |

GENERIC_ZERO_PATH_REGRESSION: **PASS**

## 3. Cself mismatch results

Completed **6/6** conditions and **24/24** evaluations. Physical truth alone used 360/380/392/408/420/440 pF; the algorithm assumption remained 400 pF in every row.

| Condition | Level | Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | Cs1/Cs2 max abs (pF) | B fundamental err (%) | M3 gate ratio | M4 mean g | M4 USR |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|
| `P2_CS_M10` | -10 | M0 | 18.557633 | 14.174374 | 19.991121 / 16.000390 | 10.951678 | NaN | NaN | NaN |
| `P2_CS_M10` | -10 | M2 | 12.598183 | 8.209862 | 14.000000 / 10.000000 | 11.052887 | NaN | NaN | NaN |
| `P2_CS_M10` | -10 | M3 | 12.598183 | 8.209862 | 14.000000 / 10.000000 | 11.052887 | 0 | NaN | NaN |
| `P2_CS_M10` | -10 | M4 | 12.598183 | 8.209862 | 14.000000 / 10.000000 | 11.052887 | NaN | 0.992168 | 0.00783194 |
| `P2_CS_M05` | -5 | M0 | 10.607510 | 6.237564 | 11.990712 / 8.000440 | 9.552431 | NaN | NaN | NaN |
| `P2_CS_M05` | -5 | M2 | 8.090971 | 7.508769 | 8.376337 / 8.063267 | 1.530470 | NaN | NaN | NaN |
| `P2_CS_M05` | -5 | M3 | 8.090971 | 7.508769 | 8.376337 / 8.063267 | 1.530470 | 0 | NaN | NaN |
| `P2_CS_M05` | -5 | M4 | 8.093438 | 7.507324 | 8.385190 / 8.060987 | 1.538520 | NaN | 0.976221 | 0.023779 |
| `P2_CS_M02` | -2 | M0 | 5.903022 | 1.772863 | 7.190466 / 3.200470 | 9.098315 | NaN | NaN | NaN |
| `P2_CS_M02` | -2 | M2 | 3.309837 | 3.136478 | 3.577844 / 3.317948 | 0.433733 | NaN | NaN | NaN |
| `P2_CS_M02` | -2 | M3 | 3.309837 | 3.136478 | 3.577844 / 3.317948 | 0.433733 | 0 | NaN | NaN |
| `P2_CS_M02` | -2 | M4 | 3.312443 | 3.134183 | 3.586932 / 3.315761 | 0.443647 | NaN | 0.975056 | 0.0249441 |
| `P2_CS_P02` | 2 | M0 | 1.722848 | 5.209280 | 3.209861 / 6.199491 | 8.950392 | NaN | NaN | NaN |
| `P2_CS_P02` | 2 | M2 | 3.096350 | 3.263752 | 3.286000 / 3.470164 | 0.418231 | NaN | NaN | NaN |
| `P2_CS_P02` | 2 | M3 | 3.096350 | 3.263752 | 3.286000 / 3.470164 | 0.418231 | 0 | NaN | NaN |
| `P2_CS_P02` | 2 | M4 | 3.094020 | 3.266275 | 3.285400 / 3.472380 | 0.428319 | NaN | 0.975075 | 0.0249252 |
| `P2_CS_P05` | 5 | M0 | 5.729364 | 9.944400 | 8.010108 / 10.999461 | 9.183787 | NaN | NaN | NaN |
| `P2_CS_P05` | 5 | M2 | 7.896587 | 8.061385 | 8.090032 / 8.271494 | 0.779620 | NaN | NaN | NaN |
| `P2_CS_P05` | 5 | M3 | 7.896587 | 8.061385 | 8.090032 / 8.271494 | 0.779620 | 0 | NaN | NaN |
| `P2_CS_P05` | 5 | M4 | 7.894275 | 8.063991 | 8.089374 / 8.273580 | 0.789780 | NaN | 0.975313 | 0.0246866 |
| `P2_CS_P10` | 10 | M0 | 13.601414 | 17.913141 | 16.010518 / 18.999410 | 10.222518 | NaN | NaN | NaN |
| `P2_CS_P10` | 10 | M2 | 15.898812 | 16.058327 | 16.096912 / 16.273466 | 2.081652 | NaN | NaN | NaN |
| `P2_CS_P10` | 10 | M3 | 15.898812 | 16.058327 | 16.096912 / 16.273466 | 2.081652 | 0 | NaN | NaN |
| `P2_CS_P10` | 10 | M4 | 15.896673 | 16.061044 | 16.096168 / 16.275215 | 2.091811 | NaN | 0.976196 | 0.0238039 |

### Directional symmetry and growth

Asymmetry below is `|positive-negative| / mean(|positive|,|negative|)` for paired ±2%, ±5%, and ±10% levels. Zero means perfect magnitude symmetry; no symmetry threshold was preregistered.

| Algorithm | RMSE-norm asymmetry at 2/5/10% (%) | |B-error| asymmetry at 2/5/10% (%) | mean RMSE norm 2→10% (pF) | M3 max gate | M4 mean-g range | M4 max USR |
|---|---:|---:|---:|---:|---:|---:|
| M0 | 11.617 / 6.970 / 3.751 | 1.639 / 3.935 / 6.887 | 5.825141 → 22.921693 | NaN | N/A | NaN |
| M2 | 1.348 / 2.206 / 40.177 | 3.639 / 65.006 / 136.605 | 4.529355 → 18.817273 | NaN | N/A | NaN |
| M3 | 1.348 / 2.206 / 40.177 | 3.639 / 65.006 / 136.605 | 4.529355 → 18.817273 | 0 | N/A | NaN |
| M4 | 1.350 / 2.201 / 40.179 | 3.516 / 64.316 / 136.345 | 4.529626 → 18.817486 | NaN | 0.975056–0.992168 | 0.0249441 |

- M0: tracking-error norm spans 5.486784–23.351630 pF; maximum |B fundamental error| is 10.951678% at -10% mismatch.
- M2: tracking-error norm spans 4.498829–22.597391 pF; maximum |B fundamental error| is 11.052887% at -10% mismatch.
- M3: tracking-error norm spans 4.498829–22.597391 pF; maximum |B fundamental error| is 11.052887% at -10% mismatch.
- M4: tracking-error norm spans 4.499057–22.597817 pF; maximum |B fundamental error| is 11.052887% at -10% mismatch.

Interpretation: paired-direction asymmetry, error growth, any M3 gate activity, and M4 suppression are reported directly above. No pass/fail accuracy threshold was preregistered, so the outer ±10% points are observed validity-boundary evidence rather than a newly declared operating limit.

## 4. Unmodelled CsAC coupling results

Completed **4/4** conditions and **16/16** evaluations. Injection remained `iA=CsAC(duA-duC)`, `iB=0`, `iC=CsAC(duC-duA)` and occurred before sigma/noise generation.

| Condition | Level | Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | Cs1/Cs2 max abs (pF) | B fundamental err (%) | M3 gate ratio | M4 mean g | M4 USR |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|
| `P2_AC_005` | 0.5 | M0 | 2.859720 | 2.298865 | 3.890338 / 3.099492 | 8.947272 | NaN | NaN | NaN |
| `P2_AC_005` | 0.5 | M2 | 0.115708 | 0.185708 | 0.278951 / 0.369254 | 0.356360 | NaN | NaN | NaN |
| `P2_AC_005` | 0.5 | M3 | 0.115708 | 0.185708 | 0.278951 / 0.369254 | 0.356360 | 0 | NaN | NaN |
| `P2_AC_005` | 0.5 | M4 | 0.118391 | 0.188206 | 0.288128 / 0.371533 | 0.366349 | NaN | 0.975069 | 0.024931 |
| `P2_AC_010` | 1 | M0 | 2.776706 | 2.385288 | 3.790374 / 3.199474 | 8.940399 | NaN | NaN | NaN |
| `P2_AC_010` | 1 | M2 | 0.148494 | 0.277800 | 0.283756 / 0.469307 | 0.362941 | NaN | NaN | NaN |
| `P2_AC_010` | 1 | M3 | 0.148494 | 0.277800 | 0.283756 / 0.469307 | 0.362941 | 0 | NaN | NaN |
| `P2_AC_010` | 1 | M4 | 0.148950 | 0.280346 | 0.283194 / 0.471563 | 0.372905 | NaN | 0.97513 | 0.0248702 |
| `P2_AC_020` | 2 | M0 | 2.614240 | 2.561098 | 3.590446 / 3.399438 | 8.940485 | NaN | NaN | NaN |
| `P2_AC_020` | 2 | M2 | 0.315349 | 0.471661 | 0.484164 / 0.669413 | 0.391118 | NaN | NaN | NaN |
| `P2_AC_020` | 2 | M3 | 0.315349 | 0.471661 | 0.484164 / 0.669413 | 0.391118 | 0 | NaN | NaN |
| `P2_AC_020` | 2 | M4 | 0.314034 | 0.474200 | 0.483601 / 0.671623 | 0.401028 | NaN | 0.975264 | 0.0247358 |
| `P2_AC_030` | 3 | M0 | 2.457304 | 2.740222 | 3.390518 / 3.599401 | 8.959011 | NaN | NaN | NaN |
| `P2_AC_030` | 3 | M2 | 0.506886 | 0.669065 | 0.684572 / 0.869519 | 0.439299 | NaN | NaN | NaN |
| `P2_AC_030` | 3 | M3 | 0.506886 | 0.669065 | 0.684572 / 0.869519 | 0.439299 | 0 | NaN | NaN |
| `P2_AC_030` | 3 | M4 | 0.505148 | 0.671591 | 0.684010 / 0.871681 | 0.449149 | NaN | 0.975411 | 0.0245891 |

### Structural-bias audit

| Algorithm | corr(CsAC,Cs1 RMSE) | corr(CsAC,Cs2 RMSE) | more affected side at 3 pF | RMSE norm 0.5→3 pF | |B error| 0.5→3 pF (%) | M3 max gate | M4 mean-g range |
|---|---:|---:|---|---:|---:|---:|---:|
| M0 | -0.999938 | 0.999978 | Cs2 | 3.669166 → 3.680647 | 8.947272 → 8.959011 | NaN | N/A |
| M2 | 0.991635 | 0.999934 | Cs2 | 0.218805 → 0.839394 | 0.356360 → 0.439299 | NaN | N/A |
| M3 | 0.991635 | 0.999934 | Cs2 | 0.218805 → 0.839394 | 0.356360 → 0.439299 | 0 | N/A |
| M4 | 0.990900 | 0.999935 | Cs2 | 0.222346 → 0.840362 | 0.366349 → 0.449149 | NaN | 0.975069–0.975411 |

At 3 pF, RMSE norms are M2 0.839394 pF, M3 0.839394 pF, and M4 0.840362 pF; M4 mean update weight is 0.975411 and USR is 0.024589. These values distinguish weighting response from residual model bias; they do not establish universal mismatch robustness.

## 5. Completeness, negative results, and structural failures

Registry matches: **40/40**; shared-data checks: **40/40**; numerical failures: **0**; metric-missing rows: **0**.

No execution-level structural failure was observed. Large errors, asymmetric response, gate activation, and suppression remain performance evidence and were not reclassified as numerical failures.

This report does **not** claim that M4 is generally robust to model mismatch. Conclusions are limited to the frozen levels and the observed data above.

## 6. Final status

STEP 3 STATUS:
**PASS**

CSELF CONDITIONS COMPLETE:
**6 / 6**

CSELF EVALUATIONS COMPLETE:
**24 / 24**

GENERIC ZERO PATH REGRESSION:
**PASS**

CSAC CONDITIONS COMPLETE:
**4 / 4**

CSAC EVALUATIONS COMPLETE:
**16 / 16**

NUMERICAL FAILURES:
**0**

FROZEN SOURCE MODIFIED:
**NO**

READY FOR STEP 4:
**YES**
