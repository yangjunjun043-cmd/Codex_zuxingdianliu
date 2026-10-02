# M5 Step4 Deterministic Core Decision Report

## Decision

- **M5_STEP4_STATUS: GO**
- Rows complete: 98 / 98
- Gate A / B / C / D: PASS / PASS / PASS / RETAINED
- Monte Carlo: NOT RUN
- Step5: NOT RUN; this report does not authorize automatic continuation.

## Readiness and provenance

- U1-U5 were required to pass before any M5 performance evaluation.
- Physical simulations: 34 exact calls for 14 registered cases.
- Execution matrix: 98 rows = 24 frozen reuse + 6 frozen-trajectory metrics-only + 68 new tracker rows.
- Registered source hashes PRE/POST: PASS / PASS.

| Readiness gate | Result |
|---|---|
| U1 independent runner | PASS |
| U2 directional identities | PASS |
| U3 A/B physical replay | PASS |
| U4 mixed F/CF signature replay | PASS |
| U5 explicit cycle schemas | PASS |

### Data integrity by physical case

| Case | Signature | Rows sharing signature |
|---|---|---:|
| M5_A1_STATIC | `77F4AEAA2401FE46A05F515E1BC26939F9D0B8057C5E937713F60F9AEE36FC27` | 7 |
| M5_A2_DRIFT_ONLY | `438ED5AA129B4E3514C4DE1E643FA02850362654C5BC2C0A1414E2D8A3C69F54` | 7 |
| M5_B_F105 | `595E8AD53E07039CF6A389E8A0ECB566FE3B257F80254DE5A769AB106135295B` | 7 |
| M5_B_F110 | `26592EE3CF3BAFEF18D7F538CB582E169A211B7DCD3C67F1FE80EF33BD560736` | 7 |
| M5_B_F120 | `5A0F9E464EDC1EA9EC696639BEC9B237D157C7BC23FBB105306C8B25B57450FE` | 7 |
| M5_B_F130 | `6C4FD42E1A78C0BCC614959FA287EF321540804D1B3A10D6252312262349EE99` | 7 |
| M5_B_F140 | `355F6FC94EEB2E727A1D5E2F010628818E05F57BECB02CD63E4734A932C7B134` | 7 |
| M5_B_F160 | `30D0205E9C66B9855556E79F58247DC1F0ABF52B9414CF6D6E12CF2C6962DD46` | 7 |
| M5_C_ORTHOGONAL_F130 | `68FE633857A49DD819FBB3BCA9A676363855B6191CB101B065A71ACD17D8143A` | 7 |
| M5_C_ORTHOGONAL_F160 | `86E30978B35B5D87C831EE81381772C81BE7AA813E9ADA9429E2002BD28B82F6` | 7 |
| M5_C_MIXED_CASE06_F130 | `C5EC0992BE0CDC0737380583256E4199AFF0C119E90902AC93D7BF8BBE6CB3C6` | 7 |
| M5_C_MIXED_CASE06_F160 | `20BE4D99E0075CE916D7895B37272A0A04BFA7DF47320A5B0AD3D7655E3C83B0` | 7 |
| M5_C_PARALLEL_F130 | `B59928B8028985FDFCCE2ACA12947579DB5CEF0C8ACE6475F8D8E25A93968388` | 7 |
| M5_C_PARALLEL_F160 | `FF8FB0C0B9B5DC077D0FC76DA3A543D4A0050BBDF7015F2A9E7E5CF60FC02260` | 7 |

## Block A — sanity tracking

| Case | Algorithm | Tracking RMSE pF | Final Cs1 error pF | Final Cs2 error pF | Final L2 pF |
|---|---|---:|---:|---:|---:|
| M5_A1_STATIC | M2 | 0.0563367856 | 0.0823882675 | -0.00167974519 | 0.0824053892 |
| M5_A1_STATIC | M3 | 0.0563367856 | 0.0823882675 | -0.00167974519 | 0.0824053892 |
| M5_A1_STATIC | M4 | 0.0559134728 | 0.0818712798 | -0.00191915224 | 0.0818937702 |
| M5_A1_STATIC | GH | 0.0563367856 | 0.0823882675 | -0.00167974519 | 0.0824053892 |
| M5_A1_STATIC | GC | 0.0559419294 | 0.0820128292 | -0.00182460463 | 0.0820331234 |
| M5_A1_STATIC | M5_DH | 0.0563367856 | 0.0823882675 | -0.00167974519 | 0.0824053892 |
| M5_A1_STATIC | M5_FULL | 0.0560248246 | 0.0822519578 | -0.00158701837 | 0.0822672669 |
| M5_A2_DRIFT_ONLY | M2 | 0.191114783 | 0.0378888597 | -0.0436339387 | 0.0577882886 |
| M5_A2_DRIFT_ONLY | M3 | 0.191114783 | 0.0378888597 | -0.0436339387 | 0.0577882886 |
| M5_A2_DRIFT_ONLY | M4 | 0.195197474 | 0.0378730988 | -0.0433845587 | 0.0575898563 |
| M5_A2_DRIFT_ONLY | GH | 0.191114783 | 0.0378888597 | -0.0436339387 | 0.0577882886 |
| M5_A2_DRIFT_ONLY | GC | 0.194603629 | 0.0379210343 | -0.0434959537 | 0.0577053103 |
| M5_A2_DRIFT_ONLY | M5_DH | 0.191114783 | 0.0378888597 | -0.0436339387 | 0.0577882886 |
| M5_A2_DRIFT_ONLY | M5_FULL | 0.194553723 | 0.0378360206 | -0.0435886162 | 0.0577194241 |

## Block B — pure-fault protection

| Algorithm | Median abs retention error % | Median fault-induced bias pF |
|---|---:|---:|
| M2 | 6.5372455 | 2.87841873 |
| M3 | 2.20392541 | 0.922209202 |
| M4 | 6.42477725 | 2.82932174 |
| GH | 2.20392541 | 0.922209202 |
| GC | 6.40696762 | 2.82178192 |
| M5_DH | 2.20392541 | 0.920033722 |
| M5_FULL | 6.40975495 | 2.82281498 |

Historical comparison uses exact frozen M2/M3/M4 primary results at all six severities; no historical tracker was rerun. GH/GC/M5-DH/M5-Full share each regenerated physical case.

## Block C — matched overlap geometry

| Case | Algorithm | W1 abs retention | W2 abs retention | Total RMSE pF | Parallel RMSE pF | Perpendicular RMSE pF | Bias pF |
|---|---|---:|---:|---:|---:|---:|---:|
| M5_C_ORTHOGONAL_F130 | GC | 0.283728419 | 0.321221958 | 3.22021725 | 3.20684093 | 0.293207006 | 3.37735595 |
| M5_C_ORTHOGONAL_F130 | M5_FULL | 0.28340553 | 0.320675659 | 3.20356043 | 3.19983902 | 0.154368549 | 3.36495134 |
| M5_C_ORTHOGONAL_F160 | GC | 0.242226573 | 0.302756682 | 5.80456192 | 5.79253336 | 0.373492045 | 6.50745305 |
| M5_C_ORTHOGONAL_F160 | M5_FULL | 0.242376698 | 0.302234092 | 5.78460565 | 5.78352805 | 0.111650131 | 6.47816334 |
| M5_C_MIXED_CASE06_F130 | GC | 0.290751656 | 0.320417879 | 2.9793297 | 2.97879154 | 0.0566252739 | 3.33036024 |
| M5_C_MIXED_CASE06_F130 | M5_FULL | 0.290763821 | 0.320422979 | 2.97925105 | 2.97881081 | 0.0512147904 | 3.33077046 |
| M5_C_MIXED_CASE06_F160 | GC | 0.238668953 | 0.299680847 | 5.47146131 | 5.47093742 | 0.0757145291 | 6.49508726 |
| M5_C_MIXED_CASE06_F160 | M5_FULL | 0.238673694 | 0.299739818 | 5.47194854 | 5.47158687 | 0.0629125469 | 6.49716199 |
| M5_C_PARALLEL_F130 | GC | 0.290678866 | 0.320340468 | 2.97460707 | 2.97450022 | 0.0252122925 | 3.33045045 |
| M5_C_PARALLEL_F130 | M5_FULL | 0.290672247 | 0.320414762 | 2.97532274 | 2.97492045 | 0.0489253848 | 3.33193811 |
| M5_C_PARALLEL_F160 | GC | 0.238355947 | 0.299595861 | 5.46385131 | 5.46381235 | 0.0206352353 | 6.49621693 |
| M5_C_PARALLEL_F160 | M5_FULL | 0.238354396 | 0.299631928 | 5.46460801 | 5.46426429 | 0.0612906426 | 6.49755204 |

Mixed M2/M3/M4 rows are metrics-only calculations from frozen Case07/08 trajectories. Orthogonal/parallel M2/M3/M4 rows are new executions because those physical geometries did not previously exist.

## Gate definitions and outcome

| Gate | Registered decision question | Outcome |
|---|---|---|
| A | M5-Full median pure-fault retention and bias improve over M2 | PASS |
| B | Orthogonal drift perpendicular RMSE is preserved at both severities and improves at least once | PASS |
| C | Mixed-geometry joint regression is absent or directly explained by registered diagnostics | PASS |
| D | All parallel-boundary rows, including negative results, are retained without a performance threshold | RETAINED |

## Matched 2x2 factorial

The strict attribution compares GH, GC, M5-DH, and M5-Full. Interaction is `(M5-Full-GC)-(M5-DH-GH)` for the registered response and bias metric.

| Case | Block | Response metric | Interaction | Bias metric | Interaction |
|---|---|---|---:|---|---:|
| M5_A1_STATIC | A | Cs_tracking_RMSE_pF | 8.28952654e-05 | final_error_L2_pF | 0.000234143445 |
| M5_A2_DRIFT_ONLY | A | Cs_tracking_RMSE_pF | -4.99054428e-05 | final_error_L2_pF | 1.41137913e-05 |
| M5_B_F105 | B | abs_fault_retention_error_pct | 0.000576612946 | Cs_fault_induced_bias_norm_pF | 0.000163033164 |
| M5_B_F110 | B | abs_fault_retention_error_pct | 0.0010706371 | Cs_fault_induced_bias_norm_pF | 0.000326800596 |
| M5_B_F120 | B | abs_fault_retention_error_pct | 0.0022026553 | Cs_fault_induced_bias_norm_pF | 0.000773132 |
| M5_B_F130 | B | abs_fault_retention_error_pct | 0.00337200741 | Cs_fault_induced_bias_norm_pF | 0.00129298627 |
| M5_B_F140 | B | abs_fault_retention_error_pct | 0.00277997281 | Cs_fault_induced_bias_norm_pF | 0.00697823092 |
| M5_B_F160 | B | abs_fault_retention_error_pct | 0.00283048721 | Cs_fault_induced_bias_norm_pF | 0.00656469394 |
| M5_C_ORTHOGONAL_F130 | C | W2_abs_retention_error | -0.000546299148 | RMSE_perp_pF | -0.138838458 |
| M5_C_ORTHOGONAL_F160 | C | W2_abs_retention_error | -0.00269588513 | RMSE_perp_pF | 0.730186669 |
| M5_C_MIXED_CASE06_F130 | C | W2_abs_retention_error | 5.10004143e-06 | RMSE_perp_pF | -0.00541048345 |
| M5_C_MIXED_CASE06_F160 | C | W2_abs_retention_error | -5.47679898e-05 | RMSE_perp_pF | 0.181805783 |
| M5_C_PARALLEL_F130 | C | W2_abs_retention_error | 7.42936032e-05 | RMSE_perp_pF | 0.0237130923 |
| M5_C_PARALLEL_F160 | C | W2_abs_retention_error | 3.2408578e-05 | RMSE_perp_pF | 0.0333903781 |

## Projection, rate, and direction diagnostics

| Case | Algorithm | Rate cycles | Projection cycles | Near-zero cycles | Raw angle deg | Protected angle deg | Post-rate angle deg | Post-projection angle deg |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| M5_A1_STATIC | M5_FULL | 0 | 0 | 0 | 41.945829 | 42.3281515 | 42.3281515 | 42.3281515 |
| M5_A2_DRIFT_ONLY | M5_FULL | 0 | 0 | 0 | 28.8909125 | 29.317596 | 29.317596 | 29.317596 |
| M5_B_F105 | M5_FULL | 0 | 0 | 0 | 41.4004414 | 43.0672471 | 43.0672471 | 43.0672471 |
| M5_B_F110 | M5_FULL | 0 | 0 | 0 | 41.2619748 | 44.49642 | 44.49642 | 44.49642 |
| M5_B_F120 | M5_FULL | 0 | 0 | 0 | 41.1467136 | 47.1613343 | 47.1613343 | 47.1613343 |
| M5_B_F130 | M5_FULL | 0 | 0 | 0 | 41.3249771 | 50.8555399 | 50.8555399 | 50.8555399 |
| M5_B_F140 | M5_FULL | 0 | 0 | 0 | 40.1770028 | 51.5815886 | 51.5815886 | 51.5815886 |
| M5_B_F160 | M5_FULL | 0 | 0 | 0 | 34.5441079 | 49.9204902 | 49.9204902 | 49.9204902 |
| M5_C_ORTHOGONAL_F130 | M5_FULL | 0 | 0 | 0 | 32.6325441 | 43.8606893 | 43.8606893 | 43.8606893 |
| M5_C_ORTHOGONAL_F160 | M5_FULL | 0 | 0 | 0 | 11.6692149 | 27.1277994 | 27.1277994 | 27.1277994 |
| M5_C_MIXED_CASE06_F130 | M5_FULL | 0 | 0 | 0 | 15.2694018 | 22.6480462 | 22.6480462 | 22.6480462 |
| M5_C_MIXED_CASE06_F160 | M5_FULL | 0 | 0 | 0 | 5.3699981 | 13.5659502 | 13.5659502 | 13.5659502 |
| M5_C_PARALLEL_F130 | M5_FULL | 0 | 0 | 0 | 14.9763773 | 22.3873302 | 22.3873302 | 22.3873302 |
| M5_C_PARALLEL_F160 | M5_FULL | 0 | 0 | 0 | 5.01808886 | 12.5254758 | 12.5254758 | 12.5254758 |

## Preserved negative and boundary results

- Relative to GC across the six Block C cases, M5-Full has worse total RMSE in 3, worse perpendicular RMSE in 2, and worse W2 retention error in 4. These rows are retained.
- Natural Step4 data triggered 0 rate-limited and 0 projection-active M5-Full cycles; the preregistered U6 boundary remains outside Step4.
- Parallel geometry is an identifiability boundary with no performance PASS threshold; both severities and all seven algorithms remain in the master CSV.

## Primary numerical summary

| Case | Algorithm | A tracking RMSE pF | B abs retention % | B bias pF | C W2 abs retention | C total/perp RMSE pF |
|---|---|---:|---:|---:|---:|---:|
| M5_A1_STATIC | M2 | 0.0563368 | NaN | NaN | NaN | NaN / NaN |
| M5_A1_STATIC | M3 | 0.0563368 | NaN | NaN | NaN | NaN / NaN |
| M5_A1_STATIC | M4 | 0.0559135 | NaN | NaN | NaN | NaN / NaN |
| M5_A1_STATIC | GH | 0.0563368 | NaN | NaN | NaN | NaN / NaN |
| M5_A1_STATIC | GC | 0.0559419 | NaN | NaN | NaN | NaN / NaN |
| M5_A1_STATIC | M5_DH | 0.0563368 | NaN | NaN | NaN | NaN / NaN |
| M5_A1_STATIC | M5_FULL | 0.0560248 | NaN | NaN | NaN | NaN / NaN |
| M5_A2_DRIFT_ONLY | M2 | 0.191115 | NaN | NaN | NaN | NaN / NaN |
| M5_A2_DRIFT_ONLY | M3 | 0.191115 | NaN | NaN | NaN | NaN / NaN |
| M5_A2_DRIFT_ONLY | M4 | 0.195197 | NaN | NaN | NaN | NaN / NaN |
| M5_A2_DRIFT_ONLY | GH | 0.191115 | NaN | NaN | NaN | NaN / NaN |
| M5_A2_DRIFT_ONLY | GC | 0.194604 | NaN | NaN | NaN | NaN / NaN |
| M5_A2_DRIFT_ONLY | M5_DH | 0.191115 | NaN | NaN | NaN | NaN / NaN |
| M5_A2_DRIFT_ONLY | M5_FULL | 0.194554 | NaN | NaN | NaN | NaN / NaN |
| M5_B_F105 | M2 | NaN | 1.47683 | 0.572178 | NaN | NaN / NaN |
| M5_B_F105 | M3 | NaN | 1.47683 | 0.572178 | NaN | NaN / NaN |
| M5_B_F105 | M4 | NaN | 1.45618 | 0.564701 | NaN | NaN / NaN |
| M5_B_F105 | GH | NaN | 1.47683 | 0.572178 | NaN | NaN / NaN |
| M5_B_F105 | GC | NaN | 1.45625 | 0.564892 | NaN | NaN / NaN |
| M5_B_F105 | M5_DH | NaN | 1.47683 | 0.572178 | NaN | NaN / NaN |
| M5_B_F105 | M5_FULL | NaN | 1.45682 | 0.565055 | NaN | NaN / NaN |
| M5_B_F110 | M2 | NaN | 2.93102 | 1.15041 | NaN | NaN / NaN |
| M5_B_F110 | M3 | NaN | 2.93102 | 1.15041 | NaN | NaN / NaN |
| M5_B_F110 | M4 | NaN | 2.89123 | 1.13531 | NaN | NaN / NaN |
| M5_B_F110 | GH | NaN | 2.93102 | 1.15041 | NaN | NaN / NaN |
| M5_B_F110 | GC | NaN | 2.88955 | 1.13485 | NaN | NaN / NaN |
| M5_B_F110 | M5_DH | NaN | 2.93102 | 1.15041 | NaN | NaN / NaN |
| M5_B_F110 | M5_FULL | NaN | 2.89062 | 1.13518 | NaN | NaN / NaN |
| M5_B_F120 | M2 | NaN | 5.46564 | 2.30263 | NaN | NaN / NaN |
| M5_B_F120 | M3 | NaN | 5.46564 | 2.30263 | NaN | NaN / NaN |
| M5_B_F120 | M4 | NaN | 5.38555 | 2.26946 | NaN | NaN / NaN |
| M5_B_F120 | GH | NaN | 5.46564 | 2.30263 | NaN | NaN / NaN |
| M5_B_F120 | GC | NaN | 5.37323 | 2.26457 | NaN | NaN / NaN |
| M5_B_F120 | M5_DH | NaN | 5.46564 | 2.30263 | NaN | NaN / NaN |
| M5_B_F120 | M5_FULL | NaN | 5.37543 | 2.26534 | NaN | NaN / NaN |
| M5_B_F130 | M2 | NaN | 7.60885 | 3.45421 | NaN | NaN / NaN |
| M5_B_F130 | M3 | NaN | 7.60885 | 3.45421 | NaN | NaN / NaN |
| M5_B_F130 | M4 | NaN | 7.46401 | 3.38919 | NaN | NaN / NaN |
| M5_B_F130 | GH | NaN | 7.60885 | 3.45421 | NaN | NaN / NaN |
| M5_B_F130 | GC | NaN | 7.44071 | 3.37899 | NaN | NaN / NaN |
| M5_B_F130 | M5_DH | NaN | 7.60885 | 3.45421 | NaN | NaN / NaN |
| M5_B_F130 | M5_FULL | NaN | 7.44408 | 3.38029 | NaN | NaN / NaN |
| M5_B_F140 | M2 | NaN | 9.44624 | 4.60595 | NaN | NaN / NaN |
| M5_B_F140 | M3 | NaN | 0.736265 | 0.39962 | NaN | NaN / NaN |
| M5_B_F140 | M4 | NaN | 9.24575 | 4.50899 | NaN | NaN / NaN |
| M5_B_F140 | GH | NaN | 0.736265 | 0.39962 | NaN | NaN / NaN |
| M5_B_F140 | GC | NaN | 9.22022 | 4.49692 | NaN | NaN / NaN |
| M5_B_F140 | M5_DH | NaN | 0.738032 | 0.394616 | NaN | NaN / NaN |
| M5_B_F140 | M5_FULL | NaN | 9.22476 | 4.49889 | NaN | NaN / NaN |
| M5_B_F160 | M2 | NaN | 12.4328 | 6.90991 | NaN | NaN / NaN |
| M5_B_F160 | M3 | NaN | 1.17893 | 0.694011 | NaN | NaN / NaN |
| M5_B_F160 | M4 | NaN | 11.9637 | 6.65054 | NaN | NaN / NaN |
| M5_B_F160 | GH | NaN | 1.17893 | 0.694011 | NaN | NaN / NaN |
| M5_B_F160 | GC | NaN | 12.0787 | 6.71444 | NaN | NaN / NaN |
| M5_B_F160 | M5_DH | NaN | 1.18054 | 0.68966 | NaN | NaN / NaN |
| M5_B_F160 | M5_FULL | NaN | 12.0832 | 6.71665 | NaN | NaN / NaN |
| M5_C_ORTHOGONAL_F130 | M2 | NaN | NaN | NaN | 0.331433 | 3.43987 / 0.203914 |
| M5_C_ORTHOGONAL_F130 | M3 | NaN | NaN | NaN | 0.331433 | 3.43987 / 0.203914 |
| M5_C_ORTHOGONAL_F130 | M4 | NaN | NaN | NaN | 0.319887 | 3.16826 / 0.288146 |
| M5_C_ORTHOGONAL_F130 | GH | NaN | NaN | NaN | 0.331433 | 3.43987 / 0.203914 |
| M5_C_ORTHOGONAL_F130 | GC | NaN | NaN | NaN | 0.321222 | 3.22022 / 0.293207 |
| M5_C_ORTHOGONAL_F130 | M5_DH | NaN | NaN | NaN | 0.331433 | 3.43987 / 0.203914 |
| M5_C_ORTHOGONAL_F130 | M5_FULL | NaN | NaN | NaN | 0.320676 | 3.20356 / 0.154369 |
| M5_C_ORTHOGONAL_F160 | M2 | NaN | NaN | NaN | 0.331982 | 6.85177 / 0.19051 |
| M5_C_ORTHOGONAL_F160 | M3 | NaN | NaN | NaN | 0.0635337 | 1.76811 / 1.09749 |
| M5_C_ORTHOGONAL_F160 | M4 | NaN | NaN | NaN | 0.294177 | 5.53755 / 0.403485 |
| M5_C_ORTHOGONAL_F160 | GH | NaN | NaN | NaN | 0.0635337 | 1.76811 / 1.09749 |
| M5_C_ORTHOGONAL_F160 | GC | NaN | NaN | NaN | 0.302757 | 5.80456 / 0.373492 |
| M5_C_ORTHOGONAL_F160 | M5_DH | NaN | NaN | NaN | 0.065707 | 1.39027 / 0.10546 |
| M5_C_ORTHOGONAL_F160 | M5_FULL | NaN | NaN | NaN | 0.302234 | 5.78461 / 0.11165 |
| M5_C_MIXED_CASE06_F130 | M2 | NaN | NaN | NaN | 0.336048 | 3.27233 / 0.0453545 |
| M5_C_MIXED_CASE06_F130 | M3 | NaN | NaN | NaN | 0.336048 | 3.27233 / 0.0453545 |
| M5_C_MIXED_CASE06_F130 | M4 | NaN | NaN | NaN | 0.321424 | 2.94851 / 0.0570682 |
| M5_C_MIXED_CASE06_F130 | GH | NaN | NaN | NaN | 0.336048 | 3.27233 / 0.0453545 |
| M5_C_MIXED_CASE06_F130 | GC | NaN | NaN | NaN | 0.320418 | 2.97933 / 0.0566253 |
| M5_C_MIXED_CASE06_F130 | M5_DH | NaN | NaN | NaN | 0.336048 | 3.27233 / 0.0453545 |
| M5_C_MIXED_CASE06_F130 | M5_FULL | NaN | NaN | NaN | 0.320423 | 2.97925 / 0.0512148 |
| M5_C_MIXED_CASE06_F160 | M2 | NaN | NaN | NaN | 0.335013 | 6.70585 / 0.0465809 |
| M5_C_MIXED_CASE06_F160 | M3 | NaN | NaN | NaN | 0.0225708 | 0.57367 / 0.259916 |
| M5_C_MIXED_CASE06_F160 | M4 | NaN | NaN | NaN | 0.290477 | 5.2 / 0.0822677 |
| M5_C_MIXED_CASE06_F160 | GH | NaN | NaN | NaN | 0.0225708 | 0.57367 / 0.259916 |
| M5_C_MIXED_CASE06_F160 | GC | NaN | NaN | NaN | 0.299681 | 5.47146 / 0.0757145 |
| M5_C_MIXED_CASE06_F160 | M5_DH | NaN | NaN | NaN | 0.0226845 | 0.515564 / 0.0653087 |
| M5_C_MIXED_CASE06_F160 | M5_FULL | NaN | NaN | NaN | 0.29974 | 5.47195 / 0.0629125 |
| M5_C_PARALLEL_F130 | M2 | NaN | NaN | NaN | 0.336168 | 3.27047 / 0.0333461 |
| M5_C_PARALLEL_F130 | M3 | NaN | NaN | NaN | 0.336168 | 3.27047 / 0.0333461 |
| M5_C_PARALLEL_F130 | M4 | NaN | NaN | NaN | 0.321386 | 2.94331 / 0.0270901 |
| M5_C_PARALLEL_F130 | GH | NaN | NaN | NaN | 0.336168 | 3.27047 / 0.0333461 |
| M5_C_PARALLEL_F130 | GC | NaN | NaN | NaN | 0.32034 | 2.97461 / 0.0252123 |
| M5_C_PARALLEL_F130 | M5_DH | NaN | NaN | NaN | 0.336168 | 3.27047 / 0.0333461 |
| M5_C_PARALLEL_F130 | M5_FULL | NaN | NaN | NaN | 0.320415 | 2.97532 / 0.0489254 |
| M5_C_PARALLEL_F160 | M2 | NaN | NaN | NaN | 0.335079 | 6.70433 / 0.0351096 |
| M5_C_PARALLEL_F160 | M3 | NaN | NaN | NaN | 0.0213776 | 0.493987 / 0.0560386 |
| M5_C_PARALLEL_F160 | M4 | NaN | NaN | NaN | 0.290129 | 5.18631 / 0.0198686 |
| M5_C_PARALLEL_F160 | GH | NaN | NaN | NaN | 0.0213776 | 0.493987 / 0.0560386 |
| M5_C_PARALLEL_F160 | GC | NaN | NaN | NaN | 0.299596 | 5.46385 / 0.0206352 |
| M5_C_PARALLEL_F160 | M5_DH | NaN | NaN | NaN | 0.0213812 | 0.494864 / 0.0633036 |
| M5_C_PARALLEL_F160 | M5_FULL | NaN | NaN | NaN | 0.299632 | 5.46461 / 0.0612906 |

## Scientific boundary

The deterministic result is limited to the preregistered model, seeds, windows, and fixed fault direction. A GO supports only progression to separately reviewed Monte Carlo work; it is not population-level validation. A STOP forbids that progression until the registered failure is reviewed.

**STEP5_AUTHORIZED: NO — pending human review.**
