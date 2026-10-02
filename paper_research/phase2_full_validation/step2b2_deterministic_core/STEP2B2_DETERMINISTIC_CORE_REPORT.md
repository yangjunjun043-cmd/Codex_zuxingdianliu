# Phase 2 Step 2B-2 — Full Deterministic Core Report

## 1. Scope and execution completeness

The frozen `PHASE2_REGISTRY_V1` selected **25/25** new physical conditions and **100/100** registered M0/M2/M3/M4 evaluations completed.

The batch contains Fault amplitude (10), SNR (3), reference phase (5), third-harmonic amplitude (4), and negative sequence (3). Frozen nominal anchors were reused conceptually and were not re-simulated or duplicated in the 100-row dataset.

Cself mismatch, CsAC mismatch, overlap rate/direction, replay, sensitivity variants, and Monte Carlo were not executed.

## 2. Registry, shared-data, and frozen-integrity audit

Registry mapping: **100/100**; shared-data signature: **100/100**; required metrics: **100/100**.

PRE integrity: Phase 1 9/9 and Step 1 3/3. POST integrity: Phase 1 9/9 and Step 1 3/3. PRE/POST unchanged: **PASS**.

Each condition generated one physical data realization. Its four algorithms shared truth, Cs trajectory, fault waveform, voltage, noise, reconstructed reference, windows, and time axis.

## 3. Numerical and metric failure audit

Numerical failures: **0**. Metric-missing rows: **0**.

Algorithm performance was never used as a numerical-failure criterion. All adverse results remain in the CSV.

## 4. Fault-amplitude chain

The table links severity to M3 gate response, M4 update weight, retention, and signed fault-induced parameter bias.

| Family | Factor | M2 retention err (%) | M2 bias norm (pF) | M3 gate ratio | M3 latency (s) | M3 retention err (%) | M4 mean g | M4 retention err (%) | M4 ΔCs1/ΔCs2 (pF) | M4 bias norm (pF) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| fault_only | 1.050 | -1.476828 | 0.572178 | 0.000000 | NaN | -1.476828 | 0.914286 | -1.456178 | 0.397498 / -0.401101 | 0.564701 |
| drift_then_fault | 1.050 | -1.440639 | 0.570547 | 0.000000 | NaN | -1.440639 | 0.916643 | -1.420492 | 0.399698 / -0.398773 | 0.564605 |
| fault_only | 1.100 | -2.931023 | 1.150407 | 0.000000 | NaN | -2.931023 | 0.836453 | -2.891230 | 0.799527 / -0.806032 | 1.135311 |
| drift_then_fault | 1.100 | -2.888989 | 1.148499 | 0.000000 | NaN | -2.888989 | 0.839727 | -2.852546 | 0.804627 / -0.801963 | 1.136032 |
| fault_only | 1.200 | -5.465638 | 2.302632 | 0.000000 | NaN | -5.465638 | 0.705819 | -5.385549 | 1.599585 / -1.609897 | 2.269458 |
| drift_then_fault | 1.200 | -5.414675 | 2.300711 | 0.000000 | NaN | -5.414675 | 0.708451 | -5.343819 | 1.609939 / -1.604224 | 2.272760 |
| fault_only | 1.300 | -7.608853 | 3.454206 | 0.000000 | NaN | -7.608853 | 0.539424 | -7.464005 | 2.389109 / -2.403899 | 3.389185 |
| drift_then_fault | 1.300 | -7.550766 | 3.452473 | 0.000000 | NaN | -7.550766 | 0.540630 | -7.416567 | 2.403131 / -2.396266 | 3.393690 |
| fault_only | 1.400 | -9.446237 | 4.605949 | 0.960000 | 0.05998 | -0.736265 | 0.464954 | -9.245748 | 3.180237 / -3.196419 | 4.508991 |
| drift_then_fault | 1.400 | -9.381874 | 4.604328 | 0.960000 | 0.05998 | -0.661400 | 0.465875 | -9.187117 | 3.193245 / -3.187235 | 4.511683 |

M3 gate not triggered: `P2_FA_FO_105`, `P2_FA_DF_105`, `P2_FA_FO_110`, `P2_FA_DF_110`, `P2_FA_FO_120`, `P2_FA_DF_120`, `P2_FA_FO_130`, `P2_FA_DF_130`.

M3 gate triggered: `P2_FA_FO_140`, `P2_FA_DF_140`.

M4 continuous-response audit: Case05_fault_only: mean g is nonincreasing (r=-0.9937); Case06_drift_then_fault: mean g is nonincreasing (r=-0.9937). Monotonicity is descriptive, not required.

M2 severity audit: Case05_fault_only: M2 bias norm is nondecreasing (r=1.0000); Case06_drift_then_fault: M2 bias norm is nondecreasing (r=1.0000).

M4 versus M2: lower absolute retention error in 10/10 rows and lower fault-induced bias norm in 10/10 rows.

M4 versus M3: lower absolute retention error in 8/10 rows and lower fault-induced bias norm in 8/10 rows. The complementary rows are the observed M4 cost; no threshold was retuned.

M4 ISR-J/ISR-h are retained for fault rows when available. **ISR is rejected cycle information and is not equal to final parameter-bias reduction.**

## 5. Noise / SNR

| Condition | Level | Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | Cs1/Cs2 max abs (pF) | B fundamental err (%) | M3 gate ratio | M4 mean g | M4 USR |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|
| `P2_SN_INF` | Inf | M0 | 2.950111 | 2.215882 | 3.997774 / 3.002226 | 8.973791 | NaN | NaN | NaN |
| `P2_SN_INF` | Inf | M2 | 0.179380 | 0.134941 | 0.311484 / 0.234940 | 0.504811 | NaN | NaN | NaN |
| `P2_SN_INF` | Inf | M3 | 0.179380 | 0.134941 | 0.311484 / 0.234940 | 0.504811 | 0 | NaN | NaN |
| `P2_SN_INF` | Inf | M4 | 0.179389 | 0.134947 | 0.311518 / 0.234965 | 0.504833 | NaN | 0.999965 | 3.48612e-05 |
| `P2_SN_40` | 40 | M0 | 2.948111 | 2.215155 | 3.995411 / 3.001367 | 8.969029 | NaN | NaN | NaN |
| `P2_SN_40` | 40 | M2 | 0.174804 | 0.126337 | 0.333698 / 0.233997 | 0.476634 | NaN | NaN | NaN |
| `P2_SN_40` | 40 | M3 | 0.174804 | 0.126337 | 0.333698 / 0.233997 | 0.476634 | 0 | NaN | NaN |
| `P2_SN_40` | 40 | M4 | 0.175762 | 0.127059 | 0.337214 / 0.235141 | 0.479281 | NaN | 0.991927 | 0.00807269 |
| `P2_SN_20` | 20 | M0 | 2.930134 | 2.208613 | 3.974148 / 2.993640 | 8.926440 | NaN | NaN | NaN |
| `P2_SN_20` | 20 | M2 | 0.244349 | 0.278381 | 0.647633 / 0.791342 | -0.051524 | NaN | NaN | NaN |
| `P2_SN_20` | 20 | M3 | 0.244349 | 0.278381 | 0.647633 / 0.791342 | -0.051524 | 0 | NaN | NaN |
| `P2_SN_20` | 20 | M4 | 0.244532 | 0.266269 | 0.668886 / 0.762179 | -0.007319 | NaN | 0.925645 | 0.0743546 |

SNR descriptive audit: M0 |B error| spans 8.926440% to 8.973791% over Inf,40,20 dB; M2 |B error| spans 0.051524% to 0.504811% over Inf,40,20 dB; M3 |B error| spans 0.051524% to 0.504811% over Inf,40,20 dB; M4 |B error| spans 0.007319% to 0.504833% over Inf,40,20 dB. Tracking RMSE and M3/M4 protection behavior are retained in the table.

## 6. Reference-phase sensitivity

| Condition | Level | Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | Cs1/Cs2 max abs (pF) | B fundamental err (%) | M3 gate ratio | M4 mean g | M4 USR |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|
| `P2_PE_033` | 0.33 | M0 | 0.041474 | 0.194373 | 0.041474 / 0.194373 | 4.703792 | NaN | NaN | NaN |
| `P2_PE_033` | 0.33 | M2 | 2.549731 | 2.681177 | 4.946443 / 5.110086 | -0.002258 | NaN | NaN | NaN |
| `P2_PE_033` | 0.33 | M3 | 0.238011 | 0.403790 | 0.407102 / 0.704765 | 4.336837 | 0.96 | NaN | NaN |
| `P2_PE_033` | 0.33 | M4 | 2.272469 | 2.393935 | 4.875188 / 5.011858 | 0.691394 | NaN | 0.370547 | NaN |
| `P2_PE_050` | 0.5 | M0 | 0.078304 | 0.265357 | 0.078304 / 0.265357 | 7.193614 | NaN | NaN | NaN |
| `P2_PE_050` | 0.5 | M2 | 2.522772 | 2.730668 | 4.894666 / 5.196060 | 2.487402 | NaN | NaN | NaN |
| `P2_PE_050` | 0.5 | M3 | 0.229610 | 0.459741 | 0.368504 / 0.777557 | 6.826487 | 0.96 | NaN | NaN |
| `P2_PE_050` | 0.5 | M4 | 2.253876 | 2.448563 | 4.825510 / 5.101432 | 3.165249 | NaN | 0.375591 | NaN |
| `P2_PE_100` | 1 | M0 | 0.195297 | 0.482792 | 0.195297 / 0.482792 | 14.511089 | NaN | NaN | NaN |
| `P2_PE_100` | 1 | M2 | 2.441623 | 2.888233 | 4.733461 / 5.457326 | 9.804686 | NaN | NaN | NaN |
| `P2_PE_100` | 1 | M3 | 0.242454 | 0.650361 | 0.332868 / 1.000292 | 14.143470 | 0.96 | NaN | NaN |
| `P2_PE_100` | 1 | M4 | 2.196177 | 2.621191 | 4.669791 / 5.373104 | 10.438460 | NaN | 0.390845 | NaN |
| `P2_PE_200` | 2 | M0 | 0.468065 | 0.956374 | 0.468065 / 0.956374 | 29.119424 | NaN | NaN | NaN |
| `P2_PE_200` | 2 | M2 | 2.277795 | 3.257257 | 4.371139 / 6.017417 | 24.413970 | NaN | NaN | NaN |
| `P2_PE_200` | 2 | M3 | 0.426483 | 1.102450 | 0.605959 / 1.484409 | 28.750895 | 0.96 | NaN | NaN |
| `P2_PE_200` | 2 | M4 | 2.076478 | 3.020148 | 4.316103 / 5.949090 | 24.968106 | NaN | 0.422319 | NaN |
| `P2_PE_300` | 3 | M0 | 0.792475 | 1.481447 | 0.792475 / 1.481447 | 43.688621 | NaN | NaN | NaN |
| `P2_PE_300` | 3 | M2 | 2.130314 | 3.697132 | 3.955697 / 6.627431 | 38.985962 | NaN | NaN | NaN |
| `P2_PE_300` | 3 | M3 | 0.725157 | 1.620016 | 0.930648 / 2.019931 | 43.319289 | 0.96 | NaN | NaN |
| `P2_PE_300` | 3 | M4 | 1.971257 | 3.488172 | 3.907046 / 6.570501 | 39.471293 | NaN | 0.453753 | NaN |

Reference-phase sensitivity: M0 |B error| 4.703792% at 0.33 deg -> 43.688621% at 3.00 deg; M2 |B error| 0.002258% at 0.33 deg -> 38.985962% at 3.00 deg; M3 |B error| 4.336837% at 0.33 deg -> 43.319289% at 3.00 deg; M4 |B error| 0.691394% at 0.33 deg -> 39.471293% at 3.00 deg. Rapid growth, non-monotonicity, or gate activity is preserved as observed.

This is sensitivity to the frozen coherent reference-phase model, not complete sensor phase-response validation. Physical voltage, current, fault waveform, and noise remain unchanged within the sweep.

## 7. Third-harmonic amplitude sensitivity

| Condition | Level | Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | Cs1/Cs2 max abs (pF) | B fundamental err (%) | M3 gate ratio | M4 mean g | M4 USR |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|
| `P2_H3_005` | 0.005 | M0 | 2.943814 | 2.213599 | 3.990333 / 2.999530 | 7.783786 | NaN | NaN | NaN |
| `P2_H3_005` | 0.005 | M2 | 0.157537 | 0.108623 | 0.378402 / 0.268856 | 0.309702 | NaN | NaN | NaN |
| `P2_H3_005` | 0.005 | M3 | 0.157537 | 0.108623 | 0.378402 / 0.268856 | 0.309702 | 0 | NaN | NaN |
| `P2_H3_005` | 0.005 | M4 | 0.160466 | 0.110316 | 0.386104 / 0.270682 | 0.316913 | NaN | 0.979422 | 0.0205785 |
| `P2_H3_020` | 0.02 | M0 | 2.943815 | 2.213600 | 3.990335 / 2.999531 | 8.172609 | NaN | NaN | NaN |
| `P2_H3_020` | 0.02 | M2 | 0.157524 | 0.108617 | 0.378442 / 0.268873 | 0.325053 | NaN | NaN | NaN |
| `P2_H3_020` | 0.02 | M3 | 0.157524 | 0.108617 | 0.378442 / 0.268873 | 0.325053 | 0 | NaN | NaN |
| `P2_H3_020` | 0.02 | M4 | 0.160643 | 0.110423 | 0.386602 / 0.270845 | 0.333105 | NaN | 0.978062 | 0.0219378 |
| `P2_H3_080` | 0.08 | M0 | 2.943722 | 2.213542 | 3.990224 / 2.999463 | 9.731670 | NaN | NaN | NaN |
| `P2_H3_080` | 0.08 | M2 | 0.156887 | 0.108304 | 0.379592 / 0.269899 | 0.381920 | NaN | NaN | NaN |
| `P2_H3_080` | 0.08 | M3 | 0.156887 | 0.108304 | 0.379592 / 0.269899 | 0.381920 | 0 | NaN | NaN |
| `P2_H3_080` | 0.08 | M4 | 0.160906 | 0.110621 | 0.390003 / 0.272590 | 0.394248 | NaN | 0.971579 | 0.0284211 |
| `P2_H3_100` | 0.1 | M0 | 2.943656 | 2.213503 | 3.990147 / 2.999417 | 10.221919 | NaN | NaN | NaN |
| `P2_H3_100` | 0.1 | M2 | 0.156476 | 0.108118 | 0.380299 / 0.270544 | 0.397711 | NaN | NaN | NaN |
| `P2_H3_100` | 0.1 | M3 | 0.156476 | 0.108118 | 0.380299 / 0.270544 | 0.397711 | 0 | NaN | NaN |
| `P2_H3_100` | 0.1 | M4 | 0.160843 | 0.110632 | 0.391600 / 0.273528 | 0.411813 | NaN | 0.969104 | 0.0308958 |

Harmonic-amplitude audit: M0 max |B error| 10.221919%, max Cs RMSE norm 3.683215 pF; M2 max |B error| 0.397711%, max Cs RMSE norm 0.191356 pF; M3 max |B error| 0.397711%, max Cs RMSE norm 0.191356 pF; M4 max |B error| 0.411813%, max Cs RMSE norm 0.195263 pF.

Only amplitude was swept; `phi3_deg=0` remained fixed. No harmonic phase sweep was added.

## 8. Negative-sequence validity boundary

| Condition | Level | Algorithm | Cs1 RMSE (pF) | Cs2 RMSE (pF) | Cs1/Cs2 max abs (pF) | B fundamental err (%) | M3 gate ratio | M4 mean g | M4 USR |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|
| `P2_NS_001` | 0.01 | M0 | 4.745878 | 5.068888 | 5.978737 / 6.055262 | 19.859475 | NaN | NaN | NaN |
| `P2_NS_001` | 0.01 | M2 | 2.107472 | 3.093255 | 2.374601 / 3.302518 | 11.062305 | NaN | NaN | NaN |
| `P2_NS_001` | 0.01 | M3 | 2.107472 | 3.093255 | 2.374601 / 3.302518 | 11.062305 | 0 | NaN | NaN |
| `P2_NS_001` | 0.01 | M4 | 2.109986 | 3.095631 | 2.383454 / 3.306563 | 11.072242 | NaN | 0.975674 | 0.0243257 |
| `P2_NS_003` | 0.03 | M0 | 8.719080 | 11.198676 | 10.076603 / 12.261617 | 44.102781 | NaN | NaN | NaN |
| `P2_NS_003` | 0.03 | M2 | 6.223445 | 9.243472 | 6.488798 / 9.485144 | 34.889727 | NaN | NaN | NaN |
| `P2_NS_003` | 0.03 | M3 | 6.223445 | 9.243472 | 6.488798 / 9.485144 | 34.889727 | 0 | NaN | NaN |
| `P2_NS_003` | 0.03 | M4 | 6.225725 | 9.245719 | 6.496961 / 9.488975 | 34.899573 | NaN | 0.976816 | 0.0231839 |
| `P2_NS_005` | 0.05 | M0 | 12.936628 | 17.503944 | 14.341033 / 18.589306 | 71.612823 | NaN | NaN | NaN |
| `P2_NS_005` | 0.05 | M2 | 10.456825 | 15.513423 | 10.771792 / 15.790320 | 61.838893 | NaN | NaN | NaN |
| `P2_NS_005` | 0.05 | M3 | 10.456825 | 15.513423 | 10.771792 / 15.790320 | 61.838893 | 0 | NaN | NaN |
| `P2_NS_005` | 0.05 | M4 | 10.458817 | 15.515512 | 10.779269 / 15.794072 | 61.848248 | NaN | 0.977738 | 0.0222624 |

Negative-sequence boundary: M0 |B error| 19.859475/44.102781/71.612823% at Vneg 0.01/0.03/0.05; M2 |B error| 11.062305/34.889727/61.838893% at Vneg 0.01/0.03/0.05; M3 |B error| 11.062305/34.889727/61.838893% at Vneg 0.01/0.03/0.05; M4 |B error| 11.072242/34.899573/61.848248% at Vneg 0.01/0.03/0.05.

All nonzero conditions retain `NEGATIVE_SEQUENCE_INTERNAL_CONVENTION=UNRESOLVED` and `INTERPRETATION=CONFIGURED_VALIDITY_BOUNDARY_ONLY`. These data are validity-boundary evidence, not a negative-sequence mechanism proof.

## 9. Structural findings and Phase 1C evidence balance

No new execution-level structural failure was found: there was no abort, corrupt result, missing required output, NaN/Inf in core signals, validator failure, or missing applicable metric.

Phase 1C support: M4 improves M2 absolute fault retention in 10/10 registered amplitude rows and reduces M2 fault-induced bias norm in 10/10 rows.

Phase 1C limitation: M4 does not dominate M3; M3 has equal or better absolute retention in 2/10 rows and equal or lower bias norm in 2/10 rows.

The phase and negative-sequence tables preserve large-error cases where present. Therefore the evidence supports the frozen method only within the tested validity region and does not justify a universal-best claim.

## 10. Required questions and authorization

| Required question | Answer |
|---|---|
| 1. 25 physical conditions complete? | 25/25 |
| 2. 100 algorithm evaluations complete? | 100/100 |
| 3. Numerical / metric failures? | 0 / 0 |
| 4. Fault sweep trend? | See Section 4; no monotonicity assumed. |
| 5. M3 threshold misses? | Explicit condition list in Section 4. |
| 6. M4 update weight continuous? | Data-derived result in Section 4. |
| 7. M2 absorption versus severity? | Data-derived result in Section 4. |
| 8. M4 versus M2 preservation stable? | Counts reported in Section 4. |
| 9. M4 versus M3 cost? | Counts reported in Section 4. |
| 10. SNR impact? | Section 5. |
| 11. Reference-phase sensitivity? | Section 6. |
| 12. Harmonic sensitivity? | Section 7. |
| 13. Negative-sequence boundary? | Section 8. |
| 14. New structural failure? | Section 9. |
| 15. Evidence supporting Phase 1C? | Section 9. |
| 16. Evidence limiting Phase 1C? | Section 9. |
| 17. Allow Step 3? | YES |

STEP 2B-2 STATUS: **PASS**

PHYSICAL CONDITIONS COMPLETE: **25 / 25**

ALGORITHM EVALUATIONS COMPLETE: **100 / 100**

NUMERICAL FAILURES: **0**

METRIC-MISSING ROWS: **0**

FROZEN SOURCE MODIFIED: **NO**

FULL DETERMINISTIC CORE COMPLETE: **YES**

READY FOR STEP 3: **YES**
