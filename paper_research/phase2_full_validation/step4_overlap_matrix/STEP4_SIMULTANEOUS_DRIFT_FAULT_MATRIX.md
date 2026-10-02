# Phase 2 Step 4 — Simultaneous Drift + Fault Matrix

## 1. Scope and execution discipline

The frozen Step 4 matrix completed **13/13 physical points** and **52/52 MAIN condition-by-algorithm records**. The execution contains **46/46 NEW_RUN** records and six exact M2/M3/M4 anchor reuses from frozen Case07/08.

No M0/M2/M3/M4 formula, parameter, gate threshold, registry, AutoComp9 source, Phase 1 result, or evaluation window was changed. Each physical point used one matched F/CF data pair shared by all four algorithms. Negative results are retained.

Signed movement vectors use one declared interval for the whole matrix: the last sample before W0 end to the last sample before W2 end. Memory metrics use W4; post-fault AUC spans fault clear to W4 end. The 2x W3 interval remains `N/A_BY_DESIGN`.

## 2. Integrity and completeness

PRE integrity: Phase 1 **9/9**, Step 1 **3/3**. POST integrity: Phase 1 **9/9**, Step 1 **3/3**. PRE/POST unchanged: **PASS**.

Registry matches: **52/52**; shared-data checks: **52/52**; numerical failures: **0**; metric-missing MAIN rows: **0**.

## 3. Core D1 rate × fault-factor matrix

Combined W1+W2 parameter error is the frozen overlap tracking quantity. Retention remains separately reported for W1 and W2.

| Condition | Rate | Factor | Algorithm | Cs RMSE norm (pF) | W1 retention | W2 retention | F-CF signed (Cs1, Cs2) pF | F-CF norm (pF) | M3 gate ratio | M4 mean g |
|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|
| `P2_OV_R05_F110` | 0.5 | 1.10 | M0 | 2.269693 | 0.999803 | 0.999814 | 0.000000, 0.000000 | 0.000000 | NaN | NaN |
| `P2_OV_R05_F110` | 0.5 | 1.10 | M2 | 0.869916 | 0.683073 | 0.661824 | 0.839104, -0.827921 | 1.178791 | NaN | NaN |
| `P2_OV_R05_F110` | 0.5 | 1.10 | M3 | 0.869916 | 0.683073 | 0.661824 | 0.839104, -0.827921 | 1.178791 | 0 | NaN |
| `P2_OV_R05_F110` | 0.5 | 1.10 | M4 | 0.822054 | 0.701205 | 0.672436 | 0.806946, -0.805203 | 1.139963 | NaN | 0.804834 |
| `P2_OV_R05_F130` | 0.5 | 1.30 | M0 | 2.269689 | 0.999832 | 0.999842 | 0.000000, 0.000000 | 0.000000 | NaN | NaN |
| `P2_OV_R05_F130` | 0.5 | 1.30 | M2 | 3.149156 | 0.677409 | 0.664488 | 2.477479, -2.462253 | 3.492935 | NaN | NaN |
| `P2_OV_R05_F130` | 0.5 | 1.30 | M3 | 3.149156 | 0.677409 | 0.664488 | 2.477479, -2.462253 | 3.492935 | 0 | NaN |
| `P2_OV_R05_F130` | 0.5 | 1.30 | M4 | 2.785832 | 0.737153 | 0.681724 | 2.381037, -2.379522 | 3.366224 | NaN | 0.538925 |
| `P2_OV_R05_F160` | 0.5 | 1.60 | M0 | 2.269682 | 0.999862 | 0.999870 | 0.000000, 0.000000 | 0.000000 | NaN | NaN |
| `P2_OV_R05_F160` | 0.5 | 1.60 | M2 | 6.569478 | 0.675776 | 0.665502 | 4.927095, -4.908710 | 6.954976 | NaN | NaN |
| `P2_OV_R05_F160` | 0.5 | 1.60 | M3 | 0.611926 | 0.953534 | 0.963314 | 0.361944, -0.489363 | 0.608671 | 1 | NaN |
| `P2_OV_R05_F160` | 0.5 | 1.60 | M4 | 4.914938 | 0.798780 | 0.716725 | 4.450489, -4.460075 | 6.300724 | NaN | 0.356309 |
| `P2_OV_R10_F110` | 1.0 | 1.10 | M0 | 2.738876 | 0.999755 | 0.999637 | 0.000000, 0.000000 | 0.000000 | NaN | NaN |
| `P2_OV_R10_F110` | 1.0 | 1.10 | M2 | 0.965714 | 0.662421 | 0.661107 | 0.824498, -0.819852 | 1.162736 | NaN | NaN |
| `P2_OV_R10_F110` | 1.0 | 1.10 | M3 | 0.965714 | 0.662421 | 0.661107 | 0.824498, -0.819852 | 1.162736 | 0 | NaN |
| `P2_OV_R10_F110` | 1.0 | 1.10 | M4 | 0.918254 | 0.681731 | 0.669270 | 0.805950, -0.805776 | 1.139663 | NaN | 0.819242 |
| `P2_AN_C07` | 1.0 | 1.30 | M0 | 2.738899 | 0.999790 | 0.999689 | 0.000000, 0.000000 | 0.000000 | NaN | NaN |
| `P2_AN_C07` | 1.0 | 1.30 | M2 | 3.272333 | 0.665120 | 0.663952 | 2.458234, -2.451316 | 3.471580 | NaN | NaN |
| `P2_AN_C07` | 1.0 | 1.30 | M3 | 3.272333 | 0.665120 | 0.663952 | 2.458234, -2.451316 | 3.471580 | 0 | NaN |
| `P2_AN_C07` | 1.0 | 1.30 | M4 | 2.948511 | 0.717784 | 0.678576 | 2.372714, -2.381607 | 3.361819 | NaN | 0.545523 |
| `P2_AN_C08` | 1.0 | 1.60 | M0 | 2.738899 | 0.999828 | 0.999745 | 0.000000, 0.000000 | 0.000000 | NaN | NaN |
| `P2_AN_C08` | 1.0 | 1.60 | M2 | 6.705849 | 0.668541 | 0.664987 | 4.906548, -4.897775 | 6.932706 | NaN | NaN |
| `P2_AN_C08` | 1.0 | 1.60 | M3 | 0.573670 | 0.958049 | 0.977429 | 0.023367, -0.423509 | 0.424153 | 1 | NaN |
| `P2_AN_C08` | 1.0 | 1.60 | M4 | 5.199996 | 0.781123 | 0.709523 | 4.512210, -4.542482 | 6.402670 | NaN | 0.360041 |
| `P2_OV_R20_F110` | 2.0 | 1.10 | M0 | 3.254772 | 0.999621 | 0.999300 | 0.000000, 0.000000 | 0.000000 | NaN | NaN |
| `P2_OV_R20_F110` | 2.0 | 1.10 | M2 | 0.756458 | 0.650852 | 0.662642 | 0.814801, -0.815033 | 1.152467 | NaN | NaN |
| `P2_OV_R20_F110` | 2.0 | 1.10 | M3 | 0.756458 | 0.650852 | 0.662642 | 0.814801, -0.815033 | 1.152467 | 0 | NaN |
| `P2_OV_R20_F110` | 2.0 | 1.10 | M4 | 0.695747 | 0.676902 | 0.674690 | 0.778126, -0.791200 | 1.109719 | NaN | 0.820334 |
| `P2_OV_R20_F130` | 2.0 | 1.30 | M0 | 3.254776 | 0.999675 | 0.999400 | 0.000000, 0.000000 | 0.000000 | NaN | NaN |
| `P2_OV_R20_F130` | 2.0 | 1.30 | M2 | 3.048463 | 0.661442 | 0.664456 | 2.447784, -2.445716 | 3.460228 | NaN | NaN |
| `P2_OV_R20_F130` | 2.0 | 1.30 | M3 | 3.048463 | 0.661442 | 0.664456 | 2.447784, -2.445716 | 3.460228 | 0 | NaN |
| `P2_OV_R20_F130` | 2.0 | 1.30 | M4 | 2.608869 | 0.733736 | 0.687012 | 2.329961, -2.350347 | 3.309509 | NaN | 0.547831 |
| `P2_OV_R20_F160` | 2.0 | 1.60 | M0 | 3.254781 | 0.999733 | 0.999506 | 0.000000, 0.000000 | 0.000000 | NaN | NaN |
| `P2_OV_R20_F160` | 2.0 | 1.60 | M2 | 6.470457 | 0.666551 | 0.665392 | 4.896787, -4.890745 | 6.920832 | NaN | NaN |
| `P2_OV_R20_F160` | 2.0 | 1.60 | M3 | 1.042094 | 1.009055 | 1.037872 | -1.112328, 0.506523 | 1.222228 | 1 | NaN |
| `P2_OV_R20_F160` | 2.0 | 1.60 | M4 | 4.619053 | 0.798574 | 0.728540 | 4.283797, -4.363260 | 6.114651 | NaN | 0.359903 |

Rate effect (mean across D1 fault factors where registered):

| Rate | Algorithm | mean Cs error norm (pF) | mean W1 retention | mean W2 retention |
|---:|---|---:|---:|---:|
| 0.5 | M0 | 2.269688 | 0.999832 | 0.999842 |
| 0.5 | M2 | 3.529517 | 0.678753 | 0.663938 |
| 0.5 | M3 | 1.543666 | 0.771339 | 0.763208 |
| 0.5 | M4 | 2.840942 | 0.745712 | 0.690295 |
| 1.0 | M0 | 2.738891 | 0.999791 | 0.999690 |
| 1.0 | M2 | 3.647965 | 0.665361 | 0.663349 |
| 1.0 | M3 | 1.603906 | 0.761863 | 0.767496 |
| 1.0 | M4 | 3.022254 | 0.726879 | 0.685790 |
| 2.0 | M0 | 3.254776 | 0.999676 | 0.999402 |
| 2.0 | M2 | 3.425126 | 0.659615 | 0.664164 |
| 2.0 | M3 | 1.615672 | 0.773783 | 0.788323 |
| 2.0 | M4 | 2.641223 | 0.736404 | 0.696747 |

M0 has its largest mean overlap tracking error at **2.0x** (3.254776 pF); the observed rate response is descriptive and is not assumed monotone.  
M2 has its largest mean overlap tracking error at **1.0x** (3.647965 pF); the observed rate response is descriptive and is not assumed monotone.  
M3 has its largest mean overlap tracking error at **2.0x** (1.615672 pF); the observed rate response is descriptive and is not assumed monotone.  
M4 has its largest mean overlap tracking error at **1.0x** (3.022254 pF); the observed rate response is descriptive and is not assumed monotone.  

Fault-amplitude effect at each rate:

- 0.5x: M3 gate ratios at factors 1.10/1.30/1.60 are 0.0000/0.0000/1.0000; M4 mean g values are 0.8048/0.5389/0.3563.
- 1.0x: M3 gate ratios at factors 1.10/1.30/1.60 are 0.0000/0.0000/1.0000; M4 mean g values are 0.8192/0.5455/0.3600.
- 2.0x: M3 gate ratios at factors 1.10/1.30/1.60 are 0.0000/0.0000/1.0000; M4 mean g values are 0.8203/0.5478/0.3599.

## 4. Direction extension D1 / D2 / D3

The direction extension keeps rate=1 and compares factor 1.30/1.60 without expanding to a full direction×rate×factor grid.

| Direction | Factor | Algorithm | True signed drift (Cs1, Cs2) pF | F movement (Cs1, Cs2) pF | CF movement (Cs1, Cs2) pF | F-CF (Cs1, Cs2) pF | Error norm (pF) |
|---|---:|---|---:|---:|---:|---:|---:|
| D1 | 1.30 | M0 | 1.261906, -0.841270 | 0.000000, 0.000000 | 0.000000, 0.000000 | 0.000000, 0.000000 | 2.738899 |
| D1 | 1.30 | M2 | 1.261906, -0.841270 | 3.729765, -3.353452 | 1.271531, -0.902136 | 2.458234, -2.451316 | 3.272333 |
| D1 | 1.30 | M3 | 1.261906, -0.841270 | 3.729765, -3.353452 | 1.271531, -0.902136 | 2.458234, -2.451316 | 3.272333 |
| D1 | 1.30 | M4 | 1.261906, -0.841270 | 3.644208, -3.283218 | 1.271494, -0.901611 | 2.372714, -2.381607 | 2.948511 |
| D1 | 1.60 | M0 | 1.261906, -0.841270 | 0.000000, 0.000000 | 0.000000, 0.000000 | 0.000000, 0.000000 | 2.738899 |
| D1 | 1.60 | M2 | 1.261906, -0.841270 | 6.178078, -5.799911 | 1.271531, -0.902136 | 4.906548, -4.897775 | 6.705849 |
| D1 | 1.60 | M3 | 1.261906, -0.841270 | 1.294898, -1.325644 | 1.271531, -0.902136 | 0.023367, -0.423509 | 0.573670 |
| D1 | 1.60 | M4 | 1.261906, -0.841270 | 5.783704, -5.444093 | 1.271494, -0.901611 | 4.512210, -4.542482 | 5.199996 |
| D2 | 1.30 | M0 | -1.261906, 0.841270 | 0.000000, 0.000000 | 0.000000, 0.000000 | 0.000000, 0.000000 | 2.717629 |
| D2 | 1.30 | M2 | -1.261906, 0.841270 | 1.157620, -1.671689 | -1.285134, 0.763482 | 2.442754, -2.435171 | 3.625331 |
| D2 | 1.30 | M3 | -1.261906, 0.841270 | 1.157620, -1.671689 | -1.285134, 0.763482 | 2.442754, -2.435171 | 3.625331 |
| D2 | 1.30 | M4 | -1.261906, 0.841270 | 1.163265, -1.635250 | -1.282537, 0.762570 | 2.445803, -2.397821 | 3.359041 |
| D2 | 1.60 | M0 | -1.261906, 0.841270 | 0.000000, 0.000000 | 0.000000, 0.000000 | 0.000000, 0.000000 | 2.717624 |
| D2 | 1.60 | M2 | -1.261906, 0.841270 | 3.585944, -4.104895 | -1.285185, 0.763477 | 4.871128, -4.868372 | 7.008894 |
| D2 | 1.60 | M3 | -1.261906, 0.841270 | 0.443479, -0.648537 | -1.285185, 0.763477 | 1.728664, -1.412014 | 2.138710 |
| D2 | 1.60 | M4 | -1.261906, 0.841270 | 3.260048, -3.712206 | -1.282589, 0.762567 | 4.542637, -4.474772 | 5.592362 |
| D3 | 1.30 | M0 | 1.261906, 0.841270 | 0.000000, 0.000000 | 0.000000, 0.000000 | 0.000000, 0.000000 | 2.762632 |
| D3 | 1.30 | M2 | 1.261906, 0.841270 | 3.697702, -1.632666 | 1.248751, 0.794697 | 2.448950, -2.427363 | 3.405292 |
| D3 | 1.30 | M3 | 1.261906, 0.841270 | 3.697702, -1.632666 | 1.248751, 0.794697 | 2.448950, -2.427363 | 3.405292 |
| D3 | 1.30 | M4 | 1.261906, 0.841270 | 3.592613, -1.622743 | 1.248537, 0.793750 | 2.344075, -2.416494 | 3.125155 |
| D3 | 1.60 | M0 | 1.261906, 0.841270 | 0.000000, 0.000000 | 0.000000, 0.000000 | 0.000000, 0.000000 | 2.762646 |
| D3 | 1.60 | M2 | 1.261906, 0.841270 | 6.144582, -4.068178 | 1.248720, 0.794694 | 4.895862, -4.862872 | 6.821260 |
| D3 | 1.60 | M3 | 1.261906, 0.841270 | 1.242059, -0.856944 | 1.248720, 0.794694 | -0.006661, -1.651638 | 1.615532 |
| D3 | 1.60 | M4 | 1.261906, 0.841270 | 5.722094, -3.826753 | 1.248505, 0.793749 | 4.473589, -4.620501 | 5.476376 |

M2 shows fault-induced movement opposite to the true drift vector in 2/6 direction-extension rows: `P2_DD_D2_F130`, `P2_DD_D2_F160`.  
M3 shows fault-induced movement opposite to the true drift vector in 3/6 direction-extension rows: `P2_DD_D2_F130`, `P2_DD_D2_F160`, `P2_DD_D3_F160`.  
M4 shows fault-induced movement opposite to the true drift vector in 2/6 direction-extension rows: `P2_DD_D2_F130`, `P2_DD_D2_F160`.  

## 5. M3 hard gate and M4 continuous weighting

M3 does not trigger in **8/13** points: `P2_OV_R05_F110`, `P2_OV_R05_F130`, `P2_OV_R10_F110`, `P2_AN_C07`, `P2_OV_R20_F110`, `P2_OV_R20_F130`, `P2_DD_D2_F130`, `P2_DD_D3_F130`.  
When triggered, M3 overlap hard-gate activity spans **1.0000–1.0000** and parameter-error RMS norm spans **0.573670–2.138710 pF**. This preserves both fault protection and the possible loss of real drift learning under hard freeze.  
M4 mean update weight spans **0.356309–0.820334** across the registered matrix. It remains continuous where observed, but a nonzero weight does not by itself prove correct drift separation.  

Rate-limit and projection activity are diagnostics, not scores. Their per-row counts are preserved in the CSV when the frozen cycle trace makes them available; exact-reuse M2 anchors do not contain a saved M2 cycle table and therefore retain `NaN` for these optional fields.

## 6. Case08 protection-schedule counterfactual replay

| Algorithm | max c(t) diff | max irB diff (A) | final Cs diff | schedule diff | state diff | Pass |
|---|---:|---:|---:|---:|---:|---|
| M3 | 0 | 0 | 0 | 0 | NaN | PASS |
| M4 | 0 | 0 | 0 | 0 | 0 | PASS |

The equivalence gate passed at the existing `1e-12` numerical tolerance. P and A were then generated by the independent replay wrapper; no frozen source was edited.

| Algorithm | F-N signed/norm (pF) | F-A signed/norm | A-P signed/norm | P-N signed/norm | identity residual (pF) |
|---|---:|---:|---:|---:|---:|
| M3 | 0.023367, -0.423509 / 0.424153 | 0.915123, -0.981061 / 1.341615 | 0.032228, -0.055821 / 0.064456 | -0.923983, 0.613373 / 1.109041 | 0 |
| M4 | 4.512210, -4.542482 / 6.402670 | 4.575018, -4.578660 / 6.472628 | 0.175127, -0.121210 / 0.212982 | -0.237935, 0.157388 / 0.285279 | 0 |

Operational interpretation only: F-A is the remaining direct fault-related contribution under a matched adaptation schedule; A-P is the VFF/adaptation-schedule contribution; P-N is the protection-induced loss of true-drift learning. This is not perfect causal identification.

## 7. Evidence balance and limitations

Across the 13 points, M4 has lower mean absolute W1/W2 retention error than M2 in **13/13**, lower overlap tracking error than M3 in **8/13**, lower F-CF movement norm than M2 in **13/13**, and lower F-CF movement norm than M3 in **8/13**.  
The complementary rows are formal limitations: continuous weighting can retain more drift learning than hard freeze, but it can also retain fault-related model bias. M3 threshold misses and hard-freeze costs are both reported rather than repaired by tuning.  

No claim is made that M4 is universally best. `||Δc_CF||/||Δc_F||` is not computed or used as purity, and no composite score is created. Performance errors are not reclassified as numerical failures.

## 8. Final status

STEP 4 STATUS:
**PASS**

OVERLAP PHYSICAL POINTS:
**13 / 13**

MAIN EVALUATION RECORDS:
**52 / 52**

NEW ALGORITHM RUNS COMPLETE:
**46 / 46**

NUMERICAL FAILURES:
**0**

METRIC-MISSING ROWS:
**0**

REPLAY_EQUIVALENCE_GATE:
**PASS**

COUNTERFACTUAL REPLAY:
**COMPLETE**

FROZEN SOURCE MODIFIED:
**NO**

READY FOR STEP 5:
**YES**
